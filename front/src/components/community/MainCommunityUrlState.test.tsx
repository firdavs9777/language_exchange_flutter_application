import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import MainCommunity from "./MainCommunity";
import { STORAGE_KEY } from "./lib/filterStorage";

// The list's copy is not what this suite is about: `t` returns the key, so a
// button is queried by its key and the assertions stay about the URL.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => key }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const mockNotifySuccess = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: {
    success: (...args: any[]) => mockNotifySuccess(...args),
    error: jest.fn(),
    info: jest.fn(),
    warning: jest.fn(),
    show: jest.fn(),
    dismiss: jest.fn(),
  },
}));

const member = (n: number) => ({
  _id: `m${n}`,
  name: `Member ${n}`,
  native_language: "Korean",
  language_to_learn: "English",
  imageUrls: [],
});

let memberCount = 3;
const requestedUrls: string[] = [];
const originalFetch = global.fetch;

beforeEach(() => {
  requestedUrls.length = 0;
  memberCount = 3;
  window.localStorage.clear();
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requestedUrls.push(url);
    const body = url.indexOf("/count") >= 0
      ? { success: true, data: { count: 7 } }
      : {
          success: true,
          data: url.indexOf("/auth/users") >= 0
            ? Array.from({ length: memberCount }, (_unused, i) => member(i))
            : [],
        };
    return Promise.resolve(
      new Response(JSON.stringify(body), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    );
  });
});

afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

const SIGNED_IN = {
  auth: {
    userInfo: {
      user: { _id: "u1", name: "Me", native_language: "English", language_to_learn: "Korean" },
      token: "t",
    },
  },
};

