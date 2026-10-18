import React, { useEffect, useMemo, useRef, useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { Heart, MessageCircle, Pencil, Plus, RefreshCw, Trash2 } from "lucide-react";
import PageMeta from "../../seo/PageMeta";
import SurfaceCard from "../../design/SurfaceCard";
import ConfirmDialog from "../../design/ConfirmDialog";
import {
  useGetMyMomentsQuery,
  useDeleteMomentMutation,
} from "../../store/slices/momentsSlice";

export interface MomentType {
  _id: string;
  title?: string;
  description?: string;
  imageUrls?: string[];
  likeCount?: any;
  commentCount?: any;
  createdAt?: string;
}

const PAGE = "min-h-screen bg-canvas dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full max-w-3xl px-3 pb-16 pt-4 sm:px-4 sm:pt-6";
const CTA =
  "inline-flex items-center justify-center gap-1.5 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-dark";
const TILE_ACTION =
  "rounded-full bg-ink-950/60 p-1.5 text-white transition-colors hover:bg-ink-950/80";

const SKELETONS = [0, 1, 2, 3, 4, 5];
const PAGE_SIZE = 12;

function countOf(value: any): number {
  if (Array.isArray(value)) return value.length;
  if (typeof value === "number" && isFinite(value)) return value;
  return 0;
}

function firstImage(moment: any): string {
  const urls = moment && (moment.imageUrls || moment.images);
  if (Array.isArray(urls)) {
    for (let i = 0; i < urls.length; i += 1) {
      const url = typeof urls[i] === "string" ? urls[i].trim() : "";
      if (url) return url;
    }
  }
  return "";
}

function captionOf(moment: any): string {
  const description = typeof moment.description === "string" ? moment.description.trim() : "";
  if (description) return description;
  return typeof moment.title === "string" ? moment.title.trim() : "";
}

/**
 * The owner's own moments, as the same square grid `ProfileMoments` draws on
 * the profile — one visual language for one set of content, rather than the
 * Bootstrap card deck this page used to be (inventory §3).
 *
 * The delete button now deletes. It previously logged the id to the console
 * and nothing else: a control that looked destructive, was shipped, and did
 * nothing. It goes through `ConfirmDialog` (deleting a moment takes its likes
 * and comments with it) and the tile disappears the moment the server agrees,
 * without waiting for the invalidated query to come back around.
 */
const MyMoments: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userId = useSelector(
    (state: any) => state.auth.userInfo?.user?._id || state.auth.userInfo?._id
  );

  // The server pages this list ({data, pagination}); "Load more" asks for the
  // next page and appends it to the pages already shown.
  const [page, setPage] = useState(1);
  const { currentData, isLoading, isFetching, error, refetch } = useGetMyMomentsQuery(
    { userId: userId || "", page, limit: PAGE_SIZE },
    { skip: !userId }
  );
  const [pages, setPages] = useState<{ [page: number]: any[] }>({});
  const [hasMore, setHasMore] = useState(false);
  useEffect(() => {
    if (!currentData) return;
    const rows: any[] = Array.isArray((currentData as any).data) ? (currentData as any).data : [];
    setPages((prev) => ({ ...prev, [page]: rows }));
    const pagination = (currentData as any).pagination;
    setHasMore(
      pagination && typeof pagination.hasNextPage === "boolean"
        ? pagination.hasNextPage
        : rows.length >= PAGE_SIZE
    );
  }, [currentData, page]);
  const [deleteMoment, { isLoading: isDeleting }] = useDeleteMomentMutation();

  const [pending, setPending] = useState<MomentType | null>(null);
  const [deleteError, setDeleteError] = useState("");
  // Ids the server has already accepted a delete for. `deleteMoment`
  // invalidates the "Moments" tag and `getMyMoments` provides it, so the list
  // does refetch — but the tile must not linger through that round trip.
  const [removed, setRemoved] = useState<{ [id: string]: boolean }>({});

  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  const moments = useMemo(() => {
    // The page just served counts before the effect above has stored it, so
    // the first render with data never flashes the empty state.
    const all: { [page: number]: any[] } = { ...pages };
    if (currentData && Array.isArray((currentData as any).data)) {
      all[page] = (currentData as any).data;
    }
    const seen: { [id: string]: boolean } = {};
    const out: any[] = [];
    Object.keys(all)
      .map(Number)
      .sort((a, b) => a - b)
      .forEach((key) => {
        all[key].forEach((moment: any) => {
          // A delete shifts later pages by one, so a refetched page can repeat
          // a moment an earlier page already shows.
          if (!moment || removed[moment._id] || seen[moment._id]) return;
          seen[moment._id] = true;
          out.push(moment);
        });
      });
    return out;
  }, [pages, currentData, page, removed]);

  const handleDelete = async (): Promise<void> => {
    if (!pending) return;
    const id = pending._id;
    setDeleteError("");
    try {
      await deleteMoment(id).unwrap();
      if (!mounted.current) return;
      setRemoved((prev) => ({ ...prev, [id]: true }));
      setPending(null);
    } catch (caught) {
      if (!mounted.current) return;
      setDeleteError(
        t("profile.myMoments.delete_failed") || "We couldn't delete that moment. Try again."
      );
    }
  };

  if (!userId) return <Navigate to="/login" replace />;

  const showSkeleton = isLoading && moments.length === 0;
  const failed = !isLoading && Boolean(error) && moments.length === 0;
  const loadingMore = isFetching && page > 1 && !currentData;
  const empty = !showSkeleton && !failed && moments.length === 0;

  return (
    <div className={PAGE}>
      <PageMeta noindex title={`${t("profile.myMoments.title") || "My moments"} · BananaTalk`} />
      <div className={COLUMN}>
        <div data-testid="my-moments" className="space-y-4">
          <div className="flex items-center justify-between gap-3">
            <h1 className="font-display text-xl text-ink-900 dark:text-ink-50">
              {t("profile.myMoments.title") || "My moments"}
            </h1>
            <Link to="/add-moment" data-testid="my-moments-create" className={CTA}>
              <Plus className="h-4 w-4" aria-hidden />
              {t("profile.myMoments.create") || "Share a moment"}
            </Link>
          </div>

          <SurfaceCard padding="lg">
            {showSkeleton && (
              <div
                data-testid="my-moments-skeleton"
                aria-busy="true"
                className="grid animate-pulse grid-cols-2 gap-2 sm:grid-cols-3"
              >
                {SKELETONS.map((index) => (
                  <div
                    key={index}
                    className="aspect-square rounded-chip bg-ink-100 dark:bg-ink-800"
                  />
                ))}
              </div>
            )}

            {failed && (
              <div data-testid="my-moments-error" role="alert" className="py-4 text-center">
                <h2 className="font-display text-lg text-ink-900 dark:text-ink-50">
                  {t("profile.myMoments.error_title") || "We couldn't load your moments"}
                </h2>
                <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                  {t("profile.myMoments.error_body") || "Check your connection and try again."}
                </p>
                <button
                  type="button"
                  data-testid="my-moments-retry"
                  onClick={refetch}
                  className={`mt-4 ${CTA}`}
                >
                  <RefreshCw className="h-4 w-4" aria-hidden />
                  {t("profile.myMoments.retry") || "Try again"}
                </button>
              </div>
            )}

            {empty && (
              <div data-testid="my-moments-empty" className="py-8 text-center">
                <h2 className="font-display text-lg text-ink-900 dark:text-ink-50">
                  {t("profile.myMoments.empty_title") || "No moments yet"}
                </h2>
                <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                  {t("profile.myMoments.empty_body") ||
                    "Share your first moment with the community."}
                </p>
                <Link to="/add-moment" className={`mt-4 ${CTA}`}>
                  <Plus className="h-4 w-4" aria-hidden />
                  {t("profile.myMoments.create") || "Share a moment"}
                </Link>
              </div>
            )}

            {!showSkeleton && !failed && moments.length > 0 && (
              <ul className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                {moments.map((moment: any) => {
                  const image = firstImage(moment);
                  const caption = captionOf(moment);
                  return (
                    <li
                      key={moment._id}
                      data-testid="moment-tile"
                      className="group relative aspect-square overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
                    >
                      <Link
                        to={`/moment/${moment._id}`}
                        data-testid={`moment-link-${moment._id}`}
                        className="block h-full w-full"
                      >
                        {image ? (
                          <img
                            src={image}
                            alt={caption || t("profile.moments.photo_alt") || "Moment photo"}
                            loading="lazy"
                            data-testid="moment-tile-image"
                            className="h-full w-full object-cover transition-transform duration-200 group-hover:scale-[1.03]"
                          />
                        ) : (
                          <span
                            data-testid="moment-tile-text"
                            className="flex h-full w-full items-center justify-center overflow-hidden p-3 text-center text-xs font-semibold leading-snug text-ink-700 dark:text-ink-100"
                          >
                            {caption}
                          </span>
                        )}
                      </Link>

                      <div className="absolute right-1.5 top-1.5 flex gap-1 opacity-0 transition-opacity focus-within:opacity-100 group-hover:opacity-100">
                        <button
                          type="button"
                          data-testid={`moment-edit-${moment._id}`}
                          onClick={() => navigate(`/edit-moment/${moment._id}`)}
                          aria-label={t("profile.myMoments.edit") || "Edit moment"}
                          className={TILE_ACTION}
                        >
                          <Pencil className="h-3.5 w-3.5" aria-hidden />
                        </button>
                        <button
                          type="button"
                          data-testid={`moment-delete-${moment._id}`}
                          onClick={() => {
                            setDeleteError("");
                            setPending(moment);
                          }}
                          aria-label={t("profile.myMoments.delete") || "Delete moment"}
                          className={TILE_ACTION}
                        >
                          <Trash2 className="h-3.5 w-3.5" aria-hidden />
                        </button>
                      </div>

                      <span className="pointer-events-none absolute inset-x-0 bottom-0 flex items-center gap-3 bg-ink-950/50 px-2 py-1 text-[11px] font-semibold text-white">
                        <span data-testid="moment-likes" className="inline-flex items-center gap-1">
                          <Heart className="h-3 w-3" aria-hidden />
                          {countOf(moment.likeCount)}
                        </span>
                        <span
                          data-testid="moment-comments"
                          className="inline-flex items-center gap-1"
                        >
                          <MessageCircle className="h-3 w-3" aria-hidden />
                          {countOf(moment.commentCount)}
                        </span>
                      </span>
                    </li>
                  );
                })}
              </ul>
            )}

            {!showSkeleton && moments.length > 0 && (hasMore || Boolean(error)) && (
              <div className="pt-4 text-center">
                <button
                  type="button"
                  data-testid="my-moments-load-more"
                  disabled={loadingMore}
                  onClick={() => {
                    if (error) {
                      refetch();
                    } else {
                      setPage((current) => current + 1);
                    }
                  }}
                  className={`${CTA} disabled:cursor-not-allowed disabled:opacity-60`}
                >
                  {loadingMore
                    ? t("profile.myMoments.loading_more") || "Loading..."
                    : error
                    ? t("profile.myMoments.retry") || "Try again"
                    : t("profile.myMoments.load_more") || "Load more"}
                </button>
              </div>
            )}
          </SurfaceCard>
        </div>
      </div>

      <ConfirmDialog
        open={pending !== null}
        danger
        title={t("profile.myMoments.delete_title") || "Delete this moment?"}
        body={
          t("profile.myMoments.delete_body") ||
          "It disappears for everyone, along with its likes and comments."
        }
        confirmLabel={t("profile.myMoments.delete_confirm") || "Delete"}
        cancelLabel={t("profile.actions.cancel") || "Cancel"}
        busy={isDeleting}
        error={deleteError || undefined}
        onConfirm={handleDelete}
        onCancel={() => setPending(null)}
      />
    </div>
  );
};

export default MyMoments;
