/**
 * Asserts the REAL request shape (URL/method/body) each reconciled
 * communitySlice endpoint produces, by dispatching `.initiate(...)` against
 * a real store + a mocked global.fetch and inspecting the outgoing Request.
 * (RTK Query endpoint objects don't expose their internal `query` builder
 * directly — `.initiate` + fetch interception is the reliable way to
 * introspect the resulting request without hitting a real network.)
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import {
  communityApiSlice,
} from "./communitySlice";
import {
  COMMUNITY_WAVES,
  COMMUNITY_WAVES_LIST,
  COMMUNITY_COUNT_URL,
} from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      // Minimal stand-in for the real authSlice — apiSlice's
      // prepareHeaders/reauth logic only reads state.auth.userInfo.
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: string | undefined };

function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body =
      req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(
      JSON.stringify({ success: true, data: { waves: [], unreadCount: 0, count: 0 } }),
      { status: 200, headers: { "content-type": "application/json" } }
    );
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

describe("wave endpoints hit the REAL backend routes", () => {
  it("sendWave -> POST /api/v1/community/wave with {targetUserId, message}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).sendWave.initiate({
        targetUserId: "user-1",
        message: "hi there",
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe(`http://localhost:5003${COMMUNITY_WAVES}`);
    expect(calls[0].url).toContain("/api/v1/community/wave");
    expect(calls[0].url).not.toContain("/wave/"); // no nested /wave/... path
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      targetUserId: "user-1",
      message: "hi there",
    });
  });

  it("getWaves -> GET /api/v1/community/waves with page/limit/unreadOnly/archive", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getWaves.initiate({
        page: 2,
        limit: 15,
        unreadOnly: true,
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].method).toBe("GET");
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(COMMUNITY_WAVES_LIST);
    expect(url.pathname).toBe("/api/v1/community/waves");
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("limit")).toBe("15");
    expect(url.searchParams.get("unreadOnly")).toBe("true");
  });

  it("markWavesRead -> PUT /api/v1/community/waves/read with {waveIds}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).markWavesRead.initiate(["w1", "w2"])
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMUNITY_WAVES_LIST}/read`);
    expect(url.pathname).toBe("/api/v1/community/waves/read");
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({ waveIds: ["w1", "w2"] });
  });

  it("does NOT expose the old non-existent wave routes", async () => {
    // The removed getReceivedWaves/getSentWaves/respondToWave/markWaveRead
    // endpoints pointed at /wave/received, /wave/sent, /wave/:id/respond,
    // /wave/:id/read — none of which exist server-side.
    const endpointNames = Object.keys((communityApiSlice as any).endpoints);
    expect(endpointNames).not.toContain("getReceivedWaves");
    expect(endpointNames).not.toContain("getSentWaves");
    expect(endpointNames).not.toContain("respondToWave");
    expect(endpointNames).not.toContain("markWaveRead");
    expect(endpointNames).toContain("getWaves");
    expect(endpointNames).toContain("markWavesRead");
  });
});

describe("getCommunityCount endpoint", () => {
  it("-> GET /api/v1/auth/users/count with the same filter params as members", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getCommunityCount.initiate({
        nativeLanguage: "English",
        learningLanguage: "Korean",
        matchLanguage: "true",
        minAge: "25",
        page: "1",
        limit: "20",
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].method).toBe("GET");
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(COMMUNITY_COUNT_URL);
    expect(url.pathname).toBe("/api/v1/auth/users/count");
    expect(url.searchParams.get("nativeLanguage")).toBe("English");
    expect(url.searchParams.get("learningLanguage")).toBe("Korean");
    expect(url.searchParams.get("minAge")).toBe("25");
  });
});
