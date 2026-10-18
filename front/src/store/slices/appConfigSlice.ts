import { apiSlice } from "./apiSlice";

/** One live announcement as app-config returns it (backend services/announcementService.js toPublic). */
export interface PublicAnnouncement {
  id: string;
  title: string;
  body: string;
  emoji: string | null;
  imageUrl: string | null;
  buttonLabel: string | null;
  buttonUrl: string | null;
  priority: number;
  displayStyle: "popup" | "banner";
}

export interface AppConfigArgs { platform?: string; lang?: string }

/** GET /api/v1/app-config: the server's public feature flags. */
export interface AppConfig {
  momentSchedulingEnforced?: boolean;
  announcements?: PublicAnnouncement[];
  [flag: string]: any;
}

export const appConfigApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getAppConfig: builder.query({
      query: (args?: AppConfigArgs) => {
        const params = new URLSearchParams();
        if (args && args.platform) params.set("platform", args.platform);
        if (args && args.lang) params.set("lang", args.lang);
        const qs = params.toString();
        return { url: `/api/v1/app-config${qs ? `?${qs}` : ""}` };
      },
      transformResponse: (response: any): AppConfig => (response && response.data) || {},
      keepUnusedDataFor: 300,
    }),
  }),
});

export const { useGetAppConfigQuery } = appConfigApiSlice as any;
