/**
 * GET /api/v1/matching/daily -- the day's batch, chosen and cached server-side
 * until `nextRefreshAt` (midnight UTC). `user` is the USER_LIST_FIELDS
 * projection: raw `images`, no `imageUrls`. `matchReasons` are CODES
 * (lib/dailyMatches.js structuredReasons), not English.
 */
export interface DailyMatchUser {
  _id: string;
  name: string;
  images?: string[];
  native_language?: string;
  language_to_learn?: string;
  location?: { country?: string; city?: string };
  intents?: string[];
  [key: string]: any;
}

export interface DailyMatch {
  user: DailyMatchUser;
  matchReasons: string[];
  reciprocal?: boolean;
  lastActiveBucket?: string;
  /** null when the server has no rate for this person. */
  responseRate: number | null;
  boosted?: boolean;
}

export interface DailyMatchesResponse {
  success: boolean;
  /** The UTC day this batch belongs to (YYYY-MM-DD). */
  date: string;
  nextRefreshAt?: string;
  cached?: boolean;
  matches: DailyMatch[];
}
