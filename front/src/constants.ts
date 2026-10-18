export const BASE_URL = process.env.REACT_APP_API_URL || "http://localhost:5003";
export const MOMENTS_URL = "/api/v1/moments";
// Comment routes are also mounted directly (routes/comment.js is registered
// both under /api/v1/moments/:momentId/comments and, standalone, here) --
// endpoints that only need a comment id (like/react/translate/replies/image)
// use this base instead of nesting under a momentId they don't have.
export const COMMENTS_URL = "/api/v1/comments";
export const USERS_URL = "/api/v1/users";
export const COMMUNITY_URL = "/api/v1/auth/users";
export const MESSAGES_URL = "/api/v1/messages";
export const CONVERSATIONS_URL = "/api/v1/conversations";
export const LOGIN_URL = "/api/v1/auth/login";
export const REGISTER_URL = "/api/v1/auth/register";
export const LOGOUT_URL = "/api/v1/auth/logout";
export const ACCEPT_TERMS_URL = "/api/v1/auth/accept-terms";

// Web Google login: the callback carries a single-use code (60 s) that this
// exchanges for { token, refreshToken, user }. Replaces ?token= in the URL.
export const GOOGLE_EXCHANGE_URL = "/api/v1/auth/google/exchange";
// Web Sign in with Apple (Apple JS identity token + the nonce the page made).
// 404 {code:'feature_disabled'} while WEB_APPLE_SIGNIN_ENABLED is off.
export const APPLE_WEB_LOGIN_URL = "/api/v1/auth/apple/web";

// router.post('/forgot-password', forgotPassword);
// router.post('/verify-reset-code', verifyResetCode);
// router.post('/reset-password', resetPassword);
export const SEND_EMAIL_CODE = "/api/v1/auth/forgot-password";
// Backend exposes two distinct flows. /sendCodeEmail + /verifyEmailCode are the
// legacy registration verification endpoints; /verify-reset-code is the
// password-reset-only verifier. Don't conflate them — see usersSlice.
export const REGISTER_EMAIL_CODE = "/api/v1/auth/sendCodeEmail";
export const VERIFY_REGISTRATION_CODE = "/api/v1/auth/verifyEmailCode";
export const CONFIRM_EMAIL_CODE = "/api/v1/auth/verify-reset-code";
export const RESET_USER_PASSWORD = "/api/v1/auth/reset-password";
export const COMMENTS = "comments";
export const USER_PROFILE_URL = "/api/v1/auth/me";
export const USER_PROFILE_UPDATE = "/api/v1/auth/updatedetails";
// Push notification preferences (GET + PUT, flat body merged per key).
// /auth/updatedetails ignores `notificationSettings`, so this is the only
// writer -- the same one the mobile app uses.
export const NOTIFICATION_SETTINGS_URL = "/api/v1/notifications/settings";
export const STORIES_FEED = "/api/v1/stories/feed";
export const MY_STORIES = "/api/v1/stories/my-stories";
export const MAIN_STORIES = "/api/v1/stories";
export const USER_STORIES = "/api/v1/stories/user/";

// Community & Discovery
export const COMMUNITY_NEARBY = "/api/v1/community/nearby";
// NOTE: singular "wave" — real backend route for POST (send a wave).
export const COMMUNITY_WAVES = "/api/v1/community/wave";
// Plural "waves" — real backend routes for GET (list) / PUT (mark read).
// Distinct from COMMUNITY_WAVES on purpose; do not conflate the two.
export const COMMUNITY_WAVES_LIST = "/api/v1/community/waves";
export const COMMUNITY_TOPICS = "/api/v1/community/topics";
export const LANGUAGES_URL = "/api/v1/languages";
export const COMMUNITY_COUNT_URL = "/api/v1/auth/users/count";

// Profile Visitors
export const PROFILE_VISITORS = "/api/v1/auth/users";

// Learning (if implementing)
export const LEARNING_URL = "/api/v1/learning";

// VIP
export const VIP_URL = "/api/v1/vip";
// Public: displays real store prices before login. See
// language_exchange_backend_application routes/purchases.js:37.
export const VIP_PLANS_URL = "/api/v1/purchases/plans";

// Block & Report
export const BLOCK_USER_URL = "/api/v1/users";
// Reporting a person, a message or a moment is ONE backend route:
// `POST /api/v1/reports` (routes/report.js), body
// `{ type, reportId, reportedUser, reason, description }`. There has never
// been a `/users/:id/report`, which is why every report the web app sent
// before this 404'd. Same path as ADMIN_REPORTS_URL below — the difference is
// only which verbs an admin may use on it.
export const REPORTS_URL = "/api/v1/reports";

// Username & Geocode
export const CHECK_USERNAME_URL = "/api/v1/auth/users/check-username";
export const GEOCODE_REVERSE_URL = "/api/v1/geocode/reverse";
export const GEOCODE_FORWARD_URL = "/api/v1/geocode/forward";

export const PUBLIC_STATS_URL = "/api/v1/public/stats";
// 모임: gatherings and clubs (be/routes/gatherings.js, be/routes/clubs.js).
// Both behind GATHERINGS_ENABLED (404 while off) and, on the website, behind
// the webGatheringsEnabled flag (src/utils/webFlags.ts).
export const GATHERINGS_URL = "/api/v1/gatherings";
export const CLUBS_URL = "/api/v1/clubs";
export const ANALYTICS_EVENTS_URL = "/api/v1/analytics/events";

// Admin console. Every route below lives under `protect` + `authorize('admin')`
// server-side (routes/admin.js); the client-side guard is cosmetic.
export const ADMIN_URL = "/api/v1/admin";
// The reports router (routes/report.js) is mounted separately from `/admin`
// in server.js (`app.use('/api/v1/reports', reports)`), not nested under
// ADMIN_URL — its admin-only routes still sit behind `authorizeRole('admin')`.
export const ADMIN_REPORTS_URL = "/api/v1/reports";
