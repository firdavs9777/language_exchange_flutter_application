/**
 * Why someone is here: `learn`, `meet`, `date`.
 *
 * Stored on the user and RANKED on — `lib/matchIntent.js` adds a flat bonus
 * when two people share one, never multiplied by how many they share, so
 * ticking all three is not a ranking lever. It is not filtered on, so an empty
 * list costs nobody their results; it costs them the bonus. Until now the web
 * had no control for it at all, which left every web-registered account on the
 * default `[]` for good while app users could set it.
 *
 * The rules below mirror `lib/matchIntent.js` and `lib/userAge.js`. They are
 * duplicated rather than inferred because the server sanitises on write
 * whatever the client sends: this module exists so the form does not offer a
 * choice the server is about to discard, not to be the thing enforcing it.
 */

export type Intent = "learn" | "meet" | "date";

/** The values the server accepts, in display order. */
export const INTENTS: Intent[] = ["learn", "meet", "date"];

/** Drops anything the enum does not name, and any repeat. */
export function normalizeIntents(value: any): Intent[] {
  const raw = Array.isArray(value) ? value : typeof value === "string" ? [value] : [];
  const out: Intent[] = [];
  raw.forEach((entry: any) => {
    if (typeof entry !== "string") return;
    const key = entry.trim().toLowerCase() as Intent;
    if (INTENTS.indexOf(key) > -1 && out.indexOf(key) === -1) out.push(key);
  });
  return out;
}

/**
 * Age from the three birth fields the User document stores as strings, or
 * null when they do not describe a date. Mirrors `lib/userAge.js:ageFrom`.
 */
export function ageFrom(source: any, now: Date = new Date()): number | null {
  if (!source || typeof source !== "object") return null;

  const year = parseInt(source.birth_year, 10);
  const month = parseInt(source.birth_month, 10);
  const day = parseInt(source.birth_day, 10);
  if (!isFinite(year) || !isFinite(month) || !isFinite(day)) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  let age = now.getFullYear() - year;
  // Month is 1-based here and 0-based on Date, hence the +1. A birthday that
  // has not arrived this year has not happened yet.
  const monthDiff = now.getMonth() + 1 - month;
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < day)) age -= 1;

  return age >= 0 && age < 130 ? age : null;
}

/**
 * Known to be 18 or over. An unknown age answers false, which is the whole
 * point: `lib/userAge.js` records that 313 production accounts carry
 * `birth_year: ""` or no birth fields at all, so treating unknown as adult
 * would offer dating to someone who might be fifteen. Treating it as
 * not-adult costs a real adult one option until they fill in their birthday.
 */
export function isVerifiedAdult(source: any, now: Date = new Date()): boolean {
  const age = ageFrom(source, now);
  return age === null ? false : age >= 18;
}

/**
 * The options to show. `date` only for a known adult — the server strips it
 * from the write regardless, and offering a choice that is silently discarded
 * is worse than not offering it.
 */
export function availableIntents(source: any, now: Date = new Date()): Intent[] {
  return isVerifiedAdult(source, now)
    ? INTENTS
    : INTENTS.filter((intent) => intent !== "date");
}

/**
 * Add or remove one, keeping the canonical order so the stored value does not
 * depend on the order the user happened to tap.
 */
export function toggleIntent(selected: any, intent: Intent): Intent[] {
  const current = normalizeIntents(selected);
  const next =
    current.indexOf(intent) > -1
      ? current.filter((entry) => entry !== intent)
      : current.concat([intent]);
  return INTENTS.filter((entry) => next.indexOf(entry) > -1);
}

/**
 * Whether two selections hold the same intents, order disregarded.
 *
 * `toggleIntent` always returns canonical order, so a comparison of what the
 * form produced would not need this — but one side is usually a value loaded
 * from the server, which is stored in whatever order it was written in.
 */
export function sameIntents(a: any, b: any): boolean {
  const left = INTENTS.filter((entry) => normalizeIntents(a).indexOf(entry) > -1);
  const right = INTENTS.filter((entry) => normalizeIntents(b).indexOf(entry) > -1);
  if (left.length !== right.length) return false;
  return left.every((entry, index) => entry === right[index]);
}

/**
 * What a profile page shows: learn and meet, never date.
 *
 * The server already strips `date` from every read about another user
 * (lib/matchIntent.js:publicIntents), but an OWN profile is built from
 * /auth/me, which returns the whole stored value. The page shows what others
 * see, so it filters the same way rather than printing dating on your own
 * profile and implying it is public.
 */
export function publicIntents(value: any): Intent[] {
  return INTENTS.filter(
    (entry) => entry !== "date" && normalizeIntents(value).indexOf(entry) > -1
  );
}
