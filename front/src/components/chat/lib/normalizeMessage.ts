/**
 * Socket payloads do not always carry a populated sender. The wave mirror and
 * story_share emits sent the bare id (backend P1-CHAT-5 populates them; rows
 * and clients from before it remain). Every reader here does
 * `msg.sender._id`, so a bare id put my own message on the wrong side.
 */
export function idOf(party: any): string {
  if (!party) return "";
  if (typeof party === "string") return party;
  return party._id !== undefined && party._id !== null ? String(party._id) : "";
}

export function senderIdOf(message: { sender?: any } | null | undefined): string {
  return message ? idOf(message.sender) : "";
}

/** Same object when nothing needed fixing, so memoized bubbles keep their identity. */
export function normalizeMessage<T extends { sender?: any }>(message: T): T {
  if (!message) return message;
  const sender: any = message.sender;
  if (sender && typeof sender === "object") return message;
  return Object.assign({}, message, { sender: { _id: idOf(sender), name: "" } });
}
