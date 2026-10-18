import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { HelmetProvider } from "react-helmet-async";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import UserListPage from "./UserListPage";

const mockGetFollowers = jest.fn();
const mockGetFollowings = jest.fn();
const mockGetVisitors = jest.fn();
const mockGetVisited = jest.fn();
const mockGetVipStatus = jest.fn();
const mockClearVisitors = jest.fn();
const mockGetCommunityDetails = jest.fn();
const mockFollow = jest.fn();
const mockUnfollow = jest.fn();
const mockNavigate = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useGetFollowersQuery: (arg: any, opts: any) => mockGetFollowers(arg, opts),
  useGetFollowingsQuery: (arg: any, opts: any) => mockGetFollowings(arg, opts),
  useGetVisitedProfilesQuery: (arg: any, opts: any) => mockGetVisited(arg, opts),
  useGetProfileVisitorsQuery: (arg: any, opts: any) =>
    mockGetVisitors(arg, opts),
  useGetVipStatusQuery: (arg: any, opts: any) => mockGetVipStatus(arg, opts),
  useClearVisitorsMutation: () => [mockClearVisitors, { isLoading: false }],
  useFollowUserMutation: () => [mockFollow, { isLoading: false }],
  useUnFollowUserMutation: () => [mockUnfollow, { isLoading: false }],
}));

jest.mock("../../store/slices/communitySlice", () => ({
  useGetCommunityDetailsQuery: (arg: any, opts: any) =>
    mockGetCommunityDetails(arg, opts),
}));

const followersRefetch = jest.fn();
const followingsRefetch = jest.fn();
const visitorsRefetch = jest.fn();

const idle = {
  data: undefined,
  isLoading: false,
  isFetching: false,
  error: undefined,
};
const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({ unwrap: () => Promise.reject(new Error("nope")) });

function person(id: string, name: string, extra: any = {}) {
  return {
    _id: id,
    name,
    imageUrls: [],
    native_language: "Korean",
    language_to_learn: "English",
    ...extra,
  };
}

function renderList(path: string, viewerId: string | null = "me") {
  const store = configureStore({
    reducer: {
      auth: (
        state: any = {
          userInfo: viewerId ? { user: { _id: viewerId } } : null,
        },
      ) => state,
    },
  });
  return render(
    <Provider store={store}>
      <HelmetProvider>
        <MemoryRouter initialEntries={[path]}>
          <Routes>
            <Route path="/followersList" element={<UserListPage />} />
            <Route path="/followingsList" element={<UserListPage />} />
            <Route path="/visitors" element={<UserListPage />} />
            <Route path="/visited" element={<UserListPage />} />
            <Route
              path="/profile/:userId/followers"
              element={<UserListPage />}
            />
            <Route
              path="/profile/:userId/following"
              element={<UserListPage />}
            />
            <Route path="/login" element={<div data-testid="login-screen" />} />
          </Routes>
        </MemoryRouter>
      </HelmetProvider>
    </Provider>,
  );
}

beforeEach(() => {
  mockGetFollowers.mockReturnValue({ ...idle, refetch: followersRefetch });
  mockGetFollowings.mockReturnValue({ ...idle, refetch: followingsRefetch });
  mockGetVisitors.mockReturnValue({ ...idle, refetch: visitorsRefetch });
  mockGetVisited.mockReturnValue({ ...idle, refetch: jest.fn() });
  mockGetVipStatus.mockReturnValue({ ...idle });
  mockClearVisitors.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
  mockGetCommunityDetails.mockReturnValue({ ...idle });
  mockFollow.mockReturnValue(resolved());
  mockUnfollow.mockReturnValue(resolved());
});

afterEach(() => {
  jest.clearAllMocks();
});

