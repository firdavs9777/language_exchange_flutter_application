import { prefetchersFor } from "./prefetch";
import { makeStore } from "../../store";

it("prefetches plans and public stats for the homepage, nothing for legal pages", async () => {
  const calls: string[] = [];
  (global as any).fetch = jest.fn(async (input: any) => {
    calls.push(typeof input === "string" ? input : input.url);
    return new Response(JSON.stringify({ success: true, data: [] }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  });

  const store = makeStore();
  await Promise.all(prefetchersFor("/").map((run) => run(store)));
  expect(calls.some((u) => u.includes("/purchases/plans"))).toBe(true);
  expect(calls.some((u) => u.includes("/public/stats"))).toBe(true);

  expect(prefetchersFor("/privacy-policy")).toEqual([]);
});

it("prefetches the public moments feed and prompt of the day for /moments, nothing for /download", async () => {
  const calls: string[] = [];
  (global as any).fetch = jest.fn(async (input: any) => {
    calls.push(typeof input === "string" ? input : input.url);
    return new Response(JSON.stringify({ success: true, data: [] }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  });

  const prefetchers = prefetchersFor("/moments");
  expect(prefetchers.length).toBe(2);

  const store = makeStore();
  await Promise.all(prefetchers.map((run) => run(store)));
  expect(calls.some((u) => u.includes("/moments?"))).toBe(true);
  expect(calls.some((u) => u.includes("/moments/prompt-of-day"))).toBe(true);

  expect(prefetchersFor("/download")).toEqual([]);
});

it("rejects when the network is unreachable, so renderRoute can log it", async () => {
  (global as any).fetch = jest.fn(async () => {
    throw new Error("offline");
  });

  // fetchBaseQuery turns a thrown fetch error into a resolved
  // { error: { status: "FETCH_ERROR", ... } } result (a plain object, not an
  // Error instance) -- .unwrap() still rejects with it, but toThrow()
  // specifically expects an Error, so assert the rejection itself here.
  await expect(
    Promise.all(prefetchersFor("/").map((run) => run(makeStore())))
  ).rejects.toBeTruthy();
});

// /communities is members-only and not prerendered (src/seo/pages.ts), so
// nothing is fetched for it at build time.
it("prefetches nothing for /communities", () => {
  expect(prefetchersFor("/communities")).toEqual([]);
});
