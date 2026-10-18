/**
 * One relative-time formatter for the whole app.
 *
 * Three copies of this arithmetic existed — `components/stories/timeAgo.ts`,
 * the `RelativeTime` memo in `components/moments/comments/CommentItem.tsx` and
 * a module-level `timeAgo()` in `components/profile/UserListPage.tsx`. All
 * three read the SAME four already-translated keys
 * (`moments_section.timeAgo.*`), so in every locale they rendered identical
 * text; they differed only in two details, and both are kept as options rather
 * than flattened away, because flattening them would change what a screen
 * renders when a key is missing:
 *
 *   - `withAgo` — the hard-coded English fallback. Stories spelled it
 *     "5m ago"; comments and the follower lists spelled it "5m", because they
 *     sit next to a name in a tight row. The translated strings all say "ago"
 *     (see locales/eng.json), so this only shows when a key is absent — which
 *     is exactly when a difference would be noticed as a regression.
 *   - `beyondWeek` — what a week-old timestamp becomes. Stories and comments
 *     hand over to `toLocaleDateString()`; the follower/visitor lists keep
 *     counting days, because "342d" there is a fact about the relationship
 *     rather than a date anyone reads.
 *
 * `t` is a parameter, not a hook call, so this stays usable from a `useMemo`,
 * from a module-level helper, and from a test with no i18n provider.
 */
export interface TimeAgoOptions {
  /** English fallbacks read "5m ago" instead of "5m". */
  withAgo?: boolean;
  /** Past seven days: a locale date (default) or a running day count. */
  beyondWeek?: "date" | "days";
}

export function timeAgo(
  date: string | number | Date | undefined | null,
  t: (key: string, vars?: any) => string,
  options?: TimeAgoOptions
): string {
  if (!date) return "";
  const then = new Date(date as any).getTime();
  if (!isFinite(then)) return "";

  const withAgo = Boolean(options && options.withAgo);
  const ago = withAgo ? " ago" : "";
  const beyondWeek = (options && options.beyondWeek) || "date";

  const minutes = Math.floor((Date.now() - then) / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (minutes < 1) return t("moments_section.timeAgo.justNow") || "just now";
  if (minutes < 60)
    return t("moments_section.timeAgo.minutesAgo", { minutes }) || `${minutes}m${ago}`;
  if (hours < 24)
    return t("moments_section.timeAgo.hoursAgo", { hours }) || `${hours}h${ago}`;
  if (days < 7 || beyondWeek === "days")
    return t("moments_section.timeAgo.daysAgo", { days }) || `${days}d${ago}`;
  return new Date(date as any).toLocaleDateString();
}

export default timeAgo;
