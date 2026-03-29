import {
  LOGOUT_URL,
  REGISTER_URL,
  LOGIN_URL,
  USER_PROFILE_URL,
  COMMUNITY_URL,
  USER_PROFILE_UPDATE,
  SEND_EMAIL_CODE,
  CONFIRM_EMAIL_CODE,
  RESET_USER_PASSWORD,
  REGISTER_EMAIL_CODE,
  BLOCK_USER_URL,
} from "../../constants";
import { apiSlice } from "./apiSlice";

export interface AuthInfo {
  name?: string;
  email: string;
  password: string;
}

export const usersApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    loginUser: builder.mutation({
      query: (data: AuthInfo) => ({
        url: `${LOGIN_URL}`,
        method: "POST",
        body: data,
      }),
      keepUnusedDataFor: 5,
    }),
    registerUser: builder.mutation({
      query: (data: any) => ({
        url: `${REGISTER_URL}`,
        method: "POST",
        body: data,
      }),
      keepUnusedDataFor: 5,
    }),
    sendCodeEmail: builder.mutation({
      query: (data: any) => ({
        url: `${SEND_EMAIL_CODE}`,
        method: "POST",
        body: data,
      }),
      keepUnusedDataFor: 5,
    }),
    registerCodeEmail: builder.mutation({
      query: (data: any) => ({
        url: `${REGISTER_EMAIL_CODE}`,
        method: "POST",
        body: data,
      }),
      keepUnusedDataFor: 5,
    }),
    verifyCodeEmail: builder.mutation({
      query: (data: any) => ({
        url: `${CONFIRM_EMAIL_CODE}`,
        method: "POST",
        body: data,
      }),
      keepUnusedDataFor: 5,
    }),
    resetPasswordUser: builder.mutation({
      query: (data: any) => ({
        url: `${RESET_USER_PASSWORD}`,
        method: "POST",
        body: data,
      }),
      keepUnusedDataFor: 5,
    }),
    uploadUserPhoto: builder.mutation({
      query: ({
        userId,
        imageFiles,
      }: {
        userId: string;
        imageFiles: FormData;
      }) => ({
        url: `${COMMUNITY_URL}/${userId}/photo`,
        method: "PUT",
        body: imageFiles,
      }),
      invalidatesTags: ["User"],
    }),
    getUserProfile: builder.query({
      query: () => ({
        url: `${USER_PROFILE_URL}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["User"],
    }),
    updateUserInfo: builder.mutation({
      query: (data: any) => ({
        url: `${USER_PROFILE_UPDATE}`,
        method: "PUT",
        body: data,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["User"],
    }),
    deleteUserPhoto: builder.mutation({
      query: ({ userId, index }: { userId: string; index: number }) => ({
        url: `${COMMUNITY_URL}/${userId}/photo/${index}`,
        method: "DELETE",
      }),
      invalidatesTags: ["User"],
    }),

    logoutUser: builder.mutation({
      query: () => ({
        url: `${LOGOUT_URL}`,
        method: "POST",
      }),
      keepUnusedDataFor: 5,
    }),
    followUser: builder.mutation({
      query: ({
        userId,
        targetUserId,
      }: {
        userId: string;
        targetUserId: string;
      }) => ({
        url: `${COMMUNITY_URL}/${userId}/follow/${targetUserId}`,
        method: "PUT",
      }),
      keepUnusedDataFor: 5,
      providesTags: ["User"],
    }),
    unFollowUser: builder.mutation({
      query: ({
        userId,
        targetUserId,
      }: {
        userId: string;
        targetUserId: string;
      }) => ({
        url: `${COMMUNITY_URL}/${userId}/unfollow/${targetUserId}`,
        method: "PUT", // Ensure the correct HTTP method is specified
      }),
      keepUnusedDataFor: 5, // Optionally, how long unused data is kept in the cache
      invalidatesTags: ["User"], // Invalidate cache after this mutation to update user state
    }),
    getFollowers: builder.query({
      query: ({ userId }: { userId: string }) => ({
        url: `${COMMUNITY_URL}/${userId}/followers`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["User"],
    }),
    getFollowings: builder.query({
      query: ({ userId }: { userId: string }) => ({
        url: `${COMMUNITY_URL}/${userId}/following`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["User"],
    }),

    // Profile Visitors
    recordProfileVisit: builder.mutation({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}/profile-visit`,
        method: "POST",
      }),
    }),
    getProfileVisitors: builder.query({
      query: ({ userId, page = 1, limit = 20 }: { userId: string; page?: number; limit?: number }) => ({
        url: `${COMMUNITY_URL}/${userId}/visitors?page=${page}&limit=${limit}`,
      }),
      providesTags: ["User"],
    }),
    getMyVisitorStats: builder.query({
      query: () => ({
        url: `${COMMUNITY_URL}/me/visitor-stats`,
      }),
      providesTags: ["User"],
    }),
    clearVisitors: builder.mutation({
      query: () => ({
        url: `${COMMUNITY_URL}/me/visitors`,
        method: "DELETE",
      }),
      invalidatesTags: ["User"],
    }),
    getVisitedProfiles: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${COMMUNITY_URL}/me/visited-profiles?page=${page}&limit=${limit}`,
      }),
    }),

    // User Limits
    getUserLimits: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}/limits`,
      }),
    }),

    // VIP Status
    getVipStatus: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}/vip/status`,
      }),
      providesTags: ["User"],
    }),

    // Block User
    blockUser: builder.mutation({
      query: (userId: string) => ({
        url: `${BLOCK_USER_URL}/${userId}/block`,
        method: "POST",
      }),
      invalidatesTags: ["User"],
    }),
    unblockUser: builder.mutation({
      query: (userId: string) => ({
        url: `${BLOCK_USER_URL}/${userId}/block`,
        method: "DELETE",
      }),
      invalidatesTags: ["User"],
    }),
    getBlockedUsers: builder.query({
      query: () => ({
        url: `${BLOCK_USER_URL}/blocked`,
      }),
      providesTags: ["User"],
    }),

    // Report User
    reportUser: builder.mutation({
      query: ({ userId, reason, description }: { userId: string; reason: string; description?: string }) => ({
        url: `${BLOCK_USER_URL}/${userId}/report`,
        method: "POST",
        body: { reason, description },
      }),
    }),

    // Get user by ID (for community)
    getUserById: builder.query({
      query: (userId: string) => ({
        url: `${COMMUNITY_URL}/${userId}`,
      }),
      keepUnusedDataFor: 5,
    }),

    // Search users
    searchUsers: builder.query({
      query: ({ query, page = 1, limit = 20 }: { query: string; page?: number; limit?: number }) => ({
        url: `${COMMUNITY_URL}?search=${query}&page=${page}&limit=${limit}`,
      }),
    }),

    // Get user by username (exact match)
    getUserByUsername: builder.query({
      query: (username: string) => ({
        url: `/api/v1/users/username/${username.replace('@', '')}`,
      }),
      keepUnusedDataFor: 5,
    }),

    // Search users by username (partial match)
    searchUsersByUsername: builder.query({
      query: ({ query, limit = 20 }: { query: string; limit?: number }) => ({
        url: `/api/v1/users/search/username?q=${query.replace('@', '')}&limit=${limit}`,
      }),
    }),
  }),
});

export const {
  useLoginUserMutation,
  useSendCodeEmailMutation,
  useRegisterCodeEmailMutation,
  useVerifyCodeEmailMutation,
  useResetPasswordUserMutation,
  useLogoutUserMutation,
  useRegisterUserMutation,
  useGetUserProfileQuery,
  useGetFollowersQuery,
  useGetFollowingsQuery,
  useFollowUserMutation,
  useUnFollowUserMutation,
  useUploadUserPhotoMutation,
  useUpdateUserInfoMutation,
  useDeleteUserPhotoMutation,
  // New hooks
  useRecordProfileVisitMutation,
  useGetProfileVisitorsQuery,
  useGetMyVisitorStatsQuery,
  useClearVisitorsMutation,
  useGetVisitedProfilesQuery,
  useGetUserLimitsQuery,
  useGetVipStatusQuery,
  useBlockUserMutation,
  useUnblockUserMutation,
  useGetBlockedUsersQuery,
  useReportUserMutation,
  useGetUserByIdQuery,
  useSearchUsersQuery,
  // Username endpoints
  useGetUserByUsernameQuery,
  useSearchUsersByUsernameQuery,
} = usersApiSlice;
