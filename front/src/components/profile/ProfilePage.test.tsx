import fs from "fs";
import path from "path";
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor, within } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { HelmetProvider } from "react-helmet-async";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ProfilePage from "./ProfilePage";

// react-helmet-async hands back a null server context under jsdom unless
// canUseDOM is forced false -- the same trick NotFound.test.tsx uses to read
// the rendered tags back out of renderToString.
HelmetProvider.canUseDOM = false;

const mockGetUserProfile = jest.fn();
const mockGetPublicProfile = jest.fn();
const mockGetMyMoments = jest.fn();
const mockFollow = jest.fn();
const mockUnfollow = jest.fn();
const mockBlock = jest.fn();
const mockReport = jest.fn();
const mockRecordVisit = jest.fn();
const mockGetCommunityMembers = jest.fn();
const mockSendWave = jest.fn();
const mockGetUserHighlights = jest.fn();
const mockNavigate = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useGetUserProfileQuery: (arg: any, opts: any) => mockGetUserProfile(arg, opts),
  useFollowUserMutation: () => [mockFollow, { isLoading: false }],
  useUnFollowUserMutation: () => [mockUnfollow, { isLoading: false }],
  useBlockUserMutation: () => [mockBlock, { isLoading: false }],
  useUnblockUserMutation: () => [jest.fn(), { isLoading: false }],
  useReportUserMutation: () => [mockReport, { isLoading: false }],
  useRecordProfileVisitMutation: () => [mockRecordVisit, { isLoading: false }],
  // ProfileActions asks whether the viewer already blocked this person.
  useGetBlockStatusQuery: () => ({ data: undefined }),
}));

jest.mock("../../store/slices/communitySlice", () => ({
  useGetPublicUserProfileQuery: (arg: any, opts: any) => mockGetPublicProfile(arg, opts),
  useGetCommunityMembersQuery: (arg: any, opts: any) => mockGetCommunityMembers(arg, opts),
  useSendWaveMutation: () => [mockSendWave, { isLoading: false }],
}));

jest.mock("../../store/slices/momentsSlice", () => ({
  useGetMyMomentsQuery: (arg: any, opts: any) => mockGetMyMoments(arg, opts),
}));

jest.mock("../../store/slices/chatSlice", () => ({
}));

// The highlights rail is a real child here (it is what decides whether the
// section appears at all), so only its one query is stubbed.
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetUserHighlightsQuery: (arg: any, opts: any) => mockGetUserHighlights(arg, opts),
}));

const ownRefetch = jest.fn();
const otherRefetch = jest.fn();
const momentsRefetch = jest.fn();

const idle = { data: undefined, isLoading: false, isFetching: false, error: undefined };
const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });

/** Reads the live URL back out of the router, for the tab assertions. */
const LocationProbe: React.FC = () => {
  const location = useLocation();
  return <div data-testid="location-search">{location.search}</div>;
};

function page(path: string, viewerId: string | null) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: viewerId ? { user: { _id: viewerId } } : null }) => state,
    },
  });
  return (
    <Provider store={store}>
      <HelmetProvider>
        <MemoryRouter initialEntries={[path]}>
          <LocationProbe />
          <Routes>
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/profile/:userId" element={<ProfilePage />} />
            <Route path="/login" element={<div data-testid="login-screen" />} />
          </Routes>
        </MemoryRouter>
      </HelmetProvider>
    </Provider>
  );
}

function renderPage(path: string = "/profile", viewerId: string | null = "me") {
  return render(page(path, viewerId));
}

beforeEach(() => {
  mockGetUserProfile.mockReturnValue({ ...idle, refetch: ownRefetch });
  mockGetPublicProfile.mockReturnValue({ ...idle, refetch: otherRefetch });
  mockGetMyMoments.mockReturnValue({ ...idle, refetch: momentsRefetch });
  mockGetCommunityMembers.mockReturnValue({ ...idle });
  mockGetUserHighlights.mockReturnValue({ ...idle });
  mockBlock.mockReturnValue(resolved());
  mockFollow.mockReturnValue(resolved());
  mockUnfollow.mockReturnValue(resolved());
  mockReport.mockReturnValue(resolved());
  mockRecordVisit.mockReturnValue(resolved());
});

afterEach(() => {
  jest.clearAllMocks();
});

