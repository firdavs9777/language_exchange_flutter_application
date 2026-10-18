import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import SingleMoment from "./SingleMoment";
import { _resetMomentViewsForTests } from "./useMomentViews";

const mockTranslateMoment = jest.fn();
const mockToastError = jest.fn();
let mockUserId: string | undefined = "me-1";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => key, i18n: { language: "ko" } }),
}));

jest.mock("react-redux", () => ({
  useSelector: (selector: any) =>
    selector({ auth: { userInfo: mockUserId ? { user: { _id: mockUserId } } : undefined } }),
}));

jest.mock("react-toastify", () => ({
  toast: { error: (...args: any[]) => mockToastError(...args), success: jest.fn(), info: jest.fn() },
  Bounce: {},
}));

const noopMutation = () => [jest.fn(() => ({ unwrap: () => Promise.resolve({}) })), {}];

jest.mock("../../store/slices/momentsSlice", () => ({
  useLikeMomentMutation: () => noopMutation(),
  useDislikeMomentMutation: () => noopMutation(),
  useReactToMomentMutation: () => noopMutation(),
  useUnreactToMomentMutation: () => noopMutation(),
  useShareMomentMutation: () => noopMutation(),
  useSaveMomentMutation: () => noopMutation(),
  useUnsaveMomentMutation: () => noopMutation(),
  useTranslateMomentMutation: () => [mockTranslateMoment, {}],
  useRecordMomentViewsMutation: () => [jest.fn(() => ({ unwrap: () => Promise.resolve({}) })), {}],
}));

// The "⋯" menu's report dialog posts through usersSlice, which needs a real
// store; this file mocks react-redux, so the mutation is stubbed instead.
jest.mock("../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [jest.fn(), { isLoading: false }],
  useBlockUserMutation: () => [jest.fn(), { isLoading: false }],
}));

const DESCRIPTION = "오늘 날씨가 정말 좋아요";

const renderMoment = (description: string = DESCRIPTION) =>
  render(
    <MemoryRouter>
      <SingleMoment
        _id="moment-1"
        title="Title"
        description={description}
        likeCount={0}
        likedUsers={[]}
        commentCount={0}
        createdAt={new Date().toISOString()}
        user={{ _id: "author-1", name: "Author" }}
      />
    </MemoryRouter>
  );

describe("SingleMoment translate on tap", () => {
  beforeEach(() => {
    mockTranslateMoment.mockReset();
    mockToastError.mockReset();
    mockUserId = "me-1";
  });

  afterEach(() => {
    // useMomentViews keeps a module-level shared IntersectionObserver,
    // flush interval and window/document listeners -- clear them so no
    // test leaves a real timer/listener running past this file.
    _resetMomentViewsForTests();
  });

  it("translates the moment body with the moment id and the target language", async () => {
    mockTranslateMoment.mockReturnValue({
      unwrap: () =>
        Promise.resolve({
          success: true,
          data: { language: "ko", translatedText: "The weather is lovely today" },
          cached: false,
        }),
    });

    renderMoment();
    fireEvent.click(screen.getByTestId("translatable-text"));

    await waitFor(() =>
      expect(mockTranslateMoment).toHaveBeenCalledWith({
        momentId: "moment-1",
        targetLanguage: "ko",
      })
    );
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "The weather is lovely today"
      )
    );
  });

  // The card renders a 200-char preview, so the same-language check must run
  // against the untruncated body it hands over as `fullText`.
  it("recognises a long moment already in the viewer's language", async () => {
    const longDescription = "오늘 날씨가 정말 좋아요. ".repeat(30).trim();
    expect(longDescription.length).toBeGreaterThan(300);

    mockTranslateMoment.mockReturnValue({
      unwrap: () =>
        Promise.resolve({
          success: true,
          data: { language: "ko", translatedText: longDescription },
          cached: false,
        }),
    });

    renderMoment(longDescription);
    fireEvent.click(screen.getByTestId("translatable-text"));

    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "moments_section.translate.same"
      )
    );
  });

  it("prompts a logged-out visitor to sign in instead of translating", () => {
    mockUserId = undefined;
    renderMoment();

    fireEvent.click(screen.getByTestId("translatable-text"));

    expect(mockTranslateMoment).not.toHaveBeenCalled();
    expect(mockToastError).toHaveBeenCalledWith(
      "moments_section.moment_login_error",
      expect.anything()
    );
  });
});

