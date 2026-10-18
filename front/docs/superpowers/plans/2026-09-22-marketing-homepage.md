# Marketing Homepage & Growth Surfaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the homepage with a real marketing landing page that shows the product mechanic, tells the truth about prices, and converts visitors into app installs.

**Architecture:** One shared animation layer (`src/components/home/anim/` — `useInView`, `useCountUp`, `Reveal`, plus the keyframe tokens) gives every section the same reveal, stagger and easing, so the page moves as one thing rather than eight components inventing their own. `HomeMain.tsx` becomes a ~100-line orchestrator over focused parts in `src/components/home/parts/`, each built on the design tokens and primitives merged in `0dd3869`. `HomeMain.scss` (1076 lines) is deleted. Growth surfaces — promo carousel, download popup, sticky mobile banner — live in `src/components/growth/` and share one **pure** rules module, `growthGate.ts`, so the logic most likely to be wrong is unit-testable without rendering anything. Pricing stops being hardcoded and reads `GET /purchases/plans`.

**Tech Stack:** React 18.3 + TypeScript, Create React App (`react-scripts` 5.0.1), Tailwind 3.4.17 with the brand tokens from sub-project 1, RTK Query, Jest + `@testing-library/react`, `react-i18next`.

**Spec:** `docs/superpowers/specs/2026-09-22-marketing-homepage-design.md`

## Global Constraints

- **Branch:** create `feat/marketing-homepage` off `main` before Task 1. `main` is at the sub-project-1 merge (`0dd3869`); do not work directly on `main`.
- **Test command:** `CI=true npx react-scripts test --testPathPattern=<pattern>`. Without `CI=true` it hangs in watch mode.
- **Build command:** `npx react-scripts build` — **without** `CI=true`. `CI=true` promotes pre-existing ESLint warnings in unrelated files (stories, chat, moments) to errors and fails on `main` too. Those warnings are not yours to fix.
- **Do not run `npx tsc --noEmit`.** `typescript` is pinned at 3.7.2, which cannot parse several dependencies' `.d.ts` files. It exits 1 on `main` and always will.
- **Tokens only, never raw hex.** Use `bg-brand`, `text-brand-dark`, `bg-banana/[0.28]`, `rounded-card`, `shadow-card`. Never `#00BFA5`. Opacity is always an arbitrary modifier — `bg-brand/[0.09]`, never `bg-brand/9`, which Tailwind v3 silently drops.
- **Primitives available** from `src/design`: `SurfaceCard` (`children`, `padding?: "sm"|"md"|"lg"`, `interactive?`, `className?`, `onClick?`), `Badge` (`children`, `tone?: "brand"|"banana"`), `Avatar`, `LanguageExchangePill`, `FollowButton`.
- **Copy:** use `t("home.x.y") || "English fallback"`, the existing idiom. Add keys to `src/utils/locales/eng.json` **only**. Never hand-write the other 17 locale files.
- **No new dependencies.** No animation library, no carousel library, no payment SDK.
- **Every animation respects `prefers-reduced-motion: reduce`** — and respecting it means **stopping**, not slowing. Use Tailwind's `motion-safe:` prefix for keyframe animations, and the `prefersReducedMotion()` helper for anything JS-driven.
- **Content is never gated behind an animation.** Reveal wrappers animate opacity and transform only; children are always in the DOM. Mounting on intersection would hide content from crawlers, from assistive tech, and from any browser whose observer never fires.
- **Keyframes live only in `tailwind.config.js`, added once in Task 2.** Later tasks confirm they exist; they never add a second copy.
- **No testimonials, ratings, review quotes or user counts** — real or invented. The App Store listing has 0 reviews and the count endpoint is authenticated.

---

### Task 1: `growthGate.ts` — the rules, with no UI

**Files:**
- Create: `src/components/growth/growthGate.ts`
- Create: `src/components/growth/growthGate.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `type GateKey = "download-popup" | "promo-carousel" | "sticky-banner"`
  - `isSuppressed(key: GateKey, ctx: GateContext): boolean`
  - `recordDismissal(key: GateKey, now?: number): void`
  - `SUPPRESSION_DAYS: Record<GateKey, number>`
  - `interface GateContext { pathname: string; referrer: string; viewportWidth: number; now?: number }`

**Context the implementer needs:** this module is pure and has no React in it on purpose — the suppression rules are the part most likely to be wrong and the hardest to verify through a rendered component. `localStorage` throws outright in some privacy modes, so every access is wrapped; a storage failure must mean "not suppressed, show it" rather than a crash, because a thrown error here would take the whole homepage down.

- [ ] **Step 1: Write the failing test**

Create `src/components/growth/growthGate.test.ts`:

```ts
import { isSuppressed, recordDismissal, SUPPRESSION_DAYS } from "./growthGate";

const base = {
  pathname: "/",
  referrer: "https://www.google.com/",
  viewportWidth: 1280,
};

beforeEach(() => window.localStorage.clear());

it("is not suppressed for a fresh desktop visitor", () => {
  expect(isSuppressed("download-popup", base)).toBe(false);
});

it("suppresses after a dismissal, until the window expires", () => {
  const t0 = 1_000_000_000_000;
  recordDismissal("download-popup", t0);

  const dayMs = 24 * 60 * 60 * 1000;
  const withinWindow = t0 + (SUPPRESSION_DAYS["download-popup"] - 1) * dayMs;
  const afterWindow = t0 + (SUPPRESSION_DAYS["download-popup"] + 1) * dayMs;

  expect(isSuppressed("download-popup", { ...base, now: withinWindow })).toBe(true);
  expect(isSuppressed("download-popup", { ...base, now: afterWindow })).toBe(false);
});

it("keeps each key's dismissal separate", () => {
  recordDismissal("download-popup", 1_000);
  expect(isSuppressed("download-popup", { ...base, now: 1_000 })).toBe(true);
  expect(isSuppressed("promo-carousel", { ...base, now: 1_000 })).toBe(false);
});

it("suppresses the popup for visitors arriving from an app store", () => {
  expect(
    isSuppressed("download-popup", { ...base, referrer: "https://apps.apple.com/us/app/x" })
  ).toBe(true);
  expect(
    isSuppressed("download-popup", { ...base, referrer: "https://play.google.com/store/apps/x" })
  ).toBe(true);
});

it("suppresses the popup on auth routes", () => {
  expect(isSuppressed("download-popup", { ...base, pathname: "/register" })).toBe(true);
  expect(isSuppressed("download-popup", { ...base, pathname: "/login" })).toBe(true);
});

it("suppresses the popup on narrow viewports, where the sticky banner takes over", () => {
  expect(isSuppressed("download-popup", { ...base, viewportWidth: 500 })).toBe(true);
  expect(isSuppressed("sticky-banner", { ...base, viewportWidth: 500 })).toBe(false);
});

it("suppresses the sticky banner on wide viewports", () => {
  expect(isSuppressed("sticky-banner", { ...base, viewportWidth: 1280 })).toBe(true);
});

// A storage failure must not take the page down, and must fail OPEN.
it("treats unreadable storage as not suppressed", () => {
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
    throw new Error("SecurityError");
  });
  expect(() => isSuppressed("download-popup", base)).not.toThrow();
  expect(isSuppressed("download-popup", base)).toBe(false);
  spy.mockRestore();
});

it("does not throw when a dismissal cannot be written", () => {
  const spy = jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
    throw new Error("QuotaExceeded");
  });
  expect(() => recordDismissal("download-popup", 1_000)).not.toThrow();
  spy.mockRestore();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=growth/growthGate`
Expected: FAIL — `Cannot find module './growthGate'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/components/growth/growthGate.ts`:

```ts
// Trigger and suppression rules for the growth surfaces (promo carousel,
// download popup, sticky mobile banner).
//
// Deliberately pure and React-free: these rules decide whether a visitor is
// interrupted, they are the easiest thing here to get wrong, and they are
// painful to verify through a rendered component.

export type GateKey = "download-popup" | "promo-carousel" | "sticky-banner";

export interface GateContext {
  pathname: string;
  referrer: string;
  viewportWidth: number;
  /** Injected in tests; defaults to Date.now(). */
  now?: number;
}

export const SUPPRESSION_DAYS: Record<GateKey, number> = {
  "download-popup": 30,
  "promo-carousel": 7,
  "sticky-banner": 30,
};

/** Below this width the sticky banner owns the screen and the popup stands down. */
export const MOBILE_MAX_WIDTH = 768;

const APP_STORE_HOSTS = ["apps.apple.com", "play.google.com", "itunes.apple.com"];
const EXCLUDED_PATHS = ["/register", "/login"];
const DAY_MS = 24 * 60 * 60 * 1000;

const storageKey = (key: GateKey) => `bt.growth.${key}.dismissedAt`;

// Storage throws outright in some privacy modes. Every failure here means
// "we don't know", and not knowing must never crash the homepage.
function readDismissedAt(key: GateKey): number | null {
  try {
    const raw = window.localStorage.getItem(storageKey(key));
    if (!raw) return null;
    const ts = Number(raw);
    return Number.isFinite(ts) ? ts : null;
  } catch {
    return null;
  }
}

export function recordDismissal(key: GateKey, now: number = Date.now()): void {
  try {
    window.localStorage.setItem(storageKey(key), String(now));
  } catch {
    // Nothing to do — the surface simply reappears next visit.
  }
}

