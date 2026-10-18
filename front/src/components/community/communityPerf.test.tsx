import "@testing-library/jest-dom";
import React from "react";
import { act, render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import MainCommunity from "./MainCommunity";
jest.mock("../../utils/webFlags", () => ({ useWebFlag: () => false, useWebFlagState: () => ({ on: false, ready: true }) }));

/**
 * What the member list costs.
 *
 * Not "does it look right" -- the other suites answer that. These are the
 * four numbers that decide whether a long list is cheap: how many requests a
 * mount makes, whether reaching the bottom asks for the next page exactly
 * once, whether a filter change replaces the list instead of appending to it,
 * and how many times typing a word rewrites the URL.
 */

jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, options?: Record<string, any>) =>
      options
        ? `${key} ${Object.keys(options)
            .map((name) => options[name])
            .join(" ")}`
        : key,
  }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: {
    success: jest.fn(),
    error: jest.fn(),
    info: jest.fn(),
    warning: jest.fn(),
    show: jest.fn(),
    dismiss: jest.fn(),
  },
}));

const PAGE_LIMIT = 20;

const member = (prefix: string, n: number) => ({
  _id: `${prefix}${n}`,
  name: `${prefix === "m" ? "Member" : "Online"} ${n}`,
  native_language: "Korean",
  language_to_learn: "English",
  imageUrls: [`https://cdn.example.com/${prefix}${n}.jpg`],
});

const pageOf = (prefix: string, from: number) =>
  Array.from({ length: PAGE_LIMIT }, (_, i) => member(prefix, from + i));

const requestedUrls: string[] = [];
const originalFetch = global.fetch;

/* --- IntersectionObserver ---------------------------------------------------
 * jsdom has none, which is exactly the environment the "Load more" button is
 * kept for. Most tests here install a fake one and drive it by hand; the
 * fallback test deletes it again.
 */
interface FakeObserver {
  callback: (entries: any[]) => void;
  element: Element;
  live: boolean;
  options: any;
}
let observers: FakeObserver[] = [];

class FakeIntersectionObserver {
  callback: (entries: any[]) => void;
  options: any;
  constructor(callback: (entries: any[]) => void, options?: any) {
    this.callback = callback;
    this.options = options;
  }
  observe(element: Element) {
    observers.push({ callback: this.callback, element, live: true, options: this.options });
  }
  unobserve() {
    /* nothing to do: `disconnect` is what the component calls */
  }
  disconnect() {
    observers.forEach((o) => {
      if (o.callback === this.callback) o.live = false;
    });
  }
  takeRecords() {
    return [];
  }
}

/** Scroll the sentinel into view, as far as the component can tell. */
const intersect = () =>
  act(() => {
    observers
      .filter((o) => o.live)
      .forEach((o) => o.callback([{ isIntersecting: true, target: o.element }]));
  });

beforeEach(() => {
  requestedUrls.length = 0;
  observers = [];
  window.localStorage.clear();
  (global as any).IntersectionObserver = FakeIntersectionObserver;
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requestedUrls.push(url);
    let body: any = { success: true, data: [] };
    if (url.indexOf("/count") >= 0) {
      body = { success: true, data: { count: 7 } };
    } else if (url.indexOf("/visitors") >= 0) {
      body = { success: true, totalCount: 0, data: [] };
    } else if (url.indexOf("/auth/users") >= 0) {
      // A different set per filter state, and a second page under the first,
      // so an append and a replace are told apart by name.
      if (url.indexOf("onlineOnly=true") >= 0) body = { success: true, data: pageOf("o", 1) };
      else if (/[?&]page=2\b/.test(url)) body = { success: true, data: pageOf("m", 21) };
      else body = { success: true, data: pageOf("m", 1) };
    }
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
  delete (global as any).IntersectionObserver;
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

function renderList(entries: string[] = ["/communities?tab=all"]) {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="communities" element={<MainCommunity />} />
        <Route path="community/:id" element={<div data-testid="member-screen" />} />
      </Route>
    ),
    { initialEntries: entries }
  );
  const utils = render(
    <Provider store={makeStore(SIGNED_IN)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return { ...utils, router };
}

const memberRequests = () => requestedUrls.filter((u) => /\/auth\/users\?/.test(u));
const cards = () => screen.queryAllByTestId("member-card-root");
/** The names on the cards themselves -- the carousel above repeats them. */
const cardNames = () =>
  screen.queryAllByTestId("member-card-name").map((el) => el.textContent);

describe("what a mount costs", () => {
  // Five, and the same five every time: the list, the topic vocabulary the
  // chips and the sheet both need, the visitors banner, and /auth/me -- the
  // account's CURRENT languages, which the default match is built from. The
  // login snapshot it replaces went stale whenever languages were changed in
  // the app. The list does not wait for it, and a /auth/me that agrees with the
  // snapshot builds the same params, so it never causes a second list request
  // (asserted below). Plus /matching/daily: whether the Today tab exists at
  // all is the server's answer (404 = the feature is off), so a signed-in
  // mount asks once even on All. Anything else on this page is a regression.
  it("asks for the list, the topics, the visitors, the account, today's batch and the app config -- and nothing else", async () => {
    renderList();

    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));

    // app-config decides the default sort (smart only while the server
    // offers it), so the list waits for it rather than asking twice.
    expect(requestedUrls).toHaveLength(6);
    expect(requestedUrls.filter((u) => u.indexOf("/app-config") >= 0)).toHaveLength(1);
    expect(requestedUrls.filter((u) => u.indexOf("/matching/daily") >= 0)).toHaveLength(1);
    expect(requestedUrls.filter((u) => /\/auth\/me(\?|$)/.test(u))).toHaveLength(1);
    expect(requestedUrls.filter((u) => /\/auth\/users\?/.test(u))).toHaveLength(1);
    expect(requestedUrls.filter((u) => u.indexOf("/topics") >= 0)).toHaveLength(1);
    expect(requestedUrls.filter((u) => u.indexOf("/visitors") >= 0)).toHaveLength(1);
    // The count belongs to the filter sheet, and the sheet is closed.
    expect(requestedUrls.filter((u) => u.indexOf("/count") >= 0)).toHaveLength(0);
  });

  it("leaves every avatar below the fold to the browser", async () => {
    const { container } = renderList();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));

    const avatars = container.querySelectorAll('[data-testid="member-card-root"] img');
    expect(avatars.length).toBe(PAGE_LIMIT);
    avatars.forEach((img) => {
      expect(img).toHaveAttribute("loading", "lazy");
      expect(img).toHaveAttribute("decoding", "async");
      // A box the browser can reserve before a byte arrives. 320x200 is the
      // 16:10 grid photo; it was 72x72 when the card was a list row.
      expect(img).toHaveAttribute("width", "320");
      expect(img).toHaveAttribute("height", "200");
    });
  });

  it("stands card-shaped placeholders in while the first page loads", () => {
    const { container } = renderList();
    expect(screen.getByTestId("community-skeletons")).toBeInTheDocument();
    expect(container.querySelectorAll(".community-card-skeleton").length).toBeGreaterThan(0);
  });
});

