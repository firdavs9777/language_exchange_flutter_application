import { MOMENTS_URL } from "../../constants";
import { apiSlice } from "./apiSlice";
import { normalizeReel, Reel, REELS_PAGE_SIZE } from "../../components/reels/lib/reelModel";

export interface ReelsPage {
  reels: Reel[];
  nextCursor: string | null;
}

export interface VideoConfig {
  allowedTypes: string[];
  maxSize: number;
}

/** Mirrors be/utils/videoUtils.js; used when video-config is odd or down. */
export const DEFAULT_VIDEO_CONFIG: VideoConfig = {
  allowedTypes: ["video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/3gpp", "video/x-m4v"],
  maxSize: 1024 * 1024 * 1024,
};

export const reelsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // GET /api/v1/moments/reels?limit=&before=. `before` is the server's
    // opaque score cursor ("<score>:<anchorMs>") -- passed back verbatim,
    // never derived from createdAt (be/controllers/moments.js getReelsFeed).
    getReelsPage: builder.query({
      query: ({ before, limit }: { before?: string | null; limit?: number }) => {
        const params = new URLSearchParams();
        params.set("limit", String(limit || REELS_PAGE_SIZE));
        if (before) params.set("before", before);
        return { url: `${MOMENTS_URL}/reels?${params.toString()}` };
      },
      transformResponse: (response: any): ReelsPage => {
        const rows = response && Array.isArray(response.data) ? response.data : [];
        const reels: Reel[] = [];
        rows.forEach((row: any) => {
          const r = normalizeReel(row);
          if (r) reels.push(r);
        });
        const cursor = response && response.nextCursor;
        return { reels, nextCursor: typeof cursor === "string" && cursor ? cursor : null };
      },
      providesTags: ["Moments"],
    }),
    // GET /api/v1/moments/video-config (public). Named getReelVideoConfig:
    // storiesSlice already injects a `getVideoConfig` (stories/video-config)
    // and RTK keeps the first endpoint injected under a name.
    getReelVideoConfig: builder.query({
      query: () => ({ url: `${MOMENTS_URL}/video-config` }),
      transformResponse: (response: any): VideoConfig => {
        const v = response && response.data && response.data.video;
        const types = v && Array.isArray(v.allowedTypes) && v.allowedTypes.length ? v.allowedTypes : null;
        const size = v && typeof v.maxSize === "number" && v.maxSize > 0 ? v.maxSize : null;
        return {
          allowedTypes: types || DEFAULT_VIDEO_CONFIG.allowedTypes,
          maxSize: size || DEFAULT_VIDEO_CONFIG.maxSize,
        };
      },
      keepUnusedDataFor: 3600,
    }),
  }),
});

export const {
  useGetReelsPageQuery,
  useLazyGetReelsPageQuery,
  useGetReelVideoConfigQuery,
} = reelsApiSlice as any;
