import { makeStore } from "../../store";
import { reelsApiSlice } from "./reelsSlice";
import { MOMENTS_URL } from "../../constants";

function mockFetch(body: any, status = 200) {
  const calls: { url: string; method: string }[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push({ url: req.url, method: req.method });
    return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const reelRow = (id: string) => ({ _id: id, video: { url: `https://cdn.test/${id}.mp4` }, user: { _id: "u", name: "U" } });

it("GET /moments/reels?limit=12 for the first page and normalises the rows", async () => {
  const calls = mockFetch({ success: true, data: [reelRow("a"), { _id: "broken" }], nextCursor: "0.91:1760000000000" });
  const store = makeStore();
  const res: any = await store.dispatch((reelsApiSlice.endpoints as any).getReelsPage.initiate({}));
  const url = new URL(calls[0].url);
  expect(url.pathname).toBe(`${MOMENTS_URL}/reels`);
  expect(url.searchParams.get("limit")).toBe("12");
  expect(url.searchParams.has("before")).toBe(false);
  expect(res.data.reels.map((r: any) => r.id)).toEqual(["a"]);
  expect(res.data.nextCursor).toBe("0.91:1760000000000");
});

it("passes the opaque cursor back verbatim as `before`", async () => {
  const calls = mockFetch({ success: true, data: [], nextCursor: null });
  const store = makeStore();
  const res: any = await store.dispatch(
    (reelsApiSlice.endpoints as any).getReelsPage.initiate({ before: "0.5:1760000000000" })
  );
  expect(new URL(calls[0].url).searchParams.get("before")).toBe("0.5:1760000000000");
  expect(res.data).toEqual({ reels: [], nextCursor: null });
});

it("GET /moments/video-config and falls back to safe defaults", async () => {
  const calls = mockFetch({ success: true, data: { video: { allowedTypes: ["video/mp4"], maxSize: 1000 } } });
  const store = makeStore();
  const res: any = await store.dispatch((reelsApiSlice.endpoints as any).getReelVideoConfig.initiate(undefined));
  expect(new URL(calls[0].url).pathname).toBe(`${MOMENTS_URL}/video-config`);
  expect(res.data).toEqual({ allowedTypes: ["video/mp4"], maxSize: 1000 });

  mockFetch({ success: true, data: {} });
  const store2 = makeStore();
  const res2: any = await store2.dispatch((reelsApiSlice.endpoints as any).getReelVideoConfig.initiate(undefined));
  expect(res2.data.allowedTypes).toContain("video/mp4");
  expect(res2.data.maxSize).toBe(1024 * 1024 * 1024);
});
