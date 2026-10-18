import React from "react";
import { render, screen, act, waitFor } from "@testing-library/react";
import { useReelsFeed, ReelsFeed } from "./useReelsFeed";

const mockTrigger = jest.fn();
jest.mock("../../store/slices/reelsSlice", () => ({
  useLazyGetReelsPageQuery: () => [mockTrigger],
}));

const reel = (id: string, authorId = "a") => ({
  id, description: "", language: "ko", likeCount: 0, commentCount: 0, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: `https://cdn.test/${id}.mp4`, thumbnail: null, duration: null, portrait: true,
  author: { id: authorId, name: "A", avatar: undefined },
});
const page = (ids: string[], nextCursor: string | null) => ({
  unwrap: () => Promise.resolve({ reels: ids.map((i) => reel(i)), nextCursor }),
});
const fail = (status: any) => ({ unwrap: () => Promise.reject({ status }) });

let feed: ReelsFeed;
function Probe() {
  feed = useReelsFeed();
  return <span data-testid="ids">{feed.status + ":" + feed.reels.map((r) => r.id).join(",")}</span>;
}
const ids = () => screen.getByTestId("ids").textContent;

beforeEach(() => mockTrigger.mockReset());

it("loads the first page without a cursor, then the next with the server's cursor", async () => {
  mockTrigger.mockReturnValueOnce(page(["a", "b"], "c1")).mockReturnValueOnce(page(["b", "c"], null));
  render(<Probe />);
  await waitFor(() => expect(ids()).toBe("ready:a,b"));
  expect(mockTrigger.mock.calls[0][0]).toEqual({ before: null });
  expect(feed.hasMore).toBe(true);
  await act(async () => feed.loadMore());
  expect(mockTrigger.mock.calls[1][0]).toEqual({ before: "c1" });
  expect(ids()).toBe("ready:a,b,c");
  expect(feed.hasMore).toBe(false);
  await act(async () => feed.loadMore());
  expect(mockTrigger).toHaveBeenCalledTimes(2);
});

it("a 404 means reels are switched off; anything else can be retried", async () => {
  mockTrigger.mockReturnValueOnce(fail(404));
  const { unmount } = render(<Probe />);
  await waitFor(() => expect(ids()).toBe("unavailable:"));
  unmount();
  mockTrigger.mockReturnValueOnce(fail("FETCH_ERROR")).mockReturnValueOnce(page(["a"], null));
  render(<Probe />);
  await waitFor(() => expect(ids()).toBe("error:"));
  await act(async () => feed.reload());
  expect(ids()).toBe("ready:a");
});

it("patches and removes reels locally (likes, blocks, deletes)", async () => {
  mockTrigger.mockReturnValueOnce(page(["a", "b"], null));
  render(<Probe />);
  await waitFor(() => expect(ids()).toBe("ready:a,b"));
  act(() => feed.patchReel("a", { likeCount: 5, isLiked: true }));
  expect(feed.reels[0].likeCount).toBe(5);
  act(() => feed.removeWhere((r) => r.id === "b"));
  expect(ids()).toBe("ready:a");
});