// A feed card's cost is mostly its media. The author avatar was eagerly
// loaded on every card -- ten per page, all competing with the content images
// for connections, which delays the images and makes the layout shift land
// later and feel worse.
describe("SingleMoment media loading", () => {
  const renderWithMedia = () =>
    render(
      <MemoryRouter>
        <SingleMoment
          _id="moment-1"
          title="Title"
          description={DESCRIPTION}
          likeCount={0}
          likedUsers={[]}
          commentCount={0}
          createdAt={new Date().toISOString()}
          imageUrls={["https://example.test/photo.jpg"]}
          user={{ _id: "author-1", name: "Author", imageUrls: ["https://example.test/a.jpg"] }}
        />
      </MemoryRouter>
    );

  it("leaves the author's avatar to the browser, with a box reserved", () => {
    renderWithMedia();
    const avatar = screen.getByAltText("Author") as HTMLImageElement;

    expect(avatar).toHaveAttribute("loading", "lazy");
    expect(avatar).toHaveAttribute("decoding", "async");
    // The largest the avatar ever renders, so the browser reserves enough.
    expect(avatar).toHaveAttribute("width", "56");
    expect(avatar).toHaveAttribute("height", "56");
  });

  it("keeps the content image lazy and asynchronous too", () => {
    renderWithMedia();
    const photo = screen.getByAltText("Title") as HTMLImageElement;

    expect(photo).toHaveAttribute("loading", "lazy");
    expect(photo).toHaveAttribute("decoding", "async");
  });
});

describe("SingleMoment scheduled badge", () => {
  const renderScheduled = (authorId: string) =>
    render(
      <MemoryRouter>
        <SingleMoment
          _id="moment-2"
          title="Later"
          description="d"
          likeCount={0}
          likedUsers={[]}
          commentCount={0}
          createdAt="2099-01-01T00:00:00.000Z"
          scheduledFor="2099-01-01T00:00:00.000Z"
          user={{ _id: authorId, name: "Author" }}
        />
      </MemoryRouter>
    );

  it("the author sees when it will go out instead of a relative time", () => {
    mockUserId = "me-1";
    renderScheduled("me-1");
    expect(screen.getByTestId("scheduled-badge")).toBeInTheDocument();
  });

  it("nobody else sees the badge", () => {
    mockUserId = "me-1";
    renderScheduled("someone-else");
    expect(screen.queryByTestId("scheduled-badge")).not.toBeInTheDocument();
  });
});

describe("SingleMoment prerendered date", () => {
  // The prerender runs on the deploy runner (UTC); visitors hydrate in their
  // own timezone. The pre-hydration date must be the same string in both, or
  // React discards the whole server tree (#418/#425).
  it("is written in UTC, whatever timezone renders it", () => {
    const { renderToString } = require("react-dom/server");
    const html = renderToString(
      <MemoryRouter>
        <SingleMoment
          _id="moment-tz"
          title="Late"
          description="d"
          likeCount={0}
          likedUsers={[]}
          commentCount={0}
          createdAt="2026-10-07T23:30:00.000Z"
          user={{ _id: "author-1", name: "Author" }}
        />
      </MemoryRouter>
    );
    expect(html).toContain("Oct 7, 2026");
  });
});

describe("feed card chips (moments#22)", () => {
  afterEach(() => _resetMomentViewsForTests());

  const renderWith = (extra: any) =>
    render(
      <MemoryRouter>
        <SingleMoment
          _id="moment-2"
          title=""
          description="hi"
          likeCount={0}
          likedUsers={[]}
          commentCount={0}
          createdAt={new Date().toISOString()}
          user={{ _id: "author-1", name: "Author" }}
          {...extra}
        />
      </MemoryRouter>
    );

  it("shows mood, every tag and the place", () => {
    renderWith({ mood: "happy", tags: ["kimchi", "seoul"], location: { formattedAddress: "Seoul, KR" } });
    const chips = screen.getByTestId("moment-chips");
    expect(chips).toHaveTextContent("moments_section.moods.happy");
    expect(chips).toHaveTextContent("#kimchi");
    expect(chips).toHaveTextContent("#seoul");
    expect(chips).toHaveTextContent("Seoul, KR");
  });

  it("renders no chip row when there is nothing to show", () => {
    renderWith({ mood: "", tags: [], location: null });
    expect(screen.queryByTestId("moment-chips")).not.toBeInTheDocument();
  });

  it("ignores a location without an address and an unknown mood", () => {
    renderWith({ mood: "not-a-mood", tags: undefined, location: { coordinates: [1, 2] } });
    // An unknown mood still renders its raw value rather than crashing.
    expect(screen.getByTestId("moment-chips")).toHaveTextContent("moments_section.moods.not-a-mood");
    expect(screen.queryByTestId("moment-chip-location")).not.toBeInTheDocument();
  });
});

describe("SingleMoment boosted label", () => {
  it("shows Boosted only on a moment the API marks boosted", () => {
    const props = {
      _id: "moment-b",
      title: "",
      description: "hi",
      likeCount: 0,
      likedUsers: [],
      commentCount: 0,
      createdAt: new Date().toISOString(),
      user: { _id: "author-1", name: "Author" },
    } as any;
    const { rerender } = render(
      <MemoryRouter>
        <SingleMoment {...props} boosted />
      </MemoryRouter>
    );
    expect(screen.getByTestId("moment-boosted-badge")).toBeInTheDocument();
    rerender(
      <MemoryRouter>
        <SingleMoment {...props} />
      </MemoryRouter>
    );
    expect(screen.queryByTestId("moment-boosted-badge")).not.toBeInTheDocument();
  });
});
