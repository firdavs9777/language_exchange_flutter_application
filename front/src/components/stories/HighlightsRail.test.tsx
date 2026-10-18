import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import HighlightsRail from "./HighlightsRail";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockGetUserHighlights = jest.fn();
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetUserHighlightsQuery: (arg: any, opts: any) => mockGetUserHighlights(arg, opts),
}));

const idle = { data: undefined, isLoading: false, error: undefined };

const HIGHLIGHTS = {
  success: true,
  count: 2,
  data: [
    {
      _id: "h-1",
      title: "Seoul",
      coverImage: "https://cdn/cover-1.jpg",
      storyCount: 2,
      stories: [
        {
          story: {
            _id: "s-1",
            mediaType: "image",
            mediaUrls: ["https://cdn/s1.jpg"],
          },
          addedAt: "2026-09-01T00:00:00Z",
        },
        {
          story: {
            _id: "s-2",
            mediaType: "text",
            text: "Hello there",
            backgroundColor: "#123456",
          },
          addedAt: "2026-09-02T00:00:00Z",
        },
      ],
    },
    {
      _id: "h-2",
      title: "Food",
      coverImage: "",
      storyCount: 1,
      stories: [
        {
          story: { _id: "s-3", mediaType: "image", mediaUrls: ["https://cdn/s3.jpg"] },
          addedAt: "2026-09-03T00:00:00Z",
        },
      ],
    },
  ],
};

beforeEach(() => {
  mockGetUserHighlights.mockReset();
  mockGetUserHighlights.mockReturnValue(idle);
});

describe("HighlightsRail", () => {
  it("asks for the profile owner's highlights and skips without a user id", () => {
    render(<HighlightsRail userId="" name="Mina" />);
    expect(mockGetUserHighlights).toHaveBeenCalledWith("", { skip: true });
    expect(screen.queryByTestId("highlights-rail")).not.toBeInTheDocument();
  });

  it("renders nothing at all when the person has no highlights", () => {
    mockGetUserHighlights.mockReturnValue({
      ...idle,
      data: { success: true, count: 0, data: [] },
    });
    render(<HighlightsRail userId="u-1" name="Mina" />);
    expect(mockGetUserHighlights).toHaveBeenCalledWith("u-1", { skip: false });
    expect(screen.queryByTestId("highlights-rail")).not.toBeInTheDocument();
  });

  it("renders one tile per highlight, with the cover falling back to the first story", () => {
    mockGetUserHighlights.mockReturnValue({ ...idle, data: HIGHLIGHTS });
    render(<HighlightsRail userId="u-1" name="Mina" />);

    const tiles = screen.getAllByTestId("highlight-rail-item");
    expect(tiles).toHaveLength(2);
    expect(screen.getByText("Seoul")).toBeInTheDocument();
    expect(screen.getByText("Food")).toBeInTheDocument();

    const covers = screen.getAllByTestId("highlight-rail-cover");
    expect(covers[0]).toHaveAttribute("src", "https://cdn/cover-1.jpg");
    // No coverImage on the second: the first story's media stands in.
    expect(covers[1]).toHaveAttribute("src", "https://cdn/s3.jpg");
  });

  it("opens the highlight's own stories in the viewer overlay and closes again", () => {
    mockGetUserHighlights.mockReturnValue({ ...idle, data: HIGHLIGHTS });
    render(<HighlightsRail userId="u-1" name="Mina" />);

    expect(screen.queryByTestId("highlight-story-viewer")).not.toBeInTheDocument();
    fireEvent.click(screen.getAllByTestId("highlight-rail-item")[0]);

    expect(screen.getByTestId("highlight-story-viewer")).toBeInTheDocument();
    expect(screen.getByTestId("highlight-story-image")).toHaveAttribute(
      "src",
      "https://cdn/s1.jpg"
    );
    expect(screen.getByTestId("highlight-story-position")).toHaveTextContent("1/2");

    fireEvent.click(screen.getByTestId("highlight-story-next"));
    expect(screen.getByTestId("highlight-story-text")).toHaveTextContent("Hello there");
    expect(screen.getByTestId("highlight-story-position")).toHaveTextContent("2/2");

    fireEvent.click(screen.getByTestId("highlight-story-close"));
    expect(screen.queryByTestId("highlight-story-viewer")).not.toBeInTheDocument();
  });

  it("drops a highlight that has neither a cover nor a story to show", () => {
    mockGetUserHighlights.mockReturnValue({
      ...idle,
      data: {
        success: true,
        data: [{ _id: "h-9", title: "Empty", coverImage: "", storyCount: 0, stories: [] }],
      },
    });
    render(<HighlightsRail userId="u-1" name="Mina" />);
    expect(screen.queryByTestId("highlights-rail")).not.toBeInTheDocument();
  });
});
