# Reach (Phase A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make BananaTalk's public web pages readable by search engines and measurable by the business: per-route metadata, static HTML for every public route, a truthful sitemap and 404, GA4 behind consent plus first-party events, and a public stats endpoint so the homepage can show a real learner count.

**Architecture:** The route tree moves into its own module so both the browser (`createBrowserRouter`) and a build-time Node script (`createStaticHandler` + `StaticRouterProvider`) render the same tree. A `RouteMeta` component mounted once in `App` looks the current path up in one SEO map (`src/seo/pages.ts`) and renders the full tag set for indexed pages or `noindex` for everything else. After `react-scripts build`, `scripts/prerender.js` renders each public route with `renderToString`, prefetching the RTK Query data the page needs, and writes `build/<route>/index.html` plus `build/sitemap.xml`. Measurement is two independent channels: GA4 loaded only after a consent bar is accepted, and a first-party `POST /analytics/events` that never depends on consent because it stores no identifier beyond a per-tab session id and a salted IP hash.

**Tech Stack:** React 18.3 + TypeScript **3.7.2** (pinned; see constraints), CRA `react-scripts` 5.0.1 (Jest 27, jsdom), react-router-dom 6.23.1, RTK Query, react-i18next, `react-helmet-async@1.3.0`, `@babel/register@^7`, Tailwind. Backend: Express + Mongoose, `node:test` with `mongodb-memory-server`, `supertest`, `express-rate-limit`.

**Spec:** `docs/superpowers/specs/2026-09-22-reach-marketing-admin-design.md` — this plan implements **§3, §4 (all of Phase A), §7.1, §7.3, §8, §9 (the Phase A tests), §10, §11**. Phases B and C get their own plans once this ships.

## Global Constraints

- **Two repos, two branches.** Frontend: `/Users/davis/Desktop/Personal/language_exchange_web_front`, branch `feat/reach` off `main`. Backend: `/Users/davis/Desktop/Personal/language_exchange_backend_application`, branch `feat/reach` off its default branch. Every task below says which repo it is in; every command is run from that repo's root. Never work directly on `main`.
- **Frontend test command:** `CI=true npx react-scripts test --testPathPattern=<pattern>`. Without `CI=true` it hangs in watch mode. Full suite: `CI=true npx react-scripts test`. Current baseline: 61 suites / 303 tests, all green.
- **Backend test command:** `node --test test/<file>.test.js` from the backend root (uses `node:test`; Node 25 is installed). Tests create a `MongoMemoryServer`; nothing touches a real database.
- **Type check:** `npx tsc` is unusable here (TypeScript 3.7.2 cannot parse Tailwind's types). The type check is `GENERATE_SOURCEMAP=false npx react-scripts build` (its ForkTsChecker runs the pinned 3.7.2). Run it at the end of Tasks 5, 8 and 10.
- **TypeScript 3.7.2 syntax rules:** no `import type` (3.8), no `export type { }` (3.8), no `#private`, no `as const` on tuples requiring 3.4+ is fine (3.4 shipped it). Optional chaining `?.` and `??` **are** allowed (3.7). Library `.d.ts` files must also parse under 3.7: `react-helmet-async` is pinned to `1.3.0` (verified: its `index.d.ts` has none of the forbidden syntax). Do not upgrade it.
- **Render-time discipline (spec §4.2):** on any component that renders on a public route, `window`, `document`, `navigator`, `localStorage`, `sessionStorage` and `matchMedia` are read only inside `useEffect`/event handlers or behind `typeof window === "undefined"` guards. In Node those globals do not exist, so a violation is a `ReferenceError` that fails the prerender, which is the intended loud failure.
- **Copy idiom:** `t("key") || "English fallback"`; i18n returns `""` on a missing key, so the fallback works. New keys go to `src/utils/locales/eng.json` **and** the other 17 locale files (`ar de es fr hi id it ja kor pt ru th tl tr vi zh_TW zho`) via `scripts/i18n/merge-keys.js` (Task 3). Brand names (BananaTalk, App Store, Google Play) and numbers stay verbatim in translations. The locale files are 2-space-indented JSON ending in a newline; the merge script preserves that.
- **Public paths (spec §3, Phase A subset):** `/`, `/download`, `/moments`, `/privacy-policy`, `/terms-of-use`, `/support`, `/data-deletion`, plus `/404` (prerendered as `build/404.html`, noindex). `/communities` and `/profile/:userId` join in Phase B. Canonical URLs have no trailing slash and no query string; `SITE_ORIGIN` is `https://banatalk.com`.
- **Never fail the build on data.** Prefetch failures at prerender time are warnings; render errors, a missing `<h1>`, or a missing `<title>` fail the build.
- **Commits:** one per task, message in the repo's conventional style (`feat(seo): …`, `test(...)`, `chore(...)`), body explains why, and end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

---

## File Structure

**Frontend — new files**

| File | Responsibility |
|---|---|
| `src/router/routes.tsx` | The route tree (`createRoutesFromElements`), shared by browser and prerender. Includes the `*` NotFound route. |
| `src/seo/pages.ts` | `SEO_PAGES` map: path → i18n keys, primary/secondary phrases; `findSeoPage`, `canonicalUrl`, `SITE_ORIGIN`. |
| `src/seo/i18nFallback.ts` | `englishFallback(key)`: reads `eng.json` by dotted path, for `t(key) || englishFallback(key)`. |
| `src/seo/PageMeta.tsx` | Renders the head tag set through `react-helmet-async` for one page, or the noindex form. |
| `src/seo/RouteMeta.tsx` | Mounted once in `App`; picks `PageMeta` for the current location. |
| `src/seo/publicRoutes.ts` | `PRERENDER_PATHS`, `SITEMAP_PATHS` derived from `SEO_PAGES`. |
| `src/seo/prerender/requestShim.ts` | `makeRequest(url)`: real `Request` in Node, minimal shape in Jest 27. |
| `src/seo/prerender/prefetch.ts` | `prefetchersFor(path)`: RTK Query `initiate()` thunks to await before rendering a path. |
| `src/seo/prerender/renderRoute.tsx` | `renderRoute(path)`: fresh store → prefetch → static handler → `renderToString` → `{ html, head, status }`, with the loud-failure checks. |
| `src/seo/prerender/template.ts` | `injectIntoTemplate(template, rendered)`: swaps head tags and fills `#root`. Pure. |
| `src/seo/prerender/sitemap.ts` | `buildSitemap(paths, date)`. Pure. |
| `src/seo/prerender/hydrationFlag.ts` | `markPrerendered()` / `isPrerendered()`: lets animations skip their "hidden first" state when hydrating. |
| `src/utils/hydrationLanguage.ts` | `prepareForHydration(i18n)` / `restoreAfterHydration(i18n)`: first client render in English, visitor's language after commit, stored choice preserved. |
| `src/components/errors/NotFound.tsx` | The 404 page. |
| `src/store/slices/publicStatsSlice.ts` | `getPublicStats` query + `formatCount`. |
| `src/analytics/track.ts` | `trackEvent(name, data)`: first-party events, one retry, silent. |
| `src/analytics/consent.ts` | `readConsent()` / `writeConsent()` over `localStorage["bt.consent"]`. |
| `src/analytics/ga.ts` | `loadGa(id)`, `gaEvent(name, params)`; no-ops without an ID or before load. |
| `src/analytics/usePageView.ts` | Fires the legacy visit ping, `trackEvent("page_view")` and `gaEvent("page_view")` on route change. |
| `src/components/growth/surfaceRegistry.ts` | Tiny registry so the consent bar can hide while the download popup is open. |
| `src/components/growth/ConsentBar.tsx` | The consent bar. Renders nothing until mounted. |
| `scripts/register.js` | Node module hooks: Babel for TS/JSX, stubs for styles, hashed URLs for media, `.env.production`. |
| `scripts/prerender.js` | The build step: renders `PRERENDER_PATHS`, writes files and the sitemap. |
| `scripts/i18n/merge-keys.js` | Deep-merges a `{ locale: {...} }` JSON into all 18 locale files. |
| `deploy/nginx.snippet.conf` | 404 status, 301s and 410s for the old sitemap URLs. Applied by hand on the server. |
| `README.md` | Deploy section: build, prerender, nginx snippet, GA ID. |

**Frontend — modified files:** `src/router/AppRouter.tsx`, `src/store/index.ts` (adds `makeStore`), `src/store/slices/authSlice.ts` (guard), `src/index.tsx` (HelmetProvider, hydrate chooser), `src/App.tsx` (RouteMeta, usePageView, ConsentBar, language restore), `src/components/linking/AppBanner.tsx`, `src/components/growth/PromoCarousel.tsx`, `src/components/growth/StickyAppBanner.tsx`, `src/components/growth/AppDownloadPopup.tsx`, `src/components/home/anim/useInView.ts`, `src/components/home/anim/useCountUp.ts`, `src/components/home/parts/StatStrip.tsx`, `src/components/navbar/TermsOfUse.tsx`, `src/components/footer/FooterMain.tsx`, `src/constants.ts`, `src/utils/locales/*.json`, `public/index.html`, `public/manifest.json`, `package.json`, `.env.production`; **deleted:** `public/sitemap.xml`.

**Backend — new files:** `routes/public.js`, `controllers/public.js`, `controllers/webEvents.js`, `models/WebEvent.js`, `utils/parseUserAgent.js`, `test/publicStats.test.js`, `test/webEvents.test.js`. **Modified:** `server.js` (one mount line), `routes/analytics.js` (uses the shared parser, adds `POST /events`), `middleware/rateLimiter.js` (adds `analyticsLimiter`).

---

### Task 1: Extract the route tree and make the app importable without a DOM

The prerender step must `require` the route tree in plain Node. Today `AppRouter.tsx` calls `createBrowserRouter` at import (reads `window.location`) and `authSlice.ts` reads `localStorage` while computing its initial state at import. Both break a Node import.

**Files:**
- Create: `src/router/routes.tsx`
- Modify: `src/router/AppRouter.tsx` (whole file), `src/store/index.ts` (whole file), `src/store/slices/authSlice.ts:49-51`
- Test: `src/router/routes.test.tsx`

**Interfaces:**
- Produces: `export const routes: RouteObject[]` from `src/router/routes.tsx`; `export function makeStore()`, `export type AppStore`, `export type RootState` and default `store` from `src/store/index.ts`.

- [ ] **Step 1: Create the branch**

```bash
git checkout main && git pull --ff-only origin main
git checkout -b feat/reach
```

- [ ] **Step 2: Write the failing test**

Create `src/router/routes.test.tsx`:

```tsx
/**
 * @jest-environment node
 */
// Runs without a DOM on purpose: the prerender step requires this module in
// plain Node, so importing it must never touch window, document or storage.
import { matchRoutes } from "react-router-dom";

const PUBLIC_PATHS = [
  "/", "/download", "/moments", "/privacy-policy", "/terms-of-use", "/support", "/data-deletion",
];

it("imports without a DOM", () => {
  expect(typeof window).toBe("undefined");
  const { routes } = require("./routes");
  expect(routes[0].path).toBe("/");
  expect(routes[0].children.length).toBeGreaterThan(30);
});

it("matches every public marketing path to a layout plus a page", () => {
  const { routes } = require("./routes");
  for (const path of PUBLIC_PATHS) {
    const matches = matchRoutes(routes, path);
    expect(matches && matches.length).toBe(2);
    expect(matches![1].route.path).not.toBe("*");
  }
});
```

- [ ] **Step 3: Run it to confirm it fails**

Run: `CI=true npx react-scripts test --testPathPattern=router/routes`
Expected: FAIL with `Cannot find module './routes'`.

- [ ] **Step 4: Create `src/router/routes.tsx`**

Move everything from `src/router/AppRouter.tsx` except the `createBrowserRouter` call. The file is the current `AppRouter.tsx` with these changes: the import line drops `createBrowserRouter`; the `const AppRouter = createBrowserRouter(` wrapper becomes `export const routes = ` and the trailing `);` closes only `createRoutesFromElements(...)`.

```tsx
import {
  createRoutesFromElements,
  Route,
  useParams,
} from "react-router-dom";
import App from "../App";
// ... every other existing import from AppRouter.tsx, unchanged ...

const MainChatWrapper = () => {
  const { userId } = useParams();
  return <MainChat key={userId || "no-user"} />;
};

// One route tree, two consumers: AppRouter.tsx wraps it in createBrowserRouter
// for the browser; scripts/prerender.js feeds it to createStaticHandler. Keep
// this module free of anything that touches window at import time.
export const routes = createRoutesFromElements(
  <Route path="/" element={<App />}>
    {/* ...every existing <Route> from AppRouter.tsx, unchanged... */}
  </Route>
);
```

- [ ] **Step 5: Reduce `src/router/AppRouter.tsx` to the browser wrapper**

Replace the whole file with:

```tsx
import { createBrowserRouter } from "react-router-dom";
import { routes } from "./routes";

// Browser-only: createBrowserRouter reads window.location when created. The
// prerender step imports ./routes directly and never this file.
const AppRouter = createBrowserRouter(routes);

export default AppRouter;
```

- [ ] **Step 6: Run the test; expect the storage error**

Run: `CI=true npx react-scripts test --testPathPattern=router/routes`
Expected: FAIL with `ReferenceError: localStorage is not defined` at `src/store/slices/authSlice.ts:50` (reached through `App → useSocket → authSlice`). If instead a third-party module throws at import (message names a file under `node_modules`), see Step 8.

- [ ] **Step 7: Guard the auth slice's initial read**

In `src/store/slices/authSlice.ts`, change the start of `getInitialUserInfo`:

```ts
const getInitialUserInfo = () => {
  // No storage without a browser (prerender, node tests): start logged out.
  if (typeof window === "undefined") return null;
  const storedRaw = localStorage.getItem("userInfo");
  if (!storedRaw) return null;
```

- [ ] **Step 8 (only if Step 6 named a `node_modules` file): defer that component**

If a chat-only or settings-only dependency throws at import in Node, wrap **that route's component only** in `React.lazy` inside `routes.tsx`, e.g. for the chat page:

```tsx
const MainChat = React.lazy(() => import("../components/chat/MainChat"));
// ...
<Route path="chat/:userId?" element={<React.Suspense fallback={null}><MainChatWrapper /></React.Suspense>} />
```

(add `import React from "react"` to the file). Lazy modules are never loaded for a route that is not rendered, so the prerender never touches them. Record which components were deferred in the commit body; Phase B's code-splitting task turns this into the general rule.

- [ ] **Step 9: Expose `makeStore`**

Replace `src/store/index.ts` with:

```ts
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./slices/apiSlice";
import momentSliceReducer from "./slices/momentsSlice";
import authSliceReducer from "./slices/authSlice";
import commentsSliceReducer from "./slices/comments";
import chatApiSliceReducer from "./slices/chatSlice";
import storiesApiSliceReducer from "./slices/storiesSlice";

/** A fresh store. The browser makes one; the prerender makes one per route. */
export function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      moments: momentSliceReducer,
      auth: authSliceReducer,
      comments: commentsSliceReducer,
      chats: chatApiSliceReducer,
      stories: storiesApiSliceReducer,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
    devTools: true,
  });
}

const store = makeStore();

export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;

export default store;
```

- [ ] **Step 10: Run the test and the full suite**

Run: `CI=true npx react-scripts test --testPathPattern=router/routes`
Expected: PASS (2 tests).
Run: `CI=true npx react-scripts test`
Expected: 62 suites pass. (`MainNavbar.test.tsx` builds its own store and is unaffected.)

- [ ] **Step 11: Commit**

```bash
git add src/router src/store/index.ts src/store/slices/authSlice.ts
git commit -m "refactor(router): extract the route tree; make the app importable without a DOM

createBrowserRouter ran at import and authSlice read localStorage while
building its initial state, so nothing under src/ could be required in
plain Node. The prerender step needs exactly that. routes.tsx now owns the
tree; AppRouter.tsx only wraps it for the browser; makeStore() gives the
prerender a fresh store per route.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Move render-time browser reads into effects

Four components read browser state while rendering. In Node that throws; in the browser it makes the first client render differ from the prerendered HTML. Each becomes "render nothing (or the neutral state) until mounted, then decide".

**Files:**
- Modify: `src/components/linking/AppBanner.tsx:1,26-31`, `src/components/growth/PromoCarousel.tsx:1,16-22`, `src/components/growth/StickyAppBanner.tsx:1,11-17`, `src/components/navbar/TermsOfUse.tsx:8`
- Test: `src/components/linking/AppBanner.test.tsx`, `src/components/growth/ssr.test.tsx`

- [ ] **Step 1: Write the failing tests**

Create `src/components/growth/ssr.test.tsx`:

```tsx
/**
 * @jest-environment node
 */
import React from "react";
import { renderToString } from "react-dom/server";
import PromoCarousel from "./PromoCarousel";
import StickyAppBanner from "./StickyAppBanner";

// The growth surfaces decide whether to show from the viewport, referrer and
// stored dismissals -- none of which exist at prerender time. They render
// nothing on the server and decide after mount, so prerendered HTML and the
// first client render agree.
it("PromoCarousel renders nothing without a DOM", () => {
  expect(renderToString(<PromoCarousel />)).toBe("");
});

it("StickyAppBanner renders nothing without a DOM", () => {
  expect(renderToString(<StickyAppBanner />)).toBe("");
});
```

Create `src/components/linking/AppBanner.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { MemoryRouter } from "react-router-dom";
import AppBanner from "./AppBanner";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (_key: string, fallback: string) => fallback }),
}));
jest.mock("./OpenInApp", () => () => <a href="#open">Open</a>);

const IPHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)";
const MAC = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)";
const setUserAgent = (ua: string) =>
  Object.defineProperty(window.navigator, "userAgent", { writable: true, configurable: true, value: ua });

const at = (path: string) => (
  <MemoryRouter initialEntries={[path]}>
    <AppBanner />
  </MemoryRouter>
);

it("renders nothing on the server pass, even for a phone on a deep-linkable route", () => {
  setUserAgent(IPHONE);
  expect(renderToString(at("/moment/abc123"))).toBe("");
});

it("shows the banner after mount for a phone on a moment page", () => {
  setUserAgent(IPHONE);
  render(at("/moment/abc123"));
  expect(screen.getByText("Open this in the BananaTalk app")).toBeInTheDocument();
});

it("stays hidden on desktop", () => {
  setUserAgent(MAC);
  render(at("/moment/abc123"));
  expect(screen.queryByText("Open this in the BananaTalk app")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `CI=true npx react-scripts test --testPathPattern='(growth/ssr|AppBanner)'`
Expected: `ssr.test.tsx` fails with `ReferenceError: window is not defined`; the first `AppBanner` test fails because the banner markup is non-empty.

- [ ] **Step 3: Fix `AppBanner`**

In `src/components/linking/AppBanner.tsx`, change the imports and the top of the component:

```tsx
import React, { useEffect, useState } from 'react';
// ...
import { detectPlatform, MobilePlatform } from '../../utils/platform';
```

```tsx
const AppBanner: React.FC = () => {
  const location = useLocation();
  const [dismissed, setDismissed] = useState(false);
  // Unknown until mounted: the prerender has no user agent, and the first
  // client render must match the prerendered (empty) output.
  const [platform, setPlatform] = useState<MobilePlatform | null>(null);
  const { t } = useTranslation();

  useEffect(() => {
    setPlatform(detectPlatform(navigator.userAgent));
  }, []);

  if (dismissed) return null;
  if (platform === null || platform === 'other') return null;
```

(The rest of the component is unchanged.)

- [ ] **Step 4: Fix `PromoCarousel`**

In `src/components/growth/PromoCarousel.tsx`, replace lines 16-22 (the `dismissed` initializer) with:

```tsx
  // Hidden until mounted. Suppression depends on viewport, referrer and
  // stored dismissals, none of which exist at prerender time; deciding in an
  // effect keeps the prerendered HTML and the first client render identical.
  const [dismissed, setDismissed] = useState(true);

  useEffect(() => {
    setDismissed(
      isSuppressed("promo-carousel", {
        pathname: window.location.pathname,
        referrer: document.referrer,
        viewportWidth: window.innerWidth,
      })
    );
  }, []);
```

- [ ] **Step 5: Fix `StickyAppBanner`**

In `src/components/growth/StickyAppBanner.tsx`, change the React import to `import React, { useCallback, useEffect, useState } from "react";` and replace lines 11-17 with:

```tsx
  // Hidden until mounted, for the same reason as PromoCarousel.
  const [hidden, setHidden] = useState(true);

  useEffect(() => {
    setHidden(
      isSuppressed("sticky-banner", {
        pathname: window.location.pathname,
        referrer: document.referrer,
        viewportWidth: window.innerWidth,
      })
    );
  }, []);
```

- [ ] **Step 6: Give the Terms page an `h1`**

`src/components/navbar/TermsOfUse.tsx:8` is `<h2 className="mb-3">Terms of Use</h2>`. Every prerendered page needs exactly one `h1`. Change it to:

```tsx
        <h1 className="mb-3 h2">Terms of Use</h1>
```

(Bootstrap's `.h2` class keeps the visual size.)

- [ ] **Step 7: Run the affected suites**

Run: `CI=true npx react-scripts test --testPathPattern='(growth|AppBanner|linking)'`
Expected: PASS, including the existing `PromoCarousel.test.tsx` and `growthSurfaces.test.tsx` (Testing Library's `render` flushes effects, so surfaces that were visible on first render are still visible after render).

- [ ] **Step 8: Commit**

```bash
git add src/components/linking src/components/growth src/components/navbar/TermsOfUse.tsx
git commit -m "fix(ssr): decide growth surfaces and the app banner after mount, not during render

AppBanner read navigator.userAgent and PromoCarousel/StickyAppBanner read
window and document in their useState initializers. In Node that throws;
in the browser it made the first client render differ from prerendered
HTML. Each now renders nothing until mounted, then decides. TermsOfUse
gains the h1 every prerendered page must have.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: The metadata layer — SEO map, PageMeta, RouteMeta, locale keys

**Files:**
- Create: `src/seo/pages.ts`, `src/seo/i18nFallback.ts`, `src/seo/PageMeta.tsx`, `src/seo/RouteMeta.tsx`, `scripts/i18n/merge-keys.js`
- Modify: `src/App.tsx`, `src/index.tsx`, `src/utils/locales/*.json` (18 files), `public/index.html:71-89,232`, `public/manifest.json`
- Test: `src/seo/pages.test.ts`, `src/seo/RouteMeta.test.tsx`, `src/utils/locales/localeParity.test.ts`

**Interfaces:**
- Produces: `SEO_PAGES`, `SeoPage`, `findSeoPage(pathname)`, `normalizePath`, `canonicalUrl(path)`, `SITE_ORIGIN`, `DEFAULT_OG_IMAGE` (from `pages.ts`); `englishFallback(key)`, `getByPath(obj, path)` (from `i18nFallback.ts`); `<PageMeta route|noindex|title|values />`; `<RouteMeta />`.

- [ ] **Step 1: Install the helmet library**

```bash
npm install react-helmet-async@1.3.0
```

Confirm `package.json` shows `"react-helmet-async": "^1.3.0"`.

- [ ] **Step 2: Write the failing tests**

Create `src/seo/pages.test.ts`:

```ts
import { matchRoutes } from "react-router-dom";
import en from "../utils/locales/eng.json";
import { routes } from "../router/routes";
import { SEO_PAGES, findSeoPage, canonicalUrl, normalizePath } from "./pages";
import { getByPath } from "./i18nFallback";

describe("SEO map", () => {
  it("every entry is a real route", () => {
    for (const page of SEO_PAGES) {
      const matches = matchRoutes(routes, page.path);
      expect(matches && matches.length).toBe(2);
      expect(matches![1].route.path).not.toBe("*");
    }
  });

  it("titles fit a result line and descriptions fit a snippet", () => {
    for (const page of SEO_PAGES) {
      const title = getByPath(en, page.titleKey);
      const description = getByPath(en, page.descriptionKey);
      expect(title.length).toBeGreaterThan(0);
      expect(title.length).toBeLessThanOrEqual(60);
      expect(description.length).toBeGreaterThan(0);
      expect(description.length).toBeLessThanOrEqual(160);
    }
  });

  it("no two pages share a title", () => {
    const titles = SEO_PAGES.map((p) => getByPath(en, p.titleKey));
    expect(new Set(titles).size).toBe(titles.length);
  });

  it("each title carries the phrase it targets", () => {
    for (const page of SEO_PAGES) {
      expect(getByPath(en, page.titleKey).toLowerCase()).toContain(page.primary.toLowerCase());
    }
  });

  it("normalizes trailing slashes and builds canonical URLs", () => {
    expect(normalizePath("/privacy-policy/")).toBe("/privacy-policy");
    expect(normalizePath("/")).toBe("/");
    expect(findSeoPage("/privacy-policy/")!.path).toBe("/privacy-policy");
    expect(findSeoPage("/chat")).toBeUndefined();
    expect(canonicalUrl("/")).toBe("https://banatalk.com");
    expect(canonicalUrl("/download")).toBe("https://banatalk.com/download");
  });
});
```

Create `src/seo/RouteMeta.test.tsx`:

```tsx
import React from "react";
import { renderToString } from "react-dom/server";
import { HelmetProvider } from "react-helmet-async";
import { MemoryRouter } from "react-router-dom";
import RouteMeta from "./RouteMeta";

// t returns "" so the English fallback path is exercised, exactly as a locale
// with a missing key would behave in production.
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

function headFor(path: string) {
  const ctx: any = {};
  renderToString(
    <HelmetProvider context={ctx}>
      <MemoryRouter initialEntries={[path]}>
        <RouteMeta />
      </MemoryRouter>
    </HelmetProvider>
  );
  const h = ctx.helmet;
  return [h.title.toString(), h.meta.toString(), h.link.toString()].join("\n");
}

it("renders the indexable tag set for the homepage", () => {
  const head = headFor("/");
  expect(head).toContain("<title data-rh=\"true\">BananaTalk: Free Language Exchange App with Native Speakers</title>");
  expect(head).toContain('name="description"');
  expect(head).toContain('rel="canonical" href="https://banatalk.com"');
  expect(head).toContain('property="og:url" content="https://banatalk.com"');
  expect(head).toContain('name="twitter:card" content="summary_large_image"');
  expect(head).toContain('name="robots" content="index, follow');
});

it("drops the trailing slash from the canonical", () => {
  expect(headFor("/privacy-policy/")).toContain('href="https://banatalk.com/privacy-policy"');
});

it("marks app-only routes noindex with a plain title", () => {
  const head = headFor("/chat");
  expect(head).toContain('name="robots" content="noindex, nofollow"');
  expect(head).toContain("<title data-rh=\"true\">BananaTalk</title>");
  expect(head).not.toContain('rel="canonical"');
});
```

Create `src/utils/locales/localeParity.test.ts`:

```ts
import fs from "fs";
import path from "path";

// Namespaces introduced by the reach work. Every locale must carry exactly the
// English key set, so a missing translation is a failing test rather than a
// silent fallback. Later tasks append to this list.
const NAMESPACES = ["seo"];

const dir = __dirname;
const files = fs.readdirSync(dir).filter((f) => f.endsWith(".json"));
const read = (f: string) => JSON.parse(fs.readFileSync(path.join(dir, f), "utf8"));
const flatten = (o: any, prefix = ""): string[] =>
  Object.entries(o).flatMap(([k, v]) =>
    v && typeof v === "object" ? flatten(v, `${prefix}${k}.`) : [`${prefix}${k}`]
  );
const en = read("eng.json");

describe.each(NAMESPACES)("locale parity: %s", (ns) => {
  const expected = flatten(en[ns] || {}).sort();

  it("exists in English", () => {
    expect(expected.length).toBeGreaterThan(0);
  });

  it.each(files)("%s carries the same keys as English", (file) => {
    const value = read(file)[ns];
    expect(value ? flatten(value).sort() : null).toEqual(expected);
  });

  it("has 18 locale files", () => {
    expect(files.length).toBe(18);
  });
});
```

- [ ] **Step 3: Run them to confirm they fail**

Run: `CI=true npx react-scripts test --testPathPattern='(seo/|localeParity)'`
Expected: FAIL — `Cannot find module './pages'`, `'./RouteMeta'`, and the parity suite fails on "exists in English".

- [ ] **Step 4: Create `src/seo/pages.ts`**

```ts
export const SITE_ORIGIN = "https://banatalk.com";
export const DEFAULT_OG_IMAGE = `${SITE_ORIGIN}/og-image.png`;

export interface SeoContext {
  url: string;
}

export interface SeoPage {
  /** Route path without trailing slash; "/" for the homepage. */
  path: string;
  /** i18n keys; English lives in eng.json and is the fallback everywhere. */
  titleKey: string;
  descriptionKey: string;
  /** The phrase the title (and the page's h1) targets. Asserted by test, never rendered. */
  primary: string;
  /** Supporting phrases for body copy. Documentation for the copywriter. */
  secondary: string[];
  jsonLd?: (ctx: SeoContext) => object | object[];
  ogImage?: string;
}

// The keyword map. One entry per indexed route. Phase B adds /meet,
// /learn-korean and /communities here and nowhere else: RouteMeta, the
// prerender list and the sitemap all derive from this array.
export const SEO_PAGES: SeoPage[] = [
  {
    path: "/",
    titleKey: "seo.home.title",
    descriptionKey: "seo.home.description",
    primary: "language exchange app",
    secondary: ["practice speaking with native speakers", "free language exchange", "chat with native speakers"],
  },
  {
    path: "/download",
    titleKey: "seo.download.title",
    descriptionKey: "seo.download.description",
    primary: "download bananatalk",
    secondary: ["language exchange app for iphone", "language exchange app for android"],
  },
  {
    path: "/moments",
    titleKey: "seo.moments.title",
    descriptionKey: "seo.moments.description",
    primary: "moments",
    secondary: ["language learning stories", "post in your target language"],
  },
  { path: "/privacy-policy", titleKey: "seo.privacy.title", descriptionKey: "seo.privacy.description", primary: "privacy policy", secondary: [] },
  { path: "/terms-of-use", titleKey: "seo.terms.title", descriptionKey: "seo.terms.description", primary: "terms of use", secondary: [] },
  { path: "/support", titleKey: "seo.support.title", descriptionKey: "seo.support.description", primary: "support", secondary: ["contact bananatalk"] },
  { path: "/data-deletion", titleKey: "seo.dataDeletion.title", descriptionKey: "seo.dataDeletion.description", primary: "data deletion", secondary: [] },
];

export function normalizePath(pathname: string): string {
  const trimmed = pathname.replace(/\/+$/, "");
  return trimmed === "" ? "/" : trimmed;
}

export function findSeoPage(pathname: string): SeoPage | undefined {
  const p = normalizePath(pathname);
  return SEO_PAGES.find((page) => page.path === p);
}

export function canonicalUrl(path: string): string {
  return path === "/" ? SITE_ORIGIN : `${SITE_ORIGIN}${path}`;
}
```

- [ ] **Step 5: Create `src/seo/i18nFallback.ts`**

```ts
import en from "../utils/locales/eng.json";

/** Reads a dotted key from a locale object; "" when absent or not a string. */
export function getByPath(obj: any, key: string): string {
  const value = key.split(".").reduce((acc, part) => (acc == null ? undefined : acc[part]), obj);
  return typeof value === "string" ? value : "";
}

/** The English string for a key, for the `t(key) || englishFallback(key)` idiom. */
export function englishFallback(key: string): string {
  return getByPath(en, key);
}
```

- [ ] **Step 6: Create `src/seo/PageMeta.tsx`**

```tsx
import React from "react";
import { Helmet } from "react-helmet-async";
import { useTranslation } from "react-i18next";
import { SEO_PAGES, canonicalUrl, DEFAULT_OG_IMAGE } from "./pages";
import { englishFallback } from "./i18nFallback";

export interface PageMetaProps {
  /** A path from SEO_PAGES. Renders the full indexable tag set. */
  route?: string;
  /** App-only pages: noindex, plain title, no canonical or Open Graph tags. */
  noindex?: boolean;
  /** Overrides the title: with `noindex`, or on dynamic routes once data has loaded. */
  title?: string;
  /** Interpolation values for the title/description keys ({{name}} etc.). */
  values?: Record<string, string>;
}

const INDEX_ROBOTS = "index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1";
const NOINDEX_ROBOTS = "noindex, nofollow";

const PageMeta: React.FC<PageMetaProps> = ({ route, noindex = false, title, values }) => {
  const { t } = useTranslation();
  const tr = (key: string) => (t(key, values as any) as string) || englishFallback(key);
  const page = route ? SEO_PAGES.find((p) => p.path === route) : undefined;

  if (noindex || !page) {
    const plain = title || tr("seo.appTitle") || "BananaTalk";
    return (
      <Helmet>
        <title>{plain}</title>
        <meta name="robots" content={NOINDEX_ROBOTS} />
      </Helmet>
    );
  }

  const resolvedTitle = title || tr(page.titleKey);
  const description = tr(page.descriptionKey);
  const url = canonicalUrl(page.path);
  const image = page.ogImage || DEFAULT_OG_IMAGE;
  const jsonLd = page.jsonLd ? page.jsonLd({ url }) : null;

  return (
    <Helmet>
      <title>{resolvedTitle}</title>
      <meta name="description" content={description} />
      <meta name="robots" content={INDEX_ROBOTS} />
      <link rel="canonical" href={url} />
      <meta property="og:type" content="website" />
      <meta property="og:url" content={url} />
      <meta property="og:title" content={resolvedTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:image" content={image} />
      <meta property="og:site_name" content="BananaTalk" />
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={resolvedTitle} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={image} />
      {jsonLd && <script type="application/ld+json">{JSON.stringify(jsonLd)}</script>}
    </Helmet>
  );
};

export default PageMeta;
```

- [ ] **Step 7: Create `src/seo/RouteMeta.tsx`**

```tsx
import React from "react";
import { useLocation } from "react-router-dom";
import PageMeta from "./PageMeta";
import { findSeoPage } from "./pages";

// Mounted once in App. Indexed pages get their tag set from the SEO map;
// everything else is noindex. A page that needs richer tags (a public profile
// after its data loads) renders its own PageMeta deeper in the tree, and the
// deeper Helmet wins.
const RouteMeta: React.FC = () => {
  const { pathname } = useLocation();
  const page = findSeoPage(pathname);
  return page ? <PageMeta route={page.path} /> : <PageMeta noindex />;
};

export default RouteMeta;
```

- [ ] **Step 8: Mount `RouteMeta` in `App` and `HelmetProvider` in `index.tsx`**

In `src/App.tsx` add `import RouteMeta from "./seo/RouteMeta";` and render it first inside the i18n provider:

```tsx
    <I18nextProvider i18n={i18n}>
      <RouteMeta />
      <SocketProvider>
```

In `src/index.tsx` add `import { HelmetProvider } from "react-helmet-async";` and wrap:

```tsx
root.render(
  <React.StrictMode>
    <HelmetProvider>
      <Provider store={rootReducer}>
        <RouterProvider router={router} />
      </Provider>
    </HelmetProvider>
  </React.StrictMode>
);
```

- [ ] **Step 9: Create `scripts/i18n/merge-keys.js`**

```js
#!/usr/bin/env node
// Merge translated keys into every locale file.
//
// Usage: node scripts/i18n/merge-keys.js path/to/keys.json
//
// keys.json: { "eng": {...}, "kor": {...}, ... } -- one entry per file in
// src/utils/locales (basename without .json). Each value is deep-merged into
// that locale; existing keys are kept unless the input names them. Refuses to
// run if any locale has no entry, so a key can never land in English alone.
const fs = require("fs");
const path = require("path");

const [, , input] = process.argv;
if (!input) {
  console.error("usage: node scripts/i18n/merge-keys.js <keys.json>");
  process.exit(1);
}

const keys = JSON.parse(fs.readFileSync(input, "utf8"));
const dir = path.join(__dirname, "..", "..", "src", "utils", "locales");
const files = fs.readdirSync(dir).filter((f) => f.endsWith(".json"));
const codes = files.map((f) => f.replace(/\.json$/, ""));
const missing = codes.filter((c) => !keys[c]);
if (missing.length) {
  console.error("no translations provided for:", missing.join(", "));
  process.exit(1);
}

const merge = (target, src) => {
  for (const [k, v] of Object.entries(src)) {
    if (v && typeof v === "object" && !Array.isArray(v)) {
      target[k] = merge(target[k] && typeof target[k] === "object" ? target[k] : {}, v);
    } else {
      target[k] = v;
    }
  }
  return target;
};

for (const file of files) {
  const p = path.join(dir, file);
  const raw = fs.readFileSync(p, "utf8");
  const merged = merge(JSON.parse(raw), keys[file.replace(/\.json$/, "")]);
  fs.writeFileSync(p, JSON.stringify(merged, null, 2) + (raw.endsWith("\n") ? "\n" : ""));
}
console.log(`merged into ${files.length} locale files`);
```

- [ ] **Step 10: Add the `seo` namespace to all 18 locales**

Write a scratch file (outside the repo, e.g. `/tmp/seo-keys.json` — do not commit it) with an entry for **each** of `eng kor zho zh_TW ja ar de es fr hi id it pt ru th tl tr vi`. The English entry is below, verbatim. For the other 17, translate every value into that language, keeping "BananaTalk", "App Store", "Google Play", "iOS", "Android" and "137" unchanged. Keep each translated title under 60 characters and each description under 160 where the language allows; the parity test checks keys, the pages test checks English lengths.

```json
{
  "eng": {
    "seo": {
      "appTitle": "BananaTalk",
      "home": {
        "title": "BananaTalk: Free Language Exchange App with Native Speakers",
        "description": "Chat with native speakers in 137 languages. Write in your language, they read it in theirs, and an AI tutor shows you the difference. Free on iOS and Android."
      },
      "download": {
        "title": "Download BananaTalk for iPhone and Android",
        "description": "Get the free BananaTalk language exchange app for iPhone and Android. Chat with native speakers with instant translations and AI tutor corrections."
      },
      "moments": {
        "title": "BananaTalk Moments: Stories in Your Target Language",
        "description": "Moments are short posts and stories shared by language learners on BananaTalk. See how the community uses them, then post your own in the app."
      },
      "privacy": {
        "title": "Privacy Policy | BananaTalk",
        "description": "How BananaTalk collects, uses and protects your data, and the choices you have."
      },
      "terms": {
        "title": "Terms of Use | BananaTalk",
        "description": "The terms that govern your use of BananaTalk, including content rules, moderation and reporting."
      },
      "support": {
        "title": "Support and Contact | BananaTalk",
        "description": "Get help with BananaTalk: account questions, reporting a problem, and how to reach the team."
      },
      "dataDeletion": {
        "title": "Data Deletion Request | BananaTalk",
        "description": "How to delete your BananaTalk account and personal data, and what happens after you ask."
      }
    }
  },
  "kor": { "seo": { "...": "translated values, same key structure" } }
}
```

Then:

```bash
node scripts/i18n/merge-keys.js /tmp/seo-keys.json
git diff --stat src/utils/locales   # 18 files, additions only
```

- [ ] **Step 11: Clean `public/index.html` and `public/manifest.json`**

In `public/index.html`:
- Delete lines 71-89, the nineteen `<link rel="alternate" hreflang=…>` tags (they point at a `?lang=` parameter the app never reads). Verify with `grep -c hreflang public/index.html` → `0`.
- Line 232: change the `<title>` to `<title>BananaTalk: Free Language Exchange App with Native Speakers</title>` (the shell title for client-rendered routes; prerendered pages replace it).

In `public/manifest.json`, change `"theme_color": "#FFD700"` to `"theme_color": "#14B8A6"` to match the `theme-color` meta tag.

- [ ] **Step 12: Run the tests and the full suite**

Run: `CI=true npx react-scripts test --testPathPattern='(seo/|localeParity)'`
Expected: PASS (5 + 3 + 20 tests).
Run: `CI=true npx react-scripts test`
Expected: all suites pass.

- [ ] **Step 13: Commit**

```bash
git add src/seo src/App.tsx src/index.tsx scripts/i18n src/utils/locales public/index.html public/manifest.json package.json package-lock.json
git commit -m "feat(seo): per-route metadata from one keyword map

Every route shared one title, description, canonical and OG image because
nothing set them per page. RouteMeta, mounted once in App, looks the path
up in src/seo/pages.ts and renders the full tag set for indexed pages or
noindex for the rest. The map is also the keyword map: each entry names
the phrase its title targets, and a test asserts the title carries it.
Strings live under seo.* in all 18 locales; the hreflang links that
pointed at an unread ?lang= parameter are gone.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: The 404 page and catch-all route

**Files:**
- Create: `src/components/errors/NotFound.tsx`
- Modify: `src/router/routes.tsx` (add the `*` route), `src/utils/locales/*.json` (`notFound` namespace), `src/utils/locales/localeParity.test.ts:7`
- Test: `src/components/errors/NotFound.test.tsx`, `src/router/routes.test.tsx` (one more case)

- [ ] **Step 1: Write the failing tests**

Create `src/components/errors/NotFound.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { HelmetProvider } from "react-helmet-async";
import { MemoryRouter } from "react-router-dom";
import NotFound from "./NotFound";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const page = (
  <MemoryRouter>
    <NotFound />
  </MemoryRouter>
);

it("explains itself and offers the two ways back", () => {
  render(<HelmetProvider>{page}</HelmetProvider>);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("This page doesn't exist");
  expect(screen.getByText("Go to the homepage")).toHaveAttribute("href", "/");
  expect(screen.getByText("Get the app")).toHaveAttribute("href", "/download");
});

it("is noindex with its own title", () => {
  const ctx: any = {};
  renderToString(<HelmetProvider context={ctx}>{page}</HelmetProvider>);
  expect(ctx.helmet.meta.toString()).toContain('content="noindex, nofollow"');
  expect(ctx.helmet.title.toString()).toContain("Page not found | BananaTalk");
});
```

Append to `src/router/routes.test.tsx`:

```tsx
it("sends unknown paths to the catch-all route", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/no-such-page");
  expect(matches && matches.length).toBe(2);
  expect(matches![1].route.path).toBe("*");
});
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `CI=true npx react-scripts test --testPathPattern='(errors/NotFound|router/routes)'`
Expected: FAIL — module not found; the catch-all test gets `null` matches (currently unknown paths match only the layout, so `matches.length` is 1).

- [ ] **Step 3: Create `src/components/errors/NotFound.tsx`**

```tsx
import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import PageMeta from "../../seo/PageMeta";

// Rendered by the "*" route. Prerendered to build/404.html and served by
// nginx with a real 404 status (deploy/nginx.snippet.conf), so a dead link no
// longer returns 200 with an empty page.
const NotFound: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section data-testid="not-found" className="bg-canvas px-4 py-24 text-center dark:bg-canvas-dark">
      <PageMeta noindex title={t("notFound.pageTitle") || "Page not found | BananaTalk"} />
      <p className="text-6xl font-extrabold text-brand" aria-hidden>404</p>
      <h1 className="mt-4 text-2xl font-extrabold text-gray-900 dark:text-gray-50">
        {t("notFound.title") || "This page doesn't exist"}
      </h1>
      <p className="mx-auto mt-3 max-w-md text-sm text-gray-600 dark:text-gray-300">
        {t("notFound.body") || "The link may be old, or the page may have moved. Here is the way back."}
      </p>
      <div className="mt-6 flex flex-wrap justify-center gap-2">
        <Link to="/" className="rounded-full bg-brand px-5 py-2.5 text-sm font-extrabold text-white shadow-brand">
          {t("notFound.home") || "Go to the homepage"}
        </Link>
        <Link
          to="/download"
          className="rounded-full border-2 border-brand px-5 py-2.5 text-sm font-extrabold text-brand-dark dark:text-brand-light"
        >
          {t("notFound.download") || "Get the app"}
        </Link>
      </div>
    </section>
  );
};

export default NotFound;
```

- [ ] **Step 4: Add the catch-all route**

In `src/router/routes.tsx`, add `import NotFound from "../components/errors/NotFound";` and, as the **last** child inside `<Route path="/" element={<App />}>`:

```tsx
      {/* Catch-all. Must stay last. */}
      <Route path="*" element={<NotFound />} />
```

- [ ] **Step 5: Add the `notFound` locale keys**

Scratch file with all 18 locales (translate the 17 as in Task 3 Step 10); English:

```json
{
  "eng": {
    "notFound": {
      "pageTitle": "Page not found | BananaTalk",
      "title": "This page doesn't exist",
      "body": "The link may be old, or the page may have moved. Here is the way back.",
      "home": "Go to the homepage",
      "download": "Get the app"
    }
  }
}
```

Run `node scripts/i18n/merge-keys.js /tmp/notfound-keys.json`, then change `localeParity.test.ts` line 7 to `const NAMESPACES = ["seo", "notFound"];`.

- [ ] **Step 6: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern='(errors/NotFound|router/routes|localeParity)'`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/components/errors src/router/routes.tsx src/router/routes.test.tsx src/utils/locales
git commit -m "feat(router): a real 404 page on a catch-all route

Unknown paths rendered the layout with an empty outlet and returned 200,
a soft-404 on every dead link the old sitemap advertised. The * route now
renders NotFound: noindex, its own title, and links home and to the app.
The prerender writes it to build/404.html for nginx to serve with a 404.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Static rendering — harness, build script, sitemap, hydration

**Files:**
- Create: `src/seo/publicRoutes.ts`, `src/seo/prerender/requestShim.ts`, `src/seo/prerender/prefetch.ts`, `src/seo/prerender/renderRoute.tsx`, `src/seo/prerender/template.ts`, `src/seo/prerender/sitemap.ts`, `src/seo/prerender/hydrationFlag.ts`, `src/utils/hydrationLanguage.ts`, `scripts/register.js`, `scripts/prerender.js`
- Modify: `src/index.tsx` (whole file), `src/App.tsx` (one effect), `src/components/home/anim/useInView.ts:26-28`, `src/components/home/anim/useCountUp.ts:16-17`, `package.json` (scripts, devDependencies)
- Test: `src/seo/prerender/renderRoute.test.tsx`, `src/seo/prerender/template.test.ts`, `src/seo/prerender/sitemap.test.ts`, `src/utils/hydrationLanguage.test.ts`

**Interfaces:**
- Consumes: `routes` (Task 1), `makeStore`/`AppStore` (Task 1), `SEO_PAGES`/`canonicalUrl`/`SITE_ORIGIN` (Task 3), `plansApiSlice` (existing).
- Produces: `renderRoute(path, opts?) → Promise<RenderedRoute>` where `RenderedRoute = { path: string; status: number; html: string; head: string }`; `prefetchersFor(path) → Prefetcher[]` where `Prefetcher = (store: AppStore) => Promise<unknown>` (Task 8 appends to it); `PRERENDER_PATHS`, `SITEMAP_PATHS`; `injectIntoTemplate(template, rendered)`; `buildSitemap(paths, date)`; `markPrerendered()`, `isPrerendered()`; `prepareForHydration(i18n)`, `restoreAfterHydration(i18n)`.

- [ ] **Step 1: Install build-time dependencies**

```bash
npm install --save-dev @babel/register@^7.25.9 dotenv@^16.4.5
```

(`@babel/register` 8.x targets Babel 8; the app is on `@babel/core` 7.24 via react-scripts.)

- [ ] **Step 2: Write the failing tests**

Create `src/seo/prerender/renderRoute.test.tsx`:

```tsx
/**
 * @jest-environment node
 */
import { renderRoute } from "./renderRoute";
import { PRERENDER_PATHS } from "../publicRoutes";
import { SEO_PAGES, canonicalUrl } from "../pages";

jest.setTimeout(30000);

// This is the same harness scripts/prerender.js runs at build time, executed
// here without a DOM so a component that reads window during render fails
// the suite, not the deploy.
describe.each(PRERENDER_PATHS)("prerender %s", (path) => {
  it("renders complete HTML with one h1 and route-specific head tags", async () => {
    const out = await renderRoute(path, { prefetch: false });
    expect(out.html.length).toBeGreaterThan(500);
    expect((out.html.match(/<h1[\s>]/g) || []).length).toBe(1);
    expect(out.head).toMatch(/<title[^>]*>[^<]+<\/title>/);

    const page = SEO_PAGES.find((p) => p.path === path);
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
```

Create `src/seo/prerender/template.test.ts`:

```ts
import { injectIntoTemplate } from "./template";

const TEMPLATE = `<!doctype html><html><head>
<meta charset="utf-8"/>
<title>Shell Title</title>
<meta name="description" content="shell description"/>
<meta name="robots" content="index, follow"/>
<link rel="canonical" href="https://banatalk.com"/>
<meta property="og:title" content="shell og"/>
<meta property="og:locale:alternate" content="ko_KR"/>
<meta name="twitter:title" content="shell tw"/>
<meta name="theme-color" content="#14B8A6"/>
<script type="application/ld+json">{"@type":"Organization"}</script>
</head><body><div id="root"></div><script src="/static/js/main.js"></script></body></html>`;

const rendered = {
  html: "<div><h1>Hi</h1></div>",
  head: '<title data-rh="true">Page Title</title>\n<meta data-rh="true" name="description" content="page"/>',
};

it("replaces the shell's route-specific head tags with the page's", () => {
  const out = injectIntoTemplate(TEMPLATE, rendered);
  expect(out).toContain('<title data-rh="true">Page Title</title>');
  expect(out).not.toContain("Shell Title");
  expect(out).not.toContain("shell description");
  expect(out).not.toContain("shell og");
  expect(out).not.toContain("shell tw");
  expect(out).not.toContain("og:locale:alternate");
  expect(out).not.toContain('rel="canonical" href="https://banatalk.com"');
});

it("keeps tags that are not route-specific", () => {
  const out = injectIntoTemplate(TEMPLATE, rendered);
  expect(out).toContain('name="theme-color"');
  expect(out).toContain('"@type":"Organization"');
  expect(out).toContain('<script src="/static/js/main.js">');
});

it("fills the root and refuses a template without an empty root", () => {
  expect(injectIntoTemplate(TEMPLATE, rendered)).toContain('<div id="root"><div><h1>Hi</h1></div></div>');
  expect(() => injectIntoTemplate("<html><body></body></html>", rendered)).toThrow(/root/);
});
```

Create `src/seo/prerender/sitemap.test.ts`:

```ts
import { buildSitemap } from "./sitemap";
import { SITEMAP_PATHS, PRERENDER_PATHS } from "../publicRoutes";
import { SEO_PAGES } from "../pages";

it("lists exactly the indexed pages, never the 404", () => {
  const xml = buildSitemap(SITEMAP_PATHS, new Date("2026-09-22T10:00:00Z"));
  const locs = Array.from(xml.matchAll(/<loc>([^<]+)<\/loc>/g)).map((m) => m[1]);
  expect(locs).toEqual(SEO_PAGES.map((p) => (p.path === "/" ? "https://banatalk.com" : `https://banatalk.com${p.path}`)));
  expect(xml).not.toContain("/404");
  expect(xml).toContain("<lastmod>2026-09-22</lastmod>");
  expect(xml.startsWith('<?xml version="1.0" encoding="UTF-8"?>')).toBe(true);
});

it("prerenders every sitemap page plus the 404", () => {
  expect(PRERENDER_PATHS).toEqual([...SITEMAP_PATHS, "/404"]);
});
```

Create `src/utils/hydrationLanguage.test.ts`:

```ts
import i18next from "i18next";
import { prepareForHydration, restoreAfterHydration, _resetHydrationLanguageForTests } from "./hydrationLanguage";

function makeI18n(lng: string) {
  const inst = i18next.createInstance();
  inst.init({
    lng,
    fallbackLng: "en",
    initImmediate: false,
    resources: { en: { translation: { hi: "hi" } }, ko: { translation: { hi: "안녕" } } },
  });
  return inst;
}

beforeEach(() => {
  window.localStorage.clear();
  _resetHydrationLanguageForTests();
});

it("switches to English for the first render and back after commit", () => {
  const i18n = makeI18n("ko");
  expect(prepareForHydration(i18n)).toBe("ko");
  expect(i18n.language).toBe("en");
  restoreAfterHydration(i18n);
  expect(i18n.language).toBe("ko");
});

it("preserves the visitor's stored choice across the English pass", () => {
  window.localStorage.setItem("i18nextLng", "ko");
  const i18n = makeI18n("ko");
  prepareForHydration(i18n);
  expect(window.localStorage.getItem("i18nextLng")).toBe("ko");
});

it("is a no-op for English visitors and for client-rendered pages", () => {
  const i18n = makeI18n("en");
  expect(prepareForHydration(i18n)).toBe("en");
  expect(i18n.language).toBe("en");
  const other = makeI18n("ko");
  restoreAfterHydration(other); // prepare was never called for this instance
  expect(other.language).toBe("ko");
});
```

- [ ] **Step 3: Run them to confirm they fail**

Run: `CI=true npx react-scripts test --testPathPattern='(prerender/|hydrationLanguage)'`
Expected: FAIL with module-not-found errors for each new module.

- [ ] **Step 4: Create `src/seo/publicRoutes.ts`**

```ts
import { SEO_PAGES } from "./pages";

/** Indexed pages; written to the sitemap. */
export const SITEMAP_PATHS: string[] = SEO_PAGES.map((p) => p.path);

/** Everything written to build/<path>/index.html. Dynamic routes never appear here. */
export const PRERENDER_PATHS: string[] = [...SITEMAP_PATHS, "/404"];
```

- [ ] **Step 5: Create `src/seo/prerender/requestShim.ts`**

```ts
// react-router's static handler takes a Fetch Request. Plain Node has one;
// Jest 27's node environment (what CRA 5 ships) does not expose it, so the
// harness falls back to the minimal shape the handler actually reads:
// url, method, signal and headers. Verified against react-router-dom 6.23.1.
export class MinimalRequest {
  url: string;
  method = "GET";
  headers = new Map<string, string>();
  signal: AbortSignal;
  constructor(url: string) {
    this.url = url;
    this.signal = new AbortController().signal;
  }
}

export function makeRequest(url: string): Request {
  const Ctor: any = (globalThis as any).Request;
  return Ctor ? new Ctor(url) : ((new MinimalRequest(url) as unknown) as Request);
}
```

- [ ] **Step 6: Create `src/seo/prerender/prefetch.ts`**

```ts
import { AppStore } from "../../store";
import { plansApiSlice } from "../../store/slices/plansSlice";

export type Prefetcher = (store: AppStore) => Promise<unknown>;

const PAGES_WITH_PRICING = ["/"];

// RTK Query hooks subscribe in effects, which renderToString never runs, so
// any data a prerendered page should contain is dispatched and awaited here
// before render. iOS prices are prerendered; the client refetches for Android
// after hydration (the two stores charge the same figures today).
export function prefetchersFor(path: string): Prefetcher[] {
  const list: Prefetcher[] = [];
  if (PAGES_WITH_PRICING.includes(path)) {
    list.push((store) => Promise.resolve(store.dispatch(plansApiSlice.endpoints.getVipPlans.initiate("ios") as any)));
  }
  return list;
}
```

- [ ] **Step 7: Create `src/seo/prerender/renderRoute.tsx`**

```tsx
import React from "react";
import { renderToString } from "react-dom/server";
import { Provider } from "react-redux";
import { HelmetProvider } from "react-helmet-async";
import { createStaticHandler, createStaticRouter, StaticRouterProvider } from "react-router-dom/server";
import { routes } from "../../router/routes";
import { makeStore, AppStore } from "../../store";
import i18n from "../../utils/i18n";
import { SITE_ORIGIN } from "../pages";
import { makeRequest } from "./requestShim";
import { prefetchersFor } from "./prefetch";

export interface RenderedRoute {
  path: string;
  status: number;
  html: string;
  head: string;
}

export interface RenderOptions {
  /** Default true. Tests pass false to stay offline. */
  prefetch?: boolean;
  /** Per-prefetch timeout. Default 5000ms. */
  fetchTimeoutMs?: number;
  /** Where data-fetch warnings go. Default: console.warn. */
  log?: (message: string) => void;
}

// A path nothing routes to, so "/404" renders the catch-all route.
const NOT_FOUND_PROBE = "/__not_found__";

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error(`timed out after ${ms}ms`)), ms);
    p.then((v) => { clearTimeout(t); resolve(v); }, (e) => { clearTimeout(t); reject(e); });
  });
}

