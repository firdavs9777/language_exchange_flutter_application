import React, { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  Archive,
  Bookmark,
  Eye,
  Film,
  Heart,
  Image as ImageIcon,
  Plus,
  Trash2,
  Type,
} from "lucide-react";
import SurfaceCard from "../../design/SurfaceCard";
import DialogShell from "../../design/DialogShell";
import ConfirmDialog from "../../design/ConfirmDialog";
import notify from "../../design/notify";
import {
  useGetMyStoriesQuery,
  useGetArchivedStoriesQuery,
  useGetHighlightsQuery,
  useDeleteIndividualStoryMutation,
  useArchiveStoryMutation,
  useAddStoryToHighlightMutation,
  useCreateHighlightMutation,
} from "../../store/slices/storiesSlice";
import StoryViewersSheet from "./StoryViewersSheet";
import { Story } from "./types";
import { coverOf, countOf, mediaOf } from "./highlightStories";
import { storyBackgroundStyle, storyTextColor } from "./storyBackground";
import timeAgo from "../../utils/timeAgo";

interface RootState {
  auth: {
    userInfo?: {
      user?: { _id: string };
      data?: { _id: string };
    };
  };
}

const PAGE = "min-h-screen bg-canvas px-4 py-6 dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full max-w-4xl space-y-4";
const PRIMARY = [
  "rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white",
  "transition hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50",
].join(" ");
const GHOST = [
  "rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700",
  "transition hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
].join(" ");
const FIELD = [
  "mt-1 w-full rounded-card border border-line bg-surface px-3 py-2 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");
const ACTION = [
  "inline-flex items-center gap-1.5 rounded-chip px-2 py-1 text-xs font-semibold",
  "text-ink-600 transition hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800",
].join(" ");

/**
 * The owner's own stories: what they posted, how many people watched, and the
 * three things they can still do about it — put a story in a highlight (so it
 * outlives the 24h expiry), archive it, or delete it.
 *
 * The view count is a button, not a number: `GET /stories/:id/views` is
 * owner-only and returns the actual list, so the count is the door to it.
 */
