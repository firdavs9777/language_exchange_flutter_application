import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  ArrowLeft,
  Bookmark,
  Check,
  Image as ImageIcon,
  Pencil,
  Plus,
  Trash2,
  X,
} from "lucide-react";
import SurfaceCard from "../../design/SurfaceCard";
import DialogShell from "../../design/DialogShell";
import ConfirmDialog from "../../design/ConfirmDialog";
import notify from "../../design/notify";
import {
  useGetHighlightsQuery,
  useGetMyStoriesQuery,
  useGetArchivedStoriesQuery,
  useCreateHighlightMutation,
  useUpdateHighlightMutation,
  useDeleteHighlightMutation,
  useRemoveStoryFromHighlightMutation,
} from "../../store/slices/storiesSlice";
import { Story } from "./types";
import { storiesOf, mediaOf, coverOf, countOf } from "./highlightStories";
import { storyBackgroundStyle, storyTextColor } from "./storyBackground";

const PAGE = "min-h-screen bg-canvas px-4 py-6 dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full max-w-3xl space-y-4";
const FIELD = [
  "mt-1 w-full rounded-card border border-line bg-surface px-3 py-2 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");
const PRIMARY = [
  "rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white",
  "transition hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50",
].join(" ");
const GHOST = [
  "rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700",
  "transition hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
].join(" ");
const ICON_BUTTON = [
  "rounded-full bg-surface/90 p-1.5 text-ink-600 shadow-card transition",
  "hover:bg-surface dark:bg-cardbg-dark/90 dark:text-ink-200",
].join(" ");

/** One story as a square tile: its media, or its text on its own colour. */
const StoryTile: React.FC<{ story: any; testId: string }> = ({ story, testId }) => {
  const media = mediaOf(story);
  if (media) {
    return (
      <img
        data-testid={testId}
        src={media}
        alt=""
        loading="lazy"
        className="h-full w-full object-cover"
      />
    );
  }
  return (
    <span
      data-testid={testId}
      // Data-driven: these are the colours the author chose for the story, so
      // they cannot be expressed as utility classes.
      style={{
        ...storyBackgroundStyle(story && story.backgroundColor),
        color: storyTextColor(story && story.textColor),
      }}
      className="flex h-full w-full items-center justify-center overflow-hidden bg-ink-800 p-2 text-center text-[11px] font-semibold leading-snug text-white"
    >
      {(story && story.text) || ""}
    </span>
  );
};

/**
 * The owner's highlights: create, rename, re-cover, delete, and open one to
 * take a story back out of it.
 *
 * Every mutation here is the backend's own contract (`routes/story.js`):
 * `POST /stories/highlights {title, storyId?}` -- the controller builds the
 * highlight *from* that story and lifts its first media into `coverImage`, so
 * "pick a first story" and "pick a cover" are one choice at creation time and
 * two afterwards (`PUT /stories/highlights/:id {title?, coverImage?}`, which
 * assigns only the truthy fields it is sent).
 */
