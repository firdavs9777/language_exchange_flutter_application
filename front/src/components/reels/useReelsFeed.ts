import { useCallback, useEffect, useRef, useState } from "react";
import { useLazyGetReelsPageQuery } from "../../store/slices/reelsSlice";
import { mergeReels, Reel } from "./lib/reelModel";

export type ReelsStatus = "loading" | "ready" | "error" | "unavailable";

export interface ReelsFeed {
  reels: Reel[];
  status: ReelsStatus;
  hasMore: boolean;
  loadingMore: boolean;
  loadMore(): void;
  reload(): void;
  patchReel(id: string, patch: Partial<Reel>): void;
  removeWhere(test: (r: Reel) => boolean): void;
}

/**
 * The reels feed as one growing list. Pages come from GET /moments/reels and
 * are appended (deduplicated) here rather than kept per cache entry: the
 * cursor is a score snapshot, so page N only makes sense after page N-1 of
 * the same session.
 */
export function useReelsFeed(): ReelsFeed {
  const [trigger] = useLazyGetReelsPageQuery();
  const [reels, setReels] = useState<Reel[]>([]);
  const [status, setStatus] = useState<ReelsStatus>("loading");
  const [cursor, setCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);
  const inFlight = useRef(false);
  const alive = useRef(true);

  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
    };
  }, []);

  const fetchPage = useCallback(
    async (before: string | null) => {
      if (inFlight.current) return;
      inFlight.current = true;
      if (before) setLoadingMore(true);
      try {
        const page = await trigger({ before }, false).unwrap();
        if (!alive.current) return;
        setReels((prev) => (before ? mergeReels(prev, page.reels) : page.reels));
        setCursor(page.nextCursor);
        setStatus("ready");
      } catch (err) {
        if (!alive.current) return;
        // A failed "load more" keeps what is on screen; only a failed first
        // page replaces it with an error state.
        if (!before) setStatus(err && (err as any).status === 404 ? "unavailable" : "error");
      } finally {
        inFlight.current = false;
        if (alive.current) setLoadingMore(false);
      }
    },
    [trigger]
  );

  useEffect(() => {
    fetchPage(null);
  }, [fetchPage]);

  const loadMore = useCallback(() => {
    if (cursor) fetchPage(cursor);
  }, [cursor, fetchPage]);

  const reload = useCallback(() => {
    setStatus("loading");
    setCursor(null);
    return fetchPage(null);
  }, [fetchPage]);

  const patchReel = useCallback((id: string, patch: Partial<Reel>) => {
    setReels((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)));
  }, []);

  const removeWhere = useCallback((test: (r: Reel) => boolean) => {
    setReels((prev) => prev.filter((r) => !test(r)));
  }, []);

  return {
    reels,
    status,
    hasMore: !!cursor,
    loadingMore,
    loadMore,
    reload: reload as () => void,
    patchReel,
    removeWhere,
  };
}
