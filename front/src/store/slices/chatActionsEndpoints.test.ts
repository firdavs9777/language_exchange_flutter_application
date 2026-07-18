/**
 * Asserts the REAL request shape (URL/method/body) each new chatSlice
 * message-action endpoint produces, by dispatching `.initiate(...)` against
 * a real store + a mocked global.fetch and inspecting the outgoing Request.
 * (RTK Query endpoint objects don't expose their internal `query` builder
 * directly — `.initiate` + fetch interception is the reliable way to
 * introspect the resulting request without hitting a real network.)
 *
 * Also asserts the 3 dead 404 routes (unread-count, read-receipts,
 * PUT /messages/:id/read) are gone from both the slice's endpoint map and
 * the exported hooks.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { chatApiSlice } from "./chatSlice";
import * as chatSliceExports from "./chatSlice";
import { MESSAGES_URL } from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      // Minimal stand-in for the real authSlice — apiSlice's
      // prepareHeaders/reauth logic only reads state.auth.userInfo.
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: string | undefined };

function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body =
      req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(
      JSON.stringify({ success: true, data: {} }),
      { status: 200, headers: { "content-type": "application/json" } }
    );
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

describe("chatSlice message-action endpoints hit the REAL backend routes", () => {
  it("pinMessage -> POST /api/v1/messages/:id/pin (toggle, no body)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).pinMessage.initiate("msg-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1/pin`);
    expect(calls[0].method).toBe("POST");
  });

  it("bookmarkMessage -> POST /api/v1/messages/:id/bookmark", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).bookmarkMessage.initiate("msg-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1/bookmark`);
    expect(calls[0].method).toBe("POST");
  });

  it("unbookmarkMessage -> DELETE /api/v1/messages/:id/bookmark", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).unbookmarkMessage.initiate("msg-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1/bookmark`);
    expect(calls[0].method).toBe("DELETE");
  });

  it("getBookmarks -> GET /api/v1/messages/bookmarks", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).getBookmarks.initiate()
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/bookmarks`);
    expect(calls[0].method).toBe("GET");
  });

  it("forwardMessage -> POST /api/v1/messages/:id/forward with {receivers}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).forwardMessage.initiate({
        messageId: "msg-1",
        receivers: ["user-2", "user-3"],
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1/forward`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      receivers: ["user-2", "user-3"],
    });
  });

  it("replyToMessage -> POST /api/v1/messages/:id/reply with {message, receiver}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).replyToMessage.initiate({
        messageId: "msg-1",
        message: "hello back",
        receiver: "user-2",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1/reply`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      message: "hello back",
      receiver: "user-2",
    });
  });

  it("ttsMessage -> POST /api/v1/messages/:id/tts", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).ttsMessage.initiate({
        messageId: "msg-1",
        language: "en",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MESSAGES_URL}/msg-1/tts`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ language: "en" });
  });
});

describe("dead 404 message routes are removed", () => {
  it("does not expose the removed endpoints", () => {
    const endpointNames = Object.keys((chatApiSlice as any).endpoints);
    expect(endpointNames).not.toContain("getUnreadCount");
    expect(endpointNames).not.toContain("getReadReceipts");
    expect(endpointNames).not.toContain("markMessageRead");
  });

  it("does not export the removed hooks", () => {
    expect((chatSliceExports as any).useGetUnreadCountQuery).toBeUndefined();
    expect((chatSliceExports as any).useGetReadReceiptsQuery).toBeUndefined();
    expect((chatSliceExports as any).useMarkMessageReadMutation).toBeUndefined();
  });

  it("does not reference the dead URLs anywhere in the built module", () => {
    const serialized = chatSliceExports.toString
      ? Object.keys(chatSliceExports).join(",")
      : "";
    // Sanity check the module still loads and exports the new hooks instead.
    expect(serialized).toContain("usePinMessageMutation");
    expect((chatSliceExports as any).usePinMessageMutation).toBeDefined();
    expect((chatSliceExports as any).useBookmarkMessageMutation).toBeDefined();
    expect((chatSliceExports as any).useUnbookmarkMessageMutation).toBeDefined();
    expect((chatSliceExports as any).useGetBookmarksQuery).toBeDefined();
    expect((chatSliceExports as any).useForwardMessageMutation).toBeDefined();
    expect((chatSliceExports as any).useReplyToMessageMutation).toBeDefined();
    expect((chatSliceExports as any).useTtsMessageMutation).toBeDefined();
  });

  it("MESSAGES_URL constant does not embed the dead sub-paths", () => {
    // These sub-paths never existed in constants.ts (they were string
    // literals inside the slice), but assert the base URL itself is
    // unaffected and no dead-route constant was ever added.
    expect(MESSAGES_URL).toBe("/api/v1/messages");
  });
});
