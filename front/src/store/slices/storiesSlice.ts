import {
  MAIN_STORIES,
  STORIES_FEED,
  MY_STORIES,
} from "../../constants";
import { apiSlice } from "./apiSlice";

export const storiesApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // Get all story feeds
    getStoryFeeds: builder.query({
      query: () => ({
        url: STORIES_FEED,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["Stories"],
    }),
    // Get All my stories
    getMyStories: builder.query({
      query: () => ({
        url: MY_STORIES,
      }),
      keepUnusedDataFor: 5,
      providesTags: ["Stories"],
    }),
    // Create new story
    createStory: builder.mutation({
      query: (data: any) => ({
        url: MAIN_STORIES,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Stories"],
    }),
    // Create video story
    createVideoStory: builder.mutation({
      query: (data: any) => ({
        url: `${MAIN_STORIES}/video`,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Stories"],
    }),
    // Get Individual Story Item
    getIndividualStory: builder.query({
      query: (storyId: string) => ({
        url: `${MAIN_STORIES}/${storyId}`,
      }),
      keepUnusedDataFor: 5,
    }),
    // Delete individual story
    deleteIndividualStory: builder.mutation({
      query: (storyId: string) => ({
        url: `${MAIN_STORIES}/${storyId}`,
        method: "DELETE",
      }),
      keepUnusedDataFor: 5,
      invalidatesTags: ["Stories"],
    }),
    // Mark story as viewed
    markIndividualStoryViewed: builder.mutation({
      query: (storyId: string) => ({
        url: `${MAIN_STORIES}/${storyId}/view`,
        method: "POST",
      }),
      keepUnusedDataFor: 5,
      invalidatesTags: ["Stories"],
    }),
    // Total User Viewers
    getStoryViewers: builder.query({
      query: (storyId: string) => ({
        url: `${MAIN_STORIES}/${storyId}/views`,
      }),
    }),
    // User Specific Stories
    getUserStories: builder.query({
      query: (userId: string) => ({
        url: `${MAIN_STORIES}/user/${userId}`,
      }),
    }),
    // React to story
    reactToStory: builder.mutation({
      query: ({ storyId, emoji }: { storyId: string; emoji: string }) => ({
        url: `${MAIN_STORIES}/${storyId}/react`,
        method: "POST",
        body: { emoji },
      }),
      invalidatesTags: ["Stories"],
    }),
    // Get story reactions
    getStoryReactions: builder.query({
      query: (storyId: string) => ({
        url: `${MAIN_STORIES}/${storyId}/reactions`,
      }),
    }),
    // Reply to story
    replyToStory: builder.mutation({
      query: ({ storyId, message }: { storyId: string; message: string }) => ({
        url: `${MAIN_STORIES}/${storyId}/reply`,
        method: "POST",
        body: { message },
      }),
    }),
    // Vote on poll
    voteOnPoll: builder.mutation({
      query: ({ storyId, optionIndex }: { storyId: string; optionIndex: number }) => ({
        url: `${MAIN_STORIES}/${storyId}/poll/vote`,
        method: "POST",
        body: { optionIndex },
      }),
      invalidatesTags: ["Stories"],
    }),
    // Answer question
    answerQuestion: builder.mutation({
      query: ({ storyId, answer }: { storyId: string; answer: string }) => ({
        url: `${MAIN_STORIES}/${storyId}/question/answer`,
        method: "POST",
        body: { answer },
      }),
    }),
    // Get question responses
    getQuestionResponses: builder.query({
      query: (storyId: string) => ({
        url: `${MAIN_STORIES}/${storyId}/question/responses`,
      }),
    }),
    // Share story
    shareStory: builder.mutation({
      query: ({ storyId, userId }: { storyId: string; userId: string }) => ({
        url: `${MAIN_STORIES}/${storyId}/share`,
        method: "POST",
        body: { userId },
      }),
    }),
    // Highlights
    getHighlights: builder.query({
      query: () => ({
        url: `${MAIN_STORIES}/highlights`,
      }),
      providesTags: ["Stories"],
    }),
    getUserHighlights: builder.query({
      query: (userId: string) => ({
        url: `${MAIN_STORIES}/highlights/user/${userId}`,
      }),
    }),
    createHighlight: builder.mutation({
      query: (data: { title: string; storyIds: string[] }) => ({
        url: `${MAIN_STORIES}/highlights`,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Stories"],
    }),
    deleteHighlight: builder.mutation({
      query: (highlightId: string) => ({
        url: `${MAIN_STORIES}/highlights/${highlightId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Stories"],
    }),
    // Close Friends
    getCloseFriends: builder.query({
      query: () => ({
        url: `${MAIN_STORIES}/close-friends`,
      }),
    }),
    addCloseFriend: builder.mutation({
      query: (userId: string) => ({
        url: `${MAIN_STORIES}/close-friends/${userId}`,
        method: "POST",
      }),
    }),
    removeCloseFriend: builder.mutation({
      query: (userId: string) => ({
        url: `${MAIN_STORIES}/close-friends/${userId}`,
        method: "DELETE",
      }),
    }),
  }),
});

export const {
  useGetStoryFeedsQuery,
  useGetMyStoriesQuery,
  useCreateStoryMutation,
  useCreateVideoStoryMutation,
  useGetIndividualStoryMutation,
  useGetIndividualStoryQuery,
  useDeleteIndividualStoryMutation,
  useGetStoryViewersQuery,
  useMarkIndividualStoryViewedMutation,
  useGetUserStoriesQuery,
  // New hooks
  useReactToStoryMutation,
  useGetStoryReactionsQuery,
  useReplyToStoryMutation,
  useVoteOnPollMutation,
  useAnswerQuestionMutation,
  useGetQuestionResponsesQuery,
  useShareStoryMutation,
  useGetHighlightsQuery,
  useGetUserHighlightsQuery,
  useCreateHighlightMutation,
  useDeleteHighlightMutation,
  useGetCloseFriendsQuery,
  useAddCloseFriendMutation,
  useRemoveCloseFriendMutation,
} = storiesApiSlice;
export default storiesApiSlice.reducer;
