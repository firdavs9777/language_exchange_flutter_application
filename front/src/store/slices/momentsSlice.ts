import { MOMENTS_URL } from "../../constants";
import { apiSlice } from "./apiSlice";

export const momentsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getMoments: builder.query({
      query: ({ page = 1, limit = 10 } = {}) => ({
        url: `${MOMENTS_URL}?page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
    }),
    // Trending moments
    getTrendingMoments: builder.query({
      query: ({ page = 1, limit = 10 } = {}) => ({
        url: `${MOMENTS_URL}/trending?page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
    }),
    // Explore moments
    getExploreMoments: builder.query({
      query: ({ page = 1, limit = 10, category }: { page?: number; limit?: number; category?: string } = {}) => ({
        url: `${MOMENTS_URL}/explore?page=${page}&limit=${limit}${category ? `&category=${category}` : ''}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
    }),
    getMomentDetails: builder.query({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}`,
      }),
      keepUnusedDataFor: 5,
    }),
    createMoment: builder.mutation({
      query: (data: any) => ({
        url: `${MOMENTS_URL}`,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Moments"],
    }),
    updateMoment: builder.mutation({
      query: ({ id, momentData }: { id: string; momentData: any }) => ({
        url: `${MOMENTS_URL}/${id}`,
        method: "PUT",
        body: momentData,
      }),
      invalidatesTags: ["Moments"],
    }),
    deleteMoment: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments"],
    }),
    uploadMomentPhotos: builder.mutation({
      query: ({
        momentId,
        imageFiles,
      }: {
        momentId: string;
        imageFiles: File[];
      }) => ({
        url: `${MOMENTS_URL}/${momentId}/photo`,
        method: "PUT",
        body: imageFiles,
      }),
      invalidatesTags: ["Moments"],
    }),
    likeMoment: builder.mutation({
      query: ({ momentId, userId }: { momentId: string; userId: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/like`,
        method: "POST",
        body: { userId },
      }),
      invalidatesTags: ["Moments"],
    }),
    dislikeMoment: builder.mutation({
      query: ({ momentId, userId }: { momentId: string; userId: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/dislike`,
        method: "POST",
        body: { userId },
      }),
      invalidatesTags: ["Moments"],
    }),
    getMyMoments: builder.query({
      query: ({ userId }: { userId: string }) => ({
        url: `${MOMENTS_URL}/user/${userId}`,
      }),
      keepUnusedDataFor: 5,
    }),
    // Save/Bookmark moment
    saveMoment: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/save`,
        method: "POST",
      }),
      invalidatesTags: ["Moments"],
    }),
    unsaveMoment: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/save`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments"],
    }),
    getSavedMoments: builder.query({
      query: ({ page = 1, limit = 10 } = {}) => ({
        url: `${MOMENTS_URL}/saved?page=${page}&limit=${limit}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
    }),
    // Translate moment
    translateMoment: builder.mutation({
      query: ({ momentId, targetLanguage }: { momentId: string; targetLanguage: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/translate`,
        method: "POST",
        body: { targetLanguage },
      }),
    }),
    getMomentTranslations: builder.query({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/translations`,
      }),
    }),
    // Report moment
    reportMoment: builder.mutation({
      query: ({ momentId, reason, description }: { momentId: string; reason: string; description?: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/report`,
        method: "POST",
        body: { reason, description },
      }),
    }),
    // Comments
    getMomentComments: builder.query({
      query: ({ momentId, page = 1, limit = 20 }: { momentId: string; page?: number; limit?: number }) => ({
        url: `${MOMENTS_URL}/${momentId}/comments?page=${page}&limit=${limit}`,
      }),
      providesTags: ['Moments'],
    }),
    addMomentComment: builder.mutation({
      query: ({ momentId, content, parentId }: { momentId: string; content: string; parentId?: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/comments`,
        method: "POST",
        body: { content, parentId },
      }),
      invalidatesTags: ["Moments"],
    }),
    deleteMomentComment: builder.mutation({
      query: ({ momentId, commentId }: { momentId: string; commentId: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/comments/${commentId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments"],
    }),
  }),
});

export const {
  useGetMomentsQuery,
  useGetTrendingMomentsQuery,
  useGetExploreMomentsQuery,
  useGetMomentDetailsQuery,
  useCreateMomentMutation,
  useUploadMomentPhotosMutation,
  useLikeMomentMutation,
  useDislikeMomentMutation,
  useGetMyMomentsQuery,
  useUpdateMomentMutation,
  useDeleteMomentMutation,
  // New hooks
  useSaveMomentMutation,
  useUnsaveMomentMutation,
  useGetSavedMomentsQuery,
  useTranslateMomentMutation,
  useGetMomentTranslationsQuery,
  useReportMomentMutation,
  useGetMomentCommentsQuery,
  useAddMomentCommentMutation,
  useDeleteMomentCommentMutation,
} = momentsApiSlice;

export default momentsApiSlice.reducer;