function renderList(entries: string[] = ["/communities?tab=all"], initialIndex?: number) {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="communities" element={<MainCommunity />} />
        <Route path="community/nearby" element={<div data-testid="nearby-screen" />} />
        <Route path="topics" element={<div data-testid="topics-screen" />} />
      </Route>
    ),
    { initialEntries: entries, initialIndex }
  );
  const utils = render(
    <Provider store={makeStore(SIGNED_IN)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return { ...utils, router };
}

/** Every `GET /auth/users` the list made, oldest first. */
const memberRequests = () => requestedUrls.filter((u) => /\/auth\/users\?/.test(u));

describe("the community list keeps its state in the URL", () => {
  it("prefers the URL over the stored filters on mount", async () => {
    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ minAge: 18, maxAge: 100, gender: "male" })
    );

    renderList(["/communities?online=1"]);

    expect(await screen.findByText("Online now")).toBeInTheDocument();
    expect(screen.queryByText("Gender: male")).not.toBeInTheDocument();
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests()[0]).toContain("onlineOnly=true");
  });

  it("falls back to the stored filters when the URL is empty, and puts them in the URL", async () => {
    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ minAge: 18, maxAge: 100, gender: "female" })
    );

    const { router } = renderList(["/communities?tab=all"]);

    expect(await screen.findByText("Gender: female")).toBeInTheDocument();
    await waitFor(() =>
      expect(router.state.location.search).toBe("?gender=female&tab=all")  // all is written since today became the default landing
    );
  });

  it("leaves the URL clean when there is nothing to say", async () => {
    const { router } = renderList(["/communities?tab=all"]);
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(router.state.location.search).toBe("?tab=all");  // all is written since today became the default landing
  });

  it("rewrites the URL and goes back to page 1 when a filter changes", async () => {
    memberCount = 20; // a full page, so "Load more" is offered
    const { router } = renderList(["/communities?tab=all"]);

    fireEvent.click(await screen.findByText("communityMain.loadMore.button"));
    await waitFor(() =>
      expect(memberRequests().some((u) => /[?&]page=2\b/.test(u))).toBe(true)
    );

    fireEvent.click(screen.getByRole("button", { name: /communityMain.chips.onlineNow/ }));

    await waitFor(() => expect(router.state.location.search).toBe("?online=1&tab=all"));  // all is written since today became the default landing
    const last = memberRequests()[memberRequests().length - 1];
    expect(last).toContain("onlineOnly=true");
    expect(last).toMatch(/[?&]page=1\b/);
  });

  it("puts what is typed in the search box straight into the URL", async () => {
    const { router } = renderList(["/communities?tab=all"]);
    const box = await screen.findByPlaceholderText(
      "communityMain.subnav.searchPlaceholder"
    );

    fireEvent.change(box, { target: { value: "anna" } });

    await waitFor(() => expect(router.state.location.search).toBe("?q=anna&tab=all"));  // all is written since today became the default landing
    expect((box as HTMLInputElement).value).toBe("anna");
    // The box is immediate; the query waits for the typing to settle.
    await waitFor(() =>
      expect(memberRequests().some((u) => /search=anna/.test(u))).toBe(true)
    );
  });

  it("reads a search term back out of a shared link", async () => {
    renderList(["/communities?q=yuki"]);
    const box = await screen.findByPlaceholderText(
      "communityMain.subnav.searchPlaceholder"
    );
    expect((box as HTMLInputElement).value).toBe("yuki");
    await waitFor(() =>
      expect(memberRequests().some((u) => /search=yuki/.test(u))).toBe(true)
    );
  });

  it("keeps the sort chip in the URL", async () => {
    const { router } = renderList(["/communities?tab=all"]);

    fireEvent.click(await screen.findByRole("button", { name: /communityMain.chips.recentlyActive/ }));
    await waitFor(() =>
      expect(router.state.location.search).toBe("?sort=recently_active&tab=all")  // all is written since today became the default landing
    );

    fireEvent.click(screen.getByRole("button", { name: /communityMain.chips.recentlyActive/ }));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=all"));  // all is written since today became the default landing
  });

  it("restores the previous filters on Back", async () => {
    const { router } = renderList(
      ["/communities?gender=male", "/communities?gender=female"],
      1
    );

    expect(await screen.findByText("Gender: female")).toBeInTheDocument();

    await act(async () => {
      await router.navigate(-1);
    });

    expect(await screen.findByText("Gender: male")).toBeInTheDocument();
    expect(screen.queryByText("Gender: female")).not.toBeInTheDocument();
  });

  it("takes a filter out of the URL when its chip is dismissed", async () => {
    const { router } = renderList(["/communities?gender=male&online=1"]);

    fireEvent.click(await screen.findByText("Gender: male"));

    await waitFor(() => expect(router.state.location.search).toBe("?online=1&tab=all"));  // all is written since today became the default landing
    expect(screen.queryByText("Gender: male")).not.toBeInTheDocument();
    expect(screen.getByText("Online now")).toBeInTheDocument();
  });

  it("empties the URL when every filter is cleared", async () => {
    const { router } = renderList(["/communities?gender=male"]);

    fireEvent.click(await screen.findByText("Clear"));

    await waitFor(() => expect(router.state.location.search).toBe("?tab=all"));  // all is written since today became the default landing
  });

  it("copies a link to the list as it stands", async () => {
    const writeText = jest.fn(() => Promise.resolve());
    Object.defineProperty(window.navigator, "clipboard", {
      value: { writeText },
      configurable: true,
    });

    renderList(["/communities?gender=male&online=1"]);

    fireEvent.click(await screen.findByRole("button", { name: /communityMain.subnav.filters/ }));
    fireEvent.click(await screen.findByText("communityMain.filterSheet.copyLink"));

    await waitFor(() => expect(writeText).toHaveBeenCalled());
    const copied = writeText.mock.calls[0][0] as unknown as string;
    expect(copied).toContain("/communities?");
    expect(copied).toContain("gender=male");
    expect(copied).toContain("online=1");
    expect(mockNotifySuccess).toHaveBeenCalled();
  });

  it("puts the tab in the URL and reads it back", async () => {
    const { router } = renderList(["/communities?tab=all&gender=male"]);
    expect(await screen.findByText("Gender: male")).toBeInTheDocument();
    // `all` is the default, so it is normalised out of the query.
    await waitFor(() => expect(router.state.location.search).toBe("?gender=male&tab=all"));  // all is written since today became the default landing
  });

  it("keeps params it does not own", async () => {
    const { router } = renderList(["/communities?utm_source=twitter&gender=male"]);
    expect(await screen.findByText("Gender: male")).toBeInTheDocument();
    await waitFor(() =>
      expect(router.state.location.search).toContain("utm_source=twitter")
    );
  });
});

// Review finding: the saved-filter fallback read a snapshot taken at mount and
// never updated. Dismissing the last chip saved {} but the snapshot still said
// gender=female, so the fallback put a filter back that the member had just
// removed -- on Online/New (a regression) and on every All visit.
describe("clearing the last filter with saved filters on record", () => {
  it.each([["online"], ["all"]])("leaves %s with no filter at all", async (tab) => {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify({ minAge: 18, maxAge: 100, gender: "female" }));
    const { router } = renderList([`/communities?tab=${tab}&gender=male`]);

    fireEvent.click(await screen.findByText("Gender: male"));

    await waitFor(() => expect(router.state.location.search).toBe(`?tab=${tab}`));
    expect(screen.queryByText("Gender: female")).not.toBeInTheDocument();
  });
});

