import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import StoryLinkPage, { storyIndexIn } from "./StoryLinkPage";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
let mockUser: any = { user: { _id: "me" } };
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: mockUser } }) }));
jest.mock("../linking/OpenInApp", () => (p: any) => (
  <button data-testid="open-in-app" data-type={p.type} data-id={p.id}>open</button>
));
jest.mock("../Loader", () => () => <div data-testid="loader" />);

const mockStory = jest.fn();
const mockUserStories = jest.fn();
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetIndividualStoryQuery: (...a: any[]) => mockStory(...a),
  useGetUserStoriesQuery: (...a: any[]) => mockUserStories(...a),
}));

const ID = "507f1f77bcf86cd799439011";
const AUTHOR = "60d5ec49f1b2c72b9c8e4a11";

const Where = () => {
  const loc = useLocation();
  return <div data-testid="where">{`${loc.pathname}${loc.search}|${JSON.stringify(loc.state)}`}</div>;
};
const renderAt = (id = ID) => render(
  <MemoryRouter initialEntries={[`/story/${id}`]}>
    <Routes>
      <Route path="/story/:id" element={<StoryLinkPage />} />
      <Route path="*" element={<Where />} />
    </Routes>
  </MemoryRouter>);

beforeEach(() => {
  mockUser = { user: { _id: "me" } };
  mockStory.mockReset().mockReturnValue({ isFetching: true });
  mockUserStories.mockReset().mockReturnValue({});
});

test("signed out: a sign-in card that comes back here, plus Open in app; no fetch", () => {
  mockUser = null;
  renderAt();
  expect(mockStory).toHaveBeenCalledWith(ID, { skip: true });
  expect(screen.getByText("stories.linkPage.sign_in_title")).toBeInTheDocument();
  expect(screen.getByRole("link", { name: "stories.linkPage.sign_in" }))
    .toHaveAttribute("href", `/login?redirect=${encodeURIComponent(`/story/${ID}`)}`);
  expect(screen.getByTestId("open-in-app")).toHaveAttribute("data-type", "story");
  expect(screen.getByTestId("open-in-app")).toHaveAttribute("data-id", ID);
});

test("signed in: opens the author's viewer on this story", () => {
  mockStory.mockReturnValue({ currentData: { success: true, data: { _id: ID, user: { _id: AUTHOR, name: "Mina" } } } });
  mockUserStories.mockReturnValue({ currentData: { success: true, data: [{ _id: "s0" }, { _id: ID }, { _id: "s2" }] } });
  renderAt();
  expect(mockUserStories).toHaveBeenLastCalledWith(AUTHOR, { skip: false });
  expect(screen.getByTestId("where")).toHaveTextContent(`/stories/${AUTHOR}|{"startIndex":1}`);
});

test("an unpopulated author id works too, and a missing story in the list starts at 0", () => {
  mockStory.mockReturnValue({ currentData: { success: true, data: { _id: ID, user: AUTHOR } } });
  mockUserStories.mockReturnValue({ currentData: [{ _id: "other" }] });
  renderAt();
  expect(screen.getByTestId("where")).toHaveTextContent(`/stories/${AUTHOR}|{"startIndex":0}`);
});

test("the author's list failing still opens the viewer (it shows its own error)", () => {
  mockStory.mockReturnValue({ currentData: { data: { _id: ID, user: { _id: AUTHOR } } } });
  mockUserStories.mockReturnValue({ error: { status: 500 } });
  renderAt();
  expect(screen.getByTestId("where")).toHaveTextContent(`/stories/${AUTHOR}`);
});

test("404 says the story expired, with a way to current stories", () => {
  mockStory.mockReturnValue({ error: { status: 404 } });
  renderAt();
  expect(screen.getByText("stories.linkPage.expired")).toBeInTheDocument();
  expect(screen.getByRole("link", { name: "stories.linkPage.browse" })).toHaveAttribute("href", "/stories");
});

test("403 says it is not available to you", () => {
  mockStory.mockReturnValue({ error: { status: 403 } });
  renderAt();
  expect(screen.getByText("stories.linkPage.unavailable")).toBeInTheDocument();
});

test("other errors offer Try again", () => {
  const refetch = jest.fn();
  mockStory.mockReturnValue({ error: { status: "FETCH_ERROR" }, refetch });
  renderAt();
  fireEvent.click(screen.getByRole("button", { name: "stories.linkPage.retry" }));
  expect(refetch).toHaveBeenCalled();
});

test("a malformed id never hits the API and reads as expired", () => {
  renderAt("not-an-id");
  expect(mockStory).toHaveBeenCalledWith("not-an-id", { skip: true });
  expect(screen.getByText("stories.linkPage.expired")).toBeInTheDocument();
});

test("stale data for another story id is not followed", () => {
  mockStory.mockReturnValue({ currentData: { data: { _id: "someone-else", user: { _id: AUTHOR } } }, isFetching: true });
  renderAt();
  expect(screen.getByTestId("loader")).toBeInTheDocument();
});

test("storyIndexIn", () => {
  expect(storyIndexIn([{ _id: "a" }, { _id: "b" }], "b")).toBe(1);
  expect(storyIndexIn([{ _id: "a" }], "zzz")).toBe(0);
  expect(storyIndexIn([], "a")).toBe(0);
});
