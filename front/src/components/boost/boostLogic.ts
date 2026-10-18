import { Boost } from "../../store/slices/boostsSlice";

/** Price on the confirm card. The server charges the real amount (BOOST_COST); a mismatch is a 402. */
export const PROFILE_BOOST_COST = 150;
/** How long after a boost ends its result is still offered with "Boost again". */
export const BOOST_RESULT_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

const time = (v?: string) => (v ? new Date(v).getTime() : NaN);

export function isBoostLive(b: Boost | null | undefined, now: number = Date.now()): boolean {
  if (!b) return false;
  const end = time(b.endsAt);
  return isFinite(end) && end > now && b.status !== "expired" && b.status !== "refunded";
}

/** Share of the boost window already used, 0..1. */
export function boostProgress(b: Boost, now: number = Date.now()): number {
  const start = time(b.startsAt);
  const end = time(b.endsAt);
  if (!isFinite(start) || !isFinite(end)) return 0;
  const total = end - start;
  if (total <= 0) return 1;
  return Math.min(1, Math.max(0, (now - start) / total));
}

/** The newest boost that ended within the result window (history is newest first), else null. */
export function lastEndedBoost(history: Boost[] | null | undefined, now: number = Date.now()): Boost | null {
  for (const b of history || []) {
    if (isBoostLive(b, now) || !b.endsAt || b.status === "refunded") continue;
    return now - time(b.endsAt) <= BOOST_RESULT_WINDOW_MS ? b : null;
  }
  return null;
}

/** "3h 5m" / "5m" left, or "Ending soon" under a minute. */
export function formatBoostRemaining(ms: number, t: (k: string, o?: any) => string): string {
  const minutes = Math.floor(ms / 60000);
  if (minutes < 1) return t("boost.endingSoon") || "Ending soon";
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h > 0 ? t("boost.durationHm", { hours: h, minutes: m }) || `${h}h ${m}m` : t("boost.durationM", { minutes: m }) || `${m}m`;
}

export type BoostErrorKind = "insufficient_coins" | "already_boosted" | "capacity_full" | "other";

/** 402 / 409 / 429 from POST /boosts, by status or by the server's error code. */
export function boostErrorKind(err: any): BoostErrorKind {
  const status = err && err.status;
  const code = String((err && err.data && err.data.error) || "");
  if (status === 402 || code === "insufficient_coins") return "insufficient_coins";
  if (status === 409 || code === "already_boosted") return "already_boosted";
  // A bare 429 can also be the rate limiter, so only the server's code means "slots full".
  if (code === "capacity_full") return "capacity_full";
  return "other";
}
