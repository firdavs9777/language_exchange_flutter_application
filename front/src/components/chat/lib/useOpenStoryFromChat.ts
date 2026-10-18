import { useCallback } from "react";
import { useNavigate } from "react-router-dom";

/** The author of a GET /stories/:id answer, populated or not. */
export function storyOwnerId(response: any): string {
  const story = response && (response.data || response);
  const user = story && story.user;
  if (!user) return "";
  return typeof user === "string" ? user : user._id ? String(user._id) : "";
}

/**
 * Open the story a chat message points at. /story/:id (StoryLinkPage) reads
 * the story, sends a live one to its author's viewer at the right index, and
 * shows the expired / hidden / signed-out states itself.
 */
export function useOpenStoryFromChat(): (storyId: string) => void {
  const navigate = useNavigate();
  return useCallback(
    (storyId: string) => {
      if (!storyId) return;
      navigate(`/story/${encodeURIComponent(storyId)}`);
    },
    [navigate]
  );
}

export default useOpenStoryFromChat;
