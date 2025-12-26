import {
  MAIN_STORIES,
  USER_STORIES,
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
    createStory: builder.query({
      query: (data: any) => ({
        url: MAIN_STORIES,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Story"],
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
  }),
});

export const {
  useGetStoryFeedsQuery,
  useGetMyStoriesQuery,
  useCreateStoryMutation,
  useGetIndividualStoryMutation,
  useGetIndividualStoryQuery,
  useDeleteIndividualStoryMutation,
  useGetStoryViewersQuery,
  useMarkIndividualStoryViewedMutation,
  useGetUserStoriesQuery,
} = storiesApiSlice;
export default storiesApiSlice.reducer;
