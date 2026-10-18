# Moments completion

**Date:** 2026-10-08
**Status:** Approved in conversation; written for review
**Scope:** Sub-project 2 of 2 ("all covered moments on the web"). Sub-project 1, Community, has its own spec (`2026-10-08-community-completion-design.md`).
**Repos:** `language_exchange_web_front` (web) and `language_exchange_backend_application` (backend, serving the production app).

---

## Where this starts

The 2026-09-23 parity inventory is mostly shipped: translate on tap, corrections, comment engagement, the Following tab, view counts, and the whole story set.

This audit (2026-10-08) found six problems. Two of them are production defects the app already suffers from:

- **(A) Filters and search look at one page.** `MainMoments.tsx` filters category, language, mood, tag, author and search in the browser, over the ten moments it has loaded. It builds the dropdown options from those same ten. Pick "Korean" and you see the Korean moments among ten, not the Korean moments.
- **(B) Scheduled moments publish immediately.** *Production bug.* `createMoment` stores `scheduledFor`, and the app's composer sets it. But no feed filters on it and no job publishes later, so a moment scheduled for tomorrow appears in every feed now.
- **(C) Moment reports never reach moderators.** *Production bug.* The app reports through `POST /moments/:id/report`, which pushes onto the moment's embedded `reports` array. The admin reports desk (`controllers/adminContent.js`) counts only the `Report` collection, so every moment report from the app is invisible. The web has no report action at all; `useReportMomentMutation` has no caller.
- **(D) Editing changes title, description and images only.** `updateMoment` also accepts mood, tags, category, language, privacy, backgroundColor, location and scheduledFor.
- **(E) A video or voice note cannot be removed or replaced while editing.** `DELETE /:id/video` exists. `PUT /:id/audio` replaces a voice note, but nothing removes one.
- **(F) `/moments` throws hydration errors** on repeat loads after a build. This is a known follow-up from 2026-09-24.

Excluded: Reels on the web (a product decision) and translation history (`getMomentTranslations`).

## 1. Real filters on every tab (A)

The user chose filters that work on For You, Following, Trending and Explore alike.

### Backend: `lib/momentFilters.js`

One function, `applyMomentFilters(query, params)`. It returns a new query object; the one passed in is not modified.

| Param | Meaning |
|---|---|
| `category` | Exact match. Ignored when empty or `'all'`. |
| `language` | Exact match. Ignored when empty or `'all'`. |
| `mood` | Exact match. Ignored when empty or `'all'`. |
| `tags` | Comma list, trimmed, matched with `$in`. |
| `q` | New. Trimmed, capped at 100 characters, `escapeRegex`d. Case-insensitive match on title, description or tags. |

The first four are exactly what `exploreMoments` applies today. Explore is refactored onto the helper, and a test pins it to its current behaviour.

`q` uses a regex rather than a `$text` index. MongoDB's text index splits words on spaces, which does not work for Korean, Japanese or Chinese. No index is added.

**The `$or` hazard.** Logged-in feeds are already a top-level `$or` (public posts, plus your own posts of any privacy). The search clause is an `$or` too. So the helper always combines through `$and: [existing, search]`; it never writes a second `$or` key. Overwriting the first would drop the privacy rule. A test proves that another user's private moment never matches a search.

**Where it is applied:**

- `getMoments`, in every feed mode: default, `forYou` and `following`.
- `getTrendingMoments`.
- `exploreMoments`.

Each applies it before both `countDocuments` and `find`, so totals stay right.

**For You and an explicit language.** For You already scopes to `{ language: { $in: [native, learning] } }`. An explicit `language` filter replaces that scope; it does not intersect with it, and For You ranking still applies. Intersecting would turn "show me Japanese" into an empty For You for anyone not learning Japanese.

**App safety.** The app sends only `page`, `limit` and `feed` to `/moments`, nothing extra to `/trending`, and its filter only to `/explore`. Those are the endpoint call sites in `moments_providers.dart` and `moments_service.dart`. So for every request the app makes today, the new params change nothing.

### Web

