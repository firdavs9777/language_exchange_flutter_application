import { MOMENTS_URL, COMMENTS_URL } from "../../constants";
import { apiSlice } from "./apiSlice";
import { MomentFilters, momentFilterQuery } from "../../components/moments/lib/momentFilterState";

export const momentsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getMoments: builder.query({
      // `feed` is only appended when given, so `getMoments({ page: 1, limit: 10 })`
      // serializes to the exact same cache key/URL as before it existed -- the
      // prerender prefetch (src/seo/prerender/prefetch.ts) and its snapshot in
      // the preloaded state depend on that match.
      // `filters` likewise only adds params when one is set.
      query: ({ page = 1, limit = 10, feed, filters }: { page?: number; limit?: number; feed?: "forYou" | "following"; filters?: MomentFilters } = {}) => ({
        url: `${MOMENTS_URL}?page=${page}&limit=${limit}${feed ? `&feed=${feed}` : ""}${momentFilterQuery(filters)}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
      // The prerender ships fulfilled entries in the preloaded state: the first
      // render must match that markup, but a mount must still refresh live data.
      // (RTK reads `refetchOnMountOrArgChange` only from the createApi config or
      // a hook option, so `forceRefetch` is the per-endpoint equivalent.)
      forceRefetch: () => true,
    }),
    // Trending moments
    getTrendingMoments: builder.query({
      query: ({ page = 1, limit = 10, filters }: { page?: number; limit?: number; filters?: MomentFilters } = {}) => ({
        url: `${MOMENTS_URL}/trending?page=${page}&limit=${limit}${momentFilterQuery(filters)}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
    }),
    // Explore moments
    getExploreMoments: builder.query({
      // A `filters.category` wins over the legacy `category` argument.
      query: ({ page = 1, limit = 10, category, filters }: { page?: number; limit?: number; category?: string; filters?: MomentFilters } = {}) => ({
        url: `${MOMENTS_URL}/explore?page=${page}&limit=${limit}${momentFilterQuery(filters && filters.category ? filters : { ...filters, category })}`,
      }),
      keepUnusedDataFor: 5,
      providesTags: ['Moments'],
    }),
    getMomentDetails: builder.query({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}`,
      }),
      keepUnusedDataFor: 5,
      // Without this the detail page kept a stale `commentCount` (and like /
      // share / save counters) after any mutation: they all invalidate
      // "Moments", but an endpoint that provides no tag is never invalidated.
      providesTags: ["Moments"],
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
        /** multipart body with one `file` entry per photo (field name the
         *  route's uploadMultiple expects). */
        imageFiles: FormData;
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
    // Tagged so `deleteMoment`/`updateMoment` actually refetch this list.
    // Without it a deleted moment came back on the next visit inside
    // `keepUnusedDataFor`, because nothing invalidated the cached page.
    // GET /api/v1/moments/user/:userId?page=&limit= → {data, pagination}.
    // Without page/limit the server serves its first page of 10.
    getMyMoments: builder.query({
      query: ({ userId, page, limit }: { userId: string; page?: number; limit?: number }) => {
        const params = new URLSearchParams();
        if (page !== undefined) params.append('page', String(page));
        if (limit !== undefined) params.append('limit', String(limit));
        const qs = params.toString();
        return {
          url: `${MOMENTS_URL}/user/${userId}${qs ? `?${qs}` : ''}`,
        };
      },
      keepUnusedDataFor: 5,
      providesTags: ["Moments"],
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
    // Comments
    getMomentComments: builder.query({
      query: ({ momentId, page = 1, limit = 20 }: { momentId: string; page?: number; limit?: number }) => ({
        url: `${MOMENTS_URL}/${momentId}/comments?page=${page}&limit=${limit}`,
      }),
      providesTags: ['Moments', 'Comments'],
    }),
    // Create a comment, a reply or a correction -- POST
    // /api/v1/moments/:momentId/comments (routes/moments.js mounts
    // routes/comment.js at `/:momentId/comments`, so `createComment` reads the
    // moment from the URL and everything else from the body).
    //
    // The field names are the model's (models/Comment.js): `text`,
    // `parentComment`, `correction`. This used to send `{ content, parentId }`,
    // which Mongoose silently dropped -- every comment was stored with the
    // schema default of an empty string. Optional fields are omitted rather
    // than sent as undefined: `createComment` branches on `req.body.correction`
    // being present at all.
    addMomentComment: builder.mutation({
      query: ({
        momentId,
        text,
        parentComment,
        correction,
        image,
        imageUrl,
      }: {
        momentId: string;
        text?: string;
        parentComment?: string;
        correction?: { originalText?: string; correctedText: string; explanation?: string };
        /** A photo: sent in the SAME request as multipart (createComment's
         *  uploadSingleCompressed('image')), so a photo-only comment works. */
        image?: File;
        /** A Giphy GIF URL; the server keeps only giphy.com hosts. */
        imageUrl?: string;
      }) => {
        if (image) {
          // multipart can't carry the nested `correction`; callers keep the
          // two-step upload for corrections (CommentComposer).
          const form = new FormData();
          form.append("text", text || "");
          if (parentComment) form.append("parentComment", parentComment);
          form.append("image", image);
          return { url: `${MOMENTS_URL}/${momentId}/comments`, method: "POST", body: form };
        }
        const body: any = { text: text || "" };
        if (parentComment) body.parentComment = parentComment;
        if (correction) body.correction = correction;
        if (imageUrl) body.imageUrl = imageUrl;
        return {
          url: `${MOMENTS_URL}/${momentId}/comments`,
          method: "POST",
          body,
        };
      },
      invalidatesTags: ["Moments", "Comments"],
    }),
    deleteMomentComment: builder.mutation({
      query: ({ momentId, commentId }: { momentId: string; commentId: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/comments/${commentId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments", "Comments"],
    }),
    // Translate a comment -- POST /api/v1/comments/:id/translate, body
    // { targetLanguage }. Response data: { language, translatedText,
    // translatedAt }. Uses the standalone /api/v1/comments mount (comment.js
    // is registered there too) since translation only needs the comment id.
    translateComment: builder.mutation({
      query: ({ commentId, targetLanguage }: { commentId: string; targetLanguage: string }) => ({
        url: `${COMMENTS_URL}/${commentId}/translate`,
        method: "POST",
        body: { targetLanguage },
      }),
    }),
    // Like/unlike a comment -- POST /api/v1/comments/:id/like, no body.
    // Response data: { isLiked, likeCount }.
    likeComment: builder.mutation({
      query: (commentId: string) => ({
        url: `${COMMENTS_URL}/${commentId}/like`,
        method: "POST",
      }),
      invalidatesTags: ["Comments"],
    }),
    // Emoji react to a comment -- POST /api/v1/comments/:id/react, body
    // { emoji }. Response data: { reactions, reactionCount }.
    reactToComment: builder.mutation({
      query: ({ commentId, emoji }: { commentId: string; emoji: string }) => ({
        url: `${COMMENTS_URL}/${commentId}/react`,
        method: "POST",
        body: { emoji },
      }),
      invalidatesTags: ["Comments"],
    }),
    // Remove a comment's emoji reaction -- DELETE /api/v1/comments/:id/react,
    // no body (the server removes whichever reaction the caller left).
    // Response data: { reactions, reactionCount }.
    unreactToComment: builder.mutation({
      query: ({ commentId }: { commentId: string; emoji?: string }) => ({
        url: `${COMMENTS_URL}/${commentId}/react`,
        method: "DELETE",
      }),
      invalidatesTags: ["Comments"],
    }),
    // Paginated replies to a comment -- GET /api/v1/comments/:id/replies?page=&limit=.
    // Response envelope: { success, count, total, page, pages, data }.
    getCommentReplies: builder.query({
      query: ({ commentId, page = 1, limit = 20 }: { commentId: string; page?: number; limit?: number }) => ({
        url: `${COMMENTS_URL}/${commentId}/replies?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Comments"],
    }),
    // Attach an image to an existing comment -- PUT /api/v1/comments/:id/image,
    // multipart with field name "image" (uploadSingleCompressed('image', ...)
    // server-side). Response data: { imageUrl }. FormData body -- no
    // Content-Type header here, fetchBaseQuery/the browser set the multipart
    // boundary for us.
    uploadCommentImage: builder.mutation({
      query: ({ commentId, file }: { commentId: string; file: File }) => {
        const formData = new FormData();
        formData.append("image", file);
        return {
          url: `${COMMENTS_URL}/${commentId}/image`,
          method: "PUT",
          body: formData,
        };
      },
      invalidatesTags: ["Comments"],
    }),
    // Record a batch of moment views -- POST /api/v1/moments/views, body
    // { views: [{ momentId, watchedMs, completed }] }. The backend only
    // counts a view once watchedMs >= 1000ms (controllers/momentViews.js
    // MIN_VIEW_MS); the caller (useMomentViews, Task 4) tracks each moment's
    // real dwell time via an IntersectionObserver and only enqueues a view
    // once watchedMs has already cleared that bar, so the real watchedMs (and
    // whether the viewer watched >=5s, i.e. completed) is passed straight
    // through here rather than synthesized. Response: { success, recorded }.
    recordMomentViews: builder.mutation({
      query: ({
        views,
      }: {
        views: { momentId: string; watchedMs: number; completed: boolean }[];
      }) => ({
        url: `${MOMENTS_URL}/views`,
        method: "POST",
        body: { views },
        // Flushed from pagehide/visibilitychange:hidden -- keepalive lets the
        // browser finish this request past unload instead of cancelling it
        // (sendBeacon can't be used here since the request needs the
        // Authorization header fetchBaseQuery attaches).
        keepalive: true,
      }),
    }),
    // Emoji reactions (distinct from like/dislike)
    reactToMoment: builder.mutation({
      query: ({ momentId, emoji }: { momentId: string; emoji: string }) => ({
        url: `${MOMENTS_URL}/${momentId}/react`,
        method: "POST",
        body: { emoji },
      }),
      invalidatesTags: ["Moments"],
    }),
    unreactToMoment: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/react`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments"],
    }),
    // Share — POST /api/v1/moments/:momentId/share, no body. Returns {shareCount}.
    shareMoment: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/share`,
        method: "POST",
      }),
      invalidatesTags: ["Moments"],
    }),
    // Video attachment — PUT /api/v1/moments/:momentId/video with FormData (field: video)
    uploadMomentVideo: builder.mutation({
      query: ({ momentId, formData }: { momentId: string; formData: FormData }) => ({
        url: `${MOMENTS_URL}/${momentId}/video`,
        method: "PUT",
        body: formData,
      }),
      invalidatesTags: ["Moments"],
    }),
    deleteMomentVideo: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/video`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments"],
    }),
    deleteMomentAudio: builder.mutation({
      query: (momentId: string) => ({
        url: `${MOMENTS_URL}/${momentId}/audio`,
        method: "DELETE",
      }),
      invalidatesTags: ["Moments"],
    }),
    // Audio attachment — PUT /api/v1/moments/:momentId/audio with FormData
    // (fields: audio (blob), duration, waveform (JSON.stringify of number[]))
    uploadMomentAudio: builder.mutation({
      query: ({ momentId, formData }: { momentId: string; formData: FormData }) => ({
        url: `${MOMENTS_URL}/${momentId}/audio`,
        method: "PUT",
        body: formData,
      }),
      invalidatesTags: ["Moments"],
    }),
    // Prompt of the day — GET /api/v1/moments/prompt-of-day?language=
    // Returns {text, emoji, promptId, language}
    getPromptOfDay: builder.query({
      query: ({ language }: { language?: string } = {}) => ({
        url: `${MOMENTS_URL}/prompt-of-day${language ? `?language=${encodeURIComponent(language)}` : ''}`,
      }),
      // The prerender ships fulfilled entries in the preloaded state: the first
      // render must match that markup, but a mount must still refresh live data.
      // (RTK reads `refetchOnMountOrArgChange` only from the createApi config or
      // a hook option, so `forceRefetch` is the per-endpoint equivalent.)
      forceRefetch: () => true,
    }),
    // Reels feed — GET /api/v1/moments/reels?before=&limit=
    // Returns {success, data, nextCursor}. NOTE: 404s when backend
    // REELS_ENABLED is off — callers feature-detect this.
    getReelsFeed: builder.query({
      query: ({ before, limit }: { before?: string; limit?: number } = {}) => {
        const params = new URLSearchParams();
        if (before) params.append('before', before);
        if (limit !== undefined) params.append('limit', String(limit));
        const qs = params.toString();
        return {
          url: `${MOMENTS_URL}/reels${qs ? `?${qs}` : ''}`,
        };
      },
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
  useGetMomentCommentsQuery,
  useAddMomentCommentMutation,
  useDeleteMomentCommentMutation,
  // Reactions / share / video / audio / prompt / reels
  useReactToMomentMutation,
  useUnreactToMomentMutation,
  useShareMomentMutation,
  useUploadMomentVideoMutation,
  useDeleteMomentVideoMutation,
  useDeleteMomentAudioMutation,
  useUploadMomentAudioMutation,
  useGetPromptOfDayQuery,
  useGetReelsFeedQuery,
  // Comment engagement, comment translation, replies, images, view counting
  useTranslateCommentMutation,
  useLikeCommentMutation,
  useReactToCommentMutation,
  useUnreactToCommentMutation,
  useGetCommentRepliesQuery,
  useUploadCommentImageMutation,
  useRecordMomentViewsMutation,
} = momentsApiSlice;

export default momentsApiSlice.reducer;
