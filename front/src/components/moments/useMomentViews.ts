import { useCallback, useEffect, useRef } from "react";
import { useRecordMomentViewsMutation } from "../../store/slices/momentsSlice";

/**
 * View counting for moments seen on web, parity with the app's "watched
 * long enough to count" behavior.
 *
 * A single `IntersectionObserver` (threshold 0.5) is shared by every
 * mounted moment card -- one native observer regardless of how many cards
 * are in the feed. Each observed card gets a small tracked entry (dwell
 * time accumulator); when a card crosses below 50% visible (or the page is
 * about to be flushed), the elapsed visible time is added to that entry's
 * `watchedMs`. The backend only counts a view once `watchedMs >= 1000`
 * (controllers/momentViews.js MIN_VIEW_MS) and this module mirrors that:
 * once a moment's accumulated dwell time clears 1s it is queued exactly
 * once per page session (`completed: true` once it clears 5s), regardless
 * of how many times the same moment scrolls in and out of view. The queue
 * is flushed via `recordMomentViews` every 5s while non-empty, and
 * immediately on `pagehide` / the tab going hidden, so a closed tab still
 * gets credit for what was actually watched.
 *
 * Every `window`/`document`/`IntersectionObserver` access is guarded so
 * this is a no-op during Node prerendering (`src/seo/prerender`) -- effects
 * never run there anyway, but the guards also make the module safe to
 * import and call from a plain Node test.
 */

const MIN_VIEW_MS = 1000;
const COMPLETED_MS = 5000;
const FLUSH_INTERVAL_MS = 5000;
const VISIBILITY_THRESHOLD = 0.5;

interface TrackedEntry {
  momentId: string;
  // Timestamp (Date.now()) the entry most recently crossed into view, or
  // null while it is not currently visible.
  visibleSince: number | null;
  // Total milliseconds this momentId has been >=50% visible this session,
  // accumulated across every time it has entered/left view.
  watchedMs: number;
}

type QueuedView = { momentId: string; watchedMs: number; completed: boolean };
type RecordViewsTrigger = (args: { views: QueuedView[] }) => any;

let observerInstance: IntersectionObserver | null = null;
const elementEntries = new Map<any, TrackedEntry>();
// A momentId is queued at most once per page session, no matter how many
// times it scrolls in and out of view or how many cards render it.
const queuedMomentIds = new Set<string>();
let pendingViews: QueuedView[] = [];
let activeTrigger: RecordViewsTrigger | null = null;
let flushIntervalId: ReturnType<typeof setInterval> | null = null;
let listenersAttached = false;

function maybeQueueView(tracked: TrackedEntry) {
  if (queuedMomentIds.has(tracked.momentId)) return;
  if (tracked.watchedMs < MIN_VIEW_MS) return;
  queuedMomentIds.add(tracked.momentId);
  pendingViews.push({
    momentId: tracked.momentId,
    watchedMs: tracked.watchedMs,
    completed: tracked.watchedMs >= COMPLETED_MS,
  });
}

// Adds elapsed visible time (if any) to the entry's total. Used both when a
// card leaves view and when the flush timer/pagehide fires while a card is
// still on screen -- in the latter case `visibleSince` is reset to `now`
// rather than cleared, since the card is still visible and dwell time
// should keep accumulating rather than being double-counted later.
function accumulate(tracked: TrackedEntry, now: number, stillVisible: boolean) {
  if (tracked.visibleSince == null) return;
  tracked.watchedMs += now - tracked.visibleSince;
  tracked.visibleSince = stillVisible ? now : null;
  maybeQueueView(tracked);
}

function handleIntersections(entries: IntersectionObserverEntry[]) {
  const now = Date.now();
  entries.forEach((entry) => {
    const tracked = elementEntries.get(entry.target);
    if (!tracked) return;
    const ratio = (entry as any).intersectionRatio;
    const visible =
      Boolean((entry as any).isIntersecting) &&
      (ratio === undefined || ratio >= VISIBILITY_THRESHOLD);
    if (visible) {
      if (tracked.visibleSince == null) tracked.visibleSince = now;
    } else {
      accumulate(tracked, now, false);
    }
  });
}

function getObserver(): IntersectionObserver | null {
  if (typeof window === "undefined" || typeof IntersectionObserver === "undefined") {
    return null;
  }
  if (!observerInstance) {
    // Intentionally never disconnected for the life of the SPA session --
    // one observer serves every moment card that ever mounts, not just the
    // currently-mounted ones; `_resetMomentViewsForTests()` is the only
    // thing that tears it down (test isolation only).
    observerInstance = new IntersectionObserver(handleIntersections, {
      threshold: VISIBILITY_THRESHOLD,
    });
  }
  return observerInstance;
}

