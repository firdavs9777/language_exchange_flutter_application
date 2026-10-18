# Moments completion — web Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The web side of the Moments spec: server filters on every tab, a report action that reaches moderators, an editor for every field, scheduling behind the server flag, media replace/remove, and a hydration-clean `/moments`.

**Architecture:** Filter state moves into the URL (`momentFilterState.ts`, the `communityUrlState.ts` pattern) and into the three feed queries' params; the browser no longer filters. Create and Edit share one set of field components under `src/components/moments/fields/`. Reporting uses the canonical `POST /reports` through `usersSlice.reportUser`. The schedule picker reads `momentSchedulingEnforced` from `GET /api/v1/app-config`.

**Tech Stack:** React 18 + TypeScript (CRA), RTK Query, react-router, Jest + Testing Library, react-i18next (18 locales).

**Spec:** `docs/superpowers/specs/2026-10-08-moments-completion-design.md` (sections 1, 2-web, 3-web, 4, 5-web, 6). Backend half shipped: `docs/superpowers/plans/2026-10-08-moments-backend.md`.

## Global Constraints

- Backend params: `category`, `language`, `mood`, `tags` (comma list), `q` on `/moments`, `/moments/trending`, `/moments/explore`. `'all'` or empty means no filter.
- URL keys: `cat`, `lang`, `mood`, `tag`, `q`. Changing any filter returns to page 1.
- Category enum (16): general, language-learning, culture, food, travel, music, books, hobbies, daily-life, technology, entertainment, sports, movies, study, work, question.
- Mood enum (12): happy, excited, grateful, motivated, relaxed, curious, sad, love, funny, thoughtful, cool, tired.
- Report reasons (Report enum): spam, harassment, hate_speech, violence, nudity, false_information, copyright, other. Description max 500.
- Duplicate report answers 400 "You have already reported this content…" → calm notice, not an error.
- Description is required (2000 max); title optional (100 max); tags max 5.
- The schedule picker renders only when `/app-config` `data.momentSchedulingEnforced === true`; sends `scheduledFor` as an ISO string; future only.
- Visible strings go through i18n; new namespaces are added to `localeParity.test.ts`, all 18 locales.
- CRA: `resetMocks: true` (arm mocks in `beforeEach`); no `import type`.
- Commits carry no Co-Authored-By trailer.
- Build is the type check: `npm run build` must pass before merge.

## Review Focus

1. A filtered feed on page 3 when a filter changes — must return to page 1, not request an empty page 3.
2. A shared link `/moments?lang=ko&q=김치` loaded cold — filters show as set and reach the query.
3. Reporting your own moment — the menu must not offer it (author id may be a string or a populated object).
4. Editing a moment and saving without changes — sends nothing destructive (no `scheduledFor: ""`, no `tags` overwrite).
5. App-config failing (404/network) — no schedule picker, Create still works.

---

### Task 1: Filter URL state, options, slice params

**Files:**
- Create: `src/components/moments/lib/momentFilterState.ts`, `src/components/moments/lib/momentOptions.ts`
- Modify: `src/store/slices/momentsSlice.ts` (getMoments, getTrendingMoments, getExploreMoments)
- Test: `src/components/moments/lib/momentFilterState.test.ts`, `src/store/slices/momentsSlice.filters.test.ts`

**Produces:**
- `type MomentFilters = { category?: string; language?: string; mood?: string; tag?: string; q?: string }`
- `decodeMomentFilters(params: URLSearchParams): MomentFilters` — drops unknown category/mood, invalid ISO-639-1 language, trims `q` (empty → absent), caps `q` at 100.
- `encodeMomentFilters(f: MomentFilters): URLSearchParams` — canonical order cat, lang, mood, tag, q.
- `mergeMomentParams(current: URLSearchParams, next: URLSearchParams): URLSearchParams` — keeps foreign params (e.g. `page`).
- `momentFilterQuery(f): string` — `&category=..&language=..&mood=..&tags=..&q=..` URI-encoded, empty when nothing set.
- `MOMENT_CATEGORIES: string[]` (16), `MOMENT_MOODS: {value, emoji}[]` (12).
- Slice args gain `filters?: MomentFilters` on all three feed queries.

