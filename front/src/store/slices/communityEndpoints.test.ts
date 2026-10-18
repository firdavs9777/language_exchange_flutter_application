/**
 * Asserts the REAL request shape (URL/method/body) each reconciled
 * communitySlice endpoint produces, by dispatching `.initiate(...)` against
 * a real store + a mocked global.fetch and inspecting the outgoing Request.
 * (RTK Query endpoint objects don't expose their internal `query` builder
 * directly — `.initiate` + fetch interception is the reliable way to
 * introspect the resulting request without hitting a real network.)
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import {
  communityApiSlice,
} from "./communitySlice";
import * as communitySliceExports from "./communitySlice";
import {
  COMMUNITY_WAVES,
  COMMUNITY_WAVES_LIST,
  COMMUNITY_COUNT_URL,
} from "../../constants";

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
      JSON.stringify({ success: true, data: { waves: [], unreadCount: 0, count: 0 } }),
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

describe("wave endpoints hit the REAL backend routes", () => {
  it("sendWave -> POST /api/v1/community/wave with {targetUserId, message}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).sendWave.initiate({
        targetUserId: "user-1",
        message: "hi there",
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe(`http://localhost:5003${COMMUNITY_WAVES}`);
    expect(calls[0].url).toContain("/api/v1/community/wave");
    expect(calls[0].url).not.toContain("/wave/"); // no nested /wave/... path
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      targetUserId: "user-1",
      message: "hi there",
    });
  });

  it("getWaves -> GET /api/v1/community/waves with page/limit/unreadOnly/archive", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getWaves.initiate({
        page: 2,
        limit: 15,
        unreadOnly: true,
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].method).toBe("GET");
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(COMMUNITY_WAVES_LIST);
    expect(url.pathname).toBe("/api/v1/community/waves");
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("limit")).toBe("15");
    expect(url.searchParams.get("unreadOnly")).toBe("true");
  });

  it("markWavesRead -> PUT /api/v1/community/waves/read with {waveIds}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).markWavesRead.initiate(["w1", "w2"])
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMUNITY_WAVES_LIST}/read`);
    expect(url.pathname).toBe("/api/v1/community/waves/read");
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({ waveIds: ["w1", "w2"] });
  });

  it("does NOT expose the old non-existent wave routes", async () => {
    // The removed getReceivedWaves/getSentWaves/respondToWave/markWaveRead
    // endpoints pointed at /wave/received, /wave/sent, /wave/:id/respond,
    // /wave/:id/read — none of which exist server-side.
    const endpointNames = Object.keys((communityApiSlice as any).endpoints);
    expect(endpointNames).not.toContain("getReceivedWaves");
    expect(endpointNames).not.toContain("getSentWaves");
    expect(endpointNames).not.toContain("respondToWave");
    expect(endpointNames).not.toContain("markWaveRead");
    expect(endpointNames).toContain("getWaves");
    expect(endpointNames).toContain("markWavesRead");
  });
});

describe("getCommunityCount endpoint", () => {
  it("-> GET /api/v1/auth/users/count with the same filter params as members", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getCommunityCount.initiate({
        nativeLanguage: "English",
        learningLanguage: "Korean",
        matchLanguage: "true",
        minAge: "25",
        page: "1",
        limit: "20",
      })
    );
    expect(calls).toHaveLength(1);
    expect(calls[0].method).toBe("GET");
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(COMMUNITY_COUNT_URL);
    expect(url.pathname).toBe("/api/v1/auth/users/count");
    expect(url.searchParams.get("nativeLanguage")).toBe("English");
    expect(url.searchParams.get("learningLanguage")).toBe("Korean");
    expect(url.searchParams.get("minAge")).toBe("25");
  });
});

// The profile page derives both the follower count and `isFollowing` from this
// query's response, so a follow that does not refetch it leaves the page
// showing the state from before the tap (P1 review finding). followUser
// invalidates the "User" tag; this asserts getCommunityDetails actually
// provides it.
describe("getCommunityDetails cache invalidation", () => {
  it("is refetched after a follow", async () => {
    const calls = mockFetch();
    const store = makeStore();
    const { usersApiSlice } = require("./usersSlice");

    await store.dispatch(
      (communityApiSlice.endpoints as any).getCommunityDetails.initiate("user-1")
    );
    const profileCalls = () =>
      calls.filter((c) => new URL(c.url).pathname === "/api/v1/auth/users/user-1").length;
    expect(profileCalls()).toBe(1);

    await store.dispatch(
      (usersApiSlice.endpoints as any).followUser.initiate({
        userId: "me",
        targetUserId: "user-1",
      })
    );

    // The refetch is scheduled by the invalidation middleware, not awaited by
    // the mutation's own promise.
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(profileCalls()).toBe(2);
  });
});

// /profile/:userId reads this endpoint (useProfileData), because the route is
// public and the protected /auth/users/:id 401s for an anonymous visitor and
// skips the backend's privacy redaction. It therefore needs the same "User"
// tags getCommunityDetails carries, or a follow leaves the page stale.
describe("getPublicUserProfile", () => {
  it("requests the PUBLIC /auth/users/:id/public URL", async () => {
    const calls = mockFetch();
    const store = makeStore();

    await store.dispatch(
      (communityApiSlice.endpoints as any).getPublicUserProfile.initiate("user-1")
    );

    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/auth/users/user-1/public");
  });

  it("is refetched after a follow", async () => {
    const calls = mockFetch();
    const store = makeStore();
    const { usersApiSlice } = require("./usersSlice");

    await store.dispatch(
      (communityApiSlice.endpoints as any).getPublicUserProfile.initiate("user-1")
    );
    const profileCalls = () =>
      calls.filter(
        (c) => new URL(c.url).pathname === "/api/v1/auth/users/user-1/public"
      ).length;
    expect(profileCalls()).toBe(1);

    await store.dispatch(
      (usersApiSlice.endpoints as any).followUser.initiate({
        userId: "me",
        targetUserId: "user-1",
      })
    );

    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(profileCalls()).toBe(2);
  });
});

describe('the "For you" recommendation feed', () => {
  it("getRecommendations -> GET /api/v1/matching/recommendations?limit=", async () => {
    const calls = mockFetch();
    const store = makeStore();

    await store.dispatch(
      (communityApiSlice.endpoints as any).getRecommendations.initiate({ limit: 20 })
    );

    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/matching/recommendations");
    expect(url.searchParams.get("limit")).toBe("20");
    expect(calls[0].method).toBe("GET");
  });

  // The backend caps `limit` at 50 and defaults to 20; the client sends a
  // limit either way so the request is explicit about the page it wants.
  it("asks for the server's default page when no limit is given", async () => {
    const calls = mockFetch();
    const store = makeStore();

    await store.dispatch(
      (communityApiSlice.endpoints as any).getRecommendations.initiate({})
    );

    expect(new URL(calls[0].url).searchParams.get("limit")).toBe("20");
  });
});

describe("Today's matches endpoints hit the live backend routes", () => {
  it("getDailyMatches -> GET /api/v1/matching/daily", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((communityApiSlice.endpoints as any).getDailyMatches.initiate());
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/matching/daily");
    expect(calls[0].method).toBe("GET");
  });

  it("skipUser -> POST /api/v1/interactions/skip with {targetUserId}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((communityApiSlice.endpoints as any).skipUser.initiate("u-9"));
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/interactions/skip");
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ targetUserId: "u-9" });
  });
});

describe("getNearbyUsers (community#2)", () => {
  // controllers/community.js reads latitude/longitude/offset. The slice sent
  // lat/lng/page, so every request answered 400 "Valid latitude and longitude
  // are required" and the page always showed "No users found nearby".
  it("-> GET /api/v1/community/nearby with latitude, longitude, radius, limit, offset", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getNearbyUsers.initiate({
        latitude: 37.5665,
        longitude: 126.978,
        radius: 10,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe("/api/v1/community/nearby");
    expect(url.searchParams.get("latitude")).toBe("37.5665");
    expect(url.searchParams.get("longitude")).toBe("126.978");
    expect(url.searchParams.get("radius")).toBe("10");
    expect(url.searchParams.get("limit")).toBe("50");
    expect(url.searchParams.get("offset")).toBe("0");
    expect(url.searchParams.get("lat")).toBeNull();
    expect(url.searchParams.get("lng")).toBeNull();
    expect(url.searchParams.get("page")).toBeNull();
  });

  it("turns page 3 into an offset the server understands", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getNearbyUsers.initiate({
        latitude: 1,
        longitude: 2,
        page: 3,
        limit: 20,
      })
    );
    const url = new URL(calls[0].url);
    expect(url.searchParams.get("offset")).toBe("40");
    expect(url.searchParams.get("limit")).toBe("20");
  });
});

describe("getWaves archive + reveal (community#10)", () => {
  it("sends archive=true and reveal=1 only when asked", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (communityApiSlice.endpoints as any).getWaves.initiate({ page: 1, limit: 20, archive: true, reveal: true })
    );
    const url = new URL(calls[0].url);
    expect(url.searchParams.get("archive")).toBe("true");
    expect(url.searchParams.get("reveal")).toBe("1");

    await store.dispatch((communityApiSlice.endpoints as any).getWaves.initiate({ page: 2, limit: 20 }));
    const plain = new URL(calls[1].url);
    expect(plain.searchParams.get("archive")).toBeNull();
    expect(plain.searchParams.get("reveal")).toBeNull();
  });
});

describe("dead endpoints are gone (community#12)", () => {
  // Each pointed at a route the API does not serve; unused, but they invite
  // reuse and every reuse is a silent 404.
  it("has no endpoint for a route the API does not serve", () => {
    const names = Object.keys((communityApiSlice as any).endpoints);
    [
      "getUserTopics",
      "updateMyLanguages",
      "getUsersByLanguage",
      "getOnlineUsers",
      "getRecentlyActive",
      "getNewUsers",
    ].forEach((name) => expect(names).not.toContain(name));
  });

  it("exports none of their hooks, nor the deprecated wave shims", () => {
    const exported = communitySliceExports as any;
    [
      "useGetUserTopicsQuery",
      "useUpdateMyLanguagesMutation",
      "useGetUsersByLanguageQuery",
      "useGetOnlineUsersQuery",
      "useGetRecentlyActiveQuery",
      "useGetNewUsersQuery",
      "useGetReceivedWavesQuery",
      "useGetSentWavesQuery",
      "useMarkWaveReadMutation",
      "useRespondToWaveMutation",
    ].forEach((name) => expect(exported[name]).toBeUndefined());
  });
});
