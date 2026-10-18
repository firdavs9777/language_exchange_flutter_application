import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { makeStore } from "./index";
import { apiSlice } from "./slices/apiSlice";
import { useGetPublicStatsQuery } from "./slices/publicStatsSlice";
import { useGetVipPlansQuery } from "./slices/plansSlice";

// The prerender ships fulfilled query entries in window.__BT_PRELOADED_STATE__
// so the client's first render matches the static markup. Without a refetch on
// mount those entries are the whole session's data: a visitor who keeps the tab
// open sees build-time numbers and prices forever. These tests pin the refetch.

const json = (body: unknown) =>
  new Response(JSON.stringify(body), { status: 200, headers: { "Content-Type": "application/json" } });

/** The api-slice config as a real store builds it — what the prerender transfers. */
function apiConfig() {
  return makeStore().getState()[apiSlice.reducerPath].config;
}

function preloadedWith(queries: Record<string, unknown>) {
  return {
    [apiSlice.reducerPath]: {
      config: apiConfig(),
      queries,
      mutations: {},
      provided: {},
      subscriptions: {},
    },
  };
}

const PRELOADED_STATS = {
  "getPublicStats(undefined)": {
    status: "fulfilled",
    endpointName: "getPublicStats",
    requestId: "x",
    originalArgs: undefined,
    startedTimeStamp: 1,
    fulfilledTimeStamp: 2,
    data: { learners: 1200, countries: 3, languages: 137, generatedAt: "x" },
  },
};

const PRELOADED_PLANS = {
  'getVipPlans("ios")': {
    status: "fulfilled",
    endpointName: "getVipPlans",
    requestId: "x",
    originalArgs: "ios",
    startedTimeStamp: 1,
    fulfilledTimeStamp: 2,
    data: [{ id: "monthly", localizedPrice: "$9.99" }],
  },
};

const Stats: React.FC = () => {
  const { data } = useGetPublicStatsQuery();
  return React.createElement("p", null, data ? String((data as any).learners) : "none");
};

const Plans: React.FC = () => {
  const { data } = useGetVipPlansQuery("ios");
  const first: any = data && data[0];
  return React.createElement("p", null, first ? first.localizedPrice : "none");
};

let fetchMock: jest.Mock;
const realFetch = global.fetch;

beforeEach(() => {
  fetchMock = jest.fn();
  (global as any).fetch = fetchMock;
});

afterEach(() => {
  (global as any).fetch = realFetch;
});

// The serialized cache keys above must be the ones RTK Query really writes,
// otherwise the test would preload an entry nothing reads.
it("uses the cache keys RTK Query actually serializes", async () => {
  fetchMock.mockResolvedValue(json({ success: true, data: { learners: 1, countries: 1, languages: 1, generatedAt: "z" } }));
  const store = makeStore();
  await store.dispatch(apiSlice.endpoints.getPublicStats.initiate(undefined) as any);
  await store.dispatch(apiSlice.endpoints.getVipPlans.initiate("ios") as any);
  const keys = Object.keys(store.getState()[apiSlice.reducerPath].queries);
  expect(keys).toContain(Object.keys(PRELOADED_STATS)[0]);
  expect(keys).toContain(Object.keys(PRELOADED_PLANS)[0]);
});

it("renders the preloaded stats first, then refreshes them on mount", async () => {
  fetchMock.mockResolvedValue(
    json({ success: true, data: { learners: 1300, countries: 3, languages: 137, generatedAt: "y" } })
  );
  const store = makeStore(preloadedWith(PRELOADED_STATS));

  render(React.createElement(Provider, { store }, React.createElement(Stats)));

  // First render must match the prerendered markup.
  expect(screen.getByText("1200")).toBeTruthy();
  // ...and then the live number replaces it.
  expect(await screen.findByText("1300")).toBeTruthy();
  expect(fetchMock).toHaveBeenCalledTimes(1);
});

it("renders the preloaded plans first, then refreshes them on mount", async () => {
  fetchMock.mockResolvedValue(json({ success: true, data: [{ id: "monthly", localizedPrice: "$10.99" }] }));
  const store = makeStore(preloadedWith(PRELOADED_PLANS));

  render(React.createElement(Provider, { store }, React.createElement(Plans)));

  expect(screen.getByText("$9.99")).toBeTruthy();
  expect(await screen.findByText("$10.99")).toBeTruthy();
  expect(fetchMock).toHaveBeenCalledTimes(1);
});