async function prefetch(store: AppStore, path: string, opts: RenderOptions): Promise<void> {
  const log = opts.log || ((m: string) => console.warn(m));
  const ms = opts.fetchTimeoutMs || 5000;
  await Promise.all(
    prefetchersFor(path).map((run) =>
      withTimeout(run(store), ms).catch((err) => {
        // Data is allowed to fail; the page renders its fallback (spec §8).
        log(`prefetch for ${path} failed: ${err && err.message ? err.message : err}`);
      })
    )
  );
}

/**
 * Renders one public route to static HTML with its head tags.
 *
 * Throws -- and therefore fails the build -- on any render error, on a page
 * with anything other than exactly one <h1>, or on a page that set no title.
 * Browser globals are simply absent in Node, so a component that reads them
 * during render throws a ReferenceError here instead of shipping an empty page.
 */
export async function renderRoute(path: string, opts: RenderOptions = {}): Promise<RenderedRoute> {
  if (typeof window !== "undefined") {
    throw new Error("renderRoute must run without a DOM; a window global is present");
  }

  const store = makeStore();
  await i18n.changeLanguage("en");
  if (opts.prefetch !== false) await prefetch(store, path, opts);

  const handler = createStaticHandler(routes);
  const url = `${SITE_ORIGIN}${path === "/404" ? NOT_FOUND_PROBE : path}`;
  const queried = await handler.query(makeRequest(url));
  // A redirect or thrown Response comes back as a Response; a render comes
  // back as a StaticHandlerContext. Checked structurally: `Response` is not
  // defined in Jest 27's node sandbox, so `instanceof Response` would throw.
  if (!("statusCode" in queried)) {
    throw new Error(`Route ${path} produced a Response (${(queried as any).status}) instead of rendering`);
  }
  const context = queried;

  const router = createStaticRouter(routes, context);
  const helmetContext: any = {};
  const html = renderToString(
    <HelmetProvider context={helmetContext}>
      <Provider store={store}>
        <StaticRouterProvider router={router} context={context} hydrate={false} />
      </Provider>
    </HelmetProvider>
  );

  const h = helmetContext.helmet;
  const head = [h.title.toString(), h.meta.toString(), h.link.toString(), h.script.toString()]
    .filter(Boolean)
    .join("\n");

  const h1Count = (html.match(/<h1[\s>]/g) || []).length;
  if (h1Count !== 1) throw new Error(`Route ${path} rendered ${h1Count} <h1> elements; expected exactly 1`);
  if (!/<title[^>]*>[^<]+<\/title>/.test(head)) throw new Error(`Route ${path} set no <title>`);

  return { path, status: path === "/404" ? 404 : context.statusCode, html, head };
}
```

- [ ] **Step 8: Create `src/seo/prerender/template.ts`**

```ts
// Pure: no import of the harness, so this module (and its test) never pulls
// the app in. The shape matches RenderedRoute's html/head fields.
export interface RenderedFragment {
  html: string;
  head: string;
}

