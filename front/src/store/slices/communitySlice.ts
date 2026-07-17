import {
  COMMUNITY_URL,
  COMMUNITY_NEARBY,
  COMMUNITY_WAVES,
  COMMUNITY_WAVES_LIST,
  COMMUNITY_TOPICS,
  LANGUAGES_URL,
  COMMUNITY_COUNT_URL
} from "../../constants";
import { apiSlice } from "./apiSlice";

export const communityApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getCommunityMembers: builder.query({
      query: ({ page = 1, limit = 10, gender, ageMin, ageMax, country, language }: {
        page?: number;
        limit?: number;
        gender?: string;
        ageMin?: number;
        ageMax?: number;
        country?: string;
        language?: string;
      } = {}) => {
        let url = `${COMMUNITY_URL}?page=${page}&limit=${limit}`;
        if (gender) url += `&gender=${gender}`;
        if (ageMin) url += `&ageMin=${ageMin}`;
        if (ageMax) url += `&ageMax=${ageMax}`;
        if (country) url += `&country=${country}`;
        if (language) url += `&language=${language}`;
        return { url };
      },
      // Normalize each user in data[] so the UI never has to reach into
      // nested/inconsistent backend fields directly:
      //  - isVIP <- vipSubscription.isActive (backend never returns a flat
      //    isVIP; the card previously read a field that never existed).
      //  - languageLevel/location/lastActive/hasActiveStory/isOnline/
      //    imageUrls/followersCount are passed through as-is (already present
      //    on USER_LIST_FIELDS / computed fields) — listed explicitly so a
      //    future backend field rename is easy to spot here.
      transformResponse: (response: any) => {
        if (!response || !Array.isArray(response.data)) return response;
        return {
          ...response,
          data: response.data.map((user: any) => ({
            ...user,
            isVIP: !!user?.vipSubscription?.isActive,
            languageLevel: user?.languageLevel,
            location: user?.location,
            lastActive: user?.lastActive,
            hasActiveStory: user?.hasActiveStory,
            isOnline: user?.isOnline,
            imageUrls: user?.imageUrls,
            followersCount: user?.followersCount,
          })),
        };
      },
      keepUnusedDataFor: 5,
      providesTags: ["Community"],
    }),
    // Live match count for the filter sheet — same filter params as
    // getCommunityMembers, hits the dedicated count endpoint instead of
    // paginated data. `params` is the Record<string,string> produced by
    // buildCommunityQuery (or any subset of it).
    getCommunityCount: builder.query({
      query: (params: Record<string, string> = {}) => ({
        url: COMMUNITY_COUNT_URL,
        params,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["Community"],
    }),
    getCommunityDetails: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}`,
      }),
      keepUnusedDataFor: 5,
    }),
    // Public counterpart of getCommunityDetails — hits the PUBLIC
    // GET /auth/users/:id/public endpoint so logged-out visitors can view a
    // shared profile (the plain /auth/users/:id endpoint above is protected
    // and 401s for anonymous requests). Same response shape.
    getPublicUserProfile: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}/public`,
      }),
      keepUnusedDataFor: 5,
    }),

    // Nearby Users (Discovery)
    getNearbyUsers: builder.query({
      query: ({ latitude, longitude, radius = 50, page = 1, limit = 20 }: {
        latitude: number;
        longitude: number;
        radius?: number;
        page?: number;
        limit?: number;
      }) => ({
        url: `${COMMUNITY_NEARBY}?lat=${latitude}&lng=${longitude}&radius=${radius}&page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["Community"],
    }),

    // Wave System — reconciled to the REAL backend routes (the previous
    // getReceivedWaves/getSentWaves/respondToWave/markWaveRead pointed at
    // /wave/received, /wave/sent, /wave/:id/respond, /wave/:id/read, none of
    // which exist server-side). Real routes:
    //   POST /api/v1/community/wave        {targetUserId, message?} -> {waveId, isMutual, message}
    //   GET  /api/v1/community/waves        {page, limit, unreadOnly, archive} -> {data:{waves, unreadCount}}
    //   PUT  /api/v1/community/waves/read   {waveIds?}
    sendWave: builder.mutation({
      query: ({ targetUserId, message }: { targetUserId: string; message?: string }) => ({
        url: COMMUNITY_WAVES,
        method: "POST",
        body: { targetUserId, message },
      }),
      invalidatesTags: ["Community"],
    }),
    getWaves: builder.query({
      query: ({ page = 1, limit = 20, unreadOnly, archive }: {
        page?: number;
        limit?: number;
        unreadOnly?: boolean;
        archive?: boolean;
      } = {}) => {
        let url = `${COMMUNITY_WAVES_LIST}?page=${page}&limit=${limit}`;
        if (unreadOnly) url += `&unreadOnly=${unreadOnly}`;
        if (archive) url += `&archive=${archive}`;
        return { url };
      },
      providesTags: ["Community"],
    }),
    markWavesRead: builder.mutation({
      query: (waveIds?: string[]) => ({
        url: `${COMMUNITY_WAVES_LIST}/read`,
        method: "PUT",
        body: waveIds ? { waveIds } : {},
      }),
      invalidatesTags: ["Community"],
    }),

    // Topics System
    getTopics: builder.query({
      query: () => ({
        url: COMMUNITY_TOPICS,
      }),
      keepUnusedDataFor: 60,
    }),
    getUserTopics: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_TOPICS}/user/${userId}`,
      }),
      providesTags: ["Community"],
    }),
    updateMyTopics: builder.mutation({
      query: (topicIds: string[]) => ({
        url: `${COMMUNITY_TOPICS}/my-topics`,
        method: "PUT",
        body: { topicIds },
      }),
      invalidatesTags: ["Community"],
    }),
    getUsersByTopic: builder.query({
      query: ({ topicId, page = 1, limit = 20 }: { topicId: string; page?: number; limit?: number }) => ({
        url: `${COMMUNITY_TOPICS}/${topicId}/users?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Community"],
    }),

    // Languages
    getLanguages: builder.query({
      query: () => ({
        url: LANGUAGES_URL,
      }),
      keepUnusedDataFor: 300, // Cache for 5 minutes
    }),
    updateMyLanguages: builder.mutation({
      query: ({ native, learning }: { native: string[]; learning: string[] }) => ({
        url: `${LANGUAGES_URL}/my-languages`,
        method: "PUT",
        body: { native, learning },
      }),
      invalidatesTags: ["User"],
    }),
    getUsersByLanguage: builder.query({
      query: ({ languageCode, type = 'all', page = 1, limit = 20 }: {
        languageCode: string;
        type?: 'native' | 'learning' | 'all';
        page?: number;
        limit?: number;
      }) => ({
        url: `${LANGUAGES_URL}/users?language=${languageCode}&type=${type}&page=${page}&limit=${limit}`,
      }),
      providesTags: ["Community"],
    }),

    // Online Status
    getOnlineUsers: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${COMMUNITY_URL}/online?page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 30,
      providesTags: ["Community"],
    }),

    // Recently Active
    getRecentlyActive: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${COMMUNITY_URL}/recently-active?page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 60,
      providesTags: ["Community"],
    }),

    // New Users
    getNewUsers: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${COMMUNITY_URL}/new?page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 60,
      providesTags: ["Community"],
    }),
  }),
});

export const {
  useGetCommunityMembersQuery,
  useGetCommunityCountQuery,
  useGetCommunityDetailsQuery,
  useGetPublicUserProfileQuery,
  // Nearby
  useGetNearbyUsersQuery,
  // Waves (real backend routes)
  useSendWaveMutation,
  useGetWavesQuery,
  useMarkWavesReadMutation,
  // Topics
  useGetTopicsQuery,
  useGetUserTopicsQuery,
  useUpdateMyTopicsMutation,
  useGetUsersByTopicQuery,
  // Languages
  useGetLanguagesQuery,
  useUpdateMyLanguagesMutation,
  useGetUsersByLanguageQuery,
  // Discovery
  useGetOnlineUsersQuery,
  useGetRecentlyActiveQuery,
  useGetNewUsersQuery,
} = communityApiSlice;
export default communityApiSlice.reducer;

// ---------------------------------------------------------------------------
// Deprecated wave-hook compatibility shims
// ---------------------------------------------------------------------------
// `src/components/community/Waves.tsx` (pre-existing, NOT part of this task)
// still imports `useGetReceivedWavesQuery`, `useGetSentWavesQuery`, and
// `useRespondToWaveMutation`. Those backed `/wave/received`, `/wave/sent`,
// `/wave/:id/respond` — routes that never existed on the backend and have
// now been removed from this slice in favor of the real routes above
// (`getWaves` / `markWavesRead`). The real API has no "received vs sent
// inbox" split and no accept/decline step (a wave is auto-mutual — see
// `isMutual` in `sendWave`'s response) — the whole Waves.tsx inbox needs a
// redesign against the real `{data:{waves, unreadCount}}` contract, tracked
// as a follow-up "waves-UI" task.
//
// These shims exist ONLY so `react-scripts build` stays green until that
// task lands. `useGetReceivedWavesQuery`/`useGetSentWavesQuery` adapt the new
// `{data:{waves,unreadCount}}` payload back into the old flat-array `data`
// shape Waves.tsx expects (so `.filter`/`.map` don't runtime-crash); they do
// NOT distinguish received vs. sent (the real endpoint returns one combined
// list). `useRespondToWaveMutation` is aliased to `useMarkWavesReadMutation`
// and becomes a harmless no-op when called with `{waveId, accept}` (not a
// `string[]`, so no `waveIds` are sent) — it no longer accepts/declines
// anything. Do NOT build new features on these; use `useGetWavesQuery` /
// `useMarkWavesReadMutation` directly instead.
export function useGetReceivedWavesQuery(arg?: any, options?: any) {
  const result = useGetWavesQuery(arg, options);
  return {
    ...result,
    data: result?.data
      ? { ...result.data, data: result.data.data?.waves || [] }
      : result?.data,
  };
}
export const useGetSentWavesQuery = useGetReceivedWavesQuery;
export const useMarkWaveReadMutation = useMarkWavesReadMutation;
export const useRespondToWaveMutation = useMarkWavesReadMutation;
