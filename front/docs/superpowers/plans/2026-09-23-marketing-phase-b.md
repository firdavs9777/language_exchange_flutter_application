# Marketing Polish (Phase B) Implementation Plan

> **For agentic workers:** execute task-by-task with a fresh implementer per task and a review after each. Steps use `- [ ]`.

**Goal:** turn the public pages into the strongest case for installing the app: one tracked `StoreLink` everywhere, homepage copy written against the keyword map and fully localized, a real download landing page, two new landing pages (`/meet`, `/learn-korean`), a public communities page for crawlers and visitors, and a lighter marketing bundle.

**Spec:** `docs/superpowers/specs/2026-09-22-reach-marketing-admin-design.md` §5 (all), §7.2. Keyword map: `src/seo/pages.ts`.

## Global Constraints

- Frontend `/Users/davis/Desktop/Personal/language_exchange_web_front`, branch `feat/marketing-b` off `main`; backend `/Users/davis/Desktop/Personal/language_exchange_backend_application`, branch `feat/public-communities` off `main`. **No `Co-Authored-By` trailers.**
- Frontend tests: `CI=true npx react-scripts test --testPathPattern=<pattern>` (foreground). Baseline 114 suites / 756 tests. TypeScript 3.7.2: no `import type`, no `export type {}`; new libraries must ship `.d.ts` that parse under 3.7 (verify by building).
- Every public page is prerendered: no `window`/`document`/`navigator` reads during render; content in the DOM at first paint; `src/seo/prerender/renderRoute.test.tsx` must stay green and every new indexed page joins `SEO_PAGES` (which drives the sitemap, prerender list and metadata) with an English title ≤ 60 chars containing its `primary` phrase and description ≤ 160.
- Copy idiom `t("key") || "English"`; every new key lands in all 18 locales (translate the 17) via `scripts/i18n/merge-keys.js` in the final task; `localeParity.test.ts` guards the touched namespaces.
- Store URLs may exist only in `StoreLink.tsx` (a test greps `src/` for `apps.apple.com` / `play.google.com` outside that file and fails otherwise).
- Backend contract for public communities: `GET /api/v1/public/communities` → `{ success, data: [{ id, name, description, memberCount, languages: [club.language] }] }`, `status: 'active'` only, limit 24, sorted by `memberCount` desc, 10-minute in-memory cache, no auth (spec §7.2; `models/Club.js` has `status`, `language`, `memberCount`).

---

### Task B0 (backend): `GET /api/v1/public/communities`
**Files:** `controllers/public.js` (add `getPublicCommunities` + `_resetPublicCommunitiesCache`), `routes/public.js` (one route), `test/publicCommunities.test.js` (mongodb-memory-server; active vs archived clubs, sort, limit 24, shape, cache).
- [ ] TDD; `nvm use 24`; `npm test | tail -14`; commit `feat(public): GET /public/communities for the marketing site`.

### Task B1: `StoreLink`
**Files:** create `src/components/growth/StoreLink.tsx` (+test), `src/components/growth/storeUrls.test.ts` (repo grep guard); modify every current store link: `HeroDemo.tsx`, `FinalCta.tsx`, `PricingSection.tsx` (VIP CTA), `DownloadApp.tsx`, `FooterMain.tsx`, `AppDownloadPopup.tsx`, `StickyAppBanner.tsx`, `PromoCarousel.tsx` (its "Get the app" CTA if it links to a store), `src/utils/platform.ts` (keep exporting the URLs from here OR move them into StoreLink — pick one home: `StoreLink.tsx` re-exports `APP_STORE_URL`/`PLAY_STORE_URL` and `platform.ts` imports from it, so the grep test passes).
**Interface:** `<StoreLink store="ios"|"android" placement="hero"|"pricing"|"final-cta"|"download-page"|"sticky-banner"|"popup"|"promo-carousel"|"footer"|"meet"|"learn-korean"|"communities" variant="badge"|"button"|"text" className? children? />` renders an `<a target="_blank" rel="noopener noreferrer">` with UTM params `utm_source=banatalk.com&utm_medium=web&utm_campaign=<placement>`, calls `trackEvent("store_tap", { placement, platform: store })` and `gaEvent("store_tap", { placement, platform: store })` on click (never blocks navigation), `data-testid="store-link-<store>"`. `variant="badge"` draws the existing inline SVG store badges (move them out of `DownloadApp`/`FooterMain`).
- [ ] TDD (href/UTM per store, both trackers called with placement, grep guard); commit `feat(growth): one StoreLink with UTM and store_tap tracking everywhere`.

### Task B2: homepage copy and i18n
**Files:** `HeroDemo.tsx` (supporting line carries the primary phrase: `t("home.hero.subtitle")` English becomes "Free language exchange with native speakers. Write in your language, they read it in theirs, and you learn from the difference."), `FeatureShowcase.tsx` (FEATURES → `home.features.items.<key>.title/body`), `HowItWorks.tsx` (STEPS → `home.howItWorks.steps.<n>.title/body`), `LanguageMarquee.tsx` (`<p>` → `<h2>` with `home.marquee.title`; "137 languages, and counting" → `home.marquee.caption`), `EarlyAdopterBand.tsx` (all copy → `home.earlyAdopter.*`), `FeatureShowcase` "In the app" → `home.features.inApp`. Keep `data-testid`s; extend `staticSections.test.tsx`/`FeatureShowcase.test.tsx` so `t` echoing keys proves every string goes through i18n and `t: () => ""` proves fallbacks.
- [ ] TDD; commit `feat(home): keyword-led hero line; every homepage string through i18n`.

