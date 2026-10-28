# Clubs v2, slice 3: club feed (records) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Club members post a record after a meetup (photo + note + optional distance and time) to a members-only club feed, with a switch to also share it to the public Moments feed.

**Architecture:** Reuse `Moment`. A club post is a moment with `club` set. Members-only posts get the new privacy value `'club'`; "also share to Moments" saves `privacy: 'public'` with `club` set, so it shows in both. Every public listing already filters on an allowlist of privacy values, so `'club'` is excluded by construction. One async helper decides whether a viewer may see a club moment, and every by-id action on a moment calls it.

**Tech Stack:** as slices 1–2.

**Spec:** `docs/moim-plan.md` Phase 2 "Club feed for records"; §8 item 10.

## Global Constraints

- Backend branch `feat/clubs-v2-feed` off backend `main` (80df2bd); app branch `feat/clubs-v2-feed` off app `main` (71d9c3d3).
- Nothing changes for moments without `club` (every existing moment): the new checks run only when `moment.club` is set or `privacy === 'club'`. The by-id visibility gaps for friends/private moments are a separate, existing issue (ledgered, not fixed here).
- Creating a club post needs clubs v2 access and membership; `GET /clubs/:id/moments` needs both too.
- REMAINING_WORK on every commit; no Co-Authored-By trailer; `package:` imports; strings in 19 locales + CSV rows (line-level edits only).

## Decisions

- **Stats:** optional `activity: { distanceM: Number ≥ 0 ≤ 1,000,000, durationS: Number ≥ 0 ≤ 86,400 }`; pace is computed in the app, never stored.
- **Author's own main feed** does not show their members-only club posts (they live in the club); shared-public ones show as usual.
- **No follower push** for `privacy: 'club'` posts.
- **Privacy can't move to or from `'club'`** after posting, and `club` can't change (prevents a members-only post being published by edit, or a public post being pulled into a club).
- **Share preview (og)** of a `'club'` moment returns the generic not-found preview.

## Review Focus

1. A non-member (or a member without v2, or a removed/banned member) acting on a `'club'` moment by id: detail, comments list/create/get/replies, like, react, save, share, report, translate, og → refused / not found. Test in Task 1.
2. `'club'` moments absent from For You, Following, Recent, Trending, explore/search, reels, other users' profiles, and the saved list for a non-member. Test in Task 1.
3. Editing privacy to/from `'club'`, or changing `club`, → 400. Test in Task 1.
4. A club post shared publicly appears in both the club feed and public feeds. Test in Task 2.
5. A removed member no longer sees the club feed or its members-only posts. Test in Task 2.

---

### Task 1: Club moments in the Moment model, with every gate

**Files:**
- Modify: `models/Moment.js` (`club` ref + index `{ club: 1, createdAt: -1 }`, `privacy` enum + `'club'`, `activity`), `validators/momentValidator.js`, `controllers/moments.js` (createMoment, updateMoment, getMoments ownPostsQuery, detail, like/dislike/save/share/react/report, translate ×2, getSavedMoments, follower push), `controllers/comments.js` (list, create, get, replies), `controllers/og.js`, `lib/momentVisibility.js`
- Create: `lib/clubMomentAccess.js`
- Test: `test/clubMoments.test.js`

**Interfaces:**
- Produces: `canSeeClubMoment(moment, viewerId) -> Promise<boolean>` — true when the moment has no `club`; otherwise when the viewer is the author, or (for `privacy: 'public'`) always, or (for `'club'`) the viewer has clubs v2 access and is a non-banned member of an active club. Every endpoint above calls it after its existing checks and answers exactly as it does for a moment that doesn't exist (404) when false.
- `createMoment` with `club`: requires v2 + membership (403 otherwise); `privacy` must be `'club'` or `'public'`; `activity` validated as above.
- [ ] **Step 1: Failing tests** — for each endpoint in Review Focus 1, non-member → 404, member → OK; non-member's feeds/search/reels/saved exclude a `'club'` moment (Review Focus 2); edits refused (Review Focus 3); create without access/membership → 403; activity bounds → 400; a `'club'` post sends no follower push; a moment without `club` behaves exactly as before on every endpoint.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** this + every `test/moment*.test.js`, `test/comment*.test.js`, `test/og*.test.js`, `test/reels*.test.js` → PASS.
- [ ] **Step 5: Commit** `feat(clubs): club posts on moments — members-only privacy, activity stats, every by-id gate`.

### Task 2: The club feed endpoint

**Files:**
- Modify: `controllers/clubs.js` (`getClubMoments`), `routes/clubs.js` (`GET /:id/moments`)
- Test: `test/clubFeed.test.js`

**Interfaces:**
- `GET /clubs/:id/moments?page=&limit=` (v2 + member; 404 without access, 403 non-member) → `{ data: [moment], hasMore }`, newest first, both privacies, excluding deleted, `hiddenPendingReview`, scheduled-in-the-future, and authors blocked either way; populated like the main feed so the app's `Moment` parser reads it.
- [ ] **Step 1: Failing tests** — member sees club + shared posts newest first; shared post also in the public feed (Review Focus 4); removed member → 403 (Review Focus 5); paging; blocked author hidden.
- [ ] **Step 2–4** as usual (this + `test/club*.test.js`). **Step 5: Commit** `feat(clubs): the club feed`; backend REMAINING_WORK.

### Task 3: App — model, API, composer

**Files:**
- Modify: the app `Moment` model (`club`, `activity`), `lib/providers/provider_root/moments_providers.dart` (`createMoments` sends `club`, `activity`; a `clubMomentsProvider` family via `PagedMomentsFeedNotifier` with a fetcher for `GET clubs/:id/moments`), `lib/pages/moments/create/create_moment.dart` (`clubId` param: hides the privacy picker, shows "Also share to Moments" (off by default) and Distance (km) / Time (min) fields), ARB files + registries
- Test: `test/community/club_feed_model_test.dart`, `test/moments/club_composer_test.dart`
- Strings: `clubPost` "Post a record", `clubPostsTitle` "Club posts", `clubPostsEmpty` "No posts yet. Share how today's meetup went.", `clubShareToMoments` "Also share to Moments", `clubActivityDistance` "Distance (km)", `clubActivityTime` "Time (min)", `clubActivitySummary` "{distance} km · {time} · {pace}/km".
- [ ] Failing tests → implement → `flutter test test/moments test/community test/l10n` → commit `feat(clubs): post a record to the club from the composer (clubs v2)`.

### Task 4: App — the club feed on the club page

**Files:**
- Modify: `lib/pages/community/gatherings/club_detail_screen.dart` (a "Club posts" section for members with access: latest posts via `MomentCard`, "Post a record" opens the composer with `clubId`, "See all" pushes a full feed screen), `lib/pages/moments/card/moment_card.dart` (activity chip when `activity` is set)
- Create: `lib/pages/community/gatherings/club_feed_screen.dart`
- Test: `test/community/club_feed_test.dart`
- [ ] Failing tests (section only for members with access; empty state; post button opens composer with clubId; activity chip shows "5.2 km · 31:00 · 5:58/km") → implement → full `flutter test` + `flutter analyze` → commit `feat(clubs): club posts on the club page (clubs v2)`; app REMAINING_WORK.
