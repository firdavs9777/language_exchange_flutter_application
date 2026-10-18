import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Eye, X } from "lucide-react";
import DialogShell from "../../design/DialogShell";
import Avatar from "../../design/Avatar";
import {
  useGetStoryReactionsQuery,
  useGetStoryViewersQuery,
} from "../../store/slices/storiesSlice";
import { StoryReaction, StoryView } from "./types";
import timeAgo from "../../utils/timeAgo";
import { userAvatarUrl } from "../../utils/photoUrl";

export interface StoryViewersSheetProps {
  storyId: string;
  onClose: () => void;
}

const TITLE_ID = "story-viewers-title";

const PANEL = [
  "relative flex w-full max-w-md flex-col rounded-2xl border border-line bg-surface shadow-lg",
  "max-h-[70vh] dark:border-line-dark dark:bg-cardbg-dark",
].join(" ");

/**
 * Who watched an own story, and which of them reacted.
 *
 * Owner-only on the server too: `GET /stories/:id/views` 403s for anyone else,
 * so the viewer only mounts this for the story's author and a 403 still lands
 * on the error state rather than an empty list pretending nobody watched.
 *
 * Reactions come from a second request and are merged onto the viewer rows by
 * user id, the way the app's `story_viewers_sheet.dart` does it. They are an
 * enrichment, so only the viewers request drives the loading and error states:
 * a failure there must not blank a sheet that already has its list.
 */
const StoryViewersSheet: React.FC<StoryViewersSheetProps> = ({
  storyId,
  onClose,
}) => {
  const { t } = useTranslation();
  const { data, isLoading, error } = useGetStoryViewersQuery(storyId, {
    skip: !storyId,
  });

  const { data: reactionsData } = useGetStoryReactionsQuery(storyId, {
    skip: !storyId,
  });

  const payload = (data as any)?.data || {};
  const views: StoryView[] = Array.isArray(payload.views) ? payload.views : [];
  // A view whose user was deleted comes back with a null `user`; it still
  // counts toward viewCount but there is nothing to link to.
  const rows = React.useMemo(
    () =>
      views
        .filter((view) => view && view.user && view.user._id)
        // The server returns views in the order they were recorded, oldest
        // first. Everyone reads this list newest first.
        .slice()
        .sort(
          (a, b) =>
            new Date(b.viewedAt).getTime() - new Date(a.viewedAt).getTime()
        ),
    [views]
  );
  const viewCount =
    typeof payload.viewCount === "number" ? payload.viewCount : rows.length;

  const reactions: StoryReaction[] = Array.isArray(
    (reactionsData as any)?.data?.reactions
  )
    ? (reactionsData as any).data.reactions
    : [];
  // One reaction per user — the server removes by user, not by emoji — so a
  // plain map is enough, and a reaction whose user was deleted is dropped
  // rather than keyed under an empty id that would match nothing.
  const emojiByUserId = new Map<string, string>();
  reactions.forEach((reaction) => {
    const reactor: any = reaction && reaction.user;
    const reactorId = typeof reactor === "string" ? reactor : reactor && reactor._id;
    if (reactorId && reaction.emoji) {
      emojiByUserId.set(String(reactorId), reaction.emoji);
    }
  });

  return (
    <DialogShell
      labelledBy={TITLE_ID}
      onClose={onClose}
      testId="story-viewers-sheet"
      backdropTestId="story-viewers-backdrop"
      panelClassName={PANEL}
    >
      <div className="flex items-center gap-2 border-b border-line px-4 py-3 dark:border-line-dark">
        <Eye size={18} className="text-gray-500" aria-hidden />
        <h2 id={TITLE_ID} className="text-base font-semibold">
          {t("stories.viewers") || "Viewers"}
        </h2>
        <span
          data-testid="story-viewers-count"
          className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 dark:bg-white/10 dark:text-gray-300"
        >
          {viewCount}
        </span>
        <button
          type="button"
          data-testid="story-viewers-close"
          onClick={onClose}
          aria-label={t("stories.close") || "Close"}
          className="ml-auto rounded-full p-1.5 text-gray-500 hover:bg-gray-100 dark:hover:bg-white/10"
        >
          <X size={18} />
        </button>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-2 py-2">
        {isLoading && (
          <p
            data-testid="story-viewers-loading"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.loading") || "Loading…"}
          </p>
        )}

        {!isLoading && error && (
          <p
            data-testid="story-viewers-error"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.error_loading") || "Error loading story"}
          </p>
        )}

        {!isLoading && !error && rows.length === 0 && (
          <p
            data-testid="story-viewers-empty"
            className="px-2 py-6 text-center text-sm text-gray-500"
          >
            {t("stories.no_viewers") || "No views yet"}
          </p>
        )}

        {!isLoading &&
          !error &&
          rows.map((view, index) => {
            const user = view.user;
            const image = userAvatarUrl(user);
            const emoji = emojiByUserId.get(user._id);
            return (
              <Link
                key={`${user._id}-${index}`}
                to={`/community/${user._id}`}
                data-testid="story-viewer-row"
                onClick={onClose}
                className="flex items-center gap-3 rounded-xl px-2 py-2 hover:bg-gray-50 dark:hover:bg-white/5"
              >
                <Avatar src={image} name={user.name} size={40} />
                <span className="min-w-0 flex-1 truncate text-sm font-medium">
                  {user.name}
                </span>
                {emoji && (
                  <span
                    data-testid="story-viewer-reaction"
                    role="img"
                    aria-label={t("stories.reacted") || "Reacted"}
                    className="shrink-0 text-base leading-none"
                  >
                    {emoji}
                  </span>
                )}
                <span className="shrink-0 text-xs text-gray-500">
                  {timeAgo(view.viewedAt, t, { withAgo: true })}
                </span>
              </Link>
            );
          })}
      </div>
    </DialogShell>
  );
};

export default StoryViewersSheet;
