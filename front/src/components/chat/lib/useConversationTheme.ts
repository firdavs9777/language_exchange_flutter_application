import { useMemo } from "react";
import {
  useGetConversationsQuery,
  useGetConversationThemeQuery,
} from "../../../store/slices/chatSlice";
import { findConversationWith, CONVERSATIONS_PAGE } from "./conversationMatch";
import { DEFAULT_WALLPAPER } from "../../../design/chatWallpapers";

export interface ConversationTheme {
  /** The conversation id, or "" until the two have a conversation document. */
  conversationId: string;
  /** The saved preset name; "default" when there is none (or none known). */
  preset: string;
}

/**
 * The wallpaper of the conversation with `userId`, for the pane to wear.
 *
 * Two hops, both off caches the chat already holds: `/chat/:userId` is keyed
 * by the other person, so the conversation id comes from `GET /conversations`
 * (the same argument and therefore the same cache entry the list and the info
 * panel use), and the theme itself comes from `GET /conversations/:id/theme`.
 *
 * The theme is keyed by the CONVERSATION id rather than the user id — the
 * controller would accept either — because the `themeChanged` socket payload
 * names the conversation, and a push that cannot find its cache entry is a
 * wallpaper that only changes after a reload.
 */
export function useConversationTheme(userId?: string): ConversationTheme {
  const { data: conversationsData } = useGetConversationsQuery(CONVERSATIONS_PAGE, {
    skip: !userId,
  });

  const conversationId: string = useMemo(() => {
    const conversation = findConversationWith(
      conversationsData && conversationsData.data,
      userId || ""
    );
    return (conversation && conversation._id) || "";
  }, [conversationsData, userId]);

  const { data: themeData } = useGetConversationThemeQuery(conversationId, {
    skip: !conversationId,
  });

  const preset: string =
    (themeData && themeData.data && themeData.data.preset) || DEFAULT_WALLPAPER;

  return { conversationId: conversationId, preset: preset };
}

export default useConversationTheme;
