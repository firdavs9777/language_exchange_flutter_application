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
  /**
   * "Serious learners" segment: active in the last 7 days. Set by the Serious
   * tab, never stored or written to the URL (the tab name says it).
   */
  activeWithin?: '7d';
  topicsAtLeast?: number;
  search?: string;
  /** `smart` is only ever the page's default while appConfig.smartSortEnabled is on. */
  sort?: 'recently_active' | 'smart';
  /**
   * Strict pairs: they speak what I learn AND learn what I speak
   * (controllers/users.js `reciprocal=true`).
   */
  reciprocal?: boolean;
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

  const hasFilterNative =
    filters.nativeLanguage !== undefined && filters.nativeLanguage !== '';
  const hasFilterLearning =
    filters.learningLanguage !== undefined && filters.learningLanguage !== '';

  let apiNativeParam: string | undefined; // API nativeLanguage: finds users LEARNING this language
  let apiLearningParam: string | undefined; // API learningLanguage: finds users who SPEAK this natively

  if (hasFilterNative && hasFilterLearning) {
    // BOTH explicit: they must both hold. matchLanguage=true would OR them --
    // "native Korean" + "learning English" came back as anyone who speaks
    // Korean plus anyone learning English. Without matchLanguage the server
    // takes its direct branch, which ANDs the two and reads each param in its
    // plain meaning (native = native, learning = learning), by substring --
    // so "Chinese" still covers "Chinese (Simplified)".
    query.nativeLanguage = filters.nativeLanguage as string;
    query.learningLanguage = filters.learningLanguage as string;
  } else {
    query.matchLanguage = 'true';
    if (hasFilterNative || hasFilterLearning) {
      // One explicit filter — inverted, per the rule above.
      if (hasFilterNative) apiLearningParam = filters.nativeLanguage;
      if (hasFilterLearning) apiNativeParam = filters.learningLanguage;
    } else {
      // Default: language-exchange matching using my own languages (direct, not swapped).
      apiNativeParam = me.native_language;
      apiLearningParam = me.language_to_learn;
    }
    if (apiNativeParam) query.nativeLanguage = apiNativeParam;
    if (apiLearningParam) query.learningLanguage = apiLearningParam;
  }

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
  // The server has never read `newUsersOnly`; it honours `joinedWithin=7d|30d`
  // (controllers/users.js). Sending the old name made the New tab return the
  // All list. 7d is the app's New members segment and the card's New badge.
  if (filters.newUsersOnly) query.joinedWithin = '7d';
  // The app's PartnerSegment.serious (controllers/users.js reads 7d/30d).
  if (filters.activeWithin) query.activeWithin = filters.activeWithin;
  if (filters.reciprocal) query.reciprocal = 'true';

  query.page = String(page);
  query.limit = String(limit);

  return query;
}

/**
 * Filters only VIP accounts may use. GET /users ignores `country` from free
 * callers (backend controllers/users.js, tier via lib/tier.js), so a free
 * user's saved or linked country is neither sent nor shown/counted as active.
 * The saved value itself is kept, so it applies again after an upgrade.
 */
export const VIP_ONLY_FILTERS: (keyof CommunityFilters)[] = ['country'];

export function withoutVipOnlyFilters(
  filters: CommunityFilters,
  isVip: boolean
): CommunityFilters {
  if (isVip) return filters;
  if (!VIP_ONLY_FILTERS.some((key) => filters[key] !== undefined)) return filters;
  const next: CommunityFilters = { ...filters };
  VIP_ONLY_FILTERS.forEach((key) => {
    delete next[key];
  });
  return next;
}
