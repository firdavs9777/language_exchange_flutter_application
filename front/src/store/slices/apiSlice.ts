import { createApi, fetchBaseQuery, BaseQueryFn, FetchArgs, FetchBaseQueryError } from "@reduxjs/toolkit/query/react";
import { BASE_URL } from "../../constants";
import { RootState } from "../index";
import { logout, setCredentials } from "./authSlice";

const baseQuery = fetchBaseQuery({
  baseUrl: BASE_URL,
  prepareHeaders: (headers, { getState, endpoint }) => {
    const token = (getState() as RootState).auth.userInfo?.token;

    if (token) {
      headers.set("Authorization", `Bearer ${token}`);
    }

    // Don't set Content-Type for file uploads - let browser set it with boundary
    // The endpoint check helps identify file upload mutations
    return headers;
  },
  credentials: "include",
});

// Token refresh wrapper
// Debug logging for API calls
const isDev = process.env.NODE_ENV === 'development';

const loggedBaseQuery: typeof baseQuery = async (args, api, extraOptions) => {
  const startTime = Date.now();
  const url = typeof args === 'string' ? args : args.url;
  const method = typeof args === 'string' ? 'GET' : (args.method || 'GET');

  if (isDev) {
    console.log(`[API] >> ${method} ${url}`, typeof args !== 'string' ? args.body || '' : '');
  }

  const result = await baseQuery(args, api, extraOptions);
  const duration = Date.now() - startTime;

  if (isDev) {
    if (result.error) {
      console.error(`[API] << ${method} ${url} [${(result.error as any)?.status || 'ERR'}] ${duration}ms`, result.error);
    } else {
      console.log(`[API] << ${method} ${url} [OK] ${duration}ms`, result.data);
    }
  }

  return result;
};

// Token refresh wrapper
/**
 * Endpoints whose 401 means "the password you typed is wrong", not "your
 * session has expired".
 *
 * `PUT /auth/updatepassword` checks the CURRENT password itself and answers
 * 401 when it does not match. Read as an expired token, a typo in that field
 * would refresh and re-send the change (a second PASSWORD_UPDATE_FAILED
 * security event against the account) or, with no refresh token stored, sign
 * the user out mid-form. These go straight back to the caller, which shows the
 * server's own message — and that message also distinguishes the rare case of
 * a token that really had expired, since `protect` words its 401 differently.
 */
const CREDENTIAL_CHECKS = ["/api/v1/auth/updatepassword"];

function answersCredentials(args: any): boolean {
  const url = typeof args === "string" ? args : args && args.url;
  if (typeof url !== "string") return false;
  const path = url.split("?")[0];
  return CREDENTIAL_CHECKS.indexOf(path) > -1;
}

const baseQueryWithReauth: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  let result = await loggedBaseQuery(args, api, extraOptions);

  // 401 ONLY, never 403. The backend's `protect` middleware answers 401 for a
  // missing or expired token and 403 only for an authorization failure —
  // `authorize('admin')`, "you cannot ban yourself", "you cannot revoke your
  // own admin role". A refresh cannot turn a 403 into a 200 (the token was
  // fine, the action was not), so re-sending on 403 silently retries an action
  // the server already rejected, and logging out on 403 throws an admin out of
  // the console for pressing a button the backend declined. A 403 passes
  // straight through to the caller, which shows it.
  //
  // On 401 we refresh with the stored refresh token (POST /auth/refresh-token,
  // token in the body) and re-send the original request once. With no refresh
  // token stored (older session, an OAuth flow that didn't return one) there is
  // nothing to refresh with, so the session is over: log out.
  //
  // The one 403 that IS a session problem: the account was banned mid-session.
  // `protect`/`optionalAuth` tag that case with `code: "ACCOUNT_BANNED"` in the
  // body (a refresh can't fix it either — the token is fine, the account
  // isn't), so we log out on it below but still return the error unchanged so
  // the caller can show it.
  if (result.error && result.error.status === 401 && !answersCredentials(args)) {
    const userInfo = (api.getState() as RootState).auth.userInfo as any;
    const refreshToken = userInfo?.refreshToken;

    if (refreshToken) {
      const refreshResult = await baseQuery(
        {
          url: "/api/v1/auth/refresh-token",
          method: "POST",
          body: { refreshToken },
        },
        api,
        extraOptions
      );

      const refreshData = refreshResult.data as
        | { token?: string; refreshToken?: string }
        | undefined;

      if (refreshData?.token) {
        api.dispatch(
          setCredentials({
            ...userInfo,
            token: refreshData.token,
            // Backend may rotate the refresh token on refresh — keep the new
            // one if present, otherwise fall back to the existing value.
            refreshToken: refreshData.refreshToken || refreshToken,
          })
        );
        result = await baseQuery(args, api, extraOptions);
      } else {
        api.dispatch(logout());
      }
    } else {
      api.dispatch(logout());
    }
  }

  if (
    result.error &&
    result.error.status === 403 &&
    (result.error.data as any)?.code === "ACCOUNT_BANNED"
  ) {
    api.dispatch(logout());
    return result;
  }

  return result;
};

export const apiSlice = createApi({
  baseQuery: baseQueryWithReauth,
  tagTypes: [
    "Community",
    // The matching engine's "For you" feed. Deliberately separate from
    // "Community": the list invalidating on a wave or a follow must not throw
    // away a recommendation set the server spent 30 cached minutes on.
    "Recommendations",
    "Moments",
    "Chat",
    "User",
    "Stories",
    // Story highlights, separate from "Stories" on purpose: adding a story to
    // a highlight, renaming one or changing its cover refetches the highlight
    // rails only -- not the feed, my-stories and the archive, which the same
    // edit leaves untouched.
    "Highlights",
    "Comments",
    "Messages",
    "Conversations",
    "UserMessages",
    "Conversation",
    // The viewer's saved messages (GET /messages/bookmarks): user-wide, so its
    // own tag rather than refetching a thread on every bookmark change.
    "Bookmarks",
    // The shared per-conversation wallpaper (GET/PUT /conversations/:id/theme).
    // Its own tag: a theme save must refresh the pane's colours without
    // refetching a thread of messages, and a new message must not refetch a
    // wallpaper that did not change.
    "ChatTheme",
    "Learning",
    "Vocabulary",
    "Lessons",
    "Quizzes",
    // Admin console. AdminUserList covers the paginated lists (search, banned)
    // so a ban/role change refetches the table the moderator is looking at;
    // AdminUser covers a single user's detail drawer.
    "AdminUser",
    "AdminUserList",
    "AdminContent",
    "AdminStats",
    // Content desk (moments moderation) and the reports queue: separate from
    // AdminContent (clubs/gatherings) so a moment hide/unhide or a report
    // review doesn't refetch the club and gathering tables too.
    "AdminContentStats",
    "AdminMoments",
    "AdminReports",
    // Admin announcements (spec 2026-10-12 §5.3): the list, and one per id
    // for the editor, so saving one announcement doesn't refetch another.
    "AdminAnnouncements",
    "AdminAnnouncement",
    // GET /notifications/settings: its own tag so saving the notification
    // page does not refetch every "User" query (profile, visitors, blocks).
    // Gatherings and clubs (Phase 4). A list tag and a per-id tag each, so an
    // RSVP refreshes that gathering's page and the list -- not every club.
    "Gatherings",
    "Gathering",
    "Clubs",
    "Club",
    "NotificationSettings",
  ],
  refetchOnFocus: false,
  refetchOnReconnect: true,
  endpoints: () => ({}),
});
