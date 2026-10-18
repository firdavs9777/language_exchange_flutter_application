# Marketing Homepage & Growth Surfaces — Design

**Date:** 2026-09-22
**Status:** approved, ready for implementation planning
**Goal:** replace the current homepage with a real marketing landing page that argues for the
product, tells the truth about its prices, and converts visitors into app installs.

**Scope:** web-only. No backend change, no API change, no payment processor.

**Relationship to other sub-projects.** This **replaces** sub-project 6 ("AI Study / VIP
redirect + app-download banner") rather than adding to it — that work is absorbed here. It
depends on sub-project 1 (the design foundation, merged as `0dd3869`) and is the first real
consumer of its tokens and primitives.

---

## 1. Why now

### 1.1 The site is advertising prices the stores do not charge

`HomeMain.tsx:137-190` hardcodes a pricing table. `controllers/iosPurchase.js:20-120` holds
what the stores actually bill:

| Plan | Website says | Stores charge | Gap |
|---|---|---|---|
| Monthly | `$14.99` | `$9.99` | overstated 50% |
| Yearly | `$49.99` | `$71.99` | **understated by $22** |
| Quarterly | not shown at all | `$23.99`, saves 20% | missing |

The yearly row is the damaging one. A visitor decides on `$49.99/year`, reaches the App
Store, and is asked for `$71.99`. That is the mismatch that produces abandoned checkouts,
refund requests and store-review complaints — and it is invisible to anyone who does not
diff two repositories by hand.

A public endpoint that solves this already exists and is unused: `GET /purchases/plans`
(`routes/purchases.js:37`), described in its own comment as "public endpoint for displaying
prices before login."

### 1.2 The homepage is the largest concentration of off-brand styling

`HomeMain.scss` is 1076 lines and holds the heaviest cluster of hardcoded `#00BFA5` in the
codebase. Sub-project 1 shipped the tokens that replace it; nothing consumes them yet.

### 1.3 The page argues for itself, not for the product

The current hero states what the app is. It never shows the mechanic — translation and
correction in flight — which is the only thing that distinguishes this from Duolingo in the
four seconds a visitor gives it.

---

## 2. Decisions taken before design

Recorded because each closes off alternatives a reader would otherwise reopen.

| Decision | Choice | Why |
|---|---|---|
| "Real subscription" | Live plan **data**; purchase stays in the app | No web payment processor exists in either repo; adding one means Stripe, webhooks, tax, and three-way entitlement reconciliation with Apple and Google. Out of scope, and it contradicts the standing decision that VIP registration goes to the app. |
| Rebuild depth | Full rebuild in Tailwind | The SCSS is where the drift lives; restyling it leaves the homepage on a second design system. |
| Hero | Demo-forward | Shows the mechanic before the fold. |
| Social proof | Mechanism + early-adopter framing | The App Store listing has **0 ratings, 0 reviews** (verified via the iTunes lookup API; released 2025-12-16). |
| Testimonials | **None, real or otherwise** | Fabricated reviews on a live consumer site are deceptive and regulated. The section is not built, rather than built empty. |
| Carousel | Promo banner + language marquee | The banner carries the download push; the marquee makes "137 languages" tangible. A screenshot carousel is deliberately omitted — see §7. |
| Popup | Earned, once per 30 days | See §5.2. |

---

## 3. Page architecture

`HomeMain.tsx` drops from 597 lines to an orchestrator of roughly 100, composing parts that
are each independently readable and testable.

```
src/components/home/HomeMain.tsx          orchestrator
src/components/home/parts/
  HeroDemo.tsx            animated chat + AI-tutor correction
  StatStrip.tsx           four verifiable facts
  HowItWorks.tsx          the three-step walkthrough
  FeatureShowcase.tsx     real features, real screenshots
  LanguageMarquee.tsx     curated language scroll
  PricingSection.tsx      live plans
  EarlyAdopterBand.tsx    launch framing
  FinalCta.tsx            closing store buttons
src/components/growth/
  PromoCarousel.tsx       rotating dismissible announcements
  AppDownloadPopup.tsx    earned popup
  StickyAppBanner.tsx     mobile-only sticky bar
  growthGate.ts           trigger, suppression and exclusion logic — PURE
src/data/promoSlides.ts   carousel copy as data
src/store/slices/plansSlice.ts
```

**`HomeMain.scss` is deleted.** Every part uses the tokens from sub-project 1 —
`bg-brand`, `text-brand-dark`, `bg-banana/[0.28]`, `rounded-card`, `shadow-card` — and the
primitives `SurfaceCard`, `Badge` and `Avatar` where they fit.

`growthGate.ts` holds no JSX on purpose. Its rules are the part most likely to be wrong and
the part hardest to verify through a rendered component, so they are a pure module with
their own unit tests.

---

## 4. The pricing section

`plansSlice.ts` adds one RTK Query endpoint against `GET /purchases/plans`, passing
`platform=ios` or `platform=android` inferred from the user agent, defaulting to `ios` on
desktop. Note this does **not** mirror the desktop CTA: `handleVipCta` at
`HomeMain.tsx:54-63` opens the App Store on iOS, Play on Android, and a **modal** on
desktop. So a desktop visitor is shown Apple pricing while the CTA shows them a modal — fine
today because Apple and Google prices are identical for all three plans (§10), and the
default must be revisited the moment they are not.

The response shape is fixed and already implemented (`controllers/iosPurchase.js:131-170`):

```ts
interface VipPlan {
  id: "monthly" | "quarterly" | "yearly";
  name: string;
  description: string;
  duration: number;
  durationUnit: string;
  features: string[];
  savings: string | null;      // "20%", "40%"
  recommended: boolean;
  productId: string;
  price: number;
  currency: string;
  localizedPrice: string;      // "$9.99" — render THIS, never format `price` yourself
  originalPrice?: number;
  originalLocalizedPrice?: string;
}
```

`localizedPrice` renders the price; `recommended` drives the highlighted card; `savings`
renders a banana `Badge`; `features[]` replaces the hardcoded lists. The free tier stays
hardcoded — it is not a store product and has no plan record.

**Failure behaviour.** If the request fails, the section renders the three real plans from a
constant seeded with today's true values (`$9.99` / `$23.99` / `$71.99`), flagged in a
comment as a mirror that must be updated if store pricing changes. A pricing section that
renders nothing is worse than one slightly stale — but it must never again show a number
that was never true.

---

## 5. Growth surfaces

### 5.1 Promo carousel

Full-width band directly under the nav. Slides come from `src/data/promoSlides.ts` — an
array of `{ id, icon, title, body, ctaLabel, ctaHref, tone }` — so copy changes touch data,
not components. Auto-advances every 6 seconds, pauses on hover and on focus within, exposes
manual dots, and is dismissible with dismissal remembered for 7 days.

Three slides ship: the app-does-more push, VIP, and Gatherings.

**Two tones, not three.** `tone` is `"brand"` or `"banana"` only. Teal means "here is the
product" (app push, Gatherings); banana means "here is an offer" (VIP). An earlier mockup
used a third purple gradient — `AppColors.accent`, which has no presence anywhere else on
the web — and three gradients cycling in one band reads as a slot machine rather than an
announcement. Restricting the palette also makes the tone itself carry meaning.

### 5.2 App-download popup

Governed entirely by `growthGate.ts`. It fires when **either** the visitor scrolls past the
demo hero **or** dwells 20 seconds — whichever first — and then only if every suppression
check passes:

| Rule | Reason |
|---|---|
| Not shown if dismissed within 30 days | `localStorage`, one key |
| Never when `document.referrer` is an app-store domain | They already came from the store |
| Never on `/register` or `/login` | Interrupting a conversion in progress |
| Never on viewports under 768px | The sticky banner already occupies that job |
| Never twice in one session | Independent of the 30-day rule |

`localStorage` access is wrapped — a private window that throws on read must not prevent the
page rendering.

### 5.3 Sticky mobile banner

Under 768px only: a slim bottom bar with the app icon, one line, and an install button.
Dismissible, remembered 30 days, sharing `growthGate.ts` with the popup so the two can never
both appear.

---

## 6. Content rules

### 6.1 The stat strip carries only verifiable facts

`137 languages` (the catalog count), `14 app languages` (the shipped locale set),
`24/7 AI tutor`, `Free forever tier`. Every one is checkable.

**Member count is deliberately excluded.** `COMMUNITY_COUNT_URL`
(`/api/v1/auth/users/count`) exists in `constants.ts` and is already used by the community
slice, but the route is `router.route('/count').get(protect, getUsersCount)`
(`routes/users.js:63`) — **authenticated**, so a logged-out visitor cannot call it. Exposing
it publicly is a backend change, outside this spec's web-only scope, and for an app launched
in December the number may undersell rather than persuade. Revisit when it is an asset worth
a backend change.

### 6.2 The language marquee is curated, and excludes sign languages

The marquee scrolls a **named, ordered list of 24** held in `src/data/marqueeLanguages.ts`,
not all 137: a full loop of the catalog takes minutes and buries Korean behind Zulu. The list
is the app's own priority order — the first ten of the backend's `NAME_TO_ISO`
(`utils/languageCodes.js:13-24`, explicitly "popular languages first, mirrors Flutter list
order"): English, Korean, Japanese, Chinese, Spanish, French, German, Italian, Portuguese,
Russian — followed by Arabic, Hindi, Indonesian, Vietnamese, Thai, Turkish, Polish, Dutch,
Swedish, Ukrainian, Persian, Tagalog, Bengali, Greek. Deriving it from an existing ordering
rather than inventing one keeps it defensible and easy to extend. The real total, 137, is
stated as a stat instead.

**The four sign languages in the catalog (ASL, BSL, JSL, KSL) are excluded.** This is not a
flag problem — the app's own `LanguageCodes._untaggable` set excludes them from taggable
languages because a *written* exchange in ASL is not representable. Advertising them would
promise something the product cannot do.

Flag data comes from `languageFlag()` (sub-project 1). Audited: of 137 catalog entries only
Esperanto renders 🌐 (correct — no country), Welsh and Scottish Gaelic correctly use
subdivision flags, Latin uses 🏛️.

### 6.3 Early-adopter framing replaces social proof

The band states the real launch date and invites visitors to be early, rather than borrowing
credibility the product has not yet earned. It is explicitly temporary: once reviews exist,
this band is what gets replaced by them.

---

### 6.4 Copy follows the existing i18n pattern

The page has 18 locale files and `home` already carries eight keyed subsections. New copy
uses the codebase's existing idiom — `t("home.hero.title") || "English fallback"` — and adds
keys to `src/utils/locales/eng.json` only. The other 17 locales fall back to the inline
English until translated, exactly as `HomeMain.tsx:137-190` does today. **Do not hand-write
17 translation files**; that is a separate content task, not part of this build.

---

## 7. Explicitly not in this spec

A screenshot carousel on the homepage (the demo hero already shows the product working; a
second showcase repeats the argument — it belongs on `/download`), testimonials in any form,
a member-count stat, any web payment flow, any change to `/download`, `/register` or the
pricing logic in the app, and any animation library.

---

## 8. Animation

CSS transitions and keyframes, with `IntersectionObserver` driving scroll reveals. No
animation library: Framer Motion adds roughly 50KB gzipped to the one page whose job is to
load fast for a first-time visitor.

Every animated element respects `prefers-reduced-motion: reduce` — the marquee stops, the
carousel stops auto-advancing (dots still work), reveals become instant. This is a
correctness requirement, not a nicety: a continuously scrolling marquee is a vestibular
trigger.

---

## 9. Testing

Existing setup: `react-scripts test` (Jest) with `@testing-library/react`.

- Unit, `growthGate.ts`: each suppression rule in isolation — 30-day dismissal, app-store
  referrer, excluded routes, viewport floor, once-per-session — plus both triggers, plus
  `localStorage` throwing.
- Component, `PricingSection`: renders `localizedPrice` verbatim rather than reformatting
  `price`; highlights the `recommended` plan; renders the `savings` badge only when present;
  **falls back to the three real plans when the request fails**.
- Component, `PricingSection` regression: asserts no hardcoded `$14.99` or `$49.99` survives
  anywhere in the tree — the §1.1 guard.
- Component, `LanguageMarquee`: excludes all four sign languages; every rendered chip has a
  non-globe flag.
- Component, `PromoCarousel`: advances, pauses on hover, dismissal persists, renders every
  slide in `promoSlides.ts`.
- Component, popup and banner never both render at the same viewport.
- Reduced motion: with the media query matched, the marquee carries no animation and the
  carousel does not auto-advance.

---

## 10. Risks

- **The fallback constant can drift exactly like the hardcoded table did.** It is the same
  failure mode this spec exists to fix, reintroduced at smaller scale. Mitigated by the §9
  test pinning the old wrong values out, and by a comment naming
  `controllers/iosPurchase.js` as the source of truth. A future sub-project should consider
  failing to a "see pricing in the app" link instead of numbers at all.
- **Platform inference is a guess.** A desktop visitor sees Apple pricing; if Apple and
  Google prices ever diverge, some visitors see the wrong one. Today both are identical for
  all three plans, so the guess is free — but it stops being free the moment they differ.
- **The promo carousel is unmeasured.** Nothing records whether slides are clicked or
  dismissed, so there is no way to tell a working slide from a wasted one. Analytics is out
  of scope here; the slides being data makes it cheap to add later.
- **Deleting 1076 lines of SCSS touches only the homepage in theory.** If any selector in it
  leaks to another route, that route regresses silently. The implementation should grep for
  each top-level class name before deleting the file.