const MyStories: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );

  const [showArchived, setShowArchived] = useState(false);
  const [viewersFor, setViewersFor] = useState<string | null>(null);
  const [pickerFor, setPickerFor] = useState<string | null>(null);
  const [newHighlight, setNewHighlight] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const { data: myStoriesData, isLoading: isLoadingActive } = useGetMyStoriesQuery(
    {},
    { skip: !userId }
  );
  const { data: archivedData, isLoading: isLoadingArchived } = useGetArchivedStoriesQuery(
    { page: 1, limit: 50 },
    { skip: !userId || !showArchived }
  );
  // Only fetched once a story is actually being filed somewhere.
  const { data: highlightsData } = useGetHighlightsQuery({}, { skip: !pickerFor });

  const [deleteStory, { isLoading: isDeleting }] = useDeleteIndividualStoryMutation();
  const [archiveStory] = useArchiveStoryMutation();
  const [addStoryToHighlight, { isLoading: isAdding }] = useAddStoryToHighlightMutation();
  const [createHighlight, { isLoading: isCreating }] = useCreateHighlightMutation();

  const listOf = (payload: any): any[] => {
    if (!payload) return [];
    if (Array.isArray(payload)) return payload;
    return Array.isArray(payload.data) ? payload.data : [];
  };

  const activeStories = useMemo(() => listOf(myStoriesData), [myStoriesData]);
  const archivedStories = useMemo(() => listOf(archivedData), [archivedData]);
  const highlights = listOf(highlightsData);

  const stories: Story[] = showArchived ? archivedStories : activeStories;
  const isLoading = showArchived ? isLoadingArchived : isLoadingActive;
  const totalViews = activeStories.reduce(
    (sum: number, story: any) => sum + (story.viewCount || 0),
    0
  );

  const closePicker = () => {
    setPickerFor(null);
    setNewHighlight(false);
    setNewTitle("");
  };

  const handleView = (storyId: string) => {
    if (!userId) return;
    const at = activeStories.findIndex((story: any) => story._id === storyId);
    navigate(`/stories/${userId}`, { state: { startIndex: at >= 0 ? at : 0 } });
  };

  const handleAddToHighlight = async (highlightId: string) => {
    if (!pickerFor) return;
    try {
      await addStoryToHighlight({ highlightId, storyId: pickerFor }).unwrap();
      notify.success(t("stories.added_to_highlight") || "Added to highlight");
      closePicker();
    } catch (error) {
      notify.error(t("stories.add_failed") || "Couldn't add that story");
    }
  };

  const handleCreateHighlight = async () => {
    if (!pickerFor) return;
    const title = newTitle.trim();
    if (!title) {
      notify.error(t("stories.title_required") || "Please enter a title");
      return;
    }
    try {
      // `POST /stories/highlights {title, storyId}` creates the highlight
      // *from* the story, so no second add call is needed.
      await createHighlight({ title, storyId: pickerFor }).unwrap();
      notify.success(t("stories.highlight_created") || "Highlight created");
      closePicker();
    } catch (error) {
      notify.error(t("stories.create_failed") || "Couldn't create the highlight");
    }
  };

  const handleArchive = async (storyId: string) => {
    try {
      await archiveStory(storyId).unwrap();
      notify.success(t("stories.story_archived") || "Story archived");
    } catch (error) {
      notify.error(t("stories.archive_failed") || "Couldn't archive that story");
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    try {
      await deleteStory(deleteId).unwrap();
      notify.success(t("stories.story_deleted") || "Story deleted");
      if (viewersFor === deleteId) setViewersFor(null);
      setDeleteId(null);
    } catch (error) {
      notify.error(t("stories.delete_story_failed") || "Couldn't delete that story");
    }
  };

  const typeIcon = (story: any) => {
    if (story.mediaType === "video") return <Film className="h-3.5 w-3.5" aria-hidden />;
    if (story.mediaType === "text") return <Type className="h-3.5 w-3.5" aria-hidden />;
    return <ImageIcon className="h-3.5 w-3.5" aria-hidden />;
  };

  return (
    <div className={PAGE}>
      <div className={COLUMN}>
        <SurfaceCard padding="lg">
          <div className="flex flex-wrap items-center gap-3">
            {/* `min-w-[8rem]`, not `min-w-0`: the row already wraps, but with
                no floor the title column shrank to nothing at 320px and the
                <h1> came out 8px wide instead of pushing the buttons onto a
                second line. */}
            <div className="min-w-[8rem] flex-1">
              <h1 className="font-display text-lg text-ink-900 dark:text-ink-50">
                {t("stories.my_stories") || "My stories"}
              </h1>
              {/* Two counters, each its own label: a sentence stitched out of
                  translated fragments is a sentence no translator can order. */}
              <p className="flex flex-wrap gap-x-3 text-xs text-ink-500 dark:text-ink-400">
                <span>
                  <span data-testid="my-stories-active-count" className="font-semibold">
                    {activeStories.length}
                  </span>{" "}
                  {t("stories.active_stories") || "Active"}
                </span>
                <span>
                  <span data-testid="my-stories-total-views" className="font-semibold">
                    {totalViews}
                  </span>{" "}
                  {t("stories.total_views") || "Total views"}
                </span>
              </p>
            </div>
            <button
              type="button"
              data-testid="my-stories-toggle-archived"
              onClick={() => setShowArchived(!showArchived)}
              aria-pressed={showArchived}
              className={GHOST}
            >
              <span className="inline-flex items-center gap-1.5">
                <Archive className="h-4 w-4" aria-hidden />
                {showArchived
                  ? t("stories.active_stories") || "Active"
                  : t("stories.archived_stories") || "Archived"}
              </span>
            </button>
            <button
              type="button"
              data-testid="my-stories-create"
              onClick={() => navigate("/create-story")}
              className={PRIMARY}
            >
              <span className="inline-flex items-center gap-1.5">
                <Plus className="h-4 w-4" aria-hidden />
                {t("stories.create_first_story") || "Create story"}
              </span>
            </button>
          </div>
        </SurfaceCard>

        <SurfaceCard padding="lg">
          {isLoading && stories.length === 0 ? (
            <div data-testid="my-stories-loading" className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {[0, 1, 2, 3].map((key) => (
                <div
                  key={key}
                  className="aspect-[9/16] animate-pulse rounded-chip bg-ink-100 dark:bg-ink-800"
                />
              ))}
            </div>
          ) : stories.length === 0 ? (
            <div data-testid="my-stories-empty" className="py-10 text-center">
              <ImageIcon
                className="mx-auto mb-3 h-8 w-8 text-ink-400 dark:text-ink-500"
                aria-hidden
              />
              <p className="text-sm text-ink-500 dark:text-ink-400">
                {showArchived
                  ? t("stories.no_archived_stories") || "Nothing archived yet"
                  : t("stories.no_stories") || "No stories yet"}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
              {stories.map((story: any) => {
                const media = mediaOf(story);
                return (
                  <div key={story._id} data-testid="my-story-card" className="flex flex-col gap-2">
                    <button
                      type="button"
                      data-testid="my-story-open"
                      onClick={() => handleView(story._id)}
                      className="relative block aspect-[9/16] overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
                    >
                      {media ? (
                        <img
                          src={media}
                          alt=""
                          loading="lazy"
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <span
                          // Data-driven: the author's own story colours.
                          style={{
                            ...storyBackgroundStyle(story.backgroundColor),
                            color: storyTextColor(story.textColor),
                          }}
                          className="flex h-full w-full items-center justify-center overflow-hidden bg-ink-800 p-3 text-center text-xs font-semibold leading-snug text-white"
                        >
                          {story.text || ""}
                        </span>
                      )}
                      <span className="absolute left-1.5 top-1.5 rounded-full bg-ink-950/55 p-1 text-white">
                        {typeIcon(story)}
                      </span>
                      <span className="absolute inset-x-0 bottom-0 flex items-center gap-3 bg-ink-950/55 px-2 py-1 text-[11px] font-semibold text-white">
                        {story.reactionCount > 0 && (
                          <span className="inline-flex items-center gap-1">
                            <Heart className="h-3 w-3" aria-hidden />
                            {story.reactionCount}
                          </span>
                        )}
                        <span className="ml-auto">{timeAgo(story.createdAt, t, { withAgo: true })}</span>
                      </span>
                    </button>

                    <div className="flex flex-wrap items-center gap-1">
                      <button
                        type="button"
                        data-testid="my-story-views"
                        onClick={() => setViewersFor(story._id)}
                        className={ACTION}
                      >
                        <Eye className="h-3.5 w-3.5" aria-hidden />
                        {story.viewCount || 0}
                      </button>
                      <button
                        type="button"
                        data-testid="my-story-highlight"
                        onClick={() => setPickerFor(story._id)}
                        aria-label={t("stories.add_to_highlight") || "Add to highlight"}
                        className={ACTION}
                      >
                        <Bookmark className="h-3.5 w-3.5" aria-hidden />
                      </button>
                      {!showArchived && (
                        <button
                          type="button"
                          data-testid="my-story-archive"
                          onClick={() => handleArchive(story._id)}
                          aria-label={t("stories.archive") || "Archive"}
                          className={ACTION}
                        >
                          <Archive className="h-3.5 w-3.5" aria-hidden />
                        </button>
                      )}
                      <button
                        type="button"
                        data-testid="my-story-delete"
                        onClick={() => setDeleteId(story._id)}
                        aria-label={t("stories.delete") || "Delete"}
                        className={`${ACTION} text-red-600 dark:text-red-400`}
                      >
                        <Trash2 className="h-3.5 w-3.5" aria-hidden />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </SurfaceCard>
      </div>

      {viewersFor && (
        <StoryViewersSheet storyId={viewersFor} onClose={() => setViewersFor(null)} />
      )}

      {pickerFor && (
        <DialogShell
          labelledBy="highlight-picker-title-label"
          onClose={closePicker}
          testId="highlight-picker"
          backdropTestId="highlight-picker-backdrop"
          dismissible={!isAdding && !isCreating}
        >
          <h2
            id="highlight-picker-title-label"
            className="font-display text-base text-ink-900 dark:text-ink-50"
          >
            {t("stories.add_to_highlight") || "Add to highlight"}
          </h2>

          {newHighlight ? (
            <>
              <label className="mt-4 block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
                {t("stories.highlight_name") || "Highlight name"}
                <input
                  data-testid="highlight-picker-title"
                  type="text"
                  value={newTitle}
                  maxLength={50}
                  onChange={(e) => setNewTitle(e.target.value)}
                  className={FIELD}
                />
              </label>
              <div className="mt-5 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setNewHighlight(false)}
                  disabled={isCreating}
                  className={GHOST}
                >
                  {t("stories.cancel") || "Cancel"}
                </button>
                <button
                  type="button"
                  data-testid="highlight-picker-create"
                  onClick={handleCreateHighlight}
                  disabled={isCreating}
                  className={PRIMARY}
                >
                  {t("stories.create") || "Create"}
                </button>
              </div>
            </>
          ) : (
            <>
              <div className="mt-3 max-h-64 space-y-1 overflow-y-auto">
                {highlights.length === 0 && (
                  <p
                    data-testid="highlight-picker-empty"
                    className="py-4 text-center text-sm text-ink-500 dark:text-ink-400"
                  >
                    {t("stories.no_highlights") || "No highlights yet"}
                  </p>
                )}
                {highlights.map((highlight: any) => {
                  const cover = coverOf(highlight);
                  return (
                    <button
                      key={highlight._id}
                      type="button"
                      data-testid="highlight-picker-option"
                      onClick={() => handleAddToHighlight(highlight._id)}
                      disabled={isAdding}
                      className="flex w-full items-center gap-3 rounded-chip px-2 py-2 text-left transition hover:bg-ink-100 disabled:opacity-50 dark:hover:bg-ink-800"
                    >
                      {cover ? (
                        <img
                          src={cover}
                          alt=""
                          className="h-10 w-10 shrink-0 rounded-full object-cover"
                        />
                      ) : (
                        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-ink-100 text-ink-500 dark:bg-ink-800 dark:text-ink-400">
                          <Bookmark className="h-4 w-4" aria-hidden />
                        </span>
                      )}
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-semibold text-ink-900 dark:text-ink-50">
                          {highlight.title}
                        </span>
                        <span className="block text-xs text-ink-500 dark:text-ink-400">
                          {`${countOf(highlight)} ${t("stories.stories_count") || "stories"}`}
                        </span>
                      </span>
                    </button>
                  );
                })}
              </div>

              <div className="mt-5 flex justify-between gap-2">
                <button
                  type="button"
                  data-testid="highlight-picker-new"
                  onClick={() => setNewHighlight(true)}
                  className={GHOST}
                >
                  <span className="inline-flex items-center gap-1.5">
                    <Plus className="h-4 w-4" aria-hidden />
                    {t("stories.new_highlight") || "New highlight"}
                  </span>
                </button>
                <button type="button" onClick={closePicker} className={GHOST}>
                  {t("stories.cancel") || "Cancel"}
                </button>
              </div>
            </>
          )}
        </DialogShell>
      )}

      <ConfirmDialog
        open={Boolean(deleteId)}
        title={t("stories.delete_story_confirm") || "Delete this story?"}
        body={t("stories.delete_story_body") || "This cannot be undone."}
        confirmLabel={t("stories.delete") || "Delete"}
        cancelLabel={t("stories.cancel") || "Cancel"}
        danger
        busy={isDeleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
};

export default MyStories;