// Shell tags the page's own head replaces. Everything else in the template
// head (charset, viewport, theme-color, manifest, icons, JSON-LD, fonts) stays.
const REPLACED_HEAD_TAGS: RegExp[] = [
  /<title>[\s\S]*?<\/title>\s*/i,
  /<meta name="description"[^>]*>\s*/gi,
  /<meta name="robots"[^>]*>\s*/gi,
  /<link rel="canonical"[^>]*>\s*/gi,
  /<meta property="og:[^"]*"[^>]*>\s*/gi,
  /<meta name="twitter:[^"]*"[^>]*>\s*/gi,
];

const ROOT = /<div id="root">\s*<\/div>/;

export function injectIntoTemplate(template: string, rendered: RenderedFragment): string {
  let doc = template;
  for (const re of REPLACED_HEAD_TAGS) doc = doc.replace(re, "");
  if (!ROOT.test(doc)) throw new Error('template has no empty <div id="root"></div> to fill');
  doc = doc.replace("</head>", `${rendered.head}\n</head>`);
  return doc.replace(ROOT, `<div id="root">${rendered.html}</div>`);
}
```

- [ ] **Step 9: Create `src/seo/prerender/sitemap.ts`**

```ts
import { canonicalUrl } from "../pages";

export function buildSitemap(paths: string[], date: Date): string {
  const lastmod = date.toISOString().slice(0, 10);
  const urls = paths
    .map((p) => `  <url>\n    <loc>${canonicalUrl(p)}</loc>\n    <lastmod>${lastmod}</lastmod>\n  </url>`)
    .join("\n");
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`;
}
```

- [ ] **Step 10: Create `src/seo/prerender/hydrationFlag.ts`**

```ts
// Set by index.tsx before hydrateRoot. Animations that start hidden and
// reveal on scroll consult it so the first client render matches the
// prerendered markup (which is always the "visible" state); on a prerendered
// page the reveal animation is skipped and content is simply there.
let prerendered = false;

export function markPrerendered(): void {
  prerendered = true;
}

export function isPrerendered(): boolean {
  return prerendered;
}
```

- [ ] **Step 11: Make the reveal and count-up hooks hydration-safe**

In `src/components/home/anim/useInView.ts`, add `import { isPrerendered } from "../../../seo/prerender/hydrationFlag";` and change the initial state (lines 26-28) to:

```ts
  const [inView, setInView] = useState(
    () => typeof IntersectionObserver === "undefined" || prefersReducedMotion() || isPrerendered()
  );
```

In `src/components/home/anim/useCountUp.ts`, add the same import and change lines 16-17 to:

```ts
  // Instant (final value on the first render) under reduced motion, in Node,
  // and when hydrating prerendered HTML: a crawler must never read "0
  // languages", and hydration must not flip the text from 137 to 0.
  const reduced = prefersReducedMotion() || typeof window === "undefined" || isPrerendered();
  const [value, setValue] = useState(reduced ? target : 0);
```

- [ ] **Step 12: Create `src/utils/hydrationLanguage.ts`**

```ts
import { i18n as I18n } from "i18next";

// Prerendered HTML is English. To hydrate without a mismatch the first client
// render must be English too; the visitor's language is restored in an effect
// after commit (App.tsx). The language detector caches every changeLanguage
// to localStorage, so the stored choice is snapshotted and put back.
const STORAGE_KEY = "i18nextLng";
let pending: string | null = null;

const safeGet = (): string | null => {
  try { return window.localStorage.getItem(STORAGE_KEY); } catch { return null; }
};
const safeSet = (value: string | null): void => {
  try {
    if (value === null) window.localStorage.removeItem(STORAGE_KEY);
    else window.localStorage.setItem(STORAGE_KEY, value);
  } catch { /* storage unavailable; the effect restores the language anyway */ }
};

/** Call before hydrateRoot. Returns the language the visitor will get back. */
export function prepareForHydration(i18n: I18n): string {
  const detected = i18n.language || "en";
  if (detected.split("-")[0] !== "en") {
    const stored = safeGet();
    i18n.changeLanguage("en");
    safeSet(stored);
    pending = detected;
  }
  return detected;
}

/** Call from an effect after the first commit. No-op when nothing is pending. */
export function restoreAfterHydration(i18n: I18n): void {
  if (pending && pending !== i18n.language) i18n.changeLanguage(pending);
  pending = null;
}

export function _resetHydrationLanguageForTests(): void {
  pending = null;
}
```

- [ ] **Step 13: Choose `hydrateRoot` in `index.tsx` and restore the language in `App`**

Replace `src/index.tsx` with:

```tsx
import React from "react";

import "./index.css";
import { createRoot, hydrateRoot } from "react-dom/client";
import { RouterProvider } from "react-router-dom";
import { Provider } from "react-redux";
import { HelmetProvider } from "react-helmet-async";
import "./assets/styles/bootstrap.custom.css";
import "./assets/styles/legacy-buttons.css";
import "bootstrap-icons/font/bootstrap-icons.css";

import router from "./router/AppRouter";
import store from "./store";
import i18n from "./utils/i18n";
import { prepareForHydration } from "./utils/hydrationLanguage";
import { markPrerendered } from "./seo/prerender/hydrationFlag";

const container = document.getElementById("root") as HTMLElement;

const app = (
  <React.StrictMode>
    <HelmetProvider>
      <Provider store={store}>
        <RouterProvider router={router} />
      </Provider>
    </HelmetProvider>
  </React.StrictMode>
);

if (container.hasChildNodes()) {
  // Prerendered page: hydrate over the English markup; App switches to the
  // visitor's language after the first commit.
  markPrerendered();
  prepareForHydration(i18n);
  hydrateRoot(container, app);
} else {
  createRoot(container).render(app);
}
```

In `src/App.tsx`, add `import { restoreAfterHydration } from "./utils/hydrationLanguage";` and, inside the component after the existing analytics effect:

```tsx
  // After a prerendered page hydrates in English, switch to the visitor's language.
  useEffect(() => {
    restoreAfterHydration(i18n);
  }, []);
```

- [ ] **Step 14: Create `scripts/register.js`**

```js
// Node-side module hooks so scripts/prerender.js can require the CRA app.
// Babel compiles TS/JSX with the app's own preset; styles are stubbed the way
// CRA's Jest config stubs them; media imports resolve to their hashed build
// URLs so prerendered <img src> matches what the client would render.
const path = require("path");
const fs = require("fs");

process.env.NODE_ENV = process.env.NODE_ENV || "production";
// babel-preset-react-app emits CommonJS (what Node's require needs) only in
// its "test" env. This affects module format, not React's build: React reads
// NODE_ENV, which stays "production".
process.env.BABEL_ENV = "test";
require("dotenv").config({ path: path.join(__dirname, "..", ".env.production") });

require("@babel/register")({
  extensions: [".js", ".jsx", ".ts", ".tsx"],
  presets: [[require.resolve("babel-preset-react-app"), { runtime: "automatic" }]],
  ignore: [/node_modules/],
  cache: true,
});

const STYLE_EXTS = [".css", ".scss", ".sass"];
const MEDIA_EXTS = [".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".ico", ".mp3", ".mp4", ".woff", ".woff2"];

const manifestPath = path.join(__dirname, "..", "build", "asset-manifest.json");
const manifest = fs.existsSync(manifestPath)
  ? JSON.parse(fs.readFileSync(manifestPath, "utf8")).files || {}
  : {};

for (const ext of STYLE_EXTS) {
  require.extensions[ext] = (m) => { m.exports = {}; };
}
for (const ext of MEDIA_EXTS) {
  require.extensions[ext] = (m, filename) => {
    const base = path.basename(filename);
    const key = Object.keys(manifest).find((k) => k.startsWith("static/media/") && path.basename(k) === base);
    m.exports = key ? manifest[key] : `/static/media/${base}`;
  };
}
```

- [ ] **Step 15: Create `scripts/prerender.js`**

```js
#!/usr/bin/env node
// Runs after `react-scripts build`. Renders each public route to static HTML
// so crawlers see content, and writes the sitemap from the same route list.
// Data fetches may fail (logged as warnings); rendering may not (the build
// fails). See docs/superpowers/specs/2026-09-22-reach-marketing-admin-design.md §4.2.
require("./register");

const fs = require("fs");
const path = require("path");
const { renderRoute } = require("../src/seo/prerender/renderRoute");
const { PRERENDER_PATHS, SITEMAP_PATHS } = require("../src/seo/publicRoutes");
const { buildSitemap } = require("../src/seo/prerender/sitemap");
const { injectIntoTemplate } = require("../src/seo/prerender/template");

const BUILD = path.join(__dirname, "..", "build");
const templatePath = path.join(BUILD, "index.html");
if (!fs.existsSync(templatePath)) {
  console.error("[prerender] build/index.html not found; run react-scripts build first");
  process.exit(1);
}
// Read once, before "/" overwrites build/index.html.
const template = fs.readFileSync(templatePath, "utf8");

const fileFor = (route) => {
  if (route === "/") return path.join(BUILD, "index.html");
  if (route === "/404") return path.join(BUILD, "404.html");
  return path.join(BUILD, route.slice(1), "index.html");
};

(async () => {
  for (const route of PRERENDER_PATHS) {
    const out = await renderRoute(route, { log: (m) => console.warn(`[prerender] warning: ${m}`) });
    const file = fileFor(route);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, injectIntoTemplate(template, out));
    console.log(`[prerender] ${route} -> ${path.relative(BUILD, file)} (${out.status}, ${out.html.length} bytes)`);
  }
  fs.writeFileSync(path.join(BUILD, "sitemap.xml"), buildSitemap(SITEMAP_PATHS, new Date()));
  console.log(`[prerender] sitemap.xml (${SITEMAP_PATHS.length} urls)`);
})().catch((err) => {
  console.error("[prerender] FAILED:", err);
  process.exit(1);
});
```

- [ ] **Step 16: Wire the build script**

In `package.json` `scripts`, change `"build"` and add two helpers:

```json
    "build": "react-scripts build && node scripts/prerender.js",
    "build:spa": "react-scripts build",
    "prerender": "node scripts/prerender.js",
```

`deploy` already calls `npm run build`, so the prerender now runs on deploy with no other change.

- [ ] **Step 17: Run the unit tests**

Run: `CI=true npx react-scripts test --testPathPattern='(prerender/|hydrationLanguage|anim)'`
Expected: PASS. If a `renderRoute` case fails with `ReferenceError: <global> is not defined`, the stack names the component; move that read into an effect or behind `typeof window === "undefined"` (the pattern from Task 2) and re-run. Do not add a DOM polyfill.

- [ ] **Step 18: Run the real build and inspect the output**

```bash
GENERATE_SOURCEMAP=false npm run build 2>&1 | tail -25
ls build/download build/privacy-policy build/404.html build/sitemap.xml
grep -o '<title[^>]*>[^<]*</title>' build/index.html build/download/index.html build/404.html
grep -c 'hreflang' build/index.html            # 0
grep -o '<h1[^>]*>[^<]*' build/download/index.html | head -1
grep -c '__staticRouterHydrationData' build/index.html   # 0
```

Expected: the build passes ForkTsChecker (the TS 3.7.2 type check), the prerender logs one line per route plus the sitemap, each prerendered file has its own title, `build/download/index.html` contains the download page's `h1`, and `build/index.html` contains the homepage `h1` and the pricing markup.

- [ ] **Step 19: Smoke-test hydration in a browser**

```bash
npx serve -s build -l 5050 &   # or: python3 -m http.server 5050 --directory build
```

Open `http://localhost:5050/download` with the browser console open. Expected: the page is visible before JavaScript runs (disable JS in devtools to confirm), and with JS enabled there are **no** hydration warnings. Switch the site language to Korean via the navbar, reload: the first paint is English, then Korean, with the stored choice still Korean after reload. Stop the server.

- [ ] **Step 20: Run the full suite and commit**

Run: `CI=true npx react-scripts test`
Expected: all suites pass.

```bash
git add src/seo src/utils/hydrationLanguage.ts src/utils/hydrationLanguage.test.ts src/index.tsx src/App.tsx src/components/home/anim scripts/register.js scripts/prerender.js package.json package-lock.json
git commit -m "feat(seo): prerender every public route to static HTML at build time

Crawlers received an empty #root. scripts/prerender.js now renders each
path in SEO_PAGES (plus /404) with renderToString over the same route tree
the browser uses, via react-router's static handler, and writes
build/<path>/index.html with the page's own head tags. The client hydrates
when it finds markup. Data the page needs is dispatched and awaited before
render and may fail (fallback content); rendering may not.

Hydration details: first client render is forced to English to match the
markup, with the visitor's stored language restored after commit; reveal
and count-up animations skip their hidden state when hydrating so stats
never flip from 137 to 0.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Footer links, nginx snippet, README, retire the hand-written sitemap

**Files:**
- Create: `deploy/nginx.snippet.conf`, `README.md`
- Modify: `src/components/footer/FooterMain.tsx:50-53,97-98`, `src/utils/locales/*.json` (`footer.links.communities`, `footer.links.download`)
- Delete: `public/sitemap.xml`
- Test: `src/components/footer/FooterMain.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `src/components/footer/FooterMain.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render } from "@testing-library/react";
import { MemoryRouter, matchRoutes } from "react-router-dom";
import fs from "fs";
import path from "path";
import FooterMain from "./FooterMain";
import { routes } from "../../router/routes";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));

it("every internal link leads to a real route, never the catch-all", () => {
  const { container } = render(
    <MemoryRouter>
      <FooterMain />
    </MemoryRouter>
  );
  const hrefs = Array.from(container.querySelectorAll("a[href^='/']")).map((a) => a.getAttribute("href")!);
  expect(hrefs.length).toBeGreaterThan(4);
  for (const href of hrefs) {
    const pathOnly = href.split("#")[0] || "/";
    const matches = matchRoutes(routes, pathOnly);
    expect({ href, matched: matches ? matches[matches.length - 1].route.path : null }).not.toEqual({ href, matched: "*" });
    expect(matches).not.toBeNull();
  }
});

it("links to the download page and the communities page", () => {
  const { container } = render(<MemoryRouter><FooterMain /></MemoryRouter>);
  const hrefs = Array.from(container.querySelectorAll("a[href^='/']")).map((a) => a.getAttribute("href"));
  expect(hrefs).toContain("/download");
  expect(hrefs).toContain("/communities");
  expect(hrefs).toContain("/support");
  expect(hrefs).not.toContain("/pricing");
  expect(hrefs).not.toContain("/contact");
});

it("every locale carries the new footer link labels", () => {
  const dir = path.join(__dirname, "../../utils/locales");
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".json"))) {
    const links = JSON.parse(fs.readFileSync(path.join(dir, file), "utf8")).footer.links;
    expect({ file, communities: typeof links.communities, download: typeof links.download })
      .toEqual({ file, communities: "string", download: "string" });
  }
});
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `CI=true npx react-scripts test --testPathPattern=FooterMain`
Expected: FAIL — `/pricing` and `/contact` match the catch-all.

- [ ] **Step 3: Fix the footer links**

In `src/components/footer/FooterMain.tsx`, replace lines 50-53 with:

```tsx
                <li><Link to="/">{t("footer.links.home")}</Link></li>
                <li><Link to="/communities">{t("footer.links.communities") || "Communities"}</Link></li>
                <li><Link to="/#pricing">{t("footer.links.pricing")}</Link></li>
                <li><Link to="/download">{t("footer.links.download") || "Download the app"}</Link></li>
                <li><Link to="/support">{t("footer.links.contact")}</Link></li>
```

Lines 97-98 stay (`/privacy-policy`, `/terms-of-use` exist).

- [ ] **Step 4: Add the two footer keys to all locales**

Scratch file with all 18 locales; English:

```json
{ "eng": { "footer": { "links": { "communities": "Communities", "download": "Download the app" } } } }
```

Run `node scripts/i18n/merge-keys.js /tmp/footer-keys.json`.

- [ ] **Step 5: Create `deploy/nginx.snippet.conf`**

```nginx
# BananaTalk web -- include inside the `server { ... }` block that serves
# the CRA build (root = the build/ folder). Apply by hand on the server; the
# live nginx config is not versioned in this repo. See README.md "Deploy".
#
# Why: the old sitemap advertised URLs that never existed and the SPA returned
# 200 with an empty page for all of them. Dead URLs with a successor redirect;
# the rest say 410 Gone so crawlers drop them. The prerendered 404 page is
# served with a real 404 status.

error_page 404 /404.html;
location = /404.html { internal; }

# Dead URLs with a successor.
location = /privacy            { return 301 /privacy-policy; }
location = /terms              { return 301 /terms-of-use; }
location = /pen-pals           { return 301 /meet; }            # /meet ships in Phase B; until then this lands on the 404 page
location = /language-exchange  { return 301 /; }

# Dead URLs with no successor.
location ~ ^/(about|features|languages|help|faq|blog|success-stories|learn-english|learn-spanish|learn-japanese|learn-chinese|learn-french|learn-german|video-call|cultural-dating|international-dating)/?$ {
  return 410;
}

# Prerendered folders are served from disk; everything else falls back to the
# SPA shell (client routes, dynamic pages, app-only routes).
location / {
  try_files $uri $uri/index.html $uri/ /index.html;
}
```

- [ ] **Step 6: Create `README.md`**

```markdown
# BananaTalk web

React 18 + TypeScript (CRA `react-scripts` 5). Marketing site and web client for the BananaTalk language-exchange app at https://banatalk.com.

## Develop

```bash
npm install
npm start                                    # http://localhost:3000, API from .env (localhost:5003)
CI=true npx react-scripts test               # full suite; CI=true avoids watch mode
```

`npx tsc` does not work here: TypeScript is pinned at 3.7.2 and cannot parse some library types. The type check is the build.

## Build and deploy

```bash
npm run build      # react-scripts build, then scripts/prerender.js
npm run deploy     # build + `nginx -s reload` on the server
```

`scripts/prerender.js` renders every public route (`src/seo/pages.ts`) to `build/<route>/index.html` so crawlers see content, writes `build/404.html`, and generates `build/sitemap.xml`. It fails the build if a route throws, has no `<h1>`, or sets no title. Data fetches during prerender may fail; the page then renders its fallback and a warning is logged.

`npm run build:spa` skips the prerender (debugging only).

### nginx

Include `deploy/nginx.snippet.conf` in the server block that serves `build/`. It returns 404 status for the prerendered 404 page, 301s for four old URLs that have a successor, and 410 for the rest of the URLs the old sitemap advertised. Reload nginx after changing it.

### Environment

`.env.production` is read at build time (and by the prerender):

| Variable | Purpose |
|---|---|
| `REACT_APP_API_URL` | Backend origin, `https://api.banatalk.com` |
| `REACT_APP_GA_MEASUREMENT_ID` | GA4 id (`G-XXXXXXX`). Empty disables GA entirely. GA loads only after the visitor accepts the consent bar. |

### Search Console

After the first deploy with prerendering, submit `https://banatalk.com/sitemap.xml` in Google Search Console and request indexing of `/`. Search Console is the only source of the queries visitors actually used.

## Docs

Specs and plans live under `docs/superpowers/`.
```

- [ ] **Step 7: Retire the hand-written sitemap**

```bash
git rm public/sitemap.xml
```

(`public/robots.txt` keeps pointing at `/sitemap.xml`, which the build now generates.)

- [ ] **Step 8: Run the tests**

Run: `CI=true npx react-scripts test --testPathPattern='(FooterMain|localeParity)'`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add src/components/footer deploy README.md src/utils/locales public/sitemap.xml
git commit -m "chore(seo): footer links to real pages, nginx snippet for dead URLs, README

The footer linked /pricing and /contact, which never existed; every
prerendered page would have pointed crawlers at a 410. It now links the
pricing section, /support, /download and /communities, and a test keeps
every footer link on a real route. The hand-written sitemap is deleted in
favour of the generated one. deploy/nginx.snippet.conf gives the old
sitemap URLs their 301/410 answers and serves 404.html with a 404 status.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Backend — `GET /api/v1/public/stats`

**Repo: backend** (`/Users/davis/Desktop/Personal/language_exchange_backend_application`).

**Files:**
- Create: `controllers/public.js`, `routes/public.js`, `test/publicStats.test.js`
- Modify: `server.js:363` (mount after the analytics line)

**Interfaces:**
- Produces: `GET /api/v1/public/stats` → `{ success: true, data: { learners: number | null, countries: number, languages: number, generatedAt: string } }`, `Cache-Control: public, max-age=3600`. `learners` is `null` below 1,000 and otherwise rounded down to two significant figures; `countries` is rounded the same way (exact below 100); `languages` is the `Language` collection count.

- [ ] **Step 1: Create the branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout -b feat/reach
```

- [ ] **Step 2: Write the failing test**

Create `test/publicStats.test.js`:

```js
/**
 * Public, unauthenticated stats for the marketing site.
 *
 * The homepage may only show numbers that are true; this endpoint is the one
 * source. Learner counts are rounded down to two significant figures so the
 * page never shows a figure that is stale by lunchtime, and hidden entirely
 * below 1,000 so early days do not read as empty.
 *
 * Run: node --test test/publicStats.test.js
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
});
test.after(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});

const User = require('../models/User');
const Language = require('../models/Language');
const { getPublicStats, roundDownTwoSig, _resetPublicStatsCache } = require('../controllers/public');

const call = async (handler) => {
  let payload = null;
  let error = null;
  const headers = {};
  const res = {
    status: () => res,
    set: (k, v) => { headers[k] = v; return res; },
    json: (b) => { payload = b; return res; },
  };
  await handler({}, res, (e) => { error = e; });
  return { payload, error, headers };
};

const makeUser = (over = {}) => User.create({
  name: 'u', email: `${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
  ...over,
});
const inCountry = (country) => ({ location: { type: 'Point', coordinates: [0, 0], country } });

test.beforeEach(async () => {
  await User.deleteMany({});
  await Language.deleteMany({});
  _resetPublicStatsCache();
});

test('roundDownTwoSig floors to two significant figures above 100', () => {
  assert.equal(roundDownTwoSig(12431), 12000);
  assert.equal(roundDownTwoSig(999), 990);
  assert.equal(roundDownTwoSig(1500), 1500);
  assert.equal(roundDownTwoSig(100), 100);
  assert.equal(roundDownTwoSig(42), 42);
  assert.equal(roundDownTwoSig(0), 0);
});

test('learners is null below 1,000 and banned users are not counted', async () => {
  await makeUser();
  await makeUser({ isBanned: true });
  const { payload, error, headers } = await call(getPublicStats);
  assert.equal(error, null);
  assert.equal(payload.success, true);
  assert.equal(payload.data.learners, null);
  assert.equal(headers['Cache-Control'], 'public, max-age=3600');
  assert.ok(payload.data.generatedAt);
});

test('countries counts distinct location.country; languages counts the catalog', async () => {
  await makeUser(inCountry('Korea'));
  await makeUser(inCountry('Korea'));
  await makeUser(inCountry('Brazil'));
  await makeUser(); // no country
  await Language.create({ code: 'ko', name: 'Korean', nativeName: '한국어' });
  const { payload } = await call(getPublicStats);
  assert.equal(payload.data.countries, 2);
  assert.equal(payload.data.languages, 1);
});

test('responses are cached for an hour', async () => {
  const a = (await call(getPublicStats)).payload;
  await Language.create({ code: 'ja', name: 'Japanese', nativeName: '日本語' });
  const b = (await call(getPublicStats)).payload;
  assert.equal(b.data.languages, a.data.languages);
  assert.equal(b.data.generatedAt, a.data.generatedAt);
  _resetPublicStatsCache();
  const c = (await call(getPublicStats)).payload;
  assert.equal(c.data.languages, a.data.languages + 1);
});
```

- [ ] **Step 3: Run it to confirm it fails**

Run: `node --test test/publicStats.test.js`
Expected: FAIL with `Cannot find module '../controllers/public'`.

- [ ] **Step 4: Create `controllers/public.js`**

```js
const asyncHandler = require('../middleware/async');
const User = require('../models/User');
const Language = require('../models/Language');

const CACHE_TTL_MS = 60 * 60 * 1000;
const LEARNERS_FLOOR = 1000;
let cache = null; // { value, expiresAt }

/** 12431 -> 12000, 999 -> 990; exact below 100. Always rounds down. */
const roundDownTwoSig = (n) => {
  if (n < 100) return n;
  const magnitude = 10 ** (String(Math.floor(n)).length - 2);
  return Math.floor(n / magnitude) * magnitude;
};

/**
 * @desc    Public counts for the marketing site
 * @route   GET /api/v1/public/stats
 * @access  Public
 */
const getPublicStats = asyncHandler(async (req, res) => {
  if (cache && cache.expiresAt > Date.now()) {
    res.set('Cache-Control', 'public, max-age=3600');
    return res.json(cache.value);
  }

  const [learners, countries, languages] = await Promise.all([
    User.countDocuments({ isBanned: { $ne: true } }),
    User.distinct('location.country', { 'location.country': { $nin: [null, ''] } }),
    Language.countDocuments(),
  ]);

  const value = {
    success: true,
    data: {
      learners: learners < LEARNERS_FLOOR ? null : roundDownTwoSig(learners),
      countries: roundDownTwoSig(countries.length),
      languages,
      generatedAt: new Date().toISOString(),
    },
  };
  cache = { value, expiresAt: Date.now() + CACHE_TTL_MS };
  res.set('Cache-Control', 'public, max-age=3600');
  return res.json(value);
});

const _resetPublicStatsCache = () => { cache = null; };

module.exports = { getPublicStats, roundDownTwoSig, _resetPublicStatsCache };
```

- [ ] **Step 5: Create `routes/public.js` and mount it**

```js
const express = require('express');
const { getPublicStats } = require('../controllers/public');

// Unauthenticated, read-only endpoints for the marketing site. Nothing here
// may return per-user data.
const router = express.Router();

router.get('/stats', getPublicStats);

module.exports = router;
```

In `server.js`, directly after line 363 (`app.use('/api/v1/analytics', require('./routes/analytics'));`) add:

```js
app.use('/api/v1/public', require('./routes/public'));
```

- [ ] **Step 6: Run the test**

Run: `node --test test/publicStats.test.js`
Expected: PASS (4 tests). If `User.create` rejects on a required field the fixture lacks, add that field to `makeUser` with a plausible value and note it in the commit body.

- [ ] **Step 7: Commit (backend repo)**

```bash
git add controllers/public.js routes/public.js test/publicStats.test.js server.js
git commit -m "feat(public): GET /public/stats — rounded learner, country and language counts

The web homepage showed no learner count because the only count endpoint
requires auth. This one is public, cached for an hour, floors learners to
two significant figures, hides the figure below 1,000, and never returns
anything about an individual user.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Frontend — learner count in the stat strip, prefetched at build

**Repo: frontend.**

**Files:**
- Create: `src/store/slices/publicStatsSlice.ts`
- Modify: `src/constants.ts` (one line), `src/components/home/parts/StatStrip.tsx`, `src/seo/prerender/prefetch.ts`, `src/utils/locales/*.json` (`home.stats.learners`)
- Test: `src/components/home/parts/StatStrip.stats.test.tsx`, `src/seo/prerender/prefetch.test.ts`

**Interfaces:**
- Consumes: `apiSlice`, `Prefetcher`/`prefetchersFor` (Task 5).
- Produces: `publicStatsApiSlice`, `useGetPublicStatsQuery()`, `PublicStats`, `formatCount(n)`; `PUBLIC_STATS_URL`.

- [ ] **Step 1: Write the failing tests**

Create `src/components/home/parts/StatStrip.stats.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import StatStrip from "./StatStrip";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

let statsResult: any = { data: undefined };
jest.mock("../../../store/slices/publicStatsSlice", () => ({
  ...jest.requireActual("../../../store/slices/publicStatsSlice"),
  useGetPublicStatsQuery: () => statsResult,
}));

// Reduced motion makes the count-up instant, so the assertions read final values.
beforeAll(() => {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    value: () => ({ matches: true, addEventListener() {}, removeEventListener() {} }),
  });
});

it("shows the four curated stats when the count is unavailable", () => {
  statsResult = { data: undefined };
  render(<StatStrip />);
  expect(screen.getAllByTestId("stat-item")).toHaveLength(4);
  expect(screen.queryByText("learners")).not.toBeInTheDocument();
  expect(screen.getByText("Free")).toBeInTheDocument();
});

it("leads with the real learner count when the endpoint has one", () => {
  statsResult = { data: { learners: 12000, countries: 40, languages: 137, generatedAt: "x" } };
  render(<StatStrip />);
  const items = screen.getAllByTestId("stat-item");
  expect(items).toHaveLength(4);
  expect(items[0]).toHaveTextContent("12,000+");
  expect(items[0]).toHaveTextContent("learners");
  expect(screen.queryByText("Free")).not.toBeInTheDocument();
});

it("hides the learner stat when the endpoint returns null (under 1,000)", () => {
  statsResult = { data: { learners: null, countries: 3, languages: 137, generatedAt: "x" } };
  render(<StatStrip />);
  expect(screen.queryByText("learners")).not.toBeInTheDocument();
  expect(screen.getAllByTestId("stat-item")).toHaveLength(4);
});
```

Create `src/seo/prerender/prefetch.test.ts`:

```ts
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
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `CI=true npx react-scripts test --testPathPattern='(StatStrip.stats|prerender/prefetch)'`
Expected: FAIL — `Cannot find module '.../publicStatsSlice'`; the prefetch test fails on the stats URL.

- [ ] **Step 3: Add the URL constant and the slice**

Append to `src/constants.ts`:

```ts
export const PUBLIC_STATS_URL = "/api/v1/public/stats";
export const ANALYTICS_EVENTS_URL = "/api/v1/analytics/events";
```

Create `src/store/slices/publicStatsSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";
import { PUBLIC_STATS_URL } from "../../constants";

/** GET /api/v1/public/stats -- controllers/public.js. `learners` is null under 1,000. */
export interface PublicStats {
  learners: number | null;
  countries: number;
  languages: number;
  generatedAt: string;
}

export const publicStatsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getPublicStats: builder.query<PublicStats, void>({
      query: () => ({ url: PUBLIC_STATS_URL }),
      transformResponse: (response: any) => (response && response.data ? response.data : response),
      keepUnusedDataFor: 3600,
    }),
  }),
});

