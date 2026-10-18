import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { FaRegComments } from "react-icons/fa";
import AdUnit from "../../ads/AdUnit";
import { AD_SLOTS } from "../../ads/adsenseConfig";
import CommentComposer from "./CommentComposer";
import CommentItem from "./CommentItem";
import { CommentType } from "./types";
import { useGetMomentCommentsQuery } from "../../../store/slices/momentsSlice";

/**
 * The whole comment surface of a moment: the composer (comment or
 * correction), the list, and the empty state.
 *
 * The backend caps a page at 100 and defaults to 50 (controllers/comments.js
 * `getComments`), and answers with { count, total, page, pages, data }, so
 * the list pages explicitly: each page is kept in its own slot and a refetch
 * REPLACES that slot rather than appending, so an edit, a like or a deletion
 * propagates instead of being shadowed by the copy fetched first. Only a
 * genuinely different payload is written back, which also keeps a query
 * result whose object identity changes every render from looping the effect.
 *
 * `total` (not `data.length`) drives the counters, including the one
 * `MomentDetail` shows in its header via `onTotalChange` -- the moment's own
 * `commentCount` is a denormalized field and the list is the fresher source.
 *
 * Reading comments is public; writing anything is not, so a logged-out
 * visitor gets the sign-in prompt in place of the composer and the per-action
 * prompt (`onRequireLogin`) everywhere else.
 */

const PAGE_SIZE = 20;

interface CommentListProps {
  momentId: string;
  /** The moment's text, prefilled as the "original" of a correction. */
  momentText?: string;
  myUserId?: string;
  isLoggedIn: boolean;
  onRequireLogin: () => void;
  /** Reports the server's `total` so a header counter can follow it. */
  onTotalChange?: (total: number) => void;
  /** The moment's author, who may delete any comment on it (moments#9). */
  momentOwnerId?: string;
}

