import "@testing-library/jest-dom";
import React from "react";
import { MemoryRouter } from "react-router-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import ReelActions from "./ReelActions";

const mockLike = jest.fn();
const mockDislike = jest.fn();
const mockShare = jest.fn();
jest.mock("../../store/slices/momentsSlice", () => ({
  useLikeMomentMutation: () => [mockLike, { isLoading: false }],
  useDislikeMomentMutation: () => [mockDislike, { isLoading: false }],
  useShareMomentMutation: () => [mockShare, { isLoading: false }],
}));
jest.mock("../moments/comments/CommentList", () => ({
  __esModule: true,
  default: (p: any) => (
    <div data-testid="comment-list-stub" data-moment={p.momentId}>
      <button onClick={() => p.onTotalChange && p.onTotalChange(7)}>total</button>
    </div>
  ),
}));
jest.mock("../linking/ShareButton", () => ({
  __esModule: true,
  default: (p: any) => <button data-testid="share-stub" data-type={p.type} data-id={p.id} />,
}));
jest.mock("../moments/actions/ReportMomentDialog", () => ({
  __esModule: true,
  default: (p: any) => <div data-testid="report-stub">{`${p.type}:${p.targetId}:${p.authorId}`}</div>,
}));
jest.mock("../moments/actions/BlockAuthorDialog", () => ({
  __esModule: true,
  default: (p: any) => (
    <button data-testid="block-stub" onClick={() => p.onBlocked && p.onBlocked()}>
      {p.authorId}
    </button>
  ),
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const ok = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const reel = (over: any = {}) => ({
  id: "r1", description: "hi", language: "ko", likeCount: 2, commentCount: 1, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: "https://cdn.test/r1.mp4", thumbnail: null, duration: null, portrait: true,
  author: { id: "u9", name: "Mina", avatar: undefined }, ...over,
});

function renderActions(r: any = reel()) {
  const onPatch = jest.fn();
  const onAuthorBlocked = jest.fn();
  render(
    <MemoryRouter>
      <ReelActions reel={r} myUserId="me" onPatch={onPatch} onAuthorBlocked={onAuthorBlocked} />
    </MemoryRouter>
  );
  return { onPatch, onAuthorBlocked };
}

beforeEach(() => {
  [mockLike, mockDislike, mockShare].forEach((m) => {
    m.mockReset();
    m.mockReturnValue(ok());
  });
});

it("likes optimistically with the app's request", async () => {
  const { onPatch } = renderActions();
  fireEvent.click(screen.getByTestId("reel-like"));
  expect(onPatch).toHaveBeenCalledWith({ isLiked: true, likeCount: 3 });
  await waitFor(() => expect(mockLike).toHaveBeenCalledWith({ momentId: "r1", userId: "me" }));
});

it("unlikes through /dislike, and rolls back when the server refuses", async () => {
  mockDislike.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  const { onPatch } = renderActions(reel({ isLiked: true, likeCount: 3 }));
  fireEvent.click(screen.getByTestId("reel-like"));
  expect(onPatch).toHaveBeenNthCalledWith(1, { isLiked: false, likeCount: 2 });
  await waitFor(() => expect(onPatch).toHaveBeenNthCalledWith(2, { isLiked: true, likeCount: 3 }));
});

it("treats 'Already liked' as liked (a double tap from another device)", async () => {
  mockLike.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { message: "Already liked" } }) });
  const { onPatch } = renderActions();
  fireEvent.click(screen.getByTestId("reel-like"));
  await waitFor(() => expect(mockLike).toHaveBeenCalled());
  expect(onPatch).toHaveBeenCalledTimes(1);
});

it("opens the comments of this reel and follows the server's total", () => {
  const { onPatch } = renderActions();
  fireEvent.click(screen.getByTestId("reel-comments"));
  expect(screen.getByTestId("comment-list-stub")).toHaveAttribute("data-moment", "r1");
  fireEvent.click(screen.getByText("total"));
  expect(onPatch).toHaveBeenCalledWith({ commentCount: 7 });
  fireEvent.click(screen.getByTestId("reel-comments-close"));
  expect(screen.queryByTestId("reel-comments-drawer")).not.toBeInTheDocument();
});

it("shares the moment link and counts the share", () => {
  const { onPatch } = renderActions();
  const share = screen.getByTestId("share-stub");
  expect(share).toHaveAttribute("data-type", "moment");
  expect(share).toHaveAttribute("data-id", "r1");
  fireEvent.click(screen.getByTestId("reel-share"));
  expect(mockShare).toHaveBeenCalledWith("r1");
  expect(onPatch).toHaveBeenCalledWith({ shareCount: 1 });
});

it("reports through the Report collection, typed as a moment", () => {
  renderActions();
  fireEvent.click(screen.getByTestId("reel-more"));
  fireEvent.click(screen.getByTestId("reel-report"));
  expect(screen.getByTestId("report-stub")).toHaveTextContent("moment:r1:u9");
});

it("blocks the author and tells the viewer to drop their reels", () => {
  const { onAuthorBlocked } = renderActions();
  fireEvent.click(screen.getByTestId("reel-more"));
  fireEvent.click(screen.getByTestId("reel-block"));
  fireEvent.click(screen.getByTestId("block-stub"));
  expect(onAuthorBlocked).toHaveBeenCalledWith("u9");
});

it("links the author to their profile", () => {
  renderActions();
  expect(screen.getByTestId("reel-author-link")).toHaveAttribute("href", "/profile/u9");
});