describe("own profile", () => {
  it("reads the signed-in user from the store when the route has no id", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", username: "me", native_language: "Korean" } },
    });

    renderPage("/profile", "me");

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Me");
    // Own profile: edit + settings, never the social actions.
    expect(screen.getByTestId("action-edit-profile")).toBeInTheDocument();
    expect(screen.queryByTestId("action-follow")).not.toBeInTheDocument();
    // The other-user endpoint is never asked.
    expect(mockGetPublicProfile.mock.calls[0][1].skip).toBe(true);
  });

  it("feeds the header badge row from the user document", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: {
        data: {
          _id: "me",
          name: "Me",
          userMode: "vip",
          isEmailVerified: true,
          createdAt: "2024-03-02T00:00:00.000Z",
        },
      },
    });

    renderPage("/profile", "me");

    expect(screen.getByTestId("badge-vip")).toBeInTheDocument();
    expect(screen.getByTestId("badge-verified")).toBeInTheDocument();
    expect(screen.getByTestId("badge-joined")).toBeInTheDocument();
  });
});

describe("another person's profile", () => {
  it("renders from the route param with the social actions", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", followers: ["me"] } },
    });

    renderPage("/profile/u2", "me");

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Ada");
    expect(screen.getByTestId("action-message")).toBeInTheDocument();
    // isFollowing comes from the target's followers list.
    expect(screen.getByTestId("action-follow")).toHaveAttribute("aria-pressed", "true");
    expect(mockGetUserProfile.mock.calls[0][1].skip).toBe(true);
  });

  it("records the visit, which is what fills the owner's visitors list", async () => {
    // The mutation and its hook existed in usersSlice from the start and had
    // no caller, so no visit from the web was ever recorded — an app user's
    // visitors list could only contain app users.
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2", "me");

    await waitFor(() => expect(mockRecordVisit).toHaveBeenCalledWith("u2"));
  });

  it("records nothing on an own profile or for a signed-out reader", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me" } },
    });
    renderPage("/profile", "me");
    expect(mockRecordVisit).not.toHaveBeenCalled();

    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });
    renderPage("/profile/u2", null);
    expect(mockRecordVisit).not.toHaveBeenCalled();
  });

  it("asks for the profile's moments with the same argument the hook uses", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2", "me");

    // Every call -- the hook's and the section's -- must carry the identical
    // argument or RTK Query issues two requests instead of one.
    mockGetMyMoments.mock.calls.forEach((call: any[]) => {
      expect(call[0]).toEqual({ userId: "u2" });
    });
  });
});

describe("states", () => {
  it("shows a skeleton in the shape of the page while it loads", () => {
    mockGetUserProfile.mockReturnValue({ ...idle, refetch: ownRefetch, isLoading: true });

    renderPage("/profile", "me");

    expect(screen.getByTestId("profile-skeleton")).toBeInTheDocument();
    expect(screen.queryByTestId("profile-body")).not.toBeInTheDocument();
    expect(screen.queryByTestId("profile-error")).not.toBeInTheDocument();
  });

  it("offers a retry that refetches the profile", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      error: { status: 500 },
    });

    renderPage("/profile", "me");

    expect(screen.getByTestId("profile-error")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("profile-retry"));
    expect(ownRefetch).toHaveBeenCalled();
    expect(momentsRefetch).toHaveBeenCalled();
  });

  it("treats a 404 as not found and points back at the community", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      error: { status: 404 },
    });

    renderPage("/profile/u2", "me");

    expect(screen.queryByTestId("profile-error")).not.toBeInTheDocument();
    expect(screen.getByTestId("profile-not-found")).toBeInTheDocument();
    expect(screen.getByTestId("profile-back-to-community")).toHaveAttribute("href", "/communities");
  });

  it("sends a signed-out visitor to the login page instead of a not-found card", () => {
    renderPage("/profile", null);

    expect(screen.getByTestId("login-screen")).toBeInTheDocument();
    expect(screen.queryByTestId("profile-not-found")).not.toBeInTheDocument();
  });

  it("still shows another person's profile to a signed-out visitor", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2", null);

    expect(screen.queryByTestId("login-screen")).not.toBeInTheDocument();
    expect(screen.getByTestId("profile-body")).toBeInTheDocument();
  });

  it("is not found when the request succeeded with no user", () => {
    mockGetPublicProfile.mockReturnValue({ ...idle, refetch: otherRefetch, data: { data: null } });

    renderPage("/profile/u2", "me");

    expect(screen.getByTestId("profile-not-found")).toBeInTheDocument();
  });
});

