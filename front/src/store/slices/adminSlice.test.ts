/**
 * The admin slice is the only thing the six admin pages talk to, so this test
 * pins two things the pages depend on and nothing else:
 *
 *  1. every endpoint named in the plan exists, with the URL the backend
 *     actually serves (`routes/admin.js`), and
 *  2. a ban really does invalidate the user list — asserted the way a user
 *     experiences it (the list refetches), not by reading tag arrays.
 *
 * Idiom follows communityEndpoints.test.ts: dispatch `.initiate(...)` against
 * a real store with a mocked `global.fetch` and inspect the outgoing Request.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { adminApiSlice } from "./adminSlice";

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

function mockFetch(payload: any = { success: true, data: [] }): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    const body = req.body ?? (req.clone ? await req.clone().text() : undefined);
    calls.push({ url: req.url, method: req.method, body });
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

const ENDPOINT_NAMES = [
  "getAdminStats",
  "getAdminActivity",
  "searchAdminUsers",
  "getAdminUser",
  "banAdminUser",
  "unbanAdminUser",
  "changeAdminUserRole",
  "getBannedUsers",
  "hardDeleteAdminUser",
  "getAuditLog",
  "getAiUsage",
  "getAiUsageLogs",
  "getAdminClubs",
  "getAdminGatherings",
  "archiveAdminClub",
  "cancelAdminGathering",
  "getContentStats",
  "listMoments",
  "setMomentHidden",
  "createUser",
  "updateUser",
  "listReports",
  "reviewReport",
  "resolveReport",
  "dismissReport",
  "getAnalyticsEvents",
  "getAnalyticsVisits",
];

it("exposes every endpoint the admin pages import", () => {
  const names = Object.keys((adminApiSlice as any).endpoints);
  for (const name of ENDPOINT_NAMES) {
    expect(names).toContain(name);
  }
});

it("exports a hook per endpoint", () => {
  const slice = adminApiSlice as any;
  expect(typeof slice.useGetAdminStatsQuery).toBe("function");
  expect(typeof slice.useSearchAdminUsersQuery).toBe("function");
  expect(typeof slice.useBanAdminUserMutation).toBe("function");
  expect(typeof slice.useGetAnalyticsEventsQuery).toBe("function");
});

describe("request shapes match routes/admin.js", () => {
  it("searchAdminUsers -> GET /api/v1/admin/users with q/adminsOnly/page/limit", async () => {
    const calls = mockFetch({ success: true, data: [], pagination: { total: 0 } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).searchAdminUsers.initiate({
        q: "ada",
        adminsOnly: true,
        page: 2,
        limit: 25,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/admin/users");
    expect(calls[0].method).toBe("GET");
    expect(url.searchParams.get("q")).toBe("ada");
    expect(url.searchParams.get("adminsOnly")).toBe("true");
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("limit")).toBe("25");
  });

  it("banAdminUser -> POST /api/v1/admin/users/:id/ban with {reason}", async () => {
    const calls = mockFetch({ success: true, data: { message: "User banned" } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).banAdminUser.initiate({ id: "u1", reason: "spam" })
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/users/u1/ban");
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ reason: "spam" });
  });

  it("changeAdminUserRole -> PUT /api/v1/admin/users/:id/role with {role, reason}", async () => {
    const calls = mockFetch({ success: true, data: { previousRole: "user", newRole: "admin" } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).changeAdminUserRole.initiate({
        id: "u1",
        role: "admin",
        reason: "promotion",
      })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/users/u1/role");
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({ role: "admin", reason: "promotion" });
  });

  it("hardDeleteAdminUser -> DELETE /api/v1/admin/users/:id", async () => {
    const calls = mockFetch({ success: true, data: {} });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).hardDeleteAdminUser.initiate({ id: "u1", reason: "gdpr" })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/users/u1");
    expect(calls[0].method).toBe("DELETE");
  });

  it("cancelAdminGathering -> POST /api/v1/admin/content/gatherings/:id/cancel", async () => {
    const calls = mockFetch({ success: true, data: { _id: "g1", status: "cancelled" } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).cancelAdminGathering.initiate({ id: "g1", reason: "dupe" })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/content/gatherings/g1/cancel");
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ reason: "dupe" });
  });

  it("archiveAdminClub -> POST /api/v1/admin/content/clubs/:id/archive with {archived, reason}", async () => {
    const calls = mockFetch({ success: true, data: { _id: "c1", status: "archived" } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).archiveAdminClub.initiate({
        id: "c1",
        archived: true,
        reason: "spam",
      })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/content/clubs/c1/archive");
    expect(JSON.parse(calls[0].body as string)).toEqual({ archived: true, reason: "spam" });
  });

  it("getAnalyticsEvents -> GET /api/v1/admin/analytics/events?days=", async () => {
    const calls = mockFetch({ success: true, data: { byDay: [] } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).getAnalyticsEvents.initiate({ days: 7 })
    );
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/admin/analytics/events");
    expect(url.searchParams.get("days")).toBe("7");
  });

  it("getAnalyticsVisits -> GET /api/v1/admin/analytics/visits", async () => {
    const calls = mockFetch({ success: true, data: { thisWeek: {} } });
    const store = makeStore();
    await store.dispatch((adminApiSlice.endpoints as any).getAnalyticsVisits.initiate(undefined));
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/analytics/visits");
  });

  it("getContentStats -> GET /api/v1/admin/content/stats", async () => {
    const calls = mockFetch({ success: true, data: { moments: { total: 1 } } });
    const store = makeStore();
    await store.dispatch((adminApiSlice.endpoints as any).getContentStats.initiate(undefined));
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/content/stats");
    expect(calls[0].method).toBe("GET");
  });

  it("listMoments -> GET /api/v1/admin/content/moments with page/limit/q/reported/hidden encoded", async () => {
    const calls = mockFetch({ success: true, total: 0, page: 1, data: [] });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).listMoments.initiate({
        page: 2,
        limit: 10,
        q: "sunset",
        reported: true,
        hidden: false,
      })
    );
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/admin/content/moments");
    expect(calls[0].method).toBe("GET");
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("limit")).toBe("10");
    expect(url.searchParams.get("q")).toBe("sunset");
    expect(url.searchParams.get("reported")).toBe("true");
    expect(url.searchParams.get("hidden")).toBe("false");
  });

  it("setMomentHidden -> POST /api/v1/admin/content/moments/:id/hide with {hidden, reason}", async () => {
    const calls = mockFetch({ success: true, data: { id: "m1", isDeleted: true } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).setMomentHidden.initiate({
        id: "m1",
        hidden: true,
        reason: "nudity",
      })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/content/moments/m1/hide");
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ hidden: true, reason: "nudity" });
  });

  it("createUser -> POST /api/v1/admin/users with the registration body", async () => {
    const calls = mockFetch({
      success: true,
      data: { id: "u9", name: "Ada", email: "ada@example.com", role: "user" },
    });
    const store = makeStore();
    const body = {
      name: "Ada",
      email: "ada@example.com",
      password: "s3cret-password",
      gender: "female",
      birth_year: 1990,
      birth_month: 1,
      birth_day: 1,
      native_language: "eng",
      language_to_learn: "kor",
      role: "user" as const,
      markVerified: true,
    };
    await store.dispatch((adminApiSlice.endpoints as any).createUser.initiate(body));
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/users");
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual(body);
  });

  it("updateUser -> PUT /api/v1/admin/users/:id with only the changed fields", async () => {
    const calls = mockFetch({ success: true, data: { _id: "u1", name: "Ada L." } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).updateUser.initiate({
        id: "u1",
        name: "Ada L.",
        vip: { grant: true, days: 30 },
      })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/users/u1");
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      name: "Ada L.",
      vip: { grant: true, days: 30 },
    });
  });

  it("listReports -> GET /api/v1/reports with status/type/page/limit ('type', not 'targetType')", async () => {
    const calls = mockFetch({ success: true, count: 0, data: [] });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).listReports.initiate({
        status: "pending",
        targetType: "moment",
        page: 1,
        limit: 20,
      })
    );
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/reports");
    expect(calls[0].method).toBe("GET");
    expect(url.searchParams.get("status")).toBe("pending");
    expect(url.searchParams.get("type")).toBe("moment");
    expect(url.searchParams.has("targetType")).toBe(false);
    expect(url.searchParams.get("page")).toBe("1");
    expect(url.searchParams.get("limit")).toBe("20");
  });

  it("reviewReport -> PUT /api/v1/reports/:id/review with no body", async () => {
    const calls = mockFetch({ success: true, data: { _id: "r1", status: "under_review" } });
    const store = makeStore();
    await store.dispatch((adminApiSlice.endpoints as any).reviewReport.initiate("r1"));
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/reports/r1/review");
    expect(calls[0].method).toBe("PUT");
  });

  it("resolveReport -> PUT /api/v1/reports/:id/resolve with {action, notes}", async () => {
    const calls = mockFetch({ success: true, data: { _id: "r1", status: "resolved" } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).resolveReport.initiate({
        id: "r1",
        action: "content_removed",
        notes: "removed the moment",
      })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/reports/r1/resolve");
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      action: "content_removed",
      notes: "removed the moment",
    });
  });

  it("dismissReport -> PUT /api/v1/reports/:id/dismiss with {notes}", async () => {
    const calls = mockFetch({ success: true, data: { _id: "r1", status: "dismissed" } });
    const store = makeStore();
    await store.dispatch(
      (adminApiSlice.endpoints as any).dismissReport.initiate({ id: "r1", notes: "no violation" })
    );
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/reports/r1/dismiss");
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({ notes: "no violation" });
  });
});

describe("setMomentHidden invalidates the moments table and the stat strip", () => {
  it("a successful hide refetches listMoments (AdminMoments invalidation)", async () => {
    const calls = mockFetch({ success: true, total: 0, page: 1, data: [] });
    const store = makeStore();

    // A live subscription, the way the content desk's moments table holds one.
    const sub: any = store.dispatch(
      (adminApiSlice.endpoints as any).listMoments.initiate({ page: 1 })
    );
    await sub;
    expect(calls).toHaveLength(1);

    await store.dispatch(
      (adminApiSlice.endpoints as any).setMomentHidden.initiate({
        id: "m1",
        hidden: true,
        reason: "spam",
      })
    );

    // The hide itself is call 2; the invalidated listMoments refetch is call 3.
    const deadline = Date.now() + 2000;
    while (calls.length < 3 && Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 10));
    }
    expect(calls.length).toBeGreaterThanOrEqual(3);
    expect(
      calls.filter((c) => new URL(c.url).pathname === "/api/v1/admin/content/moments").length
    ).toBeGreaterThanOrEqual(2);

    sub.unsubscribe();
  });
});

describe("transformResponse unwraps the {success, data} envelope", () => {
  it("keeps pagination alongside the rows for paginated lists", async () => {
    mockFetch({ success: true, data: [{ _id: "u1" }], pagination: { total: 1, page: 1, hasMore: false } });
    const store = makeStore();
    const res: any = await store.dispatch(
      (adminApiSlice.endpoints as any).searchAdminUsers.initiate({})
    );
    expect(res.data.data).toEqual([{ _id: "u1" }]);
    expect(res.data.pagination).toEqual({ total: 1, page: 1, hasMore: false });
  });

  it("returns bare data for unpaginated reads", async () => {
    mockFetch({ success: true, data: { total: 42, banned: 1 } });
    const store = makeStore();
    const res: any = await store.dispatch(
      (adminApiSlice.endpoints as any).getAdminStats.initiate(undefined)
    );
    expect(res.data).toEqual({ total: 42, banned: 1 });
  });
});

it("banning a user refetches the user list (AdminUserList invalidation)", async () => {
  const calls = mockFetch({ success: true, data: [], pagination: { total: 0 } });
  const store = makeStore();

  // A live subscription, the way the Users page holds one.
  const sub: any = store.dispatch(
    (adminApiSlice.endpoints as any).searchAdminUsers.initiate({ page: 1 })
  );
  await sub;
  expect(calls).toHaveLength(1);

  await store.dispatch(
    (adminApiSlice.endpoints as any).banAdminUser.initiate({ id: "u1", reason: "spam" })
  );

  // The ban itself is call 2; the invalidated list refetch is call 3.
  const deadline = Date.now() + 2000;
  while (calls.length < 3 && Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 10));
  }
  expect(calls.length).toBeGreaterThanOrEqual(3);
  expect(calls.filter((c) => new URL(c.url).pathname === "/api/v1/admin/users").length)
    .toBeGreaterThanOrEqual(2);

  sub.unsubscribe();
});

/**
 * The Overview's counters (total, banned, admins) move the moment a moderator
 * bans, unbans, promotes or deletes someone. Without `AdminStats` on these
 * four mutations the console keeps showing the pre-action numbers until a
 * manual refresh, which reads as "the action didn't work".
 */
