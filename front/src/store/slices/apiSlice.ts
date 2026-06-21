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
const baseQueryWithReauth: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  let result = await loggedBaseQuery(args, api, extraOptions);

  // If we get a 401 or 403, try to refresh the access token using the stored
  // refresh token. Backend route is /auth/refresh-token and requires the
  // refresh token in the body. If we don't have one stored (older session,
  // OAuth flow that didn't return one), fall straight through to logout.
  if (result.error && (result.error.status === 401 || result.error.status === 403)) {
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

  return result;
};

export const apiSlice = createApi({
  baseQuery: baseQueryWithReauth,
  tagTypes: [
    "Community",
    "Moments",
    "Chat",
    "User",
    "Stories",
    "Messages",
    "Conversations",
    "UserMessages",
    "Conversation",
    "Learning",
    "Vocabulary",
    "Lessons",
    "Quizzes",
  ],
  refetchOnFocus: false,
  refetchOnReconnect: true,
  endpoints: () => ({}),
});
