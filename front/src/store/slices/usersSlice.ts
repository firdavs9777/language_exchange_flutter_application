import {
  //   USER_PROFILE_URL,
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
        imageFiles: File[];
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
} = usersApiSlice;