export function isSuppressed(key: GateKey, ctx: GateContext): boolean {
  const now = ctx.now ?? Date.now();

  if (key === "sticky-banner") {
    if (ctx.viewportWidth > MOBILE_MAX_WIDTH) return true;
  } else if (key === "download-popup") {
    if (ctx.viewportWidth <= MOBILE_MAX_WIDTH) return true;
    if (EXCLUDED_PATHS.includes(ctx.pathname)) return true;
    if (APP_STORE_HOSTS.some((host) => ctx.referrer.includes(host))) return true;
  }

  const dismissedAt = readDismissedAt(key);
  if (dismissedAt === null) return false;
  return now - dismissedAt < SUPPRESSION_DAYS[key] * DAY_MS;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=growth/growthGate`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add src/components/growth/growthGate.ts src/components/growth/growthGate.test.ts
git commit -m "feat(growth): add the pure suppression-rules module

Trigger and suppression logic for the growth surfaces, with no React in
it: these rules decide whether a visitor gets interrupted and are the
easiest thing here to get wrong. Storage failures fail open rather than
crashing the homepage."
```

---

### Task 2: The animation layer

**Files:**
- Create: `src/components/home/anim/useInView.ts`
- Create: `src/components/home/anim/useCountUp.ts`
- Create: `src/components/home/anim/Reveal.tsx`
- Create: `src/components/home/anim/anim.test.tsx`
- Modify: `tailwind.config.js` (add the keyframes block)

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `useInView<T extends HTMLElement>(options?: { once?: boolean; rootMargin?: string }): [React.RefObject<T>, boolean]`
  - `useCountUp(target: number, opts?: { durationMs?: number; start?: boolean }): number`
  - `Reveal` — props `{ children: React.ReactNode; delayMs?: number; as?: "div" | "section"; className?: string }`, `data-testid="reveal"`
  - Tailwind keyframes `bt-rise`, `bt-marquee`, `bt-float`, `bt-shimmer`

**Context the implementer needs:** this is the shared animation vocabulary every section uses, built once so the page moves as one thing rather than eight components each inventing their own easing.

Three rules govern all of it:

1. **Content never depends on animation having run.** `Reveal` renders its children into the DOM immediately and animates opacity and transform only. A scroll reveal that mounts children on intersection would hide content from search engines, from screen readers, and from anyone whose `IntersectionObserver` never fires.
2. **`prefers-reduced-motion: reduce` means stop, not slow.** `Reveal` skips its transition entirely, `useCountUp` returns the target immediately, and marquee/float animations are gated behind Tailwind's `motion-safe:`.
3. **`IntersectionObserver` may not exist.** jsdom has no implementation, so every test would otherwise crash. When it is absent, `useInView` reports `true` immediately — visible content is the safe failure.

- [ ] **Step 1: Write the failing test**

Create `src/components/home/anim/anim.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen, act } from "@testing-library/react";
import Reveal from "./Reveal";
import { useCountUp } from "./useCountUp";

const setReducedMotion = (reduce: boolean) => {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    configurable: true,
    value: (query: string) => ({
      matches: reduce && query.includes("reduce"),
      media: query,
      addEventListener: () => {},
      removeEventListener: () => {},
      addListener: () => {},
      removeListener: () => {},
      dispatchEvent: () => false,
    }),
  });
};

beforeEach(() => setReducedMotion(false));

// The rule that matters most: content is in the DOM whether or not anything animated.
it("renders children immediately, with no observer present", () => {
  render(<Reveal><p>visible content</p></Reveal>);
  expect(screen.getByText("visible content")).toBeInTheDocument();
});

it("does not hide children behind an intersection that may never fire", () => {
  render(<Reveal><p>still here</p></Reveal>);
  expect(screen.getByTestId("reveal")).toContainElement(screen.getByText("still here"));
});

it("drops the transition entirely under reduced motion", () => {
  setReducedMotion(true);
  render(<Reveal><p>x</p></Reveal>);
  expect(screen.getByTestId("reveal").className).not.toContain("duration-");
});

function CountProbe({ to }: { to: number }) {
  const n = useCountUp(to, { durationMs: 100, start: true });
  return <span data-testid="count">{n}</span>;
}

it("counts up to the target and stops there", () => {
  jest.useFakeTimers();
  render(<CountProbe to={137} />);
  act(() => { jest.advanceTimersByTime(200); });
  expect(screen.getByTestId("count")).toHaveTextContent("137");
  jest.useRealTimers();
});

it("returns the target immediately under reduced motion", () => {
  setReducedMotion(true);
  render(<CountProbe to={137} />);
  expect(screen.getByTestId("count")).toHaveTextContent("137");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=anim/anim`
Expected: FAIL — `Cannot find module './Reveal'`.

- [ ] **Step 3: Write the hooks**

Create `src/components/home/anim/useInView.ts`:

```ts
import { useEffect, useRef, useState } from "react";

/** True when the user has asked for less motion. Read at call time, not cached. */
export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  try {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  } catch {
    return false;
  }
}

/**
 * Reports whether the element has entered the viewport.
 *
 * Returns true immediately when IntersectionObserver is unavailable (jsdom,
 * older browsers) or when reduced motion is requested. Visible content is the
 * safe failure: an animation that never runs must never mean content nobody
 * can see.
 */
export function useInView<T extends HTMLElement>(
  options: { once?: boolean; rootMargin?: string } = {}
): [React.RefObject<T>, boolean] {
  const { once = true, rootMargin = "0px 0px -10% 0px" } = options;
  const ref = useRef<T>(null);
  const [inView, setInView] = useState(
    () => typeof IntersectionObserver === "undefined" || prefersReducedMotion()
  );

  useEffect(() => {
    if (inView && once) return;
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setInView(true);
            if (once) observer.disconnect();
          } else if (!once) {
            setInView(false);
          }
        });
      },
      { rootMargin, threshold: 0.12 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [inView, once, rootMargin]);

  return [ref, inView];
}
```

Create `src/components/home/anim/useCountUp.ts`:

```ts
import { useEffect, useRef, useState } from "react";
import { prefersReducedMotion } from "./useInView";

/**
 * Animates 0 -> target with an ease-out curve, for the stat strip.
 *
 * Under reduced motion it returns the target on the first render and never
 * animates — a number ticking upward is exactly the kind of motion that rule
 * exists to suppress.
 */
export function useCountUp(
  target: number,
  opts: { durationMs?: number; start?: boolean } = {}
): number {
  const { durationMs = 1200, start = true } = opts;
  const reduced = prefersReducedMotion();
  const [value, setValue] = useState(reduced ? target : 0);
  const frame = useRef<number>();

  useEffect(() => {
    if (reduced || !start) {
      setValue(target);
      return;
    }

    const began = Date.now();
    const tick = () => {
      const elapsed = Date.now() - began;
      const t = Math.min(1, elapsed / durationMs);
      // easeOutCubic — fast start, settles rather than stopping dead.
      const eased = 1 - Math.pow(1 - t, 3);
      setValue(Math.round(target * eased));
      if (t < 1) frame.current = window.requestAnimationFrame(tick);
    };

    frame.current = window.requestAnimationFrame(tick);
    return () => {
      if (frame.current) window.cancelAnimationFrame(frame.current);
    };
  }, [target, durationMs, start, reduced]);

  return value;
}
```

- [ ] **Step 4: Write the Reveal component**

Create `src/components/home/anim/Reveal.tsx`:

```tsx
import React from "react";
import { useInView, prefersReducedMotion } from "./useInView";

export interface RevealProps {
  children: React.ReactNode;
  /** Stagger, in ms, for siblings revealed together. */
  delayMs?: number;
  as?: "div" | "section";
  className?: string;
}

/**
 * Fades and lifts its children into view on scroll.
 *
 * Children are ALWAYS in the DOM — this animates opacity and transform only.
 * Mounting on intersection would hide content from crawlers, from assistive
 * tech, and from any browser whose observer never fires.
 */
const Reveal: React.FC<RevealProps> = ({
  children,
  delayMs = 0,
  as = "div",
  className = "",
}) => {
  const [ref, inView] = useInView<HTMLDivElement>();
  const reduced = prefersReducedMotion();
  const Tag = as as any;

  if (reduced) {
    return (
      <Tag ref={ref} data-testid="reveal" className={className}>
        {children}
      </Tag>
    );
  }

  return (
    <Tag
      ref={ref}
      data-testid="reveal"
      style={{ transitionDelay: `${delayMs}ms` }}
      className={`transition-all duration-700 ease-out ${
        inView ? "translate-y-0 opacity-100" : "translate-y-6 opacity-0"
      } ${className}`}
    >
      {children}
    </Tag>
  );
};

export default Reveal;
```

- [ ] **Step 5: Add every keyframe the page uses**

In `tailwind.config.js`, inside `theme.extend`, add:

```js
      keyframes: {
        "bt-rise": {
          from: { opacity: "0", transform: "translateY(10px)" },
          to: { opacity: "1", transform: "none" },
        },
        "bt-marquee": {
          from: { transform: "translateX(0)" },
          to: { transform: "translateX(-50%)" },
        },
        "bt-float": {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
        "bt-shimmer": {
          from: { backgroundPosition: "200% 0" },
          to: { backgroundPosition: "-200% 0" },
        },
      },
      animation: {
        "bt-rise": "bt-rise .5s ease-out both",
        "bt-marquee": "bt-marquee 28s linear infinite",
        "bt-float": "bt-float 4s ease-in-out infinite",
        "bt-shimmer": "bt-shimmer 3s linear infinite",
      },
```

Later tasks use these as `motion-safe:animate-bt-float` and similar, so the animation never runs for a reduced-motion visitor.

- [ ] **Step 6: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=anim/anim`
Expected: PASS, 5 tests.

- [ ] **Step 7: Commit**

```bash
git add src/components/home/anim tailwind.config.js
git commit -m "feat(home): shared animation layer

useInView, useCountUp and Reveal, built once so the page moves as one
thing rather than eight components inventing their own easing.

Three rules hold throughout: content is always in the DOM and only its
opacity and transform animate; reduced motion stops animation rather than
slowing it; and a missing IntersectionObserver reports visible, because
an animation that never runs must never mean content nobody can see."
```

---

### Task 3: `plansSlice` — real prices, and the fallback that stops the lie

**Files:**
- Create: `src/store/slices/plansSlice.ts`
- Create: `src/store/slices/plansSlice.test.ts`
- Modify: `src/constants.ts` (add one constant)

**Interfaces:**
- Consumes: the existing `apiSlice` from `src/store/slices/apiSlice.ts` (`apiSlice.injectEndpoints`).
- Produces:
  - `interface VipPlan` — exactly the shape in the spec's §4
  - `useGetVipPlansQuery(platform: "ios" | "android")`
  - `inferPlatform(userAgent: string): "ios" | "android"`
  - `FALLBACK_PLANS: VipPlan[]`

**Context the implementer needs:** the endpoint is `GET /api/v1/purchases/plans?platform=ios|android`, already implemented at `controllers/iosPurchase.js:131`. It is public — no auth header needed, though `apiSlice` will attach one if a user is logged in, which is harmless.

`FALLBACK_PLANS` mirrors `controllers/iosPurchase.js:20-120` as of today. This is the same failure mode the whole sub-project exists to fix, reintroduced smaller, and that is a deliberate trade: a pricing section that renders nothing is worse than one slightly stale. What must never happen again is a number that was **never** true — the website currently claims `$14.99` monthly against a real `$9.99`, and `$49.99` yearly against a real `$71.99`.

- [ ] **Step 1: Write the failing test**

Create `src/store/slices/plansSlice.test.ts`:

```ts
import { inferPlatform, FALLBACK_PLANS } from "./plansSlice";

it("infers the store from the user agent", () => {
  expect(inferPlatform("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)")).toBe("ios");
  expect(inferPlatform("Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X)")).toBe("ios");
  expect(inferPlatform("Mozilla/5.0 (Linux; Android 14; Pixel 8)")).toBe("android");
});

// Desktop has no store of its own; the CTA opens a modal. iOS pricing is the
// default only because Apple and Google prices are identical today.
it("defaults to ios on desktop", () => {
  expect(inferPlatform("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)")).toBe("ios");
  expect(inferPlatform("")).toBe("ios");
});

it("ships fallback prices that match the stores, not the old website copy", () => {
  const byId = Object.fromEntries(FALLBACK_PLANS.map((p) => [p.id, p]));
  expect(byId.monthly.localizedPrice).toBe("$9.99");
  expect(byId.quarterly.localizedPrice).toBe("$23.99");
  expect(byId.yearly.localizedPrice).toBe("$71.99");
});

// The regression guard. These two numbers were on the live site and were
// never what the stores charged.
it("never reintroduces the wrong prices", () => {
  const prices = FALLBACK_PLANS.map((p) => p.localizedPrice);
  expect(prices).not.toContain("$14.99");
  expect(prices).not.toContain("$49.99");
});

it("offers all three real plans, including the quarterly the site omitted", () => {
  expect(FALLBACK_PLANS.map((p) => p.id).sort()).toEqual(["monthly", "quarterly", "yearly"]);
});

it("marks exactly one plan recommended", () => {
  expect(FALLBACK_PLANS.filter((p) => p.recommended)).toHaveLength(1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=slices/plansSlice`
Expected: FAIL — `Cannot find module './plansSlice'`.

- [ ] **Step 3: Add the endpoint constant**

In `src/constants.ts`, add after the `VIP_URL` line:

```ts
// Public: displays real store prices before login. See
// language_exchange_backend_application routes/purchases.js:37.
export const VIP_PLANS_URL = "/api/v1/purchases/plans";
```

- [ ] **Step 4: Write minimal implementation**

Create `src/store/slices/plansSlice.ts`:

```ts
import { apiSlice } from "./apiSlice";
import { VIP_PLANS_URL } from "../../constants";

/** Shape returned by GET /purchases/plans — controllers/iosPurchase.js:131. */
export interface VipPlan {
  id: "monthly" | "quarterly" | "yearly";
  name: string;
  description: string;
  duration: number;
  durationUnit: string;
  features: string[];
  savings: string | null;
  recommended: boolean;
  productId: string;
  price: number;
  currency: string;
  /** Render THIS. Never format `price` yourself — the store owns the formatting. */
  localizedPrice: string;
  originalPrice?: number;
  originalLocalizedPrice?: string;
}

/**
 * Which store's prices to show. Desktop has no store of its own — the desktop
 * VIP CTA opens a modal — so it defaults to iOS. That default is free only
 * while Apple and Google prices are identical, which they are today.
 */
export function inferPlatform(userAgent: string): "ios" | "android" {
  if (/Android/i.test(userAgent)) return "android";
  return "ios";
}

/**
 * Used only when the request fails. Mirrors controllers/iosPurchase.js:20-120.
 *
 * Yes, this is hardcoded pricing — the thing this sub-project exists to remove.
 * The trade is deliberate: a pricing section that renders nothing is worse than
 * one slightly stale. What must never return is a price that was never true.
 * If store pricing changes, update this and the test that pins it.
 */
export const FALLBACK_PLANS: VipPlan[] = [
  {
    id: "monthly", name: "Monthly VIP", description: "Full VIP access for 1 month",
    duration: 1, durationUnit: "month", savings: null, recommended: false,
    productId: "", price: 9.99, currency: "USD", localizedPrice: "$9.99",
    features: [
      "Unlimited daily messages", "See who visited your profile",
      "Unlimited profile views", "Priority in nearby users", "Ad-free experience",
    ],
  },
  {
    id: "quarterly", name: "Quarterly VIP", description: "Full VIP access for 3 months",
    duration: 3, durationUnit: "month", savings: "20%", recommended: true,
    productId: "", price: 23.99, currency: "USD", localizedPrice: "$23.99",
    features: [
      "Unlimited daily messages", "See who visited your profile",
      "Unlimited profile views", "Priority in nearby users", "Ad-free experience",
    ],
  },
  {
    id: "yearly", name: "Yearly VIP", description: "Full VIP access for 12 months",
    duration: 12, durationUnit: "month", savings: "40%", recommended: false,
    productId: "", price: 71.99, currency: "USD", localizedPrice: "$71.99",
    features: [
      "Unlimited daily messages", "See who visited your profile",
      "Unlimited profile views", "Priority in nearby users", "Ad-free experience",
    ],
  },
];

export const plansApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getVipPlans: builder.query<VipPlan[], "ios" | "android">({
      query: (platform) => ({ url: `${VIP_PLANS_URL}?platform=${platform}` }),
      transformResponse: (response: any) =>
        Array.isArray(response?.plans) ? response.plans
          : Array.isArray(response?.data) ? response.data
          : Array.isArray(response) ? response
          : [],
      keepUnusedDataFor: 300,
    }),
  }),
});

