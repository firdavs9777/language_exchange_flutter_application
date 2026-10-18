import { useGetBlockStatusQuery } from "../../../store/slices/usersSlice";

export interface ChatBlockState {
  /** Either side blocked the other: nothing can be sent. */
  blocked: boolean;
  iBlocked: boolean;
  blockedMe: boolean;
}

/**
 * Whether this chat is blocked, the app's check on open
 * (chat_conversation_screen.dart _checkBlockStatus). Same argument as
 * ChatInfoPanel, so the two share one cache entry, and block/unblock
 * invalidate it ("User"). Loading or failing counts as open: the server
 * still refuses a blocked send, and P3-CHAT-4 shows that refusal.
 */
export function useChatBlockState(viewerId?: string, partnerId?: string): ChatBlockState {
  const skip = !viewerId || !partnerId || viewerId === partnerId;
  const { data } = useGetBlockStatusQuery({ userId: viewerId, targetUserId: partnerId }, { skip: skip });
  const status: any = (!skip && data && data.data) || {};
  const iBlocked = status.isBlocked === true;
  const blockedMe = status.isBlockedBy === true;
  return { blocked: iBlocked || blockedMe, iBlocked: iBlocked, blockedMe: blockedMe };
}

export default useChatBlockState;
