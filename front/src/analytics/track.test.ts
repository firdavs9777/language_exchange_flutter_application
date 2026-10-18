import { trackEvent, sessionId, buildPayload } from "./track";

const flush = () => new Promise((r) => setTimeout(r, 0));

beforeEach(() => {
  window.sessionStorage.clear();
  (global as any).fetch = jest.fn(async () => new Response(null, { status: 204 }));
});

it("keeps one session id per tab, 32 hex chars", () => {
  const a = sessionId();
  expect(a).toMatch(/^[a-f0-9]{32}$/);
  expect(sessionId()).toBe(a);
  expect(window.sessionStorage.getItem("bt.sid")).toBe(a);
});

it("builds the payload the backend validates", () => {
  const p = buildPayload("store_tap", { placement: "hero", platform: "ios", path: "/x" });
  expect(p).toEqual({
    name: "store_tap", path: "/x", placement: "hero", platform: "ios",
    referrer: null, language: expect.any(String), sessionId: sessionId(),
  });
  expect(buildPayload("page_view", {}).path).toBe(window.location.pathname);
});

it("posts once on success", async () => {
  trackEvent("page_view", { path: "/" });
  await flush();
  expect(global.fetch).toHaveBeenCalledTimes(1);
  const [url, init] = (global.fetch as jest.Mock).mock.calls[0];
  expect(url).toContain("/api/v1/analytics/events");
  expect(init.method).toBe("POST");
  expect(JSON.parse(init.body).name).toBe("page_view");
});

it("retries exactly once, then stays silent", async () => {
  (global as any).fetch = jest.fn(async () => { throw new Error("offline"); });
  expect(() => trackEvent("cta_tap", { placement: "final-cta" })).not.toThrow();
  await flush();
  await flush();
  expect(global.fetch).toHaveBeenCalledTimes(2);
});

it("does not retry a 4xx: the request itself was rejected", async () => {
  (global as any).fetch = jest.fn(async () => new Response(null, { status: 400 }));
  trackEvent("page_view", { path: "/" });
  await flush();
  await flush();
  expect(global.fetch).toHaveBeenCalledTimes(1);
});
