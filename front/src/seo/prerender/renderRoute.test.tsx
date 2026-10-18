/**
 * @jest-environment node
 */

// Jest 27's node sandbox has no global fetch, and creating the RTK Query api
// slice without one prints a console.warn. Stub it before the harness (and the
// app module graph behind it) is loaded, which is why the harness is required
// below rather than imported: ES imports hoist above this assignment.
(global as any).fetch = () => Promise.reject(new Error("no network in tests"));

/* eslint-disable @typescript-eslint/no-var-requires */
const { renderRoute } = require("./renderRoute");
const { PRERENDER_PATHS } = require("../publicRoutes");
const { SEO_PAGES, canonicalUrl } = require("../pages");

jest.setTimeout(30000);

// This is the same harness scripts/prerender.js runs at build time, executed
// here without a DOM so a component that reads window during render fails
// the suite, not the deploy.
describe.each(PRERENDER_PATHS)("prerender %s", (path: string) => {
  it("renders complete HTML with one h1 and route-specific head tags", async () => {
    const out = await renderRoute(path, { prefetch: false });
    expect(out.html.length).toBeGreaterThan(500);
    expect((out.html.match(/<h1[\s>]/g) || []).length).toBe(1);
    expect(out.head).toMatch(/<title[^>]*>[^<]+<\/title>/);

    const page = SEO_PAGES.find((p: any) => p.path === path);
    if (page) {
      expect(out.status).toBe(200);
      expect(out.head).toContain(`href="${canonicalUrl(page.path)}"`);
      expect((out.head.match(/rel="canonical"/g) || []).length).toBe(1);
      expect(out.head).toContain('name="description"');
      expect(out.head).not.toContain("noindex");
    } else {
      expect(out.status).toBe(404);
      expect(out.head).toContain("noindex");
    }
  });
});

it("emits no hydration script from the static router", async () => {
  const out = await renderRoute("/", { prefetch: false });
  expect(out.html).not.toContain("__staticRouterHydrationData");
});

it("shows the curated stat values, not a count-up starting at zero", async () => {
  const out = await renderRoute("/", { prefetch: false });
  expect(out.html).toContain(">137<");
  expect(out.html).toContain(">18<");
});

// The download page decides its store and draws its QR after mount; what the
// crawler gets is the readable page with the box already reserved.
it("prerenders /download with the QR box reserved and the app's JSON-LD", async () => {
  const out = await renderRoute("/download", { prefetch: false });
  expect(out.html).toContain('data-testid="download-qr"');
  expect(out.html).toContain("Download BananaTalk");
  expect(out.html).toContain("utm_campaign=download-page");
  expect(out.head).toContain("SoftwareApplication");
  expect(out.head).toContain("Free, VIP from $9.99");
});

// The two landing pages are compositions of homepage parts, so what is worth
// asserting here is that their own copy -- the phrase each page targets -- is
// in the crawler's HTML, under the right canonical.
it("prerenders /meet with its own headline and canonical", async () => {
  const out = await renderRoute("/meet", { prefetch: false });
  expect(out.html).toContain("Meet people from other countries");
  expect(out.html).toContain("utm_campaign=meet");
  expect((out.html.match(/<h1[\s>]/g) || []).length).toBe(1);
  expect(out.head).toContain('href="https://banatalk.com/meet"');
  expect(out.head).not.toContain("noindex");
});

it("prerenders /learn-korean with Hangul and the tutor note in the DOM", async () => {
  const out = await renderRoute("/learn-korean", { prefetch: false });
  expect(out.html).toContain("Learn Korean by chatting");
  expect(out.html).toContain("주말에 뭐 했어요?");
  expect(out.html).toContain("존댓말");
  expect(out.html).toContain("utm_campaign=learn-korean");
  expect((out.html.match(/<h1[\s>]/g) || []).length).toBe(1);
  expect(out.head).toContain('href="https://banatalk.com/learn-korean"');
});

it("logs a warning per failed prefetch instead of swallowing the failure", async () => {
  const log = jest.fn();
  const out = await renderRoute("/", { prefetch: true, fetchTimeoutMs: 2000, log });
  expect(log).toHaveBeenCalledTimes(2);
  expect(log.mock.calls.every(([m]: [string]) => /prefetch for \/ failed/.test(m))).toBe(true);
  expect(out.html).toContain(">137<");
});

it("logs a warning per failed prefetch for /moments and still renders, with state transferred", async () => {
  const { apiSlice } = require("../../store/slices/apiSlice");
  const log = jest.fn();
  const out = await renderRoute("/moments", { prefetch: true, fetchTimeoutMs: 2000, log });
  expect(log).toHaveBeenCalledTimes(2);
  expect((out.html.match(/<h1[\s>]/g) || []).length).toBe(1);
  expect(typeof out.state[apiSlice.reducerPath].queries).toBe("object");
});

it("returns the api slice state so the client can hydrate from it", async () => {
  const { apiSlice } = require("../../store/slices/apiSlice");
  const out = await renderRoute("/", { prefetch: false });
  const api = out.state[apiSlice.reducerPath];
  expect(api).toBeDefined();
  // Nothing was fetched, but the shape must be there -- and subscriptions,
  // which are client-only, must never cross the wire.
  expect(api.queries).toEqual({});
  expect(api.subscriptions).toEqual({});
});

