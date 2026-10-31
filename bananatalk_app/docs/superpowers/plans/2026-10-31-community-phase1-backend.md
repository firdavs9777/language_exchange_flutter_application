# Community optimization — Phase 1 backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every Community list endpoint agree on filters, online status, paging order and response shape, so the app and web rewrites (Phases 2–3) can use one paged list, without changing anything shipped apps rely on.

**Architecture:** Small shared helpers in a new `lib/communityFilters.js` (language spellings, gender variants, age bounds, limit clamp) used by `buildUsersQuery`, nearby and the matching endpoints. Every change is additive or a bug fix; existing response fields stay.

**Tech Stack:** Node/Express, Mongoose 6, `node:test` + `mongodb-memory-server` (pattern: `test/usersListFilters.test.js`: `run(controller.fn, req)` helper, `makeUser`, `viewerReq`).

**Spec:** `bananatalk_app/docs/REMAINING_WORK.md` → "Community optimization (audit 2026-10-30)" → "Phase 1 — Backend list contract".

## Scope change from the spec (measured 2026-10-31, prod)

The default `/users` sort runs in **27 ms** server-side over 2,105 listed users; counts are similar; the largest room has 9 participants; a bare round trip from Asia costs 128 ms.
So these spec items are **dropped from Phase 1** (they buy nothing users can feel at 2.8k users; revisit past ~50k): stored `visibleLastActive` + index, count/exclusion caching, `/users` follower `$size` projection, `/rooms` aggregation, clubs member slicing/index, removing redundant viewer re-fetches, the `location.city` index, Wave index `partialFilterExpression`, `getSimilarUsers` `interests` select, `Topic.userCount` drift. Task 9 records this in both REMAINING_WORK files.

## Global Constraints

- Work in a new worktree from `origin/main` (80df2bd or later): `git worktree add ../be-community-p1 -b feat/community-p1 origin/main`. Never push `main` (push = live deploy); push the branch only.
- Shipped apps must keep working: never remove or rename a response field; new fields are additive.
- All limits are capped at **50**.
- Tests: run single files with `node --experimental-test-module-mocks --test --test-force-exit test/<file>.test.js` (full `npm test` dies under Node 25; see backend notes). Before the final commit run every test file whose name matches `users|community|match|nearby|wave|gather|club|topic`.
- Each commit ticks the matching item in **backend** `docs/REMAINING_WORK.md` (add a "Community optimization Phase 1" section in Task 1) and lists what is still open in the commit body. No `Co-Authored-By` trailer.
- "Online" always means the stored `isOnline` flag, forced to `false` for anyone with `privacySettings.showOnlineStatus === false` (`VISIBLE_IS_ONLINE_EXPR` / `redactUserForViewer` already do this).

## Review Focus

