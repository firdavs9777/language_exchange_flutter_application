import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import StoriesFeed from "./StoriesFeed";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  useNavigate: () => mockNavigate,
  Link: ({ to, children, ...rest }: any) => (
    <a href={to} {...rest}>
      {children}
    </a>
  ),
}));

let mockUserId: string | null = "me";
jest.mock("react-redux", () => ({
  useSelector: (selector: any) =>
    selector({
      auth: { userInfo: mockUserId ? { user: { _id: mockUserId, name: "Me" } } : undefined },
    }),
}));

let mockFeed: any;
let mockMine: any;
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetStoryFeedsQuery: () => mockFeed,
  useGetMyStoriesQuery: () => mockMine,
}));

beforeEach(() => {
  mockUserId = "me";
  mockFeed = { data: { success: true, data: [] }, isLoading: false };
  mockMine = { data: { success: true, data: [] }, isLoading: false };
});

it("offers the author a way into their own stories from their own ring", () => {
  render(<StoriesFeed />);
  expect(screen.getByTestId("my-stories-link")).toHaveAttribute("href", "/stories/mine");
});

it("still offers it once the author has stories of their own", () => {
  mockMine = { data: { success: true, data: [{ _id: "s-1" }] }, isLoading: false };
  render(<StoriesFeed />);
  expect(screen.getByTestId("my-stories-link")).toHaveAttribute("href", "/stories/mine");
});

it("shows nothing to a signed-out visitor, who has no stories page", () => {
  mockUserId = null;
  render(<StoriesFeed />);
  expect(screen.queryByTestId("my-stories-link")).toBeNull();
});

it("opens the composer from an empty own ring and the viewer once there are stories", () => {
  render(<StoriesFeed />);
  fireEvent.click(screen.getByTestId("my-story-ring"));
  expect(mockNavigate).toHaveBeenCalledWith("/create-story");

  mockNavigate.mockClear();
  mockMine = { data: { success: true, data: [{ _id: "s-1" }] }, isLoading: false };
  render(<StoriesFeed />);
  fireEvent.click(screen.getAllByTestId("my-story-ring")[1]);
  expect(mockNavigate).toHaveBeenCalledWith("/stories/me", { state: { startIndex: 0 } });
});

it("rings an author with unseen stories differently from one already seen", () => {
  mockFeed = {
    data: {
      success: true,
      data: [
        { user: { _id: "a-1", name: "Ann" }, stories: [{ _id: "s" }], hasUnviewed: 1 },
        { user: { _id: "a-2", name: "Bo" }, stories: [{ _id: "s" }], hasUnviewed: 0 },
      ],
    },
    isLoading: false,
  };
  render(<StoriesFeed />);
  // The gradient collar is the "there is something new here" signal; a seen
  // author gets the flat hairline. Both are classes now -- the old row drew
  // two SVG gradients per ring.
  expect(screen.getByTestId("story-ring-a-1").className).toContain("from-brand");
  expect(screen.getByTestId("story-ring-a-2").className).toContain("bg-line-strong");

  fireEvent.click(screen.getByTestId("story-ring-a-1"));
  expect(mockNavigate).toHaveBeenCalledWith("/stories/a-1", { state: { startIndex: 0 } });
});

it("draws skeleton rings rather than an empty row while the feed loads", () => {
  mockFeed = { data: undefined, isLoading: true };
  render(<StoriesFeed />);
  expect(screen.getByTestId("stories-feed-loading")).toBeInTheDocument();
  expect(screen.queryByTestId("stories-feed")).toBeNull();
});
