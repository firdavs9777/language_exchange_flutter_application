import { apiSlice } from "./apiSlice";

/** Language rooms ("hubs" + user topic rooms), routes/rooms.js. Same calls as the app. */
export const LANGUAGE_ROOMS_URL = "/api/v1/rooms";

export interface LanguageRoom {
  _id: string;
  roomType: "hub" | "topic";
  title: string;
  description?: string;
  emojiFlag?: string;
  targetLanguage: string;
  owner?: string;
  memberCount?: number;
  maxMembers?: number;
  onlineCount?: number;
  isMember?: boolean;
  isOwnerOrAdmin?: boolean;
  isBanned?: boolean;
  hasPendingRequest?: boolean;
  pendingRequestCount?: number;
  lastActivityAt?: string;
}

export function groupRoomsByLanguage(rooms: LanguageRoom[]): Array<{ language: string; hub: LanguageRoom | null; topics: LanguageRoom[] }> {
  const order: string[] = [];
  const groups: { [lang: string]: { language: string; hub: LanguageRoom | null; topics: LanguageRoom[] } } = {};
  (rooms || []).forEach((room) => {
    const lang = String(room.targetLanguage || "");
    if (!groups[lang]) {
      groups[lang] = { language: lang, hub: null, topics: [] };
      order.push(lang);
    }
    if (room.roomType === "hub" && !groups[lang].hub) groups[lang].hub = room;
    else groups[lang].topics.push(room);
  });
  return order.map((lang) => groups[lang]);
}

const tagged = apiSlice.enhanceEndpoints({ addTagTypes: ["LanguageRooms", "LanguageRoomRequests"] });

export const languageRoomsApiSlice = tagged.injectEndpoints({
  endpoints: (builder: any) => ({
    getLanguageRooms: builder.query({
      query: () => ({ url: LANGUAGE_ROOMS_URL }),
      keepUnusedDataFor: 30,
      providesTags: ["LanguageRooms"],
    }),
    getLanguageRoom: builder.query({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}` }),
      transformResponse: (r: any) => (r && r.data) || null,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRooms", id }],
    }),
    createTopicRoom: builder.mutation({
      query: (body: { title: string; targetLanguage: string; description?: string }) => ({
        url: LANGUAGE_ROOMS_URL,
        method: "POST",
        body: { title: String(body.title || "").trim(), targetLanguage: body.targetLanguage, description: String(body.description || "").trim() },
      }),
      invalidatesTags: ["LanguageRooms"],
    }),
    joinLanguageRoom: builder.mutation({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/join`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => ["LanguageRooms", { type: "LanguageRooms", id }],
    }),
    leaveLanguageRoom: builder.mutation({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/leave`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => ["LanguageRooms", { type: "LanguageRooms", id }],
    }),
    requestJoinLanguageRoom: builder.mutation({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/request-join`, method: "POST" }),
      invalidatesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRooms", id }],
    }),
    getLanguageRoomMessages: builder.query({
      query: ({ roomId, page = 1 }: { roomId: string; page?: number }) => ({
        url: `${LANGUAGE_ROOMS_URL}/${roomId}/messages`,
        params: { page: String(page), limit: "50" },
      }),
      keepUnusedDataFor: 0,
    }),
    getLanguageRoomMembers: builder.query({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/members` }),
      providesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRooms", id: `${id}:members` }],
    }),
    getLanguageRoomRequests: builder.query({
      query: (id: string) => ({ url: `${LANGUAGE_ROOMS_URL}/${id}/requests` }),
      providesTags: (_r: any, _e: any, id: string) => [{ type: "LanguageRoomRequests", id }],
    }),
    decideLanguageRoomRequest: builder.mutation({
      query: ({ roomId, userId, approve }: { roomId: string; userId: string; approve: boolean }) => ({
        url: `${LANGUAGE_ROOMS_URL}/${roomId}/requests/${userId}/${approve ? "approve" : "deny"}`,
        method: "POST",
      }),
      invalidatesTags: (_r: any, _e: any, a: { roomId: string }) => [
        { type: "LanguageRoomRequests", id: a.roomId },
        { type: "LanguageRooms", id: `${a.roomId}:members` },
        { type: "LanguageRooms", id: a.roomId },
      ],
    }),
    removeLanguageRoomMember: builder.mutation({
      query: ({ roomId, userId }: { roomId: string; userId: string }) => ({
        url: `${LANGUAGE_ROOMS_URL}/${roomId}/members/${userId}`,
        method: "DELETE",
      }),
      invalidatesTags: (_r: any, _e: any, a: { roomId: string }) => [
        { type: "LanguageRooms", id: `${a.roomId}:members` },
        { type: "LanguageRooms", id: a.roomId },
      ],
    }),
  }),
});

export function languageRoomErrorText(err: any, t: (k: string) => string): string {
  const data = (err && err.data) || {};
  const code = String(data.code || "");
  const raw = String(data.error || data.message || "");
  if (code === "BANNED_FROM_ROOM")
    return t("languageRooms.errors.banned") || "You were removed from this room. You can ask the owner to let you back in.";
  if (code === "REQUEST_ALREADY_PENDING") return t("languageRooms.errors.pending") || "Your request is waiting for the owner.";
  if (code === "TOO_MANY_PENDING_REQUESTS") return t("languageRooms.errors.busy") || "This room has too many requests right now. Try later.";
  if (code === "CANNOT_KICK_OWNER") return t("languageRooms.errors.owner") || "The owner can't be removed.";
  if (/up to \d+ topic rooms/i.test(raw)) return t("languageRooms.errors.tooMany") || "You already have 10 rooms. Delete one to start another.";
  if (/characters or fewer|1-\d+ characters/i.test(raw)) return t("languageRooms.errors.titleLength") || "The name can be up to 60 characters.";
  if (err && err.status === 404) return t("languageRooms.errors.gone") || "This room is no longer available.";
  return t("languageRooms.errors.generic") || "Something went wrong. Try again.";
}

export const {
  useGetLanguageRoomsQuery,
  useGetLanguageRoomQuery,
  useCreateTopicRoomMutation,
  useJoinLanguageRoomMutation,
  useLeaveLanguageRoomMutation,
  useRequestJoinLanguageRoomMutation,
  useGetLanguageRoomMessagesQuery,
  useLazyGetLanguageRoomMessagesQuery,
  useGetLanguageRoomMembersQuery,
  useGetLanguageRoomRequestsQuery,
  useDecideLanguageRoomRequestMutation,
  useRemoveLanguageRoomMemberMutation,
} = languageRoomsApiSlice as any;
