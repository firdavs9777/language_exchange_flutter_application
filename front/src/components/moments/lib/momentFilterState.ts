import ISO6391 from "iso-639-1";
import { MOMENT_CATEGORIES, MOMENT_MOODS } from "./momentOptions";

/**
 * The moments feed's filters, kept in the URL (?cat=&lang=&mood=&tag=&q=) so
 * a filtered feed is shareable, survives a reload and answers Back -- the
 * same pattern as communityUrlState.ts. The server does the filtering; this
 * only reads, writes and serialises the state.
 */
export interface MomentFilters {
  category?: string;
  language?: string;
  mood?: string;
  tag?: string;
  q?: string;
}

const MAX_Q = 100;
const MOODS = MOMENT_MOODS.map((m) => m.value);

/** URL key for each filter, in canonical order. */
const KEYS: Array<[keyof MomentFilters, string]> = [
  ["category", "cat"],
  ["language", "lang"],
  ["mood", "mood"],
  ["tag", "tag"],
  ["q", "q"],
];

/** Server param for each filter, in canonical order. */
const SERVER_KEYS: Array<[keyof MomentFilters, string]> = [
  ["category", "category"],
  ["language", "language"],
  ["mood", "mood"],
  ["tag", "tags"],
  ["q", "q"],
];

function clean(key: keyof MomentFilters, raw: string | null): string | undefined {
  if (raw == null) return undefined;
  const value = raw.trim();
  if (!value) return undefined;
  switch (key) {
    case "category":
      return MOMENT_CATEGORIES.indexOf(value) > -1 ? value : undefined;
    case "mood":
      return MOODS.indexOf(value) > -1 ? value : undefined;
    case "language":
      return ISO6391.validate(value) ? value : undefined;
    case "q":
      return value.slice(0, MAX_Q);
    default:
      return value;
  }
}

export function decodeMomentFilters(params: URLSearchParams): MomentFilters {
  const out: MomentFilters = {};
  KEYS.forEach(([key, urlKey]) => {
    const value = clean(key, params.get(urlKey));
    if (value) out[key] = value;
  });
  return out;
}

export function encodeMomentFilters(filters: MomentFilters): URLSearchParams {
  const out = new URLSearchParams();
  KEYS.forEach(([key, urlKey]) => {
    const value = clean(key, filters[key] || null);
    if (value) out.set(urlKey, value);
  });
  return out;
}

/** Replaces the filter keys in `current` with `next`, keeping foreign params first. */
export function mergeMomentParams(current: URLSearchParams, next: URLSearchParams): URLSearchParams {
  const urlKeys = KEYS.map(([, urlKey]) => urlKey);
  const out = new URLSearchParams();
  current.forEach((value, key) => {
    if (urlKeys.indexOf(key) === -1) out.append(key, value);
  });
  next.forEach((value, key) => out.append(key, value));
  return out;
}

export function hasMomentFilters(filters: MomentFilters): boolean {
  return KEYS.some(([key]) => Boolean(filters[key]));
}

/** `&category=..&language=..&mood=..&tags=..&q=..` for the feed endpoints; "" when unfiltered. */
export function momentFilterQuery(filters?: MomentFilters): string {
  if (!filters) return "";
  return SERVER_KEYS.map(([key, param]) => {
    const value = clean(key, filters[key] || null);
    return value ? `&${param}=${encodeURIComponent(value)}` : "";
  }).join("");
}