- [ ] Step 1: tests — round trip; invalid values dropped; `q` trimmed/capped; `momentFilterQuery({language:'ko', q:'김 치'})` = `&language=ko&q=%EA%B9%80%20%EC%B9%98`; the slice URLs include the filter string (assert with a fetch mock on `getMoments`, `getTrendingMoments`, `getExploreMoments`), and with no filters the URL is unchanged from today.
- [ ] Step 2: run, expect FAIL (module missing).
- [ ] Step 3: implement.
- [ ] Step 4: run `CI=true npx react-scripts test src/components/moments/lib src/store/slices/momentsSlice.filters` → PASS.
- [ ] Step 5: commit `feat(moments): filter URL state and server filter params`.

### Task 2: MainMoments on server filters

**Files:**
- Create: `src/components/moments/MomentFiltersBar.tsx`
- Modify: `src/components/moments/MainMoments.tsx`, `src/locales/*/translation.json` (`moments_section.filters.*`, `moments_section.categories.*`, `moments_section.moods.*`), `src/i18n/localeParity.test.ts` (or wherever NAMESPACES lives)
- Test: `src/components/moments/MainMoments.test.tsx`, `src/components/moments/noClientFiltering.test.ts`

**Behaviour:**
- Filters come from `useSearchParams` via `decodeMomentFilters`; the bar writes through `encodeMomentFilters` + `mergeMomentParams` with `replace: true`, and resets `currentPage` to 1.
- Every active-tab query receives `filters`.
- Category and mood selects list the full enums with i18n labels; language select lists ISO-639-1 codes with `Intl.DisplayNames` in the UI language (fallback: ISO6391 native name).
- Search: input + submit; the submitted value goes to `q`.
- The author filter, `filteredMoments`, `paginatedMoments`, `filteredPagination` and the options-from-page lists are deleted. Moments render as served; `Pagination` reads `data.pagination` (`totalPages`, `totalMoments`, `hasNextPage`, `hasPrevPage`).
- Empty with filters active: "No moments match these filters" + Clear filters (clears URL keys). Empty without filters: existing states.

- [ ] Step 1: tests — (a) `?lang=ko&q=kimchi` reaches `useGetMomentsQuery` args as `filters: {language:'ko', q:'kimchi'}`; (b) switching to Trending passes the same filters; (c) server `totalPages: 3` renders a page-3 control even with 10 moments loaded; (d) filters active + empty list → "No moments match these filters" and clicking clear empties the filters arg; (e) grep guard: `MainMoments.tsx` contains neither `filteredMoments` nor `paginatedMoments`.
- [ ] Step 2: run, expect FAIL.
- [ ] Step 3: implement; add keys to all 18 locales (English text in non-English files is not acceptable: translate).
- [ ] Step 4: run moments tests + `localeParity` → PASS.
- [ ] Step 5: commit `feat(moments): filters run on the server on every tab`.

### Task 3: Report a moment

**Files:**
- Create: `src/components/moments/actions/ReportMomentDialog.tsx`, `src/components/moments/actions/MomentOverflowMenu.tsx`
- Modify: `SingleMoment.tsx` (the dead "More options" button), `MomentDetail.tsx` (header), locales (`moments_section.report.*`)
- Test: `actions/ReportMomentDialog.test.tsx`, `actions/MomentOverflowMenu.test.tsx`

**Produces:** `<MomentOverflowMenu momentId authorId />` — renders nothing when signed out or when `authorId === viewer`; otherwise a "⋯" button opening a menu with "Report"; Report opens `ReportMomentDialog`.
`ReportMomentDialog` — radio list of the 8 reasons, optional description (500), submit calls `reportUser({ type:'moment', reportId, reportedUser, reason, description })`. Success → toast "Thanks — our moderators will review it" and close. 400 whose message contains "already reported" → inline calm notice "You've already reported this moment", no error toast. Other errors → error toast.

- [ ] Step 1: tests — payload shape; duplicate notice; menu hidden on own moment (string and populated-object author); menu hidden signed out.
- [ ] Step 2: FAIL. Step 3: implement + wire both screens. Step 4: PASS. Step 5: commit `feat(moments): report a moment from the feed and the detail page`.

### Task 4: Characterize then extract CreateMoment's fields

**Files:**
- Create: `src/components/moments/CreateMoment.test.tsx`; `src/components/moments/fields/{MoodField,CategoryField,LanguageField,TagsField,PrivacyField,BackgroundField,LocationField}.tsx`
- Modify: `CreateMoment.tsx`