export const { useGetVipPlansQuery } = plansApiSlice;
```

- [ ] **Step 5: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=slices/plansSlice`
Expected: PASS, 6 tests.

- [ ] **Step 6: Verify the real response shape**

Run, with the backend running locally:

```bash
curl -s "http://localhost:5003/api/v1/purchases/plans?platform=ios" | head -c 400
```

Confirm whether the array sits at the top level, under `plans`, or under `data`, and note which in your report. `transformResponse` handles all three, but the report should record which one is real so a later task can simplify it.

- [ ] **Step 7: Commit**

```bash
git add src/store/slices/plansSlice.ts src/store/slices/plansSlice.test.ts src/constants.ts
git commit -m "feat(store): read real VIP plans instead of hardcoding prices

The site advertises \$14.99 monthly against a real \$9.99, and \$49.99
yearly against a real \$71.99 -- understated by \$22, so a visitor decides
on one price and meets another at checkout. The quarterly plan is absent
entirely. GET /purchases/plans has existed all along and was never called.

A test pins the two wrong numbers out of the fallback constant."
```

---

### Task 4: `PricingSection` — the part that stops lying

**Files:**
- Create: `src/components/home/parts/PricingSection.tsx`
- Create: `src/components/home/parts/PricingSection.test.tsx`

**Interfaces:**
- Consumes: `useGetVipPlansQuery`, `inferPlatform`, `FALLBACK_PLANS`, `VipPlan` from Task 3; `SurfaceCard` and `Badge` from `src/design`.
- Produces: `default export PricingSection`; `data-testid`s `pricing-section`, `plan-card` (one per plan), `plan-price`, `plan-savings`, `plan-recommended`.

**Context the implementer needs:** render `localizedPrice` verbatim. Do **not** format `price` — the store owns currency formatting, and reformatting is how `$9.99` becomes `$9.99 USD` or `9,99 $` inconsistently across locales. The free tier is not a store product and stays hardcoded alongside the fetched plans.

- [ ] **Step 1: Write the failing test**

Create `src/components/home/parts/PricingSection.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import PricingSection from "./PricingSection";
import { FALLBACK_PLANS } from "../../../store/slices/plansSlice";

const mockQuery = jest.fn();
jest.mock("../../../store/slices/plansSlice", () => ({
  ...jest.requireActual("../../../store/slices/plansSlice"),
  useGetVipPlansQuery: (...args: any[]) => mockQuery(...args),
}));

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "" }),
}));

beforeEach(() => mockQuery.mockReset());

it("renders the store's own price string, unmodified", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  const prices = screen.getAllByTestId("plan-price").map((n) => n.textContent);
  expect(prices).toEqual(expect.arrayContaining(["$9.99", "$23.99", "$71.99"]));
});

it("never shows the prices the old site invented", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  const { container } = render(<PricingSection />);
  expect(container.textContent).not.toContain("$14.99");
  expect(container.textContent).not.toContain("$49.99");
});

it("falls back to real plans when the request fails", () => {
  mockQuery.mockReturnValue({ data: undefined, isError: true, isLoading: false });
  render(<PricingSection />);
  expect(screen.getAllByTestId("plan-card").length).toBeGreaterThanOrEqual(3);
  expect(screen.getAllByTestId("plan-price").map((n) => n.textContent))
    .toEqual(expect.arrayContaining(["$9.99"]));
});

it("shows a savings badge only on plans that have one", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  // monthly has savings: null; quarterly 20%, yearly 40%
  expect(screen.getAllByTestId("plan-savings")).toHaveLength(2);
});

it("highlights the recommended plan", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  expect(screen.getAllByTestId("plan-recommended")).toHaveLength(1);
});

it("renders the free tier alongside the paid plans", () => {
  mockQuery.mockReturnValue({ data: FALLBACK_PLANS, isError: false, isLoading: false });
  render(<PricingSection />);
  expect(screen.getAllByTestId("plan-card")).toHaveLength(4);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=parts/PricingSection`
