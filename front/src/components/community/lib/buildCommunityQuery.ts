/**
 * Pure param mapper for `GET /api/v1/auth/users` (Community discovery).
 *
 * THE CRITICAL RULE (confirmed against the API): param names are inverted
 * relative to naive expectation.
 *   - API `nativeLanguage=X`   -> finds users LEARNING X.
 *   - API `learningLanguage=Y` -> finds users who SPEAK Y natively.
 *
 * So a UI filter "partner's native language = X" must be sent as
 * `learningLanguage=X`, and a UI filter "partner is learning Y" must be sent
 * as `nativeLanguage=Y`.
 *
 * Default case (no explicit language filter selected): verified against the
 * app's `_buildFilterParams` (partner_discovery_tab.dart) — it sends
 * `matchLanguage=true` PLUS the current user's own languages assigned
 * DIRECTLY (not swapped) to the API params:
 *   nativeLanguage   = me.native_language   (finds users learning what I speak)
 *   learningLanguage = me.language_to_learn (finds native speakers of what I want to learn)
 */

export interface CommunityFilters {
  minAge?: number;
  maxAge?: number;
  gender?: string;
  nativeLanguage?: string;
  learningLanguage?: string;
  country?: string;
  topics?: string[];
  languageLevel?: string;
  onlineOnly?: boolean;
  newUsersOnly?: boolean;
  topicsAtLeast?: number;
  search?: string;
  sort?: 'recently_active';
}

export interface Me {
  native_language?: string;
  language_to_learn?: string;
}

export function buildCommunityQuery(
  filters: CommunityFilters,
  me: Me,
  page: number,
  limit: number
): Record<string, string> {
  const query: Record<string, string> = {};
  query.matchLanguage = 'true';

  const hasFilterNative =
    filters.nativeLanguage !== undefined && filters.nativeLanguage !== '';
  const hasFilterLearning =
    filters.learningLanguage !== undefined && filters.learningLanguage !== '';

  let apiNativeParam: string | undefined; // API nativeLanguage: finds users LEARNING this language
  let apiLearningParam: string | undefined; // API learningLanguage: finds users who SPEAK this natively

  if (hasFilterNative || hasFilterLearning) {
    // Explicit filters — apply only what was selected (inverted).
    if (hasFilterNative) apiLearningParam = filters.nativeLanguage;
    if (hasFilterLearning) apiNativeParam = filters.learningLanguage;
  } else {
    // Default: language-exchange matching using my own languages (direct, not swapped).
    apiNativeParam = me.native_language;
    apiLearningParam = me.language_to_learn;
  }

  if (apiNativeParam) query.nativeLanguage = apiNativeParam;
  if (apiLearningParam) query.learningLanguage = apiLearningParam;

  if (filters.minAge !== undefined && filters.minAge > 18) {
    query.minAge = String(filters.minAge);
  }
  if (filters.maxAge !== undefined && filters.maxAge < 100) {
    query.maxAge = String(filters.maxAge);
  }

  if (filters.gender) query.gender = filters.gender;
  if (filters.country) query.country = filters.country;
  if (filters.languageLevel) query.languageLevel = filters.languageLevel;
  if (filters.topics && filters.topics.length > 0) {
    query.topics = filters.topics.join(',');
  }
  if (filters.topicsAtLeast !== undefined) {
    query.topicsAtLeast = String(filters.topicsAtLeast);
  }
  if (filters.search) query.search = filters.search;
  if (filters.sort) query.sort = filters.sort;
  if (filters.onlineOnly) query.onlineOnly = 'true';
  if (filters.newUsersOnly) query.newUsersOnly = 'true';

  query.page = String(page);
  query.limit = String(limit);

  return query;
}