export const { useGetPublicStatsQuery } = publicStatsApiSlice;

/** 12000 -> "12,000". en-US grouping regardless of UI language: the figure sits next to a translated label. */
export function formatCount(n: number): string {
  return n.toLocaleString("en-US");
}
```

- [ ] **Step 4: Update `StatStrip`**

Replace `src/components/home/parts/StatStrip.tsx` with:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import Reveal from "../anim/Reveal";
import { useInView } from "../anim/useInView";
import { useCountUp } from "../anim/useCountUp";
import { useGetPublicStatsQuery, formatCount } from "../../../store/slices/publicStatsSlice";

// Every figure here is checkable. The learner count comes from
// GET /public/stats (rounded down, null under 1,000) and leads the strip when
// present; the curated four stand alone otherwise. No ratings: the App Store
// listing has none.
// "18 app languages" -- src/utils/locales/ holds 18 JSON files and
// `SUPPORTED_LANGUAGES` in src/utils/i18n.ts lists 18 codes; re-count either
// to re-verify.
interface Stat {
  value: string;
  label: string;
  /** Appended after the (formatted) number, e.g. "+". */
  suffix?: string;
}

const CURATED: Stat[] = [
  { value: "137", label: "languages" },
  { value: "18", label: "app languages" },
  { value: "24/7", label: "AI tutor" },
  { value: "Free", label: "forever tier" },
];

/** Numeric stats tick up when the strip scrolls into view; the rest are literal. */
const StatValue: React.FC<{ stat: Stat; start: boolean }> = ({ stat, start }) => {
  const numeric = /^\d+$/.test(stat.value) ? Number(stat.value) : null;
  const counted = useCountUp(numeric ?? 0, { start: start && numeric !== null });
  return (
    <p className="text-2xl font-extrabold text-brand-dark dark:text-brand-light">
      {numeric === null ? stat.value : `${formatCount(counted)}${stat.suffix || ""}`}
    </p>
  );
};

const StatStrip: React.FC = () => {
  const { t } = useTranslation();
  const [ref, inView] = useInView<HTMLElement>();
  const { data } = useGetPublicStatsQuery();

  // Lead with the real count and keep the strip at four: the free tier is
  // already the first pricing card, so it is the one that steps aside.
  const stats: Stat[] =
    data && data.learners
      ? [{ value: String(data.learners), label: "learners", suffix: "+" }, ...CURATED.slice(0, 3)]
      : CURATED;

  return (
    <section
      ref={ref}
      data-testid="stat-strip"
      className="border-y border-gray-100 bg-surface py-8 dark:border-gray-700 dark:bg-cardbg-dark"
    >
      <div className="mx-auto grid max-w-4xl grid-cols-2 gap-6 px-4 sm:grid-cols-4">
        {stats.map((s, i) => (
          <Reveal key={s.label} delayMs={i * 90}>
            <div data-testid="stat-item" className="text-center">
              <StatValue stat={s} start={inView} />
              <p className="mt-0.5 text-[11px] font-medium uppercase tracking-wide text-gray-400">
                {t(`home.stats.${s.label}`) || s.label}
              </p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
};

export default StatStrip;
```

