import {
  COMMUNITY_URL,
  COMMUNITY_NEARBY,
  COMMUNITY_WAVES,
  COMMUNITY_TOPICS,
  LANGUAGES_URL
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
      keepUnusedDataFor: 5,
      providesTags: ["Community"],
    }),
    getCommunityDetails: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}`,
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

    // Wave System
    sendWave: builder.mutation({
      query: ({ targetUserId, message }: { targetUserId: string; message?: string }) => ({
        url: COMMUNITY_WAVES,
        method: "POST",
        body: { targetUserId, message },
      }),
      invalidatesTags: ["Community"],
    }),
    getReceivedWaves: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${COMMUNITY_WAVES}/received?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Community"],
    }),
    getSentWaves: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${COMMUNITY_WAVES}/sent?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Community"],
    }),
    markWaveRead: builder.mutation({
      query: (waveId: string) => ({
        url: `${COMMUNITY_WAVES}/${waveId}/read`,
        method: "PUT",
      }),
      invalidatesTags: ["Community"],
    }),
    respondToWave: builder.mutation({
      query: ({ waveId, response }: { waveId: string; response: 'accept' | 'decline' }) => ({
        url: `${COMMUNITY_WAVES}/${waveId}/respond`,
        method: "POST",
        body: { response },
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
  useGetCommunityDetailsQuery,
  // Nearby
  useGetNearbyUsersQuery,
  // Waves
  useSendWaveMutation,
  useGetReceivedWavesQuery,
  useGetSentWavesQuery,
  useMarkWaveReadMutation,
  useRespondToWaveMutation,
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
