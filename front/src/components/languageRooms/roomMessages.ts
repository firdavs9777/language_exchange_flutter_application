export interface RoomMessage {
  _id: string;
  conversationId?: string;
  sender?: { _id: string; name?: string; images?: string[] } | string;
  message?: string;
  messageType?: string;
  createdAt: string;
}

export function mergeMessages(existing: RoomMessage[], incoming: RoomMessage[]): RoomMessage[] {
  const byId: { [id: string]: RoomMessage } = {};
  existing.concat(incoming || []).forEach((m) => {
    if (m && m._id) byId[String(m._id)] = m;
  });
  return Object.keys(byId)
    .map((id) => byId[id])
    .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
}

/** Text for a message; kinds the web does not draw get an honest label. */
export function messageLabel(m: RoomMessage, t: (k: string) => string): string {
  const type = m.messageType || "text";
  if ((type === "text" || type === "system") && m.message) return m.message;
  if (m.message && type !== "voice" && type !== "media") return m.message;
  if (type === "voice") return t("languageRooms.room.voice") || "Voice message — open the app to listen";
  if (type === "media") return t("languageRooms.room.media") || "Photo or video — open the app to see it";
  if (type === "sticker" || type === "gif") return t("languageRooms.room.sticker") || "Sticker";
  return t("languageRooms.room.unsupported") || "Open the app to see this message";
}