Check `staticSections.test.tsx` still passes: it renders `StatStrip` without a store. `useGetPublicStatsQuery` needs a Provider, so add to that test file's mocks:

```tsx
jest.mock("../../../store/slices/publicStatsSlice", () => ({
  ...jest.requireActual("../../../store/slices/publicStatsSlice"),
  useGetPublicStatsQuery: () => ({ data: undefined }),
}));
```

and the same mock in `src/components/home/HomeMain.test.tsx` (which also renders without a store).

- [ ] **Step 5: Register the prefetch**

In `src/seo/prerender/prefetch.ts` add `import { publicStatsApiSlice } from "../../store/slices/publicStatsSlice";` and inside `prefetchersFor`, after the plans block:

```ts
  if (path === "/") {
    list.push((store) => Promise.resolve(store.dispatch(publicStatsApiSlice.endpoints.getPublicStats.initiate() as any)));
  }
```

- [ ] **Step 6: Add the `home.stats.learners` label to all locales**

Scratch file (18 locales; "learners" translated as the noun for people learning a language):

```json
{ "eng": { "home": { "stats": { "learners": "learners" } } } }
```

Run `node scripts/i18n/merge-keys.js /tmp/learners-key.json`.

- [ ] **Step 7: Run the tests, the suite, and the build**

Run: `CI=true npx react-scripts test --testPathPattern='(StatStrip|staticSections|HomeMain|prerender/)'`
Expected: PASS.
Run: `CI=true npx react-scripts test` → all pass.
Run: `GENERATE_SOURCEMAP=false npm run build 2>&1 | grep -E "prerender|error|Failed" ` → prerender lines, no errors. With the backend unreachable from the build machine the log shows `warning: prefetch for / failed` and `build/index.html` still contains `>137<`. When it is reachable and there are 1,000+ learners, `build/index.html` contains the rounded count with `+`.

- [ ] **Step 8: Commit**

```bash
git add src/constants.ts src/store/slices/publicStatsSlice.ts src/components/home src/seo/prerender src/utils/locales
git commit -m "feat(home): real learner count in the stat strip, from GET /public/stats

Prefetched at build time so crawlers see it; hidden under 1,000 so early
days do not read as empty; the free-tier stat steps aside to keep four.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Backend — `POST /api/v1/analytics/events`

**Repo: backend.**

**Files:**
- Create: `models/WebEvent.js`, `controllers/webEvents.js`, `utils/parseUserAgent.js`, `test/webEvents.test.js`
- Modify: `routes/analytics.js` (import the shared parser, add the route), `middleware/rateLimiter.js` (append `analyticsLimiter`)

**Interfaces:**
- Produces: `POST /api/v1/analytics/events` with JSON body `{ name: "page_view"|"store_tap"|"cta_tap", path: string, placement?: string, platform?: "ios"|"android"|"web", referrer?: string, language?: string, sessionId: string /^[A-Za-z0-9_-]{8,64}$/ }` → `204`; `400` on a bad body; rate-limited 60/min per IP (`RateLimit-Limit: 60` header). Stores `WebEvent { name, path, placement, platform, referrer, language, sessionId, device, os, ipHash }` with a 400-day TTL.

- [ ] **Step 1: Write the failing test**

Create `test/webEvents.test.js`:

```js
/**
 * First-party marketing events (page views, store taps) from banatalk.com.
 *
 * No cookie, no user id: a per-tab session id chosen by the browser and a
 * salted hash of the IP are the only correlators, so the endpoint needs no
 * consent and the raw IP is never stored.
 *
 * Run: node --test test/webEvents.test.js
 */
