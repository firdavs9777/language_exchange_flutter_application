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

  // If we get a 401 or 403, try to refresh the token
  if (result.error && (result.error.status === 401 || result.error.status === 403)) {
    // Try to get a new token
    const refreshResult = await baseQuery(
      { url: "/api/v1/auth/refresh", method: "POST" },
      api,
      extraOptions
    );

    if (refreshResult.data) {
      // Store the new token
      const userInfo = (api.getState() as RootState).auth.userInfo;
      api.dispatch(setCredentials({
        ...userInfo,
        token: (refreshResult.data as any).token,
      }));

      // Retry the original query
      result = await baseQuery(args, api, extraOptions);
    } else {
      // Refresh failed, logout user
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
