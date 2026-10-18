/**
 * Task 0 (moments parity phase 1): asserts the REAL request shape
 * (URL/method/body/FormData) each new momentsSlice endpoint produces, and
 * that `getMoments` without `feed` still serializes to the exact same
 * URL/cache key the prerender prefetch (src/seo/prerender/prefetch.ts)
 * depends on. Mirrors momentsActionsEndpoints.test.ts, but dispatches
 * against the real app store (src/store) as instructed.
 */
import { defaultSerializeQueryArgs } from "@reduxjs/toolkit/query";
import { makeStore } from "../../store";
import { momentsApiSlice } from "./momentsSlice";
import { MOMENTS_URL, COMMENTS_URL } from "../../constants";

type Captured = { url: string; method: string; body: string | undefined; contentType: string | null };

function mockFetch(): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    let body: string | undefined = req.body;
    if (body === undefined && req.clone) {
      try {
        body = await req.clone().text();
      } catch {
        // whatwg-fetch's polyfilled Request can't re-serialize a FormData
        // body as text — expected for uploadCommentImage. URL/method/the
        // multipart content-type are asserted instead.
        body = undefined;
      }
    }
    calls.push({
      url: req.url,
      method: req.method,
      body,
      contentType: req.headers?.get ? req.headers.get("content-type") : null,
    });
    return new Response(
      JSON.stringify({ success: true, data: {} }),
      { status: 200, headers: { "content-type": "application/json" } }
    );
  });
  return calls;
}

// whatwg-fetch's polyfilled Request (loaded by react-app-polyfill/jsdom for
// every test in this project) never stores `keepalive` on the instance it
// builds -- the property is silently dropped, so reading `req.keepalive` off
// a captured Request in `mockFetch` above is always `undefined` regardless of
// what fetchBaseQuery was asked to send. To prove `keepalive` actually made
// it into the `RequestInit` fetchBaseQuery builds, this wraps the real
// `Request` constructor (still fully functional -- it delegates straight to
// the original) and records the `init` argument each call received.
function captureRequestInit(): { init: any }[] {
  const calls: { init: any }[] = [];
  const OriginalRequest = (global as any).Request;
  (global as any).Request = jest.fn((...args: any[]) => {
    calls.push({ init: args[1] });
    return new OriginalRequest(...args);
  });
  return calls;
}

const originalFetch = global.fetch;
const originalRequest = global.Request;
afterEach(() => {
  global.fetch = originalFetch;
  (global as any).Request = originalRequest;
  jest.restoreAllMocks();
});

