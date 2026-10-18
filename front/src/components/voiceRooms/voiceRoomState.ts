import { LkPeer } from "../../lib/livekit/lkSession";

export interface VoiceRoomMember {
  userId: string;
  name: string;
  images?: string[];
  role: string;
  isMuted: boolean;
  isSpeaking: boolean;
  handRaised: boolean;
}

export interface VoiceRoomChatLine {
  id: string;
  userId: string;
  name: string;
  message: string;
  at: string;
}

export interface VoiceRoomState {
  members: { [userId: string]: VoiceRoomMember };
  order: string[];
  hostId: string;
  chat: VoiceRoomChatLine[];
  ended: boolean;
}

export const initialVoiceRoomState: VoiceRoomState = { members: {}, order: [], hostId: "", chat: [], ended: false };

export type VoiceRoomAction =
  | { type: "detail"; room: any }
  | { type: "joined"; payload: any }
  | { type: "left"; payload: any }
  | { type: "mute"; payload: any }
  | { type: "hand"; payload: any }
  | { type: "chat"; payload: any }
  | { type: "host"; hostId: string }
  | { type: "ended" }
  | { type: "reset" };

const idOf = (v: any): string => (v && typeof v === "object" ? String(v._id || "") : v ? String(v) : "");
const CHAT_LIMIT = 200;
let chatSeq = 0;

function upsert(state: VoiceRoomState, userId: string, patch: Partial<VoiceRoomMember>): VoiceRoomState {
  if (!userId) return state;
  const prev = state.members[userId];
  const next: VoiceRoomMember = Object.assign(
    { userId, name: "", role: "listener", isMuted: true, isSpeaking: false, handRaised: false },
    prev || {},
    patch
  );
  return Object.assign({}, state, {
    members: Object.assign({}, state.members, { [userId]: next }),
    order: prev ? state.order : state.order.concat([userId]),
  });
}

export function voiceRoomReducer(state: VoiceRoomState, action: VoiceRoomAction): VoiceRoomState {
  switch (action.type) {
    case "detail": {
      const room = action.room || {};
      let next: VoiceRoomState = Object.assign({}, state, { hostId: idOf(room.host) || state.hostId });
      (Array.isArray(room.participants) ? room.participants : []).forEach((p: any) => {
        const u = p && p.user;
        const userId = idOf(u);
        next = upsert(next, userId, {
          name: (u && typeof u === "object" && u.name) || (next.members[userId] && next.members[userId].name) || "",
          images: u && typeof u === "object" ? u.images : undefined,
          role: (p && p.role) || (userId === next.hostId ? "host" : "listener"),
          isMuted: p && typeof p.isMuted === "boolean" ? p.isMuted : true,
        });
      });
      // Host first, everyone else in join order.
      const order = next.order.slice().sort((a, b) => (a === next.hostId ? -1 : b === next.hostId ? 1 : 0));
      return Object.assign({}, next, { order });
    }
    case "joined": {
      const p = action.payload || {};
      const userId = idOf(p.user) || idOf(p.userId);
      return upsert(state, userId, {
        name: (p.user && p.user.name) || (state.members[userId] && state.members[userId].name) || "",
        images: p.user && p.user.images,
      });
    }
    case "left": {
      const p = action.payload || {};
      const userId = idOf(p.userId);
      const members = Object.assign({}, state.members);
      delete members[userId];
      return Object.assign({}, state, {
        members,
        order: state.order.filter((id) => id !== userId),
        ended: state.ended || p.roomEnded === true,
      });
    }
    case "mute": {
      const p = action.payload || {};
      return upsert(state, idOf(p.userId), { isMuted: !!p.isMuted });
    }
    case "hand": {
      const p = action.payload || {};
      const userId = idOf(p.userId);
      return upsert(state, userId, {
        handRaised: p.isRaised === true,
        name: (p.user && p.user.name) || (state.members[userId] && state.members[userId].name) || "",
      });
    }
    case "chat": {
      const p = action.payload || {};
      chatSeq += 1;
      const line: VoiceRoomChatLine = {
        id: `c${chatSeq}`,
        userId: idOf(p.user),
        name: (p.user && p.user.name) || "",
        message: String(p.message || ""),
        at: String(p.timestamp || new Date().toISOString()),
      };
      const chat = state.chat.concat([line]);
      return Object.assign({}, state, { chat: chat.length > CHAT_LIMIT ? chat.slice(chat.length - CHAT_LIMIT) : chat });
    }
    case "host": {
      const next = Object.assign({}, state, { hostId: action.hostId });
      return action.hostId && next.members[action.hostId] ? upsert(next, action.hostId, { role: "host" }) : next;
    }
    case "ended":
      return Object.assign({}, state, { ended: true });
    case "reset":
      return initialVoiceRoomState;
    default:
      return state;
  }
}

/** Members in display order, with LiveKit's view of speaking/mic applied. */
export function selectMembers(state: VoiceRoomState, peers: LkPeer[]): VoiceRoomMember[] {
  const byId: { [id: string]: LkPeer } = {};
  peers.forEach((p) => {
    byId[p.identity] = p;
  });
  return state.order
    .map((id) => state.members[id])
    .filter(Boolean)
    .map((m) => {
      const peer = byId[m.userId];
      return peer ? Object.assign({}, m, { isSpeaking: peer.isSpeaking, isMuted: !peer.micOn }) : m;
    });
}
