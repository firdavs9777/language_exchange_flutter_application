/**
 * localStorage persistence for the Community filter sheet's `CommunityFilters`
 * (see `buildCommunityQuery.ts` for the shape). Mirrors the app's persisted
 * `community_filters` key so filter state survives reloads.
 */
import { CommunityFilters } from './buildCommunityQuery';

export const STORAGE_KEY = 'community_filters';

export const DEFAULT_FILTERS: CommunityFilters = {
  minAge: 18,
  maxAge: 100,
};

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/**
 * Reads and parses the persisted filters. Returns `DEFAULT_FILTERS` whenever
 * storage is empty, the JSON is corrupt, or the parsed value isn't a plain
 * object (e.g. a stray string/number/array/null literal).
 */
export function load(): CommunityFilters {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_FILTERS };

    const parsed = JSON.parse(raw);
    if (!isPlainObject(parsed)) return { ...DEFAULT_FILTERS };

    return parsed as CommunityFilters;
  } catch {
    return { ...DEFAULT_FILTERS };
  }
}

export function save(filters: CommunityFilters): void {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(filters));
}