- [ ] Step 1: characterization tests on the current CreateMoment: text post payload (`title, description, mood, tags, privacy, language, category, mediaType:'text'`), tags capped at 5, background only on text posts. Run → PASS (it characterizes). Commit `test(moments): pin CreateMoment's payload`.
- [ ] Step 2: extract each picker into `fields/` as a controlled component (`value`, `onChange`), full enums from `momentOptions.ts`, labels via i18n keys from Task 2 (`moments_section.moods.*`, `.categories.*`). Mood and category lists grow to 12 and 16 — the characterization test's payload assertions stay green.
- [ ] Step 3: run CreateMoment tests → PASS. Commit `refactor(moments): create form uses shared field components`.

### Task 5: Scheduling on the web

**Files:**
- Modify: `src/store/slices/apiSlice`-injected endpoint — create `src/store/slices/appConfigSlice.ts` with `getAppConfig` (`GET /api/v1/app-config`, `transformResponse: r => r?.data ?? {}`)
- Create: `src/components/moments/fields/ScheduleField.tsx`, `src/components/moments/lib/scheduling.ts`
- Modify: `CreateMoment.tsx` (drop `scheduledDate`; send `scheduledFor` ISO only when set and enabled), `SingleMoment.tsx`, `MomentDetail.tsx` (badge)
- Test: `fields/ScheduleField.test.tsx`, `lib/scheduling.test.ts`, CreateMoment test additions

**Produces:** `useMomentSchedulingEnabled(): boolean` (false while loading or on error); `isScheduledLater(m: {scheduledFor?, createdAt?}, now = Date.now()): boolean` (scheduledFor parses to a future time); `<ScheduleField value onChange />` — `datetime-local`, `min` = now rounded up to the minute, rejects past values with an inline error.

- [ ] Step 1: tests — picker absent when flag false/erroring; present when true; past value → error and Create disabled; payload carries `scheduledFor` ISO and never `scheduledDate`; badge "Scheduled for <time>" replaces relative time for the author, not for others.
- [ ] Step 2: FAIL. Step 3: implement. Step 4: PASS. Step 5: commit `feat(moments): schedule a moment when the server enforces it`.

### Task 6: Edit everything the server allows

**Files:**
- Modify: `src/components/profile/EditMyMoment.tsx`, locales (`editMoment.*` additions)
- Create: `src/components/moments/lib/momentEditDiff.ts`
- Test: `src/components/profile/EditMyMoment.test.tsx`, `lib/momentEditDiff.test.ts`

**Behaviour:** fields from Task 4/5 (mood, tags, category, language, privacy, background for text moments, location, schedule while unpublished and the flag is on). `momentEditDiff(original, draft)` returns only changed keys (arrays compared by value). Save requires a description (title optional). Save with no changes and no new photos → "Nothing to save" notice, no request. `existingImages` is no longer sent (the server ignores it); the remove button on existing photos is removed because the server cannot remove a stored photo.

- [ ] Step 1: tests — diff returns `{}` for an untouched moment; title-less moment can be saved after a description edit; only `mood` is sent after changing mood; no remove button on existing photos.
- [ ] Step 2: FAIL. Step 3: implement. Step 4: PASS. Step 5: commit `feat(moments): the editor edits every field and sends only what changed`.

### Task 7: Replace or remove video and voice note

**Files:**
- Modify: `momentsSlice.ts` (`deleteMomentAudio`: `DELETE /moments/:id/audio`, invalidates the moment), `EditMyMoment.tsx`
- Create: `src/components/moments/fields/MediaEditor.tsx`
- Test: `fields/MediaEditor.test.tsx`

**Behaviour:** a video moment shows its video with Replace (file input → `uploadMomentVideo`) and Remove (ConfirmDialog → `deleteMomentVideo`); an audio moment the same with `uploadMomentAudio` / `deleteMomentAudio`. Image and text moments show no media editor.

- [ ] Step 1: tests — remove asks first and calls the right mutation only on confirm; replace calls upload with the file.
- [ ] Step 2: FAIL. Step 3: implement. Step 4: PASS. Step 5: commit `feat(moments): replace or remove a video or voice note while editing`.

### Task 8: `/moments` hydration

Follow superpowers:systematic-debugging: `npm run build`, serve `build/`, load `/moments` twice with the console open, capture the React hydration error text, find the first differing node, fix the cause, add a regression test for the cause.

- [ ] Commit `fix(moments): /moments hydrates cleanly` (or a ledgered ruling if it does not reproduce).
