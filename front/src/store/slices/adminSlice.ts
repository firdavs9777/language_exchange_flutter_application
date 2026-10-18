import { ADMIN_URL, ADMIN_REPORTS_URL } from "../../constants";
import { apiSlice } from "./apiSlice";

/** `GET /admin/content/stats` — the content desk's stat strip. */
export interface ContentStats {
  moments: { total: number; today: number; last7d: number; hidden: number };
  comments: { total: number; last7d: number };
  clubs: { active: number; archived: number; membersTotal: number };
  gatherings: { upcoming: number; past: number; cancelled: number };
  reports: {
    pending: number;
    underReview: number;
    byType: {
      moment: number;
      comment: number;
      user: number;
      club: number;
      gathering: number;
      message: number;
      story: number;
    };
  };
}

/** One row of `GET /admin/content/moments` — a projection, not the document. */
export interface AdminMomentRow {
  id: string;
  title: string;
  description: string;
  imageUrl: string | null;
  language: string;
  category: string;
  user: { id: string; name: string; image: string | null } | null;
  likeCount: number;
  commentCount: number;
  viewCount: number;
  shareCount: number;
  openReports: number;
  isDeleted: boolean;
  createdAt: string;
}

/** `POST /admin/users` body. Mirrors `validateRegistration` in the backend. */
export interface CreateUserBody {
  name: string;
  email: string;
  password: string;
  gender: string;
  birth_year: number;
  birth_month: number;
  birth_day: number;
  native_language: string;
  language_to_learn: string;
  role?: "user" | "admin";
  bio?: string;
  markVerified?: boolean;
}

/** `PUT /admin/users/:id` body — a whitelist; anything absent is unchanged. */
export interface UpdateUserBody {
  name?: string;
  bio?: string;
  native_language?: string;
  language_to_learn?: string;
  gender?: string;
  vip?: { grant: boolean; days?: number };
}

/**
 * A row from `GET /api/v1/reports` (routes/report.js, mounted standalone in
 * server.js — NOT nested under ADMIN_URL). `reportedBy`/`reportedUser`/
 * `moderatedBy` come back populated; a string id is what an unpopulated
 * document would carry, kept here only as a defensive fallback.
 */
export interface AdminReportRow {
  _id: string;
  type: "user" | "moment" | "comment" | "message" | "story" | "gathering" | "club";
  reportId: string;
  reportedBy:
    | { _id: string; name: string; email: string; images?: string[] }
    | string;
  reportedUser:
    | {
        _id: string;
        name: string;
        email: string;
        images?: string[];
        imageUrls?: string[];
        native_language?: string;
        language_to_learn?: string;
        location?: any;
        createdAt?: string;
        isBanned?: boolean;
      }
    | string;
  reason:
    | "spam"
    | "harassment"
    | "hate_speech"
    | "violence"
    | "nudity"
    | "false_information"
    | "copyright"
    | "other";
  description?: string;
  status: "pending" | "under_review" | "resolved" | "dismissed";
  moderatorAction?:
    | "pending"
    | "content_removed"
    | "user_warned"
    | "user_suspended"
    | "user_banned"
    | "no_violation";
  moderatedBy?: { _id: string; name: string; email: string } | string | null;
  moderatorNotes?: string;
  reviewedAt?: string | null;
  resolvedAt?: string | null;
  priority?: "low" | "medium" | "high" | "urgent";
  contentHidden?: boolean;
  createdAt: string;
  updatedAt: string;
}

/** Announcements (spec 2026-10-12 §5.1/§5.3). Mirrors models/Announcement.js. */
export type AnnouncementStatus = "draft" | "scheduled" | "live" | "ended";
export type AnnouncementPlatform = "all" | "ios" | "android" | "web";
export type AnnouncementDisplayStyle = "popup" | "banner";
export type AnnouncementDeliveryState = "none" | "queued" | "running" | "done" | "failed";

export interface AnnouncementTranslation {
  title: string;
  body: string;
  buttonLabel?: string;
}

