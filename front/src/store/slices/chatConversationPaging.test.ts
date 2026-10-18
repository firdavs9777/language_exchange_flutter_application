/**
 * `getConversation` used to ask for one page and keep one page: the backend's
 * default limit is 50, so on a thread longer than that everything older was
 * unreachable on the web. The endpoint now follows RTK Query's infinite
 * pattern — one cache entry per conversation, keyed by the two ids, with each
 * older page merged in FRONT of what is already there.
 *
 * Asserted against a real store with `global.fetch` mocked (the technique
 * chatActionsEndpoints.test.ts and usersEndpoints.test.ts use), because the
 * merge only exists inside the cache entry RTK Query builds.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { chatApiSlice } from "./chatSlice";

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

const msg = (id: string, createdAt: string, extra: any = {}) => ({
  _id: id,
  message: id,
  createdAt,
  sender: { _id: "me", name: "Me" },
  receiver: { _id: "u2", name: "Ada" },
  ...extra,
});

/** Page 1 is the NEWEST page; page 2 the one before it (the backend's order). */
const PAGES: { [page: string]: any } = {
  "1": {
    success: true,
    count: 2,
    total: 4,
    pagination: { currentPage: 1, totalPages: 2, limit: 2, hasNextPage: true, hasPrevPage: false },
    data: [msg("m3", "2026-09-20T10:00:00.000Z"), msg("m4", "2026-09-20T11:00:00.000Z")],
  },
  "2": {
    success: true,
    count: 2,
    total: 4,
    pagination: { currentPage: 2, totalPages: 2, limit: 2, hasNextPage: false, hasPrevPage: true },
    data: [msg("m1", "2026-09-19T10:00:00.000Z"), msg("m2", "2026-09-19T11:00:00.000Z")],
  },
};

type Captured = { url: string };

function mockFetch(pages: { [page: string]: any } = PAGES): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push({ url: req.url });
    const page = new URL(req.url).searchParams.get("page") || "1";
    return new Response(JSON.stringify(pages[page] || pages["1"]), {
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

const ARGS = { senderId: "me", receiverId: "u2", limit: 2 };

const ids = (state: any) =>
  ((chatApiSlice.endpoints as any).getConversation.select({ ...ARGS, page: 1 })(state).data
    ?.data || []).map((m: any) => m._id);

describe("getConversation paging", () => {
  it("asks the backend for the page it was given", async () => {
    const calls = mockFetch();
    const store = makeStore();

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 2 })
    );

    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/messages/conversation/me/u2");
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("limit")).toBe("2");
  });

  it("merges page 2 in front of page 1, oldest first, with no duplicates", async () => {
    mockFetch();
    const store = makeStore();

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 1 })
    );
    expect(ids(store.getState())).toEqual(["m3", "m4"]);

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 2 })
    );

    expect(ids(store.getState())).toEqual(["m1", "m2", "m3", "m4"]);
  });

  it("keeps both pages in ONE cache entry, keyed by the conversation", async () => {
    mockFetch();
    const store = makeStore();

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 1 })
    );
    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 2 })
    );

    const queries = (store.getState() as any)[apiSlice.reducerPath].queries;
    const conversationKeys = Object.keys(queries).filter((k) =>
      k.startsWith("getConversation")
    );
    expect(conversationKeys).toHaveLength(1);
    expect(conversationKeys[0]).toContain("me");
    expect(conversationKeys[0]).toContain("u2");
  });

  it("a second conversation gets its own entry", async () => {
    mockFetch();
    const store = makeStore();

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 1 })
    );
    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({
        senderId: "me",
        receiverId: "u9",
        page: 1,
        limit: 2,
      })
    );

    const queries = (store.getState() as any)[apiSlice.reducerPath].queries;
    expect(
      Object.keys(queries).filter((k) => k.startsWith("getConversation"))
    ).toHaveLength(2);
  });

  it("refetching the newest page updates messages in place instead of duplicating them", async () => {
    mockFetch();
    const store = makeStore();

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 1 })
    );
    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 2 })
    );

    // The same newest page comes back with a read receipt on m4.
    mockFetch({
      ...PAGES,
      "1": {
        ...PAGES["1"],
        data: [
          msg("m3", "2026-09-20T10:00:00.000Z"),
          msg("m4", "2026-09-20T11:00:00.000Z", { read: true }),
        ],
      },
    });
    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate(
        { ...ARGS, page: 1 },
        { forceRefetch: true }
      )
    );

    expect(ids(store.getState())).toEqual(["m1", "m2", "m3", "m4"]);
    const entry = (chatApiSlice.endpoints as any).getConversation.select({
      ...ARGS,
      page: 1,
    })(store.getState());
    expect(entry.data.data[3].read).toBe(true);
    expect(entry.data.total).toBe(4);
    expect(entry.data.pagination.totalPages).toBe(2);
  });

  it("refetches when only the page changed", async () => {
    const calls = mockFetch();
    const store = makeStore();

    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 1 })
    );
    await store.dispatch(
      (chatApiSlice.endpoints as any).getConversation.initiate({ ...ARGS, page: 2 })
    );

    expect(calls.map((c) => new URL(c.url).searchParams.get("page"))).toEqual(["1", "2"]);
  });
});