1. A user who hides online status must never come back `isOnline: true` from any endpoint touched here (Task 2 test pins it for nearby and topic users).
2. The **default** Partners list (app sends `matchLanguage=true` + the viewer's own languages) must return the same set as today; only an explicitly chosen pair becomes AND (Task 6 test pins both).
3. A viewer with no `location.city` sending `sameCity=true` must get the normal list, not an empty or everyone-in-null-city list (Task 6 test).
4. Paging through equal `lastActive` values must neither repeat nor skip anyone (Task 3 test with 25 identical timestamps).
5. A failed blocked-users lookup must not stick for 120 s (Task 5 test).

---

### Task 1: Shared filter helpers + nearby uses them

**Files:**
- Create: `lib/communityFilters.js`
- Modify: `controllers/users.js:180-235, 267-298` (use helpers; behaviour unchanged)
- Modify: `controllers/community.js:85-107` (nearby language / gender / age)
- Modify: `docs/REMAINING_WORK.md` (new section listing Tasks 1–9)
- Test: `test/communityNearbyFilters.test.js`

**Interfaces:**
- Produces (`lib/communityFilters.js`):
  - `anySpelling(value: string) -> { $in: RegExp[] }` — exact, case-insensitive match on every `equivalentValues(value)` spelling (moved from users.js:207).
  - `genderMatch(gender: string) -> { $regex: RegExp }` — the `male/female/other` variants map from users.js:269-276.
  - `ageBounds(minAge, maxAge) -> object | null` — `birth_year` string bounds incl. `$gt: ''` when a minimum is set; `null` when neither bound applies (same 18/100 rules as users.js:285-296).
  - `clampLimit(raw, fallback: number, max = 50) -> number` — `Math.min(Math.max(parseInt(raw,10) || fallback, 1), max)`.

- [ ] **Step 1: Write the failing tests** (`test/communityNearbyFilters.test.js`, users placed within 5 km of the viewer, `location: { type:'Point', coordinates:[127.0, 37.5] }`, call `community.getNearbyUsers` with `query: { latitude:'37.5', longitude:'127.0', ... }`)
  - `language=Chinese` returns a user whose `native_language` is `'Chinese (Simplified)'`.
  - `gender=male` returns users stored as `'Male'` and `'m'`, not `'female'`.
  - `minAge=30` excludes a user with `birth_year: ''`.
- [ ] **Step 2: Run** `node --experimental-test-module-mocks --test --test-force-exit test/communityNearbyFilters.test.js` — expect 3 FAIL.
- [ ] **Step 3: Implement** `lib/communityFilters.js`; nearby builds `$or: [{native_language: anySpelling(language)}, {language_to_learn: anySpelling(language)}]`, `gender: genderMatch(gender)`, `birth_year: ageBounds(...)`; `buildUsersQuery` switches to the same helpers.
- [ ] **Step 4: Run** the new test plus `test/usersListFilters.test.js`, `test/communityFilterMatching.test.js`, `test/matchLanguage.test.js`, `test/nearbyGeoKey.test.js` — all PASS.
- [ ] **Step 5: Commit** `fix(community): nearby filters use the same language, gender and age rules as the list`

### Task 2: One meaning of "online"

**Files:**
- Modify: `controllers/community.js:163-170` (nearby projection), `:563-588` (topic users select + map)
- Modify: `controllers/matching.js:715-728, 762-778` (findByLanguage, getSimilarUsers)
- Test: `test/communityOnlineFlag.test.js`

**Interfaces:** Consumes nothing new. Nearby projects `isOnline: VISIBLE_IS_ONLINE_EXPR` (from `lib/privacySettings`); the other three add `isOnline` to `select` and stop overriding it from `lastActive`.

- [ ] **Step 1: Write the failing tests**
  - Topic users: user A `isOnline: false, lastActive: now` → `isOnline === false`; user B `isOnline: true, lastActive: 1h ago` → `true`.
  - Nearby with `onlineOnly=true`: every returned row has `isOnline === true`.
  - Topic users: user C `isOnline: true`, `privacySettings.showOnlineStatus: false` → `isOnline === false`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** as in Interfaces.
- [ ] **Step 4: Run** the new test + `test/userPrivacyRedaction.test.js` + `test/communityTabsFixes.test.js` — PASS.
- [ ] **Step 5: Commit** `fix(community): online means the stored presence flag on every list`

### Task 3: Stable paging order

**Files:**
- Modify: `controllers/community.js:567` (topic users sort → `{ lastActive: -1, _id: -1 }`), nearby pipeline (insert `{ $sort: { distance: 1, _id: 1 } }` before `$facet`)
- Modify: `controllers/matching.js:722, 776` (`_id: -1` after `lastActive`)
- Modify: `controllers/gatherings.js:314` (`{ startsAt: 1, _id: 1 }`), `controllers/clubs.js:225` (`{ memberCount: -1, createdAt: -1, _id: -1 }`), `:270` (`{ startsAt: 1, _id: 1 }`)
- Test: `test/communityStablePaging.test.js`

- [ ] **Step 1: Write the failing test** — 25 users in one topic, all `lastActive` equal; topic users `limit=10` pages 1–3 → 25 distinct ids, no repeats. Same shape for `matching.findByLanguage` with `limit=10&offset=0/10/20`.
- [ ] **Step 2: Run** — FAIL (or flaky; a single repeat fails it).
- [ ] **Step 3: Implement** the sorts listed above.
- [ ] **Step 4: Run** new test + `test/gatherings.test.js`, `test/clubs.test.js`, `test/gatheringDiscoveryFilters.test.js` — PASS.
- [ ] **Step 5: Commit** `fix(community): total order on every paged list so pages never repeat or skip`

### Task 4: Cap matching limits

**Files:**
- Modify: `controllers/matching.js:610-680` (getQuickMatches: one `const limit = clampLimit(req.query.limit, 10)` used everywhere `parseInt(limit)` is), `:724` (`clampLimit(limit, 30)`), `:774` (`clampLimit(limit, 10)`)
- Test: `test/matchingLimitCaps.test.js`

**Interfaces:** Consumes `clampLimit` from Task 1.

- [ ] **Step 1: Write the failing tests** — 60 eligible users; `findByLanguage` and `getSimilarUsers` with `limit=100000` return ≤ 50; `getQuickMatches` with `limit=abc` returns ≤ 10 and status 200.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** new test + `test/matchingRecommendations.test.js` — PASS.
- [ ] **Step 5: Commit** `fix(matching): cap limit at 50 on quick, language and similar`

### Task 5: Wave badge = wave list; blocked lookup failures not cached

**Files:**
- Modify: `models/Wave.js:77-79` → `getUnreadCount(userId, { since?: Date, excludeFrom?: string[] } = {})`
- Modify: `controllers/community.js:435` → pass `{ since: 7 days ago, excludeFrom: blockedIds }`
- Modify: `utils/blockingUtils.js:20-50` — the fetcher rethrows; the outer function catches, logs and returns `[]` **without** caching (`cacheService.get` does not store when the fetcher throws).
- Test: `test/waveBadgeAndBlockCache.test.js`

- [ ] **Step 1: Write the failing tests**
  - Viewer has unread waves: 1 from 2 days ago, 1 from 10 days ago, 1 from a blocked user 1 day ago → `getWaves` returns `unreadCount === 1` and 1 row.
  - `getBlockedUserIds`: stub `User.findById` to throw once, then restore; first call → `[]`, second call → the real blocked id.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** new test + `test/waveLimit.test.js`, `test/waveInteraction.test.js`, `test/socketBlockCheck.test.js` — PASS.
- [ ] **Step 5: Commit** `fix(waves): unread badge counts what the list shows; a failed block lookup is not cached`

### Task 6: List filters the chips need

**Files:**
- Modify: `controllers/users.js` `buildUsersQuery`
- Test: `test/communityListContract.test.js`

**Behaviour:**
- `newUsersOnly=true` → same as `joinedWithin=7d` (list **and** count, so old builds' count stops lying).
- Explicit pair: `matchLanguage=true` with **both** languages set and `!isDefaultLanguageMatch(req.query, req.user)` → `$and: [{native_language: anySpelling(learningLanguage)}, {language_to_learn: anySpelling(nativeLanguage)}]` instead of `$or`. The default request (viewer's own languages) keeps `$or`.
- `sameCity=true` → `'location.city'` exact, case-insensitive match on the viewer's own `location.city`, plus `'privacySettings.showCity': { $ne: false }`. Ignored when the viewer has no city. Available to every tier (owner may later gate it like `country`).

- [ ] **Step 1: Write the failing tests**
  - `newUsersOnly=true`: a user created today is listed, one with `createdAt` 20 days ago is not; `getUsersCount` agrees.
  - Explicit pair French/Korean (viewer is English/Spanish): user speaks French + learns Korean listed; speaks French + learns German not listed.
  - Default pair (viewer's own languages): a one-direction match is still listed.
  - `sameCity=true`, viewer city `'Seoul'`: `'seoul'` user listed, `'Busan'` user not, `'Seoul'` user with `showCity:false` not; a viewer without a city gets the same rows as without the param.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** new test + `test/usersListFilters.test.js`, `test/defaultLanguageMatch.test.js`, `test/usersSegmentParams.test.js`, `test/communitySearchEveryone.test.js` — PASS.
- [ ] **Step 5: Commit** `feat(users): newUsersOnly, explicit language pair as AND, sameCity — list and count agree`

### Task 7: Response contract for one client list

**Files:**
- Modify: `utils/imageUtils.js` → export `listImageUrls(images: string[], req) -> string[] | null` (body moved from users.js:565-575)
- Modify: `controllers/users.js:563-596` (use it; add top-level `hasMore: skip + users.length < total`)
- Modify: `controllers/community.js` nearby + topic users rows → add `imageUrls: listImageUrls(u.images, req)`; nearby rows also get `lastActive` (same value as existing `lastSeen`, which stays)
- Test: `test/communityResponseShape.test.js`

- [ ] **Step 1: Write the failing tests** — `/users` with 3 users and `limit=2`: page 1 `hasMore === true`, page 2 `false`, `total`/`pages`/`count` still present. Nearby and topic users rows have `imageUrls` as an array of `https://` URLs for a user with one image (set `CDN_BASE_URL` in the test if `toCdnUrl` needs it), and nearby rows keep `lastSeen`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** new test + `test/usersListFilters.test.js` + `test/nearbyGeoKey.test.js` — PASS.
- [ ] **Step 5: Commit** `feat(community): hasMore on /users, imageUrls on nearby and topic users`

### Task 8: Full verification

- [ ] **Step 1:** Run every test file matching `users|community|match|nearby|wave|gather|club|topic|privacy|block` one by one; expect all PASS. Paste the counts in the PR/merge note.
- [ ] **Step 2:** `node -e "require('./server')"` is not safe (it listens); instead `node --check` each modified file.
- [ ] **Step 3:** Push the branch `feat/community-p1` (not main). Do **not** deploy; the owner deploys with "deploy it".

### Task 9: Record the outcome

**Files:**
- Modify: backend `docs/REMAINING_WORK.md` (tick Tasks 1–7; list the dropped perf items with the 27 ms / 128 ms measurement)
- Modify: app `bananatalk_app/docs/REMAINING_WORK.md` "Phase 1" — tick the shipped items, move the dropped perf items under a "Not worth it at 2.8k users (measured 2026-10-31)" line, note that the filter-sheet count's missing default `matchLanguage` is fixed in the app in Phase 2.
- [ ] **Step 1:** Edit both files.
- [ ] **Step 2:** Commit each repo (`docs: community phase 1 status`) with open items in the body; push the backend branch and the app branch.