describe("moderation", () => {
  it("leaves the blocked person's profile for the community", async () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2", "me");

    fireEvent.click(screen.getByTestId("action-more"));
    fireEvent.click(screen.getByTestId("action-block"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));

    await waitFor(() => expect(mockBlock).toHaveBeenCalledWith("u2"));
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/communities"));
  });
});

describe("photos", () => {
  // The photo card is declared twice -- once ABOVE the tabs for a phone, once
  // in the right-hand column (inside the Moments panel) for a desktop -- with
  // exactly one displayed at any width. The phone copy is deliberately outside
  // both panels so it needs no tap, so it is queried from the page, not from a
  // panel.
  const phoneCopy = () => within(screen.getByTestId("profile-photos-phone"));
  const moments = () => within(screen.getByTestId("profile-moments-panel"));

  it("shows the photo set, and Add photos on an own profile", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", imageUrls: ["a.jpg", "b.jpg"] } },
    });

    renderPage("/profile", "me");

    expect(phoneCopy().getByTestId("profile-photos")).toBeInTheDocument();
    expect(phoneCopy().getAllByTestId("photo-tile")).toHaveLength(2);
    expect(phoneCopy().getByTestId("photos-add")).toHaveAttribute("href", "/profile/edit");
  });

  it("puts the desktop copy in the right-hand column", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", imageUrls: ["a.jpg"] } },
    });

    renderPage("/profile", "me");

    // Phone: the above-the-tabs copy shows, the column copy is held back to lg.
    const phone = screen.getByTestId("profile-photos-phone");
    const desktop = moments().getByTestId("profile-photos-desktop");
    expect(phone.className).toContain("lg:hidden");
    expect(desktop.className).toContain("hidden lg:block");
    expect(within(phone).getByTestId("profile-photos")).toBeInTheDocument();
    expect(within(desktop).getByTestId("profile-photos")).toBeInTheDocument();
  });

  it("shows another person's photos without the Add link", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["a.jpg"] } },
    });

    renderPage("/profile/u2", "me");

    expect(phoneCopy().getAllByTestId("photo-tile")).toHaveLength(1);
    expect(screen.queryByTestId("photos-add")).not.toBeInTheDocument();
  });

  it("renders no photos card at all when the account has none", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", imageUrls: [] } },
    });

    renderPage("/profile", "me");

    expect(screen.queryByTestId("profile-photos")).not.toBeInTheDocument();
  });
});

describe("moments", () => {
  it("caps the grid and leaves the rest behind See all", () => {
    const many = Array.from({ length: 12 }).map((unused, i) => ({
      _id: `m${i}`,
      description: `moment ${i}`,
    }));
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me" } },
    });
    mockGetMyMoments.mockReturnValue({
      ...idle,
      refetch: momentsRefetch,
      data: { data: many, totalMoments: 12 },
    });

    renderPage("/profile", "me");

    expect(screen.getAllByTestId("moment-tile")).toHaveLength(9);
    expect(screen.getByTestId("moments-see-all")).toBeInTheDocument();
  });
});

it("titles the page after the person and keeps it out of the index", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    refetch: otherRefetch,
    data: { data: { _id: "u2", name: "Ada" } },
  });

  // renderToString walks react-router's Links, and useNavigate's layout effect
  // warns on the server. The warning is react-router's, not the page's, and it
  // would otherwise be the only noise this suite prints.
  const consoleError = jest.spyOn(console, "error").mockImplementation(() => undefined);
  const context: any = {};
  renderToString(
    <HelmetProvider context={context}>
      <Provider
        store={configureStore({
          reducer: { auth: (state: any = { userInfo: { user: { _id: "me" } } }) => state },
        })}
      >
        <MemoryRouter initialEntries={["/profile/u2"]}>
          <Routes>
            <Route path="/profile/:userId" element={<ProfilePage />} />
            <Route path="/login" element={<div data-testid="login-screen" />} />
          </Routes>
        </MemoryRouter>
      </Provider>
    </HelmetProvider>
  );

  consoleError.mockRestore();

  expect(context.helmet.title.toString()).toContain("Ada · BananaTalk");
  expect(context.helmet.meta.toString()).toContain("noindex");
});

