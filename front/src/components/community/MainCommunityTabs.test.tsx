import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, within } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import MainCommunity from "./MainCommunity";

// `t` returns the key: these tests are about which request is made and what is
// on the page, never about the wording.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    // The key, plus whatever was interpolated into it -- enough to assert that
    // the reasons the server sent reach the page, without asserting on copy.
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

const member = (n: number) => ({
  _id: `m${n}`,
  name: `Member ${n}`,
  native_language: "Korean",
  language_to_learn: "English",
  imageUrls: [],
});

/** What the recommendation feed answers with, reset per test. */
let recommendations: any[] = [];
let appConfig: any = {};
const requestedUrls: string[] = [];
const originalFetch = global.fetch;

beforeEach(() => {
  requestedUrls.length = 0;
  appConfig = {};
  recommendations = [
    {
      ...member(1),
      matchReasons: ["Native Korean speaker", "Online now"],
      matchScore: 91,
    },
    { ...member(2), matchReasons: [] },
  ];
  window.localStorage.clear();
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requestedUrls.push(url);
    let body: any = { success: true, data: [] };
    if (url.indexOf("/app-config") >= 0) {
      body = { success: true, data: appConfig };
    } else if (url.indexOf("/matching/recommendations") >= 0) {
      body = { success: true, count: recommendations.length, data: recommendations, cached: false };
    } else if (url.indexOf("/count") >= 0) {
      body = { success: true, data: { count: 7 } };
    } else if (url.indexOf("/visitors") >= 0) {
      body = {
        success: true,
        totalCount: 3,
        data: [{ _id: "v1", name: "Vera", imageUrls: [] }],
      };
    } else if (url.indexOf("/auth/users") >= 0) {
      body = { success: true, data: [member(1), member(2), member(3)] };
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
        <Route path="community/nearby" element={<div data-testid="nearby-screen" />} />
        <Route path="topics" element={<div data-testid="topics-screen" />} />
        <Route path="profile/edit" element={<div data-testid="edit-profile-screen" />} />
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
const recommendationRequests = () =>
  requestedUrls.filter((u) => u.indexOf("/matching/recommendations") >= 0);

const tab = (name: string) => screen.getByRole("tab", { name });

describe("the community tabs", () => {
  it("puts the chosen tab in the URL", async () => {
    const { router } = renderList();
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));

    fireEvent.click(tab("communityMain.tabs.online"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=online"));

    fireEvent.click(tab("communityMain.tabs.new"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=new"));

    // `all` is the default: it is normalised back out of the query.
    fireEvent.click(tab("communityMain.tabs.all"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=all"));  // all is written since today became the default landing
  });

  it("reads the tab back out of a pasted link", async () => {
    renderList(["/communities?tab=foryou"]);

    await waitFor(() => expect(recommendationRequests().length).toBe(1));
    expect(tab("communityMain.tabs.forYou")).toHaveAttribute("aria-selected", "true");
  });

  // The tab locks the switch; the member's own filters ride along with it.
  it("locks onlineOnly on the Online tab, keeping the other filters", async () => {
    renderList(["/communities?tab=online&gender=female"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    const last = memberRequests()[memberRequests().length - 1];
    expect(last).toContain("onlineOnly=true");
    expect(last).toContain("gender=female");
  });

  // The server reads `joinedWithin`; it has never read `newUsersOnly`, and
  // this test used to pin exactly that dead parameter -- which is how the New
  // tab came to return the All list without anything going red.
  it("locks the New tab to members who joined in the last week", async () => {
    renderList(["/communities?tab=new"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    const last = memberRequests()[memberRequests().length - 1];
    expect(last).toContain("joinedWithin=7d");
    expect(last).not.toContain("newUsersOnly");
  });

  // The lock is a property of the tab, not a filter the member set: leaving
  // the tab must not leave `online=1` behind in the URL.
  it("does not write the tab's own lock into the query string", async () => {
    const { router } = renderList(["/communities?tab=online"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(router.state.location.search).toBe("?tab=online");
  });

  // The page matched on the languages saved at LOGIN. Change your native
  // language in the app and the web kept matching the old one until you logged
  // in again. /auth/me is the account as it is now.
  it("matches on the account's current languages, not the login snapshot", async () => {
    const realFetch = global.fetch;
    (global as any).fetch = jest.fn((input: any) => {
      const url = typeof input === "string" ? input : input?.url || "";
      if (/\/auth\/me(\?|$)/.test(url)) {
        return Promise.resolve(new Response(JSON.stringify({
          success: true,
          data: { _id: "u1", native_language: "Japanese", language_to_learn: "Korean" },
        }), { status: 200, headers: { "content-type": "application/json" } }));
      }
      return (realFetch as any)(input);
    });

    try {
      renderList(["/communities?tab=all"]);
      await waitFor(() =>
        expect(memberRequests().some((u) => u.indexOf("nativeLanguage=Japanese") >= 0)).toBe(true)
      );
    } finally {
      global.fetch = realFetch;
    }
  });

  it("asks the All tab for no lock at all", async () => {
    renderList(["/communities?tab=all"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    const first = memberRequests()[0];
    expect(first).not.toContain("onlineOnly");
    expect(first).not.toContain("joinedWithin");
  });

  // Reported from production: "highlighted profiles came to the middle". The
  // carousel had been interleaved into the grid after the sixth member -- the
  // first row boundary shared by the 3, 2 and 1 column layouts -- which put the
  // page's showcase halfway down the list. It sits above the grid now, the
  // first thing on the All tab, and never inside it.
  it("keeps the highlighted carousel on All only, above the grid", async () => {
    const { container, router } = renderList();

    await waitFor(() =>
      expect(container.querySelector(".highlighted-banner")).toBeInTheDocument()
    );
    const grid = container.querySelector(".community-grid")!;
    expect(grid.querySelector(".highlighted-banner")).not.toBeInTheDocument();
    expect(container.querySelector(".visitors-banner")).not.toBeInTheDocument();

    fireEvent.click(tab("communityMain.tabs.online"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=online"));

    expect(container.querySelector(".highlighted-banner")).not.toBeInTheDocument();
  });

  it("puts the carousel before the first member, whatever the list length", async () => {
    const realFetch = global.fetch;
    (global as any).fetch = jest.fn((input: any) => {
      const url = typeof input === "string" ? input : input?.url || "";
      if (/\/auth\/users\?/.test(url)) {
        return Promise.resolve(new Response(JSON.stringify({
          success: true,
          data: [member(1), member(2), member(3), member(4), member(5), member(6), member(7)],
        }), { status: 200, headers: { "Content-Type": "application/json" } }));
      }
      return (realFetch as any)(input);
    });

    try {
      const { container } = renderList();
      await waitFor(() =>
        expect(container.querySelector(".highlighted-banner")).toBeInTheDocument()
      );
      const banner = container.querySelector(".highlighted-banner")!;
      const grid = container.querySelector(".community-grid")!;
      // Document order: the banner comes before the grid that holds the members.
      expect(
        banner.compareDocumentPosition(grid) & Node.DOCUMENT_POSITION_FOLLOWING
      ).toBeTruthy();
      expect(grid.querySelector(".community-grid__feature")).not.toBeInTheDocument();
    } finally {
      global.fetch = realFetch;
    }
  });

  it("keeps the wave sheet reachable on every tab", async () => {
    renderList(["/communities?tab=foryou"]);

    const waveButtons = await screen.findAllByTestId("member-card-wave");
    fireEvent.click(waveButtons[0]);
    expect(await screen.findByTestId("wave-sheet")).toBeInTheDocument();
  });

  it("locks the Serious tab to members active in the last week", async () => {
    renderList(["/communities?tab=serious"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    const last = memberRequests()[memberRequests().length - 1];
    expect(last).toContain("activeWithin=7d");
    expect(tab("communityMain.tabs.serious")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("segment-hint")).toHaveTextContent("communityMain.tabs.seriousHint");
  });
});

describe("the For you tab", () => {
  it("asks the recommendation endpoint for a page of members, and the list for nothing", async () => {
    renderList(["/communities?tab=foryou"]);

    await waitFor(() => expect(recommendationRequests().length).toBe(1));
    expect(recommendationRequests()[0]).toContain("limit=20");
    expect(memberRequests()).toEqual([]);
  });

  it("costs nothing to a member who never opens it", async () => {
    renderList(["/communities?tab=all"]);

    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(recommendationRequests()).toEqual([]);
  });

  // A recommendation nobody can see the reasoning for is just a list, and a
  // reason that lands under the wrong member is worse than no reason at all
  // -- this is the only end-to-end proof the parent hands the right reasons
  // to the right card.
  it("prints the server's reasons under the member they belong to", async () => {
    renderList(["/communities?tab=foryou"]);

    const cards = await screen.findAllByTestId("member-card-root");
    const member1Card = cards.find((c) => within(c).queryByText(/Member 1/)) as HTMLElement;
    const member2Card = cards.find((c) => within(c).queryByText(/Member 2/)) as HTMLElement;

    expect(within(member1Card).getByText("Native Korean speaker")).toBeInTheDocument();
    expect(within(member1Card).getByText("Online now")).toBeInTheDocument();

    // Member 2's fixture has no match reasons -- it renders no chip row.
    expect(within(member2Card).queryByTestId("member-card-reasons")).not.toBeInTheDocument();
  });

  it("offers no filter or sort control", async () => {
    renderList(["/communities?tab=foryou"]);

    await waitFor(() => expect(recommendationRequests().length).toBe(1));
    expect(screen.queryByText("communityMain.chips.onlineNow")).not.toBeInTheDocument();
    expect(
      screen.queryByLabelText("communityMain.subnav.filtersLabel")
    ).not.toBeInTheDocument();
  });

  it("asks again when the member asks for something new", async () => {
    renderList(["/communities?tab=foryou"]);
    await waitFor(() => expect(recommendationRequests().length).toBe(1));

    fireEvent.click(screen.getByTestId("for-you-refresh"));
    await waitFor(() => expect(recommendationRequests().length).toBe(2));
  });

  // An empty feed is never "nobody is here": it is that we do not know enough
  // about this member yet, so the way out is their own profile.
  it("sends an empty feed to the profile editor", async () => {
    recommendations = [];
    renderList(["/communities?tab=foryou"]);

    const empty = await screen.findByTestId("for-you-empty");
    expect(empty).toBeInTheDocument();
    expect(screen.getByText("communityMain.forYou.empty.action").closest("a")).toHaveAttribute(
      "href",
      "/profile/edit"
    );
  });
});

describe("For You reason chips", () => {
  it("renders the localised key when the server sends codes", async () => {
    recommendations = [
      {
        ...member(1),
        matchReasons: ["Native Korean speaker"],
        matchReasonCodes: [{ code: "native_speaker", native: "Korean" }],
      },
    ];
    renderList(["/communities?tab=foryou"]);
    // This file's `t` mock returns "<key> <values...>".
    expect(await screen.findByText("communityMain.reasons.native_speaker Korean")).toBeInTheDocument();
  });

  it("falls back to the English strings when there are no codes", async () => {
    recommendations = [{ ...member(1), matchReasons: ["Native Korean speaker"] }];
    renderList(["/communities?tab=foryou"]);
    expect(await screen.findByText("Native Korean speaker")).toBeInTheDocument();
  });
});

describe("smart sort (community#9)", () => {
  it("asks for sort=smart by default when the server offers it, from the first request", async () => {
    appConfig = { smartSortEnabled: true };
    renderList();
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests().every((u) => u.indexOf("sort=smart") >= 0)).toBe(true);
  });

  it("never overrides the member's own sort", async () => {
    appConfig = { smartSortEnabled: true };
    renderList(["/communities?tab=all&sort=recently_active"]);
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests().some((u) => u.indexOf("sort=smart") >= 0)).toBe(false);
    expect(memberRequests()[memberRequests().length - 1]).toContain("sort=recently_active");
  });

  it("sends no sort while the flag is off", async () => {
    renderList();
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests().some((u) => u.indexOf("sort=") >= 0)).toBe(false);
  });

  it("sends reciprocal=true from a pair=1 link", async () => {
    renderList(["/communities?tab=all&pair=1"]);
    await waitFor(() => expect(memberRequests().length).toBeGreaterThan(0));
    expect(memberRequests()[memberRequests().length - 1]).toContain("reciprocal=true");
  });
});