describe("tabs", () => {
  it("selects Followers on /followersList and asks only for that list", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 1, data: [person("u2", "Ada")] },
    });

    renderList("/followersList", "me");

    expect(screen.getByTestId("tab-followers")).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(screen.getByTestId("tab-followers")).toHaveAttribute(
      "href",
      "/followersList",
    );
    expect(mockGetFollowers.mock.calls[0][0]).toEqual({ userId: "me" });
    expect(mockGetFollowers.mock.calls[0][1].skip).toBe(false);
    // The other two lists are not fetched until their tab is open.
    expect(mockGetVisitors.mock.calls[0][1].skip).toBe(true);
  });

  it("selects Following on /followingsList", () => {
    renderList("/followingsList", "me");

    expect(screen.getByTestId("tab-following")).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(mockGetFollowers.mock.calls[0][1].skip).toBe(true);
    const forOwner = mockGetFollowings.mock.calls.filter(
      (call: any[]) => !call[1].skip,
    );
    expect(forOwner.length).toBeGreaterThan(0);
  });

  it("selects Visitors on /visitors", () => {
    renderList("/visitors", "me");

    expect(screen.getByTestId("tab-visitors")).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(mockGetVisitors.mock.calls[0][1].skip).toBe(false);
  });

  it("offers no Visitors tab on another person's lists, and names them", () => {
    mockGetCommunityDetails.mockReturnValue({
      ...idle,
      data: { data: { _id: "u9", name: "Ada" } },
    });

    renderList("/profile/u9/followers", "me");

    expect(screen.queryByTestId("tab-visitors")).not.toBeInTheDocument();
    expect(screen.getByTestId("tab-followers")).toHaveAttribute(
      "href",
      "/profile/u9/followers",
    );
    expect(screen.getByTestId("tab-following")).toHaveAttribute(
      "href",
      "/profile/u9/following",
    );
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Ada");
    // Another person's list, so their id -- not the viewer's -- is fetched.
    expect(mockGetFollowers.mock.calls[0][0]).toEqual({ userId: "u9" });
  });
});

it("lets the tab bar scroll instead of widening the page on a phone", () => {
  renderList("/visitors", "me");
  const nav = screen.getByTestId("list-tabs");
  expect(nav.className).toContain("overflow-x-auto");
  // A tab that can shrink wraps its label and pushes the row wider instead.
  expect(screen.getByTestId("tab-visitors").className).toContain("shrink-0");
  expect(screen.getByTestId("tab-visitors").className).toContain("whitespace-nowrap");
});