// The app's member page carries four blocks a profile page of your own has no
// use for. Every one of them is keyed off `isOwn`, so this is the guard that
// they never appear on /profile.
describe("the match-aware blocks", () => {
  const viewer = {
    _id: "me",
    name: "Me",
    native_language: "Korean",
    language_to_learn: "English",
    topics: ["music", "travel"],
  };
  const other = {
    _id: "u2",
    name: "Ada",
    native_language: "English",
    language_to_learn: "Korean",
    topics: ["music"],
    responseRate: 91,
  };

  beforeEach(() => {
    mockGetUserProfile.mockReturnValue({ ...idle, refetch: ownRefetch, data: { data: viewer } });
    mockGetPublicProfile.mockReturnValue({ ...idle, refetch: otherRefetch, data: { data: other } });
    mockGetCommunityMembers.mockReturnValue({
      ...idle,
      data: {
        data: [
          { _id: "u3", name: "Grace", native_language: "English", language_to_learn: "Korean", imageUrls: [] },
        ],
      },
    });
  });

  it("renders the match, engagement, interests, starters and suggestions for someone else", () => {
    renderPage("/profile/u2", "me");

    expect(screen.getByTestId("language-match-card")).toHaveAttribute("data-match", "perfect");
    expect(screen.getByTestId("engagement-stats")).toBeInTheDocument();
    expect(screen.getByTestId("mutual-interests")).toBeInTheDocument();
    expect(screen.getByTestId("conversation-starters")).toBeInTheDocument();
    expect(screen.getByTestId("suggested-members")).toBeInTheDocument();
  });

  it("renders none of them on your own profile", () => {
    renderPage("/profile", "me");

    expect(screen.queryByTestId("language-match-card")).not.toBeInTheDocument();
    expect(screen.queryByTestId("engagement-stats")).not.toBeInTheDocument();
    expect(screen.queryByTestId("mutual-interests")).not.toBeInTheDocument();
    expect(screen.queryByTestId("conversation-starters")).not.toBeInTheDocument();
    expect(screen.queryByTestId("suggested-members")).not.toBeInTheDocument();
  });

  it("drops the signed-in-only blocks for a signed-out visitor", () => {
    mockGetUserProfile.mockReturnValue({ ...idle, refetch: ownRefetch });

    renderPage("/profile/u2", null);

    expect(screen.getByTestId("profile-body")).toBeInTheDocument();
    expect(screen.queryByTestId("language-match-card")).not.toBeInTheDocument();
    expect(screen.queryByTestId("conversation-starters")).not.toBeInTheDocument();
    expect(screen.queryByTestId("mutual-interests")).not.toBeInTheDocument();
    // The engagement strip is public data, so it stays.
    expect(screen.getByTestId("engagement-stats")).toBeInTheDocument();
  });

  it("keeps the suggestions off the profile itself and off the viewer", () => {
    renderPage("/profile/u2", "me");

    expect(mockGetCommunityMembers.mock.calls[0][0]).toEqual({
      page: 1,
      limit: 12,
      nativeLanguage: "English",
    });
    expect(screen.getAllByTestId("suggested-member")).toHaveLength(1);
  });
});