- **Filter state lives in the URL** — `?cat=&lang=&mood=&tag=&q=` — the same pattern as `communityUrlState.ts`. It is shareable, survives a reload and answers Back. It is sent as `category`, `language`, `mood`, `tags` and `q` on whichever tab query is active.
- **Changing a filter returns to page 1.**
- **Option lists:**
  - category and mood mirror the schema enums in one web constant, with i18n labels;
  - language comes from a language list in the UI language, through the same `Intl.DisplayNames` approach as the community country list.
- **Removed:** the client-side filtering, the "options from this page" lists, and the author filter, which only ever listed authors on the current page. Search goes server-side.
- **Paging and empty state:**
  - the page count comes from the server's total;
  - when nothing matches there is an empty state ("No moments match these filters") with a clear-filters action.
- **Visible strings go through i18n,** under `moments_section.filters.*`, which is added to the parity guard.

## 2. Scheduled moments work (B)

### Backend

A moment whose `scheduledFor` is in the future is visible **only to its author** until that time.

While enforcement is on (see the switch below), every discovery read adds the scheduling filter to the public side of its query:

- `getMoments`, in every mode;
- `getTrendingMoments`;
- `exploreMoments`;
- `getUserMoments`, unless the viewer is the author;
- `getMoment` by id, which answers 404 to anyone but the author while the moment is still scheduled.

The author's own-posts branch is untouched, so authors keep seeing their scheduled moments.

**The read filter** is `scheduledFor: { $not: { $gt: now } }`. That matches null, missing and past values without adding an `$or`, so it cannot collide with the logged-in feeds' existing top-level `$or` or with the search clause.

**Reads deliberately left alone:** `getSavedMoments`, `getReelsFeed`, comments and translate. Each needs an id the viewer could only have got while the moment was visible, so leaving them is low risk.

**One more read is covered:** `controllers/og.js`, the OG preview for `banatalk.com/moments/:id`. It serves the generic BananaTalk card for a scheduled moment, or a share preview would leak its text.

**Order on publish.** Feeds sort by `createdAt`, so a moment published tomorrow would surface buried at today's position. So, **only while enforcement is on**, whenever a moment is created or updated with a future `scheduledFor`, `createdAt` is set to `scheduledFor` and the moment appears at its publish time. An update may move `createdAt` only while the moment is still unpublished (its stored `scheduledFor` is still in the future). Once it is public, `createdAt` is never rewritten.

`createMoment` already rejects a `scheduledFor` in the past. `updateMoment` gets the same check, in the controller. The app's `updateMoment` never sends `scheduledFor`, so this cannot reject an app request.

**Follower push.** `createMoment` currently calls `notificationService.sendFollowerMoment` straight away. While enforcement is on, it is skipped for a moment created with a future `scheduledFor`; otherwise a follower would tap the push and get a 404. A push at publish time stays out of scope.

**Switch: `MOMENT_SCHEDULING_ENFORCED` — OFF by default.** Enforcement happens only when the value is `'true'`, read per request. The user chose to count first: moments already scheduled for a future time are public right now, and would vanish the moment enforcement starts.

So this ships in two steps:

1. **Count.** Deploy with the switch off — no behaviour change — and run a read-only script, `scripts/countFutureScheduledMoments.js` (`node scripts/countFutureScheduledMoments.js`). It prints how many non-deleted moments have `scheduledFor > now`, split by privacy, with their likes and comments, so the user can see what enforcement would hide.
2. **Enable.** The user sets `MOMENT_SCHEDULING_ENFORCED=true` and restarts.

**Switching it off again** stops the filter, the `createdAt` rewrite and the push skip. Any moment whose `createdAt` was already moved into the future then shows at the top of the feeds until that time passes. That is accepted: it is a handful of moments, for at most as long as they were scheduled.

**Web.** In the author's own views, a scheduled moment shows "Scheduled for <time>" **instead of** its relative time. Its `createdAt` is in the future, so "posted X ago" would read negative.

