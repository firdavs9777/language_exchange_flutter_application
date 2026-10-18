# Today's Matches (Web) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Signed-in members land on a **Today** tab on `/communities` showing their daily batch from `GET /matching/daily`, with Say hi / Wave / Skip, the way the app does.

**Architecture:**
- **Pure helpers and storage,** in `src/components/community/today/`:
  - `dailyMatchView.ts` — photo URL, reason chips, "replies fast", country flag, refresh label;
  - `todaySkips.ts` — skipped ids per batch date.
- **Two presentational components:** `MatchCard` and `TodayTab`.
- **Two RTK Query endpoints** in `communitySlice.ts`.
- **`MainCommunity` integration:**
  - `today` becomes the URL's left-out default; an absent `tab` means All when the URL carries list params;
  - a display-only fallback to All when the endpoint answers 404 or the member is signed out.
- No backend changes.

**Tech Stack:** React 18 + TypeScript (CRA), RTK Query, react-router v6 data router, Jest + Testing Library, i18next (18 locale JSONs).

**Spec:** `docs/superpowers/specs/2026-10-08-todays-matches-design.md`

## Global Constraints

- Web repo only: `/Users/davis/Desktop/Personal/language_exchange_web_front`. **No backend changes.**
- Work on branch `feat/todays-matches`. Merge to `main` with `git merge --no-ff`. **Never** add a `Co-Authored-By` trailer.
- Commands:
  - tests: `CI=true npx react-scripts test --watchAll=false [--testPathPattern X]`;
  - type-check: `npx react-scripts build`. Its ESLint parser rejects `import type`, so use plain `import`.
- New copy lives under `communityMain.today.*` in all 18 `src/utils/locales/*.json`. `communityMain` is parity-guarded.
- Endpoints, all existing and live:
  - `GET /api/v1/matching/daily` — answers 404 when the feature is off;
  - `POST /api/v1/interactions/skip` with body `{ targetUserId }`.
- Daily `user` objects carry raw `images`, not `imageUrls`. `matchReasons` are codes: `reciprocal_pair`, `same_target_language`, `shared_topic:<id>`, `active_today`, `same_city`. `responseRate` is `number | null`.
- The image URL rule matches `MainNavbar.tsx:193-195`: absolute → as-is; relative → `${BASE_URL}/uploads/<path>`.
- Pushing `main` deploys the web automatically (GitHub Actions "Deploy to DigitalOcean").

## Review Focus

1. **The batch's `date` changes while the tab is open** (midnight rollover). Skips from yesterday must not hide today's cards. *Pinned in Task 1:* "a new date starts clean"; *Task 4:* rollover refetch.
2. **`sessionStorage` throws** (private mode, blocked storage). Skips must still work for the session and nothing may crash. *Pinned in Task 1:* "storage that throws".
3. **A `shared_topic:` id with no translation.** The chip must show the id, never `profile.topics.<id>`. *Pinned in Task 1:* "an unknown topic id shows the id".
4. **A daily user with no `images`, an empty first image, or a relative path.** Avatar initials, or a correct `/uploads` URL. *Pinned in Task 1:* `photoUrl` tests.
5. **A pre-existing filtered link with no `tab`** (`/communities?native=ko`). It lands on All and keeps its params. *Pinned in Task 5:* "old filtered links land on All".

---

### Task 1: Data and pure helpers

**Files:**
- Modify: `src/store/slices/communitySlice.ts` — add two endpoints and export their hooks.
- Create: `src/components/community/today/types.ts`, `src/components/community/today/dailyMatchView.ts`, `src/components/community/today/todaySkips.ts`
- Test: `src/components/community/today/dailyMatchView.test.ts`, `src/components/community/today/todaySkips.test.ts`, and append to `src/store/slices/communityEndpoints.test.ts`

**Interfaces — Produces:**

```ts
// types.ts
export interface DailyMatchUser { _id: string; name: string; images?: string[]; native_language?: string;
  language_to_learn?: string; location?: { country?: string; city?: string }; intents?: string[]; [k: string]: any; }
export interface DailyMatch { user: DailyMatchUser; matchReasons: string[]; reciprocal?: boolean;
  lastActiveBucket?: string; responseRate: number | null; boosted?: boolean; }
export interface DailyMatchesResponse { success: boolean; date: string; nextRefreshAt?: string; cached?: boolean; matches: DailyMatch[]; }
// dailyMatchView.ts
export function photoUrl(images: string[] | undefined): string | undefined
export function reasonChips(reasons: string[] | undefined, user: DailyMatchUser, t: (k: string, o?: any) => string): string[]
export function repliesFast(rate: number | null | undefined): boolean
export function countryFlag(country: string | undefined): string
export function refreshTimeLabel(nextRefreshAt: string | undefined, locale: string): string | null
// todaySkips.ts
export function loadSkips(date: string): string[]
export function addSkip(date: string, id: string): string[]
// communitySlice.ts hooks
useGetDailyMatchesQuery, useSkipUserMutation
```

- [ ] **Step 1: Branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front && git checkout main && git pull --ff-only && git checkout -b feat/todays-matches
```

- [ ] **Step 2: Write the failing endpoint tests.** Append to `src/store/slices/communityEndpoints.test.ts`. That file already defines `makeStore`, `mockFetch` and `communityApiSlice`.

```ts
describe("Today's matches endpoints hit the live backend routes", () => {
  it("getDailyMatches -> GET /api/v1/matching/daily", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((communityApiSlice.endpoints as any).getDailyMatches.initiate());
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/matching/daily");
    expect(calls[0].method).toBe("GET");
  });

  it("skipUser -> POST /api/v1/interactions/skip with {targetUserId}", async () => {
    const calls = mockFetch();
    const store = makeStore();
    await store.dispatch((communityApiSlice.endpoints as any).skipUser.initiate("u-9"));
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe("/api/v1/interactions/skip");
    expect(calls[0].method).toBe("POST");
    expect(JSON.parse(calls[0].body as string)).toEqual({ targetUserId: "u-9" });
  });
});
```

- [ ] **Step 3: Write the failing helper tests**

`src/components/community/today/dailyMatchView.test.ts`:

```ts
import { photoUrl, reasonChips, repliesFast, countryFlag, refreshTimeLabel } from "./dailyMatchView";
import { BASE_URL } from "../../../constants";

const t = (key: string, options?: any) => {
  if (key.startsWith("profile.topics.")) return options && options.defaultValue !== undefined && key === "profile.topics.zzz" ? options.defaultValue : `T(${key})`;
  return options ? `${key}|${JSON.stringify(options)}` : key;
};
const user = { _id: "u1", name: "Ada", language_to_learn: "Korean" };

describe("photoUrl", () => {
  it("uses an absolute URL as-is", () => {
    expect(photoUrl(["https://cdn.x/a.jpg"])).toBe("https://cdn.x/a.jpg");
  });
  it("puts a relative path under the API's /uploads", () => {
    expect(photoUrl(["users/a.jpg"])).toBe(`${BASE_URL}/uploads/users/a.jpg`);
  });
  it("skips empty entries and returns undefined for none", () => {
    expect(photoUrl(["", "https://cdn.x/b.jpg"])).toBe("https://cdn.x/b.jpg");
    expect(photoUrl([])).toBeUndefined();
    expect(photoUrl(undefined)).toBeUndefined();
  });
});