describe("the phone tab switcher", () => {
  beforeEach(() => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me" } },
    });
  });

  it("opens on About below 1024px, so a phone lands on who someone is", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", bio: "something to read" } },
    });
    renderPage("/profile", "me");

    expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("profile-moments-panel").className).toContain("hidden");
    expect(screen.getByTestId("profile-about-panel").className).not.toContain("hidden");
  });

  it("still honours ?tab=moments, so existing links keep working", () => {
    renderPage("/profile?tab=moments", "me");

    expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("profile-moments-panel").className).not.toContain("hidden");
    expect(screen.getByTestId("profile-about-panel").className).toContain("hidden");
  });

  it("writes the chosen tab into the URL", () => {
    renderPage("/profile", "me");

    // About is the default now, so Moments is the one a click has to move to.
    fireEvent.click(screen.getByTestId("profile-tab-moments"));

    expect(screen.getByTestId("location-search")).toHaveTextContent("tab=moments");
    expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("profile-about-panel").className).toContain("hidden");
    expect(screen.getByTestId("profile-moments-panel").className).not.toContain("hidden");
  });

  it("reads the tab back off the URL", () => {
    renderPage("/profile?tab=about", "me");

    expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("profile-about-panel").className).not.toContain("hidden");
  });

  it("keeps both panels in the DOM so switching costs no refetch", () => {
    renderPage("/profile?tab=about", "me");

    expect(screen.getByTestId("profile-moments-panel")).toBeInTheDocument();
    expect(screen.getByTestId("profile-about-panel")).toBeInTheDocument();
  });

  // An incomplete tablist reads worse than plain buttons: the reader
  // announces "tab 1 of 2" and then cannot find what it controls.
  it("wires each tab to the panel it controls", () => {
    renderPage("/profile", "me");

    const momentsTab = screen.getByTestId("profile-tab-moments");
    const aboutTab = screen.getByTestId("profile-tab-about");

    expect(momentsTab).toHaveAttribute("aria-controls", "profile-panel-moments");
    expect(aboutTab).toHaveAttribute("aria-controls", "profile-panel-about");
    expect(screen.getByTestId("profile-moments-panel")).toHaveAttribute("role", "tabpanel");
    expect(screen.getByTestId("profile-moments-panel")).toHaveAttribute(
      "aria-labelledby",
      momentsTab.id
    );
    expect(screen.getByTestId("profile-about-panel")).toHaveAttribute(
      "aria-labelledby",
      aboutTab.id
    );
  });

  it("gives the tablist one tab stop, on whichever tab is selected", () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", bio: "something to read" } },
    });
    renderPage("/profile", "me");

    // About is the default, so it carries the tab stop.
    expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("tabindex", "0");
    expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("tabindex", "-1");
  });

  it("moves between tabs with the arrow keys, and focus follows", () => {
    // Anchored to Moments: this proves the journey from the FIRST tab in the
    // order, which is independent of which tab happens to be the default.
    renderPage("/profile?tab=moments", "me");

    fireEvent.keyDown(screen.getByTestId("profile-tabs"), { key: "ArrowRight" });

    expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("location-search")).toHaveTextContent("tab=about");
    expect(document.activeElement).toBe(screen.getByTestId("profile-tab-about"));

    fireEvent.keyDown(screen.getByTestId("profile-tabs"), { key: "ArrowLeft" });

    expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("aria-selected", "true");
    expect(document.activeElement).toBe(screen.getByTestId("profile-tab-moments"));
  });

  it("wraps at the ends and answers Home and End", () => {
    renderPage("/profile?tab=moments", "me");

    // About is first now, Moments last. Starting on Moments (the last tab),
    // ArrowRight wraps round to About.
    fireEvent.keyDown(screen.getByTestId("profile-tabs"), { key: "ArrowRight" });
    expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("aria-selected", "true");

    fireEvent.keyDown(screen.getByTestId("profile-tabs"), { key: "End" });
    expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("aria-selected", "true");

    fireEvent.keyDown(screen.getByTestId("profile-tabs"), { key: "Home" });
    expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("aria-selected", "true");
  });

  it("leaves other keys to the browser", () => {
    // Anchored, not defaulted: asserting the tab the page already opens on
    // would pass whether or not the keypress was inert.
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", bio: "something to read" } },
    });
    renderPage("/profile?tab=moments", "me");

    fireEvent.keyDown(screen.getByTestId("profile-tabs"), { key: "a" });

    expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("aria-selected", "true");
    expect(screen.getByTestId("location-search")).toHaveTextContent("tab=moments");
  });
});

