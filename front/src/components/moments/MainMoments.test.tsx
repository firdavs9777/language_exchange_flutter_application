import "@testing-library/jest-dom";
import { fireEvent, render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import MainMoments from "./MainMoments";
import { clearPrerendered, markPrerendered } from "../../seo/prerender/hydrationFlag";
import { mockAppConfig, ALL_WEB_FLAGS_OFF, ALL_WEB_FLAGS_ON } from "../../utils/testing/mockWebFlags";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../../store/slices/appConfigSlice", () => require("../../utils/testing/mockWebFlags").appConfigSliceMock());

jest.mock("../stories/StoriesFeed", () => () => null);
jest.mock("../ads/AdUnit", () => () => null);
jest.mock("./SingleMoment", () => (props: any) => <article>{props.title}</article>);

const pagination = (page = 1) => ({
  currentPage: page,
  totalPages: 1,
  totalMoments: 0,
  limit: 10,
  hasNextPage: false,
  hasPrevPage: false,
  nextPage: null,
  prevPage: null,
});

const emptyFeedResult = () => ({
  data: { moments: [], pagination: pagination() },
  isLoading: false,
  error: null,
  refetch: jest.fn(),
});

// CRA's default jest config sets `resetMocks: true`, which wipes any
// `mockImplementation` before *every* test (including the first). So the
// implementations below are (re)installed in `beforeEach`, not at module
// scope, and the query results they read (`forYouResult`/`followingResult`)
// are plain `let`s each test can override before rendering.
const mockUseGetMomentsQuery = jest.fn();
const mockUseGetTrendingMomentsQuery = jest.fn();
const mockUseGetExploreMomentsQuery = jest.fn();
const mockUseGetPromptOfDayQuery = jest.fn();

jest.mock("../../store/slices/momentsSlice", () => ({
  useGetMomentsQuery: (...args: any[]) => mockUseGetMomentsQuery(...args),
  useGetTrendingMomentsQuery: (...args: any[]) =>
    mockUseGetTrendingMomentsQuery(...args),
  useGetExploreMomentsQuery: (...args: any[]) =>
    mockUseGetExploreMomentsQuery(...args),
  useGetPromptOfDayQuery: (...args: any[]) =>
    mockUseGetPromptOfDayQuery(...args),
}));

function makeStore(user?: any) {
  return configureStore({
    reducer: {
      auth: (state: any = { userInfo: user ? { user } : undefined }) => state,
    },
  });
}

function renderMainMoments(user?: any, url = "/moments") {
  return render(
    <Provider store={makeStore(user)}>
      <MemoryRouter initialEntries={[url]}>
        <MainMoments />
      </MemoryRouter>
    </Provider>
  );
}

let forYouResult: any;
let followingResult: any;

beforeEach(() => {
  mockAppConfig(ALL_WEB_FLAGS_OFF);
  forYouResult = emptyFeedResult();
  followingResult = emptyFeedResult();

  mockUseGetMomentsQuery.mockImplementation((args: any) =>
    args && args.feed === "following" ? followingResult : forYouResult
  );
  mockUseGetTrendingMomentsQuery.mockImplementation(() => emptyFeedResult());
  mockUseGetExploreMomentsQuery.mockImplementation(() => emptyFeedResult());
  mockUseGetPromptOfDayQuery.mockImplementation(() => ({
    data: undefined,
    error: undefined,
  }));
});

const loggedInUser = { _id: "u1", name: "Ada", imageUrls: [] };

it("does not show a Following tab when logged out", () => {
  renderMainMoments();
  expect(
    screen.queryByRole("tab", { name: /Following/i })
  ).not.toBeInTheDocument();
});

it("shows a Following tab when logged in", () => {
  renderMainMoments(loggedInUser);
  expect(screen.getByRole("tab", { name: /Following/i })).toBeInTheDocument();
});

it("queries the following feed (page 1, skip:false) once the tab is selected", () => {
  renderMainMoments(loggedInUser);
  fireEvent.click(screen.getByRole("tab", { name: /Following/i }));

  expect(mockUseGetMomentsQuery).toHaveBeenCalledWith(
    { page: 1, limit: expect.any(Number), feed: "following" },
    { skip: false }
  );
});

it("shows the empty state with a link to /communities when the following feed has no moments", () => {
  renderMainMoments(loggedInUser);
  fireEvent.click(screen.getByRole("tab", { name: /Following/i }));

  expect(
    screen.getByText("Follow people to see their moments here")
  ).toBeInTheDocument();
  const link = screen.getByRole("link", { name: "Find people" });
  expect(link).toHaveAttribute("href", "/communities");
});

const moment = (id: string) => ({
  _id: id,
  title: `Moment ${id}`,
  description: "d",
  likeCount: 0,
  commentCount: 0,
  user: { _id: "a1", name: "Author" },
  likedUsers: [],
  imageUrls: [],
  createdAt: "2026-10-01T00:00:00.000Z",
});

const lastArgs = (mock: jest.Mock) => mock.mock.calls[mock.mock.calls.length - 1][0];

describe("filters run on the server", () => {
  it("a shared link's filters reach the For You query", () => {
    renderMainMoments(undefined, "/moments?lang=ko&q=kimchi&cat=food");
    expect(lastArgs(mockUseGetMomentsQuery)).toEqual(
      expect.objectContaining({ page: 1, filters: { category: "food", language: "ko", q: "kimchi" } })
    );
  });

  it("the same filters follow the reader to Trending and Explore", () => {
    renderMainMoments(undefined, "/moments?mood=happy");
    fireEvent.click(screen.getByRole("tab", { name: /Trending/i }));
    expect(lastArgs(mockUseGetTrendingMomentsQuery)).toEqual(
      expect.objectContaining({ filters: { mood: "happy" } })
    );
    fireEvent.click(screen.getByRole("tab", { name: /Explore/i }));
    expect(lastArgs(mockUseGetExploreMomentsQuery)).toEqual(
      expect.objectContaining({ filters: { mood: "happy" } })
    );
  });

  it("an unfiltered feed sends no filters (the prerender cache key stays put)", () => {
    renderMainMoments();
    expect(lastArgs(mockUseGetMomentsQuery).filters).toBeUndefined();
  });

  it("pages come from the server's total, not the ten moments on screen", () => {
    forYouResult = {
      ...emptyFeedResult(),
      data: {
        moments: Array.from({ length: 10 }, (_, i) => moment(`m${i}`)),
        pagination: { ...pagination(1), totalPages: 3, totalMoments: 27, hasNextPage: true },
      },
    };
    renderMainMoments();
    expect(screen.getAllByText("Moment m0").length).toBeGreaterThan(0);
    expect(screen.getByRole("button", { name: "3" })).toBeInTheDocument();
  });

  it("changing a filter on page 2 asks for page 1", () => {
    forYouResult = {
      ...emptyFeedResult(),
      data: {
        moments: [moment("m1")],
        pagination: { ...pagination(1), totalPages: 3, totalMoments: 27, hasNextPage: true },
      },
    };
    renderMainMoments();
    fireEvent.click(screen.getByRole("button", { name: "2" }));
    expect(lastArgs(mockUseGetMomentsQuery).page).toBe(2);
    fireEvent.click(screen.getByRole("button", { name: /Filters/i }));
    fireEvent.change(screen.getByLabelText("Mood"), { target: { value: "sad" } });
    expect(lastArgs(mockUseGetMomentsQuery)).toEqual(
      expect.objectContaining({ page: 1, filters: { mood: "sad" } })
    );
  });

  it("nothing matching shows its own empty state, and Clear filters clears them", () => {
    renderMainMoments(undefined, "/moments?cat=music");
    expect(screen.getByText("No moments match these filters")).toBeInTheDocument();
    fireEvent.click(screen.getAllByRole("button", { name: /Clear filters/i })[0]);
    expect(lastArgs(mockUseGetMomentsQuery).filters).toBeUndefined();
  });

  it("the search box submits to q", () => {
    renderMainMoments();
    fireEvent.click(screen.getByRole("button", { name: /Filters/i }));
    fireEvent.change(screen.getByRole("searchbox"), { target: { value: "  서울 " } });
    fireEvent.click(screen.getByRole("button", { name: "Search" }));
    expect(lastArgs(mockUseGetMomentsQuery).filters).toEqual({ q: "서울" });
  });
});

it("no client-side filtering remains", () => {
  const source = require("fs").readFileSync(require("path").join(__dirname, "MainMoments.tsx"), "utf8");
  expect(source).not.toMatch(/filteredMoments|paginatedMoments|filteredPagination/);
});

describe("a shared filtered link on the prerendered page", () => {
  afterEach(() => clearPrerendered());

  it("hydrates the unfiltered markup first, then applies the URL's filters", () => {
    markPrerendered();
    renderMainMoments(undefined, "/moments?lang=ko");
    expect(mockUseGetMomentsQuery.mock.calls[0][0].filters).toBeUndefined();
    expect(lastArgs(mockUseGetMomentsQuery).filters).toEqual({ language: "ko" });
  });

  it("a page the client rendered itself filters from the first render", () => {
    renderMainMoments(undefined, "/moments?lang=ko");
    expect(mockUseGetMomentsQuery.mock.calls[0][0].filters).toEqual({ language: "ko" });
  });
});

it("offers no Reels link while the flag is off", () => {
  renderMainMoments(loggedInUser);
  expect(screen.queryByTestId("moments-reels-link")).not.toBeInTheDocument();
});

it("links to /reels for a signed-in user once the flag is on", () => {
  mockAppConfig(ALL_WEB_FLAGS_ON);
  renderMainMoments(loggedInUser);
  expect(screen.getByTestId("moments-reels-link")).toHaveAttribute("href", "/reels");
});