describe("reasonChips", () => {
  it("maps every known code", () => {
    expect(reasonChips(["reciprocal_pair", "same_target_language", "active_today", "same_city"], user, t)).toEqual([
      "communityMain.today.reasonReciprocal",
      'communityMain.today.reasonSameTarget|{"language":"Korean"}',
      "communityMain.today.reasonActiveToday",
      "communityMain.today.reasonSameCity",
    ]);
  });
  it("labels a shared topic through profile.topics", () => {
    expect(reasonChips(["shared_topic:music"], user, t)).toEqual([
      'communityMain.today.reasonSharedTopic|{"topic":"T(profile.topics.music)"}',
    ]);
  });
  it("an unknown topic id shows the id, never the raw key", () => {
    expect(reasonChips(["shared_topic:zzz"], user, t)).toEqual([
      'communityMain.today.reasonSharedTopic|{"topic":"zzz"}',
    ]);
  });
  it("drops codes it does not know", () => {
    expect(reasonChips(["from_the_future", "active_today"], user, t)).toEqual(["communityMain.today.reasonActiveToday"]);
    expect(reasonChips(undefined, user, t)).toEqual([]);
  });
});

describe("repliesFast", () => {
  it("is true from 0.7 up, false below and for null", () => {
    expect(repliesFast(0.7)).toBe(true);
    expect(repliesFast(0.95)).toBe(true);
    expect(repliesFast(0.69)).toBe(false);
    expect(repliesFast(null)).toBe(false);
    expect(repliesFast(undefined)).toBe(false);
  });
});

describe("countryFlag", () => {
  it("turns an English country name into its flag", () => {
    expect(countryFlag("South Korea")).toBe("🇰🇷");
    expect(countryFlag("Japan")).toBe("🇯🇵");
  });
  it("is empty for an unknown or missing country", () => {
    expect(countryFlag("Atlantis")).toBe("");
    expect(countryFlag(undefined)).toBe("");
  });
});

describe("refreshTimeLabel", () => {
  it("formats the refresh moment as a local hour and minute", () => {
    const label = refreshTimeLabel("2026-10-09T00:00:00.000Z", "en");
    expect(label).toMatch(/\d{1,2}:\d{2}/);
  });
  it("is null when missing or unparseable", () => {
    expect(refreshTimeLabel(undefined, "en")).toBeNull();
    expect(refreshTimeLabel("not a date", "en")).toBeNull();
  });
});
```

`src/components/community/today/todaySkips.test.ts`:

```ts
import { loadSkips, addSkip } from "./todaySkips";

beforeEach(() => window.sessionStorage.clear());

describe("todaySkips", () => {
  it("remembers skips for the batch's date", () => {
    expect(loadSkips("2026-10-08")).toEqual([]);
    addSkip("2026-10-08", "u1");
    expect(addSkip("2026-10-08", "u2")).toEqual(["u1", "u2"]);
    expect(loadSkips("2026-10-08")).toEqual(["u1", "u2"]);
  });
  it("does not repeat an id", () => {
    addSkip("2026-10-08", "u1");
    expect(addSkip("2026-10-08", "u1")).toEqual(["u1"]);
  });
  it("a new date starts clean", () => {
    addSkip("2026-10-08", "u1");
    expect(loadSkips("2026-10-09")).toEqual([]);
  });
  it("storage that throws: no crash, the skip still counts for this call", () => {
    const get = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
    const set = jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => { throw new Error("blocked"); });
    expect(loadSkips("2026-10-08")).toEqual([]);
    expect(addSkip("2026-10-08", "u1")).toEqual(["u1"]);
    get.mockRestore();
    set.mockRestore();
  });
  it("ignores a corrupt stored value", () => {
    window.sessionStorage.setItem("bt.todaySkips.2026-10-08", "{not json");
    expect(loadSkips("2026-10-08")).toEqual([]);
  });
});
```

- [ ] **Step 4: Run them — expect FAIL** (missing modules and endpoints)

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "today/|communityEndpoints"`

- [ ] **Step 5: Implement.**

`src/components/community/today/types.ts`:

```ts
/**
 * GET /api/v1/matching/daily -- the day's batch, chosen and cached server-side
 * until `nextRefreshAt` (midnight UTC). `user` is the USER_LIST_FIELDS
 * projection: raw `images`, no `imageUrls`. `matchReasons` are CODES
 * (lib/dailyMatches.js structuredReasons), not English.
 */
export interface DailyMatchUser {
  _id: string;
  name: string;
  images?: string[];
  native_language?: string;
  language_to_learn?: string;
  location?: { country?: string; city?: string };
  intents?: string[];
  [key: string]: any;
}

export interface DailyMatch {
  user: DailyMatchUser;
  matchReasons: string[];
  reciprocal?: boolean;
  lastActiveBucket?: string;
  /** null when the server has no rate for this person. */
  responseRate: number | null;
  boosted?: boolean;
}

export interface DailyMatchesResponse {
  success: boolean;
  /** The UTC day this batch belongs to (YYYY-MM-DD). */
  date: string;
  nextRefreshAt?: string;
  cached?: boolean;
  matches: DailyMatch[];
}
```

`src/components/community/today/dailyMatchView.ts`:

