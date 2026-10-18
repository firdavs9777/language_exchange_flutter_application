import { apiSlice } from "./apiSlice";
import { GATHERINGS_URL, CLUBS_URL } from "../../constants";

/** be/lib/gatheringFilters.js GATHERING_TOPICS, same order. */
export const GATHERING_TOPICS = [
  "conversation",
  "exam_prep",
  "grammar",
  "pronunciation",
  "culture",
  "media",
  "games",
  "business",
  "travel",
];

/** be/models/Gathering.js `level` enum. */
export const GATHERING_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"];

export interface GatheringPerson {
  _id: string;
  name: string;
  username: string;
  images: string[];
  requestedAt?: string | null;
}

export interface GatheringHost {
  _id: string;
  name?: string;
  username?: string;
  images?: string[];
  imageUrls?: string[];
}

/** be/controllers/gatherings.js present(). Every field optional-safe on read. */
export interface Gathering {
  _id: string;
  title: string;
  description?: string;
  language: string;
  languageLabel?: string;
  level?: string | null;
  topic?: string | null;
  coverImage?: string | null;
  type?: string;
  host?: GatheringHost | string | null;
  hostCity?: string | null;
  hostCountry?: string | null;
  hostTimezone?: string | null;
  startsAt: string;
  durationMinutes: number;
  capacity: number;
  quorum: number;
  joinMode: "open" | "approval";
  status: "scheduled" | "confirmed" | "live" | "ended" | "cancelled";
  going: number;
  needed: number;
  quorumMet?: boolean;
  viewerIsAttending: boolean;
  viewerRequestPending?: boolean;
  viewerIsHost: boolean;
  requests?: GatheringPerson[];
  /** Only on an RSVP response: the RSVP became a request (approval mode). */
  pending?: boolean;
}

export interface ClubMember {
  _id: string;
  name: string;
  username: string;
  images: string[];
  role: "owner" | "organizer" | "member";
  joinedAt?: string | null;
}

/** be/controllers/clubs.js present() (+ detail-only fields). */
export interface Club {
  _id: string;
  name: string;
  description?: string;
  language: string;
  languageLabel?: string;
  interest?: string;
  owner?: GatheringHost | string | null;
  memberCount: number;
  status?: "active" | "archived";
  coverImage?: string | null;
  city?: string | null;
  place?: { name: string | null; address: string | null } | null;
  members: ClubMember[];
  roleCounts?: { owner: number; organizer: number; member: number };
  viewerCanManage: boolean;
  viewerIsMember: boolean;
  viewerIsOwner: boolean;
  upcoming?: number;
  pastCount?: number;
  gatherings?: Gathering[];
}

export interface GatheringListArgs {
  scope?: "mine" | "all" | "me";
  page?: number;
  language?: string;
  topic?: string;
  when?: "" | "today" | "week";
  hasSeat?: boolean;
}

export interface ClubListArgs {
  scope?: "mine" | "all" | "member";
  page?: number;
  language?: string;
}

/** What the create form sends (POST /gatherings). */
export interface GatheringInput {
  title: string;
  language: string;
  startsAt: string;
  description: string;
  level?: string;
  durationMinutes: number;
  capacity: number;
  quorum: number;
  joinMode: "open" | "approval";
  topic?: string;
  club?: string;
}

/**
 * The browse query, in the app's order: scope and page always, everything else
 * only when set, and hasSeat only when true -- the server treats anything but
 * 'true' as off (GatheringApiClient.getGatherings).
 */
export function gatheringListQuery(args: GatheringListArgs): string {
  const p = new URLSearchParams();
  p.set("scope", args.scope || "mine");
  p.set("page", String(args.page || 1));
  if (args.language) p.set("language", args.language);
  if (args.topic) p.set("topic", args.topic);
  if (args.when) p.set("when", args.when);
  if (args.hasSeat) p.set("hasSeat", "true");
  return p.toString();
}

function clubListQuery(args: ClubListArgs): string {
  const p = new URLSearchParams();
  p.set("scope", args.scope || "mine");
  p.set("page", String(args.page || 1));
  if (args.language) p.set("language", args.language);
  return p.toString();
}

/** Editable fields of a gathering as the form holds them. */
export interface GatheringEditable {
  title: string;
  description?: string;
  languageLabel?: string;
  language?: string;
  level?: string | null;
  topic?: string | null;
  startsAt: string;
  durationMinutes: number;
  capacity: number;
  joinMode: "open" | "approval";
}

/**
 * The partial PUT body: only what changed, like the app's updateGathering, so
 * moving the time can never blank the description. `topic: null` is sent on
 * purpose -- it is how a topic is cleared. Quorum is not editable server-side.
 */
export function gatheringEditBody(before: GatheringEditable, after: GatheringEditable): { [k: string]: any } {
  const body: { [k: string]: any } = {};
  const same = (a: any, b: any) => (a === undefined || a === null ? null : a) === (b === undefined || b === null ? null : b);
  if (!same(before.title, after.title)) body.title = after.title;
  if (!same(before.description || "", after.description || "")) body.description = after.description || "";
  const beforeLang = before.languageLabel || before.language;
  const afterLang = after.languageLabel || after.language;
  if (!same(beforeLang, afterLang)) body.language = afterLang;
  if (!same(before.level, after.level)) body.level = after.level || null;
  if (!same(before.topic, after.topic)) body.topic = after.topic || null;
  if (new Date(before.startsAt).getTime() !== new Date(after.startsAt).getTime()) body.startsAt = after.startsAt;
  if (!same(before.durationMinutes, after.durationMinutes)) body.durationMinutes = after.durationMinutes;
  if (!same(before.capacity, after.capacity)) body.capacity = after.capacity;
  if (!same(before.joinMode, after.joinMode)) body.joinMode = after.joinMode;
  return body;
}

