import { apiSlice } from "./apiSlice";

/** Voice rooms (LiveKit audio rooms). Same endpoints as the app. */
export const VOICE_ROOMS_URL = "/api/v1/voicerooms";

export interface VoiceRoomUser {
  _id: string;
  name?: string;
  images?: string[];
}

export interface VoiceRoomSummary {
  _id: string;
  title: string;
  description?: string;
  topic?: string;
  language: string;
  secondaryLanguage?: string;
  host: VoiceRoomUser | string;
  participantCount?: number;
  maxParticipants: number;
  participants?: Array<{ _id?: string; name?: string; images?: string[]; role?: string; isSpeaking?: boolean }>;
  status: "scheduled" | "waiting" | "active" | "ended";
  tags?: string[];
  scheduledFor?: string | null;
  rsvps?: Array<{ user: string }>;
  category?: string | null;
  createdAt?: string;
}

export interface VoiceRoomToken {
  token: string;
  url: string;
  roomName: string;
  role: "host" | "participant";
}

export interface CreateVoiceRoomBody {
  title: string;
  description?: string;
  topic?: string;
  language: string;
  secondaryLanguage?: string;
  maxParticipants?: number;
  category?: string;
  scheduledFor?: string;
}

const compact = (obj: { [k: string]: any }) => {
  const out: { [k: string]: any } = {};
  Object.keys(obj).forEach((k) => {
    const v = obj[k];
    if (v !== undefined && v !== null && v !== "") out[k] = v;
  });
  return out;
};

const tagged = apiSlice.enhanceEndpoints({ addTagTypes: ["VoiceRooms"] });

export const voiceRoomsApiSlice = tagged.injectEndpoints({
  endpoints: (builder: any) => ({
    getVoiceRooms: builder.query({
      query: (arg: { status?: "scheduled" | "all"; language?: string; page?: number } = {}) => ({
        url: VOICE_ROOMS_URL,
        params: compact({ status: arg.status, language: arg.language, page: String(arg.page || 1), limit: "20" }),
      }),
      keepUnusedDataFor: 15,
      providesTags: ["VoiceRooms"],
    }),
    getVoiceRoom: builder.query({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}` }),
      transformResponse: (r: any) => (r && r.data) || null,
      keepUnusedDataFor: 5,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "VoiceRooms", id }],
    }),
    getMyVoiceRoom: builder.query({
      query: () => ({ url: `${VOICE_ROOMS_URL}/my` }),
      transformResponse: (r: any) => (r && r.data) || null,
      keepUnusedDataFor: 0,
    }),
    createVoiceRoom: builder.mutation({
      query: (body: CreateVoiceRoomBody) => ({ url: VOICE_ROOMS_URL, method: "POST", body: compact(body as any) }),
      invalidatesTags: ["VoiceRooms"],
    }),
    joinVoiceRoom: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/join`, method: "POST" }),
    }),
    getVoiceRoomToken: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/token`, method: "POST" }),
      transformResponse: (r: any): VoiceRoomToken => r && r.data,
    }),
    leaveVoiceRoom: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/leave`, method: "POST" }),
      invalidatesTags: ["VoiceRooms"],
    }),
    endVoiceRoom: builder.mutation({
      query: (id: string) => ({ url: `${VOICE_ROOMS_URL}/${id}/end`, method: "POST" }),
      invalidatesTags: ["VoiceRooms"],
    }),
    promoteVoiceParticipant: builder.mutation({
      query: ({ roomId, userId }: { roomId: string; userId: string }) => ({
        url: `${VOICE_ROOMS_URL}/${roomId}/promote/${userId}`,
        method: "PUT",
      }),
      invalidatesTags: (_r: any, _e: any, arg: { roomId: string }) => [{ type: "VoiceRooms", id: arg.roomId }],
    }),
    rsvpVoiceRoom: builder.mutation({
      query: ({ roomId, going }: { roomId: string; going: boolean }) => ({
        url: `${VOICE_ROOMS_URL}/${roomId}/rsvp`,
        method: going ? "POST" : "DELETE",
      }),
      invalidatesTags: ["VoiceRooms"],
    }),
  }),
});

/**
 * The backend's refusal, in words a member can act on. Never the raw server
 * string: those are English-only and some are written for developers.
 */
export function voiceRoomErrorText(err: any, t: (k: string) => string): string {
  const raw = String((err && err.data && (err.data.error || err.data.message)) || "");
  if (/Room is full/i.test(raw)) return t("voiceRooms.errors.full") || "This room is full.";
  if (/has ended/i.test(raw)) return t("voiceRooms.errors.ended") || "This room has ended.";
  if (/cannot join/i.test(raw)) return t("voiceRooms.errors.blocked") || "You can't join this room.";
  if (/not available for your account type/i.test(raw))
    return t("voiceRooms.errors.vipToCreate") || "Creating voice rooms needs a VIP plan.";
  if (err && err.status === 404) return t("voiceRooms.errors.gone") || "This room is no longer available.";
  return t("voiceRooms.errors.generic") || "Something went wrong. Try again.";
}

export const {
  useGetVoiceRoomsQuery,
  useGetVoiceRoomQuery,
  useGetMyVoiceRoomQuery,
  useCreateVoiceRoomMutation,
  useJoinVoiceRoomMutation,
  useGetVoiceRoomTokenMutation,
  useLeaveVoiceRoomMutation,
  useEndVoiceRoomMutation,
  usePromoteVoiceParticipantMutation,
  useRsvpVoiceRoomMutation,
} = voiceRoomsApiSlice as any;
