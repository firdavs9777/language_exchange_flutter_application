/**
 * Finding the conversation a person is on the other side of.
 *
 * `/chat/:userId` is keyed by the OTHER USER, and the thread endpoint
 * (`GET /messages/conversation/:senderId/:receiverId`) answers with messages
 * and no conversation document — so every per-conversation action (mute,
 * unmute, delete) has to resolve the id out of `GET /api/v1/conversations`
 * first. Two screens do that: the list rows and the chat info panel.
 *
 * It lived twice, and the two copies did not agree: one matched populated
 * participants only, the other populated-or-raw, and neither used
 * `otherParticipant` — the per-viewer field the backend already computes
 * (`controllers/conversations.js`). That field is the exact answer where
 * scanning `participants` is merely a good guess: a document with more than
 * two members can contain a person without being the conversation *with*
 * them.
 */

/**
 * The one argument every `getConversations` caller passes.
 *
 * RTK Query keys its cache on the serialized argument, so two screens asking
 * with different literals hold two cache entries and issue two identical
 * requests. `limit` is the backend's maximum (`controllers/conversations.js`
 * clamps to 100): there is no participant filter and no "conversation with
 * this person" endpoint, so a page-1 miss is indistinguishable from "these
 * two have never spoken".
 */
export const CONVERSATIONS_PAGE = { page: 1, limit: 100 };

export interface ConversationLike {
  _id?: string;
  otherParticipant?: any;
  participants?: any[];
  [key: string]: any;
}

/** The id of a participant entry, populated object or raw id alike. */
function idOf(participant: any): string {
  if (!participant) return "";
  if (typeof participant === "string") return participant;
  return participant._id || "";
}

/** Whether this conversation is the one with `userId` on the other side. */
export function isConversationWith(
  conversation: ConversationLike,
  userId: string
): boolean {
  if (!conversation || !userId) return false;
  if (conversation.otherParticipant) {
    return idOf(conversation.otherParticipant) === userId;
  }
  return (conversation.participants || []).some(
    (participant: any) => idOf(participant) === userId
  );
}

/** The conversation with `userId`, or null when this page does not hold it. */
export function findConversationWith(
  conversations: any,
  userId: string
): ConversationLike | null {
  if (!Array.isArray(conversations)) return null;
  return (
    conversations.find((conversation: ConversationLike) =>
      isConversationWith(conversation, userId)
    ) || null
  );
}
