import React from "react";
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import StoryViewersSheet from "./StoryViewersSheet";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

let mockViewersState: any = { data: undefined, isLoading: true, error: undefined };
let mockReactionsState: any = { data: undefined, isLoading: false, error: undefined };
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetStoryViewersQuery: () => mockViewersState,
  useGetStoryReactionsQuery: () => mockReactionsState,
}));

const NOW = new Date("2026-09-24T12:00:00Z").getTime();

const renderSheet = (onClose = jest.fn()) => {
  render(
    <MemoryRouter>
      <StoryViewersSheet storyId="story-1" onClose={onClose} />
    </MemoryRouter>
  );
  return onClose;
};

beforeEach(() => {
  jest.spyOn(Date, "now").mockReturnValue(NOW);
  mockViewersState = { data: undefined, isLoading: true, error: undefined };
  mockReactionsState = { data: undefined, isLoading: false, error: undefined };
});

afterEach(() => jest.restoreAllMocks());

describe("StoryViewersSheet", () => {
  it("shows a loading state while GET /:id/views is in flight", () => {
    renderSheet();
    expect(screen.getByTestId("story-viewers-loading")).toBeInTheDocument();
  });

  it("lists each viewer with a name, a relative viewedAt and a link to their profile", () => {
    mockViewersState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          viewCount: 2,
          views: [
            {
              user: { _id: "u-1", name: "Mina", imageUrls: ["https://cdn/m.jpg"] },
              viewedAt: "2026-09-24T11:30:00Z",
            },
            {
              user: { _id: "u-2", name: "Tom", images: ["https://cdn/t.jpg"] },
              viewedAt: "2026-09-23T12:00:00Z",
            },
          ],
        },
      },
    };
    renderSheet();

    const rows = screen.getAllByTestId("story-viewer-row");
    expect(rows).toHaveLength(2);
    expect(screen.getByText("Mina")).toBeInTheDocument();
    expect(screen.getByText("Tom")).toBeInTheDocument();
    // 30 minutes and 1 day before the frozen "now".
    expect(screen.getByText("30m ago")).toBeInTheDocument();
    expect(screen.getByText("1d ago")).toBeInTheDocument();
    expect(rows[0]).toHaveAttribute("href", "/community/u-1");
    expect(rows[1]).toHaveAttribute("href", "/community/u-2");
  });

  it("shows the view count from the response, not the row count", () => {
    mockViewersState = {
      isLoading: false,
      error: undefined,
      data: { success: true, data: { viewCount: 41, views: [] } },
    };
    renderSheet();
    expect(screen.getByTestId("story-viewers-count")).toHaveTextContent("41");
  });

  it("shows an empty state when nobody has watched yet", () => {
    mockViewersState = {
      isLoading: false,
      error: undefined,
      data: { success: true, data: { viewCount: 0, views: [] } },
    };
    renderSheet();
    expect(screen.getByTestId("story-viewers-empty")).toBeInTheDocument();
    expect(screen.queryByTestId("story-viewer-row")).not.toBeInTheDocument();
  });

  it("shows an error state when the request fails", () => {
    mockViewersState = { isLoading: false, error: { status: 403 }, data: undefined };
    renderSheet();
    expect(screen.getByTestId("story-viewers-error")).toBeInTheDocument();
  });

  it("closes from its own close button", () => {
    mockViewersState = {
      isLoading: false,
      error: undefined,
      data: { success: true, data: { viewCount: 0, views: [] } },
    };
    const onClose = renderSheet();
    screen.getByTestId("story-viewers-close").click();
    expect(onClose).toHaveBeenCalled();
  });

  it("survives a response whose viewer was deleted (no user object)", () => {
    mockViewersState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          viewCount: 1,
          views: [{ user: null, viewedAt: "2026-09-24T11:59:00Z" }],
        },
      },
    };
    renderSheet();
    // Rendered, but not as a link to /community/undefined.
    expect(screen.queryByTestId("story-viewer-row")).not.toBeInTheDocument();
    expect(screen.getByTestId("story-viewers-empty")).toBeInTheDocument();
  });
});

describe("StoryViewersSheet reactions", () => {
  // `GET /:id/reactions` existed, the slice generated the hook, and nothing
  // called it: on the web you could see who watched but never who reacted or
  // with what. The app's sheet (story_viewers_sheet.dart) fetches both and
  // merges them by user id, which is what these cover.
  const twoViewers = {
    isLoading: false,
    error: undefined,
    data: {
      success: true,
      data: {
        viewCount: 2,
        views: [
          {
            user: { _id: "u-1", name: "Mina", imageUrls: ["https://cdn/m.jpg"] },
            viewedAt: "2026-09-24T11:30:00Z",
          },
          {
            user: { _id: "u-2", name: "Tom", images: ["https://cdn/t.jpg"] },
            viewedAt: "2026-09-24T11:40:00Z",
          },
        ],
      },
    },
  };

  it("shows the emoji of a viewer who also reacted, on their own row", () => {
    mockViewersState = twoViewers;
    mockReactionsState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          reactionCount: 1,
          reactions: [
            {
              user: { _id: "u-1", name: "Mina" },
              emoji: "🔥",
              reactedAt: "2026-09-24T11:31:00Z",
            },
          ],
        },
      },
    };
    renderSheet();

    const reactions = screen.getAllByTestId("story-viewer-reaction");
    expect(reactions).toHaveLength(1);
    expect(reactions[0]).toHaveTextContent("🔥");
    // On Mina's row, not on Tom's.
    const rows = screen.getAllByTestId("story-viewer-row");
    const mina = rows.find((row) => row.getAttribute("href") === "/community/u-1");
    expect(mina).toContainElement(reactions[0]);
  });

  it("leaves a viewer who only watched without an emoji", () => {
    mockViewersState = twoViewers;
    mockReactionsState = {
      isLoading: false,
      error: undefined,
      data: { success: true, data: { reactionCount: 0, reactions: [] } },
    };
    renderSheet();
    expect(screen.queryByTestId("story-viewer-reaction")).not.toBeInTheDocument();
    expect(screen.getAllByTestId("story-viewer-row")).toHaveLength(2);
  });

  it("still lists the viewers when the reactions request fails", () => {
    // Reactions are an enrichment. A 500 on them must not blank a sheet whose
    // own request succeeded, so only the viewers error drives the error state.
    mockViewersState = twoViewers;
    mockReactionsState = { isLoading: false, error: { status: 500 }, data: undefined };
    renderSheet();
    expect(screen.getAllByTestId("story-viewer-row")).toHaveLength(2);
    expect(screen.queryByTestId("story-viewers-error")).not.toBeInTheDocument();
  });

  it("drops a reaction whose user was deleted rather than matching a blank id", () => {
    mockViewersState = twoViewers;
    mockReactionsState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          reactionCount: 1,
          reactions: [{ user: null, emoji: "😮", reactedAt: "2026-09-24T11:31:00Z" }],
        },
      },
    };
    renderSheet();
    expect(screen.queryByTestId("story-viewer-reaction")).not.toBeInTheDocument();
  });

  it("orders the rows newest view first, as the app does", () => {
    // The server returns views in insertion order, i.e. oldest first. The app
    // sorts them before rendering; the web was showing the first watcher at the
    // top and the most recent one at the bottom.
    mockViewersState = twoViewers;
    renderSheet();
    const rows = screen.getAllByTestId("story-viewer-row");
    expect(rows[0]).toHaveAttribute("href", "/community/u-2");
    expect(rows[1]).toHaveAttribute("href", "/community/u-1");
  });
});
