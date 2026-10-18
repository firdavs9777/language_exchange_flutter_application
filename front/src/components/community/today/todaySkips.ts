/**
 * People skipped from today's batch. The server sends the same cached batch
 * all day, skipped cards included (it does not read skips when building it),
 * so the web remembers them per batch date in sessionStorage -- surviving a
 * reload, and starting clean when the date moves on.
 *
 * Storage that throws (private mode, blocked site data) falls back to an
 * in-memory copy for this page load, so skips still accumulate and survive a
 * tab switch; they only last until reload. While storage works it is the
 * source of truth and the in-memory copy just mirrors it.
 */
const KEY = (date: string) => `bt.todaySkips.${date}`;

const memory: Record<string, string[]> = {};

export function loadSkips(date: string): string[] {
  let raw: string | null;
  try {
    raw = window.sessionStorage.getItem(KEY(date));
  } catch (e) {
    // Storage is blocked: this page load's own record is all there is.
    return (memory[date] || []).slice();
  }
  // Storage works, so it is the truth -- a corrupt value reads as no skips.
  let ids: string[] = [];
  try {
    const parsed = raw ? JSON.parse(raw) : [];
    ids = Array.isArray(parsed) ? parsed.filter((id) => typeof id === "string") : [];
  } catch (e) {
    ids = [];
  }
  memory[date] = ids;
  return ids.slice();
}

export function addSkip(date: string, id: string): string[] {
  const current = loadSkips(date);
  const next = current.indexOf(id) > -1 ? current : current.concat([id]);
  memory[date] = next;
  try {
    window.sessionStorage.setItem(KEY(date), JSON.stringify(next));
  } catch (e) {
    // Kept in memory for this page load.
  }
  return next.slice();
}