```ts
import { BASE_URL } from "../../../constants";
import { COUNTRY_CODES } from "../lib/countries";
import { DailyMatchUser } from "./types";

/**
 * The first photo, as a URL a browser can load. Daily matches carry raw
 * `images` (no `imageUrls`), so this is the rule MainNavbar already uses: an
 * absolute URL as-is, a relative storage path under the API's /uploads.
 */
export function photoUrl(images: string[] | undefined): string | undefined {
  const first = (images || []).find((image) => typeof image === "string" && image.trim());
  if (!first) return undefined;
  return first.startsWith("http") ? first : `${BASE_URL}/uploads/${first}`;
}

/**
 * Why this person is in today's batch, in the reader's language. The codes
 * come from lib/dailyMatches.js structuredReasons; one the web does not know
 * renders nothing -- there is no English string to fall back to, and a raw
 * code is never shown.
 */
export function reasonChips(
  reasons: string[] | undefined,
  user: DailyMatchUser,
  t: (key: string, options?: any) => string
): string[] {
  const chips: string[] = [];
  (reasons || []).forEach((code) => {
    if (code === "reciprocal_pair") chips.push(t("communityMain.today.reasonReciprocal"));
    else if (code === "same_target_language") {
      chips.push(t("communityMain.today.reasonSameTarget", { language: user.language_to_learn || "" }));
    } else if (code === "active_today") chips.push(t("communityMain.today.reasonActiveToday"));
    else if (code === "same_city") chips.push(t("communityMain.today.reasonSameCity"));
    else if (code.indexOf("shared_topic:") === 0) {
      const id = code.slice("shared_topic:".length);
      // defaultValue, not `|| id`: a missing key returns the key itself, so an
      // `||` would print "profile.topics.<id>".
      const topic = t(`profile.topics.${id}`, { defaultValue: id });
      chips.push(t("communityMain.today.reasonSharedTopic", { topic }));
    }
  });
  return chips.filter(Boolean);
}

/** The app's threshold (match_card.dart): 70% of first messages answered. */
export function repliesFast(rate: number | null | undefined): boolean {
  return typeof rate === "number" && rate >= 0.7;
}

let byEnglishName: Record<string, string> | null = null;

/** 🇰🇷 for "South Korea": the stored country is an English name (lib/countryNames). */
export function countryFlag(country: string | undefined): string {
  if (!country) return "";
  if (!byEnglishName) {
    byEnglishName = {};
    try {
      const names = new (Intl as any).DisplayNames(["en"], { type: "region" });
      COUNTRY_CODES.forEach((code) => {
        const name = names.of(code);
        if (name) (byEnglishName as Record<string, string>)[name.toLowerCase()] = code;
      });
    } catch (e) {
      // No Intl.DisplayNames: no flags, nothing else lost.
    }
  }
  const code = byEnglishName[country.trim().toLowerCase()];
  if (!code) return "";
  return String.fromCodePoint(...code.split("").map((c) => 0x1f1e6 + c.charCodeAt(0) - 65));
}

/** "9:00 AM" -- when the batch refreshes, in the reader's own clock. */
export function refreshTimeLabel(nextRefreshAt: string | undefined, locale: string): string | null {
  if (!nextRefreshAt) return null;
  const when = new Date(nextRefreshAt);
  if (isNaN(when.getTime())) return null;
  try {
    return new Intl.DateTimeFormat((locale || "en").replace(/_/g, "-"), { hour: "numeric", minute: "2-digit" }).format(when);
  } catch (e) {
    return new Intl.DateTimeFormat("en", { hour: "numeric", minute: "2-digit" }).format(when);
  }
}
```

`src/components/community/today/todaySkips.ts`:

```ts
/**
 * People skipped from today's batch. The server sends the same cached batch
 * all day, skipped cards included (it does not read skips when building it),
 * so the web remembers them per batch date in sessionStorage -- surviving a
 * reload, and starting clean when the date moves on. Storage that throws
 * (private mode, blocked site data) only means skips last until reload.
 */
const KEY = (date: string) => `bt.todaySkips.${date}`;

export function loadSkips(date: string): string[] {
  try {
    const raw = window.sessionStorage.getItem(KEY(date));
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed.filter((id) => typeof id === "string") : [];
  } catch (e) {
    return [];
  }
}

export function addSkip(date: string, id: string): string[] {
  const current = loadSkips(date);
  const next = current.indexOf(id) > -1 ? current : current.concat([id]);
  try {
    window.sessionStorage.setItem(KEY(date), JSON.stringify(next));
  } catch (e) {
    // Remembered for this call only.
  }
  return next;
}
```

In `src/store/slices/communitySlice.ts`, add inside `endpoints: (builder) => ({ ... })`, next to `getRecommendations`:

```ts
    // "Today": the day's batch of partners (GET /api/v1/matching/daily,
    // protected). The server picks and caches it until `nextRefreshAt`
    // (midnight UTC) and answers 404 when DAILY_MATCHES_ENABLED is off --
    // which the page reads as "this feature is not here", not as an error.
    getDailyMatches: builder.query({
      query: () => ({ url: "/api/v1/matching/daily" }),
      keepUnusedDataFor: 60,
    }),
    // POST /api/v1/interactions/skip { targetUserId }. Fire-and-forget from
    // the Today card: the card leaves at once whatever this answers.
    skipUser: builder.mutation({
      query: (targetUserId: string) => ({
        url: "/api/v1/interactions/skip",
        method: "POST",
        body: { targetUserId },
      }),
    }),
```

Then add `useGetDailyMatchesQuery,` and `useSkipUserMutation,` to the slice's exported hooks list.