process.env.ANALYTICS_IP_SALT = 'test-salt';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const express = require('express');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, app, WebEvent;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
  WebEvent = require('../models/WebEvent');
  app = express();
  app.use(express.json());
  app.use('/api/v1/analytics', require('../routes/analytics'));
  app.use(require('../middleware/error'));
});
test.after(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});
test.beforeEach(() => WebEvent.deleteMany({}));

const valid = {
  name: 'store_tap', path: '/download', placement: 'download-page', platform: 'ios',
  referrer: 'https://www.google.com/', language: 'ko-KR', sessionId: 'abcdefgh12345678',
};

test('stores a valid event with derived device/os and a hashed ip, and answers 204', async () => {
  const res = await request(app)
    .post('/api/v1/analytics/events')
    .set('User-Agent', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/604.1')
    .set('X-Forwarded-For', '203.0.113.9')
    .send(valid);
  assert.equal(res.status, 204);
  assert.equal(res.headers['ratelimit-limit'], '60');

  const [doc] = await WebEvent.find({}).lean();
  assert.equal(doc.name, 'store_tap');
  assert.equal(doc.placement, 'download-page');
  assert.equal(doc.platform, 'ios');
  assert.equal(doc.device, 'mobile');
  assert.equal(doc.os, 'iOS');
  assert.equal(doc.sessionId, valid.sessionId);
  assert.match(doc.ipHash, /^[a-f0-9]{64}$/);
  assert.equal(JSON.stringify(doc).includes('203.0.113.9'), false);
});

test('rejects unknown names, bad paths and bad session ids', async () => {
  for (const body of [
    { ...valid, name: 'purchase' },
    { ...valid, path: 'download' },
    { ...valid, sessionId: 'short' },
    { ...valid, platform: 'windows' },
  ]) {
    const res = await request(app).post('/api/v1/analytics/events').send(body);
    assert.equal(res.status, 400, JSON.stringify(body));
  }
  assert.equal(await WebEvent.countDocuments(), 0);
});

test('optional fields may be absent', async () => {
  const res = await request(app)
    .post('/api/v1/analytics/events')
    .send({ name: 'page_view', path: '/', sessionId: 'abcdefgh12345678' });
  assert.equal(res.status, 204);
  const [doc] = await WebEvent.find({}).lean();
  assert.equal(doc.placement, null);
  assert.equal(doc.platform, null);
});
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `node --test test/webEvents.test.js`
Expected: FAIL with `Cannot find module '../models/WebEvent'`.

- [ ] **Step 3: Create `utils/parseUserAgent.js` and use it in `routes/analytics.js`**

```js
/**
 * Parse a user-agent string into device, browser, OS. Shared by the visit
 * and events endpoints (routes/analytics.js, controllers/webEvents.js).
 */
const parseUserAgent = (ua) => {
  if (!ua) return { device: 'unknown', browser: 'Unknown', os: 'Unknown' };

  let device = 'desktop';
  if (/tablet|ipad/i.test(ua)) device = 'tablet';
  else if (/mobile|android|iphone|ipod/i.test(ua)) device = 'mobile';

  let browser = 'Unknown';
  if (/edg\//i.test(ua)) browser = 'Edge';
  else if (/opr\//i.test(ua) || /opera/i.test(ua)) browser = 'Opera';
  else if (/chrome/i.test(ua) && !/edg/i.test(ua)) browser = 'Chrome';
  else if (/safari/i.test(ua) && !/chrome/i.test(ua)) browser = 'Safari';
  else if (/firefox/i.test(ua)) browser = 'Firefox';

  let os = 'Unknown';
  if (/windows/i.test(ua)) os = 'Windows';
  else if (/mac os/i.test(ua) && !/iphone|ipad|ipod/i.test(ua)) os = 'macOS';
  else if (/linux/i.test(ua) && !/android/i.test(ua)) os = 'Linux';
  else if (/android/i.test(ua)) os = 'Android';
  else if (/iphone|ipad|ipod/i.test(ua)) os = 'iOS';

  return { device, browser, os };
};

module.exports = { parseUserAgent };
```

(The two `&& !` exclusions are new: an iPhone UA contains "like Mac OS X" and an Android UA contains "Linux", which the old order misread. Keep the function otherwise identical.)

In `routes/analytics.js`: delete the local `parseUserAgent` definition (lines 6 through its closing `};`) and add `const { parseUserAgent } = require('../utils/parseUserAgent');` with the other requires. Then add, after the `/visit` route:

```js
const { recordEvent } = require('../controllers/webEvents');
const { analyticsLimiter } = require('../middleware/rateLimiter');

/**
 * @desc    Record a first-party marketing event (page view, store tap)
 * @route   POST /api/v1/analytics/events
 * @access  Public, 60/min per IP
 */
router.post('/events', analyticsLimiter, recordEvent);
```

- [ ] **Step 4: Create `models/WebEvent.js`**

```js
const mongoose = require('mongoose');

// One row per marketing event from the web. No user reference on purpose:
// this is reach data, not behaviour data, and it is sent without consent
// because nothing in it identifies a person. See spec §4.5 / §7.3.
const WebEventSchema = new mongoose.Schema({
  name: { type: String, enum: ['page_view', 'store_tap', 'cta_tap'], required: true, index: true },
  path: { type: String, required: true, maxlength: 512 },
  placement: { type: String, maxlength: 64, default: null },
  platform: { type: String, enum: ['ios', 'android', 'web', null], default: null },
  referrer: { type: String, maxlength: 2048, default: null },
  language: { type: String, maxlength: 16, default: null },
  sessionId: { type: String, required: true, maxlength: 64, index: true },
  device: { type: String, enum: ['desktop', 'mobile', 'tablet', 'unknown'], default: 'unknown' },
  os: { type: String, default: 'Unknown' },
  ipHash: { type: String, index: true },
}, { timestamps: true });

WebEventSchema.index({ createdAt: 1 }, { expireAfterSeconds: 400 * 24 * 60 * 60 });
WebEventSchema.index({ name: 1, createdAt: -1 });

module.exports = mongoose.model('WebEvent', WebEventSchema);
```

- [ ] **Step 5: Create `controllers/webEvents.js`**

```js
const crypto = require('crypto');
const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const WebEvent = require('../models/WebEvent');
const { parseUserAgent } = require('../utils/parseUserAgent');

const NAMES = new Set(['page_view', 'store_tap', 'cta_tap']);
const PLATFORMS = new Set(['ios', 'android', 'web']);
const SESSION_ID = /^[A-Za-z0-9_-]{8,64}$/;

const clientIp = (req) =>
  ((req.headers['x-forwarded-for'] || '').split(',')[0] || '').trim()
  || req.headers['x-real-ip']
  || req.ip
  || 'unknown';

// Salted so the hash cannot be reversed by hashing candidate IPs; the raw
// address is never stored.
const hashIp = (ip) => crypto
  .createHash('sha256')
  .update(`${process.env.ANALYTICS_IP_SALT || process.env.JWT_SECRET || ''}:${ip}`)
  .digest('hex');

const str = (v, max) => (typeof v === 'string' && v.length ? v.slice(0, max) : null);

exports.recordEvent = asyncHandler(async (req, res, next) => {
  const { name, path, placement, platform, referrer, language, sessionId } = req.body || {};

  if (!NAMES.has(name)) return next(new ErrorResponse('Unknown event name', 400));
  if (typeof path !== 'string' || !path.startsWith('/') || path.length > 512) {
    return next(new ErrorResponse('Invalid path', 400));
  }
  if (typeof sessionId !== 'string' || !SESSION_ID.test(sessionId)) {
    return next(new ErrorResponse('Invalid sessionId', 400));
  }
  if (platform != null && !PLATFORMS.has(platform)) return next(new ErrorResponse('Invalid platform', 400));

  const { device, os } = parseUserAgent(req.headers['user-agent'] || '');

  await WebEvent.create({
    name,
    path,
    placement: str(placement, 64),
    platform: platform || null,
    referrer: str(referrer, 2048),
    language: str(language, 16),
    sessionId,
    device,
    os,
    ipHash: hashIp(clientIp(req)),
  });

  res.status(204).end();
});
```

- [ ] **Step 6: Add the limiter**

Append to `middleware/rateLimiter.js`:

```js
/**
 * First-party analytics events. A page view plus a couple of taps per
 * minute is normal; 60 per IP per minute is generous for a person and
 * useless for a flood.
 */
exports.analyticsLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: 'Too many events from this IP, slow down.' },
});
```

- [ ] **Step 7: Run the new test and the existing analytics-adjacent tests**

Run: `node --test test/webEvents.test.js`
Expected: PASS (3 tests).
Run: `npm test 2>&1 | tail -15`
Expected: the whole backend suite passes (the `parseUserAgent` move must not have broken the visit route: `grep -n parseUserAgent routes/analytics.js` shows only the require and the call).

- [ ] **Step 8: Commit (backend repo)**

```bash
git add models/WebEvent.js controllers/webEvents.js utils/parseUserAgent.js routes/analytics.js middleware/rateLimiter.js test/webEvents.test.js
git commit -m "feat(analytics): POST /analytics/events for first-party marketing events

Page views and store taps from banatalk.com, stored with a per-tab
session id and a salted IP hash only -- no cookie, no user, so no consent
gate. Validated names/paths/ids, 60/min per IP, 400-day TTL. Ready for the
admin console's Reach page to aggregate. parseUserAgent moves to utils so
both analytics endpoints share it (and now tells iPhone from macOS).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Frontend — first-party tracking, GA4 behind consent, consent bar

**Repo: frontend.**

**Files:**
- Create: `src/analytics/track.ts`, `src/analytics/consent.ts`, `src/analytics/ga.ts`, `src/analytics/usePageView.ts`, `src/components/growth/surfaceRegistry.ts`, `src/components/growth/ConsentBar.tsx`
- Modify: `src/App.tsx`, `src/components/growth/AppDownloadPopup.tsx`, `.env.production`, `src/utils/locales/*.json` (`consent` namespace), `src/utils/locales/localeParity.test.ts:7`
- Test: `src/analytics/track.test.ts`, `src/analytics/track.node.test.ts`, `src/analytics/ga.test.ts`, `src/analytics/consent.test.ts`, `src/components/growth/surfaceRegistry.test.tsx`, `src/components/growth/ConsentBar.test.tsx`

**Interfaces:**
- Consumes: `ANALYTICS_EVENTS_URL`, `BASE_URL` (constants).
- Produces: `trackEvent(name: EventName, data?: EventData): void`, `sessionId(): string`, `buildPayload(name, data)`; `readConsent(): Consent | null`, `writeConsent(c)`; `loadGa(id?): boolean`, `gaEvent(name, params?)`, `GA_MEASUREMENT_ID`; `usePageView()`; `openSurface(key)`, `closeSurface(key)`, `useSurfaceOpen(key): boolean`; `<ConsentBar />`. Phase B's `StoreLink` calls `trackEvent("store_tap", { placement, platform })` and `gaEvent("store_tap", { placement, platform })`.

- [ ] **Step 1: Write the failing tests**

Create `src/analytics/track.test.ts`:

```ts
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
```

Create `src/analytics/track.node.test.ts`:

```ts
/**
 * @jest-environment node
 */
import { trackEvent } from "./track";

it("never sends during prerender (no window)", () => {
  (global as any).fetch = jest.fn();
  expect(() => trackEvent("page_view", { path: "/" })).not.toThrow();
  expect(global.fetch).not.toHaveBeenCalled();
});
```

Create `src/analytics/consent.test.ts`:

```ts
import { readConsent, writeConsent } from "./consent";

beforeEach(() => window.localStorage.clear());

it("is undecided by default and round-trips a decision", () => {
  expect(readConsent()).toBeNull();
  writeConsent("granted");
  expect(readConsent()).toBe("granted");
  writeConsent("denied");
  expect(readConsent()).toBe("denied");
});

it("treats junk and throwing storage as undecided", () => {
  window.localStorage.setItem("bt.consent", "maybe");
  expect(readConsent()).toBeNull();
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
  expect(readConsent()).toBeNull();
  spy.mockRestore();
});
```

Create `src/analytics/ga.test.ts`:

```ts
import { loadGa, gaEvent, _resetGaForTests } from "./ga";

beforeEach(() => {
  _resetGaForTests();
  document.head.querySelectorAll("script[data-ga]").forEach((s) => s.remove());
});

it("does nothing without a measurement id", () => {
  expect(loadGa("")).toBe(false);
  gaEvent("page_view", { page_path: "/" });
  expect(window.dataLayer).toBeUndefined();
});

it("injects gtag once and forwards events after load", () => {
  expect(loadGa("G-TEST123")).toBe(true);
  expect(loadGa("G-TEST123")).toBe(false); // already loaded
  const script = document.head.querySelector("script[data-ga]") as HTMLScriptElement;
  expect(script.src).toContain("googletagmanager.com/gtag/js?id=G-TEST123");
  gaEvent("store_tap", { placement: "hero" });
  const layer = window.dataLayer as any[];
  expect(layer.some((args) => args[0] === "config" && args[1] === "G-TEST123")).toBe(true);
  expect(layer.some((args) => args[0] === "event" && args[1] === "store_tap")).toBe(true);
});
```

Create `src/components/growth/surfaceRegistry.test.tsx`:

```tsx
import React from "react";
import { render, screen, act } from "@testing-library/react";
import { openSurface, closeSurface, useSurfaceOpen, _resetSurfacesForTests } from "./surfaceRegistry";

const Probe: React.FC = () => <span>{useSurfaceOpen("download-popup") ? "open" : "closed"}</span>;

beforeEach(() => _resetSurfacesForTests());

it("tells subscribers when a surface opens and closes", () => {
  render(<Probe />);
  expect(screen.getByText("closed")).toBeInTheDocument();
  act(() => openSurface("download-popup"));
  expect(screen.getByText("open")).toBeInTheDocument();
  act(() => closeSurface("download-popup"));
  expect(screen.getByText("closed")).toBeInTheDocument();
});
```

Create `src/components/growth/ConsentBar.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import ConsentBar from "./ConsentBar";
import { openSurface, _resetSurfacesForTests } from "./surfaceRegistry";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("../../analytics/ga", () => ({ loadGa: jest.fn(), gaEvent: jest.fn() }));
const { loadGa } = require("../../analytics/ga");

beforeEach(() => {
  window.localStorage.clear();
  _resetSurfacesForTests();
  (loadGa as jest.Mock).mockClear();
});

it("is absent from server output", () => {
  expect(renderToString(<ConsentBar />)).toBe("");
});

it("shows when undecided and loads GA only on accept", () => {
  render(<ConsentBar />);
  expect(screen.getByTestId("consent-bar")).toBeInTheDocument();
  expect(loadGa).not.toHaveBeenCalled();
  fireEvent.click(screen.getByText("OK"));
  expect(window.localStorage.getItem("bt.consent")).toBe("granted");
  expect(loadGa).toHaveBeenCalledTimes(1);
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
});

it("records a refusal and never loads GA", () => {
  render(<ConsentBar />);
  fireEvent.click(screen.getByText("No thanks"));
  expect(window.localStorage.getItem("bt.consent")).toBe("denied");
  expect(loadGa).not.toHaveBeenCalled();
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
});

it("stays hidden once decided, and loads GA on return visits when granted", () => {
  window.localStorage.setItem("bt.consent", "granted");
  render(<ConsentBar />);
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
  expect(loadGa).toHaveBeenCalledTimes(1);
});

it("shows when storage throws (treated as undecided)", () => {
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
  render(<ConsentBar />);
  expect(screen.getByTestId("consent-bar")).toBeInTheDocument();
  spy.mockRestore();
});

it("steps aside while the download popup is open", () => {
  render(<ConsentBar />);
  act(() => openSurface("download-popup"));
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
});
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `CI=true npx react-scripts test --testPathPattern='(analytics/|surfaceRegistry|ConsentBar)'`
Expected: FAIL with module-not-found errors.

- [ ] **Step 3: Create `src/analytics/consent.ts`**

```ts
export type Consent = "granted" | "denied";

const KEY = "bt.consent";

/** null = undecided. Storage that throws (private modes) reads as undecided. */
export function readConsent(): Consent | null {
  try {
    const v = window.localStorage.getItem(KEY);
    return v === "granted" || v === "denied" ? v : null;
  } catch {
    return null;
  }
}

export function writeConsent(value: Consent): void {
  try {
    window.localStorage.setItem(KEY, value);
  } catch {
    // The bar will show again next visit. Acceptable.
  }
}
```

- [ ] **Step 4: Create `src/analytics/ga.ts`**

```ts
// GA4, loaded only after consent (ConsentBar). With no measurement id every
// call is a no-op, which is what tests and local development get.
declare global {
  interface Window {
    dataLayer?: unknown[];
    gtag?: (...args: unknown[]) => void;
  }
}

export const GA_MEASUREMENT_ID: string = process.env.REACT_APP_GA_MEASUREMENT_ID || "";

let loaded = false;

export function loadGa(id: string = GA_MEASUREMENT_ID): boolean {
  if (!id || loaded || typeof document === "undefined") return false;
  window.dataLayer = window.dataLayer || [];
  window.gtag = function gtag() {
    window.dataLayer!.push(arguments);
  };
  window.gtag("js", new Date());
  window.gtag("config", id, { anonymize_ip: true });

  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(id)}`;
  script.setAttribute("data-ga", id);
  document.head.appendChild(script);
  loaded = true;
  return true;
}