describe("rows", () => {
  it("links each person to their profile and shows their language pair", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 2, data: [person("u2", "Ada"), person("u3", "Grace")] },
    });

    renderList("/followersList", "me");

    expect(screen.getByTestId("list-row-u2")).toBeInTheDocument();
    expect(screen.getByTestId("list-name-u2")).toHaveAttribute(
      "href",
      "/profile/u2",
    );
    expect(screen.getAllByTestId("language-pill").length).toBe(2);
    // No photo on either person: initials, never a broken image.
    expect(screen.getAllByTestId("avatar-initials").length).toBe(2);
  });

  // `aria-hidden` on something that can still be focused or clicked is a WCAG
  // 4.1.2 violation. The avatar link stays in the accessibility tree and out of
  // the tab order instead.
  it("keeps the avatar link out of the tab order without hiding it", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 1, data: [person("u2", "Ada")] },
    });

    renderList("/followersList", "me");
    const row = screen.getByTestId("list-row-u2");
    const links = row.querySelectorAll('a[href="/profile/u2"]');
    expect(links.length).toBe(2);
    links.forEach((link) => expect(link).not.toHaveAttribute("aria-hidden"));
    expect(links[0]).toHaveAttribute("tabindex", "-1");
    expect(screen.getByTestId("list-name-u2")).not.toHaveAttribute("tabindex");
  });

  // The followers/following/visitors populate does not select `languageLevel`,
  // so the rows must not pretend to know it: the pill renders its language
  // pair without CEFR dots.
  it("draws no CEFR dots on a list row", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 1, data: [person("u2", "Ada", { languageLevel: "C1" })] },
    });

    renderList("/followersList", "me");
    expect(screen.getByTestId("language-pill")).toBeInTheDocument();
    expect(screen.queryAllByTestId("language-pill-dot")).toHaveLength(0);
  });

  it("gives the viewer's own row no follow button", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 2, data: [person("me", "Me"), person("u2", "Ada")] },
    });

    renderList("/followersList", "me");

    expect(screen.queryByTestId("list-follow-me")).not.toBeInTheDocument();
    expect(screen.getByTestId("list-follow-u2")).toBeInTheDocument();
  });

  it("reads the follow state from the viewer's own following list", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 2, data: [person("u2", "Ada"), person("u3", "Grace")] },
    });
    mockGetFollowings.mockReturnValue({
      ...idle,
      refetch: followingsRefetch,
      data: { count: 1, data: [person("u3", "Grace")] },
    });

    renderList("/followersList", "me");

    expect(screen.getByTestId("list-follow-u2")).toHaveAttribute(
      "aria-pressed",
      "false",
    );
    expect(screen.getByTestId("list-follow-u3")).toHaveAttribute(
      "aria-pressed",
      "true",
    );
  });

  it("follows optimistically and rolls back when the server refuses", async () => {
    mockFollow.mockReturnValue(rejected());
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 1, data: [person("u2", "Ada")] },
    });

    renderList("/followersList", "me");

    fireEvent.click(screen.getByTestId("list-follow-u2"));
    expect(mockFollow).toHaveBeenCalledWith({
      userId: "me",
      targetUserId: "u2",
    });
    expect(screen.getByTestId("list-follow-u2")).toHaveAttribute(
      "aria-pressed",
      "true",
    );

    await waitFor(() =>
      expect(screen.getByTestId("list-follow-u2")).toHaveAttribute(
        "aria-pressed",
        "false",
      ),
    );
  });
});

describe("search", () => {
  it("filters the list by name without asking the server again", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 2, data: [person("u2", "Ada"), person("u3", "Grace")] },
    });

    renderList("/followersList", "me");
    const callsBefore = mockGetFollowers.mock.calls.length;

    fireEvent.change(screen.getByTestId("list-search"), {
      target: { value: "gra" },
    });

    expect(screen.queryByTestId("list-row-u2")).not.toBeInTheDocument();
    expect(screen.getByTestId("list-row-u3")).toBeInTheDocument();
    expect(mockGetFollowers.mock.calls.length).toBeGreaterThanOrEqual(
      callsBefore,
    );
    expect(
      mockGetFollowers.mock.calls[mockGetFollowers.mock.calls.length - 1][0],
    ).toEqual({
      userId: "me",
    });
  });

  // The heading counter sits next to the list it counts; with a filter active
  // the unfiltered total contradicts the rows on screen.
  it("counts what the list actually shows while a search is active", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 2, data: [person("u2", "Ada"), person("u3", "Grace")] },
    });

    renderList("/followersList", "me");
    expect(screen.getByTestId("list-count")).toHaveTextContent("2");

    fireEvent.change(screen.getByTestId("list-search"), {
      target: { value: "gra" },
    });
    expect(screen.getByTestId("list-count")).toHaveTextContent("1");
  });

  it("says so when the search matches nobody, without claiming the list is empty", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 1, data: [person("u2", "Ada")] },
    });

    renderList("/followersList", "me");
    fireEvent.change(screen.getByTestId("list-search"), {
      target: { value: "zzz" },
    });

    expect(screen.getByTestId("list-search-empty")).toBeInTheDocument();
    expect(screen.queryByTestId("list-empty")).not.toBeInTheDocument();
  });
});