describe("the story highlights rail", () => {
  const viewer = { _id: "me", name: "Me" };
  const other = { _id: "u2", name: "Ada" };

  const HIGHLIGHTS = {
    success: true,
    data: [
      {
        _id: "h-1",
        title: "Seoul",
        coverImage: "https://cdn/cover-1.jpg",
        storyCount: 1,
        stories: [
          { story: { _id: "s-1", mediaType: "image", mediaUrls: ["https://cdn/s1.jpg"] } },
        ],
      },
    ],
  };

  beforeEach(() => {
    mockGetUserProfile.mockReturnValue({ ...idle, refetch: ownRefetch, data: { data: viewer } });
    mockGetPublicProfile.mockReturnValue({ ...idle, refetch: otherRefetch, data: { data: other } });
  });

  it("shows another person's highlights above their moments", () => {
    mockGetUserHighlights.mockReturnValue({ ...idle, data: HIGHLIGHTS });

    renderPage("/profile/u2", "me");

    const rail = screen.getByTestId("highlights-rail");
    expect(rail).toBeInTheDocument();
    expect(within(rail).getByTestId("highlight-rail-item")).toBeInTheDocument();
    expect(mockGetUserHighlights).toHaveBeenCalledWith("u2", { skip: false });

    // Above the moments, not below them.
    const moments = screen.getByTestId("profile-moments");
    expect(rail.compareDocumentPosition(moments) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it("renders no rail when the person has no highlights", () => {
    mockGetUserHighlights.mockReturnValue({ ...idle, data: { success: true, data: [] } });
    renderPage("/profile/u2", "me");
    expect(screen.queryByTestId("highlights-rail")).not.toBeInTheDocument();
  });

  it("stays off your own profile, which manages highlights on /highlights", () => {
    mockGetUserHighlights.mockReturnValue({ ...idle, data: HIGHLIGHTS });
    renderPage("/profile", "me");
    expect(screen.queryByTestId("highlights-rail")).not.toBeInTheDocument();
  });

  it("opens the highlight's own stories in a viewer overlay", () => {
    mockGetUserHighlights.mockReturnValue({ ...idle, data: HIGHLIGHTS });
    renderPage("/profile/u2", "me");

    fireEvent.click(screen.getByTestId("highlight-rail-item"));

    expect(screen.getByTestId("highlight-story-viewer")).toBeInTheDocument();
    expect(screen.getByTestId("highlight-story-image")).toHaveAttribute(
      "src",
      "https://cdn/s1.jpg"
    );
  });
});

describe("the photo set on a phone", () => {
  const withPhotos = () => {
    mockGetUserProfile.mockReturnValue({
      ...idle,
      refetch: ownRefetch,
      data: { data: { _id: "me", name: "Me", imageUrls: ["a.jpg", "b.jpg"] } },
    });
  };

  it("sits above the tabs, outside both panels, so it needs no tap", () => {
    withPhotos();
    const { container } = renderPage("/profile", "me");

    const photos = screen.getByTestId("profile-photos-phone");
    const tablist = container.querySelector('[role="tablist"]') as HTMLElement;

    // Not inside a panel: it must not disappear when the tab changes.
    expect(photos.closest('[role="tabpanel"]')).toBeNull();
    // And it comes before the tablist in document order.
    expect(
      photos.compareDocumentPosition(tablist) & Node.DOCUMENT_POSITION_FOLLOWING
    ).toBeTruthy();
  });

  it("keeps the desktop copy inside the Moments panel", () => {
    withPhotos();
    renderPage("/profile", "me");

    const desktop = screen.getByTestId("profile-photos-desktop");
    expect(desktop.closest('[data-testid="profile-moments-panel"]')).not.toBeNull();
  });
});

describe("the info card", () => {
  it("draws the four sections inside one card, not four", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", native_language: "English", bio: "hi" } },
    });

    renderPage("/profile/u2", "me");

    expect(screen.getAllByTestId("profile-info-card")).toHaveLength(1);
    const card = within(screen.getByTestId("profile-info-card"));
    expect(card.getByTestId("profile-languages")).toBeInTheDocument();
    expect(card.getByTestId("profile-about")).toBeInTheDocument();
  });

  it("shows no card at all when the profile has none of the four", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2", "me");

    // Absent, not empty: four independent early returns gave nothing before.
    expect(screen.queryByTestId("profile-info-card")).not.toBeInTheDocument();
  });

  it("carries only the sections that have something", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", bio: "just a bio" } },
    });

    renderPage("/profile/u2", "me");

    const card = within(screen.getByTestId("profile-info-card"));
    expect(card.getByTestId("profile-about")).toBeInTheDocument();
    expect(card.queryByTestId("profile-languages")).not.toBeInTheDocument();
    expect(card.queryByTestId("profile-learning")).not.toBeInTheDocument();
  });
});

