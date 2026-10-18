/**
 * The community list's state, written as URL search params.
 *
 * Filters, search, sort and the active tab used to live only in React state
 * plus `localStorage`, which meant a filtered list could not be linked, could
 * not be bookmarked, and lost itself on Back. This module is the one place
 * that decides how that state is spelled in a URL.
 *
 * Two rules keep the sync loop in `MainCommunity` from oscillating:
 *
 *  1. `encode` is canonical — the same state always produces the same param
 *     string, in the fixed `URL_KEYS` order, with defaults left out entirely.
 *  2. `decode` is total — anything it does not recognise (an unknown gender,
 *     an inverted age range, `online=true` instead of `online=1`) is dropped
 *     rather than passed through, so a hand-edited or stale link degrades to
 *     the parts that still make sense instead of poisoning the query.
 *
 * Together they make `encode(decode(encode(x))) === encode(x)`, which is what
 * lets the component compare param strings to decide whether to write at all.
 *
 * Nothing here touches a browser global: it takes and returns
 * `URLSearchParams`, so it is safe on the prerender path and testable as a
 * pure function.
 */
import { CommunityFilters } from './buildCommunityQuery';

/**
 * The tab set the list ships (`CommunitySubNav`'s `CommunityNavTab`).
 *
 * `foryou`, `all`, `serious`, `online` and `new` are rendered in place by the list;
 * `nearby` and `topics` are their own routes and only ever appear here when a
 * link or an old URL says so.
 */
export type CommunityUrlTab =
  | 'today'
  | 'foryou'
  | 'all'
  | 'serious'
  | 'online'
  | 'new'
  | 'nearby'
  | 'topics';

export interface CommunityUrlState {
  filters: CommunityFilters;
  search: string;
  sort?: 'recently_active';
  tab: CommunityUrlTab;
}

/** What `decode` found in a URL — every part is optional and may be absent. */
export interface CommunityUrlStatePatch {
  filters?: CommunityFilters;
  search?: string;
  sort?: 'recently_active';
  tab?: CommunityUrlTab;
}

/**
 * Every key this module owns, in the order `encode` writes them. Short and
 * stable: these appear in links people paste to each other, so renaming one
 * breaks every link already in the wild.
 */
export const URL_KEYS: string[] = [
  'native',
  'learning',
  'age',
  'gender',
  'country',
  'level',
  'topics',
  'mutual',
  'online',
  'new',
  'pair',
  'sort',
  'q',
  'tab',
];

const GENDERS = ['male', 'female', 'other'];
const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
const SORTS = ['recently_active'];
const TABS: CommunityUrlTab[] = [
  'today',
  'foryou',
  'all',
  'serious',
  'online',
  'new',
  'nearby',
  'topics',
];

/** Mirrors the filter sheet's own bounds (CommunityFilterSheet.tsx). */
const MIN_AGE = 18;
const MAX_AGE = 100;
const MAX_TOPICS_AT_LEAST = 10;
/** A link is not a bulk import — a runaway `topics=` list is truncated. */
const MAX_TOPICS = 20;
/** Free-text values (country, search) are capped so a URL stays a URL. */
const MAX_TEXT = 80;

/** Length-capped, otherwise verbatim — a URL is not a place for an essay. */
const clip = (value: unknown): string =>
  typeof value === 'string' ? value.slice(0, MAX_TEXT) : '';

const text = (value: unknown): string => clip(value).trim();

const isInt = (value: string): boolean => /^-?\d+$/.test(value.trim());

function cleanTopics(topics: unknown): string[] {
  if (!Array.isArray(topics)) return [];
  const seen: Record<string, true> = {};
  const out: string[] = [];
  for (const raw of topics) {
    const topic = text(raw);
    // A comma would split into two topics on the way back out.
    if (!topic || topic.indexOf(',') >= 0 || seen[topic]) continue;
    seen[topic] = true;
    out.push(topic);
    if (out.length === MAX_TOPICS) break;
  }
  return out;
}

function ageOf(value: unknown, fallback: number): number {
  const n = typeof value === 'number' ? value : Number.NaN;
  if (!Number.isFinite(n)) return fallback;
  return Math.min(MAX_AGE, Math.max(MIN_AGE, Math.round(n)));
}

/**
 * State -> params. Defaults (age 18-100, no sort, the `all` tab, every toggle
 * off) are omitted so an unfiltered list has a clean `/communities` URL.
 */