describe("states", () => {
  it("shows skeleton rows while the list loads", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      isLoading: true,
    });

    renderList("/followersList", "me");

    expect(screen.getByTestId("list-skeleton")).toBeInTheDocument();
    expect(screen.queryByTestId("list-empty")).not.toBeInTheDocument();
  });

  it("offers a retry that refetches the open tab", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      error: { status: 500 },
    });

    renderList("/followersList", "me");

    expect(screen.getByTestId("list-error")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("list-retry"));
    expect(followersRefetch).toHaveBeenCalled();
  });

  it("has an empty state of its own per tab", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 0, data: [] },
    });

    const { unmount } = renderList("/followersList", "me");
    const followersCopy = screen.getByTestId("list-empty").textContent;
    unmount();

    mockGetFollowings.mockReturnValue({
      ...idle,
      refetch: followingsRefetch,
      data: { count: 0, data: [] },
    });
    renderList("/followingsList", "me");

    expect(screen.getByTestId("list-empty").textContent).not.toBe(
      followersCopy,
    );
  });
});

describe("visitors", () => {
  // Who may see this list is the server's ruling, and it sends it: `locked` is
  // the NUMBER of visitors it withheld, 0 when it withheld none. The page used
  // to decide for itself from the VIP status endpoint and skip the request
  // whenever that said no — which locked out everyone the server would have
  // let in by another door: an active `who_waved` grant (24h, bought with
  // coins) and a VIP inside the expiry grace period both open the list in
  // `controllers/profileVisits.js` and neither shows up as `isActive`.
  const teaser = (locked: number, rows = 1) => ({
    ...idle,
    refetch: visitorsRefetch,
    locked,
    data: {
      count: rows,
      locked,
      stats: { totalVisits: 42, uniqueVisitors: 17 },
      data: Array.from({ length: rows }, (unused, i) => ({
        user: person(`u${i + 5}`, `Lin${i}`),
        lastVisit: new Date().toISOString(),
        visitCount: 1,
        source: "search",
      })),
    },
  });

  it("asks for the list whatever the client believes about VIP", () => {
    renderList("/visitors", "me");
    expect(mockGetVisitors.mock.calls[0][1].skip).toBe(false);
  });

  it("locks on the count the server withheld, and points at the VIP page", () => {
    mockGetVisitors.mockReturnValue(teaser(16));
    renderList("/visitors", "me");

    expect(screen.getByTestId("visitors-locked")).toBeInTheDocument();
    expect(screen.getByTestId("visitors-vip-link")).toHaveAttribute(
      "href",
      "/settings/vip",
    );
  });

  it("still shows the teaser the paywall is built on", () => {
    // Free accounts get the counters and the single most recent visitor —
    // "the primary paywall in the monetization spec". Hiding them left the
    // upsell arguing for something the reader had seen no evidence of.
    mockGetVisitors.mockReturnValue(teaser(16));
    renderList("/visitors", "me");

    expect(screen.getByTestId("list-row-u5")).toBeInTheDocument();
    expect(screen.getByTestId("visitor-stat-uniqueVisitors")).toHaveTextContent("17");
  });

  it("unlocks on the server's word alone, with no VIP signal of its own", () => {
    // A who_waved grant or a grace-period VIP: `isActive` is false, the server
    // still returns the whole list.
    mockGetVisitors.mockReturnValue(teaser(0, 2));
    renderList("/visitors", "me");

    expect(screen.queryByTestId("visitors-locked")).not.toBeInTheDocument();
    expect(screen.getByTestId("list-row-u5")).toBeInTheDocument();
    expect(screen.getByTestId("list-row-u6")).toBeInTheDocument();
  });

  it("does not call it locked while the list is still loading", () => {
    mockGetVisitors.mockReturnValue({ ...idle, isLoading: true, refetch: visitorsRefetch });
    renderList("/visitors", "me");
    expect(screen.queryByTestId("visitors-locked")).not.toBeInTheDocument();
  });

  it("lists the visitors for a VIP account", () => {
    mockGetVisitors.mockReturnValue({
      ...idle,
      refetch: visitorsRefetch,
      data: {
        count: 1,
        locked: 0,
        data: [
          {
            user: person("u5", "Lin"),
            lastVisit: new Date().toISOString(),
            visitCount: 2,
            source: "search",
          },
        ],
      },
    });

    renderList("/visitors", "me");

    expect(screen.queryByTestId("visitors-locked")).not.toBeInTheDocument();
    expect(screen.getByTestId("list-row-u5")).toBeInTheDocument();
    expect(screen.getByTestId("list-name-u5")).toHaveAttribute(
      "href",
      "/profile/u5",
    );
  });

  describe("clearing the history", () => {
    // DELETE /me/visitors deletes every ProfileVisit row pointing at the owner
    // and zeroes profileStats. Irreversible, so it asks first.
    const withRows = () =>
      mockGetVisitors.mockReturnValue({
        ...idle,
        refetch: visitorsRefetch,
        data: {
          count: 1,
          locked: 0,
          stats: { totalVisits: 42, uniqueVisitors: 17 },
          data: [{ user: person("u5", "Lin"), lastVisit: new Date().toISOString() }],
        },
      });

    it("offers the control only once there is something to clear", () => {
      mockGetVisitors.mockReturnValue({
        ...idle,
        refetch: visitorsRefetch,
        data: { count: 0, locked: 0, data: [] },
      });
      renderList("/visitors", "me");
      expect(screen.queryByTestId("visitors-clear")).not.toBeInTheDocument();

      withRows();
      renderList("/visitors", "me");
      expect(screen.getAllByTestId("visitors-clear").length).toBeGreaterThan(0);
    });

    it("asks before deleting, and does nothing if the answer is no", () => {
      withRows();
      renderList("/visitors", "me");
      fireEvent.click(screen.getByTestId("visitors-clear"));
      expect(screen.getByTestId("confirm-dialog-cancel")).toBeInTheDocument();
      fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
      expect(mockClearVisitors).not.toHaveBeenCalled();
    });

    it("clears and refetches once the answer is yes", async () => {
      withRows();
      renderList("/visitors", "me");
      fireEvent.click(screen.getByTestId("visitors-clear"));
      fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));

      await waitFor(() => expect(mockClearVisitors).toHaveBeenCalledTimes(1));
      await waitFor(() => expect(visitorsRefetch).toHaveBeenCalled());
    });

    it("keeps the control off the followers and following tabs", () => {
      renderList("/followersList", "me");
      expect(screen.queryByTestId("visitors-clear")).not.toBeInTheDocument();
    });
  });

  it("keeps counting days on an old visit instead of printing a date", () => {
    // This page's relative time now comes from src/utils/timeAgo.ts, shared
    // with the comments and the story sheets. Its `beyondWeek: "days"` option
    // is what preserves this screen's own behaviour: here the distance is the
    // point, so a visit from last spring reads "400d", not a calendar date.
    mockGetVisitors.mockReturnValue({
      ...idle,
      refetch: visitorsRefetch,
      data: {
        count: 2,
        locked: 0,
        data: [
          {
            user: person("u5", "Lin"),
            lastVisit: new Date(Date.now() - 400 * 24 * 3600 * 1000).toISOString(),
            visitCount: 1,
            source: "search",
          },
          {
            user: person("u6", "Mo"),
            lastVisit: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
            visitCount: 1,
            source: "search",
          },
        ],
      },
    });

    renderList("/visitors", "me");

    expect(screen.getByTestId("list-row-u5")).toHaveTextContent("400d");
    expect(screen.getByTestId("list-row-u6")).toHaveTextContent("30m");
  });

  it("shows the counters the endpoint sent, and only those", () => {
    mockGetVisitors.mockReturnValue({
      ...idle,
      refetch: visitorsRefetch,
      data: {
        locked: 0,
        data: [{ user: person("u5", "Lin"), lastVisit: new Date().toISOString() }],
        // visitsThisWeek absent on purpose: an omitted field gets no tile.
        stats: { totalVisits: 42, uniqueVisitors: 17, visitsToday: 3 },
      },
    });

    renderList("/visitors", "me");

    expect(screen.getByTestId("visitor-stat-totalVisits")).toHaveTextContent("42");
    expect(screen.getByTestId("visitor-stat-uniqueVisitors")).toHaveTextContent("17");
    expect(screen.getByTestId("visitor-stat-visitsToday")).toHaveTextContent("3");
    expect(screen.queryByTestId("visitor-stat-visitsThisWeek")).not.toBeInTheDocument();
  });

  it("renders no stats row when the response carries no stats", () => {
    mockGetVisitors.mockReturnValue({
      ...idle,
      refetch: visitorsRefetch,
      data: { data: [{ user: person("u5", "Lin") }] },
    });

    renderList("/visitors", "me");

    expect(screen.queryByTestId("visitor-stats")).not.toBeInTheDocument();
  });

  it("keeps the stats row off the followers and following tabs", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { data: [person("u5", "Lin")], stats: { totalVisits: 42 } },
    });

    renderList("/followersList", "me");

    expect(screen.queryByTestId("visitor-stats")).not.toBeInTheDocument();
  });
});