export function gaEvent(name: string, params: Record<string, unknown> = {}): void {
  if (!loaded || typeof window === "undefined" || !window.gtag) return;
  window.gtag("event", name, params);
}

export function _resetGaForTests(): void {
  loaded = false;
  if (typeof window !== "undefined") {
    delete window.gtag;
    delete window.dataLayer;
  }
}
```

- [ ] **Step 5: Create `src/analytics/track.ts`**

```ts
import { BASE_URL, ANALYTICS_EVENTS_URL } from "../constants";

export type EventName = "page_view" | "store_tap" | "cta_tap";

export interface EventData {
  path?: string;
  placement?: string;
  platform?: "ios" | "android" | "web";
  referrer?: string;
  language?: string;
}

// First-party events: POST /api/v1/analytics/events (controllers/webEvents.js).
// Independent of GA and of consent: the payload carries a per-tab session id
// and nothing that identifies a person. Fire-and-forget, one retry, never throws.

const SESSION_KEY = "bt.sid";
let memoSession: string | null = null;

function randomId(): string {
  const bytes = new Uint8Array(16);
  if (typeof crypto !== "undefined" && crypto.getRandomValues) crypto.getRandomValues(bytes);
  else for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export function sessionId(): string {
  try {
    const existing = window.sessionStorage.getItem(SESSION_KEY);
    if (existing) return existing;
    const id = randomId();
    window.sessionStorage.setItem(SESSION_KEY, id);
    return id;
  } catch {
    if (!memoSession) memoSession = randomId();
    return memoSession;
  }
}

export function buildPayload(name: EventName, data: EventData) {
  return {
    name,
    path: data.path || window.location.pathname,
    placement: data.placement || null,
    platform: data.platform || null,
    referrer: data.referrer || document.referrer || null,
    language: data.language || navigator.language || null,
    sessionId: sessionId(),
  };
}

async function post(body: string): Promise<boolean> {
  try {
    const res = await fetch(`${BASE_URL}${ANALYTICS_EVENTS_URL}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
      keepalive: true,
    });
    return res.ok;
  } catch {
    return false;
  }
}

export function trackEvent(name: EventName, data: EventData = {}): void {
  if (typeof window === "undefined") return; // prerender: nothing to measure
  let body: string;
  try {
    body = JSON.stringify(buildPayload(name, data));
  } catch {
    return;
  }
  void (async () => {
    if (!(await post(body))) await post(body);
  })();
}
```

- [ ] **Step 6: Create `src/analytics/usePageView.ts`**

```ts
import { useEffect } from "react";
import { useLocation } from "react-router-dom";
import { BASE_URL } from "../constants";
import { trackEvent } from "./track";
import { gaEvent } from "./ga";

// The legacy visit ping (WebVisit, geo-located server-side) stays as it was;
// it feeds the existing weekly report. The new event channel and GA sit
// alongside it.
function legacyVisitPing(pathname: string): void {
  try {
    fetch(`${BASE_URL}/api/v1/analytics/visit`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        page: pathname,
        referrer: document.referrer || null,
        language: navigator.language || null,
      }),
    }).catch(() => {});
  } catch {
    // analytics must never block the UI
  }
}

export function usePageView(): void {
  const { pathname } = useLocation();
  useEffect(() => {
    legacyVisitPing(pathname);
    trackEvent("page_view", { path: pathname });
    gaEvent("page_view", { page_path: pathname });
  }, [pathname]);
}
```

- [ ] **Step 7: Create `src/components/growth/surfaceRegistry.ts`**

```ts
import { useEffect, useState } from "react";

// Which interrupting surfaces are on screen. Lets the consent bar step aside
// while the download popup is open instead of stacking two asks at once.
type Listener = () => void;
const open = new Set<string>();
const listeners = new Set<Listener>();
const notify = () => listeners.forEach((l) => l());

export function openSurface(key: string): void {
  open.add(key);
  notify();
}

export function closeSurface(key: string): void {
  open.delete(key);
  notify();
}

export function useSurfaceOpen(key: string): boolean {
  const [isOpen, setIsOpen] = useState(() => open.has(key));
  useEffect(() => {
    const listener = () => setIsOpen(open.has(key));
    listeners.add(listener);
    listener();
    return () => {
      listeners.delete(listener);
    };
  }, [key]);
  return isOpen;
}

export function _resetSurfacesForTests(): void {
  open.clear();
  listeners.clear();
}
```

In `src/components/growth/AppDownloadPopup.tsx`, add `import { openSurface, closeSurface } from "./surfaceRegistry";` and, after the keydown effect (line 59), add:

```tsx
  useEffect(() => {
    if (!open) return;
    openSurface("download-popup");
    return () => closeSurface("download-popup");
  }, [open]);
```

- [ ] **Step 8: Create `src/components/growth/ConsentBar.tsx`**

```tsx
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { readConsent, writeConsent, Consent } from "../../analytics/consent";
import { loadGa } from "../../analytics/ga";
import { useSurfaceOpen } from "./surfaceRegistry";

type State = "pending" | Consent | null; // pending until mounted: never in prerendered HTML

const ConsentBar: React.FC = () => {
  const { t } = useTranslation();
  const [state, setState] = useState<State>("pending");
  const popupOpen = useSurfaceOpen("download-popup");

  useEffect(() => {
    const stored = readConsent();
    setState(stored);
    if (stored === "granted") loadGa();
  }, []);

  if (state !== null || popupOpen) return null;

  const choose = (decision: Consent) => {
    writeConsent(decision);
    setState(decision);
    if (decision === "granted") loadGa();
  };

  return (
    <div
      role="region"
      aria-label={t("consent.label") || "Cookie consent"}
      data-testid="consent-bar"
      className="fixed inset-x-0 bottom-0 z-[60] border-t border-gray-200 bg-surface px-4 py-3 shadow-float dark:border-gray-700 dark:bg-cardbg-dark"
    >
      <div className="mx-auto flex max-w-4xl flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-gray-700 dark:text-gray-200">
          {t("consent.message") || "We use analytics cookies to understand what brings people here."}
        </p>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => choose("denied")}
            className="rounded-full border border-gray-300 px-4 py-1.5 text-sm font-bold text-gray-700 dark:border-gray-600 dark:text-gray-200"
          >
            {t("consent.decline") || "No thanks"}
          </button>
          <button
            type="button"
            onClick={() => choose("granted")}
            className="rounded-full bg-brand px-4 py-1.5 text-sm font-extrabold text-white shadow-brand"
          >
            {t("consent.accept") || "OK"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConsentBar;
```

- [ ] **Step 9: Wire `App.tsx`**

Replace the inline analytics `useEffect` (the `fetch(.../analytics/visit ...)` block, lines 19-34 of the original file) with a call to the hook, and mount the consent bar:

```tsx
import { usePageView } from "./analytics/usePageView";
import ConsentBar from "./components/growth/ConsentBar";
// ...
const App = () => {
  usePageView();

  useEffect(() => {
    restoreAfterHydration(i18n);
  }, []);

  return (
    <I18nextProvider i18n={i18n}>
      <RouteMeta />
      <SocketProvider>
        <MainNavbar />
        <AppBanner />
        <Container fluid>
          <Outlet />
        </Container>
        <FooterMain />
        <ConsentBar />
        <ToastContainer />
      </SocketProvider>
    </I18nextProvider>
  );
};
```

Remove the now-unused `useLocation` and `BASE_URL` imports from `App.tsx` if nothing else in the file uses them.

- [ ] **Step 10: Env and locale keys**

Append to `.env.production`:

```
# GA4 measurement id (G-XXXXXXXXXX). Empty = GA disabled. Loaded only after consent.
REACT_APP_GA_MEASUREMENT_ID=
```

Scratch file with the `consent` namespace for all 18 locales; English:

```json
{
  "eng": {
    "consent": {
      "label": "Cookie consent",
      "message": "We use analytics cookies to understand what brings people here.",
      "accept": "OK",
      "decline": "No thanks"
    }
  }
}
```

Run `node scripts/i18n/merge-keys.js /tmp/consent-keys.json`, then set `localeParity.test.ts` line 7 to `const NAMESPACES = ["seo", "notFound", "consent"];`.

- [ ] **Step 11: Run the tests, the suite, and the build**

Run: `CI=true npx react-scripts test --testPathPattern='(analytics/|growth|localeParity|prerender/)'`
Expected: PASS. The `renderRoute` suite still passes because `ConsentBar` renders nothing before mount and `usePageView` only fires in an effect.
Run: `CI=true npx react-scripts test` → all pass.
Run: `GENERATE_SOURCEMAP=false npm run build 2>&1 | grep -Ei "prerender|error|failed"` → prerender lines only. Confirm `grep -c consent-bar build/index.html` prints `0`.

- [ ] **Step 12: Commit**

```bash
git add src/analytics src/components/growth src/App.tsx src/utils/locales .env.production
git commit -m "feat(analytics): first-party events, GA4 behind consent, consent bar

Nothing measured which pages or store buttons worked. usePageView now
fires the legacy visit ping, a first-party page_view (no cookie, per-tab
session id only) and, once GA has loaded, a GA4 page_view. GA loads only
after the consent bar is accepted; refusal is remembered; undecided means
no GA. The bar renders nothing until mounted so it never appears in
prerendered HTML, and steps aside while the download popup is open.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 11: Verification, merge, deploy notes

- [ ] **Step 1: Full verification, frontend**

```bash
CI=true npx react-scripts test 2>&1 | grep -E "^(Tests|Test Suites):"
GENERATE_SOURCEMAP=false npm run build 2>&1 | tail -20
```

Expected: every suite green (about 75 suites); build succeeds; prerender logs eight routes and the sitemap.

Then, with `npx serve -s build -l 5050` running, check each of these by hand and stop the server after:

- [ ] `view-source:http://localhost:5050/` shows the hero `h1`, the stat strip values and the pricing cards inside `#root`, and a `<title>` of "BananaTalk: Free Language Exchange App with Native Speakers".
- [ ] `view-source:http://localhost:5050/download` has its own title and canonical `https://banatalk.com/download`.
- [ ] `http://localhost:5050/404.html` renders the 404 page; its head has `noindex`.
- [ ] `http://localhost:5050/sitemap.xml` lists seven URLs and no `/404`.
- [ ] No hydration warnings in the console on `/`, `/download`, `/moments`.
- [ ] Set the language to Korean, reload `/`: English flashes, then Korean; the choice survives another reload.
- [ ] The consent bar appears once; "OK" then "No thanks" on a fresh profile each behave as specified; with `REACT_APP_GA_MEASUREMENT_ID` empty no gtag script is ever injected.
- [ ] Network tab: one `POST /analytics/events` per navigation with `name: "page_view"`.

- [ ] **Step 2: Full verification, backend**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application && npm test 2>&1 | tail -8
```

Expected: all pass, including `publicStats` and `webEvents`.

- [ ] **Step 3: Merge (both repos), following the repo convention**

Frontend:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
git checkout main
git merge --no-ff feat/reach -m "Merge: reach — per-route metadata, static rendering, sitemap/404, analytics (Phase A)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
CI=true npx react-scripts test 2>&1 | grep -E "^(Tests|Test Suites):"
```

Backend:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout <default-branch>   # `git symbolic-ref refs/remotes/origin/HEAD` names it
git merge --no-ff feat/reach -m "Merge: public stats and first-party web events for the marketing site

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

Push only when the user asks.

- [ ] **Step 4: Deploy checklist for the user (not automated)**

1. Deploy the backend first (`/public/stats` and `/analytics/events` must exist before the web build prefetches and posts to them).
2. Set `REACT_APP_GA_MEASUREMENT_ID` in `.env.production` on the server if GA is wanted.
3. Include `deploy/nginx.snippet.conf` in the server block and reload nginx.
4. `npm run deploy` on the web server.
5. Verify `https://banatalk.com/download` view-source shows content, `https://banatalk.com/about` returns 410, `https://banatalk.com/privacy` redirects, `https://banatalk.com/no-such-page` returns a 404 status.
6. Submit `https://banatalk.com/sitemap.xml` in Google Search Console.

---

## Verification against the spec

- **§3 public page set (Phase A rows):** Task 3 `SEO_PAGES` covers `/`, `/download`, `/moments`, the four legal/support pages; Task 4 the 404; every other route is noindex through `RouteMeta`. `/communities` and `/profile/:userId` are Phase B by spec.
- **§4.1 metadata layer:** Task 3 (`pages.ts`, `PageMeta`, `RouteMeta`, `HelmetProvider`, hreflang removal, title, manifest). Dynamic-route `values` interpolation is in `PageMeta` for Phase B's profile work.
- **§4.2 static rendering:** Task 1 (route tree, import safety), Task 2 (render-time reads), Task 5 (harness with static handler, `hydrate={false}`, prefetch via `initiate()`, `!data` branching already in `PricingSection` and used in `StatStrip`, loud failures, hydration chooser, English-first hydration with stored language preserved). The spec's `globalThis` Proxy is implemented as the absence of browser globals in Node plus the harness's `typeof window` assertion: same failure, less machinery.
- **§4.3 sitemap:** Task 5 generates it from `SEO_PAGES`; Task 6 deletes the hand-written one.
- **§4.4 404 and dead URLs:** Task 4 (page), Task 5 (`build/404.html`), Task 6 (nginx snippet with the real 301/410 split, footer fixes, README).
- **§4.5 measurement:** Task 9 (backend events), Task 10 (`trackEvent`, `usePageView`, GA behind consent, `ConsentBar`, popup stacking). `store_tap` wiring arrives with Phase B's `StoreLink`, per spec §5.1.
- **§4.6 truthful numbers:** Task 7 (endpoint with rounding, floor and cache), Task 8 (stat strip, prefetch).
- **§7.1, §7.3:** Tasks 7 and 9. §7.2, §7.4, §7.5 belong to Phases B and C.
- **§8 error handling:** prefetch failures are warnings (Task 5), render failures fail the build (Task 5), analytics never throws (Task 10), consent defaults to no GA (Task 10).
- **§9 tests:** SEO map (Task 3), prerender harness (Task 5), sitemap (Task 5), tracking and consent (Task 10), locale parity (Tasks 3, 4, 10), hydration chooser is covered by the manual smoke test in Task 5 Step 19 and Task 11 (jsdom cannot exercise `hydrateRoot` over prerendered markup meaningfully). Bundle budget and `StoreLink` tests are Phase B.
- **§10 not in this spec:** untouched. **§11 risks:** Task 1 does the route split first; Task 2 plus the Task 5 test cover the window-read inventory; TypeScript 3.7.2 constraints are in Global Constraints and the pinned `react-helmet-async@1.3.0`.
