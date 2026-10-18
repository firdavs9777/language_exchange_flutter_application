import { apiSlice } from "./apiSlice";
import { PublicAnnouncement } from "./appConfigSlice";

export const announcementsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getPublicAnnouncement: builder.query({
      query: ({ id, lang }: { id: string; lang?: string }) =>
        ({ url: `/api/v1/announcements/${encodeURIComponent(id)}${lang ? `?lang=${encodeURIComponent(lang)}` : ""}` }),
      transformResponse: (r: any): PublicAnnouncement => (r && r.data) || r,
    }),
  }),
});

export const { useGetPublicAnnouncementQuery } = announcementsApiSlice as any;