const CommentList: React.FC<CommentListProps> = ({
  momentId,
  momentText,
  myUserId,
  isLoggedIn,
  onRequireLogin,
  onTotalChange,
  momentOwnerId,
}) => {
  const { t } = useTranslation();
  const [mode, setMode] = useState<"comment" | "correction">("comment");
  const [page, setPage] = useState(1);
  const [pagesLoaded, setPagesLoaded] = useState<CommentType[][]>([]);
  const signatures = useRef<string[]>([]);

  const { data, isLoading, isFetching } = useGetMomentCommentsQuery(
    { momentId, page, limit: PAGE_SIZE },
    { skip: !momentId }
  );

  useEffect(() => {
    const batch: CommentType[] = (data && data.data) || [];
    const signature = JSON.stringify(batch);
    if (signatures.current[page - 1] === signature) return;
    signatures.current[page - 1] = signature;
    setPagesLoaded((prev) => {
      const next = prev.slice();
      next[page - 1] = batch;
      return next;
    });
  }, [data, page]);

  const comments = useMemo(() => {
    const flat: CommentType[] = [];
    pagesLoaded.forEach((chunk) => {
      if (chunk) flat.push.apply(flat, chunk);
    });
    return flat;
  }, [pagesLoaded]);

  const total: number =
    data && typeof data.total === "number" ? data.total : comments.length;
  const pages: number = (data && data.pages) || 1;

  useEffect(() => {
    if (onTotalChange && data && typeof data.total === "number") {
      onTotalChange(data.total);
    }
  }, [onTotalChange, data]);

  const handleDeleted = useCallback((deletedId: string) => {
    signatures.current = [];
    setPagesLoaded((prev) =>
      prev.map((chunk) => (chunk || []).filter((c) => c._id !== deletedId))
    );
  }, []);

  // A new comment lands at the top of page 1 (createdAt descending), so the
  // list goes back to a single page rather than showing it twice.
  const handlePosted = useCallback(() => {
    signatures.current = [];
    setPagesLoaded([]);
    setPage(1);
  }, []);

  const tabClass = (active: boolean) =>
    `rounded-full px-3 py-1 text-xs font-semibold transition-colors ${
      active
        ? "bg-blue-500 text-white"
        : "bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300"
    }`;

  return (
    <div data-testid="comment-list">
      {isLoggedIn ? (
        <div className="mb-4 sm:mb-6">
          <div className="mb-2 flex items-center gap-2">
            <button
              type="button"
              data-testid="comments-mode-comment"
              aria-pressed={mode === "comment"}
              onClick={() => setMode("comment")}
              className={tabClass(mode === "comment")}
            >
              {t("moments_section.commentEngagement.commentTab") || "Comment"}
            </button>
            <button
              type="button"
              data-testid="comments-mode-correction"
              aria-pressed={mode === "correction"}
              onClick={() => setMode("correction")}
              className={tabClass(mode === "correction")}
            >
              {t("moments_section.commentEngagement.correctionTab") || "Correction"}
            </button>
          </div>

          <CommentComposer
            key={mode}
            momentId={momentId}
            mode={mode}
            momentText={momentText}
            isLoggedIn={isLoggedIn}
            onRequireLogin={onRequireLogin}
            onDone={handlePosted}
            inputId={mode === "comment" ? "commentInput" : undefined}
          />
        </div>
      ) : (
        <div
          data-testid="comments-signin"
          className="mb-4 rounded-2xl border border-gray-200 bg-gray-50 p-3 text-center sm:mb-6 sm:p-4 dark:border-gray-700 dark:bg-gray-800"
        >
          <p className="text-sm text-gray-600 sm:text-base dark:text-gray-300">
            {t("moments_section.signInToComment") ||
              "Sign in to join the conversation."}{" "}
            <Link
              to="/login"
              className="font-semibold text-blue-600 transition-colors hover:text-blue-700"
            >
              {t("moments_section.signIn") || "Sign in"}
            </Link>
          </p>
        </div>
      )}

      {isLoading ? (
        <p className="py-8 text-center text-sm text-gray-500">
          {t("moments_section.loadingComments") || "Loading comments…"}
        </p>
      ) : comments.length > 0 ? (
        <div>
          <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold text-gray-700 sm:mb-4 sm:text-base dark:text-gray-200">
            <span>{t("moments_section.comments") || "Comments"}</span>
            <span
              data-testid="comments-total"
              className="flex h-5 w-5 items-center justify-center rounded-full bg-gray-200 text-xs text-gray-600 sm:h-6 sm:w-6"
            >
              {total}
            </span>
          </h3>

          <div className="divide-y divide-gray-100 dark:divide-gray-700">
            {comments.map((comment, index) => (
              <React.Fragment key={comment._id}>
                <CommentItem
                  comment={comment}
                  momentId={momentId}
                  myUserId={myUserId}
                  isLoggedIn={isLoggedIn}
                  onRequireLogin={onRequireLogin}
                  onDeleted={handleDeleted}
                  momentOwnerId={momentOwnerId}
                />
                {/* One ad after the fifth comment, as before. No-op until
                    AdSense is configured. */}
                {index === 4 && comments.length > 5 && (
                  <AdUnit slot={AD_SLOTS.comments} />
                )}
              </React.Fragment>
            ))}
          </div>

          {page < pages && (
            <button
              type="button"
              data-testid="comments-load-more"
              onClick={() => setPage((p) => p + 1)}
              disabled={isFetching}
              className="mt-3 w-full rounded-full bg-gray-100 py-2 text-xs font-semibold text-gray-600 hover:bg-gray-200 disabled:opacity-50 dark:bg-gray-800 dark:text-gray-300"
            >
              {t("moments_section.commentEngagement.loadMoreComments") ||
                "Load more comments"}
            </button>
          )}
        </div>
      ) : (
        <div className="py-8 text-center sm:py-12">
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 sm:mb-4 sm:h-16 sm:w-16">
            <FaRegComments className="h-5 w-5 text-gray-400 sm:h-6 sm:w-6" />
          </div>
          <p
            data-testid="comments-empty"
            className="text-sm font-medium text-gray-500 sm:text-base"
          >
            {t("moments_section.noCommentsYet") || "No comments yet"}
          </p>
          <p className="mt-1 text-xs text-gray-400 sm:text-sm">
            {t("moments_section.commentEngagement.beFirst") ||
              "Be the first to share your thoughts!"}
          </p>
        </div>
      )}
    </div>
  );
};

export default CommentList;