describe("signed out", () => {
  it("sends a visitor with no session to the login page", () => {
    renderList("/followersList", null);

    expect(screen.getByTestId("login-screen")).toBeInTheDocument();
  });

  it("still renders another person's list for a signed-out visitor", () => {
    mockGetFollowers.mockReturnValue({
      ...idle,
      refetch: followersRefetch,
      data: { count: 1, data: [person("u2", "Ada")] },
    });

    renderList("/profile/u9/followers", null);

    expect(screen.queryByTestId("login-screen")).not.toBeInTheDocument();
    expect(screen.getByTestId("list-row-u2")).toBeInTheDocument();
    // Nobody to follow as: no button rather than one that bounces to login.
    expect(screen.queryByTestId("list-follow-u2")).not.toBeInTheDocument();
  });
});

// GET /me/visited-profiles existed with a generated hook and no caller. The
// app lists the profiles you looked at; the web had no way to find someone
// again whose profile you had opened and lost.
describe("profiles I visited", () => {
  it("is its own tab, on the own lists only", () => {
    renderList("/visited", "me");
    expect(screen.getByTestId("tab-visited")).toHaveAttribute("aria-current", "page");
    expect(mockGetVisited.mock.calls[0][1].skip).toBe(false);
  });

  it("lists who you looked at, newest first, linking to them", () => {
    mockGetVisited.mockReturnValue({
      ...idle,
      refetch: jest.fn(),
      data: {
        count: 2,
        data: [
          { user: person("u7", "Kim"), visitedAt: new Date(Date.now() - 5 * 60000).toISOString() },
          { user: person("u8", "Lee"), visitedAt: new Date(Date.now() - 3 * 86400000).toISOString() },
        ],
      },
    });
    renderList("/visited", "me");

    expect(screen.getByTestId("list-name-u7")).toHaveAttribute("href", "/profile/u7");
    expect(screen.getByTestId("list-row-u7")).toHaveTextContent("5m");
    expect(screen.getByTestId("list-row-u8")).toHaveTextContent("3d");
  });

  it("is not paywalled, and offers no clear-history control", () => {
    mockGetVisited.mockReturnValue({
      ...idle,
      refetch: jest.fn(),
      data: { data: [{ user: person("u7", "Kim"), visitedAt: new Date().toISOString() }] },
    });
    renderList("/visited", "me");
    expect(screen.queryByTestId("visitors-locked")).not.toBeInTheDocument();
    expect(screen.queryByTestId("visitors-clear")).not.toBeInTheDocument();
    expect(screen.queryByTestId("visitor-stats")).not.toBeInTheDocument();
  });

  it("is not offered on someone else's lists", () => {
    mockGetCommunityDetails.mockReturnValue({ ...idle, data: { data: { name: "Ada" } } });
    renderList("/profile/u2/followers", "me");
    expect(screen.queryByTestId("tab-visited")).not.toBeInTheDocument();
  });
});
