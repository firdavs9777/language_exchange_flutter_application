# Homepage Animation — Design and Plan

> **For agentic workers:** single-task plan; execute with one implementer and one task review. Steps use `- [ ]`.

**Date:** 2026-09-23
**Goal:** make the homepage feel alive — a hero demo that visibly "types", language flags drifting behind it, a slowly shifting CTA gradient — without touching what crawlers see, without hydration mismatches, and with every motion switched off under `prefers-reduced-motion`.

**Constraints inherited from the reach spec (§4.2, §8):** public pages are prerendered with `renderToString` and hydrated; no browser global may be read during render; the first client render must equal the server markup. Therefore **every animation in this plan is CSS-only** (keyframes + `animation-delay`), attached as classes present in the server HTML, prefixed `motion-safe:` so `prefers-reduced-motion: reduce` disables it, and never gated on JavaScript state. Content is always in the DOM at full opacity for a crawler (CSS animations only affect painted frames).

**Design tokens:** all keyframes and durations live in `tailwind.config.js` under `theme.extend.keyframes` / `theme.extend.animation` next to the existing `bt-rise`, `bt-float`, `bt-marquee`. No inline `@keyframes` in components; `src/components/home/anim/anim.test.tsx`'s existing rule (`grep -rn "animate-\[" src/components/home` returns nothing) stays true.

## Design

### 1. Hero demo "types" itself (`src/components/home/parts/HeroDemo.tsx`)

Timeline per page load, one 14-second CSS cycle, then it repeats:

| t (s) | what the viewer sees |
|---|---|
| 0.0–1.2 | typing indicator (three pulsing dots) inside the first bubble's position |
| 1.2 | first message text fades/rises in; dots gone |
| 1.9 | its translation line slides down under the dashed rule |
| 2.8–3.8 | typing dots in the reply bubble |
| 3.8 | reply text in; 4.5 its translation |
| 5.6 | AI tutor card rises in (banana border) |
| 5.6–12 | everything rests; the card floats (existing `bt-float`) |
| 12–14 | all three fade out together, cycle restarts |

Implementation: three new keyframes — `bt-type-dots` (dots opacity/scale pulse, and the whole indicator hidden after its window), `bt-msg-in` (message: opacity 0 → 1, translateY 6px → 0, held, then fade-out at the end of the cycle), `bt-line-in` (translation: opacity + `max-height` 0 → 2.5rem). Each element gets `motion-safe:animate-bt-msg-in` (or `-line-in` / `-type-dots`) with `style={{ animationDelay }}` for its slot; the cycle length is the keyframe's total duration (`14s`), `infinite`. The typing indicator is a `<span aria-hidden data-testid="demo-typing">` of three dots inside each bubble, absolutely positioned, `motion-reduce:hidden` (so reduced-motion users never see dots). Bubble text stays in the DOM at all times; under reduced motion the `motion-safe:` classes do nothing and the bubbles are simply visible.

The existing `motion-safe:animate-bt-rise` entrance and inline `animationDelay`s are replaced by the new cycle classes.

### 2. Drifting flags behind the hero

Inside the hero `<section>`, a `<div aria-hidden data-testid="hero-flags" className="pointer-events-none absolute inset-0 overflow-hidden">` renders eight flag emoji taken from the first eight entries of the language marquee's curated list (`src/components/home/parts/LanguageMarquee.tsx` — import the exported list; if it is not exported, export it as `MARQUEE_LANGUAGES` without changing its contents). Each flag: `absolute text-2xl sm:text-3xl opacity-[0.16] motion-safe:animate-bt-drift`, positioned by a fixed table of `left/top` percentages and given `animationDelay`/`animationDuration` from the same table (durations 18–30s) so no two move in sync. Keyframe `bt-drift`: `translateY(0) rotate(0)` → `translateY(-18px) rotate(4deg)` → back, `ease-in-out infinite`. The hero section becomes `relative`; the text column gets `relative z-10`. Dark mode: `dark:opacity-[0.12]`.

### 3. Shifting CTA gradient (`src/components/home/parts/FinalCta.tsx`)

Section background changes from `bg-brand` to `bg-[length:200%_200%] bg-gradient-to-br from-brand via-[#00ACC1] to-brand motion-safe:animate-bt-gradient`. Keyframe `bt-gradient`: `background-position` 0% 50% → 100% 50% → 0% 50%, `12s ease-in-out infinite`. Text stays white (contrast against the darkest stop `#00ACC1` with white is 2.9:1 for the 30px heading — passes AA large; the 14px subtitle is `text-white/[0.9]`, so move it to `font-semibold` and check it reads; if the contrast on the lightest stop `#00BFA5` (2.33:1) is a concern for the small line, keep the small line inside a `bg-black/10 rounded-full px-3 py-1` pill).

