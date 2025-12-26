import { apiSlice } from "./apiSlice";


export const storiesApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getFeeds: builder.query({
      // query: () => ({
      //   url: FEED_URL
      // }),
      // keepUnusedDataFor: 5,
      // providesTags: ["Stories"],
    }),
  }),
  // create: builder.mutation({
  //       query: (data: any) => ({
  //         url: `${MOMENTS_URL}`,
  //         method: "POST",
  //         body: data,
  //       }),
  //       invalidatesTags: ["Moment"],
  //     }),
})

export const {
  useGetFeedsQuery
} = storiesApiSlice;

export default storiesApiSlice.reducer;