describe("paging without a button press", () => {
  it("asks for page 2 once when the sentinel comes into view", async () => {
    renderList();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));
    expect(screen.getByTestId("community-sentinel")).toBeInTheDocument();

    await intersect();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT * 2));

    const pageTwo = memberRequests().filter((u) => /[?&]page=2\b/.test(u));
    expect(pageTwo).toHaveLength(1);
  });

  // A flick past the end of the list fires the observer more than once before
  // the request it started has come back.
  it("does not ask twice for the same page when the sentinel fires again", async () => {
    renderList();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));

    await intersect();
    await intersect();
    await intersect();

    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT * 2));
    expect(memberRequests().filter((u) => /[?&]page=2\b/.test(u))).toHaveLength(1);
  });

  // The button is not decoration: it is the whole paging story wherever
  // IntersectionObserver does not exist, and the only one reachable by keyboard.
  it("keeps the Load more button as the fallback where there is no observer", async () => {
    delete (global as any).IntersectionObserver;
    renderList();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));

    fireEvent.click(screen.getByText("communityMain.loadMore.button"));
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT * 2));
    expect(memberRequests().filter((u) => /[?&]page=2\b/.test(u))).toHaveLength(1);
  });
});

describe("when the question changes", () => {
  // Page 2 of the old list is not the top of the new one. A filter change has
  // to start over, not append the answer to a question nobody asked.
  it("goes back to page 1 and replaces the list", async () => {
    renderList();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));

    await intersect();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT * 2));
    // (the highlighted carousel renders the same names, so count cards only)
    expect(cardNames()).toContain("Member 21");

    fireEvent.click(screen.getByText("communityMain.chips.onlineNow"));

    await waitFor(() => expect(cardNames()).toContain("Online 1"));
    expect(cards().length).toBe(PAGE_LIMIT);
    expect(cardNames()).not.toContain("Member 21");
    expect(cardNames()).not.toContain("Member 1");

    const online = memberRequests().filter((u) => u.indexOf("onlineOnly=true") >= 0);
    expect(online).toHaveLength(1);
    expect(online[0]).toMatch(/[?&]page=1\b/);
  });
});

describe("typing in the search box", () => {
  // The box is instant; the URL -- and the re-derivation of every piece of
  // list state that hangs off it -- waits for the word to finish.
  it("writes the URL once for a five-character word", async () => {
    const { router } = renderList();
    await waitFor(() => expect(cards().length).toBe(PAGE_LIMIT));

    jest.useFakeTimers();
    try {
      const navigations: string[] = [];
      const unsubscribe = router.subscribe((state) =>
        navigations.push(state.location.search)
      );

      const box = screen.getByPlaceholderText("communityMain.subnav.searchPlaceholder");
      ["a", "an", "ann", "anna", "annab"].forEach((value) => {
        fireEvent.change(box, { target: { value } });
      });

      // Every keystroke is already on screen...
      expect((box as HTMLInputElement).value).toBe("annab");
      // ...and none of them has touched the URL yet.
      expect(router.state.location.search).toBe("?tab=all");  // all is written since today became the default landing
      expect(navigations).toHaveLength(0);

      act(() => {
        jest.advanceTimersByTime(600);
      });

      expect(router.state.location.search).toBe("?q=annab&tab=all");  // all is written since today became the default landing
      expect(navigations.filter((search) => search.indexOf("q=") >= 0)).toHaveLength(1);
      unsubscribe();
    } finally {
      jest.useRealTimers();
    }

    // And one request, for the finished word -- not five.
    await waitFor(() =>
      expect(memberRequests().filter((u) => u.indexOf("search=") >= 0)).toHaveLength(1)
    );
    expect(memberRequests().filter((u) => u.indexOf("search=annab") >= 0)).toHaveLength(1);
  });
});

describe("what the Today landing costs", () => {
  // Today is the default landing: it asks for the day's batch and NOT for the
  // All list, which waits until the member switches tabs.
  it("asks for /matching/daily once and never for /auth/users", async () => {
    renderList(["/communities"]);
    await waitFor(() => expect(requestedUrls.filter((u) => u.indexOf("/matching/daily") >= 0)).toHaveLength(1));
    expect(requestedUrls.filter((u) => /\/auth\/users\?/.test(u))).toHaveLength(0);
  });
});