### Task B3: download landing page
**Files:** rewrite `src/components/download/DownloadApp.tsx` (+test), delete `DownloadApp.scss` if fully replaced by Tailwind, `package.json` (add `qrcode` + `@types/qrcode` — verify types parse under TS 3.7.2 in the build; if not, render the QR with a tiny inline implementation via `qrcode`'s `toString` at runtime only), `src/seo/pages.ts` (`/download` gains `jsonLd` → `SoftwareApplication` with both store URLs and `offers` "Free, VIP from $9.99").
Behaviour: `h1` "Download BananaTalk", subtitle, two `StoreLink variant="badge" placement="download-page"` (mobile visitors see their own store first — decided in an effect, not render), a QR code rendered after mount into a placeholder box (prerender emits the box), pointing at `https://banatalk.com/download?src=qr`, three `SurfaceCard` reasons, "Free. No card." line. Redirect only when `?go=1` is present (growth surfaces and the QR link append it); otherwise the page is readable.
- [ ] TDD (badges, `go=1` redirect via a mocked `window.location.assign`, no redirect otherwise, QR placeholder present in `renderToString`); commit `feat(download): a real landing page with QR and store badges`.

### Task B4: `/meet` and `/learn-korean`
**Files:** create `src/components/landing/MeetLanding.tsx`, `LearnKoreanLanding.tsx` (+tests), `src/components/landing/copy.ts` (per-page copy keys), modify `src/router/routes.tsx` (two routes), `src/seo/pages.ts` (two entries: `/meet` primary "meet people from other countries", `/learn-korean` primary "learn Korean by chatting"), `FooterMain.tsx` (links "Meet people", "Learn Korean"), `HeroDemo.tsx` (accept `variant` props or extract a `HeroDemoBase` so the landing heroes reuse it with different demo lines — keep the homepage hero unchanged), `FeatureShowcase.tsx` (accept an optional `only?: string[]` filter). Each landing = hero (own demo conversation), `HowItWorks` (own step copy), filtered `FeatureShowcase`, `LanguageMarquee`, `FinalCta` with its `placement`. `/meet` must not use the word "date". `/learn-korean` demo uses Hangul with the tutor note on 존댓말 vs 반말.
- [ ] TDD (both routes match; SEO map tests pass; `renderRoute` renders both with one `h1`; footer links present); commit `feat(landing): /meet and /learn-korean landing pages`.

### Task B5: public communities page
**Files:** `src/store/slices/publicCommunitiesSlice.ts` (`getPublicCommunities`), `src/components/community/PublicCommunities.tsx` (+test), modify `MainCommunity.tsx` (logged out → render `PublicCommunities` instead of `<Navigate to="/login">`), `src/seo/pages.ts` (`/communities` entry, primary "language exchange communities"), `src/seo/prerender/prefetch.ts` (prefetch `getPublicCommunities` for `/communities`).
Behaviour: `h1` "Language exchange communities", grid of `SurfaceCard`s (name, description, member count, one `LanguageExchangePill` per language), each card's action a `StoreLink placement="communities"`, empty-state copy with store links when the list is empty or the fetch failed.
- [ ] TDD; commit `feat(community): public communities page for visitors and crawlers`.

### Task B6: weight
**Files:** `src/router/routes.tsx` (`React.lazy` + one `Suspense` per non-public route group: chat, stories, moments composer/detail, profile, settings, community-authenticated pages, courses; public routes stay eager), `public/index.html` (remove the jsdelivr `bootstrap-icons` stylesheet and the unused Google Fonts `preconnect` if any remains after the fonts change), `src/index.tsx` (import `bootstrap-icons/font/bootstrap-icons.css` only from the lazy chunks that use `bi-*` — grep; public components using `bi-*` switch to `lucide-react`), `src/seo/bundleBudget.test.ts` (reads `build/asset-manifest.json`, gzips the main chunk + its CSS, asserts ≤ 150KB; `describe.skip` when `build/` is absent), `package.json` (`"test:budget"` script run after build in `deploy`).
- [ ] Build, measure, record the numbers in the report; if the budget cannot be met without Bootstrap retirement, set the assertion to the measured value + 5% and say so (spec §5.6 renegotiation). Commit `perf(marketing): lazy-load the app, drop the blocking icon stylesheet, add a bundle budget`.

### Task B7: locales, verification, merge
- [ ] Inventory new keys (`home.*`, `download.*`, `meet.*`, `learnKorean.*`, `communities.public.*`, `seo.meet/learnKorean/communities`) → all 18 locales via merge script; parity test namespaces.
- [ ] Full suite; build; `build/meet/index.html` and `build/learn-korean/index.html` exist with one `h1` and a canonical; sitemap now 10 URLs; nginx allowlist includes `meet` and `learn-korean`; `deploy/nginx.snippet.conf` `/pen-pals → /meet` now lands on a real page; browser smoke: `/`, `/download`, `/meet`, `/learn-korean`, `/communities` hydrate clean, store links carry UTM and fire `store_tap`.
- [ ] Merge both branches into their mains `--no-ff`; push.

## Not in this plan
Self-hosting fonts, Bootstrap retirement, consent withdrawal UI, Moments Phase 2, admin changes.
