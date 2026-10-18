# Reach, Marketing Polish & Admin Console — Design

**Date:** 2026-09-22
**Status:** approved in conversation, ready for spec review and implementation planning
**Goal:** make BananaTalk's public web pages findable and measurable, sharpen them into the
best case for installing the app, and give the admin a web console over the data this
produces and the moderation surface the backend already exposes.

**Scope:** two repositories. Frontend `language_exchange_web_front` (React 18.3, CRA
`react-scripts` 5.0.1, TypeScript pinned at 3.7.2, Tailwind 3.4, RTK Query, react-i18next,
Jest). Backend `language_exchange_backend_application` (Express, Mongoose) for five small,
additive endpoints listed in §7. Deployment is unchanged: `npm run deploy` builds on the
server under a 1GB Node heap and reloads nginx, which serves the `build/` folder.

**Relationship to other sub-projects.** Builds on the design foundation (`0dd3869`) and the
marketing homepage (`e670124`). The Moments-to-app-promo change (`6934943`) is assumed.
Community and profile cleanup and the remaining Moments/Stories tidy-up are **not** here; they
are separate sub-projects that will reuse the metadata layer this spec creates.

**Phases.** Built strictly in order because each depends on the previous:

- **A — Reach:** metadata layer, static rendering, sitemap and 404, measurement, truthful numbers.
- **B — Marketing polish:** homepage copy against the keyword map, download landing page, two new
  landing pages, public communities, code splitting.
- **C — Admin console:** navbar entry for admins, `/admin/*` pages over existing and new endpoints.

---

## 1. Why now

### 1.1 Search engines cannot read the site

Every route is client-rendered. `public/index.html` carries a strong static title, description,
Open Graph set and four JSON-LD blocks, but the `#root` a crawler receives is empty, and there
is no per-route mechanism: no `react-helmet`, no `document.title` write anywhere in `src/`.
Every page — homepage, download, public profiles, privacy policy — presents the same title,
description, canonical (`https://banatalk.com`) and OG image.

### 1.2 The sitemap promises pages that do not exist

`public/sitemap.xml` lists 28 URLs. Twenty-one (`/about`, `/features`, `/languages`, `/help`,
`/faq`, `/blog`, `/learn-korean`, `/pen-pals`, `/cultural-dating`, …) have no route. Because
there is no catch-all route, each returns HTTP 200 with an empty page: a soft-404 on every
promised URL. `lastmod` is 2024-12-29. Separately, `public/index.html` carries 19 `hreflang`
alternates pointing at `?lang=xx`, a query parameter the app never reads.

### 1.3 The claims disagree with each other

The `<title>` says "Learn 50+ Languages"; the homepage stat strip says 137. The homepage shows
no learner count because the count endpoint requires auth; the store listing has no reviews.
Nothing can be measured: there is no GA, no pixel, only a first-party `POST /analytics/visit`
that records page and device and is never read back by anyone.

### 1.4 The marketing page ships the whole app

There is no `React.lazy` anywhere. The landing page downloads chat, `socket.io-client`,
`emoji-picker-react`, `moment`, Bootstrap and react-bootstrap, plus a render-blocking
Bootstrap Icons stylesheet from jsdelivr that the marketing pages do not use.

### 1.5 The admin API has no web client

The backend already has an admin router behind `protect` + `authorize('admin')` with user
search and detail, ban/unban, role change, banned list, hard delete, audit log, stats,
activity, AI-usage summary and logs, and club/gathering moderation. The frontend `authSlice`
has an unused `isAdmin?: boolean`. Nothing on the web consumes any of it.

---

## 2. Decisions taken before design

