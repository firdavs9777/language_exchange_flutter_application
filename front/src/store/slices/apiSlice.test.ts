/**
 * `baseQueryWithReauth` is the one place in the client that can send a request
 * the caller never asked for. This pins exactly when it may do that.
 *
 * The backend's `protect` middleware answers 401 for a missing or expired
 * token and 403 only for an authorization failure (`authorize('admin')`, "you
 * cannot ban yourself", "you cannot revoke your own admin role"). A refresh
 * cannot turn a 403 into a 200 — the token was fine, the action was not — so
 * re-sending on 403 is a silent retry of a rejected moderation action against
 * a backend that already said no, and logging out on 403 throws an admin out
 * of the console for pressing a button the server declined.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import authReducer from "./authSlice";

// A probe endpoint so the test exercises the real base query rather than a
// hand-rolled stand-in. It is a mutation because that is the shape that hurts:
// a re-sent GET is wasteful, a re-sent PUT is a repeated action.
const probeSlice: any = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    probeAction: builder.mutation({
      query: () => ({ url: "/api/v1/admin/users/u1/role", method: "PUT", body: { role: "user" } }),
      extraOptions: { maxRetries: 0 },
    }),
  }),
});

const SESSION = {
  user: { _id: "me", role: "admin" },
  token: "old-token",
  refreshToken: "refresh-1",
};

function makeStore(userInfo: any = SESSION) {
  window.localStorage.setItem("userInfo", JSON.stringify(userInfo));
  return configureStore({
    reducer: { [apiSlice.reducerPath]: apiSlice.reducer, auth: authReducer },
    preloadedState: { auth: { userInfo } } as any,
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; auth: string | null };

/** Queue one response per call; the last one repeats if the queue runs dry. */
function mockFetch(responses: Array<{ status: number; body: any }>): Captured[] {
  const calls: Captured[] = [];
  let index = 0;
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push({
      url: req.url,
      method: req.method,
      auth: req.headers && req.headers.get ? req.headers.get("authorization") : null,
    });
    const next = responses[Math.min(index, responses.length - 1)];
    index += 1;
    return new Response(JSON.stringify(next.body), {
      status: next.status,
      headers: { "content-type": "application/json" },
    });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  window.localStorage.clear();
  jest.restoreAllMocks();
});

it("never re-sends a request the backend refused with 403", async () => {
  const calls = mockFetch([{ status: 403, body: { success: false, message: "You cannot revoke your own admin role" } }]);
  const store = makeStore();

  const result: any = await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  // One request. Not a refresh, and above all not a second PUT.
  expect(calls).toHaveLength(1);
  expect(calls[0].method).toBe("PUT");
  expect(result.error.status).toBe(403);
  expect((result.error.data as any).message).toBe("You cannot revoke your own admin role");
});

it("keeps the session on a 403: the token was valid, the action was not", async () => {
  mockFetch([{ status: 403, body: { success: false, message: "Not authorized" } }]);
  const store = makeStore();

  await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  expect((store.getState() as any).auth.userInfo).toBeTruthy();
});

it("does not log out on 403 even when no refresh token is stored", async () => {
  mockFetch([{ status: 403, body: { success: false, message: "Not authorized" } }]);
  const store = makeStore({ user: { _id: "me" }, token: "old-token" });

  const result: any = await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  expect(result.error.status).toBe(403);
  expect((store.getState() as any).auth.userInfo).toBeTruthy();
});

it("logs out on a 403 tagged ACCOUNT_BANNED, without refreshing or re-sending", async () => {
  const calls = mockFetch([
    { status: 403, body: { success: false, message: "Your account has been suspended.", code: "ACCOUNT_BANNED" } },
  ]);
  const store = makeStore();

  const result: any = await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  // One request. Not a refresh, and above all not a second PUT.
  expect(calls).toHaveLength(1);
  expect(result.error.status).toBe(403);
  expect((result.error.data as any).code).toBe("ACCOUNT_BANNED");
  expect((store.getState() as any).auth.userInfo).toBeNull();
});

it("does not log out on a 403 without the ACCOUNT_BANNED code", async () => {
  mockFetch([{ status: 403, body: { success: false, message: "Not authorized" } }]);
  const store = makeStore();

  await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  expect((store.getState() as any).auth.userInfo).toBeTruthy();
});

it("refreshes and re-sends exactly once on 401", async () => {
  const calls = mockFetch([
    { status: 401, body: { success: false, message: "Not authorized" } },
    { status: 200, body: { token: "new-token", refreshToken: "refresh-2" } },
    { status: 200, body: { success: true, data: { newRole: "user" } } },
  ]);
  const store = makeStore();

  const result: any = await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  expect(calls).toHaveLength(3);
  expect(new URL(calls[1].url).pathname).toBe("/api/v1/auth/refresh-token");
  // The original request, re-sent once, carrying the refreshed token.
  expect(new URL(calls[2].url).pathname).toBe("/api/v1/admin/users/u1/role");
  expect(calls[2].method).toBe("PUT");
  expect(calls[2].auth).toBe("Bearer new-token");
  expect(result.error).toBeUndefined();
  expect((store.getState() as any).auth.userInfo.token).toBe("new-token");
});

it("logs out on a 401 with no refresh token", async () => {
  const calls = mockFetch([{ status: 401, body: { success: false, message: "Not authorized" } }]);
  const store = makeStore({ user: { _id: "me" }, token: "old-token" });

  await store.dispatch(probeSlice.endpoints.probeAction.initiate({}));

  expect(calls).toHaveLength(1);
  expect((store.getState() as any).auth.userInfo).toBeNull();
});

// PUT /auth/updatepassword answers 401 for a wrong CURRENT password — the
// controller's own "Current password is incorrect", not `protect`'s expired
// token. Read as an expired session, a typo in that field would refresh and
// re-send the password change (logging a second PASSWORD_UPDATE_FAILED
// security event against the account) or, with no refresh token stored, sign
// the user out mid-form. The caller gets the 401 and the server's message.
const passwordSlice: any = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    probePassword: builder.mutation({
      query: () => ({
        url: "/api/v1/auth/updatepassword",
        method: "PUT",
        body: { currentPassword: "wrong", newPassword: "Abcdefg1" },
      }),
      extraOptions: { maxRetries: 0 },
    }),
  }),
});

it("hands a wrong current password back to the form instead of refreshing", async () => {
  const calls = mockFetch([
    { status: 401, body: { success: false, message: "Current password is incorrect" } },
  ]);
  const store = makeStore();

  const result: any = await store.dispatch(
    passwordSlice.endpoints.probePassword.initiate({})
  );

  expect(calls).toHaveLength(1);
  expect(result.error.status).toBe(401);
  expect(result.error.data.message).toBe("Current password is incorrect");
  expect((store.getState() as any).auth.userInfo.token).toBe("old-token");
});

it("does not sign anyone out over a mistyped current password", async () => {
  const calls = mockFetch([
    { status: 401, body: { success: false, message: "Current password is incorrect" } },
  ]);
  const store = makeStore({ user: { _id: "me" }, token: "old-token" });

  await store.dispatch(passwordSlice.endpoints.probePassword.initiate({}));

  expect(calls).toHaveLength(1);
  expect((store.getState() as any).auth.userInfo).toBeTruthy();
});