Expected: FAIL — `Cannot find module './PricingSection'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/components/home/parts/PricingSection.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { Check } from "lucide-react";
import { SurfaceCard, Badge } from "../../../design";
import {
  useGetVipPlansQuery,
  inferPlatform,
  FALLBACK_PLANS,
  VipPlan,
} from "../../../store/slices/plansSlice";

const APP_STORE_URL =
  "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bananatalk.app";

const PricingSection: React.FC = () => {
  const { t } = useTranslation();
  const platform = inferPlatform(
    typeof navigator === "undefined" ? "" : navigator.userAgent
  );
  const { data, isError } = useGetVipPlansQuery(platform);

  // A pricing section that renders nothing is worse than one slightly stale.
  const plans: VipPlan[] = isError || !data || data.length === 0 ? FALLBACK_PLANS : data;
  const storeUrl = platform === "android" ? PLAY_STORE_URL : APP_STORE_URL;

  return (
    <section data-testid="pricing-section" className="px-4 py-16 bg-canvas dark:bg-canvas-dark">
      <div className="mx-auto max-w-5xl">
        <h2 className="text-center text-3xl font-extrabold tracking-tight text-gray-900 dark:text-gray-50">
          {t("home.pricing.title") || "Simple pricing"}
        </h2>
        <p className="mt-2 text-center text-sm text-gray-500 dark:text-gray-400">
          {t("home.pricing.subtitle") || "Start free. Upgrade in the app whenever you want."}
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {/* Free is not a store product and has no plan record. */}
          <SurfaceCard padding="lg" className="flex flex-col">
            <div data-testid="plan-card" className="flex h-full flex-col">
              <h3 className="text-sm font-bold text-gray-900 dark:text-gray-50">
                {t("home.pricing.free.name") || "Free"}
              </h3>
              <p data-testid="plan-price" className="mt-2 text-3xl font-extrabold text-gray-900 dark:text-gray-50">
                $0
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {t("home.pricing.free.period") || "forever"}
              </p>
              <ul className="mt-4 flex-1 space-y-2">
                {[
                  t("home.pricing.free.f1") || "Unlimited 1-on-1 chat with translation",
                  t("home.pricing.free.f2") || "Browse and connect with the community",
                  t("home.pricing.free.f3") || "Post Moments and read Stories",
                ].map((f) => (
                  <li key={f} className="flex gap-2 text-xs text-gray-600 dark:text-gray-300">
                    <Check className="mt-0.5 h-3.5 w-3.5 shrink-0 text-brand" aria-hidden />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href="/register"
                className="mt-5 rounded-full border-2 border-brand px-4 py-2 text-center text-xs font-bold text-brand-dark dark:text-brand-light"
              >
                {t("home.pricing.free.cta") || "Create a free account"}
              </a>
            </div>
          </SurfaceCard>

          {plans.map((plan) => (
            <SurfaceCard
              key={plan.id}
              padding="lg"
              className={plan.recommended ? "ring-2 ring-brand" : undefined}
            >
              <div data-testid="plan-card" className="flex h-full flex-col">
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-bold text-gray-900 dark:text-gray-50">{plan.name}</h3>
                  {plan.recommended && (
                    <span data-testid="plan-recommended">
                      <Badge tone="brand">{t("home.pricing.best") || "Best value"}</Badge>
                    </span>
                  )}
                </div>

                {/* localizedPrice verbatim: the store owns currency formatting. */}
                <p data-testid="plan-price" className="mt-2 text-3xl font-extrabold text-gray-900 dark:text-gray-50">
                  {plan.localizedPrice}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {plan.duration === 1
                    ? t("home.pricing.perMonth") || "per month"
                    : `${t("home.pricing.every") || "every"} ${plan.duration} ${plan.durationUnit}s`}
                </p>

                {plan.savings && (
                  <span data-testid="plan-savings" className="mt-2 self-start">
                    <Badge tone="banana">
                      {t("home.pricing.save") || "Save"} {plan.savings}
                    </Badge>
                  </span>
                )}

                <ul className="mt-4 flex-1 space-y-2">
                  {plan.features.slice(0, 5).map((f) => (
                    <li key={f} className="flex gap-2 text-xs text-gray-600 dark:text-gray-300">
                      <Check className="mt-0.5 h-3.5 w-3.5 shrink-0 text-brand" aria-hidden />
                      <span>{f}</span>
                    </li>
                  ))}
                </ul>

                <a
                  href={storeUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-5 rounded-full bg-brand px-4 py-2 text-center text-xs font-bold text-white shadow-brand"
                >
                  {t("home.pricing.getVip") || "Get VIP in the app"}
                </a>
              </div>
            </SurfaceCard>
          ))}
        </div>
      </div>
    </section>
  );
};

export default PricingSection;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=parts/PricingSection`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add src/components/home/parts/PricingSection.tsx src/components/home/parts/PricingSection.test.tsx
git commit -m "feat(home): pricing section driven by real store prices

Renders localizedPrice verbatim rather than formatting price, falls back
to the real three plans when the request fails, and is pinned by a test
asserting the old invented \$14.99 and \$49.99 can never return."
```

---

### Task 5: `PromoCarousel`

**Files:**
- Create: `src/data/promoSlides.ts`
- Create: `src/components/growth/PromoCarousel.tsx`
- Create: `src/components/growth/PromoCarousel.test.tsx`

**Interfaces:**
- Consumes: `isSuppressed`, `recordDismissal` from Task 1; `Reveal` from Task 2.
- Produces:
  - `interface PromoSlide { id: string; icon: string; title: string; body: string; ctaLabel: string; ctaHref: string; tone: "brand" | "banana" }`
  - `PROMO_SLIDES: PromoSlide[]`
  - `default export PromoCarousel`
  - `data-testid`s: `promo-carousel`, `promo-slide`, `promo-dot`, `promo-dismiss`

**Context the implementer needs:** `tone` is `"brand"` or `"banana"` **only** — two tones, deliberately. Teal means "here is the product", banana means "here is an offer". A third accent colour cycling in the same band reads as a slot machine and makes the tone meaningless.

Auto-advance must pause on hover and on keyboard focus within the band, or a keyboard user can never reach a CTA before it rotates away.

- [ ] **Step 1: Write the failing test**

Create `src/components/growth/PromoCarousel.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen, act, fireEvent } from "@testing-library/react";
import PromoCarousel from "./PromoCarousel";
import { PROMO_SLIDES } from "../../data/promoSlides";

beforeEach(() => {
  window.localStorage.clear();
  jest.useFakeTimers();
});
afterEach(() => jest.useRealTimers());

it("renders the first slide and a dot per slide", () => {
  render(<PromoCarousel />);
  expect(screen.getByTestId("promo-slide")).toHaveTextContent(PROMO_SLIDES[0].title);
  expect(screen.getAllByTestId("promo-dot")).toHaveLength(PROMO_SLIDES.length);
});

it("advances on its own", () => {
  render(<PromoCarousel />);
  act(() => { jest.advanceTimersByTime(6000); });
  expect(screen.getByTestId("promo-slide")).toHaveTextContent(PROMO_SLIDES[1].title);
});

it("pauses while hovered", () => {
  render(<PromoCarousel />);
  fireEvent.mouseEnter(screen.getByTestId("promo-carousel"));
  act(() => { jest.advanceTimersByTime(12000); });
  expect(screen.getByTestId("promo-slide")).toHaveTextContent(PROMO_SLIDES[0].title);
});

it("jumps to a slide when its dot is clicked", () => {
  render(<PromoCarousel />);
  fireEvent.click(screen.getAllByTestId("promo-dot")[2]);
  expect(screen.getByTestId("promo-slide")).toHaveTextContent(PROMO_SLIDES[2].title);
});

it("disappears when dismissed, and stays gone on remount", () => {
  const { unmount } = render(<PromoCarousel />);
  fireEvent.click(screen.getByTestId("promo-dismiss"));
  expect(screen.queryByTestId("promo-carousel")).not.toBeInTheDocument();
  unmount();
  render(<PromoCarousel />);
  expect(screen.queryByTestId("promo-carousel")).not.toBeInTheDocument();
});