**The web picker only appears while enforcement is on.**
- `GET /app-config` already exposes feature flags (`smartSortEnabled`, `matchesLayoutEnabled`, …). It gains one more, additive: `momentSchedulingEnforced: MOMENT_SCHEDULING_ENFORCED === 'true'`, read per request.
- The Create and Edit schedule pickers render only when that flag is true. Otherwise a web user would schedule a post that publishes immediately — the bug this section exists to fix.

**Reports already made are not backfilled.** The legacy endpoint returns early when the user already has an embedded report. So a user who reported a moment before this deploy gets no `Report` row from a repeat report. That is accepted and deliberate: the dual-write is forward-only. A test pins it, so nobody "fixes" it into a backfill.

**The web's own reports keep their side effects.** They go through the canonical `POST /reports`, so the reel auto-hide and the admin email still apply to them. "Record only" describes the app's legacy path, not the web flow.

### Web

- **Create:** an optional "Schedule" date-time picker, future times only.
- **Edit:** the same picker, shown only while the moment is unpublished.
- **Author views** (own profile moments and the detail page) show a "Scheduled for <time>" badge.

## 3. Reports reach moderators (C)

### Backend

`POST /moments/:id/report` keeps its response exactly as it is. It additionally creates a `Report` document:

- `type: 'moment'`
- `reportId: moment._id`
- `reportedUser: moment.user`
- the same `reason` and `description`

The embedded `reports` push stays, because existing code reads it.

**Dedup.** No `Report` row is written if the reporter has **any** existing `Report` for this moment, whatever its status. `Report` has a unique index on `{ reportedBy, type, reportId }`, so a second row would throw. A duplicate-key error that slips through a race is caught and treated as "already recorded".

**Reason mapping**, from the embedded enum the app sends to the `Report` enum:

