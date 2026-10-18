import { normalizeReel, mergeReels, formatReelDuration, REEL_MAX_SECONDS } from "./reelModel";

const full = {
  _id: "r1",
  description: "hello",
  language: "ko",
  likeCount: 3,
  commentCount: 2,
  shareCount: 1,
  isLiked: true,
  isSaved: false,
  createdAt: "2026-10-01T00:00:00.000Z",
  mediaType: "video",
  video: { url: "https://cdn.test/r.mp4", thumbnail: "https://cdn.test/r.jpg", duration: 12.4, width: 720, height: 1280 },
  user: { _id: "u1", name: "Mina", images: ["https://cdn.test/a.jpg"] },
};

it("keeps every field the viewer reads", () => {
  expect(normalizeReel(full)).toEqual({
    id: "r1",
    description: "hello",
    language: "ko",
    likeCount: 3,
    commentCount: 2,
    shareCount: 1,
    isLiked: true,
    createdAt: "2026-10-01T00:00:00.000Z",
    videoUrl: "https://cdn.test/r.mp4",
    thumbnail: "https://cdn.test/r.jpg",
    duration: 12.4,
    portrait: true,
    author: { id: "u1", name: "Mina", avatar: "https://cdn.test/a.jpg" },
  });
});

it("survives a 2.6.1 reel: no thumbnail, zero duration, unpopulated user, no counts", () => {
  const r = normalizeReel({ _id: "r2", video: { url: "https://cdn.test/x.mp4", duration: 0 }, user: "u9" });
  expect(r).not.toBe(null);
  expect(r!.thumbnail).toBe(null);
  expect(r!.duration).toBe(null);
  expect(r!.author).toEqual({ id: "u9", name: "", avatar: undefined });
  expect(r!.likeCount).toBe(0);
  expect(r!.commentCount).toBe(0);
  expect(r!.isLiked).toBe(false);
  expect(r!.description).toBe("");
  expect(r!.portrait).toBe(true); // unknown size: assume the 9:16 the app records
});

it("drops rows that cannot play", () => {
  expect(normalizeReel(null)).toBe(null);
  expect(normalizeReel({ _id: "r3" })).toBe(null);
  expect(normalizeReel({ _id: "r4", video: { url: "" } })).toBe(null);
  expect(normalizeReel({ video: { url: "https://cdn.test/x.mp4" } })).toBe(null);
});

it("reads a landscape video as landscape", () => {
  expect(normalizeReel({ ...full, video: { ...full.video, width: 1920, height: 1080 } })!.portrait).toBe(false);
});

it("merges pages without duplicates (a score cursor can repeat a boundary item)", () => {
  const a = normalizeReel(full)!;
  const b = normalizeReel({ ...full, _id: "r5" })!;
  expect(mergeReels([a], [a, b]).map((r) => r.id)).toEqual(["r1", "r5"]);
});

it("formats durations and caps reels at 180 s", () => {
  expect(REEL_MAX_SECONDS).toBe(180);
  expect(formatReelDuration(65.7)).toBe("1:05");
  expect(formatReelDuration(0)).toBe(null);
  expect(formatReelDuration(undefined)).toBe(null);
});
