import { userAvatarUrl } from "../../../utils/photoUrl";

/** Server cap for a reel (be/lib/reelsFeed.js isReelOverCap). */
export const REEL_MAX_SECONDS = 180;
/** The app's page size (bananatalk_app reels_api_client.dart). */
export const REELS_PAGE_SIZE = 12;

export interface ReelAuthor {
  id: string;
  name: string;
  avatar: string | undefined;
}

/** The only shape reel components read. Built by normalizeReel. */
export interface Reel {
  id: string;
  description: string;
  language: string;
  likeCount: number;
  commentCount: number;
  shareCount: number;
  isLiked: boolean;
  createdAt: string;
  videoUrl: string;
  thumbnail: string | null;
  /** Seconds, or null when the server never measured it (old rows store 0). */
  duration: number | null;
  /** True unless the stored size says landscape; the app records 9:16. */
  portrait: boolean;
  author: ReelAuthor;
}

const num = (v: any): number => (typeof v === "number" && isFinite(v) && v > 0 ? v : 0);

/**
 * One feed row -> Reel, or null when it cannot play (no id or no video url).
 * Tolerates what app 2.6.1 and the first reels wrote: no thumbnail, a 0 or
 * missing duration, an unpopulated `user` id string, missing counters.
 */
export function normalizeReel(raw: any): Reel | null {
  if (!raw || typeof raw !== "object") return null;
  const id = raw._id ? String(raw._id) : "";
  const video = raw.video && typeof raw.video === "object" ? raw.video : null;
  const videoUrl = video && typeof video.url === "string" ? video.url.trim() : "";
  if (!id || !videoUrl) return null;

  const user = raw.user;
  const author: ReelAuthor =
    user && typeof user === "object"
      ? { id: String(user._id || ""), name: String(user.name || ""), avatar: userAvatarUrl(user) }
      : { id: user ? String(user) : "", name: "", avatar: undefined };

  const width = num(video.width);
  const height = num(video.height);
  const duration = num(video.duration);

  return {
    id,
    description: typeof raw.description === "string" ? raw.description : "",
    language: typeof raw.language === "string" ? raw.language : "",
    likeCount: num(raw.likeCount),
    commentCount: num(raw.commentCount),
    shareCount: num(raw.shareCount),
    isLiked: raw.isLiked === true,
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : "",
    videoUrl,
    thumbnail: typeof video.thumbnail === "string" && video.thumbnail ? video.thumbnail : null,
    duration: duration || null,
    portrait: width && height ? height >= width : true,
    author,
  };
}

/**
 * Append a page, dropping ids already shown. The feed pages by a score
 * cursor, and a boundary item can come back on the next page; the app keeps
 * the first copy (reels_provider.dart _dedupedById), so does this.
 */
export function mergeReels(prev: Reel[], next: Reel[]): Reel[] {
  const seen: { [id: string]: true } = {};
  const out: Reel[] = [];
  prev.concat(next).forEach((r) => {
    if (seen[r.id]) return;
    seen[r.id] = true;
    out.push(r);
  });
  return out;
}

export function formatReelDuration(sec?: number | null): string | null {
  if (typeof sec !== "number" || !isFinite(sec) || sec <= 0) return null;
  const total = Math.floor(sec);
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${m}:${s < 10 ? "0" : ""}${s}`;
}