- [ ] **Step 6: Run them — expect PASS**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "today/|communityEndpoints"`

- [ ] **Step 7: Commit**

```bash
git add src/store/slices/communitySlice.ts src/store/slices/communityEndpoints.test.ts src/components/community/today
git commit -m "feat(community): today's matches -- data, view helpers, per-day skips"
```

---

### Task 2: URL state — `today` is the left-out default

**Files:**
- Modify: `src/components/community/lib/communityUrlState.ts` — `CommunityUrlTab` (line ~34), `TABS` (line ~81), and the tab line of `encodeCommunityState` (line ~180).
- Modify: `src/components/community/tandem/CommunitySubNav.tsx` — `CommunityNavTab`.
- Test: `src/components/community/lib/communityUrlState.test.ts` (append, and fix the existing `all`-is-left-out assertions)

**Interfaces — Produces:**
- `CommunityUrlTab` and `CommunityNavTab` include `"today"`.
- `encodeCommunityState({ tab: "today" })` writes no `tab`; `encodeCommunityState({ tab: "all" })` writes `tab=all`.
- `decodeCommunityState` is unchanged in contract: it returns only what the URL said. The default is applied by `MainCommunity` in Task 5.

- [ ] **Step 1: Write the failing tests** — append to `src/components/community/lib/communityUrlState.test.ts`. The module's import line already brings in `encodeCommunityState` / `decodeCommunityState`; if `DEFAULT_FILTERS` is needed, mirror the file's existing imports.

```ts
describe("today is the default tab", () => {
  it("leaves `today` out of the URL", () => {
    expect(encodeCommunityState({ filters: {}, search: "", tab: "today" } as any).get("tab")).toBeNull();
  });
  it("writes `all` like any other tab", () => {
    expect(encodeCommunityState({ filters: {}, search: "", tab: "all" } as any).get("tab")).toBe("all");
  });
  it("reads tab=today and tab=all back", () => {
    expect(decodeCommunityState(new URLSearchParams("tab=today")).tab).toBe("today");
    expect(decodeCommunityState(new URLSearchParams("tab=all")).tab).toBe("all");
  });
  it("an absent tab decodes as absent -- the page decides the default", () => {
    expect(decodeCommunityState(new URLSearchParams("native=Korean")).tab).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (`all` is still left out; `today` is not in `TABS`)

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern communityUrlState`

- [ ] **Step 3: Implement**

1. `communityUrlState.ts`:
   - add `| 'today'` as the first member of `CommunityUrlTab`;
   - add `'today'` as the first entry of `TABS`;
   - in `encodeCommunityState`, replace:

     ```ts
     // `all` is the default, so it is never spelled out.
     if (tab !== 'all' && TABS.indexOf(tab) >= 0) params.set('tab', tab);
     ```

     with:

     ```ts
     // `today` is the default landing, so it is never spelled out; `all` now is,
     // or a bare /communities would mean Today and All could never be reached.
     if (tab !== 'today' && TABS.indexOf(tab) >= 0) params.set('tab', tab);
     ```

2. `CommunitySubNav.tsx`: add `| "today"` as the first member of `export type CommunityNavTab`. (The button itself comes in Task 5.)

3. Fix the existing tests in `communityUrlState.test.ts` that assert `all` is left out. Find them with `grep -n "all" src/components/community/lib/communityUrlState.test.ts`. Each now expects `tab=all` to be written, and any "default tab is left out" assertion now uses `today`. Each changed assertion gets a one-line comment: `// all is written since today became the default landing`.

- [ ] **Step 4: Run — expect PASS**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern communityUrlState`

- [ ] **Step 5: Commit**

```bash
git add src/components/community/lib/communityUrlState.ts src/components/community/lib/communityUrlState.test.ts src/components/community/tandem/CommunitySubNav.tsx
git commit -m "feat(community): today is the URL's left-out default tab; all is written"
```

---

### Task 3: `MatchCard`

**Files:**
- Create: `src/components/community/today/MatchCard.tsx`
- Test: `src/components/community/today/MatchCard.test.tsx`

**Interfaces:**
- Consumes (Task 1): `DailyMatch`, `photoUrl`, `reasonChips`, `repliesFast`, `countryFlag`.
- Produces: `MatchCard: React.FC<{ match: DailyMatch; onWave: (match: DailyMatch) => void; onSkip: (match: DailyMatch) => void }>`. Rendered with test ids `match-card`, `match-card-name`, `match-active-dot`, `match-pair`, `match-reason`, `match-replies-fast`, `match-boosted`, `match-say-hi`, `match-wave`, `match-skip`.

- [ ] **Step 1: Write the failing test** — `src/components/community/today/MatchCard.test.tsx`

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import MatchCard from "./MatchCard";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string, o?: any) => (o && o.defaultValue !== undefined ? o.defaultValue : key), i18n: { language: "en" } }),
}));

const match = {
  user: { _id: "u7", name: "Mina", images: ["https://cdn.x/m.jpg"], native_language: "Korean", language_to_learn: "English", location: { country: "South Korea" } },
  matchReasons: ["reciprocal_pair", "active_today"],
  lastActiveBucket: "today",
  responseRate: 0.8,
  boosted: true,
};

const renderCard = (over: any = {}, handlers: any = {}) =>
  render(
    <MemoryRouter>
      <MatchCard match={{ ...match, ...over } as any} onWave={handlers.onWave || jest.fn()} onSkip={handlers.onSkip || jest.fn()} />
    </MemoryRouter>
  );

describe("MatchCard", () => {
  it("shows who they are and why they matched", () => {
    renderCard();
    expect(screen.getByTestId("match-card-name")).toHaveTextContent("Mina");
    expect(screen.getByTestId("match-card-name")).toHaveTextContent("🇰🇷");
    expect(screen.getByTestId("match-pair")).toHaveTextContent("Korean → English");
    expect(screen.getAllByTestId("match-reason")).toHaveLength(2);
    expect(screen.getByTestId("match-active-dot")).toBeInTheDocument();
    expect(screen.getByTestId("match-replies-fast")).toBeInTheDocument();
    expect(screen.getByTestId("match-boosted")).toBeInTheDocument();
  });

  it("leaves out what does not apply", () => {
    renderCard({ lastActiveBucket: "this_week", responseRate: null, boosted: undefined, matchReasons: [] });
    expect(screen.queryByTestId("match-active-dot")).not.toBeInTheDocument();
    expect(screen.queryByTestId("match-replies-fast")).not.toBeInTheDocument();
    expect(screen.queryByTestId("match-boosted")).not.toBeInTheDocument();
    expect(screen.queryByTestId("match-reason")).not.toBeInTheDocument();
  });

  it("drops an empty side of the language pair", () => {
    renderCard({ user: { ...match.user, language_to_learn: "" } });
    expect(screen.getByTestId("match-pair")).toHaveTextContent(/^Korean$/);
  });

  it("Say hi opens the chat; name and photo open the profile", () => {
    renderCard();
    expect(screen.getByTestId("match-say-hi")).toHaveAttribute("href", "/chat/u7");
    expect(screen.getByTestId("match-profile-link")).toHaveAttribute("href", "/community/u7");
  });

  it("Wave and Skip hand the match to their handlers", () => {
    const onWave = jest.fn();
    const onSkip = jest.fn();
    renderCard({}, { onWave, onSkip });
    fireEvent.click(screen.getByTestId("match-wave"));
    fireEvent.click(screen.getByTestId("match-skip"));
    expect(onWave).toHaveBeenCalledWith(expect.objectContaining({ user: expect.objectContaining({ _id: "u7" }) }));
    expect(onSkip).toHaveBeenCalledWith(expect.objectContaining({ user: expect.objectContaining({ _id: "u7" }) }));
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (module not found)

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "today/MatchCard"`

- [ ] **Step 3: Implement** — `src/components/community/today/MatchCard.tsx`

```tsx
import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { MessageCircle, X } from "lucide-react";
import Avatar from "../../../design/Avatar";
import { DailyMatch } from "./types";
import { countryFlag, photoUrl, reasonChips, repliesFast } from "./dailyMatchView";

const ACTION =
  "inline-flex min-h-[40px] flex-1 items-center justify-center gap-1.5 rounded-chip px-3 text-sm font-semibold transition-colors";

/**
 * One of today's matches, laid out as the app's match card
 * (match_card.dart): who they are, why they matched, and three actions.
 */
const MatchCard: React.FC<{
  match: DailyMatch;
  onWave: (match: DailyMatch) => void;
  onSkip: (match: DailyMatch) => void;
}> = ({ match, onWave, onSkip }) => {
  const { t } = useTranslation();
  const user = match.user;
  const photo = photoUrl(user.images);
  const flag = countryFlag(user.location && user.location.country);
  const pair = [user.native_language, user.language_to_learn].filter((s) => s && s.trim()).join(" → ");
  const reasons = reasonChips(match.matchReasons, user, t);

  return (
    <article
      data-testid="match-card"
      className="rounded-2xl border border-line bg-surface p-4 shadow-card dark:border-line-dark dark:bg-cardbg-dark"
    >
      <div className="flex items-start gap-3">
        <Link to={`/community/${user._id}`} data-testid="match-profile-link" className="shrink-0">
          <Avatar src={photo} name={user.name} size={54} />
        </Link>
        <div className="min-w-0 flex-1">
          <Link
            to={`/community/${user._id}`}
            data-testid="match-card-name"
            className="flex items-center gap-1.5 font-display text-base text-ink-900 hover:underline dark:text-ink-50"
          >
            <span className="truncate">{user.name}</span>
            {flag && <span aria-hidden>{flag}</span>}
            {match.lastActiveBucket === "today" && (
              <span
                data-testid="match-active-dot"
                aria-label={t("communityMain.today.reasonActiveToday") || "Active today"}
                className="h-2 w-2 shrink-0 rounded-full bg-emerald-500"
              />
            )}
          </Link>
          <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
            {pair && (
              <span
                data-testid="match-pair"
                className="rounded-full bg-brand/[0.09] px-2.5 py-0.5 text-xs font-semibold text-brand-dark dark:bg-brand/[0.18] dark:text-brand-light"
              >
                {pair}
              </span>
            )}
            {repliesFast(match.responseRate) && (
              <span data-testid="match-replies-fast" className="rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300">
                {t("communityMain.today.repliesFast") || "Replies fast"}
              </span>
            )}
            {match.boosted && (
              <span data-testid="match-boosted" className="rounded-full bg-banana/25 px-2.5 py-0.5 text-xs font-semibold text-ink-800 dark:bg-banana/15 dark:text-ink-100">
                {t("communityMain.today.boosted") || "Boosted"}
              </span>
            )}
          </div>
        </div>
      </div>

      {reasons.length > 0 && (
        <ul className="mt-3 flex flex-wrap gap-1.5">
          {reasons.map((reason) => (
            <li key={reason} data-testid="match-reason" className="rounded-chip bg-ink-50 px-2.5 py-1 text-xs text-ink-700 dark:bg-white/5 dark:text-ink-200">
              {reason}
            </li>
          ))}
        </ul>
      )}

      <div className="mt-4 flex gap-2">
        <Link to={`/chat/${user._id}`} data-testid="match-say-hi" className={`${ACTION} bg-brand-deep text-white hover:bg-brand-dark`}>
          <MessageCircle className="h-4 w-4" aria-hidden />
          {t("communityMain.today.sayHi") || "Say hi"}
        </Link>
        <button type="button" data-testid="match-wave" onClick={() => onWave(match)} className={`${ACTION} border border-line text-ink-800 hover:bg-ink-50 dark:border-line-dark dark:text-ink-100 dark:hover:bg-white/5`}>
          <span aria-hidden>👋</span>
          {t("communityMain.today.wave") || "Wave"}
        </button>
        <button type="button" data-testid="match-skip" onClick={() => onSkip(match)} className={`${ACTION} text-ink-500 hover:bg-ink-50 dark:text-ink-400 dark:hover:bg-white/5`}>
          <X className="h-4 w-4" aria-hidden />
          {t("communityMain.today.skip") || "Skip"}
        </button>
      </div>
    </article>
  );
};

export default MatchCard;
```

- [ ] **Step 4: Run — expect PASS**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "today/MatchCard"`

- [ ] **Step 5: Commit**

```bash
git add src/components/community/today/MatchCard.tsx src/components/community/today/MatchCard.test.tsx
git commit -m "feat(community): MatchCard -- who, why, and Say hi / Wave / Skip"
```

---

### Task 4: `TodayTab` — header, list, skips, empty, error, rollover

**Files:**
- Create: `src/components/community/today/TodayTab.tsx`
- Test: `src/components/community/today/TodayTab.test.tsx`

**Interfaces:**
- Consumes:
  - Task 1: `DailyMatchesResponse`, `refreshTimeLabel`, `loadSkips`, `addSkip`, `useSkipUserMutation`;
  - Task 3: `MatchCard`.
- Produces:

  ```ts
  TodayTab: React.FC<{
    response?: DailyMatchesResponse;
    isLoading: boolean;
    isError: boolean;
    onRetry: () => void;
    onWave: (match: DailyMatch) => void;
    onBrowse: () => void;
  }>
  ```

  Test ids: `today-tab`, `today-title`, `today-refresh`, `today-skeleton`, `today-empty`, `today-browse`, `today-error`, `today-retry`.

- [ ] **Step 1: Write the failing test** — `src/components/community/today/TodayTab.test.tsx`

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import TodayTab from "./TodayTab";

const mockSkip = jest.fn();
jest.mock("../../../store/slices/communitySlice", () => ({
  useSkipUserMutation: () => [mockSkip, { isLoading: false }],
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, o?: any) => (o ? `${key}|${JSON.stringify(o)}` : key),
    i18n: { language: "en" },
  }),
}));

const m = (id: string) => ({
  user: { _id: id, name: `N${id}`, images: [], native_language: "Korean", language_to_learn: "English" },
  matchReasons: [], responseRate: null,
});
const response = (over: any = {}) => ({
  success: true, date: "2026-10-08", nextRefreshAt: "2026-10-09T00:00:00.000Z",
  matches: [m("a"), m("b"), m("c")], ...over,
});

const renderTab = (props: any = {}) =>
  render(
    <MemoryRouter>
      <TodayTab response={response()} isLoading={false} isError={false} onRetry={jest.fn()} onWave={jest.fn()} onBrowse={jest.fn()} {...props} />
    </MemoryRouter>
  );

beforeEach(() => {
  window.sessionStorage.clear();
  mockSkip.mockReturnValue({ unwrap: () => Promise.resolve({}) });
});

describe("TodayTab", () => {
  it("titles the batch with its size and says when it refreshes", () => {
    renderTab();
    expect(screen.getByTestId("today-title")).toHaveTextContent('communityMain.today.title|{"count":3}');
    expect(screen.getByTestId("today-refresh")).toHaveTextContent("communityMain.today.refreshes");
    expect(screen.getAllByTestId("match-card")).toHaveLength(3);
  });

  it("falls back to 'at midnight' without a refresh time", () => {
    renderTab({ response: response({ nextRefreshAt: undefined }) });
    expect(screen.getByTestId("today-refresh")).toHaveTextContent("communityMain.today.refreshesMidnight");
  });

  it("Skip removes the card, posts the skip, and the count follows", () => {
    renderTab();
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    expect(screen.getAllByTestId("match-card")).toHaveLength(2);
    expect(mockSkip).toHaveBeenCalledWith("a");
    expect(screen.getByTestId("today-title")).toHaveTextContent('{"count":2}');
  });

  it("a failed skip keeps the card gone", async () => {
    mockSkip.mockReturnValue({ unwrap: () => Promise.reject(new Error("nope")) });
    renderTab();
    await act(async () => { fireEvent.click(screen.getAllByTestId("match-skip")[0]); });
    expect(screen.getAllByTestId("match-card")).toHaveLength(2);
  });

  it("skips survive a remount within the same batch date", () => {
    const first = renderTab();
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    first.unmount();
    renderTab();
    expect(screen.getAllByTestId("match-card")).toHaveLength(2);
  });

  it("a new batch date brings everyone back", () => {
    const first = renderTab();
    fireEvent.click(screen.getAllByTestId("match-skip")[0]);
    first.unmount();
    renderTab({ response: response({ date: "2026-10-09" }) });
    expect(screen.getAllByTestId("match-card")).toHaveLength(3);
  });

  it("shows the empty state after the last skip, and Browse partners asks for All", () => {
    const onBrowse = jest.fn();
    renderTab({ response: response({ matches: [m("a")] }), onBrowse });
    fireEvent.click(screen.getByTestId("match-skip"));
    expect(screen.getByTestId("today-empty")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("today-browse"));
    expect(onBrowse).toHaveBeenCalled();
  });

  it("an empty batch is the empty state too", () => {
    renderTab({ response: response({ matches: [] }) });
    expect(screen.getByTestId("today-empty")).toBeInTheDocument();
  });

  it("shows a skeleton while loading and an error with retry on failure", () => {
    const { unmount } = renderTab({ response: undefined, isLoading: true });
    expect(screen.getByTestId("today-skeleton")).toBeInTheDocument();
    unmount();
    const onRetry = jest.fn();
    renderTab({ response: undefined, isError: true, onRetry });
    fireEvent.click(screen.getByTestId("today-retry"));
    expect(onRetry).toHaveBeenCalled();
  });

  it("Wave hands the match up to the page", () => {
    const onWave = jest.fn();
    renderTab({ onWave });
    fireEvent.click(screen.getAllByTestId("match-wave")[1]);
    expect(onWave).toHaveBeenCalledWith(expect.objectContaining({ user: expect.objectContaining({ _id: "b" }) }));
  });

  it("refetches once when the clock passes nextRefreshAt", () => {
    jest.useFakeTimers();
    const now = new Date("2026-10-08T23:59:00.000Z").getTime();
    jest.setSystemTime(now);
    const onRetry = jest.fn();
    renderTab({ onRetry });
    act(() => { jest.advanceTimersByTime(61 * 1000); });
    expect(onRetry).toHaveBeenCalledTimes(1);
    jest.useRealTimers();
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (module not found)

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "today/TodayTab"`

- [ ] **Step 3: Implement** — `src/components/community/today/TodayTab.tsx`

```tsx
import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { RefreshCw, Sparkles } from "lucide-react";
import MatchCard from "./MatchCard";
import { DailyMatch, DailyMatchesResponse } from "./types";
import { refreshTimeLabel } from "./dailyMatchView";
import { addSkip, loadSkips } from "./todaySkips";
import { useSkipUserMutation } from "../../../store/slices/communitySlice";

/**
 * Today's matches: the server's batch for this UTC day (GET /matching/daily),
 * as the app's Matches tab shows it. The batch is the server's choice, so
 * there is nothing here to filter or search.
 */
const TodayTab: React.FC<{
  response?: DailyMatchesResponse;
  isLoading: boolean;
  isError: boolean;
  onRetry: () => void;
  onWave: (match: DailyMatch) => void;
  onBrowse: () => void;
}> = ({ response, isLoading, isError, onRetry, onWave, onBrowse }) => {
  const { t, i18n } = useTranslation();
  const [skipUser] = useSkipUserMutation();
  const date = (response && response.date) || "";
  const [skipped, setSkipped] = useState<string[]>(() => (date ? loadSkips(date) : []));

  // A new batch (midnight rollover) starts clean; the same date re-reads what
  // this session already skipped.
  useEffect(() => {
    setSkipped(date ? loadSkips(date) : []);
  }, [date]);

  // Roll over once the batch's refresh moment passes while the tab is open:
  // one timer for that moment, plus a check on focus for a laptop that slept
  // through it. Re-armed whenever nextRefreshAt changes; cleared on unmount.
  const nextRefreshAt = response && response.nextRefreshAt;
  useEffect(() => {
    if (!nextRefreshAt) return undefined;
    const at = new Date(nextRefreshAt).getTime();
    if (isNaN(at)) return undefined;
    let fired = false;
    const fire = () => {
      if (fired || Date.now() < at) return;
      fired = true;
      onRetry();
    };
    const timer = window.setTimeout(fire, Math.max(0, at - Date.now()) + 1000);
    window.addEventListener("focus", fire);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("focus", fire);
    };
  }, [nextRefreshAt, onRetry]);

  const visible = useMemo(
    () => ((response && response.matches) || []).filter((m) => m && m.user && m.user._id && skipped.indexOf(m.user._id) === -1),
    [response, skipped]
  );

  const handleSkip = (match: DailyMatch) => {
    const id = match.user._id;
    setSkipped(date ? addSkip(date, id) : (prev: string[]) => prev.concat([id]) as any);
    // Fire-and-forget, as the app does: the card is gone either way.
    skipUser(id).unwrap().catch(() => {});
  };

  if (isLoading && !response) {
    return (
      <div data-testid="today-skeleton" aria-busy="true" className="space-y-3 py-2">
        {[0, 1, 2].map((i) => (
          <div key={i} className="h-36 animate-pulse rounded-2xl bg-ink-100 dark:bg-white/5" />
        ))}
      </div>
    );
  }

  if (isError && !response) {
    return (
      <div data-testid="today-error" className="community-empty">
        <p>{t("communityMain.today.error") || "We couldn't load today's matches"}</p>
        <button type="button" data-testid="today-retry" onClick={onRetry} className="community-empty__action">
          <RefreshCw className="h-4 w-4" aria-hidden />
          {t("communityMain.today.retry") || "Try again"}
        </button>
      </div>
    );
  }

  const refresh = refreshTimeLabel(nextRefreshAt, i18n.language);

  if (visible.length === 0) {
    return (
      <div data-testid="today-empty" className="community-empty">
        <Sparkles className="community-empty__icon" aria-hidden />
        <h3>{t("communityMain.today.emptyTitle") || "That's everyone for today"}</h3>
        <p>{t("communityMain.today.emptyBody") || "Fresh matches tomorrow. Meanwhile, browse all partners."}</p>
        <button type="button" data-testid="today-browse" onClick={onBrowse} className="community-empty__action">
          {t("communityMain.today.browse") || "Browse partners"}
        </button>
      </div>
    );
  }

  return (
    <div data-testid="today-tab" className="py-2">
      <div className="pb-3">
        <h2 data-testid="today-title" className="font-display text-xl text-ink-900 dark:text-ink-50">
          {t("communityMain.today.title", { count: visible.length })}
        </h2>
        <p data-testid="today-refresh" className="text-sm text-ink-500 dark:text-ink-400">
          {refresh
            ? t("communityMain.today.refreshes", { time: refresh })
            : t("communityMain.today.refreshesMidnight")}
        </p>
      </div>
      <div className="grid gap-3 md:grid-cols-2">
        {visible.map((match) => (
          <MatchCard key={match.user._id} match={match} onWave={onWave} onSkip={handleSkip} />
        ))}
      </div>
    </div>
  );
};

export default TodayTab;
```

- [ ] **Step 4: Run — expect PASS**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "today/TodayTab"`

- [ ] **Step 5: Commit**

```bash
git add src/components/community/today/TodayTab.tsx src/components/community/today/TodayTab.test.tsx
git commit -m "feat(community): TodayTab -- the day's batch, skips that last, rollover"
```

---

### Task 5: `MainCommunity` integration, copy, link audit, suite rework

**Files:**
- Modify:
  - `src/components/community/MainCommunity.tsx`:
    - `listState` default + `forYouWithoutFilters` (~lines 199-224);
    - `activeTab` / `isForYou` (~226-227);
    - `writeUrl` (~302-317);
    - `applyState` base + the canonical effect (~326-363);
    - the members/recommendations query skips (~424-433);
    - the sub-nav props (~814-834);
    - the tab render (~869);
    - `handleWaveMember` (~783).
  - `src/components/community/tandem/CommunitySubNav.tsx` — the Today button and a `showToday` prop.
  - `src/components/profile/parts/SuggestedMembers.tsx:83` — `to="/communities?tab=all"`.
  - All 18 `src/utils/locales/*.json` (`communityMain.today.*` + `communityMain.tabs.today`).
- Test:
  - `src/components/community/MainCommunityTabs.test.tsx`, `communityPerf.test.tsx`, `MainCommunityUrlState.test.tsx` — rework their default render path;
  - create `src/components/community/today/todayIntegration.test.tsx`.

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: `CommunitySubNav` prop `showToday?: boolean`, default `false`.

- [ ] **Step 1: Rework existing suites to name their tab.** In each of these files, change the `renderList` default from `["/communities"]` to `["/communities?tab=all"]`:
  - `MainCommunityTabs.test.tsx:112`
  - `communityPerf.test.tsx:158`
  - `MainCommunityUrlState.test.tsx:91`

  Their bare-URL assumption was "bare = All", which this change ends. Then run:

  ```bash
  CI=true npx react-scripts test --watchAll=false --testPathPattern "MainCommunity|communityPerf"
  ```

  Expected: PASS, since nothing has changed in the code yet. Where an existing assertion expects an empty `location.search` after selecting All, change it to `?tab=all`, with the comment `// all is written since today became the default landing`.

- [ ] **Step 2: Write the failing integration test** — `src/components/community/today/todayIntegration.test.tsx`

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { createMemoryRouter, createRoutesFromElements, Route, RouterProvider } from "react-router-dom";
import { makeStore } from "../../../store";
import MainCommunity from "../MainCommunity";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string, o?: any) => (o ? `${key} ${Object.values(o).join(" ")}` : key), i18n: { language: "en" } }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));
jest.mock("../PublicCommunities", () => ({ __esModule: true, default: () => <div data-testid="public-communities" /> }));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn(), warning: jest.fn(), show: jest.fn(), dismiss: jest.fn() },
}));

const SIGNED_IN = { auth: { userInfo: { user: { _id: "u1", native_language: "English", language_to_learn: "Korean" }, token: "t" } } };
const daily = {
  success: true, date: "2026-10-08", nextRefreshAt: "2026-10-09T00:00:00.000Z",
  matches: [{ user: { _id: "d1", name: "Daily One", images: [], native_language: "Korean", language_to_learn: "English" }, matchReasons: ["reciprocal_pair"], responseRate: null }],
};
const requested: string[] = [];
const originalFetch = global.fetch;
let dailyStatus = 200;

beforeEach(() => {
  requested.length = 0;
  dailyStatus = 200;
  window.sessionStorage.clear();
  (global as any).IntersectionObserver = class { observe() {} disconnect() {} unobserve() {} };
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requested.push(url);
    let status = 200;
    let body: any = { success: true, data: [] };
    if (url.indexOf("/matching/daily") >= 0) {
      status = dailyStatus;
      body = dailyStatus === 200 ? daily : { success: false, error: "Not found" };
    } else if (/\/auth\/users\?/.test(url)) {
      body = { success: true, total: 1, pages: 1, data: [{ _id: "m1", name: "Listed Member", native_language: "Korean", language_to_learn: "English", imageUrls: [] }] };
    }
    return Promise.resolve(new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } }));
  });
});
afterEach(() => { global.fetch = originalFetch; });

function renderAt(path: string, state: any = SIGNED_IN) {
  const router = createMemoryRouter(
    createRoutesFromElements(<Route path="/communities" element={<MainCommunity />} />),
    { initialEntries: [path] }
  );
  render(<Provider store={makeStore(state)}><RouterProvider router={router} /></Provider>);
  return router;
}

describe("Today on /communities", () => {
  it("lands a signed-in member on Today, and asks for the batch rather than the list", async () => {
    renderAt("/communities");
    expect(await screen.findByText("Daily One")).toBeInTheDocument();
    expect(requested.some((u) => u.indexOf("/matching/daily") >= 0)).toBe(true);
    expect(requested.some((u) => /\/auth\/users\?/.test(u))).toBe(false);
  });

  it("?tab=all still opens All", async () => {
    renderAt("/communities?tab=all");
    expect(await screen.findByText("Listed Member")).toBeInTheDocument();
  });

  it("old filtered links land on All and keep their params", async () => {
    const router = renderAt("/communities?native=Korean");
    expect(await screen.findByText("Listed Member")).toBeInTheDocument();
    expect(router.state.location.search).toContain("native=Korean");
  });

  it("feature off (404): shows All, hides the Today button, leaves the address bar alone", async () => {
    dailyStatus = 404;
    const router = renderAt("/communities");
    expect(await screen.findByText("Listed Member")).toBeInTheDocument();
    expect(screen.queryByTestId("subnav-tab-today")).not.toBeInTheDocument();
    expect(router.state.location.search).toBe("");
  });

  it("Today hides filters, search and the carousel, and writes no filter params", async () => {
    const router = renderAt("/communities");
    await screen.findByText("Daily One");
    expect(screen.queryByTestId("subnav-search")).not.toBeInTheDocument();
    expect(screen.queryByTestId("subnav-filters")).not.toBeInTheDocument();
    expect(router.state.location.search).toBe("");
  });

  it("Browse partners switches to All, written into the URL", async () => {
    const router = renderAt("/communities");
    await screen.findByText("Daily One");
    fireEvent.click(screen.getByTestId("match-skip"));
    fireEvent.click(await screen.findByTestId("today-browse"));
    await waitFor(() => expect(router.state.location.search).toBe("?tab=all"));
  });

  it("Wave opens the wave sheet for that person", async () => {
    renderAt("/communities");
    await screen.findByText("Daily One");
    fireEvent.click(screen.getByTestId("match-wave"));
    expect(await screen.findByRole("dialog")).toBeInTheDocument();
  });
});
```

Before running it, read `CommunitySubNav.tsx` for its real search, filter-button and tab-button test ids, and use those exact names in this file. The values above (`subnav-search`, `subnav-filters`, `subnav-tab-today`) are the convention the file is expected to follow. If they differ, record a ledger ruling and substitute the real ids. The new Today button gets `data-testid="subnav-tab-today"` in Step 3 in any case.

- [ ] **Step 3: Run — expect FAIL**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern todayIntegration`

- [ ] **Step 4: Implement in `CommunitySubNav.tsx`**

- Add a `showToday?: boolean` prop, default `false`.
- Prepend a Today entry to `IN_PAGE_TABS`:

  ```tsx
  { id: "today", copyKey: "communityMain.tabs.today", fallback: "Today", Icon: CalendarHeart },
  ```

  `CalendarHeart` comes from `lucide-react`; if that icon does not exist in the installed version, use `Heart`.
- In the tab render loop, skip `id === "today"` when `!showToday`.
- Make sure each tab button carries `data-testid={\`subnav-tab-${id}\`}`. Add it if the loop has no test id yet.

- [ ] **Step 5: Implement in `MainCommunity.tsx`**

1. Imports:

   ```tsx
   import { useGetDailyMatchesQuery } from "../../store/slices/communitySlice";
   import TodayTab from "./today/TodayTab";
   import { DailyMatch } from "./today/types";
   import { photoUrl } from "./today/dailyMatchView";
   ```

   Add `useGetDailyMatchesQuery` to the existing `communitySlice` import instead of a second import line, if that import already exists.

2. In `listState`:
   - Compute the default tab: `const carriesList = decoded.filters !== undefined || decoded.search !== undefined || decoded.sort !== undefined;` then `const tab = decoded.tab || (carriesList ? "all" : "today");`.
   - Extend the For You special case to Today: `const serverPickedWithoutFilters = (tab === "foryou" || tab === "today") && decoded.filters === undefined;`. Use it where `forYouWithoutFilters` was, and keep the comment, mentioning Today.
   - Return `tab` (instead of `decoded.tab || "all"`).

3. After `listState` (before `const activeTab`):

   ```tsx
   const userInfoForToday = useSelector((state: RootState) => state.auth.userInfo);
   const signedIn = Boolean(userInfoForToday && (userInfoForToday as any).user && (userInfoForToday as any).user._id);
   const urlTab: CommunityNavTab = listState.tab;
   const {
     data: dailyData,
     isLoading: dailyLoading,
     error: dailyError,
     refetch: refetchDaily,
   } = useGetDailyMatchesQuery(undefined, { skip: !signedIn });
   // 404 = DAILY_MATCHES_ENABLED is off: the feature is not here, not an error.
   const todayOff = !signedIn || (dailyError as any)?.status === 404;
   // Display-only fallback: the URL keeps saying today; the page shows All.
   const activeTab: CommunityNavTab = urlTab === "today" && todayOff ? "all" : urlTab;
   const isToday = activeTab === "today";
   ```

   Remove the old `const activeTab: CommunityNavTab = listState.tab;`. If a later `const userInfo = useSelector(...)` already exists, reuse it by moving it above this block, rather than adding a second selector.

4. In `writeUrl`, change `next.tab === "foryou" ? { ...next, filters: {} } : next` to `next.tab === "foryou" || next.tab === "today" ? { ...next, filters: {} } : next`, and update its comment.

5. The canonical effect writes the **URL-derived** tab:

   ```tsx
   useEffect(() => {
     writeUrl({ filters, search, sort, tab: urlTab });
   }, [filters, search, sort, urlTab, writeUrl]);
   ```

   `applyState` keeps `tab: activeTab` (the displayed tab), per the spec.

6. Query skips:
   - members: `useGetCommunityMembersQuery(queryArg, { skip: isForYou || isToday })`;
   - recommendations: unchanged.

7. Sub-nav props:
   - `showToday={signedIn && !todayOff}`;
   - `showFilterButton={!isForYou && !isToday}`;
   - `showSearch={!isForYou && !isToday}`.

8. Render: before the `isForYou ? (<ForYouTab .../>)` branch, add:

   ```tsx
   isToday ? (
     <TodayTab
       response={dailyData as any}
       isLoading={dailyLoading}
       isError={Boolean(dailyError)}
       onRetry={refetchDaily}
       onWave={handleWaveDaily}
       onBrowse={() => applyState({ tab: "all" })}
     />
   ) :
   ```

   The existing `isForYou ? ... : ...` chain stays after it.

9. Next to `handleWaveMember`:

   ```tsx
   // WaveSheet reads its avatar from imageUrls[0]; daily users carry raw images.
   const handleWaveDaily = useCallback((match: DailyMatch) => {
     const photo = photoUrl(match.user.images);
     setWaveTarget({ ...(match.user as any), imageUrls: photo ? [photo] : [] });
   }, []);
   ```

10. Anywhere else that compares `activeTab === "all"` for highlights or visitors keeps doing so, since those only belong on All.

- [ ] **Step 6: Point "browse everyone" at All.** In `src/components/profile/parts/SuggestedMembers.tsx:83`, change `to="/communities"` to `to="/communities?tab=all"`. If its test asserts the href, update that test too.

- [ ] **Step 7: Add the copy.** Run the prepared table (`scratchpad/today_copy.py`, 18 locales × 19 keys) through this writer, from the web repo root:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front/src/utils/locales && python3 - <<'PY'
import json, collections, runpy
ns = runpy.run_path("/private/tmp/claude-501/-Users-davis-Desktop-Personal-language-exchange-web-front/f4ebb588-39a1-4eba-864f-de64536f9fd1/scratchpad/today_copy.py")
KEYS, T = ns["KEYS"], ns["T"]
for name, vals in T.items():
    f = f"{name}.json"
    d = json.load(open(f), object_pairs_hook=collections.OrderedDict)
    cm = d["communityMain"]
    block = collections.OrderedDict(zip(KEYS, vals))
    cm.setdefault("tabs", collections.OrderedDict())["today"] = block.pop("tab")
    cm["today"] = block
    open(f, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print("ok")
PY
```

- [ ] **Step 8: Run the integration test and the community suites — expect PASS**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
CI=true npx react-scripts test --watchAll=false --testPathPattern "todayIntegration|today/|MainCommunity|communityPerf|communityUrlState|SuggestedMembers|localeParity"
```

- [ ] **Step 9: Pin the Today mount budget** — append to `communityPerf.test.tsx`. That file's own `renderList`, `requestedUrls` and fetch mock are reused; extend the mock to answer `/matching/daily` with `{ success: true, date: "2026-10-08", matches: [] }` if it does not already.

```tsx
describe("what the Today landing costs", () => {
  // Today is the default landing: it asks for the day's batch and NOT for the
  // All list, which waits until the member switches tabs.
  it("asks for /matching/daily once and never for /auth/users", async () => {
    renderList(["/communities"]);
    await waitFor(() => expect(requestedUrls.filter((u) => u.indexOf("/matching/daily") >= 0)).toHaveLength(1));
    expect(requestedUrls.filter((u) => /\/auth\/users\?/.test(u))).toHaveLength(0);
  });
});
```

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern communityPerf`. Expected: PASS.

- [ ] **Step 10: Full suite and build**

```bash
CI=true npx react-scripts test --watchAll=false 2>&1 | tail -5
npx react-scripts build 2>&1 | grep -E "Failed|Compiled|rror"
```

Expected: all suites pass; "Compiled with warnings."

- [ ] **Step 11: Commit**

```bash
git add src/components/community src/components/profile/parts/SuggestedMembers.tsx src/components/profile/parts/SuggestedMembers.test.tsx src/utils/locales
git commit -m "feat(community): Today's matches is the default landing on /communities

Signed-in members open /communities on Today: the day's batch from
GET /matching/daily with Say hi / Wave / Skip, as the app's Matches tab.
today is the URL's left-out default and all is written explicitly; an absent
tab on a URL that carries filters, search or sort still means All, so links
shared before this keep their filters. When the endpoint answers 404
(DAILY_MATCHES_ENABLED off) or nobody is signed in, the page shows All while
the address bar keeps what it said, and the Today button is hidden. Today
writes no filter params, like For you. SuggestedMembers' see-more points at
?tab=all. Copy in all 18 locales."
```

---

## After all tasks

Run the final review: a fresh reviewer over `git merge-base main HEAD..HEAD`. Then merge, push, and verify the deploy:

```bash
git checkout main && git pull --ff-only && git merge --no-ff feat/todays-matches -m "Merge feat/todays-matches: Today's matches on the web" && git branch -d feat/todays-matches && git push origin main
gh run watch "$(gh run list --workflow deploy.yml --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
curl -s -o /dev/null -L -w "%{http_code}\n" https://banatalk.com/communities   # expect 200
```
