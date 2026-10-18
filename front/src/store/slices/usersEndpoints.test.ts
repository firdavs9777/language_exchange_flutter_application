/**
 * The block and report endpoints, asserted against the REAL backend routes.
 *
 * Three of them were wrong and each one failed silently: reporting posted to
 * `/users/:id/report` (no such route — routes/report.js mounts the reports
 * router at /api/v1/reports), the blocked list read `/users/blocked` (the
 * router's only GET is `/:userId/blocked`), and nothing at all asked whether
 * a person was already blocked. A 404 from RTK Query lands in `isError`,
 * which none of these call sites rendered, so the UI reported success.
 *
 * Same technique as chatActionsEndpoints.test.ts: dispatch `.initiate(...)`
 * against a real store with `global.fetch` mocked, and read the Request that
 * comes out. It is the only way to see the URL and body RTK Query actually
 * builds.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { usersApiSlice } from "./usersSlice";
import * as usersSliceExports from "./usersSlice";
import { BLOCK_USER_URL, COMMUNITY_URL, REPORTS_URL } from "../../constants";

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
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify({ success: true, data: {} }), {
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

describe("block endpoints hit routes/userBlocks.js", () => {
  it("blockUser -> POST /api/v1/users/:userId/block", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).blockUser.initiate("u2")
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe(`${BLOCK_USER_URL}/u2/block`);
    expect(calls[0].method).toBe("POST");
  });

  it("unblockUser -> DELETE /api/v1/users/:userId/block", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).unblockUser.initiate("u2")
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe(`${BLOCK_USER_URL}/u2/block`);
    expect(calls[0].method).toBe("DELETE");
  });

  it("getBlockedUsers -> GET /api/v1/users/:userId/blocked (the viewer's own id)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).getBlockedUsers.initiate({ userId: "me" })
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe(`${BLOCK_USER_URL}/me/blocked`);
    expect(calls[0].method).toBe("GET");
  });

  it("getBlockStatus -> GET /api/v1/users/:userId/block-status/:targetUserId", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).getBlockStatus.initiate({
        userId: "me",
        targetUserId: "u2",
      })
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe(
      `${BLOCK_USER_URL}/me/block-status/u2`
    );
    expect(calls[0].method).toBe("GET");
  });

  it("exports a hook for the block status so screens can offer Unblock", () => {
    expect(typeof (usersSliceExports as any).useGetBlockStatusQuery).toBe("function");
  });
});

describe("reportUser hits POST /api/v1/reports with the Report model's body", () => {
  it("posts type/reportId/reportedUser/reason/description", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).reportUser.initiate({
        type: "user",
        reportedUser: "u2",
        reason: "harassment",
        description: "kept messaging after I asked them to stop",
      })
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe(REPORTS_URL);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      type: "user",
      // Required by controllers/report.js — a report without it 400s.
      reportId: "u2",
      reportedUser: "u2",
      reason: "harassment",
      description: "kept messaging after I asked them to stop",
    });
  });

  it("keeps reportId distinct from reportedUser when the thing reported is a message", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).reportUser.initiate({
        type: "message",
        reportId: "msg-9",
        reportedUser: "u2",
        reason: "spam",
      })
    );
    const body = JSON.parse(calls[0].body as string);
    expect(body.type).toBe("message");
    expect(body.reportId).toBe("msg-9");
    expect(body.reportedUser).toBe("u2");
  });

  it("no longer posts to the /users/:id/report route that never existed", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).reportUser.initiate({
        reportedUser: "u2",
        reason: "other",
      })
    );
    expect(new URL(calls[0].url).pathname).not.toMatch(/\/users\/[^/]+\/report$/);
  });
});

describe("recordProfileVisit hits POST /auth/users/:userId/profile-visit", () => {
  // The visit carries a source and a device type. `controllers/profileVisits.js`
  // reads both off the body and defaults deviceType to 'ios' when it is absent,
  // so a web visit sent without one is filed under iOS — in the owner's
  // visitors list, in profileStats, and in the bySource breakdown. 'web' has
  // been a valid value in the ProfileVisit schema's enum all along.
  it("sends source and deviceType, so a web visit is not filed as iOS", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).recordProfileVisit.initiate("u2")
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe(`${COMMUNITY_URL}/u2/profile-visit`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      source: "direct",
      deviceType: "web",
    });
  });
});

describe("username lookups hit the /auth/users router (community#3)", () => {
  // /api/v1/users is the userBlocks router; the username routes are mounted
  // under /api/v1/auth/users (routes/users.js:66,69). NewChat's "@handle"
  // search 404'd and showed nothing.
  it("searchUsersByUsername -> GET /api/v1/auth/users/search/username?q=", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (usersApiSlice.endpoints as any).searchUsersByUsername.initiate({ query: "@ada lo" })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMUNITY_URL}/search/username`);
    expect(url.searchParams.get("q")).toBe("ada lo");
    expect(url.searchParams.get("limit")).toBe("20");
  });

  it("getUserByUsername -> GET /api/v1/auth/users/username/:u, @ stripped and encoded", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((usersApiSlice.endpoints as any).getUserByUsername.initiate("@ada/x"));
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMUNITY_URL}/username/ada%2Fx`);
  });
});

it("blocking someone refetches feeds and comment lists (moments#10)", async () => {
  // A moments query that provides "Moments" is refetched after blockUser.
  const calls: string[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push(`${req.method} ${new URL(req.url).pathname}`);
    return new Response(JSON.stringify({ success: true, data: [] }), {
      status: 200, headers: { "content-type": "application/json" },
    });
  });
  const store = makeStore();
  const { momentsApiSlice } = require("./momentsSlice");
  const sub = store.dispatch(momentsApiSlice.endpoints.getSavedMoments.initiate({ page: 1, limit: 12 }));
  await sub;
  await store.dispatch((usersApiSlice.endpoints as any).blockUser.initiate("a1"));
  await new Promise((r) => setTimeout(r, 0));
  expect(calls.filter((c) => c.endsWith("/moments/saved")).length).toBe(2);
  sub.unsubscribe();
});
