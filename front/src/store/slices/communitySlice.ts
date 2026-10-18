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

/**
 * The matching engine's recommendation feed, behind `protect`.
 * Kept local rather than in `constants.ts` because this is the only caller:
 * `/api/v1/matching/*` is a namespace of its own, not part of the community
 * CRUD surface the shared constants describe.
 */
const MATCHING_RECOMMENDATIONS_URL = "/api/v1/matching/recommendations";

export const communityApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // Accepts the flat `Record<string,string>` produced by
    // `buildCommunityQuery` (community/lib) so EVERY discovery filter
    // (age/gender/language/level/country/topics/online/search/sort/…) reaches
    // the DB, plus the legacy `{ page, limit, language }` shape still passed by
    // CommunityDetail's "Suggested for you" strip. Any defined key is spread
    // straight onto `params`; `page`/`limit` default when absent. Empty /
    // undefined / null values are dropped so we never send `?gender=`.
    getCommunityMembers: builder.query({
      query: (arg: Record<string, any> = {}) => {
        const { page = 1, limit = 20, ...rest } = arg;
        const params: Record<string, string> = {
          page: String(page),
          limit: String(limit),
        };
        for (const [key, val] of Object.entries(rest)) {
          if (val !== undefined && val !== null && val !== "") {
            params[key] = String(val);
          }
        }
        return { url: COMMUNITY_URL, params };
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
      // Tagged so followUser/unFollowUser (invalidatesTags: ["User"]) actually
      // refetch this profile. Without it the profile page's follower count and
      // its derived isFollowing never reconciled after a follow -- the
      // optimistic state in ProfileActions was hiding a stale cache.
      providesTags: (_result: any, _error: any, id: string) => [
        { type: "User", id },
        "User",
      ],
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
      // The profile page reads this one (useProfileData), so it carries the
      // same "User" tags as getCommunityDetails above -- followUser /
      // unFollowUser invalidate "User", and without the tag the follower count
      // and the derived isFollowing keep showing the state from before the tap.
      providesTags: (_result: any, _error: any, id: string) => [
        { type: "User", id },
        "User",
      ],
    }),

    // "For you": the backend's scored recommendation feed
    // (GET /api/v1/matching/recommendations, protected, cached 30 min
    // server-side). Response is `{ success, count, data, cached }` and each
    // item carries the same fields the member cards read plus `matchScore`
    // and `matchReasons` (an array of short English reason strings).
    //
    // It takes no filters by design — the whole point of the tab is that the
    // server decides — so the only argument is `limit` (default 20, capped at
    // 50 server-side). Its own tag, not "Community": a follow or a wave
    // invalidating the list must not throw away a 30-minute recommendation
    // computation.
    getRecommendations: builder.query({
      query: ({ limit = 20 }: { limit?: number } = {}) => ({
        url: MATCHING_RECOMMENDATIONS_URL,
        params: { limit: String(limit) },
      }),
      keepUnusedDataFor: 60,
      providesTags: ["Recommendations"],
    }),

    // "Today": the day's batch of partners (GET /api/v1/matching/daily,
    // protected). The server picks and caches it until `nextRefreshAt`
    // (midnight UTC) and answers 404 when DAILY_MATCHES_ENABLED is off --
    // which the page reads as "this feature is not here", not as an error.
    getDailyMatches: builder.query({
      query: () => ({ url: "/api/v1/matching/daily" }),
      keepUnusedDataFor: 60,
    }),
    // POST /api/v1/interactions/skip { targetUserId }. Fire-and-forget from
    // the Today card: the card leaves at once whatever this answers.
    skipUser: builder.mutation({
      query: (targetUserId: string) => ({
        url: "/api/v1/interactions/skip",
        method: "POST",
        body: { targetUserId },
      }),
    }),

    // Nearby Users (Discovery). controllers/community.js getNearbyUsers reads
    // `latitude`, `longitude`, `radius` (km), `limit` and `offset`. It never
    // read `lat`/`lng`/`page`, so every request used to 400 and the page
    // always said nobody was nearby. `page` stays the caller's unit and is
    // turned into the offset here.
    getNearbyUsers: builder.query({
      query: ({ latitude, longitude, radius = 50, page = 1, limit = 50 }: {
        latitude: number;
        longitude: number;
        radius?: number;
        page?: number;
        limit?: number;
      }) => ({
        url: COMMUNITY_NEARBY,
        params: {
          latitude: String(latitude),
          longitude: String(longitude),
          radius: String(radius),
          limit: String(limit),
          offset: String((Math.max(1, page) - 1) * limit),
        },
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
      query: ({ page = 1, limit = 20, unreadOnly, archive, reveal }: {
        page?: number;
        limit?: number;
        unreadOnly?: boolean;
        /** 7-30 days old (the main list is the last 7 days). */
        archive?: boolean;
        /** ?reveal=1 — the app sends it while appConfig.boostsEnabled is on. */
        reveal?: boolean;
      } = {}) => {
        let url = `${COMMUNITY_WAVES_LIST}?page=${page}&limit=${limit}`;
        if (unreadOnly) url += `&unreadOnly=${unreadOnly}`;
        if (archive) url += `&archive=true`;
        if (reveal) url += `&reveal=1`;
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
    // `PUT /api/v1/community/topics/my` with `{ topics }` -- routes/community.js
    // and controllers/community.js `updateMyTopics`. This used to post
    // `{ topicIds }` to `/topics/my-topics`, an endpoint the API has never
    // had, so saving a member's topics was a 404 every time.
    updateMyTopics: builder.mutation({
      query: (topicIds: string[]) => ({
        url: `${COMMUNITY_TOPICS}/my`,
        method: "PUT",
        body: { topics: topicIds },
      }),
      invalidatesTags: ["Community", "User"],
    }),
    // `onlineOnly` is a real query param on `getTopicUsers` (it filters on the
    // persisted isOnline flag, the same one behind the green presence dots);
    // it is only ever sent when true so the cache key of the default list
    // stays `?page&limit`.
    getUsersByTopic: builder.query({
      query: ({
        topicId,
        page = 1,
        limit = 20,
        onlineOnly = false,
      }: {
        topicId: string;
        page?: number;
        limit?: number;
        onlineOnly?: boolean;
      }) => ({
        url: `${COMMUNITY_TOPICS}/${topicId}/users?page=${page}&limit=${limit}${
          onlineOnly ? "&onlineOnly=true" : ""
        }`,
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
  }),
});

export const {
  useGetCommunityMembersQuery,
  useGetCommunityCountQuery,
  useGetCommunityDetailsQuery,
  useGetPublicUserProfileQuery,
  // "For you"
  useGetRecommendationsQuery,
  useGetDailyMatchesQuery,
  useSkipUserMutation,
  // Nearby
  useGetNearbyUsersQuery,
  // Waves (real backend routes)
  useSendWaveMutation,
  useGetWavesQuery,
  useMarkWavesReadMutation,
  // Topics
  useGetTopicsQuery,
  useUpdateMyTopicsMutation,
  useGetUsersByTopicQuery,
  // Languages
  useGetLanguagesQuery,
} = communityApiSlice;
export default communityApiSlice.reducer;
