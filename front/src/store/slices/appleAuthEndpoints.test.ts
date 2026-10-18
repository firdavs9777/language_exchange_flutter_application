import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { appleAuthApiSlice } from "./appleAuthSlice";
import { APPLE_WEB_LOGIN_URL } from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: string | undefined; auth: string | null };
function mockFetch(status = 200, body: any = { success: true, token: "t", refreshToken: "r", user: { _id: "u1" } }) {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push({
      url: req.url,
      method: req.method,
      body: req.clone ? await req.clone().text() : undefined,
      auth: req.headers && req.headers.get ? req.headers.get("authorization") : null,
    });
    return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
});

it("posts {identityToken, nonce, user} to /api/v1/auth/apple/web", async () => {
  const calls = mockFetch();
  const store = makeStore();
  const result: any = await store.dispatch(
    (appleAuthApiSlice.endpoints as any).appleWebLogin.initiate({
      identityToken: "id.tok",
      nonce: "n".repeat(43),
      user: { name: { firstName: "Ada", lastName: "Lovelace" } },
    })
  );
  expect(calls).toHaveLength(1);
  expect(new URL(calls[0].url).pathname).toBe(APPLE_WEB_LOGIN_URL);
  expect(APPLE_WEB_LOGIN_URL).toBe("/api/v1/auth/apple/web");
  expect(calls[0].method).toBe("POST");
  expect(JSON.parse(calls[0].body as string)).toEqual({
    identityToken: "id.tok",
    nonce: "n".repeat(43),
    user: { name: { firstName: "Ada", lastName: "Lovelace" } },
  });
  expect(result.data).toEqual({ success: true, token: "t", refreshToken: "r", user: { _id: "u1" } });
});

it("leaves `user` out when Apple sent none (every sign-in after the first)", async () => {
  const calls = mockFetch();
  await makeStore().dispatch(
    (appleAuthApiSlice.endpoints as any).appleWebLogin.initiate({ identityToken: "id.tok", nonce: "n".repeat(43) })
  );
  expect(JSON.parse(calls[0].body as string)).toEqual({ identityToken: "id.tok", nonce: "n".repeat(43) });
});

it("surfaces the 404 feature_disabled body as the error", async () => {
  mockFetch(404, { success: false, error: "Not found", code: "feature_disabled" });
  const result: any = await makeStore().dispatch(
    (appleAuthApiSlice.endpoints as any).appleWebLogin.initiate({ identityToken: "x", nonce: "n".repeat(43) })
  );
  expect(result.error).toMatchObject({ status: 404, data: { code: "feature_disabled" } });
});