function flushQueue() {
  const now = Date.now();
  // Give every still-visible card credit for the time it's accumulated so
  // far before deciding what to send -- a card that's been on screen the
  // whole 5s interval shouldn't have to leave view to be counted.
  elementEntries.forEach((tracked) => {
    if (tracked.visibleSince != null) accumulate(tracked, now, true);
  });
  if (pendingViews.length === 0) return;
  const views = pendingViews;
  pendingViews = [];
  if (!activeTrigger) return;
  try {
    const result: any = activeTrigger({ views });
    if (result && typeof result.unwrap === "function") {
      result.unwrap().catch(() => {});
    }
  } catch {
    // Best-effort analytics -- never throw out of a pagehide/visibility
    // handler or an interval tick.
  }
}

function handleVisibilityChange() {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") {
    flushQueue();
  }
}

function ensureGlobalWiring() {
  if (typeof window === "undefined") return;
  // Both the interval and the listeners below are set up once and kept
  // running for as long as the SPA tab stays open -- they are shared by
  // every moment card that mounts over the session, not torn down when any
  // one card (or even every currently-mounted card) unmounts.
  if (flushIntervalId == null) {
    flushIntervalId = setInterval(flushQueue, FLUSH_INTERVAL_MS);
  }
  if (!listenersAttached) {
    listenersAttached = true;
    window.addEventListener("pagehide", flushQueue);
    if (typeof document !== "undefined") {
      document.addEventListener("visibilitychange", handleVisibilityChange);
    }
  }
}

/**
 * Starts tracking one moment card's visibility. Returns an unobserve
 * function; call it when the card unmounts (or is replaced). No-ops (and
 * returns a no-op fn) when there is no real `IntersectionObserver` to use,
 * e.g. Node prerendering or an older browser.
 */
export function observeMoment(el: any, momentId: string): () => void {
  const observer = getObserver();
  if (!observer || !el) return () => {};

  elementEntries.set(el, { momentId, visibleSince: null, watchedMs: 0 });
  observer.observe(el);

  return () => {
    const tracked = elementEntries.get(el);
    if (tracked) accumulate(tracked, Date.now(), false);
    observer.unobserve(el);
    elementEntries.delete(el);
  };
}

/**
 * Wires up view counting for a single moment card. Returns a ref callback
 * to attach to the card's root element -- the same pattern as any other
 * DOM ref. No-ops entirely (no observer, no listeners) when logged out,
 * since recording a view is a protected write.
 */
export function useMomentViews({
  momentId,
  isLoggedIn,
}: {
  momentId: string;
  isLoggedIn: boolean;
}): (node: any) => void {
  const [recordMomentViews] = useRecordMomentViewsMutation();
  const unobserveRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (!isLoggedIn) return;
    activeTrigger = recordMomentViews;
    ensureGlobalWiring();
  }, [isLoggedIn, recordMomentViews]);

  // Unobserve on unmount, whatever element was last attached.
  useEffect(() => {
    return () => {
      if (unobserveRef.current) {
        unobserveRef.current();
        unobserveRef.current = null;
      }
    };
  }, []);

  const ref = useCallback(
    (node: any) => {
      if (unobserveRef.current) {
        unobserveRef.current();
        unobserveRef.current = null;
      }
      if (node && isLoggedIn && momentId) {
        unobserveRef.current = observeMoment(node, momentId);
      }
    },
    [momentId, isLoggedIn]
  );

  return ref;
}

/** Test-only: clears every module-level singleton this file keeps. */
export function _resetMomentViewsForTests() {
  if (flushIntervalId != null) {
    clearInterval(flushIntervalId);
    flushIntervalId = null;
  }
  if (listenersAttached && typeof window !== "undefined") {
    window.removeEventListener("pagehide", flushQueue);
    if (typeof document !== "undefined") {
      document.removeEventListener("visibilitychange", handleVisibilityChange);
    }
  }
  listenersAttached = false;
  if (observerInstance) {
    try {
      observerInstance.disconnect();
    } catch {
      // ignore -- best-effort cleanup for tests
    }
  }
  observerInstance = null;
  elementEntries.clear();
  queuedMomentIds.clear();
  pendingViews = [];
  activeTrigger = null;
}
