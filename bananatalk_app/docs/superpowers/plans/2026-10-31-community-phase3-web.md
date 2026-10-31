# Community optimization — Phase 3 web Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** banatalk.com's Community matches the app: tabs Matches · Partners · Gatherings · Rooms (already so); Same city / Women / Men / Topic become Partners chips (City, Genders and Topics pages go); Waves gets a header icon with a badge; one paging hook replaces four; the audit's web bugs are gone.

**Architecture:** One `usePagedList` hook (`currentData` + a key check, server `hasMore`, pages kept in a small in-memory cache so Back restores them) used by the Partners list and Waves. Chips extend `CommunityFilters` (`sameCity`, quick `gender`, quick `topic`) and the URL state, so links still work. Old routes redirect.

**Tech Stack:** React 18, RTK Query (@reduxjs/toolkit 2.2.5 — no upgrade), react-router 6, Tailwind/SCSS, Jest via react-scripts.

**Spec:** `bananatalk_app/docs/REMAINING_WORK.md` → "Community optimization" → "Phase 3 — Web" (bug list with file:line) and the owner decisions above it.

## Global Constraints

- Worktree: `git -C /Users/davis/Desktop/Personal/language_exchange_web_front worktree add ../wt-web-community-p3 -b feat/community-p3 origin/main`; `npm ci` (or symlink `node_modules` from the main checkout).
- **Never push `main`** — a web main push deploys banatalk.com, and another session also pushes main (always merge, never overwrite). Push the branch only.
- Tests: `CI=true npx react-scripts test --watchAll=false <paths>`; before the last commit `CI=true npx react-scripts test --watchAll=false src/components/community src/router src/store` and `npm run build` (bundle-budget test included).
- Backend contract (live, cc5064b): `/users` accepts `sameCity=true`, `joinedWithin=7d`, returns `hasMore`.
- New i18n keys go through the repo's existing `scripts/i18n/keys/*.json` flow (one new file `2026-10-31-p3-community.json`), all locales filled.
- Each commit updates the web repo `docs/REMAINING_WORK.md` (new "Community optimization phase 3" section) and lists open items in the body. No `Co-Authored-By` trailer.

## Review Focus

1. A pasted old link (`/community/city?...`, `/community/genders`, `/topics`) must land on Partners with the matching chip, not a 404 — Task 4 test.
2. Switching filters back and forth (A → B → A after > 5 s) must never mix B's members into A — Task 1 test.
3. A failed page 3 keeps pages 1–2 and the sub-nav on screen with an inline Retry — Task 1 test.
4. Back from a profile restores the loaded pages (no jump to page 1, no sessionStorage hack) — Task 1 test.
5. Signed-out visitors opening `/community/nearby`, `/waves` are sent to sign in, never shown "nobody nearby" — Task 5 test.

---

### Task 1: `usePagedList` + Partners list on it

**Files:**
- Create: `src/components/community/lib/usePagedList.ts`, test `usePagedList.test.tsx`
- Modify: `src/components/community/MainCommunity.tsx` (~:455-635: `pager`, `extraPages`, the merge effect, `allMembers` re-sort, the sessionStorage scroll code; ~:893-907 early error return)

**Interfaces:**
- Produces:
  ```ts
  export function usePagedList<T extends { _id: string }, A>(args: {
    key: string;                       // the question; a new key starts at page 1
    argFor: (page: number) => A;
    useQuery: (arg: A, opts: { skip?: boolean; refetchOnFocus?: boolean }) =>
      { currentData?: unknown; isFetching: boolean; isError: boolean; error?: unknown; refetch: () => void };
    items: (data: unknown) => T[];
    hasMore: (data: unknown, page: number) => boolean; // server hasMore, else page < pages
    skip?: boolean;
  }): { items: T[]; initialLoading: boolean; loadingMore: boolean;
        firstPageError?: unknown; pageError?: unknown; hasMore: boolean;
        loadMore(): void; retry(): void };
  ```
  Pages live in a module-level `Map<string, {pages: T[][], hasMore: boolean}>` (max 5 keys, LRU) so a remount with the same key renders every loaded page at once.