/** A row of `GET /admin/announcements` (translations flattened to an object). */
export interface AdminAnnouncement {
  id: string;
  _id: string;
  status: AnnouncementStatus;
  priority: number;
  translations: { [locale: string]: AnnouncementTranslation };
  defaultLocale: string;
  emoji: string | null;
  imageUrl: string | null;
  buttonUrl: string | null;
  platforms: AnnouncementPlatform[];
  displayStyle?: AnnouncementDisplayStyle;
  languages: string[];
  startsAt: string | null;
  endsAt: string | null;
  showInApp: boolean;
  notify: boolean;
  publishedAt: string | null;
  endedAt: string | null;
  delivery: {
    state: AnnouncementDeliveryState;
    targeted: number;
    pushed: number;
    listed: number;
    failed: number;
    startedAt: string | null;
    finishedAt: string | null;
    /** Touched every batch while running; a run idle >10 min is taken over. */
    heartbeatAt?: string | null;
    /** Claims so far (first run, stale takeovers, failed retries); the job stops retrying at 3. */
    attempts?: number;
    /** 'end_time': finished `done` because endsAt passed before every batch went out. Absent otherwise. */
    stoppedReason?: string | null;
    /** Last failure message (cleared on the next claim). */
    error?: string | null;
  };
  createdAt: string;
  updatedAt: string;
}

/** `POST`/`PUT /admin/announcements` body — anything absent is unchanged. */
export interface AnnouncementInput {
  translations?: { [locale: string]: AnnouncementTranslation };
  defaultLocale?: string;
  emoji?: string;
  imageUrl?: string | null;
  buttonUrl?: string | null;
  platforms?: AnnouncementPlatform[];
  displayStyle?: AnnouncementDisplayStyle;
  languages?: string[];
  startsAt?: string | null;
  endsAt?: string | null;
  showInApp?: boolean;
  notify?: boolean;
  priority?: number;
}

/** `GET /admin/announcements/:id/audience-count`: push audience and list audience. */
export interface AudienceCount {
  count: number;
  listed: number;
  /** `web_only`: it cannot reach the app, so there is no push audience. */
  reason?: "web_only";
}

/**
 * The admin console's data layer: one endpoint per route in the backend's
 * `routes/admin.js`, and nothing the backend doesn't serve. Every route below
 * sits behind `protect` + `authorize('admin')`, so a non-admin reaching one of
 * these gets a 403 regardless of what the client believes about its user.
 *
 * Two conventions the six pages rely on:
 *
 *  - `transformResponse` unwraps the `{ success, data, ... }` envelope. A
 *    paginated read returns `{ data, pagination }`; everything else returns
 *    `data` itself, so a page never writes `?.data?.data`.
 *  - Tags: `AdminUserList` is carried by both user lists (search and banned) so
 *    a ban, unban, role change or delete refetches whichever table the
 *    moderator is looking at; `AdminUser` is per-id for the detail drawer;
 *    `AdminContent` covers clubs and gatherings.
 */

/** Drop undefined/null/empty values so we never send `?q=` or `?feature=`. */
const params = (arg: Record<string, any> = {}): Record<string, string> => {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(arg || {})) {
    if (value !== undefined && value !== null && value !== "") {
      out[key] = String(value);
    }
  }
  return out;
};

/** `data` out of the envelope; `null` rather than `undefined` when absent. */
const unwrap = (response: any) => (response && "data" in response ? response.data : response);

/**
 * A paginated list, normalized to `{ data, pagination }`.
 *
 * `/users`, `/banned-users`, `/audit-log` and `/ai-usage/logs` return a real
 * `pagination` object. The content routes (`/content/clubs`, `/content/
 * gatherings`) return flat `count`/`total` instead — mapped here to the same
 * shape so the tables don't need two code paths. `hasMore` is only ever what
 * the backend said: it is never inferred.
 */
const unwrapList = (response: any) => ({
  data: Array.isArray(response?.data) ? response.data : [],
  pagination:
    response?.pagination ||
    { total: response?.total ?? 0, count: response?.count ?? 0 },
});

