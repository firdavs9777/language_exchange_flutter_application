/**
 * Asserts the REAL request shape (URL/method/body/params) each new
 * momentsSlice endpoint produces, by dispatching `.initiate(...)` against a
 * real store + a mocked global.fetch and inspecting the outgoing Request.
 * Mirrors chatActionsEndpoints.test.ts.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { momentsApiSlice } from "./momentsSlice";
import { MOMENTS_URL } from "../../constants";

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
    let body: string | undefined = req.body;
    if (body === undefined && req.clone) {
      try {
        body = await req.clone().text();
      } catch {
        // whatwg-fetch's polyfilled Request can't re-serialize a FormData
        // body as text — that's expected for the video/audio upload
        // endpoints. Body shape isn't asserted for those; URL/method are.
        body = undefined;
      }
    }
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

describe("momentsSlice new endpoints hit the REAL backend routes", () => {
  it("reactToMoment -> POST /api/v1/moments/:momentId/react with {emoji}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).reactToMoment.initiate({
        momentId: "moment-1",
        emoji: "🔥",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/moment-1/react`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ emoji: "🔥" });
  });

  it("unreactToMoment -> DELETE /api/v1/moments/:momentId/react", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).unreactToMoment.initiate("moment-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/moment-1/react`);
    expect(calls[0].method).toBe("DELETE");
  });

  it("shareMoment -> POST /api/v1/moments/:momentId/share (no body)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).shareMoment.initiate("moment-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/moment-1/share`);
    expect(calls[0].method).toBe("POST");
  });

  it("uploadMomentVideo -> PUT /api/v1/moments/:momentId/video with FormData (field: video)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    const formData = new FormData();
    formData.append(
      "video",
      new File(["fake-bytes"], "clip.mp4", { type: "video/mp4" })
    );
    await store.dispatch(
      (momentsApiSlice.endpoints as any).uploadMomentVideo.initiate({
        momentId: "moment-1",
        formData,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/moment-1/video`);
    expect(calls[0].method).toBe("PUT");
  });

  it("deleteMomentVideo -> DELETE /api/v1/moments/:momentId/video", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).deleteMomentVideo.initiate("moment-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/moment-1/video`);
    expect(calls[0].method).toBe("DELETE");
  });

  it("uploadMomentAudio -> PUT /api/v1/moments/:momentId/audio with FormData (fields: audio, duration, waveform)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    const formData = new FormData();
    formData.append(
      "audio",
      new File(["fake-bytes"], "clip.webm", { type: "audio/webm" })
    );
    formData.append("duration", "12.5");
    formData.append("waveform", JSON.stringify([0, 1, 2, 3]));
    await store.dispatch(
      (momentsApiSlice.endpoints as any).uploadMomentAudio.initiate({
        momentId: "moment-1",
        formData,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/moment-1/audio`);
    expect(calls[0].method).toBe("PUT");
  });

  it("getPromptOfDay -> GET /api/v1/moments/prompt-of-day (no language)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).getPromptOfDay.initiate()
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/prompt-of-day`);
    expect(url.searchParams.get("language")).toBeNull();
    expect(calls[0].method).toBe("GET");
  });

  it("getPromptOfDay -> GET /api/v1/moments/prompt-of-day?language=ko", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).getPromptOfDay.initiate({
        language: "ko",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/prompt-of-day`);
    expect(url.searchParams.get("language")).toBe("ko");
    expect(calls[0].method).toBe("GET");
  });

  it("getReelsFeed -> GET /api/v1/moments/reels with {before, limit} params", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).getReelsFeed.initiate({
        before: "2026-07-01T00:00:00.000Z",
        limit: 5,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/reels`);
    expect(url.searchParams.get("before")).toBe("2026-07-01T00:00:00.000Z");
    expect(url.searchParams.get("limit")).toBe("5");
    expect(calls[0].method).toBe("GET");
  });

  it("getReelsFeed -> GET /api/v1/moments/reels with no params", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).getReelsFeed.initiate()
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/reels`);
    expect(calls[0].method).toBe("GET");
  });
});