| App sends | `Report` gets |
|---|---|
| spam | spam |
| harassment | harassment |
| hate_speech | hate_speech |
| violence | violence |
| other | other |
| misinformation | false_information |
| inappropriate | other (the user's choice — "inappropriate" is broader than nudity) |

**Record only.** The dual-write creates the row and nothing else. It does **not** run `createReport`'s side effects:
- the reel auto-hide, where two reports on an `isReel` moment set `hiddenPendingReview`;
- the admin email, `emailService.sendAdminReportAlert`.

That was the user's choice. App reports reach the desk with no new automatic consequences.

**Switch: `MOMENT_REPORTS_TO_DESK`.** On by default; `'false'` stops the dual-write. It is read per request. A failure to write the `Report` record is logged and does not fail the request: the embedded write is the existing contract.

### Web

- **One shared report dialog** in `src/components/moments/actions/`, taking the reason list from the `Report` enum. The chat and profile report flows can adopt it later; that is out of scope here.
- **It posts to `POST /reports`** with `{ type: 'moment', reportId, reportedUser, reason, description }` — the canonical path. A "you already reported this" 400 is shown as a calm notice, not an error.
- **Placement:** an overflow ("⋯") menu on `SingleMoment` and `MomentDetail`, shown on other people's moments only.

## 4. Edit everything the server allows (D)

`EditMyMoment` gains:

- mood, tags (5 at most), category and language;
- privacy;
- background colour, for text moments;
- location;
- the schedule picker from section 2.

The pickers are extracted from `CreateMoment.tsx` into `src/components/moments/fields/`, one file per field, and used by both forms. They are not copied. `CreateMoment` must behave identically after the extraction; its existing tests are the guard.

The editor sends only fields that changed, as `EditProfile` does since `78a59e2`.

## 5. Replace or remove media while editing (E)

### Backend

`DELETE /moments/:id/audio` is new and additive. It is owner-only. It clears `audio` and resets `mediaType`, mirroring `deleteVideo`.

### Web

The editor shows the current video or voice note, with:

- **Replace:** the existing `PUT` upload endpoints;
- **Remove:** `DELETE /:id/video` or `DELETE /:id/audio`, behind the shared `ConfirmDialog`.

Media modes stay mutually exclusive, as in `CreateMoment` (image XOR video XOR audio XOR text).

## 6. `/moments` hydration (F)

This follows `superpowers:systematic-debugging`: reproduce on a production build (`npm run build`, serve, repeat loads), find the root cause, then fix that cause. The spec fixes the goal, not the fix: zero hydration errors on first and repeat loads of the prerendered `/moments`.

The 2026-09-24 note suspects two things:

- a stale prefetched first page compared with the live feed;
- viewed state read from sessionStorage during render.

Neither is assumed.

## Production safety (backend)

This backend serves the production app. Every change follows these rules:

1. **Additive only.** No field is renamed or removed and no response shape changes. The `Report` dual-write and `DELETE /:id/audio` are both additions.
2. **Same request, same answer.** Requests with no new params return exactly today's results, except where a section deliberately changes visibility, which is behind a switch. Tests pin this for each feed, and `exploreMoments` is pinned to its current filtering.
3. **Behaviour changes sit behind switches.**
   - Scheduled visibility (section 2) sits behind `MOMENT_SCHEDULING_ENFORCED`, which is **off** until the user has run the count and turned it on.
   - The report dual-write (section 3) sits behind `MOMENT_REPORTS_TO_DESK`. It is on by default; it is record-only and invisible to the app.
4. **No data migrations and no new indexes.** `createdAt` moves only on new writes of unpublished scheduled moments, and only while enforcement is on.
5. **One merge per section, in this order: 1, then 2, then 3, then 5.** Each can be reverted alone. Sections 1 and 2 both touch `getMoments`, `getTrendingMoments` and `exploreMoments`, so 1 lands first and 2 builds on it.
6. **Before every backend push:**
   - the full suite on Node 24;
   - `npm ci --omit=dev --dry-run` under npm 9.2.0.
7. **After every backend push:**
   - the deploy log shows `npm ci succeeded` and PM2 `online`;
   - a live request against `api.banatalk.com` answers 200.

## Testing

Backend, with Node tests against an in-memory MongoDB:

- **Filters (1):**
  - each filter, on each of the three endpoints;
  - `q` matches title, description and tags, case-insensitively, including Korean text;
  - `q` never surfaces another user's private moment (the `$or` hazard);
  - `countDocuments` agrees with the page;
  - Explore with today's params returns today's results;
  - For You with an explicit language replaces its language scope.
- **Scheduling (2):**
  - **Switch off (the default):** every read, `createdAt`, and the follower push behave exactly as today.
  - **Switch on:**
    - a future moment is hidden from other users on every listed read, including the OG preview, and visible to its author;
    - it appears once `scheduledFor` has passed;
    - `createdAt` follows `scheduledFor` while unpublished and is frozen after;
    - the follower push is skipped for a scheduled create.
  - A past `scheduledFor` is rejected on update.
  - The count script prints the right numbers against a seeded database.
- **Reports (3):**
  - the legacy endpoint's response is unchanged;
  - a `Report` row is created with the mapped reason;
  - no second row is written when any earlier `Report` exists, whatever its status;
  - a duplicate-key race is swallowed;
  - no admin email is sent and no reel is auto-hidden;
  - `MOMENT_REPORTS_TO_DESK=false` stops the dual-write;
  - a `Report` write failure does not fail the request.
- **Media (5):**
  - `DELETE /:id/audio` is owner-only, clears the audio and resets `mediaType`.

Web, with Jest:

- **URL state** round-trips; changing a filter resets to page 1; params reach every tab's query.
- **No client-side filtering remains.** A grep guard checks that `filteredMoments` is gone.
- **Report dialog:** the payload shape, the duplicate notice, and that it never appears on your own moment.
- **Shared fields:** create still behaves identically; edit sends only what changed.
- **Schedule picker:** rejects past times; the badge shows on the author's view only.
- **Media replace/remove** goes through the dialog.
- **Locale parity** for `moments_section.filters.*` and every other new key.
- **Hydration (6):** a regression test for whatever the root cause turns out to be.

## Out of scope

- Reels on the web.
- Translation history.
- Moving the chat and profile report flows onto the shared report dialog.
- Publish-time notifications to followers for scheduled moments. There is no job; visibility is decided by the clock.
