import "@testing-library/jest-dom";
import React from "react";
import { MemoryRouter } from "react-router-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import ReelsGridPage from "./ReelsGridPage";

let mockFeed: any;
jest.mock("./useReelsFeed", () => ({ useReelsFeed: () => mockFeed }));
jest.mock("./ReelPolicyGate", () => ({ __esModule: true, default: (p: any) => <>{p.children}</> }));
jest.mock("react-redux", () => ({
  ...jest.requireActual("react-redux"),
  useSelector: (fn: any) => fn({ auth: { userInfo: { token: "t", user: { _id: "me" } } } }),
}));
jest.mock("./ReelActions", () => ({ __esModule: true, default: () => null }));
jest.mock("./ReelViewer", () => ({
  __esModule: true,
  default: (p: any) => <div data-testid="viewer-stub">{p.reels[p.index].id}</div>,
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const reel = (id: string, extra: any = {}) => ({
  id, description: "caption " + id, language: "ko", likeCount: 4, commentCount: 1, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: `https://cdn.test/${id}.mp4`, thumbnail: `https://cdn.test/${id}.jpg`, duration: 65,
  portrait: true, author: { id: "u", name: "Mina", avatar: undefined }, ...extra,
});
const feed = (over: any = {}) => ({
  reels: [], status: "ready", hasMore: false, loadingMore: false,
  loadMore: jest.fn(), reload: jest.fn(), patchReel: jest.fn(), removeWhere: jest.fn(), ...over,
});
const renderPage = () =>
  render(
    <MemoryRouter>
      <ReelsGridPage />
    </MemoryRouter>
  );

it("draws a tile per reel with its thumbnail, duration and likes", () => {
  mockFeed = feed({ reels: [reel("a"), reel("b")] });
  renderPage();
  const tile = screen.getByTestId("reel-tile-a");
  expect(tile.querySelector("img")).toHaveAttribute("src", "https://cdn.test/a.jpg");
  expect(tile).toHaveTextContent("1:05");
  expect(tile).toHaveTextContent("4");
  expect(screen.getByTestId("reel-tile-b")).toBeInTheDocument();
});

it("falls back to the video's first frame when there is no thumbnail (2.6.1 reels)", () => {
  mockFeed = feed({ reels: [reel("a", { thumbnail: null, duration: null })] });
  renderPage();
  const video = screen.getByTestId("reel-tile-a").querySelector("video") as HTMLVideoElement;
  expect(video).toHaveAttribute("src", "https://cdn.test/a.mp4#t=0.1");
  expect(video).toHaveAttribute("preload", "metadata");
  expect(video.muted).toBe(true);
});

it("loads more only when the server said there is more", () => {
  mockFeed = feed({ reels: [reel("a")], hasMore: true });
  const { unmount } = renderPage();
  fireEvent.click(screen.getByTestId("reels-load-more"));
  expect(mockFeed.loadMore).toHaveBeenCalled();
  unmount();
  mockFeed = feed({ reels: [reel("a")], hasMore: false });
  renderPage();
  expect(screen.queryByTestId("reels-load-more")).not.toBeInTheDocument();
});

it("offers to create a reel, and says so when there are none yet", () => {
  mockFeed = feed();
  renderPage();
  expect(screen.getByTestId("reels-empty")).toBeInTheDocument();
  expect(screen.getByTestId("reels-create")).toHaveAttribute("href", "/reels/new");
});

it("says reels are unavailable on a 404, and offers a retry on other errors", () => {
  mockFeed = feed({ status: "unavailable" });
  const { unmount } = renderPage();
  expect(screen.getByTestId("reels-unavailable")).toBeInTheDocument();
  expect(screen.queryByTestId("reels-create")).not.toBeInTheDocument();
  unmount();
  mockFeed = feed({ status: "error" });
  renderPage();
  fireEvent.click(screen.getByTestId("reels-retry"));
  expect(mockFeed.reload).toHaveBeenCalled();
});

it("opens the viewer on the clicked reel and puts it in the URL", () => {
  mockFeed = feed({ reels: [reel("a"), reel("b")] });
  renderPage();
  fireEvent.click(screen.getByTestId("reel-tile-b"));
  expect(screen.getByTestId("viewer-stub")).toHaveTextContent("b");
});