export function encodeCommunityState(
  state: Partial<CommunityUrlState>
): URLSearchParams {
  const params = new URLSearchParams();
  const filters: CommunityFilters = state.filters || {};

  const native = text(filters.nativeLanguage);
  if (native) params.set('native', native);

  const learning = text(filters.learningLanguage);
  if (learning) params.set('learning', learning);

  const minAge = ageOf(filters.minAge, MIN_AGE);
  const maxAge = ageOf(filters.maxAge, MAX_AGE);
  if (minAge <= maxAge && (minAge > MIN_AGE || maxAge < MAX_AGE)) {
    params.set('age', `${minAge}-${maxAge}`);
  }

  const gender = text(filters.gender).toLowerCase();
  if (GENDERS.indexOf(gender) >= 0) params.set('gender', gender);

  const country = text(filters.country);
  if (country) params.set('country', country);

  const level = text(filters.languageLevel).toUpperCase();
  if (LEVELS.indexOf(level) >= 0) params.set('level', level);

  const topics = cleanTopics(filters.topics);
  if (topics.length) params.set('topics', topics.join(','));

  const mutual =
    typeof filters.topicsAtLeast === 'number' && Number.isFinite(filters.topicsAtLeast)
      ? Math.min(MAX_TOPICS_AT_LEAST, Math.round(filters.topicsAtLeast))
      : 0;
  if (mutual > 0) params.set('mutual', String(mutual));

  if (filters.onlineOnly) params.set('online', '1');
  if (filters.newUsersOnly) params.set('new', '1');
  if (filters.reciprocal) params.set('pair', '1');

  const sort = text(state.sort);
  if (SORTS.indexOf(sort) >= 0) params.set('sort', sort);

  // `q` keeps its whitespace: the search box is bound straight to this param,
  // and trimming here would eat the space the moment it is typed.
  const search = clip(state.search);
  if (search.trim()) params.set('q', search);

  const tab = text(state.tab).toLowerCase() as CommunityUrlTab;
  // `today` is the default landing, so it is never spelled out; `all` now is,
  // or a bare /communities would mean Today and All could never be reached.
  if (tab !== 'today' && TABS.indexOf(tab) >= 0) params.set('tab', tab);

  return params;
}

/**
 * Params -> state. Only what the URL actually said comes back: `filters` is
 * absent (not an empty object) when no filter key was present and valid, which
 * is how the caller tells "this URL has no opinion" apart from "this URL says
 * no filters".
 */
export function decodeCommunityState(
  params: URLSearchParams
): CommunityUrlStatePatch {
  const patch: CommunityUrlStatePatch = {};
  const filters: CommunityFilters = {};
  let hasFilter = false;

  const read = (key: string): string => text(params.get(key));

  const native = read('native');
  if (native) {
    filters.nativeLanguage = native;
    hasFilter = true;
  }

  const learning = read('learning');
  if (learning) {
    filters.learningLanguage = learning;
    hasFilter = true;
  }

  const age = read('age');
  if (age) {
    const parts = age.split('-');
    if (parts.length === 2 && isInt(parts[0]) && isInt(parts[1])) {
      const min = Number(parts[0]);
      const max = Number(parts[1]);
      if (min >= MIN_AGE && max <= MAX_AGE && min <= max) {
        filters.minAge = min;
        filters.maxAge = max;
        hasFilter = true;
      }
    }
  }

  const gender = read('gender').toLowerCase();
  if (GENDERS.indexOf(gender) >= 0) {
    filters.gender = gender;
    hasFilter = true;
  }

  const country = read('country');
  if (country) {
    filters.country = country;
    hasFilter = true;
  }

  const level = read('level').toUpperCase();
  if (LEVELS.indexOf(level) >= 0) {
    filters.languageLevel = level;
    hasFilter = true;
  }

  const topics = cleanTopics(read('topics').split(','));
  if (topics.length) {
    filters.topics = topics;
    hasFilter = true;
  }

  const mutual = read('mutual');
  if (isInt(mutual)) {
    const count = Math.min(MAX_TOPICS_AT_LEAST, Number(mutual));
    if (count > 0) {
      filters.topicsAtLeast = count;
      hasFilter = true;
    }
  }

  if (read('online') === '1') {
    filters.onlineOnly = true;
    hasFilter = true;
  }
  if (read('new') === '1') {
    filters.newUsersOnly = true;
    hasFilter = true;
  }
  if (read('pair') === '1') {
    filters.reciprocal = true;
    hasFilter = true;
  }

  if (hasFilter) patch.filters = filters;

  const sort = read('sort');
  if (SORTS.indexOf(sort) >= 0) patch.sort = sort as 'recently_active';

  const search = clip(params.get('q'));
  if (search.trim()) patch.search = search;

  const tab = read('tab').toLowerCase() as CommunityUrlTab;
  if (TABS.indexOf(tab) >= 0) patch.tab = tab;

  return patch;
}

/**
 * Does this URL say anything about the list at all? The mount path uses it to
 * decide whether the stored filters may fill in: a URL that carries state is
 * the whole truth, so a shared link never picks up the recipient's own saved
 * filters.
 */
export function hasCommunityUrlState(params: URLSearchParams): boolean {
  const decoded = decodeCommunityState(params);
  return (
    decoded.filters !== undefined ||
    decoded.search !== undefined ||
    decoded.sort !== undefined ||
    decoded.tab !== undefined
  );
}

/**
 * Swap this module's keys inside an existing query while leaving anything else
 * (campaign params, a stray `ref`) exactly where it was. Foreign params keep
 * their original order and come first, so two calls with equal state produce
 * an identical string — which is the comparison the write effect relies on.
 */
export function mergeCommunityParams(
  current: URLSearchParams,
  encoded: URLSearchParams
): URLSearchParams {
  const next = new URLSearchParams();
  current.forEach((value, key) => {
    if (URL_KEYS.indexOf(key) === -1) next.append(key, value);
  });
  encoded.forEach((value, key) => {
    next.append(key, value);
  });
  return next;
}