describe("momentsSlice Task 0 endpoints hit the REAL backend routes", () => {
  it("translateComment -> POST /api/v1/comments/:commentId/translate with {targetLanguage}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).translateComment.initiate({
        commentId: "comment-1",
        targetLanguage: "ko",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMENTS_URL}/comment-1/translate`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ targetLanguage: "ko" });
  });

  it("likeComment -> POST /api/v1/comments/:commentId/like (no body)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).likeComment.initiate("comment-1")
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMENTS_URL}/comment-1/like`);
    expect(calls[0].method).toBe("POST");
  });

  it("reactToComment -> POST /api/v1/comments/:commentId/react with {emoji}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).reactToComment.initiate({
        commentId: "comment-1",
        emoji: "😂",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMENTS_URL}/comment-1/react`);
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ emoji: "😂" });
  });

  it("unreactToComment -> DELETE /api/v1/comments/:commentId/react (no body)", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).unreactToComment.initiate({
        commentId: "comment-1",
        emoji: "😂",
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMENTS_URL}/comment-1/react`);
    expect(calls[0].method).toBe("DELETE");
  });

  it("getCommentReplies -> GET /api/v1/comments/:commentId/replies?page=&limit=", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).getCommentReplies.initiate({
        commentId: "comment-1",
        page: 2,
        limit: 15,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMENTS_URL}/comment-1/replies`);
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("limit")).toBe("15");
    expect(calls[0].method).toBe("GET");
  });

  it("getCommentReplies -> defaults to page=1&limit=20", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).getCommentReplies.initiate({
        commentId: "comment-1",
      })
    );
    const url = new URL(calls[0].url);
    expect(url.searchParams.get("page")).toBe("1");
    expect(url.searchParams.get("limit")).toBe("20");
  });

  it("uploadCommentImage -> PUT /api/v1/comments/:commentId/image with a FormData body (field: image)", async () => {
    // jsdom/whatwg-fetch's Request can't re-serialize or re-read a FormData
    // body (no content-type header gets set, .formData()/.text() both throw
    // -- confirmed by hand against this exact environment), so the network
    // layer can't prove the body shape here. Spying on FormData.append proves
    // the query function itself builds `new FormData()` with the right field
    // name instead, which is what "or FormData presence" comes down to.
    const calls = mockFetch();
    const store = makeStore();
    const file = new File(["fake-bytes"], "photo.jpg", { type: "image/jpeg" });
    const appendSpy = jest.spyOn(FormData.prototype, "append");
    await store.dispatch(
      (momentsApiSlice.endpoints as any).uploadCommentImage.initiate({
        commentId: "comment-1",
        file,
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${COMMENTS_URL}/comment-1/image`);
    expect(calls[0].method).toBe("PUT");
    expect(appendSpy).toHaveBeenCalledWith("image", file);
    appendSpy.mockRestore();
  });

  it("recordMomentViews -> POST /api/v1/moments/views with a views[] batch carrying real per-moment watchedMs/completed", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).recordMomentViews.initiate({
        views: [
          { momentId: "moment-1", watchedMs: 1500, completed: false },
          { momentId: "moment-2", watchedMs: 6000, completed: true },
        ],
      })
    );
    expect(calls).toHaveLength(1);
    const url = new URL(calls[0].url);
    expect(url.pathname).toBe(`${MOMENTS_URL}/views`);
    expect(calls[0].method).toBe("POST");
    const parsed = JSON.parse(calls[0].body as string);
    expect(parsed.views).toEqual([
      { momentId: "moment-1", watchedMs: 1500, completed: false },
      { momentId: "moment-2", watchedMs: 6000, completed: true },
    ]);
  });

  it("recordMomentViews -> sets keepalive:true on the request so pagehide/unload does not cancel the flush", async () => {
    mockFetch();
    const requestCalls = captureRequestInit();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).recordMomentViews.initiate({
        views: [{ momentId: "moment-1", watchedMs: 1500, completed: false }],
      })
    );
    expect(requestCalls.length).toBeGreaterThan(0);
    expect(requestCalls[0].init.keepalive).toBe(true);
  });

  describe("getMoments feed parameter", () => {
    it("produces the exact same URL for {page:1,limit:10} with or without an explicit feed key omitted", async () => {
      const calls = mockFetch();
      const store = makeStore();
      await store.dispatch(
        (momentsApiSlice.endpoints as any).getMoments.initiate({ page: 1, limit: 10 })
      );
      expect(calls).toHaveLength(1);
      expect(new URL(calls[0].url).pathname + new URL(calls[0].url).search).toBe(
        `${MOMENTS_URL}?page=1&limit=10`
      );
    });

    it("appends &feed=following only when feed is given", async () => {
      const calls = mockFetch();
      const store = makeStore();
      await store.dispatch(
        (momentsApiSlice.endpoints as any).getMoments.initiate({
          page: 1,
          limit: 10,
          feed: "following",
        })
      );
      expect(calls).toHaveLength(1);
      expect(new URL(calls[0].url).pathname + new URL(calls[0].url).search).toBe(
        `${MOMENTS_URL}?page=1&limit=10&feed=following`
      );
    });

    it("gives {page:1,limit:10} and {page:1,limit:10,feed:undefined} the same RTK Query cache key", () => {
      // Default serializeQueryArgs is (roughly) JSON.stringify({endpointName,
      // queryArgs}) -- JSON.stringify drops undefined-valued keys, so a
      // `feed` key that's merely undefined never changes the key. This is
      // what actually guarantees the prerender prefetch's cache entry
      // ({page:1,limit:10}, no feed key at all) is still found by a mount
      // that calls useGetMomentsQuery({page:1,limit:10,feed:undefined}).
      const keyA = defaultSerializeQueryArgs({
        endpointName: "getMoments",
        queryArgs: { page: 1, limit: 10 },
        endpointDefinition: undefined as any,
      });
      const keyB = defaultSerializeQueryArgs({
        endpointName: "getMoments",
        queryArgs: { page: 1, limit: 10, feed: undefined },
        endpointDefinition: undefined as any,
      });
      expect(keyA).toBe(keyB);
    });
  });
  describe("addMomentComment sends the field names models/Comment.js stores", () => {
    it("posts { text } for a plain comment", async () => {
      const calls = mockFetch();
      const store = makeStore();
      await store.dispatch(
        (momentsApiSlice.endpoints as any).addMomentComment.initiate({
          momentId: "moment-1",
          text: "Nice one",
        })
      );
      expect(calls).toHaveLength(1);
      expect(new URL(calls[0].url).pathname).toBe(`${MOMENTS_URL}/moment-1/comments`);
      expect(calls[0].method).toBe("POST");
      expect(JSON.parse(calls[0].body as string)).toEqual({ text: "Nice one" });
    });

    it("posts { text, parentComment } for a reply", async () => {
      const calls = mockFetch();
      const store = makeStore();
      await store.dispatch(
        (momentsApiSlice.endpoints as any).addMomentComment.initiate({
          momentId: "moment-1",
          text: "Agreed",
          parentComment: "comment-1",
        })
      );
      expect(JSON.parse(calls[0].body as string)).toEqual({
        text: "Agreed",
        parentComment: "comment-1",
      });
    });

    it("posts { text: '', correction } for a correction with no note -- the server labels it itself", async () => {
      const calls = mockFetch();
      const store = makeStore();
      await store.dispatch(
        (momentsApiSlice.endpoints as any).addMomentComment.initiate({
          momentId: "moment-1",
          correction: {
            originalText: "I go to school yesterday",
            correctedText: "I went to school yesterday",
            explanation: "Past tense.",
          },
        })
      );
      expect(JSON.parse(calls[0].body as string)).toEqual({
        text: "",
        correction: {
          originalText: "I go to school yesterday",
          correctedText: "I went to school yesterday",
          explanation: "Past tense.",
        },
      });
    });
  });
});

