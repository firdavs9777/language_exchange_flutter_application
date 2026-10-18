import { BASE_URL } from "../constants";
import { logout, setCredentials } from "./slices/authSlice";

/**
 * One silent token refresh, outside RTK Query: the socket's `tokenExpired`
 * push has no request to retry, so baseQueryWithReauth never sees it. Same
 * endpoint and body as apiSlice.ts. A new token re-creates the socket
 * (SocketProvider keys on it); a failure ends the session as before.
 */
export async function refreshSession(
  dispatch: (action: any) => any,
  getState: () => any
): Promise<boolean> {
  const userInfo = getState() && getState().auth && getState().auth.userInfo;
  const refreshToken = userInfo && userInfo.refreshToken;
  if (!refreshToken) {
    dispatch(logout(undefined));
    return false;
  }
  try {
    const res = await fetch(`${BASE_URL}/api/v1/auth/refresh-token`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    const body: any = res.ok ? await res.json() : null;
    if (body && body.token) {
      dispatch(
        setCredentials({
          ...userInfo,
          token: body.token,
          refreshToken: body.refreshToken || refreshToken,
        })
      );
      return true;
    }
  } catch (err) {
    // Network failure: same outcome as a refusal.
  }
  dispatch(logout(undefined));
  return false;
}