- [ ] **Step 1:** Hook tests with a fake `useQuery` (renderHook):
  - `key change resets to page 1 and never mixes`: load A p1+p2, switch to B, switch back to A after `jest.advanceTimersByTime(6000)` while the fake returns B's data as `data` but `currentData` undefined → items are only A's.
  - `server hasMore wins`: body `{hasMore:false, pages:5}` → `hasMore === false`.
  - `page error keeps rows`: p3 errors → `items.length` = p1+p2, `pageError` set, `retry()` refetches p3.
  - `remount restores pages`: unmount after p2, remount with the same key → 2 pages of items synchronously.
- [ ] **Step 2:** Run — FAIL (module missing).
- [ ] **Step 3:** Implement; MainCommunity uses it for the `/users` views (All, Serious, Online, New); delete the client VIP/online re-sort, the `communityScroll` sessionStorage code and the early error return — errors render inline under the sub-nav (first page: error panel with Retry; page N: "Couldn't load more · Retry" at the foot).
- [ ] **Step 4:** Run hook tests + `src/components/community/communityPaging.test.tsx`, `MainCommunity*.test.tsx` (update assertions that relied on the re-sort or full-page error) — PASS.
- [ ] **Step 5:** Commit `fix(community): one paging hook for the Partners list — no mixed pages, inline errors, Back restores`.

### Task 2: Waves — header icon, own tag, error state