const Highlights: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [openId, setOpenId] = useState<string | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newStoryId, setNewStoryId] = useState<string | null>(null);
  const [editId, setEditId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState("");
  const [editCover, setEditCover] = useState<string | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const { data, isLoading } = useGetHighlightsQuery({});
  // The story pickers are the only reason this page needs my stories at all,
  // so neither list is fetched until the create dialog asks for one.
  const { data: myStoriesData } = useGetMyStoriesQuery({}, { skip: !createOpen });
  const { data: archivedData } = useGetArchivedStoriesQuery(
    { page: 1, limit: 50 },
    { skip: !createOpen }
  );

  const [createHighlight, { isLoading: isCreating }] = useCreateHighlightMutation();
  const [updateHighlight, { isLoading: isUpdating }] = useUpdateHighlightMutation();
  const [deleteHighlight, { isLoading: isDeleting }] = useDeleteHighlightMutation();
  const [removeStoryFromHighlight] = useRemoveStoryFromHighlightMutation();

  const listOf = (payload: any): any[] =>
    Array.isArray(payload && payload.data) ? payload.data : [];

  const highlights: any[] = listOf(data);
  const sourceStories: Story[] = listOf(myStoriesData).concat(listOf(archivedData));

  const open = highlights.filter((item) => item && item._id === openId)[0];
  const editing = highlights.filter((item) => item && item._id === editId)[0];

  const closeCreate = () => {
    setCreateOpen(false);
    setNewTitle("");
    setNewStoryId(null);
  };

  const handleCreate = async () => {
    const title = newTitle.trim();
    if (!title) {
      notify.error(t("stories.title_required") || "Please enter a title");
      return;
    }
    // `storyId` travels only when one was picked: with it the server creates
    // the highlight from that story and derives the cover; without it the
    // highlight starts empty.
    const payload: any = newStoryId ? { title, storyId: newStoryId } : { title };
    try {
      await createHighlight(payload).unwrap();
      notify.success(t("stories.highlight_created") || "Highlight created");
      closeCreate();
    } catch (error) {
      notify.error(t("stories.create_failed") || "Couldn't create the highlight");
    }
  };

  const startEdit = (highlight: any) => {
    setEditId(highlight._id);
    setEditTitle(highlight.title || "");
    setEditCover(null);
  };

  const closeEdit = () => {
    setEditId(null);
    setEditTitle("");
    setEditCover(null);
  };

  const handleUpdate = async () => {
    if (!editing) return;
    const title = editTitle.trim();
    const payload: any = { highlightId: editing._id };
    if (title && title !== editing.title) payload.title = title;
    if (editCover && editCover !== editing.coverImage) payload.coverImage = editCover;
    // Nothing moved: no request, and the dialog still closes.
    if (payload.title === undefined && payload.coverImage === undefined) {
      closeEdit();
      return;
    }
    try {
      await updateHighlight(payload).unwrap();
      notify.success(t("stories.highlight_updated") || "Highlight updated");
      closeEdit();
    } catch (error) {
      notify.error(t("stories.update_failed") || "Couldn't save the highlight");
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    try {
      await deleteHighlight(deleteId).unwrap();
      notify.success(t("stories.highlight_deleted") || "Highlight deleted");
      if (openId === deleteId) setOpenId(null);
      setDeleteId(null);
    } catch (error) {
      notify.error(t("stories.delete_failed") || "Couldn't delete the highlight");
    }
  };

  const handleRemoveStory = async (highlightId: string, storyId: string) => {
    try {
      await removeStoryFromHighlight({ highlightId, storyId }).unwrap();
      notify.success(t("stories.removed_from_highlight") || "Removed from highlight");
    } catch (error) {
      notify.error(t("stories.remove_failed") || "Couldn't remove that story");
    }
  };

  const header = (
    // Wrapping, with a floor under the title. Without it the "New highlight"
    // button took the whole row on a phone and the <h1> was squeezed to zero
    // width -- the page had no visible title at 320-414px. `min-w-[8rem]`
    // below is the floor; it is what makes the row wrap instead of
    // collapsing the heading, and `truncate` still handles a long custom
    // highlight name.
    <div className="flex flex-wrap items-center gap-3">
      <button
        type="button"
        data-testid="highlights-back"
        onClick={() => (open ? setOpenId(null) : navigate(-1))}
        aria-label={t("stories.back") || "Back"}
        className="rounded-full p-1.5 text-ink-600 transition hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800"
      >
        <ArrowLeft className="h-5 w-5" />
      </button>
      <div className="min-w-[8rem] flex-1">
        <h1 className="truncate font-display text-lg text-ink-900 dark:text-ink-50">
          {open ? open.title : t("stories.highlights_title") || "Highlights"}
        </h1>
        <p className="truncate text-xs text-ink-500 dark:text-ink-400">
          {open
            ? `${countOf(open)} ${t("stories.stories_count") || "stories"}`
            : t("stories.highlights_subtitle") || "Your saved story collections"}
        </p>
      </div>
      {!open && (
        <button
          type="button"
          data-testid="highlight-create-open"
          onClick={() => setCreateOpen(true)}
          className={PRIMARY}
        >
          <span className="inline-flex items-center gap-1.5">
            <Plus className="h-4 w-4" aria-hidden />
            {t("stories.new_highlight") || "New highlight"}
          </span>
        </button>
      )}
    </div>
  );

  return (
    <div className={PAGE}>
      <div className={COLUMN}>
        <SurfaceCard padding="lg">{header}</SurfaceCard>

        {open ? (
          <SurfaceCard padding="lg">
            <section data-testid="highlight-detail">
              {storiesOf(open).length === 0 ? (
                <p
                  data-testid="highlight-detail-empty"
                  className="py-8 text-center text-sm text-ink-500 dark:text-ink-400"
                >
                  {t("stories.highlight_empty") || "This highlight has no stories yet"}
                </p>
              ) : (
                <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
                  {storiesOf(open).map((story: any) => (
                    <div
                      key={story._id}
                      className="relative aspect-[9/16] overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
                    >
                      <StoryTile story={story} testId="highlight-story-tile" />
                      <button
                        type="button"
                        data-testid="highlight-story-remove"
                        onClick={() => handleRemoveStory(open._id, story._id)}
                        aria-label={
                          t("stories.remove_from_highlight") || "Remove from highlight"
                        }
                        className={`absolute right-1.5 top-1.5 ${ICON_BUTTON}`}
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </section>
          </SurfaceCard>
        ) : (
          <SurfaceCard padding="lg">
            {isLoading && highlights.length === 0 ? (
              <div data-testid="highlights-loading" className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                {[0, 1, 2].map((key) => (
                  <div
                    key={key}
                    className="aspect-square animate-pulse rounded-chip bg-ink-100 dark:bg-ink-800"
                  />
                ))}
              </div>
            ) : highlights.length === 0 ? (
              <div data-testid="highlights-empty" className="py-10 text-center">
                <Bookmark
                  className="mx-auto mb-3 h-8 w-8 text-ink-400 dark:text-ink-500"
                  aria-hidden
                />
                <p className="text-sm text-ink-500 dark:text-ink-400">
                  {t("stories.no_highlights") || "No highlights yet"}
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                {highlights.map((highlight: any) => {
                  const cover = coverOf(highlight);
                  return (
                    <div
                      key={highlight._id}
                      data-testid="highlight-card"
                      className="relative overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
                    >
                      <button
                        type="button"
                        data-testid="highlight-open"
                        onClick={() => setOpenId(highlight._id)}
                        className="block aspect-square w-full"
                      >
                        {cover ? (
                          <img
                            data-testid="highlight-card-cover"
                            src={cover}
                            alt={highlight.title || ""}
                            loading="lazy"
                            className="h-full w-full object-cover"
                          />
                        ) : (
                          <span className="flex h-full w-full items-center justify-center text-ink-400 dark:text-ink-500">
                            <ImageIcon className="h-8 w-8" aria-hidden />
                          </span>
                        )}
                        <span className="absolute inset-x-0 bottom-0 block bg-ink-950/55 px-2 py-1.5 text-left">
                          <span className="block truncate text-sm font-semibold text-white">
                            {highlight.title}
                          </span>
                          <span className="block text-[11px] text-white/75">
                            {`${countOf(highlight)} ${t("stories.stories_count") || "stories"}`}
                          </span>
                        </span>
                      </button>

                      <div className="absolute right-1.5 top-1.5 flex gap-1">
                        <button
                          type="button"
                          data-testid="highlight-edit-open"
                          onClick={() => startEdit(highlight)}
                          aria-label={t("stories.edit_highlight") || "Edit highlight"}
                          className={ICON_BUTTON}
                        >
                          <Pencil className="h-4 w-4" />
                        </button>
                        <button
                          type="button"
                          data-testid="highlight-delete-open"
                          onClick={() => setDeleteId(highlight._id)}
                          aria-label={t("stories.delete_highlight") || "Delete highlight"}
                          className={`${ICON_BUTTON} text-red-600 dark:text-red-400`}
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </SurfaceCard>
        )}
      </div>

      {createOpen && (
        <DialogShell
          labelledBy="highlight-create-title"
          onClose={closeCreate}
          testId="highlight-create-dialog"
          backdropTestId="highlight-create-backdrop"
          dismissible={!isCreating}
        >
          <h2
            id="highlight-create-title"
            className="font-display text-base text-ink-900 dark:text-ink-50"
          >
            {t("stories.new_highlight") || "New highlight"}
          </h2>

          <label className="mt-4 block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
            {t("stories.highlight_name") || "Highlight name"}
            <input
              data-testid="highlight-title-input"
              type="text"
              value={newTitle}
              maxLength={50}
              onChange={(e) => setNewTitle(e.target.value)}
              className={FIELD}
            />
          </label>

          <p className="mt-4 text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
            {t("stories.choose_cover") || "Choose a cover"}
          </p>
          {sourceStories.length === 0 ? (
            <p
              data-testid="highlight-no-sources"
              className="py-4 text-center text-sm text-ink-500 dark:text-ink-400"
            >
              {t("stories.no_stories_to_pick") || "No stories to choose from"}
            </p>
          ) : (
            <div className="mt-2 grid max-h-52 grid-cols-4 gap-2 overflow-y-auto">
              {sourceStories.map((story: any) => (
                <button
                  key={story._id}
                  type="button"
                  data-testid="highlight-source-story"
                  aria-pressed={newStoryId === story._id}
                  onClick={() =>
                    setNewStoryId(newStoryId === story._id ? null : story._id)
                  }
                  className={`relative aspect-[9/16] overflow-hidden rounded-chip ${
                    newStoryId === story._id
                      ? "ring-2 ring-brand-deep"
                      : "ring-1 ring-line dark:ring-line-dark"
                  }`}
                >
                  <StoryTile story={story} testId="highlight-source-thumb" />
                  {newStoryId === story._id && (
                    <span className="absolute right-1 top-1 rounded-full bg-brand-deep p-0.5 text-white">
                      <Check className="h-3 w-3" aria-hidden />
                    </span>
                  )}
                </button>
              ))}
            </div>
          )}

          <div className="mt-5 flex justify-end gap-2">
            <button type="button" onClick={closeCreate} disabled={isCreating} className={GHOST}>
              {t("stories.cancel") || "Cancel"}
            </button>
            <button
              type="button"
              data-testid="highlight-create-submit"
              onClick={handleCreate}
              disabled={isCreating}
              className={PRIMARY}
            >
              {t("stories.create") || "Create"}
            </button>
          </div>
        </DialogShell>
      )}

      {editing && (
        <DialogShell
          labelledBy="highlight-edit-title-label"
          onClose={closeEdit}
          testId="highlight-edit-dialog"
          backdropTestId="highlight-edit-backdrop"
          dismissible={!isUpdating}
        >
          <h2
            id="highlight-edit-title-label"
            className="font-display text-base text-ink-900 dark:text-ink-50"
          >
            {t("stories.edit_highlight") || "Edit highlight"}
          </h2>

          <label className="mt-4 block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
            {t("stories.highlight_name") || "Highlight name"}
            <input
              data-testid="highlight-edit-title"
              type="text"
              value={editTitle}
              maxLength={50}
              onChange={(e) => setEditTitle(e.target.value)}
              className={FIELD}
            />
          </label>

          {/* The cover can only be one of this highlight's own stories -- the
              server stores a URL, and any other URL would point at media the
              highlight does not contain. */}
          {storiesOf(editing).length > 0 && (
            <>
              <p className="mt-4 text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
                {t("stories.choose_cover") || "Choose a cover"}
              </p>
              <div className="mt-2 grid max-h-52 grid-cols-4 gap-2 overflow-y-auto">
                {storiesOf(editing)
                  .filter((story: any) => mediaOf(story))
                  .map((story: any) => {
                    const url = mediaOf(story);
                    const picked = editCover ? editCover === url : editing.coverImage === url;
                    return (
                      <button
                        key={story._id}
                        type="button"
                        data-testid="highlight-cover-option"
                        aria-pressed={picked}
                        onClick={() => setEditCover(url)}
                        className={`relative aspect-[9/16] overflow-hidden rounded-chip ${
                          picked ? "ring-2 ring-brand-deep" : "ring-1 ring-line dark:ring-line-dark"
                        }`}
                      >
                        <StoryTile story={story} testId="highlight-cover-thumb" />
                      </button>
                    );
                  })}
              </div>
            </>
          )}

          <div className="mt-5 flex justify-end gap-2">
            <button type="button" onClick={closeEdit} disabled={isUpdating} className={GHOST}>
              {t("stories.cancel") || "Cancel"}
            </button>
            <button
              type="button"
              data-testid="highlight-edit-submit"
              onClick={handleUpdate}
              disabled={isUpdating}
              className={PRIMARY}
            >
              {t("stories.save") || "Save"}
            </button>
          </div>
        </DialogShell>
      )}

      <ConfirmDialog
        open={Boolean(deleteId)}
        title={t("stories.delete_highlight_confirm") || "Delete highlight?"}
        body={
          t("stories.delete_highlight_body") ||
          "The stories themselves stay in your archive."
        }
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

export default Highlights;