1. **Positioning is layered.** Primary: the language learner ("language exchange app",
   "practice speaking with native speakers"). Secondary: the social seeker ("meet people from
   other countries", "international friends app"). Tertiary long-tail: Korean ("learn Korean by
   chatting", "Korean language exchange"). The homepage owns the primary; two landing pages own
   the other two.
2. **Static rendering with React's own server renderer**, not Puppeteer snapshotting and not a
   Next.js migration. Reasoning: no browser and no new server; it fits a build machine that caps
   Node at 1GB; the cost is render-time discipline, which a test enforces (§4.2).
3. **Measurement is GA4 plus first-party events.** GA4 for search attribution and Search
   Console integration; first-party for store-tap data the business owns and the admin console
   reads. GA4 loads only after consent.
4. **Backend changes are in scope** but additive only: five new endpoints (§7), no change to
   any existing one.
5. **The admin console is a client over existing endpoints** plus the two analytics aggregates
   this spec adds. It introduces no new moderation capability.
6. **Numbers come from one source.** A public stats endpoint replaces every hand-maintained
   figure that can be computed; figures that cannot (e.g. "24/7 AI tutor") stay curated in the
   existing `StatStrip` with their provenance comments.

---

## 3. Public page set

| Route | Status | Owner phrase | Indexed | Prerendered |
|---|---|---|---|---|
| `/` | exists | language exchange app; practice with native speakers | yes | yes |
| `/download` | exists, rebuilt | download BananaTalk; language exchange app for iPhone/Android | yes | yes |
| `/meet` | **new** | meet people from other countries; international friends app | yes | yes |
| `/learn-korean` | **new** | learn Korean by chatting; talk to Korean native speakers | yes | yes |
| `/communities` | exists, public view added | language exchange communities; language clubs | yes | yes |
| `/profile/:userId` | exists | `{name} — learning {lang}, speaks {lang} on BananaTalk` | yes | no (dynamic) |
| `/privacy-policy`, `/terms-of-use`, `/support`, `/data-deletion` | exist | legal / support | yes | yes |
| `/moments` | exists (app promo) | Moments on BananaTalk | yes | yes |
| `/404` | **new** | — | noindex | yes (as `build/404.html`) |
| every other route | exist | — | **noindex** | no |

"Every other route" (`/login`, `/register`, `/chat/*`, `/settings/*`, `/my-moments`,
`/stories/*`, `/admin/*`, …) renders `PageMeta` with `noindex, nofollow` and a plain title.

The current sitemap's 28 URLs are handled as follows (exact list in §4.4): routes that exist
and are indexed stay; `/login`, `/register` and `/stories` exist but are noindex and leave the
sitemap; `/learn-korean` becomes real; four dead URLs with an obvious successor become 301s;
the remaining sixteen dead URLs are answered with HTTP 410 by nginx.

---

## 4. Phase A — Reach

### 4.1 Metadata layer

**`src/seo/pages.ts`** is the single source of truth for public-page metadata and the keyword
map. One entry per indexed route:

```ts
export type SeoPage = {
  path: string;                 // "/meet"
  titleKey: string;             // i18n key; English lives in eng.json
  descriptionKey: string;
  primary: string;              // the phrase the title and h1 target
  secondary: string[];          // supporting phrases used in body copy
  jsonLd?: (ctx: SeoContext) => object | object[];
  ogImage?: string;             // defaults to /og-default.png
};
```

The `primary`/`secondary` fields are documentation for the copywriter and reviewer and are
asserted against titles by test (§9); they are not rendered.

**`<PageMeta route="/meet" />`** (in `src/seo/PageMeta.tsx`) reads the entry, resolves the
i18n keys, and renders through `react-helmet-async`: `<title>`, `meta description`,
`link canonical` (`https://banatalk.com` + path, no query string), OG title/description/url/
image/type, Twitter card, `robots`, and any JSON-LD. `<PageMeta noindex title="…" />` is the
form for app-only routes. `HelmetProvider` wraps the app in `src/index.tsx` and, on the build
side, the prerender script.

**Dynamic routes** (`/profile/:userId`) call `<PageMeta route="/profile/:userId" values={{ name, learning, speaks }} />`
after data loads; the title template interpolates. Until data loads they render the generic
noindex form, so a crawler that executes JS still ends with the right tags, and a failed
fetch never produces an indexable empty profile.

**`public/index.html`** keeps its static tags as the fallback for any route that fails to set
its own, but: the 19 `hreflang` links are removed (the app has no per-language URLs; keeping
them lies to Google), the title's "50+ Languages" becomes "137 Languages" matching the page,
and `manifest.json` `theme_color` becomes `#14B8A6` to match the meta tag.

### 4.2 Static rendering

**Route tree extraction, first.** `src/router/AppRouter.tsx` currently calls
`createBrowserRouter(createRoutesFromElements(...))` at module load, which both touches
`window` on import and leaves the route tree unreachable to a static renderer. It is split:
`src/router/routes.tsx` exports the route objects (`createRoutesFromElements(<Route ...>)`,
with `App` as the layout element rendering `<Outlet/>` as today), and `AppRouter.tsx` becomes
`createBrowserRouter(routes)`. The client keeps `<RouterProvider router={AppRouter}/>` in
`index.tsx`. The prerender uses the same `routes` with the data-router static APIs that
`react-router-dom@6.23.1` already exports: `createStaticHandler(routes)`, `handler.query(new
Request(url))`, `createStaticRouter(routes, context)`, `<StaticRouterProvider router context/>`.
One tree, two providers; the hydration section below relies on this.

**`scripts/prerender.tsx`**, run by `npm run build` after `react-scripts build`
(`"build": "react-scripts build && node -r ./scripts/register.js scripts/prerender.tsx"`).

- `scripts/register.js` sets up `@babel/register` (new devDependency; only
  `babel-preset-react-app@10.0.1` is present today) with that preset, extensions
  `.ts .tsx .js .jsx`, and `ignore-styles`-style hooks that make `.css .scss .png .svg .jpg`
  imports resolve to empty modules or the filename.
- For each route in the public route list (`src/seo/publicRoutes.ts`, derived from `pages.ts`
  minus dynamic routes, plus `/404`), it builds a fresh Redux store, **prefetches the data the
  page needs** (below), runs the static handler for the URL, and renders
  `<HelmetProvider><Provider store={store}><StaticRouterProvider router={staticRouter} context={context} hydrate={false}/></Provider></HelmetProvider>`
  with `renderToString`, i18n fixed to English. `hydrate={false}` is required: by default
  `StaticRouterProvider` appends a `<script>window.__staticRouterHydrationData=…</script>`
  inside the markup, which the client's `RouterProvider` never renders, so leaving it on
  guarantees a hydration mismatch on every prerendered page.
- **Build-time data.** RTK Query hooks subscribe in effects, which `renderToString` never runs,
  so any data a prerendered page should contain is dispatched and awaited before render:
  `await store.dispatch(publicStatsApi.endpoints.getPublicStats.initiate())` for every page that
  mounts `StatStrip`, `getPublicCommunities` for `/communities`, and
  `getVipPlans("ios")` (the endpoint's argument is the platform string) for pages with `PricingSection` (the client refetches for
  Android after hydration; iOS and Android prices are the same figures today). A fetch that
  fails or times out (5s) is logged as a warning and the page renders its fallback (§8); the
  build does not fail on data. Components detect "no data" as `!data`, never `isLoading`, since
  an unsubscribed query reports `isUninitialized`. `PricingSection` already does this.
- It reads `build/index.html` as the template, replaces `<div id="root"></div>` with the
  rendered markup, injects helmet's `title`, `meta`, `link` and `script` output into `<head>`
  (replacing the static title/description/canonical/OG tags it supersedes), and writes
  `build/<path>/index.html` (`/` → `build/index.html`, `/404` → `build/404.html`).
- **Failure is loud.** Any thrown error, any route whose output has no `<h1`, and any access to
  `window`, `document`, `localStorage` or `matchMedia` during render (detected by a Proxy on
  `globalThis` that throws) fails the build with the route name. A silent fallback here would
  ship an empty page to crawlers, which is the problem we are fixing.
- Render-time discipline is the only cost. Components on public routes read `window` in
  effects, never in render. Where the current code reads at module top level
  (`inferPlatform` in `plansSlice.ts`, `prefersReducedMotion`), it is wrapped so it returns a
  neutral default when `typeof window === "undefined"`. Known render-time readers that the
  inventory (§11) must handle: `AppBanner.tsx:31` (`navigator.userAgent` in render, mounted by
  `App` on every route), `plansSlice.inferPlatform`, `anim/useInView`'s reduced-motion check,
  and anything in `App.tsx`/`SocketProvider` that runs outside an effect.

**Hydration.** `src/index.tsx` uses `hydrateRoot` when `#root` has children and `createRoot`
otherwise, in both cases rendering `<RouterProvider router={AppRouter}/>` over the same
`routes` tree the prerender used, so the matched element tree is identical. Because i18n on
the client may resolve to a non-English language after detection,
the first client render is forced to English to match the prerendered markup, then
`changeLanguage` runs in an effect. This avoids a hydration mismatch and a flash of wrong
language is acceptable for a first visit; a stored language choice applies after hydration.

**Not prerendered:** routes with `:params`, and everything noindex. nginx's existing SPA
fallback (`try_files $uri $uri/ /index.html`) keeps them working: `$uri/` serves prerendered
folders, `/index.html` serves the shell for the rest.

### 4.3 Sitemap

`scripts/prerender.tsx` also writes `build/sitemap.xml` from the public route list with
`lastmod` set to the build date and no priorities (Google ignores them). `public/sitemap.xml`
is deleted so a stale hand-written copy can never win. `public/robots.txt` continues to point
at `/sitemap.xml`.

### 4.4 404 and dead URLs

- A `path="*"` route renders `NotFound` (`src/components/errors/NotFound.tsx`): a short
  message, a link home and to `/download`, `PageMeta noindex`. It is prerendered to
  `build/404.html`.
- **`deploy/nginx.snippet.conf`**, versioned in the repo with a comment explaining how to
  include it in the server block:
  - `error_page 404 /404.html;` and a `location = /404.html { internal; }`.
  - **301 redirects**, dead URL → successor: `/privacy` → `/privacy-policy`, `/terms` →
    `/terms-of-use`, `/pen-pals` → `/meet`, `/language-exchange` → `/`.
  - **`return 410;`** for the sixteen dead sitemap URLs with no successor: `/about`,
    `/features`, `/languages`, `/help`, `/faq`, `/blog`, `/success-stories`, `/learn-english`,
    `/learn-spanish`, `/learn-japanese`, `/learn-chinese`, `/learn-french`, `/learn-german`,
    `/video-call`, `/cultural-dating`, `/international-dating`.
  - `try_files $uri $uri/ /index.html;` unchanged.

  The snippet is applied by hand on the server; the spec cannot version the live config.
  The frontend has no `README.md` today; the plan creates one with a "Deploy" section that
  documents the build, the prerender step and this snippet.

- **Footer links.** `FooterMain.tsx` links to `/pricing` and `/contact`, neither of which
  exists, and labels `/communities` "About". After this work every prerendered page would link
  to a 410, so the footer changes in Phase A: `/pricing` → `/#pricing` (the homepage section),
  `/contact` → `/support`, the "About" label → "Communities", plus links to `/download`,
  `/meet` and `/learn-korean` once those exist in Phase B. A test asserts every internal footer
  link matches a route in the tree.

### 4.5 Measurement

**GA4.** `src/analytics/ga.ts` exposes `loadGa(measurementId)` and `gaEvent(name, params)`.
The ID comes from `REACT_APP_GA_MEASUREMENT_ID`; absent, GA is a no-op (tests, local dev).
`loadGa` injects the gtag script only after consent (below) and sets
`anonymize_ip`. `gaEvent` is called from the same places as first-party tracking.

**Consent.** `src/components/growth/ConsentBar.tsx`: a one-line bar at the bottom, "We use
analytics cookies to understand what brings people here. OK / No thanks", i18n'd, dismissed
state stored under `bt.consent` = `granted | denied` in `localStorage`, guarded with try/catch
like the growth gate. Default (no choice) = no GA. Denied = no GA, first-party events still
sent because they carry no cookie and no identifier beyond what the visit endpoint already
records. The bar is excluded from prerendered output (rendered only after mount) so it never
appears in the crawler's HTML. It respects `growthGate`'s stacking: it does not show while
the download popup is open.

**First-party events.** `src/analytics/track.ts` exposes
`trackEvent(name: "page_view" | "store_tap" | "cta_tap", data)` posting to
`POST /api/v1/analytics/events` with `{ name, path, placement, platform, referrer, language,
sessionId }`. `sessionId` is a random id held in `sessionStorage` for the tab; it is not a
user identifier. Fire-and-forget with one retry; never throws; queued until `document` is
ready so prerender never sends anything. `page_view` fires on route change from a hook in
`App.tsx`; `store_tap` fires from a shared `StoreLink` component (§5.1) with `placement` such
as `hero`, `pricing`, `final-cta`, `download-page`, `sticky-banner`, `popup`, `promo-carousel`,
`meet`, `learn-korean`.

The existing `POST /analytics/visit` stays as it is.

### 4.6 Truthful numbers

`GET /api/v1/public/stats` (§7.1) returns `{ learners, languages, countries }` rounded down
to two significant figures (12,431 → 12,000) so the page never shows a figure that is stale
by lunchtime. `src/store/slices/publicStatsSlice.ts` wraps it. `StatStrip` renders the learner
count as the first stat when the query succeeds and its current four curated stats otherwise;
the count-up animation is unchanged. The homepage never shows a learner count below 1,000
(the endpoint returns `learners: null` under that threshold, and the frontend hides the stat),
so early days do not read as empty.

---

## 5. Phase B — Marketing polish

### 5.1 Shared pieces

- **`StoreLink`** (`src/components/growth/StoreLink.tsx`): the one component that renders an
  App Store or Google Play link. Props `store: "ios" | "android"`, `placement`, `variant:
  "badge" | "button"`. It owns the URLs (moved out of `MomentsAppPromo`, `HeroDemo`,
  `FinalCta`, `DownloadApp`, growth surfaces), appends UTM parameters
  (`utm_source=banatalk.com&utm_medium=web&utm_campaign=<placement>`), and calls both
  `trackEvent("store_tap")` and `gaEvent`. Every existing store link is replaced by it; a test
  greps `src/` for the raw store URLs and fails if they appear outside this file.
- **Copy** follows the existing idiom `t("key") || "English fallback"`; i18n returns `""` on
  a miss so the fallback works. New keys go to `eng.json` **and** the 17 other locales, as the
  homepage translation commit (`a96ff5d`) established; a test asserts key-set parity per
  namespace (`home`, `download`, `meet`, `learnKorean`, `seo`, `consent`, `notFound`).

### 5.2 Homepage

Structure unchanged (`HeroDemo → StatStrip → HowItWorks → FeatureShowcase → LanguageMarquee →
PricingSection → EarlyAdopterBand → FinalCta`). Changes:

- **Hero.** The visual headline stays "Say it badly. We'll translate." The supporting line
  becomes the primary phrase in plain words, e.g. "Free language exchange with native speakers
  — write in your language, they read it in theirs, and you learn from the difference." The
  `h1` wraps both lines so the phrase is in the h1 without the headline becoming a keyword
  list. Exact copy is written in the plan against `pages.ts`.
- **Stat strip** gains the learner count (§4.6).
- **Hardcoded English** in `FeatureShowcase` (FEATURES), `HowItWorks` (STEPS),
  `LanguageMarquee` ("137 languages, and counting"), all of `EarlyAdopterBand`, hero store
  labels and "In the app" moves to i18n under `home.*`.
- **Marquee** heading becomes an `h2` ("Someone is learning your language right now") so the
  section has a heading like its siblings.
- All store links become `StoreLink`.

### 5.3 Download page

`/download` (`src/components/download/DownloadApp.tsx`) is rebuilt as a landing page:

- `h1` "Download BananaTalk", one-line subtitle, both `StoreLink` badges
  (`placement="download-page"`), a QR code rendered client-side (`qrcode` package, ~10KB;
  rendered after mount so prerender emits a placeholder box) pointing at
  `https://banatalk.com/download?src=qr`, three short reasons reusing `SurfaceCard`, and a
  reassurance line ("Free. No card.").
- **Auto-redirect changes.** Today any mobile visitor is redirected immediately, which makes
  the page unreadable and un-indexable. New rule: redirect only when `?go=1` is present (the
  growth surfaces and QR link append it); otherwise show the page. Mobile visitors see one
  badge for their platform first.
- `PageMeta route="/download"` with `SoftwareApplication` JSON-LD carrying both store URLs and
  the real price range from the plans fallback ("Free, VIP from $9.99").

### 5.4 Two landing pages

Both are compositions of existing homepage parts with different copy, under
`src/components/landing/`. No new visual components; each page is a ~60-line orchestrator plus
a copy module.

**`/meet`** — `MeetLanding.tsx`. Owner phrases: meet people from other countries, international
friends app. Sections: hero (`HeroDemo` with a demo conversation about weekend plans, not a
grammar correction), `HowItWorks` framed as "pick a language, say hi, keep talking",
`FeatureShowcase` filtered to community, waves, topics, nearby, `LanguageMarquee`, `FinalCta`
with `placement="meet"`. Tone is friendly and explicitly not dating; the word "date" does not
appear.

**`/learn-korean`** — `LearnKoreanLanding.tsx`. Owner phrases: learn Korean by chatting, talk to
Korean native speakers. Sections: hero with a Korean demo (Hangul message, romanisation on
tap, translation, a tutor note on 존댓말 vs 반말), a three-item "why chatting works for Korean"
block reusing `HowItWorks`'s layout, `FeatureShowcase` filtered to translation, AI tutor,
community, `FinalCta` with `placement="learn-korean"`. `PageMeta` JSON-LD: `Course`-free (we
are not a course); plain `WebPage`.

Both pages: `PageMeta` from `pages.ts`, prerendered, in the sitemap, i18n'd with the same
fallback idiom, linked from the footer ("Meet people", "Learn Korean") so they have internal
links.

### 5.5 Public communities

`GET /api/v1/public/communities` (§7.2). `MainCommunity` currently assumes auth. New behaviour:
when `userInfo` is absent it renders `PublicCommunities` (`src/components/community/PublicCommunities.tsx`):
`h1` "Language exchange communities", a grid of `SurfaceCard`s with name, one-line
description, member count and one `LanguageExchangePill` per language (one today, since a
club has a single `language`), each card's action being a
`StoreLink` (`placement="communities"`) since joining requires the app. The prerender
prefetches `getPublicCommunities` before rendering (§4.2), so the crawler's HTML contains the
real list; when the endpoint is unreachable at build time the build **does not fail** (this is
data, not code) and the page prerenders its empty-state copy, logged as a warning. Logged-in
behaviour is unchanged.

### 5.6 Weight

- Route-level `React.lazy` + `Suspense` in `AppRouter.tsx` for everything outside the public
  page set; the public pages stay in the main chunk so prerender and first paint need no
  network. Chat, stories, moments composer, profile edit, settings and admin each become their
  own chunk.
- `bootstrap-icons` stylesheet removed from `index.html` after a grep confirms the remaining
  `bi-*` class usages are in lazy chunks, which then import it themselves. If any public-page
  component uses `bi-*`, it switches to `lucide-react`.
- The unused Google Fonts `preconnect` is removed.
- **Budget:** the JavaScript needed to render `/` (main chunk plus its synchronous imports)
  stays under 150KB gzipped; a test on `build/asset-manifest.json` plus gzip sizes enforces it.
  If the budget cannot be met without touching chat or Bootstrap, the plan says so and the
  budget is renegotiated rather than silently raised.

---

## 6. Phase C — Admin console

### 6.1 Access

- The login/refresh response already includes `user.role` (`sendTokenResponse` serialises the
  full user via `toObject()`); the plan confirms it with a test against the stored `userInfo`
  and adds nothing to the backend unless that test fails. `authSlice` derives
  `isAdmin = user.role === "admin"` and drops the unused manual flag.
- `MainNavbar` shows an "Admin" item (desktop and mobile menus) only when `isAdmin`; it links to
  `/admin`.
- `RequireAdmin` (`src/components/admin/RequireAdmin.tsx`) wraps every `/admin/*` route:
  renders children when `isAdmin`, otherwise `<Navigate to="/" replace />`. It is an experience
  guard; the backend enforces the role on every admin endpoint already.
- All `/admin/*` routes are `PageMeta noindex` and lazy-loaded in one chunk.

### 6.2 Layout and pages

`AdminLayout` (`src/components/admin/AdminLayout.tsx`): a left rail (collapses to a top tab
row under 768px) and a content pane, built from `src/design` primitives and Tailwind; no
Bootstrap, no SCSS. Pages, each in `src/components/admin/pages/`:

| Route | Page | Backend |
|---|---|---|
| `/admin` | Overview | `GET /admin/stats`, `GET /admin/activity`, `GET /admin/analytics/visits` |
| `/admin/reach` | Reach | `GET /admin/analytics/events` (by day, placement, platform, referrer), `GET /admin/analytics/visits` (country, device, new vs returning) |
| `/admin/users` | Users | `GET /admin/users` (search, paginated), `GET /admin/users/:id`, `POST …/ban`, `POST …/unban`, `PUT …/role`, `GET /admin/banned-users`, `DELETE /admin/users/:id` |
| `/admin/content` | Content | `GET /admin/content/clubs`, `GET /admin/content/gatherings`, `POST …/clubs/:id/archive`, `POST …/gatherings/:id/cancel` |
| `/admin/ai-usage` | AI usage | `GET /admin/ai-usage`, `GET /admin/ai-usage/logs` |
| `/admin/audit` | Audit log | `GET /admin/audit-log` (paginated) |

**Overview** shows the stat cards the backend already computes (total, new today, new this
week, active this week, VIP, banned, by role) and the activity feed. **Reach** shows a 30-day
line of page views and store taps, a table of taps by placement × platform, top referrers, and
visits by country and device. Charts use inline SVG (no chart library; the `dataviz` skill's
guidance applies at implementation). **Users** is a search box, a paginated table, and a detail
drawer with the actions. Ban, unban and role change confirm with a dialog; hard delete requires
typing the user's email. **Content**, **AI usage** and **Audit log** are tables with the
backend's own pagination.

### 6.3 Data

`src/store/slices/adminSlice.ts` (RTK Query, `injectEndpoints` on `apiSlice`) with one endpoint
per row above, tags `AdminUser`, `AdminUserList`, `AdminContent`, `AdminStats`. Ban/unban/role
invalidate `AdminUser` and `AdminUserList`; archive/cancel invalidate `AdminContent`. No
polling; a manual refresh button per page. Errors from the backend's `ErrorResponse` shape are
shown inline; destructive mutations are never retried.

### 6.4 Scope guard

The console offers exactly what the backend exposes today plus the two analytics reads in §7.
No new moderation action, no user editing beyond role, no export, no email. If a page needs
something the backend lacks, it is listed under "Not in this spec".

---

## 7. Backend changes (all additive)

| # | Endpoint | Auth | Purpose |
|---|---|---|---|
| 7.1 | `GET /api/v1/public/stats` | none | `{ learners, languages, countries, generatedAt }`. `learners` = count of non-banned users rounded down to two significant figures, `null` below 1,000; `languages` = 137 from the catalog; `countries` = distinct user countries, same rounding. In-memory cache, 1 hour. |
| 7.2 | `GET /api/v1/public/communities` | none | Clubs with `status: 'active'` (the `Club` model has no visibility field): `{ id, name, description, memberCount, languages[] }` where `languages` is `[club.language]` today so the shape can grow, limit 24, sorted by memberCount desc. Cache 10 minutes. |
| 7.3 | `POST /api/v1/analytics/events` | none | Body `{ name, path, placement?, platform?, referrer?, language?, sessionId }`, `name` enum `page_view | store_tap | cta_tap`. Stores `WebEvent` with server-side `device`/`os` from UA (reusing `parseUserAgent` from `analytics.js`), `ip` hashed with a server salt (not stored raw). Rate-limited 60/min per IP. Returns 204. |
| 7.4 | `GET /api/v1/admin/analytics/events` | admin | Query `days` (default 30). Returns `{ byDay: [{ date, pageViews, storeTaps }], byPlacement: [{ placement, platform, taps }], topReferrers: [{ referrer, count }], topPaths: [{ path, views }] }` via aggregation. |
| 7.5 | `GET /api/v1/admin/analytics/visits` | admin | Thin wrapper over the existing `WebVisit.getWeeklyStats`: returns its `thisWeek`, `lastWeek`, `dailyBreakdown`, `topCountries` and `deviceBreakdown` unchanged, plus one derived field `newVisitorRatio = thisWeek.newVisitors / thisWeek.totalVisits` (those are the helper's actual key names; `0` when `totalVisits` is 0). No new aggregation. |

New model `WebEvent` (`models/WebEvent.js`) with a TTL index of 400 days. Routes in
`routes/public.js` (new) and additions to `routes/analytics.js` and `routes/admin.js`. Each has a
supertest route test in the backend's existing style. No existing endpoint or model changes.

---

## 8. Error handling

- **Public pages never depend on the backend to render.** Stats missing → curated stats only.
  Communities missing → empty-state copy with store links. Plans missing → existing fallback.
  Prerender prefetches these three (§4.2) and emits live data when the fetch succeeds and the
  same fallback when it fails, so a crawler always sees a complete page either way.
- **Prerender fails loudly** on thrown errors, missing `h1`, or browser-global access (§4.2).
  It does **not** fail on data-fetch failures at build time; those are logged and fall back.
- **Analytics never reaches the user.** `trackEvent` and `gaEvent` swallow all errors after one
  retry. The consent bar defaults to no tracking. If `localStorage` throws, consent is treated
  as undecided and the bar shows.
- **Admin** shows the backend's message inline, keeps the table's last good data, never retries
  a destructive call, and redirects to `/` if the role disappears (e.g. after logout).

---

## 9. Testing

Frontend, Jest + Testing Library, run with `CI=true npx react-scripts test`:

- **`seo/pages.test.ts`:** every indexed route in the router has an entry; every entry's
  English title ≤ 60 chars and description ≤ 160; no two routes share a title; each title
  contains its `primary` phrase (case-insensitive, allowing the brand suffix).
- **`scripts/prerender.test.ts`:** renders every public route in Node with the same harness the
  script uses; asserts non-empty markup, exactly one `<h1`, helmet title and description
  present, one canonical, and that the browser-global Proxy did not trip.
- **Sitemap:** generated XML's `<loc>` set equals the public route list.
- **`analytics/track.test.ts`:** payload shape; silent on network failure; nothing sent before
  `document` is ready; `gaEvent` no-op without consent or ID.
- **`ConsentBar.test.tsx`:** default hidden GA; grant loads; deny does not; storage throwing
  shows the bar.
- **`StoreLink.test.tsx`:** correct URL per store, UTM params, both trackers called with
  placement; **repo grep test** that raw store URLs appear only in `StoreLink.tsx`.
- **Landing pages, download page, `PublicCommunities`, `NotFound`:** render tests in the
  existing style: h1 present, store links via `StoreLink`, copy via i18n keys (mock `t` echoes
  keys), fallback copy when `t` returns `""`.
- **Locale parity:** every locale carries the same key set as English under each new namespace.
- **Hydration guard:** `index.tsx`'s chooser picks `hydrateRoot` when `#root` has children.
- **Admin:** `RequireAdmin` redirects non-admins; navbar shows "Admin" only for admins;
  `adminSlice` ban invalidates `AdminUser` and `AdminUserList`; one render test per page against
  mocked data; hard-delete dialog disabled until the email matches.
- **Bundle budget:** a test reads `build/asset-manifest.json`, gzips the main chunk and its
  synchronous CSS, and asserts ≤ 150KB. Runs only when `build/` exists (skipped in unit runs;
  run in `npm run deploy` before the nginx reload).

Backend, existing test runner: one route test per new endpoint (§7) covering the happy path,
auth rejection for admin routes, rate limiting for events, and rounding/threshold for stats.

---

## 10. Explicitly not in this spec

Community and profile cleanup (design-primitive adoption, Bootstrap retirement, orphaned
stylesheets) — separate sub-project. Remaining Moments/Stories coherence (the five
`navigate("/moments")` dead ends, dead `MyStories`, stories vs. app-only claim) — separate
sub-project, except that any `navigate("/moments")` encountered while touching a file in this
work is changed to `/my-moments`. Per-language URLs or translated slugs. Any additional landing
page beyond `/meet` and `/learn-korean`. Blog, FAQ page, testimonials, reviews, user counts under
1,000. Web payments. Email, export or new moderation actions in the admin console. Search
Console verification itself (the user does it; the spec only makes the site worth verifying).

---

## 11. Risks

- **Render-time `window` access lurks in shared components.** Mitigated by the failing Proxy
  and by keeping the public page set small; the plan inventories `window`/`document`/
  `navigator`/`localStorage`/`matchMedia` reads under `src/App.tsx`, `src/components/linking`
  (`AppBanner` is a known offender), the socket provider, and
  `src/components/{home,growth,download,landing,community,navbar,footer}` before writing the
  script, and moves each into an effect or behind a `typeof window` guard.
- **The route-tree split touches every route.** `routes.tsx` is a mechanical move, but the
  existing `AppRouter` import in `index.tsx` and any test that imports the router must follow.
  The plan does this as its first task so the rest of Phase A builds on it.
- **Hydration mismatch from language detection.** Mitigated by first-render-in-English (§4.2);
  if a mismatch still appears, `suppressHydrationWarning` is **not** the fix — the differing
  component moves its language-dependent output into an effect.
- **TypeScript 3.7.2** cannot type newer library versions; `react-helmet-async` 1.x and `qrcode`
  1.5 are known to work under it. `npx tsc` is unusable in this repo; `react-scripts build` is
  the type check, and the prerender step runs after it so a type error still fails first.
- **Build-time data fetch on the server** hits the production API from the same host; if the
  API is down during deploy the communities page prerenders empty (§5.5), which is acceptable
  and logged.
- **GA4 consent bar reduces GA coverage.** Accepted; first-party events cover store taps
  regardless of consent.
- **Bundle budget may be unattainable** while Bootstrap is global. §5.6 makes renegotiation
  explicit rather than silent.