### 4. Card hover lift (already present)

`FeatureShowcase` cards already have `transition-transform duration-300 motion-safe:hover:-translate-y-1`. Add the same to the three pricing cards in `PricingSection.tsx` plus `hover:shadow-float`; nothing else.

### 5. Nothing else moves

No new libraries. No JS timers. `StatStrip` count-up and `LanguageMarquee` are unchanged.

## Plan

**Files:** Modify `tailwind.config.js` (keyframes + animation), `src/components/home/parts/HeroDemo.tsx`, `src/components/home/parts/FinalCta.tsx`, `src/components/home/parts/PricingSection.tsx`, `src/components/home/parts/LanguageMarquee.tsx` (export only). Tests: `src/components/home/parts/HeroDemo.test.tsx` (extend), `src/components/home/parts/staticSections.test.tsx` (extend for FinalCta), `src/components/home/anim/anim.test.tsx` (extend), `src/seo/prerender/renderRoute.test.tsx` (already asserts `/` renders; keep green).

- [ ] **Step 1: Tests first.**
  - `anim.test.tsx`: `tailwind.config.js` `theme.extend.keyframes` has `bt-type-dots`, `bt-msg-in`, `bt-line-in`, `bt-drift`, `bt-gradient`; `theme.extend.animation` has matching entries; every new animation string contains `infinite`; the existing `grep` rule (no `animate-[` in `src/components/home`) still holds.
  - `HeroDemo.test.tsx`: renders three `demo-typing` indicators with `aria-hidden`; each of the two `demo-message` bubbles and the `demo-tutor-note` still contain their text (crawler content intact); the flag layer `hero-flags` exists, is `aria-hidden`, contains 8 children, each child's className includes `motion-safe:animate-bt-drift`; every animated element's className includes `motion-safe:` and none includes `animate-` without the prefix; `renderToString(<HeroDemo/>)` output contains "안녕하세요" and no `undefined`.
  - `staticSections.test.tsx`: FinalCta section className includes `motion-safe:animate-bt-gradient`; h2 keeps `text-white`.
  - Run: `CI=true npx react-scripts test --testPathPattern='(HeroDemo|staticSections|anim)'` → FAIL on the new assertions.
- [ ] **Step 2: Tokens.** Add the five keyframes and animations to `tailwind.config.js` beside `bt-float`. Durations: `bt-type-dots 14s`, `bt-msg-in 14s`, `bt-line-in 14s`, `bt-drift` per element, `bt-gradient 12s`. Keyframe percentages for the 14s cycle: dots visible 0–8.5% (first), messages appear at 8.5% / 27% / 40% via the per-element `animationDelay` (so one keyframe set serves all three: `0% {opacity:0; transform: translateY(6px)} 3% {opacity:1; transform:none} 86% {opacity:1} 100% {opacity:0}` and each element shifts by its delay; the dots keyframe: `0% {opacity:1} 7% {opacity:1} 8.5% {opacity:0; visibility:hidden} 100% {opacity:0; visibility:hidden}`).
- [ ] **Step 3: HeroDemo.** Add the typing indicators, replace `bt-rise` with the cycle classes and delays (`0ms`, `2800ms`, `5600ms` for messages; translations `+700ms`; dots `0ms`, `2800ms`), add the flag layer and `relative` wrappers. Keep all `data-testid`s and copy.
- [ ] **Step 4: FinalCta + PricingSection** per Design §3–4.
- [ ] **Step 5: Verify.** Tests above pass; full suite `CI=true npx react-scripts test`; `GENERATE_SOURCEMAP=false npm run build`; `grep -c 'demo-typing' build/index.html` = 3; `grep -c 'hero-flags' build/index.html` = 1; then a Playwright check from the scratchpad shots directory: at 1280px on the built `/`, screenshot at t=0.5s, t=2s and t=6s and confirm visually that the first bubble shows dots then text; with `page.emulateMedia({ reducedMotion: 'reduce' })` confirm computed `animation-name` on a `demo-message` is `none` and `demo-typing` is not visible; no console errors; `documentElement.scrollWidth <= 360` at 360px (flags must not cause overflow).
- [ ] **Step 6: Commit** on branch `feat/homepage-animation`: `feat(home): the hero types itself, flags drift, the CTA gradient breathes — CSS-only, reduced-motion aware` with the trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Do not merge or push.

## Not in this plan
JavaScript-driven sequencing, scroll-linked effects, Lottie/Framer, animated nav, page transitions. Any motion that would require hiding content in the first paint.