describe("addMomentComment media (moments#21)", () => {
  const capture = () => {
    const calls: any[] = [];
    (global as any).fetch = jest.fn(async (req: any) => {
      // CRA's jsdom uses whatwg-fetch, which keeps a FormData body on
      // _bodyFormData and a JSON string on _bodyText.
      calls.push({ url: req.url, method: req.method, form: req._bodyFormData, text: req._bodyText });
      return new Response(JSON.stringify({ success: true, data: { _id: "c1" } }), {
        status: 200, headers: { "content-type": "application/json" },
      });
    });
    return calls;
  };

  it("a photo comment goes up in ONE multipart request with its text", async () => {
    const calls = capture();
    const store = makeStore();
    const file = new File(["x"], "p.jpg", { type: "image/jpeg" });
    await store.dispatch(
      (momentsApiSlice.endpoints as any).addMomentComment.initiate({ momentId: "m1", text: "", image: file, parentComment: "p1" })
    );
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/moments/m1/comments");
    expect(calls[0].form).toBeInstanceOf(FormData);
    expect(calls[0].form.get("image")).toBeInstanceOf(File);
    expect(calls[0].form.get("text")).toBe("");
    expect(calls[0].form.get("parentComment")).toBe("p1");
  });

  it("a GIF comment is JSON with imageUrl", async () => {
    const calls = capture();
    const store = makeStore();
    await store.dispatch(
      (momentsApiSlice.endpoints as any).addMomentComment.initiate({
        momentId: "m1", text: "", imageUrl: "https://media1.giphy.com/media/x/giphy.gif",
      })
    );
    expect(JSON.parse(calls[0].text)).toEqual({ text: "", imageUrl: "https://media1.giphy.com/media/x/giphy.gif" });
  });

  it("a plain comment is unchanged JSON", async () => {
    const calls = capture();
    const store = makeStore();
    await store.dispatch((momentsApiSlice.endpoints as any).addMomentComment.initiate({ momentId: "m1", text: "hi" }));
    expect(JSON.parse(calls[0].text)).toEqual({ text: "hi" });
  });
});
