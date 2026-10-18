import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import MyStories from "./MyStories";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("react-redux", () => ({
  useSelector: (selector: any) =>
    selector({ auth: { userInfo: { user: { _id: "me", name: "Me" } } } }),
}));

const mockDeleteStory = jest.fn();
const mockArchiveStory = jest.fn();
const mockAddToHighlight = jest.fn();
const mockCreateHighlight = jest.fn();

let mockMyStoriesState: any;
let mockArchivedState: any;
let mockHighlightsState: any;

jest.mock("../../store/slices/storiesSlice", () => ({
  useGetMyStoriesQuery: () => mockMyStoriesState,
  useGetArchivedStoriesQuery: () => mockArchivedState,
  useGetHighlightsQuery: () => mockHighlightsState,
  useDeleteIndividualStoryMutation: () => [mockDeleteStory, { isLoading: false }],
  useArchiveStoryMutation: () => [mockArchiveStory, { isLoading: false }],
  useAddStoryToHighlightMutation: () => [mockAddToHighlight, { isLoading: false }],
  useCreateHighlightMutation: () => [mockCreateHighlight, { isLoading: false }],
}));

// The viewers sheet is S1's and has its own suite; here it only has to prove
// that the view count opens it for the right story.
jest.mock("./StoryViewersSheet", () => ({
  __esModule: true,
  default: ({ storyId }: any) => <div data-testid="viewers-sheet-stub">{storyId}</div>,
}));

jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn() },
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });

const MY_STORIES = {
  success: true,
  data: [
    {
      _id: "s-1",
      mediaType: "image",
      mediaUrls: ["https://cdn/s1.jpg"],
      viewCount: 12,
      reactionCount: 3,
      createdAt: "2026-09-24T11:00:00Z",
      privacy: "public",
    },
    {
      _id: "s-2",
      mediaType: "text",
      text: "Hi there",
      backgroundColor: "#123456",
      viewCount: 4,
      reactionCount: 0,
      createdAt: "2026-09-24T09:00:00Z",
      privacy: "friends",
    },
  ],
};

const HIGHLIGHTS = {
  success: true,
  data: [
    { _id: "h-1", title: "Seoul", coverImage: "https://cdn/c1.jpg", storyCount: 2, stories: [] },
    { _id: "h-2", title: "Food", coverImage: "", storyCount: 0, stories: [] },
  ],
};

beforeEach(() => {
  jest.clearAllMocks();
  mockDeleteStory.mockReturnValue(resolved());
  mockArchiveStory.mockReturnValue(resolved());
  mockAddToHighlight.mockReturnValue(resolved());
  mockCreateHighlight.mockReturnValue(resolved());
  mockMyStoriesState = { data: MY_STORIES, isLoading: false, refetch: jest.fn() };
  mockArchivedState = { data: { success: true, data: [] }, isLoading: false };
  mockHighlightsState = { data: HIGHLIGHTS, isLoading: false };
});

describe("MyStories", () => {
  it("renders a card per story with its total view count", () => {
    render(<MyStories />);
    expect(screen.getAllByTestId("my-story-card")).toHaveLength(2);
    expect(screen.getByTestId("my-stories-total-views")).toHaveTextContent("16");
  });

  it("opens the viewers sheet for the story whose view count was clicked", () => {
    render(<MyStories />);
    expect(screen.queryByTestId("viewers-sheet-stub")).not.toBeInTheDocument();
    fireEvent.click(screen.getAllByTestId("my-story-views")[1]);
    expect(screen.getByTestId("viewers-sheet-stub")).toHaveTextContent("s-2");
  });

  it("adds a story to an existing highlight", async () => {
    render(<MyStories />);
    fireEvent.click(screen.getAllByTestId("my-story-highlight")[0]);

    const options = screen.getAllByTestId("highlight-picker-option");
    expect(options).toHaveLength(2);
    fireEvent.click(options[0]);

    await waitFor(() => expect(mockAddToHighlight).toHaveBeenCalledTimes(1));
    expect(mockAddToHighlight).toHaveBeenCalledWith({
      highlightId: "h-1",
      storyId: "s-1",
    });
  });

  it("creates a new highlight from the picker, seeded with the story", async () => {
    render(<MyStories />);
    fireEvent.click(screen.getAllByTestId("my-story-highlight")[1]);
    fireEvent.click(screen.getByTestId("highlight-picker-new"));
    fireEvent.change(screen.getByTestId("highlight-picker-title"), {
      target: { value: " Trip " },
    });
    fireEvent.click(screen.getByTestId("highlight-picker-create"));

    await waitFor(() => expect(mockCreateHighlight).toHaveBeenCalledTimes(1));
    expect(mockCreateHighlight).toHaveBeenCalledWith({ title: "Trip", storyId: "s-2" });
    expect(mockAddToHighlight).not.toHaveBeenCalled();
  });

  it("deletes a story only after the confirmation is answered", async () => {
    render(<MyStories />);
    fireEvent.click(screen.getAllByTestId("my-story-delete")[0]);
    expect(mockDeleteStory).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(mockDeleteStory).toHaveBeenCalledTimes(1));
    expect(mockDeleteStory).toHaveBeenCalledWith("s-1");
  });

  it("keeps the delete dialog shut when the confirmation is cancelled", () => {
    render(<MyStories />);
    fireEvent.click(screen.getAllByTestId("my-story-delete")[0]);
    fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
    expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument();
    expect(mockDeleteStory).not.toHaveBeenCalled();
  });
});