**Files:** `src/store/slices/apiSlice.ts` (add tag `"Waves"`), `communitySlice.ts` (`getWaves` provides `"Waves"`; `sendWave`/`markWavesRead` invalidate `"Waves"` only, not `"Community"`), `Waves.tsx` (error branch with Retry; paging via `usePagedList`), `tandem/CommunitySubNav.tsx` (waves icon link `/waves` with unread badge from `useGetWavesQuery({ unreadOnly: true, limit: 1 })`'s `unreadCount`), `MemberCard`/list: pass `wavedIds` to every view so a waved card shows "Waved".
- [ ] **Step 1:** Tests: sending a wave does not refetch `getCommunityMembers` (spy on the endpoint's `initiate` count via store); Waves shows the error panel on a 500; sub-nav shows "3" when `unreadCount: 3`.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS + `Waves.test.tsx`, `WaveSheet.test.tsx`.
- [ ] **Step 5:** Commit `fix(community): waves get their own cache tag, an error state and a header badge`.

### Task 3: Partners chips — Same city, Women, Men, Topic; Nearby link

**Files:**
- `lib/buildCommunityQuery.ts`: `CommunityFilters` + `sameCity?: boolean` → `sameCity=true`.
- `lib/communityUrlState.ts`: new URL keys `city=1`, `g=f|m`, `topic=<id>` (append to `URL_KEYS`; old keys unchanged).
- `tandem/CommunitySubNav.tsx`: the `IN_PAGE_TABS` row gets chips after New: Nearby (a `Link` to `/community/nearby`, as today), Same city, Women, Men, Topic ▾ (popover listing `useGetTopicsQuery` topics); the City / Genders / Topics icon links are removed.
- `CommunityFilterSheet.tsx`: the count uses the same `buildCommunityQuery` input as the list incl. chips and the refreshed `/auth/me` languages (fixes the stale-languages count); lock hint says the right tab (~:198-207).
- [ ] **Step 1:** Tests: `buildCommunityQuery({sameCity:true})` has `sameCity=true`; URL round-trip `city=1&g=f&topic=music`; tapping Women sets `g=f` and the list query has `gender=female`; lock hint on Serious says "Serious learners".
- [ ] **Step 2:** FAIL. **Step 3:** Implement (new i18n keys `communityMain.tabs.sameCity`, `.women`, `.men`, `.topic`). **Step 4:** PASS + `CommunitySubNav.test.tsx`, `CommunityFilterSheet.test.tsx`, `communityUrlState.test.ts`.
- [ ] **Step 5:** Commit `feat(community): Same city, Women, Men and Topic chips on Partners`.

### Task 4: City, Genders, Topics pages go; old links redirect

**Files:** `src/router/routes.tsx` (`community/city` → `<Navigate replace to="/communities?city=1">` keeping a `?q` city search as `search`; `community/genders` → `/communities?g=f`; `topics` → `/communities?topic=<first topic param>` or `/communities`), delete `cityGenders/*`, `Topics.tsx` + their tests, `useGetUsersByTopicQuery` if unused; `AppOnlyTab.tsx:30-31` `<Navigate replace>`; `routes.test.tsx` updated.
- [ ] **Step 1:** Tests: `/community/city` → `/communities?city=1`; `/community/genders` → `/communities?g=f`; `/topics` → `/communities`; AppOnlyTab redirect uses replace (history length unchanged).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS + `routes.test.tsx`, `subnavLinks` replacement.
- [ ] **Step 5:** Commit `refactor(community): City, Genders and Topics pages become chips; old links redirect`.

### Task 5: Signed-out, empty-vs-error, a11y

**Files:** `routes.tsx` (`community/nearby`, `waves` wrapped in `RequireSignIn`), `NearbyUsers.tsx:89` (error branch + Retry), `HighlightedProfilesCarousel.tsx` (`onTryPro` → navigate `/settings/vip`; show only when there are VIPs, no fillers), add `public/default-avatar.svg` and point MainNavbar.tsx:279, MomentDetail, ChatContent and the carousel at it, `usersSlice.ts:285,294` block/unblock invalidate `"Community"` + `"Recommendations"`, `getDailyMatches` provides/invalidated by block, `CommunitySubNav.tsx:169` arrow-key roving focus + labelled search input, `MemberCard.tsx` no nested button (the card is a link-styled `div` with the wave `button` beside it), i18n the "New" badge and "Wave at …", `WaveSheet` Escape + focus trap.
- [ ] **Step 1:** Tests: signed-out `/community/nearby` renders the sign-in redirect; Nearby 500 shows error not "No users found"; ArrowRight moves focus to the next tab; Escape closes WaveSheet; blocking a user invalidates `Community` (store tag spy).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS + `NearbyUsers.test.tsx`, `MemberCard.test.tsx`, `WaveSheet.test.tsx`.
- [ ] **Step 5:** Commit `fix(community): sign-in gates, error states, keyboard access, block refresh`.

### Task 6: Performance

**Files:** one `useAppConfig()` hook wrapping `useGetAppConfigQuery({ platform: "web", lang })` used by MainCommunity.tsx:486, Waves.tsx:66 and webFlags.ts:53 (one cache entry, no waterfall); visitors query skipped unless `activeTab === "all"`; topics query only when a topic chip/label is shown; filter sheet resets its debounced value on open (no stale first count) and search debounced once (drop the 250 ms URL debounce or the 300 ms query one — keep 300 ms); `React.lazy` for `CommunityFilterSheet` and `WaveSheet` mounted only while open; drop `backdrop-blur-*` on MemberCard:133 and Nearby rows; `loading="lazy"` + width/height on Nearby/Waves/WaveSheet/carousel avatars.
- [ ] **Step 1:** Tests (extend `communityPerf.test.tsx`): one app-config request for the page; no visitors request on Online; the filter sheet chunk is not in the initial render; opening the sheet fires one count request.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS + `npm run build` within the bundle budget.
- [ ] **Step 5:** Commit `perf(community): one app-config request, lazy sheets, fewer requests and repaints`.

### Task 7: Dead code, docs, push

- [ ] **Step 1:** Delete `generateRandomStats`, `getLanguageFlag` (and its test), unused exports in `community/type.ts`, `todayOff`'s `!signedIn` branch, the ~25 unused selectors in `tandem/tandem-community.scss` (grep each class in `src` first); City/Genders no longer use `webLanguageRoomsEnabled`.
- [ ] **Step 2:** Full community/router/store tests + `npm run build` — PASS.
- [ ] **Step 3:** Web `docs/REMAINING_WORK.md`: phase 3 section ticked + browser QA rows; app `REMAINING_WORK.md` (clubs branch) Phase 3 ticked. Commit `docs: community phase 3 status`, push `feat/community-p3`. **Do not merge or push main**; deploy is the owner's "deploy it".
