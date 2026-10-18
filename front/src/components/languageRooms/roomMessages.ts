export interface RoomSender {
  _id: string;
  name?: string;
  images?: string[];
}

export interface RoomReaction {
  emoji: string;
  user?: string | RoomSender;
}

export interface RoomMessage {
  _id: string;
  conversationId?: string;
  sender?: RoomSender | string;
  message?: string;
  messageType?: string;
  createdAt: string;
  /** Set on the server's daily "question of the day" system message. */
  promptId?: string;
  media?: { url?: string; type?: string } | null;
  replyTo?: {
    _id?: string;
    message?: string;
    sender?: { _id?: string; name?: string } | string;
    media?: { url?: string; type?: string } | null;
    messageType?: string;
    isDeleted?: boolean;
  } | null;
  reactions?: RoomReaction[];
  isDeleted?: boolean;
}

export const senderIdOf = (s: RoomMessage["sender"]): string =>
  s && typeof s === "object" ? String(s._id || "") : s ? String(s) : "";
export const senderNameOf = (s: RoomMessage["sender"]): string => (s && typeof s === "object" ? s.name || "" : "");

export function mergeMessages(existing: RoomMessage[], incoming: RoomMessage[]): RoomMessage[] {
  const byId: { [id: string]: RoomMessage } = {};
  existing.concat(incoming || []).forEach((m) => {
    if (m && m._id) byId[String(m._id)] = m;
  });
  return Object.keys(byId)
    .map((id) => byId[id])
    .filter((m) => !m.isDeleted)
    .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
}

/** `messageReaction` {messageId, reactions}: the list with that message's reactions replaced. */
export function applyReactionUpdate(messages: RoomMessage[], data: any): RoomMessage[] {
  if (!data || !data.messageId || !Array.isArray(data.reactions)) return messages;
  const id = String(data.messageId);
  if (!messages.some((m) => String(m._id) === id)) return messages;
  return messages.map((m) => (String(m._id) === id ? Object.assign({}, m, { reactions: data.reactions }) : m));
}

/** `room:messageDeleted`: the message disappears for everyone. */
export function removeMessage(messages: RoomMessage[], messageId: string): RoomMessage[] {
  return messages.filter((m) => String(m._id) !== String(messageId));
}

/** People the viewer blocked never show in the room (history already hides them; this covers live ones). */
export function withoutBlocked(messages: RoomMessage[], blockedIds: string[]): RoomMessage[] {
  if (!blockedIds || blockedIds.length === 0) return messages;
  const blocked = new Set(blockedIds.map(String));
  return messages.filter((m) => !blocked.has(senderIdOf(m.sender)));
}

/**
 * The newest daily prompt (a `system` message with a promptId) is pinned as
 * "Question of the day"; it is taken out of the thread. Other system
 * messages (joins) stay inline.
 */
export function splitDailyPrompt(messages: RoomMessage[]): { prompt: RoomMessage | null; thread: RoomMessage[] } {
  let prompt: RoomMessage | null = null;
  messages.forEach((m) => {
    if (m.messageType === "system" && m.promptId) prompt = m;
  });
  if (!prompt) return { prompt: null, thread: messages };
  const promptId = (prompt as RoomMessage)._id;
  return { prompt, thread: messages.filter((m) => m._id !== promptId) };
}

/** Moderators may delete any message; everyone else only their own. */
export function canDeleteMessage(m: RoomMessage, myId: string, isModerator: boolean): boolean {
  if (m.messageType === "system") return false;
  return isModerator || (!!myId && senderIdOf(m.sender) === myId);
}

export const isPhoto = (m: { media?: { url?: string; type?: string } | null; messageType?: string } | null | undefined): boolean =>
  !!(m && m.media && m.media.url && (m.media.type === "image" || m.messageType === "media"));

/** Text for a message; kinds the web does not draw get an honest label. */
export function messageLabel(m: RoomMessage, t: (k: string) => string): string {
  const type = m.messageType || "text";
  if ((type === "text" || type === "system") && m.message) return m.message;
  if (m.message && type !== "voice" && type !== "media") return m.message;
  if (type === "media" && isPhoto(m)) return m.message || "";
  if (type === "voice") return t("languageRooms.room.voice") || "Voice message — open the app to listen";
  if (type === "media") return t("languageRooms.room.media") || "Photo or video — open the app to see it";
  if (type === "sticker" || type === "gif") return t("languageRooms.room.sticker") || "Sticker";
  return t("languageRooms.room.unsupported") || "Open the app to see this message";
}

/** One-line preview of a quoted message. */
export function replyPreview(r: RoomMessage["replyTo"], t: (k: string) => string): string {
  if (!r) return "";
  if (r.isDeleted) return t("languageRooms.room.replyDeleted") || "Message removed";
  if (r.message) return r.message;
  if (r.media && r.media.url) return t("languageRooms.room.photo") || "Photo";
  return "";
}