it("uses only the two sanctioned tones", () => {
  PROMO_SLIDES.forEach((s) => expect(["brand", "banana"]).toContain(s.tone));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=growth/PromoCarousel`
Expected: FAIL — `Cannot find module './PromoCarousel'`.

- [ ] **Step 3: Write the slide data**

Create `src/data/promoSlides.ts`:

```ts
// Carousel copy lives here, not in the component, so changing a slide is a
// data edit. `tone` is deliberately limited to two values: teal means "here is
// the product", banana means "here is an offer".
export interface PromoSlide {
  id: string;
  icon: string;
  title: string;
  body: string;
  ctaLabel: string;
  ctaHref: string;
  tone: "brand" | "banana";
}

export const PROMO_SLIDES: PromoSlide[] = [
  {
    id: "app-does-more",
    icon: "📱",
    title: "The app does more than the web",
    body: "AI tutor, voice rooms and reels are mobile only",
    ctaLabel: "Get the app",
    ctaHref: "/download",
    tone: "brand",
  },
  {
    id: "vip",
    icon: "🍌",
    title: "VIP from $9.99 a month",
    body: "Unlimited messages, no ads, see who visited you",
    ctaLabel: "See plans",
    ctaHref: "#pricing",
    tone: "banana",
  },
  {
    id: "gatherings",
    icon: "✨",
    title: "New: Gatherings",
    body: "Find a language meetup near you",
    ctaLabel: "Explore",
    ctaHref: "/download",
    tone: "brand",
  },
];
```

- [ ] **Step 4: Write the component**

Create `src/components/growth/PromoCarousel.tsx`:

```tsx
import React, { useCallback, useEffect, useState } from "react";
import { X } from "lucide-react";
import { PROMO_SLIDES } from "../../data/promoSlides";
import { isSuppressed, recordDismissal } from "./growthGate";

const ROTATE_MS = 6000;

const TONE: Record<"brand" | "banana", string> = {
  brand: "bg-gradient-to-r from-brand to-[#00ACC1] text-white",
  banana: "bg-gradient-to-r from-banana to-[#FFB300] text-gray-900",
};

const PromoCarousel: React.FC = () => {
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [dismissed, setDismissed] = useState(() =>
    isSuppressed("promo-carousel", {
      pathname: window.location.pathname,
      referrer: document.referrer,
      viewportWidth: window.innerWidth,
    })
  );

  useEffect(() => {
    if (paused || dismissed) return;
    const id = window.setInterval(
      () => setIndex((i) => (i + 1) % PROMO_SLIDES.length),
      ROTATE_MS
    );
    return () => window.clearInterval(id);
  }, [paused, dismissed]);

  const dismiss = useCallback(() => {
    recordDismissal("promo-carousel");
    setDismissed(true);
  }, []);

  if (dismissed) return null;

  const slide = PROMO_SLIDES[index];

  return (
    <div
      data-testid="promo-carousel"
      className={`relative ${TONE[slide.tone]}`}
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={() => setPaused(false)}
    >
      <div
        data-testid="promo-slide"
        className="mx-auto flex max-w-5xl items-center gap-3 px-4 py-3"
      >
        <span aria-hidden className="text-xl">{slide.icon}</span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-extrabold">{slide.title}</p>
          <p className="truncate text-xs opacity-90">{slide.body}</p>
        </div>
        <a
          href={slide.ctaHref}
          className="shrink-0 rounded-full bg-white px-3 py-1.5 text-xs font-extrabold text-brand-dark"
        >
          {slide.ctaLabel}
        </a>
        <button
          type="button"
          data-testid="promo-dismiss"
          onClick={dismiss}
          aria-label="Dismiss announcement"
          className="shrink-0 rounded-full p-1 opacity-70 hover:opacity-100"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      <div className="absolute bottom-1 left-1/2 flex -translate-x-1/2 gap-1">
        {PROMO_SLIDES.map((s, i) => (
          <button
            key={s.id}
            type="button"
            data-testid="promo-dot"
            onClick={() => setIndex(i)}
            aria-label={`Show announcement ${i + 1}`}
            className={`h-1 w-4 rounded-sm ${i === index ? "bg-white" : "bg-white/45"}`}
          />
        ))}
      </div>
    </div>
  );
};

export default PromoCarousel;
```

- [ ] **Step 5: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=growth/PromoCarousel`
Expected: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/data/promoSlides.ts src/components/growth/PromoCarousel.tsx src/components/growth/PromoCarousel.test.tsx
git commit -m "feat(growth): add the promo announcement carousel

Copy lives in src/data/promoSlides.ts so a slide change is a data edit.
Two tones only -- teal for product, banana for offers -- because three
cycling gradients read as a slot machine. Pauses on hover and on focus
so a keyboard user can reach a CTA before it rotates away."
```

---

### Task 6: `AppDownloadPopup` and `StickyAppBanner`

**Files:**
- Create: `src/components/growth/AppDownloadPopup.tsx`
- Create: `src/components/growth/StickyAppBanner.tsx`
- Create: `src/components/growth/growthSurfaces.test.tsx`

**Interfaces:**
- Consumes: `isSuppressed`, `recordDismissal`, `MOBILE_MAX_WIDTH` from Task 1.
- Produces: `default export AppDownloadPopup`, `default export StickyAppBanner`; `data-testid`s `download-popup`, `download-popup-dismiss`, `sticky-app-banner`, `sticky-banner-dismiss`.

**Context the implementer needs:** the popup fires on **either** trigger — scrolled past 600px, or 20 seconds of dwell — whichever comes first, and only when `isSuppressed` returns false. The two surfaces must never appear together; `growthGate`'s viewport rules already guarantee that (popup suppressed at or below 768px, banner suppressed above it), and the test below proves it rather than trusting it.

- [ ] **Step 1: Write the failing test**

Create `src/components/growth/growthSurfaces.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen, act, fireEvent } from "@testing-library/react";
import AppDownloadPopup from "./AppDownloadPopup";
import StickyAppBanner from "./StickyAppBanner";

const setViewport = (w: number) => {
  Object.defineProperty(window, "innerWidth", { writable: true, configurable: true, value: w });
};

beforeEach(() => {
  window.localStorage.clear();
  jest.useFakeTimers();
  setViewport(1280);
  Object.defineProperty(document, "referrer", { writable: true, configurable: true, value: "" });
});
afterEach(() => jest.useRealTimers());

it("stays hidden before either trigger fires", () => {
  render(<AppDownloadPopup />);
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

it("appears after the dwell timer", () => {
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();
});

it("appears once the visitor scrolls past the hero", () => {
  render(<AppDownloadPopup />);
  Object.defineProperty(window, "scrollY", { writable: true, configurable: true, value: 900 });
  act(() => { fireEvent.scroll(window); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();
});

it("never appears for a visitor who came from an app store", () => {
  Object.defineProperty(document, "referrer", {
    writable: true, configurable: true,
    value: "https://apps.apple.com/us/app/bananatalk/id6755862146",
  });
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

it("stays gone after being dismissed", () => {
  const { unmount } = render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  fireEvent.click(screen.getByTestId("download-popup-dismiss"));
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
  unmount();
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

// The rule that keeps the two surfaces from stacking on one screen.
it("shows exactly one surface at any viewport", () => {
  setViewport(1280);
  const wide = render(<><AppDownloadPopup /><StickyAppBanner /></>);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();
  expect(screen.queryByTestId("sticky-app-banner")).not.toBeInTheDocument();
  wide.unmount();

  window.localStorage.clear();
  setViewport(390);
  render(<><AppDownloadPopup /><StickyAppBanner /></>);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
  expect(screen.getByTestId("sticky-app-banner")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=growth/growthSurfaces`
Expected: FAIL — `Cannot find module './AppDownloadPopup'`.

- [ ] **Step 3: Write the popup**

Create `src/components/growth/AppDownloadPopup.tsx`:

```tsx
import React, { useCallback, useEffect, useState } from "react";
import { X } from "lucide-react";
import { isSuppressed, recordDismissal } from "./growthGate";

const APP_STORE_URL =
  "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bananatalk.app";

const DWELL_MS = 20000;
const SCROLL_TRIGGER_PX = 600;

const AppDownloadPopup: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (done) return;

    const gated = () =>
      isSuppressed("download-popup", {
        pathname: window.location.pathname,
        referrer: document.referrer,
        viewportWidth: window.innerWidth,
      });

    if (gated()) return;

    const fire = () => {
      if (!gated()) setOpen(true);
    };

    const timer = window.setTimeout(fire, DWELL_MS);
    const onScroll = () => {
      if (window.scrollY > SCROLL_TRIGGER_PX) fire();
    };
    window.addEventListener("scroll", onScroll, { passive: true });

    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("scroll", onScroll);
    };
  }, [done]);

  const dismiss = useCallback(() => {
    recordDismissal("download-popup");
    setOpen(false);
    setDone(true);
  }, []);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center">
      <div
        data-testid="download-popup"
        role="dialog"
        aria-modal="true"
        aria-labelledby="download-popup-title"
        className="relative w-full max-w-sm rounded-card bg-surface p-6 shadow-float dark:bg-cardbg-dark"
      >
        <button
          type="button"
          data-testid="download-popup-dismiss"
          onClick={dismiss}
          aria-label="Close"
          className="absolute right-3 top-3 rounded-full p-1 text-gray-400 hover:text-gray-600"
        >
          <X className="h-4 w-4" />
        </button>

        <p className="text-3xl" aria-hidden>🍌</p>
        <h2
          id="download-popup-title"
          className="mt-2 text-lg font-extrabold text-gray-900 dark:text-gray-50"
        >
          Keep the conversation going
        </h2>
        <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
          The AI tutor, voice rooms and reels only live in the app. It's free to start.
        </p>

        <div className="mt-5 flex gap-2">
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="flex-1 rounded-full bg-brand px-4 py-2 text-center text-xs font-extrabold text-white shadow-brand"
          >
            App Store
          </a>
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="flex-1 rounded-full bg-brand px-4 py-2 text-center text-xs font-extrabold text-white shadow-brand"
          >
            Google Play
          </a>
        </div>
      </div>
    </div>
  );
};

export default AppDownloadPopup;
```

- [ ] **Step 4: Write the sticky banner**

Create `src/components/growth/StickyAppBanner.tsx`:

```tsx
import React, { useCallback, useState } from "react";
import { X } from "lucide-react";
import { isSuppressed, recordDismissal } from "./growthGate";

const STORE_URL = /Android/i.test(
  typeof navigator === "undefined" ? "" : navigator.userAgent
)
  ? "https://play.google.com/store/apps/details?id=com.bananatalk.app"
  : "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";

const StickyAppBanner: React.FC = () => {
  const [hidden, setHidden] = useState(() =>
    isSuppressed("sticky-banner", {
      pathname: window.location.pathname,
      referrer: document.referrer,
      viewportWidth: window.innerWidth,
    })
  );

  const dismiss = useCallback(() => {
    recordDismissal("sticky-banner");
    setHidden(true);
  }, []);

  if (hidden) return null;

  return (
    <div
      data-testid="sticky-app-banner"
      className="fixed inset-x-0 bottom-0 z-40 flex items-center gap-3 border-t border-gray-200 bg-surface px-4 py-2.5 shadow-float dark:border-gray-700 dark:bg-cardbg-dark"
    >
      <span aria-hidden className="text-2xl">🍌</span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-bold text-gray-900 dark:text-gray-50">
          BanaTalk is better in the app
        </p>
        <p className="truncate text-[11px] text-gray-500 dark:text-gray-400">
          AI tutor, voice rooms, reels
        </p>
      </div>
      <a
        href={STORE_URL}
        target="_blank"
        rel="noopener noreferrer"
        className="shrink-0 rounded-full bg-brand px-4 py-1.5 text-xs font-extrabold text-white"
      >
        Install
      </a>
      <button
        type="button"
        data-testid="sticky-banner-dismiss"
        onClick={dismiss}
        aria-label="Dismiss"
        className="shrink-0 rounded-full p-1 text-gray-400"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
};

export default StickyAppBanner;
```

- [ ] **Step 5: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=growth/growthSurfaces`
Expected: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/components/growth/AppDownloadPopup.tsx src/components/growth/StickyAppBanner.tsx src/components/growth/growthSurfaces.test.tsx
git commit -m "feat(growth): earned download popup and mobile sticky banner

The popup fires on scroll-past-hero or 20s dwell, never for a visitor who
arrived from an app store, and never on the viewports the sticky banner
owns. A test asserts exactly one of the two renders at any width."
```

---

### Task 7: `LanguageMarquee`

**Files:**
- Create: `src/data/marqueeLanguages.ts`
- Create: `src/components/home/parts/LanguageMarquee.tsx`
- Create: `src/components/home/parts/LanguageMarquee.test.tsx`

**Interfaces:**
- Consumes: `languageFlag`, `displayCode` from `src/utils/languages` (sub-project 1).
- Produces: `MARQUEE_LANGUAGES: string[]`, `default export LanguageMarquee`; `data-testid`s `language-marquee`, `marquee-chip`.

**Context the implementer needs:** the list is 24 names in the backend's own "popular languages first" order, **not** all 137 — a full loop of the catalog takes minutes and buries Korean behind Zulu. The four sign languages are excluded on purpose: the app's own `LanguageCodes._untaggable` set cannot represent a written exchange in them, so advertising them would promise something the product cannot do.

The marquee animates continuously, which is a vestibular trigger, so `prefers-reduced-motion` must stop it — not slow it.

- [ ] **Step 1: Write the failing test**

Create `src/components/home/parts/LanguageMarquee.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import LanguageMarquee from "./LanguageMarquee";
import { MARQUEE_LANGUAGES } from "../../../data/marqueeLanguages";

it("renders a chip per language, duplicated for a seamless loop", () => {
  render(<LanguageMarquee />);
  expect(screen.getAllByTestId("marquee-chip")).toHaveLength(MARQUEE_LANGUAGES.length * 2);
});

it("gives every chip a real flag, never the globe", () => {
  render(<LanguageMarquee />);
  screen.getAllByTestId("marquee-chip").forEach((chip) => {
    expect(chip.textContent).not.toContain("🌐");
  });
});

// The app's own _untaggable set cannot represent a written exchange in these,
// so advertising them would promise something the product cannot do.
it("excludes sign languages", () => {
  const lower = MARQUEE_LANGUAGES.map((l) => l.toLowerCase());
  expect(lower.some((l) => l.includes("sign language"))).toBe(false);
});

it("is a curated list, not the whole catalog", () => {
  expect(MARQUEE_LANGUAGES).toHaveLength(24);
});

it("leads with the languages the backend calls popular", () => {
  expect(MARQUEE_LANGUAGES.slice(0, 4)).toEqual(["English", "Korean", "Japanese", "Chinese"]);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=parts/LanguageMarquee`
Expected: FAIL — `Cannot find module './LanguageMarquee'`.

- [ ] **Step 3: Write the language list**

Create `src/data/marqueeLanguages.ts`:

```ts
// The marquee scrolls 24 languages, not all 137: a full catalog loop takes
// minutes and buries Korean behind Zulu. The real total is stated as a stat.
//
// Order is the backend's own, from utils/languageCodes.js NAME_TO_ISO, whose
// comment reads "Popular languages first (mirrors Flutter list order)".
// Deriving it from an existing ordering keeps it defensible.
//
// The four sign languages in the catalog are deliberately absent: the app's
// LanguageCodes._untaggable set cannot represent a written exchange in them.
export const MARQUEE_LANGUAGES: string[] = [
  "English", "Korean", "Japanese", "Chinese", "Spanish", "French",
  "German", "Italian", "Portuguese", "Russian", "Arabic", "Hindi",
  "Indonesian", "Vietnamese", "Thai", "Turkish", "Polish", "Dutch",
  "Swedish", "Ukrainian", "Persian", "Tagalog", "Bengali", "Greek",
];
```

- [ ] **Step 4: Write the component**

Create `src/components/home/parts/LanguageMarquee.tsx`:

```tsx
import React from "react";
import { languageFlag, displayCode } from "../../../utils/languages";
import { MARQUEE_LANGUAGES } from "../../../data/marqueeLanguages";

const LanguageMarquee: React.FC = () => {
  // Rendered twice so the -50% translate loops seamlessly.
  const loop = [...MARQUEE_LANGUAGES, ...MARQUEE_LANGUAGES];

  return (
    <section
      data-testid="language-marquee"
      className="overflow-hidden py-10 [mask-image:linear-gradient(90deg,transparent,#000_12%,#000_88%,transparent)]"
    >
      <p className="mb-5 text-center text-xs font-bold uppercase tracking-widest text-gray-400">
        137 languages, and counting
      </p>
      <div className="flex w-max gap-2 motion-safe:animate-bt-marquee hover:[animation-play-state:paused]">
        {loop.map((name, i) => (
          <span
            key={`${name}-${i}`}
            data-testid="marquee-chip"
            className="inline-flex items-center gap-2 whitespace-nowrap rounded-full border border-gray-200 bg-surface px-3.5 py-2 text-xs font-bold text-gray-900 shadow-card dark:border-gray-700 dark:bg-cardbg-dark dark:text-gray-50"
          >
            <span aria-hidden className="text-sm">{languageFlag(name)}</span>
            {name}
            <b className="rounded-full bg-brand/[0.09] px-1.5 py-0.5 text-[9px] font-extrabold text-brand-dark dark:text-brand-light">
              {displayCode(name)}
            </b>
          </span>
        ))}
      </div>
    </section>
  );
};

export default LanguageMarquee;
```

- [ ] **Step 5: Confirm the keyframes exist**

`bt-marquee` was added to `tailwind.config.js` in Task 2. Confirm:

```bash
grep -n "bt-marquee" tailwind.config.js
```

Expected: two hits — one under `keyframes`, one under `animation`. If either is missing, Task 2 was not completed; stop and report rather than adding a second copy.

`motion-safe:` in the component means Tailwind applies the animation only when `prefers-reduced-motion` is *not* `reduce`, so a reduced-motion visitor gets a static row. Required, not cosmetic: a continuously scrolling strip is a vestibular trigger.

- [ ] **Step 6: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=parts/LanguageMarquee`
Expected: PASS, 5 tests.

- [ ] **Step 7: Commit**

```bash
git add src/data/marqueeLanguages.ts src/components/home/parts/LanguageMarquee.tsx src/components/home/parts/LanguageMarquee.test.tsx tailwind.config.js
git commit -m "feat(home): add the language marquee

24 languages in the backend's own popularity order, not all 137. Sign
languages are excluded because the app's _untaggable set cannot represent
a written exchange in them. motion-safe: stops the scroll entirely for
reduced-motion visitors rather than slowing it."
```

---

### Task 8: `HeroDemo`

**Files:**
- Create: `src/components/home/parts/HeroDemo.tsx`
- Create: `src/components/home/parts/HeroDemo.test.tsx`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `default export HeroDemo`; `data-testid`s `hero-demo`, `hero-headline`, `hero-store-ios`, `hero-store-android`, `demo-message` (one per chat bubble), `demo-tutor-note`.

**Context the implementer needs:** this is the page's whole argument. The visitor has roughly four seconds, and the one thing that separates this product from a flashcard app is that a real person is on the other side and the translation happens in flight. So the hero shows a Korean message, its English translation underneath, a reply, and an AI tutor correction — the mechanic, not a claim about the mechanic.

The messages animate in on a stagger. Under `prefers-reduced-motion` they must all be present immediately rather than animating; the test asserts the content is in the document regardless, so the animation is presentation only and never gates the content.

- [ ] **Step 1: Write the failing test**

Create `src/components/home/parts/HeroDemo.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import HeroDemo from "./HeroDemo";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

it("renders a headline", () => {
  render(<HeroDemo />);
  expect(screen.getByTestId("hero-headline")).toBeInTheDocument();
});

it("links to both stores", () => {
  render(<HeroDemo />);
  expect(screen.getByTestId("hero-store-ios")).toHaveAttribute(
    "href", expect.stringContaining("apps.apple.com")
  );
  expect(screen.getByTestId("hero-store-android")).toHaveAttribute(
    "href", expect.stringContaining("play.google.com")
  );
});

// The mechanic is the argument: a message, its translation, and a correction.
it("shows the exchange, its translation and a tutor correction", () => {
  render(<HeroDemo />);
  expect(screen.getAllByTestId("demo-message").length).toBeGreaterThanOrEqual(2);
  expect(screen.getByTestId("demo-tutor-note")).toBeInTheDocument();
});

// Content must never depend on an animation having run.
it("renders all content immediately, animation aside", () => {
  render(<HeroDemo />);
  const text = screen.getByTestId("hero-demo").textContent || "";
  expect(text).toContain("안녕하세요");
  expect(text).toContain("Do you have time today?");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=parts/HeroDemo`
Expected: FAIL — `Cannot find module './HeroDemo'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/components/home/parts/HeroDemo.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";

const APP_STORE_URL =
  "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bananatalk.app";

const HeroDemo: React.FC = () => {
  const { t } = useTranslation();

  return (
    <section
      data-testid="hero-demo"
      className="px-4 py-14 sm:py-20 bg-gradient-to-b from-white to-canvas dark:from-canvas-dark dark:to-canvas-dark"
    >
      <div className="mx-auto grid max-w-5xl items-center gap-10 lg:grid-cols-[1.1fr_.9fr]">
        <div>
          <h1
            data-testid="hero-headline"
            className="text-4xl font-extrabold leading-[1.08] tracking-tight text-gray-900 sm:text-5xl dark:text-gray-50"
          >
            {t("home.hero.title") || "Say it badly."}{" "}
            <span className="text-brand">
              {t("home.hero.titleAccent") || "We'll translate."}
            </span>
          </h1>
          <p className="mt-4 max-w-md text-base leading-relaxed text-gray-600 dark:text-gray-300">
            {t("home.hero.subtitle") ||
              "Type in your language, they read it in theirs. Tap any message to see how it was really said — that's how you learn."}
          </p>

          <div className="mt-7 flex flex-wrap gap-3">
            <a
              data-testid="hero-store-ios"
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-xl bg-gray-900 px-5 py-3 text-sm font-bold text-white"
            >
              App Store
            </a>
            <a
              data-testid="hero-store-android"
              href={PLAY_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-xl bg-gray-900 px-5 py-3 text-sm font-bold text-white"
            >
              Google Play
            </a>
          </div>

          <p className="mt-5 text-xs font-medium text-gray-400">
            {t("home.hero.trust") || "Free forever tier · 137 languages · AI tutor 24/7"}
          </p>
        </div>

        {/* The mechanic, shown rather than claimed. */}
        <div className="rounded-card bg-gradient-to-br from-brand/[0.08] to-banana/[0.14] p-5 motion-safe:animate-bt-float">
          <div className="flex flex-col gap-3">
            <div
              data-testid="demo-message"
              className="max-w-[86%] self-start rounded-card bg-surface p-3 shadow-card motion-safe:animate-bt-rise dark:bg-cardbg-dark"
            >
              <p className="text-sm text-gray-900 dark:text-gray-50">안녕하세요! 오늘 시간 있어요?</p>
              <p className="mt-1.5 border-t border-dashed border-gray-200 pt-1.5 text-xs text-brand dark:border-gray-600">
                Hi! Do you have time today?
              </p>
            </div>

            <div
              data-testid="demo-message"
              className="max-w-[86%] self-end rounded-card bg-brand p-3 text-white shadow-card motion-safe:animate-bt-rise"
              style={{ animationDelay: "400ms" }}
            >
              <p className="text-sm">Yes! I want practice Korean 😅</p>
              <p className="mt-1.5 border-t border-dashed border-white/40 pt-1.5 text-xs opacity-90">
                네! 한국어 연습하고 싶어요
              </p>
            </div>

            <div
              data-testid="demo-tutor-note"
              className="max-w-[94%] self-start rounded-card border-2 border-banana bg-surface p-3 shadow-card motion-safe:animate-bt-rise dark:bg-cardbg-dark"
              style={{ animationDelay: "800ms" }}
            >
              <p className="text-[10px] font-extrabold tracking-wide text-banana-dark">✦ AI TUTOR</p>
              <p className="mt-1 text-xs text-gray-700 dark:text-gray-200">
                "I want to practise" — <b>practise</b> takes <i>to</i>. Try:{" "}
                <i>I want to practise Korean.</i>
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroDemo;
```

- [ ] **Step 4: Confirm the keyframes exist**

`bt-rise` and `bt-float` were added to `tailwind.config.js` in Task 2. Confirm:

```bash
grep -n "bt-rise\|bt-float" tailwind.config.js
```

Expected: four hits. If any is missing, Task 2 was not completed; stop and report rather than adding a second copy.

- [ ] **Step 5: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=parts/HeroDemo`
Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add src/components/home/parts/HeroDemo.tsx src/components/home/parts/HeroDemo.test.tsx tailwind.config.js
git commit -m "feat(home): demo-led hero

Shows the mechanic instead of claiming it -- a Korean message, its
translation, a reply, and an AI tutor correction. Content renders
immediately; the stagger is presentation only and is dropped entirely
under prefers-reduced-motion."
```

---

### Task 9: `StatStrip`, `HowItWorks`, `EarlyAdopterBand`, `FinalCta`

**Files:**
- Create: `src/components/home/parts/StatStrip.tsx`
- Create: `src/components/home/parts/HowItWorks.tsx`
- Create: `src/components/home/parts/EarlyAdopterBand.tsx`
- Create: `src/components/home/parts/FinalCta.tsx`
- Create: `src/components/home/parts/staticSections.test.tsx`

**Interfaces:**
- Consumes: `SurfaceCard`, `Badge` from `src/design`; `Reveal`, `useInView`, `useCountUp` from Task 2.
- Produces: four default exports; `data-testid`s `stat-strip`, `stat-item`, `how-it-works`, `how-step`, `early-adopter-band`, `final-cta`.

**Context the implementer needs:** these four are grouped because each is a short presentational section with no state — splitting them into four tasks would give a reviewer four near-identical diffs.

Every stat must be **verifiable**. The four are 137 languages, 14 app languages, 24/7 AI tutor, free forever tier. **No member count** — `/api/v1/auth/users/count` is behind `protect` (`routes/users.js:63`) so a logged-out visitor cannot read it, and exposing it is a backend change outside this plan. **No ratings or review counts** — the App Store listing has zero.

- [ ] **Step 1: Write the failing test**

Create `src/components/home/parts/staticSections.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import StatStrip from "./StatStrip";
import HowItWorks from "./HowItWorks";
import EarlyAdopterBand from "./EarlyAdopterBand";
import FinalCta from "./FinalCta";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

it("shows exactly the four verifiable stats", () => {
  render(<StatStrip />);
  expect(screen.getAllByTestId("stat-item")).toHaveLength(4);
  expect(screen.getByTestId("stat-strip").textContent).toContain("137");
});

// Nothing on this page may claim social proof the product has not earned.
it("claims no members, ratings or reviews", () => {
  render(<StatStrip />);
  const text = (screen.getByTestId("stat-strip").textContent || "").toLowerCase();
  expect(text).not.toContain("member");
  expect(text).not.toContain("rating");
  expect(text).not.toContain("review");
  expect(text).not.toContain("★");
});

it("walks through three steps", () => {
  render(<HowItWorks />);
  expect(screen.getAllByTestId("how-step")).toHaveLength(3);
});

it("frames the launch honestly rather than borrowing credibility", () => {
  render(<EarlyAdopterBand />);
  const text = screen.getByTestId("early-adopter-band").textContent || "";
  expect(text).toContain("2025");
  expect(text.toLowerCase()).not.toContain("trusted by");
});

it("closes with both store links", () => {
  render(<FinalCta />);
  const cta = screen.getByTestId("final-cta");
  expect(cta.querySelector('a[href*="apps.apple.com"]')).toBeTruthy();
  expect(cta.querySelector('a[href*="play.google.com"]')).toBeTruthy();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=parts/staticSections`
Expected: FAIL — `Cannot find module './StatStrip'`.

- [ ] **Step 3: Write the four sections**

Create `src/components/home/parts/StatStrip.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import Reveal from "../anim/Reveal";
import { useInView } from "../anim/useInView";
import { useCountUp } from "../anim/useCountUp";

// Every figure here is checkable. No member count: /api/v1/auth/users/count is
// behind `protect` (routes/users.js:63), so a logged-out visitor cannot read
// it. No ratings: the App Store listing has none.
const STATS = [
  { value: "137", label: "languages" },
  { value: "14", label: "app languages" },
  { value: "24/7", label: "AI tutor" },
  { value: "Free", label: "forever tier" },
];

/** Numeric stats tick up when the strip scrolls into view; the rest are literal. */
const StatValue: React.FC<{ value: string; start: boolean }> = ({ value, start }) => {
  const numeric = /^\d+$/.test(value) ? Number(value) : null;
  const counted = useCountUp(numeric ?? 0, { start: start && numeric !== null });
  return (
    <p className="text-2xl font-extrabold text-brand-dark dark:text-brand-light">
      {numeric === null ? value : counted}
    </p>
  );
};

const StatStrip: React.FC = () => {
  const { t } = useTranslation();
  const [ref, inView] = useInView<HTMLElement>();

  return (
    <section
      ref={ref}
      data-testid="stat-strip"
      className="border-y border-gray-100 bg-surface py-8 dark:border-gray-700 dark:bg-cardbg-dark"
    >
      <div className="mx-auto grid max-w-4xl grid-cols-2 gap-6 px-4 sm:grid-cols-4">
        {STATS.map((s, i) => (
          <Reveal key={s.label} delayMs={i * 90}>
            <div data-testid="stat-item" className="text-center">
              <StatValue value={s.value} start={inView} />
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

Create `src/components/home/parts/HowItWorks.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { SurfaceCard } from "../../../design";
import Reveal from "../anim/Reveal";

const STEPS = [
  {
    n: "1",
    title: "Tell us what you speak, and what you want",
    body: "Pick your native language and the one you're learning. That pair is how we match you.",
  },
  {
    n: "2",
    title: "Find someone worth talking to",
    body: "Browse partners learning your language. Wave, or just start a conversation.",
  },
  {
    n: "3",
    title: "Talk badly, improve fast",
    body: "Every message is translated both ways, and the AI tutor corrects you without anyone watching.",
  },
];

const HowItWorks: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section data-testid="how-it-works" className="px-4 py-16">
      <div className="mx-auto max-w-5xl">
        <h2 className="text-center text-3xl font-extrabold tracking-tight text-gray-900 dark:text-gray-50">
          {t("home.howItWorks.title") || "How it works"}
        </h2>
        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          {STEPS.map((s, i) => (
            <Reveal key={s.n} delayMs={i * 120}>
              <SurfaceCard padding="lg">
              <div data-testid="how-step">
                <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-brand/[0.12] text-sm font-extrabold text-brand-dark dark:text-brand-light">
                  {s.n}
                </span>
                <h3 className="mt-3 text-sm font-bold text-gray-900 dark:text-gray-50">{s.title}</h3>
                <p className="mt-1.5 text-xs leading-relaxed text-gray-600 dark:text-gray-300">{s.body}</p>
              </div>
              </SurfaceCard>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
```

Create `src/components/home/parts/EarlyAdopterBand.tsx`:

```tsx
import React from "react";
import { Badge } from "../../../design";

// Honest framing in place of social proof the product has not earned. This
// band is explicitly temporary: once real reviews exist, they replace it.
const EarlyAdopterBand: React.FC = () => (
  <section data-testid="early-adopter-band" className="px-4 py-14">
    <div className="mx-auto max-w-3xl rounded-card bg-banana/[0.14] p-8 text-center">
      <Badge tone="banana">Launched December 2025</Badge>
      <h2 className="mt-3 text-2xl font-extrabold tracking-tight text-gray-900 dark:text-gray-50">
        Be one of the first
      </h2>
      <p className="mx-auto mt-2 max-w-xl text-sm leading-relaxed text-gray-600 dark:text-gray-300">
        BanaTalk is new. The people you meet here are the ones building what this
        community becomes — which is a better reason to join early than any review.
      </p>
    </div>
  </section>
);

export default EarlyAdopterBand;
```

Create `src/components/home/parts/FinalCta.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";

const APP_STORE_URL =
  "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bananatalk.app";

const FinalCta: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section data-testid="final-cta" className="bg-brand px-4 py-16 text-center">
      <h2 className="text-3xl font-extrabold tracking-tight text-white">
        {t("home.cta.title") || "Someone is learning your language right now"}
      </h2>
      <p className="mx-auto mt-2 max-w-md text-sm text-white/90">
        {t("home.cta.subtitle") || "Free to start. No card, no trial countdown."}
      </p>
      <div className="mt-7 flex flex-wrap justify-center gap-3">
        <a href={APP_STORE_URL} target="_blank" rel="noopener noreferrer"
           className="rounded-xl bg-white px-6 py-3 text-sm font-extrabold text-brand-dark">
          App Store
        </a>
        <a href={PLAY_STORE_URL} target="_blank" rel="noopener noreferrer"
           className="rounded-xl bg-gray-900 px-6 py-3 text-sm font-extrabold text-white">
          Google Play
        </a>
      </div>
    </section>
  );
};

export default FinalCta;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=parts/staticSections`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add src/components/home/parts/StatStrip.tsx src/components/home/parts/HowItWorks.tsx src/components/home/parts/EarlyAdopterBand.tsx src/components/home/parts/FinalCta.tsx src/components/home/parts/staticSections.test.tsx
git commit -m "feat(home): stat strip, how-it-works, early-adopter band, final CTA

Four short presentational sections. Every stat is verifiable and a test
asserts the strip claims no members, ratings or reviews -- the count
endpoint is authenticated and the store listing has zero reviews."
```

---

### Task 10: `FeatureShowcase`

**Files:**
- Create: `src/components/home/parts/FeatureShowcase.tsx`
- Create: `src/components/home/parts/FeatureShowcase.test.tsx`

**Interfaces:**
- Consumes: `SurfaceCard`, `Badge` from `src/design`; `Reveal` from Task 2.
- Produces: `default export FeatureShowcase`; `data-testid`s `feature-showcase`, `feature-card`, `feature-mobile-only`.

**Context the implementer needs:** features that exist only in the app carry a "In the app" badge. That badge is the page's honest version of an upsell — it tells the visitor what they get by installing, rather than implying the web has everything. The features listed must be ones the product actually ships: Community matching, Moments, chat with live translation, AI tutor, voice rooms, Gatherings.

- [ ] **Step 1: Write the failing test**

Create `src/components/home/parts/FeatureShowcase.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import FeatureShowcase from "./FeatureShowcase";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

it("renders a card per feature", () => {
  render(<FeatureShowcase />);
  expect(screen.getAllByTestId("feature-card").length).toBeGreaterThanOrEqual(6);
});

it("marks the mobile-only features so the install promise is honest", () => {
  render(<FeatureShowcase />);
  expect(screen.getAllByTestId("feature-mobile-only").length).toBeGreaterThanOrEqual(1);
});

it("does not mark every feature mobile-only", () => {
  render(<FeatureShowcase />);
  const all = screen.getAllByTestId("feature-card").length;
  const mobile = screen.getAllByTestId("feature-mobile-only").length;
  expect(mobile).toBeLessThan(all);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=parts/FeatureShowcase`
Expected: FAIL — `Cannot find module './FeatureShowcase'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/components/home/parts/FeatureShowcase.tsx`:

```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { SurfaceCard, Badge } from "../../../design";
import Reveal from "../anim/Reveal";

// `appOnly` drives the "In the app" badge. It is the honest form of an upsell:
// it says what installing gets you rather than implying the web has it all.
const FEATURES = [
  { icon: "🌏", title: "Find a partner", body: "Match on the language pair you actually want to trade.", appOnly: false },
  { icon: "💬", title: "Chat that translates", body: "Both directions, in the message, as you type.", appOnly: false },
  { icon: "📸", title: "Moments", body: "Share what your day looks like; get corrected by natives.", appOnly: false },
  { icon: "✦", title: "AI tutor", body: "Practise at 3am without embarrassing yourself.", appOnly: true },
  { icon: "🎙️", title: "Voice rooms", body: "Drop into a live room and just listen, if you like.", appOnly: true },
  { icon: "📍", title: "Gatherings", body: "Meet people learning your language nearby.", appOnly: true },
];

const FeatureShowcase: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section data-testid="feature-showcase" className="px-4 py-16 bg-canvas dark:bg-canvas-dark">
      <div className="mx-auto max-w-5xl">
        <h2 className="text-center text-3xl font-extrabold tracking-tight text-gray-900 dark:text-gray-50">
          {t("home.features.title") || "Everything you need to actually practise"}
        </h2>
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f, i) => (
            <Reveal key={f.title} delayMs={(i % 3) * 110}>
              <SurfaceCard
                padding="lg"
                className="h-full transition-transform duration-300 motion-safe:hover:-translate-y-1"
              >
              <div data-testid="feature-card">
                <span aria-hidden className="text-2xl">{f.icon}</span>
                <div className="mt-2 flex items-center gap-2">
                  <h3 className="text-sm font-bold text-gray-900 dark:text-gray-50">{f.title}</h3>
                  {f.appOnly && (
                    <span data-testid="feature-mobile-only">
                      <Badge tone="banana">In the app</Badge>
                    </span>
                  )}
                </div>
                <p className="mt-1.5 text-xs leading-relaxed text-gray-600 dark:text-gray-300">{f.body}</p>
              </div>
              </SurfaceCard>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
};

export default FeatureShowcase;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=parts/FeatureShowcase`
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/components/home/parts/FeatureShowcase.tsx src/components/home/parts/FeatureShowcase.test.tsx
git commit -m "feat(home): feature showcase with honest app-only badges

Mobile-only features carry an 'In the app' badge rather than being listed
as though the web has them."
```

---

### Task 11: Assemble `HomeMain` and delete the SCSS

**Files:**
- Modify: `src/components/home/HomeMain.tsx` (full rewrite, 597 → ~90 lines)
- Delete: `src/components/home/HomeMain.scss`
- Create: `src/components/home/HomeMain.test.tsx`
- Modify: `src/utils/locales/eng.json` (add the new `home.*` keys)

**Interfaces:**
- Consumes: every part from Tasks 4-10 and the growth surfaces from Tasks 5-6.
- Produces: `default export HomeMain` composing them in order.

**Context the implementer needs — read before deleting anything.** `HomeMain.scss` declares **87 top-level class names**, several of which are generic enough to collide with other routes or with Bootstrap, which is still loaded globally: `.btn-primary`, `.btn-secondary`, `.feature-card`, `.gradient-text`, `.chat-message`. If any other component relies on a rule defined in this file, deleting it regresses that component silently, with no build error and no failing test.

So Step 1 is a real gate, not a formality.

- [ ] **Step 1: Prove no other file depends on the SCSS**

Run:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
grep -oE "^\.[a-zA-Z][a-zA-Z0-9_-]*" src/components/home/HomeMain.scss | sed 's/^\.//' | sort -u > /tmp/home-classes.txt
wc -l < /tmp/home-classes.txt
while read -r c; do
  hits=$(grep -rl "\b$c\b" src --include="*.tsx" --include="*.ts" --include="*.scss" --include="*.css" 2>/dev/null \
         | grep -v "components/home/HomeMain" || true)
  [ -n "$hits" ] && echo "LEAK: .$c used by: $hits"
done < /tmp/home-classes.txt
echo "--- scan complete ---"
```

Expected: `87` class names, and ideally no `LEAK:` lines.

**If any `LEAK:` line appears, do not delete the file.** Report the leaking class names and the files that use them, and stop. That is a finding the plan did not anticipate and it needs a decision, not a workaround.

- [ ] **Step 2: Write the failing test**

Create `src/components/home/HomeMain.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import HomeMain from "./HomeMain";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("../../store/slices/plansSlice", () => ({
  ...jest.requireActual("../../store/slices/plansSlice"),
  useGetVipPlansQuery: () => ({ data: undefined, isError: true, isLoading: false }),
}));

beforeEach(() => window.localStorage.clear());

it("assembles every section in order", () => {
  render(<HomeMain />);
  ["hero-demo", "stat-strip", "how-it-works", "feature-showcase",
   "language-marquee", "pricing-section", "early-adopter-band", "final-cta"]
    .forEach((id) => expect(screen.getByTestId(id)).toBeInTheDocument());
});

it("mounts the promo carousel", () => {
  render(<HomeMain />);
  expect(screen.getByTestId("promo-carousel")).toBeInTheDocument();
});

// The whole page must be free of the prices that were never true.
it("shows no invented prices anywhere", () => {
  const { container } = render(<HomeMain />);
  expect(container.textContent).not.toContain("$14.99");
  expect(container.textContent).not.toContain("$49.99");
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=home/HomeMain`
Expected: FAIL — the current `HomeMain` renders none of those test ids.

- [ ] **Step 4: Rewrite HomeMain**

Replace the entire contents of `src/components/home/HomeMain.tsx`:

```tsx
import React from "react";
import HeroDemo from "./parts/HeroDemo";
import StatStrip from "./parts/StatStrip";
import HowItWorks from "./parts/HowItWorks";
import FeatureShowcase from "./parts/FeatureShowcase";
import LanguageMarquee from "./parts/LanguageMarquee";
import PricingSection from "./parts/PricingSection";
import EarlyAdopterBand from "./parts/EarlyAdopterBand";
import FinalCta from "./parts/FinalCta";
import PromoCarousel from "../growth/PromoCarousel";
import AppDownloadPopup from "../growth/AppDownloadPopup";
import StickyAppBanner from "../growth/StickyAppBanner";

// The homepage is an ordering of sections and nothing else. Every section owns
// its own markup, copy and tests; this file owns only the sequence, which is
// the argument the page makes: show the mechanic, prove the scale, explain the
// use, show the features, name the price, ask for the install.
const HomeMain: React.FC = () => (
  <div className="bg-surface dark:bg-canvas-dark">
    <PromoCarousel />
    <HeroDemo />
    <StatStrip />
    <HowItWorks />
    <FeatureShowcase />
    <LanguageMarquee />
    <div id="pricing">
      <PricingSection />
    </div>
    <EarlyAdopterBand />
    <FinalCta />
    <AppDownloadPopup />
    <StickyAppBanner />
  </div>
);

export default HomeMain;
```

- [ ] **Step 5: Delete the SCSS**

```bash
git rm src/components/home/HomeMain.scss
```

- [ ] **Step 6: Add the English copy keys**

In `src/utils/locales/eng.json`, merge into the existing `"home"` object (keep the existing subsections; add these alongside):

```json
"hero": {
  "title": "Say it badly.",
  "titleAccent": "We'll translate.",
  "subtitle": "Type in your language, they read it in theirs. Tap any message to see how it was really said — that's how you learn.",
  "trust": "Free forever tier · 137 languages · AI tutor 24/7"
},
"stats": {
  "languages": "languages",
  "app languages": "app languages",
  "AI tutor": "AI tutor",
  "forever tier": "forever tier"
}
```

Leave the other 17 locale files untouched — the inline `|| "English"` fallbacks cover them until translation is done as its own content task.

- [ ] **Step 7: Run the full suite**

Run: `CI=true npx react-scripts test`
Expected: PASS across every suite. The baseline before this plan was 48 suites / 230 tests; this plan adds roughly 52 tests.

- [ ] **Step 8: Verify the production build**

Run: `npx react-scripts build`
Expected: exit 0. (Do **not** add `CI=true` — it promotes pre-existing warnings in unrelated files to errors and fails on `main` too.)

- [ ] **Step 9: Commit**

```bash
git add src/components/home src/utils/locales/eng.json
git commit -m "feat(home): assemble the marketing homepage, delete HomeMain.scss

HomeMain drops from 597 lines to an ordering of sections. The 1076-line
SCSS goes with it, after verifying none of its 87 class names -- several
generic enough to collide with Bootstrap -- are used anywhere else.

A test asserts the whole page is free of the \$14.99 and \$49.99 that were
never what the stores charged."
```

---

## Verification

- [ ] `CI=true npx react-scripts test` — every suite passes
- [ ] `npx react-scripts build` — exit 0
- [ ] `grep -rn "14\.99\|49\.99" src/` returns nothing
- [ ] `grep -rn "#00BFA5" src/components/home src/components/growth` returns nothing
- [ ] `grep -rn "bg-brand/[0-9]\|bg-banana/[0-9]" src/components/home src/components/growth` returns nothing — no bare opacity steps
- [ ] `ls src/components/home/HomeMain.scss` — no such file
- [ ] `git log --oneline main..HEAD` shows 11 commits
- [ ] `grep -rn "animate-\[" src/components/home` returns nothing — every animation is a named token from Task 2, never an inline arbitrary keyframe

**Eyeball before merge**, in a browser at `npm start`:

- [ ] Hero messages stagger in and the demo panel drifts; with OS reduced-motion enabled everything is still, the marquee does not scroll, and the stat numbers show their final value immediately
- [ ] Stat numbers count up when the strip scrolls into view
- [ ] How-it-works steps and feature cards reveal on a stagger; feature cards lift on hover
- [ ] Promo carousel rotates every 6s, pauses on hover, dismisses and stays dismissed on reload
- [ ] Pricing shows `$9.99` / `$23.99` / `$71.99` with the quarterly plan highlighted
- [ ] At desktop width, the popup appears after scrolling past the hero and the sticky banner does not
- [ ] At phone width, the sticky banner appears and the popup does not
- [ ] Dark mode (OS-level) renders every section legibly

---

## Self-Review

**Spec coverage.** §3 architecture → Tasks 1-11. §4 pricing → Tasks 3-4, including the fallback and the regression guard. §5.1 carousel → Task 5, two tones enforced by test. §5.2 popup → Tasks 1 and 6, every suppression rule unit-tested. §5.3 sticky banner → Task 6, with the one-surface-at-a-time test. §6.1 stat strip → Task 9, with a test asserting no member/rating/review claim. §6.2 marquee → Task 7, sign languages excluded by test. §6.3 early-adopter framing → Task 9. §6.4 i18n → Task 11 Step 6, `eng.json` only. §8 animation → Task 2 (the shared layer), consumed by Tasks 7, 8 and 9; `motion-safe:` throughout. §9 testing → distributed; every listed test appears in a task. §10 risks → the SCSS leak scan is Task 11 Step 1 and is a hard stop, not advisory.

**Deliberately not built**, per spec §7: screenshot carousel, testimonials in any form, member count, any web payment flow, changes to `/download` or `/register`, any animation library.

**Type consistency.** `VipPlan`, `inferPlatform`, `FALLBACK_PLANS`, `useGetVipPlansQuery` are spelled identically in Tasks 3, 4 and 11. `GateKey`, `GateContext`, `isSuppressed`, `recordDismissal`, `SUPPRESSION_DAYS`, `MOBILE_MAX_WIDTH` match across Tasks 1, 5 and 6. `PromoSlide` / `PROMO_SLIDES` match across Tasks 5 and its test. `MARQUEE_LANGUAGES` matches across Task 7's data file, component and test. `SurfaceCard`'s props (`padding`, `interactive`, `className`, `onClick`) and `Badge`'s (`tone: "brand" | "banana"`) match the merged `src/design` exactly — verified against `0dd3869`, not assumed.

**Two things the implementer must confirm rather than assume.** Task 3 Step 6 checks the real response envelope of `GET /purchases/plans` — `transformResponse` handles three shapes because the handler's return was not read end-to-end, and the report should record which is real. Task 11 Step 1 is a hard gate: if any of the 87 SCSS class names is used outside `HomeMain`, deletion stops and the finding is reported rather than worked around.
