/**
 * Asserts the REAL request shape (URL / method / body) every storiesSlice
 * endpoint this phase depends on produces, by dispatching `.initiate(...)`
 * against a real store plus a mocked `global.fetch` and inspecting the
 * outgoing Request. RTK Query does not expose an endpoint's `query` builder,
 * so intercepting fetch is the only honest way to see what would go out.
 *
 * Every expectation below is checked against
 * `language_exchange_backend_application/routes/story.js` +
 * `controllers/stories.js` — the three endpoints that existed but were never
 * called (`answerQuestion`, `shareStory`, `getStoryViewers`) had bodies that
 * the backend ignores, which is exactly the kind of bug a test like this
 * catches once and for good:
 *   - `POST /:id/question/answer` reads `{ text, isAnonymous }`, not `{ answer }`
 *   - `POST /:id/share` reads `{ sharedTo, receiverId }`, not `{ userId }`
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { storiesApiSlice } from "./storiesSlice";
import * as storiesSliceExports from "./storiesSlice";
import { MAIN_STORIES } from "../../constants";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      // Minimal stand-in for authSlice: apiSlice's prepareHeaders and the
      // reauth wrapper only ever read state.auth.userInfo.
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

const dispatchOnce = async (name: string, arg?: any): Promise<Captured[]> => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch((storiesApiSlice.endpoints as any)[name].initiate(arg));
  return calls;
};

const pathOf = (call: Captured) => new URL(call.url).pathname;

describe("reactions", () => {
  it("reactToStory -> POST /stories/:id/react with {emoji}", async () => {
    const calls = await dispatchOnce("reactToStory", {
      storyId: "story-1",
      emoji: "🔥",
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/story-1/react`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ emoji: "🔥" });
  });

  it("removeReaction -> DELETE /stories/:id/react with {emoji}", async () => {
    const calls = await dispatchOnce("removeReaction", {
      storyId: "story-1",
      emoji: "🔥",
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/story-1/react`);
    // The reason this endpoint exists: POST does NOT toggle server-side, so
    // reacting twice with the same emoji left the reaction in place.
    expect(calls[0].method).toBe("DELETE");
    expect(JSON.parse(calls[0].body as string)).toEqual({ emoji: "🔥" });
  });
});

describe("question box", () => {
  it("answerQuestion -> POST /stories/:id/question/answer with {text, isAnonymous}", async () => {
    const calls = await dispatchOnce("answerQuestion", {
      id: "story-1",
      text: "Seoul, twice",
      isAnonymous: true,
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/story-1/question/answer`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      text: "Seoul, twice",
      isAnonymous: true,
    });
  });

  it("answerQuestion defaults isAnonymous to false rather than omitting it", async () => {
    const calls = await dispatchOnce("answerQuestion", {
      id: "story-1",
      text: "Seoul",
    });
    expect(JSON.parse(calls[0].body as string)).toEqual({
      text: "Seoul",
      isAnonymous: false,
    });
  });

  it("getQuestionResponses -> GET /stories/:id/question/responses", async () => {
    const calls = await dispatchOnce("getQuestionResponses", "story-1");
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/story-1/question/responses`);
    expect(calls[0].method).toBe("GET");
  });
});

describe("viewers and sharing", () => {
  it("getStoryViewers -> GET /stories/:id/views", async () => {
    const calls = await dispatchOnce("getStoryViewers", "story-1");
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/story-1/views`);
    expect(calls[0].method).toBe("GET");
  });

  it("shareStory -> POST /stories/:id/share with {sharedTo, receiverId}", async () => {
    const calls = await dispatchOnce("shareStory", {
      id: "story-1",
      sharedTo: "dm",
      receiverId: "user-2",
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/story-1/share`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      sharedTo: "dm",
      receiverId: "user-2",
    });
  });

  it("shareStory omits receiverId when there is none (external share)", async () => {
    const calls = await dispatchOnce("shareStory", {
      id: "story-1",
      sharedTo: "external",
    });
    expect(JSON.parse(calls[0].body as string)).toEqual({
      sharedTo: "external",
    });
  });
});

describe("highlights", () => {
  it("addStoryToHighlight -> POST /stories/highlights/:id/stories with {storyId}", async () => {
    const calls = await dispatchOnce("addStoryToHighlight", {
      highlightId: "hl-1",
      storyId: "story-1",
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/highlights/hl-1/stories`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ storyId: "story-1" });
  });

  it("removeStoryFromHighlight -> DELETE /stories/highlights/:id/stories/:storyId", async () => {
    const calls = await dispatchOnce("removeStoryFromHighlight", {
      highlightId: "hl-1",
      storyId: "story-1",
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(
      `${MAIN_STORIES}/highlights/hl-1/stories/story-1`
    );
    expect(calls[0].method).toBe("DELETE");
  });

  it("updateHighlight -> PUT /stories/highlights/:id with {title, coverImage}", async () => {
    const calls = await dispatchOnce("updateHighlight", {
      highlightId: "hl-1",
      title: "Seoul 2026",
      coverImage: "https://cdn/x.jpg",
    });
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/highlights/hl-1`);
    expect(calls[0].method).toBe("PUT");
    expect(JSON.parse(calls[0].body as string)).toEqual({
      title: "Seoul 2026",
      coverImage: "https://cdn/x.jpg",
    });
  });

  it("updateHighlight sends only the fields given (rename without a cover)", async () => {
    const calls = await dispatchOnce("updateHighlight", {
      highlightId: "hl-1",
      title: "Seoul 2026",
    });
    expect(JSON.parse(calls[0].body as string)).toEqual({ title: "Seoul 2026" });
  });

  it("getHighlights and getUserHighlights refetch after addStoryToHighlight", async () => {
    const calls = mockFetch();
    const store = makeStore();
    const endpoints = (storiesApiSlice.endpoints as any);

    await store.dispatch(endpoints.getHighlights.initiate(undefined));
    await store.dispatch(endpoints.getUserHighlights.initiate("user-9"));
    expect(calls).toHaveLength(2);

    await store.dispatch(
      endpoints.addStoryToHighlight.initiate({
        highlightId: "hl-1",
        storyId: "story-1",
      })
    );
    // The mutation itself, then the two invalidated lists refetching.
    await new Promise((resolve) => setTimeout(resolve, 0));

    const refetched = calls
      .slice(3)
      .map(pathOf)
      .sort();
    expect(refetched).toEqual([
      `${MAIN_STORIES}/highlights`,
      `${MAIN_STORIES}/highlights/user/user-9`,
    ]);
  });
});

describe("video config", () => {
  it("getVideoConfig -> GET /stories/video-config", async () => {
    const calls = await dispatchOnce("getVideoConfig", undefined);
    expect(calls).toHaveLength(1);
    expect(pathOf(calls[0])).toBe(`${MAIN_STORIES}/video-config`);
    expect(calls[0].method).toBe("GET");
  });
});

describe("exported hooks", () => {
  it("exposes a hook for every endpoint this phase adds", () => {
    const exports = storiesSliceExports as any;
    expect(exports.useRemoveReactionMutation).toBeDefined();
    expect(exports.useAddStoryToHighlightMutation).toBeDefined();
    expect(exports.useRemoveStoryFromHighlightMutation).toBeDefined();
    expect(exports.useUpdateHighlightMutation).toBeDefined();
    expect(exports.useGetVideoConfigQuery).toBeDefined();
    // Already present, now actually called by the viewer.
    expect(exports.useAnswerQuestionMutation).toBeDefined();
    expect(exports.useGetQuestionResponsesQuery).toBeDefined();
    expect(exports.useShareStoryMutation).toBeDefined();
    expect(exports.useGetStoryViewersQuery).toBeDefined();
  });
});
