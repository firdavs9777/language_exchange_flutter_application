import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import CommentItem from "./CommentItem";
import { CommentType } from "./types";
import { useGetCommentRepliesQuery } from "../../../store/slices/momentsSlice";

/**
 * The replies under one comment, oldest first, paged the way the backend
 * pages them (GET /api/v1/comments/:id/replies -> { data, total, page, pages }).
 *
 * Pages are kept per page number rather than concatenated: a refetch of an
 * already-loaded page REPLACES that page's items, so a like count or a
 * deletion from elsewhere propagates instead of being shadowed by the copy
 * fetched first. Only a genuinely different payload is written back (the
 * per-page signature below), which also keeps a query result whose object
 * identity changes on every render from looping the effect.
 *
 * Replies render with `allowReplies={false}`: `models/Comment.js` stores a
 * single `parentComment` pointer, so one level is all the data supports.
 *
 * Known backend gap: `deleteComment` (controllers/comments.js) does not
 * decrement the parent's `replyCount`, so "View N replies" can over-count
 * until the parent is re-created. Deleting here removes the reply from the
 * thread optimistically and lets the `Comments` tag refetch confirm it.
 */

const REPLIES_PAGE_SIZE = 10;

interface RepliesThreadProps {
  commentId: string;
  momentId: string;
  myUserId?: string;
  isLoggedIn: boolean;
  onRequireLogin: () => void;
  /** The moment's author, who may delete any reply on it (moments#9). */
  momentOwnerId?: string;
}

const RepliesThread: React.FC<RepliesThreadProps> = ({
  commentId,
  momentId,
  myUserId,
  isLoggedIn,
  onRequireLogin,
  momentOwnerId,
}) => {
  const { t } = useTranslation();
  const [page, setPage] = useState(1);
  const [pagesLoaded, setPagesLoaded] = useState<CommentType[][]>([]);
  const signatures = useRef<string[]>([]);

  const { data, isFetching } = useGetCommentRepliesQuery({
    commentId,
    page,
    limit: REPLIES_PAGE_SIZE,
  });

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

  const replies = useMemo(() => {
    const flat: CommentType[] = [];
    pagesLoaded.forEach((chunk) => {
      if (chunk) flat.push.apply(flat, chunk);
    });
    return flat;
  }, [pagesLoaded]);

  const pages: number = (data && data.pages) || 1;

  const handleDeleted = useCallback((deletedId: string) => {
    // Drop it now; the refetch the delete triggers confirms it. Signatures
    // are cleared so that refetch is always written back, even if the server
    // answers with exactly what we had before this removal.
    signatures.current = [];
    setPagesLoaded((prev) =>
      prev.map((chunk) => (chunk || []).filter((reply) => reply._id !== deletedId))
    );
  }, []);

  const loadMore = useCallback(() => setPage((p) => p + 1), []);

  return (
    <div
      data-testid="replies-thread"
      className="mt-2 space-y-1 border-l-2 border-gray-100 pl-3 dark:border-gray-700"
    >
      {replies.map((reply) => (
        <CommentItem
          key={reply._id}
          comment={reply}
          momentId={momentId}
          myUserId={myUserId}
          isLoggedIn={isLoggedIn}
          onRequireLogin={onRequireLogin}
          onDeleted={handleDeleted}
          allowReplies={false}
          momentOwnerId={momentOwnerId}
        />
      ))}

      {isFetching && replies.length === 0 && (
        <p className="py-2 text-xs text-gray-500">
          {t("moments_section.commentEngagement.loadingReplies") ||
            "Loading replies…"}
        </p>
      )}

      {page < pages && (
        <button
          type="button"
          data-testid="replies-load-more"
          onClick={loadMore}
          disabled={isFetching}
          className="py-1 text-xs font-semibold text-blue-600 hover:underline disabled:opacity-50"
        >
          {t("moments_section.commentEngagement.loadMoreReplies") || "Load more"}
        </button>
      )}
    </div>
  );
};

export default RepliesThread;