describe("the default tab on a sparse profile", () => {
  it("falls back to Moments when About would be empty", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      // No languages, no bio, no learning stats, no photos.
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2", "me");

    // Landing on an empty panel is worse than landing on posts.
    expect(screen.getByTestId("profile-moments-panel").className).not.toContain("hidden");
    expect(screen.getByTestId("profile-about-panel").className).toContain("hidden");
  });

  it("still opens on About when there is only a photo to show", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["a.jpg"] } },
    });

    renderPage("/profile/u2", "me");

    expect(screen.getByTestId("profile-about-panel").className).not.toContain("hidden");
  });

  it("honours an explicit ?tab=about even on a sparse profile", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });

    renderPage("/profile/u2?tab=about", "me");

    expect(screen.getByTestId("profile-about-panel").className).not.toContain("hidden");
  });
});

// Reported: the profile's sections are too tall. Every card carried p-5 (20px
// all round), stacked with 16px between ~8 blocks, and the merged info card
// added another 20px between each of its four sections. Nothing is removed —
// the air is.
describe("section density", () => {
  const source = fs.readFileSync(
    path.resolve(__dirname, "./ProfilePage.tsx"),
    "utf8"
  );

  it("stacks the profile's blocks at 12px, not 16px", () => {
    expect(source).toContain('data-testid="profile-body" className="space-y-3"');
  });

  it("uses the medium card padding, not the large one", () => {
    expect(source).not.toContain('padding="lg"');
  });

  it("keeps the info card's four sections closer together", () => {
    expect(source).toContain('className="space-y-4"');
    expect(source).not.toContain('className="space-y-5"');
  });
});

describe("the profile picture", () => {
  const withPhotos = () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["a.jpg", "b.jpg"] } },
    });
  };

  it("opens the photo viewer when the avatar is clicked", () => {
    withPhotos();
    renderPage("/profile/u2", "me");

    // Nothing open to begin with.
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /Ada's photo/i }));

    expect(screen.getAllByRole("dialog").length).toBeGreaterThan(0);
  });

  it("leaves the avatar inert when the person has no photo to show", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: [] } },
    });
    renderPage("/profile/u2", "me");

    // A button that opens an empty viewer is worse than no button.
    expect(screen.queryByRole("button", { name: /Ada's photo/i })).not.toBeInTheDocument();
  });
});

describe("story ring (community#6)", () => {
  it("rings the avatar and opens the stories when the person has one", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["https://cdn/a.jpg"], hasActiveStory: true } },
    });
    renderPage("/profile/u2", "me");
    expect(screen.getByTestId("avatar-story-ring")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "View Ada's story" }));
    expect(mockNavigate).toHaveBeenCalledWith("/stories/u2");
  });

  it("sends a signed-out visitor to log in rather than to a protected viewer", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["https://cdn/a.jpg"], hasActiveStory: true } },
    });
    renderPage("/profile/u2", null);
    fireEvent.click(screen.getByRole("button", { name: "View Ada's story" }));
    expect(mockNavigate).toHaveBeenCalledWith("/login");
  });

  it("keeps the photo viewer when there is no story", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", imageUrls: ["https://cdn/a.jpg"] } },
    });
    renderPage("/profile/u2", "me");
    expect(screen.queryByTestId("avatar-story-ring")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Open Ada's photo" })).toBeInTheDocument();
  });
});

describe("blocked (community#5)", () => {
  it("shows a neutral card with only the header, no actions, stats or tabs", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada", username: "ada", images: [], imageUrls: [], isBlocked: true } },
    });
    renderPage("/profile/u2", "me");

    expect(screen.getByTestId("profile-blocked")).toBeInTheDocument();
    expect(screen.getByText("Ada")).toBeInTheDocument();
    expect(screen.queryByTestId("action-more")).not.toBeInTheDocument();
    expect(screen.queryByTestId("profile-tabs")).not.toBeInTheDocument();
    expect(screen.getByText("Manage blocked people").closest("a")).toHaveAttribute("href", "/settings/blocked");
  });

  it("renders the full page when isBlocked is absent", () => {
    mockGetPublicProfile.mockReturnValue({
      ...idle,
      refetch: otherRefetch,
      data: { data: { _id: "u2", name: "Ada" } },
    });
    renderPage("/profile/u2", "me");
    expect(screen.queryByTestId("profile-blocked")).not.toBeInTheDocument();
    expect(screen.getByTestId("profile-body")).toBeInTheDocument();
  });
});
