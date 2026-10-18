import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import Highlights from "./Highlights";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

const mockCreate = jest.fn();
const mockUpdate = jest.fn();
const mockDelete = jest.fn();
const mockRemoveStory = jest.fn();

let mockHighlightsState: any;
let mockMyStoriesState: any;
let mockArchivedState: any;

jest.mock("../../store/slices/storiesSlice", () => ({
  useGetHighlightsQuery: () => mockHighlightsState,
  useGetMyStoriesQuery: () => mockMyStoriesState,
  useGetArchivedStoriesQuery: () => mockArchivedState,
  useCreateHighlightMutation: () => [mockCreate, { isLoading: false }],
  useUpdateHighlightMutation: () => [mockUpdate, { isLoading: false }],
  useDeleteHighlightMutation: () => [mockDelete, { isLoading: false }],
  useRemoveStoryFromHighlightMutation: () => [mockRemoveStory, { isLoading: false }],
}));

jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn() },
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });

const HIGHLIGHTS = {
  success: true,
  data: [
    {
      _id: "h-1",
      title: "Seoul",
      coverImage: "https://cdn/cover-1.jpg",
      storyCount: 2,
      stories: [
        { story: { _id: "s-1", mediaType: "image", mediaUrls: ["https://cdn/s1.jpg"] } },
        { story: { _id: "s-2", mediaType: "image", mediaUrls: ["https://cdn/s2.jpg"] } },
      ],
    },
  ],
};

const MY_STORIES = {
  success: true,
  data: [
    { _id: "s-1", mediaType: "image", mediaUrls: ["https://cdn/s1.jpg"], createdAt: "2026-09-20T00:00:00Z" },
    { _id: "s-2", mediaType: "image", mediaUrls: ["https://cdn/s2.jpg"], createdAt: "2026-09-21T00:00:00Z" },
  ],
};

const ARCHIVED = {
  success: true,
  data: [
    { _id: "s-9", mediaType: "text", text: "Old one", backgroundColor: "#222", createdAt: "2026-08-01T00:00:00Z" },
  ],
};

beforeEach(() => {
  jest.clearAllMocks();
  mockCreate.mockReturnValue(resolved());
  mockUpdate.mockReturnValue(resolved());
  mockDelete.mockReturnValue(resolved());
  mockRemoveStory.mockReturnValue(resolved());
  mockHighlightsState = { data: HIGHLIGHTS, isLoading: false, error: undefined };
  mockMyStoriesState = { data: MY_STORIES, isLoading: false, error: undefined };
  mockArchivedState = { data: ARCHIVED, isLoading: false, error: undefined };
});

describe("Highlights", () => {
  it("lists each highlight with its cover and story count", () => {
    render(<Highlights />);
    const cards = screen.getAllByTestId("highlight-card");
    expect(cards).toHaveLength(1);
    expect(screen.getByText("Seoul")).toBeInTheDocument();
    expect(screen.getByTestId("highlight-card-cover")).toHaveAttribute(
      "src",
      "https://cdn/cover-1.jpg"
    );
  });

  it("shows an empty state when there are no highlights", () => {
    mockHighlightsState = { data: { success: true, data: [] }, isLoading: false, error: undefined };
    render(<Highlights />);
    expect(screen.getByTestId("highlights-empty")).toBeInTheDocument();
  });

  it("creates a highlight from a chosen story, sending title and storyId", async () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-create-open"));

    fireEvent.change(screen.getByTestId("highlight-title-input"), {
      target: { value: "  Trip  " },
    });
    // Active and archived stories are both offered as the first story / cover.
    const options = screen.getAllByTestId("highlight-source-story");
    expect(options).toHaveLength(3);
    fireEvent.click(options[0]);
    fireEvent.click(screen.getByTestId("highlight-create-submit"));

    await waitFor(() => expect(mockCreate).toHaveBeenCalledTimes(1));
    expect(mockCreate).toHaveBeenCalledWith({ title: "Trip", storyId: "s-1" });
  });

  it("creates an empty highlight when no story is picked", async () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-create-open"));
    fireEvent.change(screen.getByTestId("highlight-title-input"), {
      target: { value: "Later" },
    });
    fireEvent.click(screen.getByTestId("highlight-create-submit"));

    await waitFor(() => expect(mockCreate).toHaveBeenCalledTimes(1));
    expect(mockCreate).toHaveBeenCalledWith({ title: "Later" });
  });

  it("refuses to create a highlight without a title", () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-create-open"));
    fireEvent.click(screen.getByTestId("highlight-create-submit"));
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it("renames a highlight and sets a new cover in one update call", async () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-edit-open"));

    fireEvent.change(screen.getByTestId("highlight-edit-title"), {
      target: { value: "Seoul trip" },
    });
    const covers = screen.getAllByTestId("highlight-cover-option");
    expect(covers).toHaveLength(2);
    fireEvent.click(covers[1]);
    fireEvent.click(screen.getByTestId("highlight-edit-submit"));

    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1));
    expect(mockUpdate).toHaveBeenCalledWith({
      highlightId: "h-1",
      title: "Seoul trip",
      coverImage: "https://cdn/s2.jpg",
    });
  });

  it("sends only the title when the cover was not touched", async () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-edit-open"));
    fireEvent.change(screen.getByTestId("highlight-edit-title"), {
      target: { value: "Seoul 2026" },
    });
    fireEvent.click(screen.getByTestId("highlight-edit-submit"));

    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1));
    expect(mockUpdate).toHaveBeenCalledWith({
      highlightId: "h-1",
      title: "Seoul 2026",
    });
  });

  it("deletes a highlight only after the confirmation is answered", async () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-delete-open"));
    expect(mockDelete).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(mockDelete).toHaveBeenCalledTimes(1));
    expect(mockDelete).toHaveBeenCalledWith("h-1");
  });

  it("opens a highlight and removes a story from it", async () => {
    render(<Highlights />);
    fireEvent.click(screen.getByTestId("highlight-open"));

    const tiles = screen.getAllByTestId("highlight-story-tile");
    expect(tiles).toHaveLength(2);

    fireEvent.click(screen.getAllByTestId("highlight-story-remove")[1]);
    await waitFor(() => expect(mockRemoveStory).toHaveBeenCalledTimes(1));
    expect(mockRemoveStory).toHaveBeenCalledWith({
      highlightId: "h-1",
      storyId: "s-2",
    });
  });
});