export const adminApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // --- Dashboard reads -------------------------------------------------
    getAdminStats: builder.query({
      query: () => ({ url: `${ADMIN_URL}/stats` }),
      transformResponse: unwrap,
      providesTags: ["AdminStats"],
    }),
    getAdminActivity: builder.query({
      query: (arg: { limit?: number } = {}) => ({
        url: `${ADMIN_URL}/activity`,
        params: params(arg),
      }),
      transformResponse: unwrap,
      providesTags: ["AdminStats"],
    }),

    // --- Users -----------------------------------------------------------
    searchAdminUsers: builder.query({
      query: (arg: { q?: string; adminsOnly?: boolean; page?: number; limit?: number } = {}) => ({
        url: `${ADMIN_URL}/users`,
        params: params(arg),
      }),
      transformResponse: unwrapList,
      providesTags: ["AdminUserList"],
    }),
    getAdminUser: builder.query({
      query: (id: string) => ({ url: `${ADMIN_URL}/users/${id}` }),
      transformResponse: unwrap,
      providesTags: (_result: any, _error: any, id: string) => [{ type: "AdminUser", id }],
    }),
    getBannedUsers: builder.query({
      query: (arg: { page?: number; limit?: number; search?: string } = {}) => ({
        url: `${ADMIN_URL}/banned-users`,
        params: params(arg),
      }),
      transformResponse: unwrapList,
      providesTags: ["AdminUserList"],
    }),

    // --- User moderation --------------------------------------------------
    // `reason` is required by the backend on ban; the dialogs enforce it before
    // these ever fire. None of the four is retried: a moderation action that
    // silently repeats is worse than one that visibly failed. All four also
    // invalidate `AdminStats`: each one moves the Overview's total/banned/
    // admins counters, and stale counters read as "the action didn't work".
    banAdminUser: builder.mutation({
      query: ({ id, reason }: { id: string; reason: string }) => ({
        url: `${ADMIN_URL}/users/${id}/ban`,
        method: "POST",
        body: { reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminUser", id: arg.id },
        "AdminUserList",
        "AdminStats",
      ],
    }),
    unbanAdminUser: builder.mutation({
      query: ({ id, reason }: { id: string; reason?: string }) => ({
        url: `${ADMIN_URL}/users/${id}/unban`,
        method: "POST",
        body: { reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminUser", id: arg.id },
        "AdminUserList",
        "AdminStats",
      ],
    }),
    changeAdminUserRole: builder.mutation({
      query: ({ id, role, reason }: { id: string; role: "admin" | "user"; reason?: string }) => ({
        url: `${ADMIN_URL}/users/${id}/role`,
        method: "PUT",
        body: { role, reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminUser", id: arg.id },
        "AdminUserList",
        "AdminStats",
      ],
    }),
    hardDeleteAdminUser: builder.mutation({
      query: ({ id, reason }: { id: string; reason?: string }) => ({
        url: `${ADMIN_URL}/users/${id}`,
        method: "DELETE",
        body: { reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminUser", id: arg.id },
        "AdminUserList",
        "AdminStats",
      ],
    }),

    // --- Audit log ---------------------------------------------------------
    getAuditLog: builder.query({
      query: (
        arg: {
          moderatorId?: string;
          targetId?: string;
          action?: string;
          page?: number;
          limit?: number;
        } = {}
      ) => ({ url: `${ADMIN_URL}/audit-log`, params: params(arg) }),
      transformResponse: unwrapList,
    }),

    // --- AI usage ----------------------------------------------------------
    getAiUsage: builder.query({
      query: (arg: { feature?: string; from?: string; to?: string } = {}) => ({
        url: `${ADMIN_URL}/ai-usage`,
        params: params(arg),
      }),
      transformResponse: unwrap,
    }),
    getAiUsageLogs: builder.query({
      query: (
        arg: { feature?: string; from?: string; to?: string; page?: number; limit?: number } = {}
      ) => ({ url: `${ADMIN_URL}/ai-usage/logs`, params: params(arg) }),
      transformResponse: unwrapList,
    }),

    // --- Content moderation -------------------------------------------------
    getAdminClubs: builder.query({
      query: (arg: { page?: number; limit?: number; reported?: boolean } = {}) => ({
        url: `${ADMIN_URL}/content/clubs`,
        params: params(arg),
      }),
      transformResponse: unwrapList,
      providesTags: ["AdminContent"],
    }),
    getAdminGatherings: builder.query({
      query: (arg: { page?: number; limit?: number; reported?: boolean } = {}) => ({
        url: `${ADMIN_URL}/content/gatherings`,
        params: params(arg),
      }),
      transformResponse: unwrapList,
      providesTags: ["AdminContent"],
    }),
    archiveAdminClub: builder.mutation({
      // `archived` defaults to true: the button says "Archive". Passing false
      // is how the same endpoint un-archives.
      query: ({
        id,
        archived = true,
        reason,
      }: {
        id: string;
        archived?: boolean;
        reason?: string;
      }) => ({
        url: `${ADMIN_URL}/content/clubs/${id}/archive`,
        method: "POST",
        body: { archived, reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminContent"],
    }),
    cancelAdminGathering: builder.mutation({
      query: ({ id, reason }: { id: string; reason?: string }) => ({
        url: `${ADMIN_URL}/content/gatherings/${id}/cancel`,
        method: "POST",
        body: { reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminContent"],
    }),

    // --- Content desk: moments moderation -----------------------------------
    // Separate tags from `AdminContent` (clubs/gatherings) on purpose: hiding
    // a moment has no reason to refetch the club and gathering tables, and a
    // club archive has no reason to refetch the moments table.
    getContentStats: builder.query({
      query: () => ({ url: `${ADMIN_URL}/content/stats` }),
      transformResponse: unwrap,
      providesTags: ["AdminContentStats"],
    }),
    listMoments: builder.query({
      query: (
        arg: {
          page?: number;
          limit?: number;
          q?: string;
          reported?: boolean;
          hidden?: boolean;
        } = {}
      ) => ({
        url: `${ADMIN_URL}/content/moments`,
        params: params(arg),
      }),
      transformResponse: unwrapList,
      providesTags: ["AdminMoments"],
    }),
    setMomentHidden: builder.mutation({
      // `hidden` defaults to true server-side, but the button drives both
      // directions explicitly (Hide / Unhide), so it's always sent here.
      query: ({ id, hidden, reason }: { id: string; hidden: boolean; reason?: string }) => ({
        url: `${ADMIN_URL}/content/moments/${id}/hide`,
        method: "POST",
        body: { hidden, reason },
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      // Both the moments table (isDeleted/openReports badge) and the stat
      // strip's "hidden" counter move when this succeeds.
      invalidatesTags: ["AdminMoments", "AdminContentStats"],
    }),

    // --- User management: create and edit -----------------------------------
    createUser: builder.mutation({
      query: (body: CreateUserBody) => ({
        url: `${ADMIN_URL}/users`,
        method: "POST",
        body,
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      // A brand-new user belongs in whichever list the moderator has open
      // (search results, or the page after a refresh) — same list tag a
      // ban/unban/role-change/delete already invalidates.
      invalidatesTags: ["AdminUserList"],
    }),
    updateUser: builder.mutation({
      query: ({ id, ...body }: { id: string } & UpdateUserBody) => ({
        url: `${ADMIN_URL}/users/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminUser", id: arg.id },
        "AdminUserList",
      ],
    }),

    // --- Reports queue -------------------------------------------------------
    // routes/report.js is mounted standalone (`/api/v1/reports`), not nested
    // under ADMIN_URL — see ADMIN_REPORTS_URL. The backend's query param is
    // `type` (controllers/report.js `getAllReports`), not `targetType`; the
    // arg is named `targetType` here to read clearly next to `AdminMomentRow`/
    // `AdminReportRow`'s own `type` field. `page`/`limit` are accepted by this
    // call but NOT read by `getAllReports` today (it always returns the newest
    // 100) — sent anyway so the list doesn't need a shape change if the
    // backend adds real pagination later.
    listReports: builder.query({
      query: (
        arg: {
          status?: string;
          targetType?: string;
          page?: number;
          limit?: number;
        } = {}
      ) => ({
        url: ADMIN_REPORTS_URL,
        params: params({
          status: arg.status,
          type: arg.targetType,
          page: arg.page,
          limit: arg.limit,
        }),
      }),
      transformResponse: unwrap,
      providesTags: ["AdminReports"],
    }),
    reviewReport: builder.mutation({
      query: (id: string) => ({
        url: `${ADMIN_REPORTS_URL}/${id}/review`,
        method: "PUT",
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      // A report resolution can hide a moment or ban a user, so the moments
      // table and the stat strip's counters are invalidated alongside the
      // reports queue itself on all three actions below.
      invalidatesTags: ["AdminReports", "AdminContentStats", "AdminMoments"],
    }),
    resolveReport: builder.mutation({
      query: ({
        id,
        ...body
      }: {
        id: string;
        action: "content_removed" | "user_warned" | "user_suspended" | "user_banned" | "no_violation";
        notes?: string;
      }) => ({
        url: `${ADMIN_REPORTS_URL}/${id}/resolve`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminReports", "AdminContentStats", "AdminMoments"],
    }),
    dismissReport: builder.mutation({
      query: ({ id, ...body }: { id: string; notes?: string }) => ({
        url: `${ADMIN_REPORTS_URL}/${id}/dismiss`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminReports", "AdminContentStats", "AdminMoments"],
    }),

    // --- Reach analytics -----------------------------------------------------
    getAnalyticsEvents: builder.query({
      query: (arg: { days?: number } = {}) => ({
        url: `${ADMIN_URL}/analytics/events`,
        params: params(arg),
      }),
      transformResponse: unwrap,
    }),
    getAnalyticsVisits: builder.query({
      query: () => ({ url: `${ADMIN_URL}/analytics/visits` }),
      transformResponse: unwrap,
    }),

    // --- Announcements (spec 2026-10-12 §5.3) --------------------------------
    // Writes are never retried: a publish that silently repeats is a second
    // push to every user (the backend dedupes per user, but it should never
    // have to).
    listAnnouncements: builder.query({
      query: (arg: { status?: AnnouncementStatus } = {}) => ({
        url: `${ADMIN_URL}/announcements`,
        params: params(arg),
      }),
      transformResponse: unwrap,
      providesTags: ["AdminAnnouncements"],
    }),
    getAnnouncement: builder.query({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}` }),
      transformResponse: unwrap,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "AdminAnnouncement", id }],
    }),
    createAnnouncement: builder.mutation({
      query: (body: AnnouncementInput) => ({ url: `${ADMIN_URL}/announcements`, method: "POST", body }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminAnnouncements"],
    }),
    updateAnnouncement: builder.mutation({
      query: ({ id, ...body }: { id: string } & AnnouncementInput) => ({
        url: `${ADMIN_URL}/announcements/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminAnnouncement", id: arg.id },
        "AdminAnnouncements",
      ],
    }),
    publishAnnouncement: builder.mutation({
      query: ({ id, at }: { id: string; at?: string }) => ({
        url: `${ADMIN_URL}/announcements/${id}/publish`,
        method: "POST",
        body: at ? { at } : {},
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminAnnouncement", id: arg.id },
        "AdminAnnouncements",
      ],
    }),
    endAnnouncement: builder.mutation({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}/end`, method: "POST" }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, id: string) => [{ type: "AdminAnnouncement", id }, "AdminAnnouncements"],
    }),
    deleteAnnouncement: builder.mutation({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}`, method: "DELETE" }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminAnnouncements"],
    }),
    // Asked right before the confirm dialog; never served from cache.
    getAnnouncementAudience: builder.query({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}/audience-count` }),
      transformResponse: unwrap,
      keepUnusedDataFor: 0,
    }),
    uploadAnnouncementImage: builder.mutation({
      query: (file: File) => {
        const form = new FormData();
        form.append("image", file);
        return { url: `${ADMIN_URL}/announcements/upload-image`, method: "POST", body: form };
      },
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
    }),
  }),
});

export const {
  useGetAdminStatsQuery,
  useGetAdminActivityQuery,
  useSearchAdminUsersQuery,
  useGetAdminUserQuery,
  useGetBannedUsersQuery,
  useBanAdminUserMutation,
  useUnbanAdminUserMutation,
  useChangeAdminUserRoleMutation,
  useHardDeleteAdminUserMutation,
  useGetAuditLogQuery,
  useGetAiUsageQuery,
  useGetAiUsageLogsQuery,
  useGetAdminClubsQuery,
  useGetAdminGatheringsQuery,
  useArchiveAdminClubMutation,
  useCancelAdminGatheringMutation,
  useGetContentStatsQuery,
  useListMomentsQuery,
  useSetMomentHiddenMutation,
  useCreateUserMutation,
  useUpdateUserMutation,
  useListReportsQuery,
  useReviewReportMutation,
  useResolveReportMutation,
  useDismissReportMutation,
  useGetAnalyticsEventsQuery,
  useGetAnalyticsVisitsQuery,
  useListAnnouncementsQuery,
  useGetAnnouncementQuery,
  useCreateAnnouncementMutation,
  useUpdateAnnouncementMutation,
  usePublishAnnouncementMutation,
  useEndAnnouncementMutation,
  useDeleteAnnouncementMutation,
  useLazyGetAnnouncementAudienceQuery,
  useUploadAnnouncementImageMutation,
} = adminApiSlice;
