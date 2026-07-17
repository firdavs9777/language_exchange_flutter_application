# Community Discovery Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Web people-discovery to app parity — filters that actually hit the DB, a `PartnerListItem`-parity member card, a full filter sheet with live match count, reconciled waves, all in Tailwind.

**Architecture:** Front repo ONLY (`/Users/firdavsmutalipov/Projects/BananaTalk/front`). Backend already supports every param — the fixes are all client-side (send the right params). A pure, unit-tested query-param mapper is the core; the rest is RTK wiring + Tailwind UI.

**Tech Stack:** React 18, TypeScript, RTK Query, `react-scripts test` (Jest/RTL), Tailwind, lucide-react.

## Global Constraints

- Design system: **Tailwind** for all new/modified UI; no new `.scss`. Reference `EditProfile.tsx`. Teal `#00BFA5`→`#00ACC1`, gold VIP gradient `#FFD700`→`#FFA500`, green online dots, `rounded-full` pill chips.
- **INVERTED language semantics (verbatim, critical):** API `nativeLanguage` param finds users LEARNING that language; API `learningLanguage` finds users who SPEAK it natively. UI "partner's native language = X" → API `learningLanguage=X`; UI "learning Y" → API `nativeLanguage=Y`. No language filter set → `matchLanguage=true` + current user's own native/learning.
- Backend params (exact): `page, limit, nativeLanguage, learningLanguage, matchLanguage, gender, minAge (only >18), maxAge (only <100), onlineOnly, country, languageLevel, topics(csv), topicsAtLeast, search, sort(recently_active)`.
- Real wave routes: `POST /api/v1/community/wave` `{targetUserId, message?}`; `GET /api/v1/community/waves` `{page,limit,unreadOnly,archive}`; `PUT /api/v1/community/waves/read` `{waveIds?}`. Handle `ALREADY_WAVED` 400.
- Member list payload has NO `responseRate` / `mbti` — card must omit those chip types (render only when field present).
- **Do NOT touch the backend repo** (it has the user's unrelated WIP). No backend changes needed.
- Verify web with `CI=false npx react-scripts build` + Jest; `npx tsc --noEmit` is BROKEN repo-wide (pre-existing) — do not use it. Commit locally per task; do NOT push.

---

### Task 1: `buildCommunityQuery` pure mapper

**Files:** Create `src/components/community/lib/buildCommunityQuery.ts` + `.test.ts`.

**Interfaces:**
- `CommunityFilters = { minAge?, maxAge?, gender?, nativeLanguage?, learningLanguage?, country?, topics?: string[], languageLevel?, onlineOnly?, newUsersOnly?, topicsAtLeast?, search?, sort?: 'recently_active' }`.
- `Me = { native_language?: string; language_to_learn?: string }`.
- `buildCommunityQuery(filters, me, page, limit) => Record<string,string>` — the URL query object, applying inverted semantics + matchLanguage default + age guards.

- [ ] **Step 1: Write the failing test**

```ts
// src/components/community/lib/buildCommunityQuery.test.ts
import { buildCommunityQuery } from './buildCommunityQuery';
const me = { native_language: 'English', language_to_learn: 'Korean' };

it('inverts native/learning: UI nativeLanguage=Spanish -> API learningLanguage=Spanish', () => {
  const q = buildCommunityQuery({ nativeLanguage: 'Spanish' }, me, 1, 20);
  expect(q.learningLanguage).toBe('Spanish');
  expect(q.nativeLanguage).toBeUndefined();
  expect(q.matchLanguage).toBeUndefined();
});
it('UI learningLanguage=French -> API nativeLanguage=French', () => {
  const q = buildCommunityQuery({ learningLanguage: 'French' }, me, 1, 20);
  expect(q.nativeLanguage).toBe('French');
});
it('no language filter -> matchLanguage=true with my langs', () => {
  const q = buildCommunityQuery({}, me, 1, 20);
  expect(q.matchLanguage).toBe('true');
  expect(q.nativeLanguage).toBe('Korean');   // find users learning Korean (my target)... see note
  expect(q.learningLanguage).toBe('English');
});
it('age maps to minAge/maxAge and respects guards (min>18, max<100)', () => {
  const q = buildCommunityQuery({ minAge: 25, maxAge: 40 }, me, 1, 20);
  expect(q.minAge).toBe('25'); expect(q.maxAge).toBe('40');
  const q2 = buildCommunityQuery({ minAge: 18, maxAge: 100 }, me, 1, 20);
  expect(q2.minAge).toBeUndefined(); expect(q2.maxAge).toBeUndefined();
});
it('passes gender, onlineOnly, country, languageLevel, topics(csv), topicsAtLeast, search, sort, page, limit', () => {
  const q = buildCommunityQuery({ gender: 'female', onlineOnly: true, country: 'Japan', languageLevel: 'B2', topics: ['t1','t2'], topicsAtLeast: 2, search: 'kim', sort: 'recently_active' }, me, 3, 20);
  expect(q).toMatchObject({ gender: 'female', onlineOnly: 'true', country: 'Japan', languageLevel: 'B2', topics: 't1,t2', topicsAtLeast: '2', search: 'kim', sort: 'recently_active', page: '3', limit: '20' });
});
```
(NOTE for implementer: for the matchLanguage default, mirror the app's `_buildFilterParams` exactly — when no explicit language filter, send `matchLanguage=true` plus the current user's languages under the INVERTED param names, i.e. `nativeLanguage = me.language_to_learn`, `learningLanguage = me.native_language`. If the app's default omits explicit langs and sends only `matchLanguage=true`, match THAT instead — inspect `partner_discovery_tab.dart` `_buildFilterParams` in the app repo to confirm before finalizing, and adjust the test's default-case expectation to match the verified app behavior. The inversion for explicit filters is confirmed and must hold.)

- [ ] **Step 2:** Run `CI=true npx react-scripts test src/components/community/lib/buildCommunityQuery.test.ts --watchAll=false` — FAIL (no module).
- [ ] **Step 3:** Implement `buildCommunityQuery` per the constraints (omit undefined/empty keys; only add minAge when >18, maxAge when <100; topics joined with `,`; booleans as `'true'`; page/limit stringified). Confirm the default-language-case against the app before finalizing.
- [ ] **Step 4:** Run the test — PASS.
- [ ] **Step 5:** Commit `feat(community): add buildCommunityQuery param mapper (inverted lang semantics)`.

---

### Task 2: communitySlice — count endpoint, wave-endpoint fix, member normalization

**Files:** Modify `src/store/slices/communitySlice.ts`; add `src/constants.ts` entries if needed. Test: `src/store/slices/communityEndpoints.test.ts`.

**Interfaces:** `useGetCommunityCountQuery` (`GET /api/v1/auth/users/count`), corrected `useSendWaveMutation`/`useGetWavesQuery`/`useMarkWavesReadMutation` on the real routes, and a `transformResponse` on the members query normalizing each user: `isVIP = vipSubscription?.isActive`, keep `languageLevel, location, lastActive, hasActiveStory, isOnline, imageUrls, followersCount`.

- [ ] **Step 1:** Read the current `communitySlice.ts` fully. Write `communityEndpoints.test.ts` asserting the wave query configs hit `/api/v1/community/wave`, `/community/waves`, `/community/waves/read` and count hits `/api/v1/auth/users/count`.
- [ ] **Step 2:** Run the test — FAIL.
- [ ] **Step 3:** Add `getCommunityCount` query; fix the three wave endpoints to the real routes (remove `/received`,`/sent`,`/:id/respond`); add `transformResponse` to the members query mapping `vipSubscription.isActive`→`isVIP` and passing through the enrichment fields. Export the hooks in the existing export block.
- [ ] **Step 4:** Run the test + `CI=false npx react-scripts build` (no new errors) — PASS.
- [ ] **Step 5:** Commit `feat(community): add count query, reconcile wave endpoints, normalize member VIP/level fields`.

---

### Task 3: MemberCard (Tailwind, PartnerListItem parity)

**Files:** Create `src/components/community/MemberCard.tsx` + `.test.tsx`.

**Interfaces:** `<MemberCard user onWave onOpen />` where `user` is the normalized member. Renders avatar + online dot (when `isOnline`) + story ring (when `hasActiveStory`) + NEW badge (createdAt ≤7d or `isNew`) + VIP badge (`isVIP`) + name + age (from birth_year) + native→learning flags + CEFR badge (`languageLevel`, when present) + location (city/country, when present) + 1-line bio + wave button. Contextual chips: online/last-active + shared "Speaks/Learning" only (NO responseRate/mbti chips — not in payload).

- [ ] **Step 1:** Write RTL test: given a fixture user with `isVIP:true, languageLevel:'B2', isOnline:true, images`, asserts VIP badge, "B2", online dot present, name rendered; given `hasActiveStory:true` asserts story-ring element; wave button calls `onWave`.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3:** Implement in Tailwind (import `@testing-library/jest-dom` in the test). Reuse existing `tandem/LanguageFlagChip` if suitable or inline flags. Degrade gracefully when optional fields absent.
- [ ] **Step 4:** Run test + build — PASS.
- [ ] **Step 5:** Commit `feat(community): Tailwind MemberCard with PartnerListItem parity`.

---

### Task 4: CommunityFilterSheet (Tailwind) + live match count + persistence + ActiveFilterChips

**Files:** Create `src/components/community/CommunityFilterSheet.tsx`, `src/components/community/ActiveFilterChips.tsx`, `src/components/community/lib/filterStorage.ts` + tests for `filterStorage`.

**Interfaces:** `<CommunityFilterSheet open value onChange onApply onClear />` emitting a `CommunityFilters`; `filterStorage.load()/save(filters)` (localStorage key `community_filters`); `<ActiveFilterChips value onRemove onClear />`.

- [ ] **Step 1:** TDD `filterStorage` (save→load round-trip; load returns defaults when empty/corrupt). Write its test first, fail, implement, pass.
- [ ] **Step 2:** Build `CommunityFilterSheet` (Tailwind modal): Age range, Gender chips, native+learning language selects, Country input, CEFR level chips (Any/A1..C2), Topics multi-select (from `useGetTopicsQuery`), toggles (online now / new only), mutual-interests slider (`topicsAtLeast`). Header shows live count via `useGetCommunityCountQuery(buildCommunityQuery(value, me))` debounced 300ms. Footer Clear all / Apply. Persist via `filterStorage` on apply.
- [ ] **Step 3:** Build `ActiveFilterChips` (removable chip per active value + Clear).
- [ ] **Step 4:** `CI=false npx react-scripts build` — compiles, no new errors.
- [ ] **Step 5:** Commit `feat(community): Tailwind filter sheet w/ live match count + persistence + active chips`.

---

### Task 5: Wire mapper into MainCommunity (server-side filtering, quick chips, pagination, sort)

**Files:** Modify `src/components/community/MainCommunity.tsx`; create `src/components/community/QuickFilterChips.tsx`.

- [ ] **Step 1:** Read `MainCommunity.tsx` fully. Replace the ad-hoc param building + client-side search/language/online/age filtering with a single `useGetCommunityMembersQuery(buildCommunityQuery(filters, me, page, limit))` so ALL filters hit the DB. Keep the Load-more pagination (accumulate pages; `hasMore` = last page length === limit) and scroll restore.
- [ ] **Step 2:** Render `MemberCard` (Task 3), `CommunityFilterSheet` + `ActiveFilterChips` (Task 4), and `QuickFilterChips` (Recently Active → `sort:'recently_active'`; Online Now → `onlineOnly`; Speaks {my learning} / Learning {my native} → set the inverted language filter). Read `me` (native/learning langs) from auth `userInfo`.
- [ ] **Step 3:** Keep VIP-first/online-first client sort as a stable tiebreak on the accumulated list.
- [ ] **Step 4:** `CI=false npx react-scripts build` — compiles; manual note: changing a filter refetches from the server and the match count updates.
- [ ] **Step 5:** Commit `feat(community): server-side filtering via mapper + quick chips in MainCommunity`.

---

### Task 6: Waves — send sheet + received inbox + unread badge

**Files:** Create `src/components/community/WaveSheet.tsx`, `src/components/community/WavesInbox.tsx`; modify `MainCommunity.tsx`/nav to surface the inbox + unread badge; may modify existing `Waves.tsx` (reconcile to real endpoints) — reuse or replace, verify routing.

- [ ] **Step 1:** `WaveSheet` (Tailwind bottom sheet): emoji quick-reply chips (👋❤️😊🎉✋🌟), a few icebreaker prompt chips, custom message field, Send → `useSendWaveMutation({targetUserId, message})`; on `ALREADY_WAVED` (400) show a friendly "already waved" state and disable; on `isMutual` show a mutual toast.
- [ ] **Step 2:** `WavesInbox`: `useGetWavesQuery({page,limit})` → render `{data.waves}` (avatar, name, message/"Waved at you", timeago, unread tint); auto-mark read via `useMarkWavesReadMutation` on open; show `unreadCount` as a nav badge.
- [ ] **Step 3:** Wire the card's wave button (Task 3 `onWave`) to open `WaveSheet` for that user.
- [ ] **Step 4:** `CI=false npx react-scripts build` — compiles.
- [ ] **Step 5:** Commit `feat(community): wave send sheet + received inbox + unread badge (real endpoints)`.

---

### Task 7: Dead-code cleanup

**Files:** Delete (only if zero references — verify with grep first): `src/components/community/SingleCommunity.tsx`, `src/components/community/MemberCard.tsx` (the OLD legacy one, if distinct from the new Task-3 path — CAREFUL: Task 3 creates a new MemberCard; the legacy dead one is the pre-existing unused file — confirm which is referenced), `src/components/community/CommunityFilter.tsx` (9-line stub), `src/components/community/MainCommunity.css`, and the superseded `tandem/TandemMemberCard.tsx`/`tandem/CommunityFilterSheet.tsx` if fully replaced.

- [ ] **Step 1:** `grep -rn "SingleCommunity\|CommunityFilter\b\|MainCommunity.css\|TandemMemberCard\|tandem/CommunityFilterSheet" src` — delete only zero-reference files. If a file is still imported, leave it and note.
- [ ] **Step 2:** `CI=false npx react-scripts build` — compiles.
- [ ] **Step 3:** Commit `chore(community): remove superseded community components`.

---

## Self-Review notes (author)
- Spec coverage: bugs #1–#4 → Task 1 mapper + Task 5 wiring; #5 VIP → Task 2 transformResponse + Task 3 card; card parity → Task 3; filter sheet + match count + persistence + active chips → Task 4; quick chips + server filtering → Task 5; waves reconciled → Task 6; cleanup → Task 7. Nearby/city/voice-rooms/quick-match deferred per spec.
- **Open verification for Task 1:** the exact default-language behavior (matchLanguage-only vs matchLanguage+inverted-own-langs) must be confirmed against the app's `partner_discovery_tab.dart _buildFilterParams` before finalizing the mapper's empty-filter case; the explicit-filter inversion is confirmed. Flag as the one thing the implementer must verify in the app repo (read-only).
- No backend changes; backend working tree (user WIP) must not be touched.
