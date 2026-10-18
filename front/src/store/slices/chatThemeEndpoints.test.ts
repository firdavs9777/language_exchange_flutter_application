/**
 * The shared conversation theme (wallpaper) endpoints, and the send path's
 * page-1 refetch.
 *
 * Same technique as chatActionsEndpoints.test.ts: dispatch `.initiate(...)`
 * against a real store with `global.fetch` mocked, then inspect the outgoing
 * Request. That is the only reliable way to see the URL/method/body an RTK
 * Query endpoint actually produces.
 *
 * Contract (backend controllers/conversations.js, `getConversationTheme` /
 * `setConversationTheme`):
 *   GET  /api/v1/conversations/:id/theme -> { success, data: { preset, ... } }
 *   PUT  /api/v1/conversations/:id/theme  body { theme: { preset, ... } }
 * `:id` may be a conversation id OR the other participant's user id — the
 * controller falls back to a participants lookup — but the web always passes
 * the conversation id, because the `themeChanged` socket payload is keyed by
 * it and the cache entry has to match.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { chatApiSlice } from "./chatSlice";
import { CONVERSATIONS_URL, MESSAGES_URL } from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
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
    // A FormData body cannot be read back as text by the whatwg-fetch
    // polyfill jsdom ships -- it throws, and RTK would report the send as a
    // FETCH_ERROR. The body is only interesting for the JSON requests here.
    let body: string | undefined;
    try {
      body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    } catch (error) {
      body = undefined;
    }
    calls.push({ url: req.url, method: req.method, body });
    // A message thread answers with an ARRAY (and pagination); everything
    // else with an object. `getConversation`'s merge reducer reads `data` as
    // a list, so one shape for both would crash the reducer, not the code
    // under test.
    const isThread = String(req.url).indexOf("/conversation/") !== -1;
    const payload = isThread
      ? { success: true, data: [], count: 0, pagination: { page: 1, totalPages: 3 } }
      : { success: true, data: {} };
    return new Response(JSON.stringify(payload), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("conversation theme endpoints", () => {
  it("getConversationTheme -> GET /api/v1/conversations/:id/theme", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversationTheme.initiate("conv-1")
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toContain(`${CONVERSATIONS_URL}/conv-1/theme`);
    expect(calls[0].method).toBe("GET");
  });

  it("setConversationTheme -> PUT the same URL with a { theme } body", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (chatApiSlice.endpoints as any).setConversationTheme.initiate({
        conversationId: "conv-1",
        theme: { preset: "gradient_ocean" },
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toContain(`${CONVERSATIONS_URL}/conv-1/theme`);
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      theme: { preset: "gradient_ocean" },
    });
  });

  it("exports the hooks the picker and the pane use", () => {
    const exports: any = require("./chatSlice");
    expect(typeof exports.useGetConversationThemeQuery).toBe("function");
    expect(typeof exports.useSetConversationThemeMutation).toBe("function");
  });

  it("tags the theme so a save refetches it", async () => {
    expect((apiSlice as any).internalActions).toBeDefined();

    const calls = mockFetch();
    const store = makeStore();
    // A live subscriber, as the chat pane is.
    store.dispatch(
      (chatApiSlice.endpoints as any).getConversationTheme.initiate("conv-1")
    );
    await flush();
    expect(calls.filter((c) => c.method === "GET")).toHaveLength(1);

    await store.dispatch(
      (chatApiSlice.endpoints as any).setConversationTheme.initiate({
        conversationId: "conv-1",
        theme: { preset: "cream" },
      })
    );
    await flush();
    expect(calls.filter((c) => c.method === "GET").length).toBeGreaterThan(1);
  });
});

describe("sending a message refreshes page 1, not the page being read", () => {
  it("createMessage refetches the newest page of the thread", async () => {
    const calls = mockFetch();
    const store = makeStore();

    // The reader has scrolled back to page 3 of the history.
    store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({
        senderId: "me",
        receiverId: "you",
        page: 3,
        limit: 50,
      })
    );
    await flush();
    calls.length = 0;

    await store.dispatch(
      (chatApiSlice.endpoints as any).createMessage.initiate({
        sender: "me",
        receiver: "you",
        message: "hi",
        type: "text",
      })
    );
    await flush();

    const threadGets = calls.filter(
      (c) => c.method === "GET" && c.url.indexOf(`${MESSAGES_URL}/conversation/me/you`) !== -1
    );
    expect(threadGets.length).toBeGreaterThan(0);
    // The new message is on page 1. Refetching page 3 would put it nowhere.
    expect(threadGets.some((c) => c.url.indexOf("page=1") !== -1)).toBe(true);
    expect(threadGets.some((c) => c.url.indexOf("page=3") !== -1)).toBe(false);
  });

  it("a media send finds the thread from the cache (its FormData has no sender)", async () => {
    const calls = mockFetch();
    const store = makeStore();

    store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({
        senderId: "me",
        receiverId: "you",
        page: 2,
        limit: 50,
      })
    );
    await flush();
    calls.length = 0;

    const formData = new FormData();
    formData.append("receiver", "you");
    formData.append("message", "look");
    await store.dispatch(
      (chatApiSlice.endpoints as any).sendMediaMessage.initiate(formData)
    );
    await flush();

    const threadGets = calls.filter(
      (c) => c.method === "GET" && c.url.indexOf(`${MESSAGES_URL}/conversation/me/you`) !== -1
    );
    expect(threadGets.some((c) => c.url.indexOf("page=1") !== -1)).toBe(true);
  });
});
