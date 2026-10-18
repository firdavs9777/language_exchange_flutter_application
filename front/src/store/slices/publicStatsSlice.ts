import { apiSlice } from "./apiSlice";
import { PUBLIC_STATS_URL } from "../../constants";

/** GET /api/v1/public/stats -- controllers/public.js. `learners` is null under 1,000. */
export interface PublicStats {
  learners: number | null;
  countries: number;
  languages: number;
  generatedAt: string;
}

export const publicStatsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getPublicStats: builder.query<PublicStats, void>({
      query: () => ({ url: PUBLIC_STATS_URL }),
      transformResponse: (response: any) => (response && response.data ? response.data : response),
      keepUnusedDataFor: 3600,
      // The prerender ships fulfilled entries in the preloaded state: the first
      // render must match that markup, but a mount must still refresh live data.
      // (RTK reads `refetchOnMountOrArgChange` only from the createApi config or
      // a hook option, so `forceRefetch` is the per-endpoint equivalent.)
      forceRefetch: () => true,
    }),
  }),
});

export const { useGetPublicStatsQuery } = publicStatsApiSlice;

/** 12000 -> "12,000". en-US grouping regardless of UI language: the figure sits next to a translated label. */
export function formatCount(n: number): string {
  return n.toLocaleString("en-US");
}
