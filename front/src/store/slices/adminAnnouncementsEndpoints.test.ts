/**
 * Announcements endpoints (spec 2026-10-12 §5.3) — URL, method and body of
 * each request, asserted on the outgoing Request like adminSlice.test.ts.
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
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: any };

function mockFetch(payload: any = { success: true, data: {} }): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    let body: any = req.body;
    if (body === undefined && req.clone) {
      try {
        body = await req.clone().text();
      } catch {
        // whatwg-fetch can't re-serialize a FormData body (the image upload);
        // only URL and method are asserted for it, as in momentsActionsEndpoints.test.ts.
        body = undefined;
      }
    }
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify(payload), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

const ep = (name: string) => (adminApiSlice.endpoints as any)[name];

it("exports every announcements hook the pages use", () => {
  const slice = adminApiSlice as any;
  [
    "useListAnnouncementsQuery", "useGetAnnouncementQuery", "useCreateAnnouncementMutation",
    "useUpdateAnnouncementMutation", "usePublishAnnouncementMutation", "useEndAnnouncementMutation",
    "useDeleteAnnouncementMutation", "useLazyGetAnnouncementAudienceQuery", "useUploadAnnouncementImageMutation",
  ].forEach((hook) => expect(typeof slice[hook]).toBe("function"));
});

it("list -> GET /admin/announcements?status=", async () => {
  const calls = mockFetch({ success: true, data: [] });
  const result: any = await makeStore().dispatch(ep("listAnnouncements").initiate({ status: "live" }));
  const url = new URL(calls[0].url);
  expect(url.pathname).toBe("/api/v1/admin/announcements");
  expect(url.searchParams.get("status")).toBe("live");
  expect(result.data).toEqual([]);
});

it("create -> POST with the body; update -> PUT /:id without the id in the body", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("createAnnouncement").initiate({ defaultLocale: "en", notify: true }));
  expect(calls[0].method).toBe("POST");
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements");
  expect(JSON.parse(calls[0].body)).toEqual({ defaultLocale: "en", notify: true });

  await store.dispatch(ep("updateAnnouncement").initiate({ id: "a1", priority: 3 }));
  expect(calls[1].method).toBe("PUT");
  expect(new URL(calls[1].url).pathname).toBe("/api/v1/admin/announcements/a1");
  expect(JSON.parse(calls[1].body)).toEqual({ priority: 3 });
});

it("publish sends {at} only when scheduling; end and delete hit their routes", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("publishAnnouncement").initiate({ id: "a1" }));
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements/a1/publish");
  expect(JSON.parse(calls[0].body)).toEqual({});

  await store.dispatch(ep("publishAnnouncement").initiate({ id: "a1", at: "2030-01-01T00:00:00.000Z" }));
  expect(JSON.parse(calls[1].body)).toEqual({ at: "2030-01-01T00:00:00.000Z" });

  await store.dispatch(ep("endAnnouncement").initiate("a1"));
  expect(calls[2].method).toBe("POST");
  expect(new URL(calls[2].url).pathname).toBe("/api/v1/admin/announcements/a1/end");

  await store.dispatch(ep("deleteAnnouncement").initiate("a1"));
  expect(calls[3].method).toBe("DELETE");
  expect(new URL(calls[3].url).pathname).toBe("/api/v1/admin/announcements/a1");
});

it("audience count -> GET /:id/audience-count, unwrapped", async () => {
  const calls = mockFetch({ success: true, data: { count: 12, listed: 40 } });
  const result: any = await makeStore().dispatch(ep("getAnnouncementAudience").initiate("a1"));
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements/a1/audience-count");
  expect(result.data).toEqual({ count: 12, listed: 40 });
});

it("image upload -> POST multipart to /upload-image", async () => {
  const calls = mockFetch({ success: true, data: { url: "https://cdn/x.jpg" } });
  const file = new File(["x"], "x.png", { type: "image/png" });
  const result: any = await makeStore().dispatch(ep("uploadAnnouncementImage").initiate(file));
  expect(calls[0].method).toBe("POST");
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements/upload-image");
  expect(result.data).toEqual({ url: "https://cdn/x.jpg" });
});