describe("user moderation refreshes the Overview stats", () => {
  const cases: Array<[string, any]> = [
    ["banAdminUser", { id: "u1", reason: "spam" }],
    ["unbanAdminUser", { id: "u1", reason: "appeal" }],
    ["changeAdminUserRole", { id: "u1", role: "admin", reason: "mod team" }],
    ["hardDeleteAdminUser", { id: "u1", reason: "gdpr" }],
  ];

  for (const [name, arg] of cases) {
    it(`${name} invalidates AdminStats`, async () => {
      const calls = mockFetch({ success: true, data: { total: 1 } });
      const store = makeStore();

      // A live subscription, the way the Overview page holds one.
      const sub: any = store.dispatch(
        (adminApiSlice.endpoints as any).getAdminStats.initiate(undefined)
      );
      await sub;
      const statsPath = "/api/v1/admin/stats";
      expect(calls.filter((c) => new URL(c.url).pathname === statsPath)).toHaveLength(1);

      await store.dispatch((adminApiSlice.endpoints as any)[name].initiate(arg));

      const deadline = Date.now() + 2000;
      while (
        calls.filter((c) => new URL(c.url).pathname === statsPath).length < 2 &&
        Date.now() < deadline
      ) {
        await new Promise((r) => setTimeout(r, 10));
      }
      expect(
        calls.filter((c) => new URL(c.url).pathname === statsPath).length
      ).toBeGreaterThanOrEqual(2);

      sub.unsubscribe();
    });
  }
});