const unwrapList = (response: any): any[] => {
  if (Array.isArray(response)) return response;
  const data = response && response.data;
  return Array.isArray(data) ? data : [];
};
const unwrapOne = (response: any): any => (response && response.data) || null;

const coverForm = (file: File) => {
  const form = new FormData();
  form.append("image", file);
  return form;
};

const gatheringTags = (id: string) => [{ type: "Gathering", id }, "Gatherings"];
const clubTags = (id: string) => [{ type: "Club", id }, "Clubs"];

export const gatheringsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // ---- gatherings -------------------------------------------------------
    getGatherings: builder.query({
      query: (args: GatheringListArgs = {}) => ({ url: `${GATHERINGS_URL}?${gatheringListQuery(args)}` }),
      transformResponse: unwrapList,
      providesTags: ["Gatherings"],
      keepUnusedDataFor: 30,
    }),
    getGathering: builder.query({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}` }),
      transformResponse: unwrapOne,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "Gathering", id }],
    }),
    createGathering: builder.mutation({
      query: (body: GatheringInput) => ({ url: GATHERINGS_URL, method: "POST", body }),
      transformResponse: unwrapOne,
      invalidatesTags: ["Gatherings", "Club"],
    }),
    updateGathering: builder.mutation({
      query: ({ id, body }: { id: string; body: { [k: string]: any } }) => ({
        url: `${GATHERINGS_URL}/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    cancelGathering: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}`, method: "DELETE" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    rsvpGathering: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/rsvp`, method: "POST" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    cancelRsvp: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/rsvp`, method: "DELETE" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    hostDecision: builder.mutation({
      query: ({ id, run }: { id: string; run: boolean }) => ({
        url: `${GATHERINGS_URL}/${id}/decision`,
        method: "POST",
        body: { run },
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    endGathering: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/end`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),
    decideJoinRequest: builder.mutation({
      query: ({ id, userId, approve }: { id: string; userId: string; approve: boolean }) => ({
        url: `${GATHERINGS_URL}/${id}/requests/${userId}`,
        method: "POST",
        body: { approve },
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    setGatheringCover: builder.mutation({
      query: ({ id, file }: { id: string; file: File }) => ({
        url: `${GATHERINGS_URL}/${id}/cover`,
        method: "POST",
        body: coverForm(file),
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => gatheringTags(a.id),
    }),
    removeGatheringCover: builder.mutation({
      query: (id: string) => ({ url: `${GATHERINGS_URL}/${id}/cover`, method: "DELETE" }),
      invalidatesTags: (_r: any, _e: any, id: string) => gatheringTags(id),
    }),

    // ---- clubs ------------------------------------------------------------
    getClubs: builder.query({
      query: (args: ClubListArgs = {}) => ({ url: `${CLUBS_URL}?${clubListQuery(args)}` }),
      transformResponse: unwrapList,
      providesTags: ["Clubs"],
      keepUnusedDataFor: 30,
    }),
    getClub: builder.query({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}` }),
      transformResponse: unwrapOne,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "Club", id }, "Club"],
    }),
    createClub: builder.mutation({
      query: (body: { name: string; description: string; language: string; interest: string }) => ({
        url: CLUBS_URL,
        method: "POST",
        body,
      }),
      transformResponse: unwrapOne,
      invalidatesTags: ["Clubs"],
    }),
    updateClub: builder.mutation({
      query: ({ id, body }: { id: string; body: { [k: string]: any } }) => ({
        url: `${CLUBS_URL}/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    deleteClub: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}`, method: "DELETE" }),
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
    joinClub: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}/join`, method: "POST" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
    leaveClub: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}/join`, method: "DELETE" }),
      transformResponse: unwrapOne,
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
    removeClubMember: builder.mutation({
      query: ({ id, userId }: { id: string; userId: string }) => ({
        url: `${CLUBS_URL}/${id}/members/${userId}`,
        method: "DELETE",
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    setClubMemberRole: builder.mutation({
      query: ({ id, userId, role }: { id: string; userId: string; role: "organizer" | "member" }) => ({
        url: `${CLUBS_URL}/${id}/members/${userId}`,
        method: "PUT",
        body: { role },
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    setClubCover: builder.mutation({
      query: ({ id, file }: { id: string; file: File }) => ({
        url: `${CLUBS_URL}/${id}/cover`,
        method: "POST",
        body: coverForm(file),
      }),
      invalidatesTags: (_r: any, _e: any, a: { id: string }) => clubTags(a.id),
    }),
    removeClubCover: builder.mutation({
      query: (id: string) => ({ url: `${CLUBS_URL}/${id}/cover`, method: "DELETE" }),
      invalidatesTags: (_r: any, _e: any, id: string) => clubTags(id),
    }),
  }),
});

export const {
  useGetGatheringsQuery,
  useGetGatheringQuery,
  useCreateGatheringMutation,
  useUpdateGatheringMutation,
  useCancelGatheringMutation,
  useRsvpGatheringMutation,
  useCancelRsvpMutation,
  useHostDecisionMutation,
  useEndGatheringMutation,
  useDecideJoinRequestMutation,
  useSetGatheringCoverMutation,
  useRemoveGatheringCoverMutation,
  useGetClubsQuery,
  useGetClubQuery,
  useCreateClubMutation,
  useUpdateClubMutation,
  useDeleteClubMutation,
  useJoinClubMutation,
  useLeaveClubMutation,
  useRemoveClubMemberMutation,
  useSetClubMemberRoleMutation,
  useSetClubCoverMutation,
  useRemoveClubCoverMutation,
} = gatheringsApiSlice as any;
