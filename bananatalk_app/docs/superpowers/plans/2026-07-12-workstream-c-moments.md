# Workstream C: Moments 2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the dead generic feed (23 posts / 2.5 months) into a language-learning feed: For You ranking by language match, daily prompts to fix cold-start, corrections on posts, audio moments, and a card/comment/edit UI refresh.

**Architecture:** Backend already has language-indexed moments (ISO codes), trending endpoint, generic comments, and full audio infra (audioUtils + Spaces storage). Two prod-verified blockers shape the design: (1) **users store language NAMES ("Chinese (Simplified)") while moments store ISO codes ("en")** — a normalization util is Task 1 and everything ranks on normalized codes at query time (no data migration); (2) 66 users have same-language pairs and 98 have empty languages (legacy) — every feed mode must fall back gracefully to trending. Corrections are Comment-model extensions (no new collection). Audio moments reuse the chat voice recorder/player and audioUtils validation.

**Tech Stack:** Node/Express + Mongoose, Flutter + Riverpod. Branches `workstream-c-moments` (create from current main in both repos). Single end-of-workstream commit per repo (standing user instruction).

## Global Constraints

- `package:` imports only; teal #00BFA5 / banana #FFD54F tokens; dark-mode parity
- Backend responses additive — shipped app must keep working (default getMoments behavior unchanged when no `feed` param)
- Do not start the backend server locally (production Mongo); verify via node --check + node -e
- `flutter analyze` 0 errors/warnings; new pure logic gets tests; existing tests keep passing
- Prompt seed languages priority (prod cohorts): zh→en (103 users), ar→en (53), en→ko (21), ru→en (20), plus generic English
- NO commits until all tasks complete (single commit per repo at gate)

---

## Phase 1 — Backend

### Task 1: Language normalization + For You / Following feed modes

**Files:**
- Create: `utils/languageCodes.js`
- Modify: `controllers/moments.js:42-120` (`getMoments`)

**Interfaces:**
- Produces: `toIso(nameOrCode) -> 'en'|null` (maps full names like 'Chinese (Simplified)'→'zh', 'English'→'en', passes valid ISO codes through, null for empty/unknown); `getMoments` gains `feed=forYou|following` query param. `forYou`: moments whose `language` ∈ [iso(user.language_to_learn), iso(user.native_language)], sorted `{likeCount:-1, createdAt:-1}` recency-weighted (simple: sort createdAt desc, but pin engagement: use existing trending sort for the first page tie-break — keep it ONE query, no aggregation). `following`: `{user: {$in: me.following}}` sorted createdAt desc. Both fall back to the default public feed when the user's languages normalize to null or equal codes. No `feed` param → existing behavior byte-identical.

- [ ] **Step 1:** Write `utils/languageCodes.js`: a `NAME_TO_ISO` map covering the app's full language list (source of truth: the Flutter `FilterOptions.allLanguages` list in `lib/pages/moments/filter/moment_filter_model.dart` — mirror its ~40 `{code,name}` pairs, plus variants 'Chinese (Simplified)'→'zh', 'Chinese (Traditional)'→'zh'), `toIso()` trimming/case-insensitive, ISO pass-through via the same table's codes.
- [ ] **Step 2:** In `getMoments`, after auth/blocking setup: read `req.query.feed`; for `forYou` fetch `req.user`'s two language fields, normalize, build `query.language = {$in: [codes]}` when valid+distinct, else leave query unchanged (fallback); for `following` use `req.user.following` (`$in`, empty array → fallback). Add `feedMode` to the response meta for the app to display.
- [ ] **Step 3:** Verify: `node --check` both files; `node -e` asserts: toIso('Chinese (Simplified)')==='zh', toIso('English')==='en', toIso('en')==='en', toIso('')===null, toIso('Klingon')===null.
- [ ] **Step 4:** NO commit (end-of-workstream policy).

### Task 2: Daily prompts — model, seed, endpoint

**Files:**
- Create: `models/Prompt.js`, `routes/prompts seeding via` `_data/prompts.json` + `seedPrompts` script in `migrations/seedPrompts.js`
- Modify: `routes/moments.js`, `controllers/moments.js` (add `getPromptOfDay`)

**Interfaces:**
- Produces: `Prompt {text: String, language: String(ISO, the language learners should WRITE in), level: String('any'|'beginner'), emoji: String, active: Boolean}`; `GET /api/v1/moments/prompt-of-day?language=ko` → `{success, data: {promptId, text, language, emoji}}` — deterministic daily rotation: `prompts[dayOfYear % count]` among active prompts for that language, falling back to 'en'. `Moment` gains optional `promptId` (ObjectId, no index needed at this scale).

- [ ] **Step 1:** Model + 40-prompt seed JSON: 10 'en' (for zh/ar/ru→en learners), 10 'ko', 10 'zh', 10 generic 'en' conversation prompts. Example texts: "Describe your breakfast today 🍳", "What's a word in this language you love? Why?", "Post a photo of your favorite place and describe it". Seed script upserts by text (idempotent).
- [ ] **Step 2:** `getPromptOfDay` controller + route (optionalAuth: language param wins, else derive from user's language_to_learn via `toIso`). Add `promptId` to Moment schema + accept it in `createMoment`'s allowed fields.
- [ ] **Step 3:** Verify node --check all; node -e: rotation is deterministic for a fixed date; seed script dry-run prints 40 items (do NOT run against prod from local — the seed runs on the server post-deploy; note this in the report).
- [ ] **Step 4:** NO commit.

### Task 3: Corrections on posts (Comment extension)

**Files:**
- Modify: `models/Comment.js` (add optional `correction` subdoc), `controllers/comments.js` (`createComment` accepts it; `getComments` returns it — verify serialization passthrough)

**Interfaces:**
- Produces: `Comment.correction = {originalText: String(max 2000), correctedText: String(max 2000), explanation: String(max 500)}` (optional, no default doc — absent for normal comments). `createComment` accepts `correction` object in body; when present and `text` empty, set `text = '✏️ Correction'` (list previews + notifications keep working). Existing `moment_comment` notification fires unchanged.

- [ ] **Step 1:** Schema subdoc (use `_id: false`); validate correctedText required when correction present.
- [ ] **Step 2:** Controller: whitelist `correction` in createComment body handling; ensure `.lean()`/populate paths in getComments and getReplies include it (they return full docs — confirm no field projection strips it).
- [ ] **Step 3:** node --check; node -e constructs a Comment instance with/without correction and validates.
- [ ] **Step 4:** NO commit.

### Task 4: Audio moments (model + upload)

**Files:**
- Modify: `models/Moment.js` (audio fields + mediaType), `controllers/moments.js` (upload handler), `routes/moments.js`

**Interfaces:**
- Produces: `Moment.audio = {url, duration(sec, max 60), waveform: [Number], mimeType, fileSize}`; `mediaType` enum gains `'audio'`; `PUT /api/v1/moments/:id/audio` (protected) — multipart upload mirroring the existing `momentPhotoUpload`/video pattern: validate via `audioUtils.validateAudioFile`, filename via `generateAudioFilename('moment-audio')`, store to Spaces the same way voice messages do (copy the storage call from the voice upload path), set mediaType='audio'. Reject >60s (client sends duration; also cap file 10MB).

- [ ] **Step 1:** Schema fields + enum value.
- [ ] **Step 2:** Upload controller + route following the photo-upload handler's structure exactly (auth: owner-only, same error responses).
- [ ] **Step 3:** node --check; trace in report which storage helper was reused.
- [ ] **Step 4:** NO commit.

## Phase 2 — App

### Task 5: Feed tabs + service plumbing

**Files:**
- Modify: `lib/providers/provider_root/moments_providers.dart` (feed param + prompt fetch), `lib/pages/moments/feed/moments_main.dart` (tabs)

**Interfaces:**
- Produces: `getMoments({page, limit, String? feed})` appends `&feed=` when set; providers `forYouMomentsProvider`, `followingMomentsProvider` (family or distinct FutureProviders mirroring `momentsFeedProvider`); `promptOfDayProvider` FutureProvider hitting `/moments/prompt-of-day`. `moments_main.dart` gets a segmented control / TabBar with **For You (default) / Following / Trending** above the existing filter bar; Trending uses the existing `trendingMomentsProvider`; the existing filter bar continues to apply client-side on whichever tab's data (unchanged utility).

- [ ] **Step 1:** Service + providers (mirror existing patterns; keep `momentsFeedProvider` untouched for compatibility anywhere else it's read).
- [ ] **Step 2:** Tabs UI: teal indicator, persisted last-selected tab (SharedPreferences), pull-to-refresh invalidates the active tab's provider only.
- [ ] **Step 3:** `flutter analyze` clean on touched paths; existing tests pass.
- [ ] **Step 4:** NO commit.

### Task 6: Prompt card + composer prefill

**Files:**
- Create: `lib/pages/moments/feed/prompt_of_day_card.dart`
- Modify: `lib/pages/moments/feed/moments_main.dart` (card atop For You), `lib/pages/moments/create/create_moment.dart` (prompt chip prefill + promptId), `lib/providers/provider_root/moments_providers.dart` (createMoments gains promptId)

**Interfaces:**
- Consumes: `promptOfDayProvider` (Task 5).
- Produces: `PromptOfDayCard` — banana-accent card: emoji + prompt text + "Answer" button → opens `CreateMoment(prefillPrompt: prompt)`; `CreateMoment` gains optional `prefillPrompt` (shows a dismissible chip above the text field, sends `promptId` on create). Card renders only on the For You tab, `SizedBox.shrink` on error/loading. Empty-feed state also points at the prompt ("Be the first to answer today's prompt!").

- [ ] Steps: build card → wire composer prefill + promptId param end-to-end → analyze clean → NO commit.

### Task 7: Corrections UI

**Files:**
- Create: `lib/pages/moments/corrections/correction_sheet.dart`
- Modify: comment rendering (comments list card under `lib/pages/comments/` — locate the comment card widget), `lib/providers/provider_models/comments_model.dart` (+correction fields), `lib/providers/provider_root/comments_providers.dart` (createComment accepts correction), `lib/pages/moments/card/moment_card.dart` (overflow menu gains "Suggest a correction", correction-count chip)

**Interfaces:**
- Produces: `CorrectionSheet(momentText, onSubmit(original, corrected, explanation))` — bottom sheet: original text (read-only selectable), corrected-text field prefilled with the original for inline editing, optional explanation field, submit → createComment with correction payload. Rendering: comments carrying `correction` render a distinct panel (reuse the translated-panel visual pattern): original with strikethrough style where it differs, corrected in teal, explanation caption. Simple word-level diff helper `List<DiffSpan> diffWords(a, b)` in the sheet file with a unit test (equal/replaced/inserted/deleted cases).

- [ ] Steps: TDD the `diffWords` helper (test file `test/moments/diff_words_test.dart`) → model fields → sheet → render panel → card entry point + count chip (count = comments where correction != null, computed client-side from loaded comments; skip server aggregation at this scale) → analyze + tests → NO commit.

### Task 8: Audio moments UI

**Files:**
- Modify: `lib/pages/moments/create/create_moment.dart` (record entry), `lib/pages/moments/card/moment_card_media.dart` (audio playback), `lib/providers/provider_root/moments_providers.dart` (uploadMomentAudio)

**Interfaces:**
- Consumes: `VoiceRecorderWidget(onRecordingComplete(File, int duration, List<double> waveform), onCancel)` and `VoiceMessagePlayer(audioUrl, durationSeconds, waveform, ...)` — existing chat widgets, reused as-is.
- Produces: composer mic button → recorder inline (60s cap enforced in UI); recorded audio preview with delete; on post: create moment then `uploadMomentAudio(momentId, file, duration, waveform)` multipart to the Task 4 endpoint. Card: `mediaType=='audio'` renders VoiceMessagePlayer full-width in the media slot.

- [ ] Steps: service method → composer integration → card rendering → analyze → NO commit.

### Task 9: UI refresh + edit mode

**Files:**
- Modify: `lib/pages/moments/card/moment_card.dart` + `moment_card_header.dart` (polish: language badge chip from moment.language, cleaner spacing/typography per app tokens), `lib/pages/moments/single/single_moment.dart` (comment pagination: load 50, "load more" button using existing page param), `lib/pages/moments/create/create_moment.dart` (finish `momentToEdit` wiring: prefill all fields, call updateMoment instead of create, entry from card overflow "Edit" for own posts), empty states across tabs

**Interfaces:**
- Consumes: existing `updateMoment(id, ...)` service (exists, unused by UI).

- [ ] Steps: card polish → comment pagination → edit flow end-to-end (own-post overflow → composer in edit mode → save → feed refresh) → designed empty states (For You: prompt CTA; Following: "follow people from Community") → analyze + full moments-area smoke via tests → NO commit.

## Phase 2.5 — Stories (user-added scope: "Instagram-like, cooler")

Scout finding: backend Story/StoryHighlight models + routes are already Instagram-grade (views[], reactions, replies→DM, polls, questionBox, highlights, close friends, link, hashtags all exist); app has a solid viewer (progress bars, tap zones, hold-pause, swipe-down, reaction bar, reply sheet) and creator (media, text stories, overlays, privacy). All story work below is last-mile UI over EXISTING endpoints — no backend changes except where noted.

### Task 10: Viewer list + engagement for own stories

**Files:**
- Create: `lib/pages/stories/viewer/story_viewers_sheet.dart`
- Modify: `lib/pages/stories/viewer/story_viewer_screen.dart` (own-story bottom-left eye affordance)

**Interfaces:**
- Consumes: `StoriesService.getStoryViewers({storyId})` (owner-only endpoint, already implemented, never called) and `getStoryReactions({storyId})`.
- Produces: on OWN stories, a bottom-left "👁 N" chip; tap → draggable bottom sheet: viewer list (avatar, name, relative time; reaction emoji beside viewers who reacted). Pauses playback while open, resumes on close. Empty state "No views yet".

- [ ] Steps: sheet widget → viewer_screen integration (own-story detection exists for the Delete flow — reuse) → analyze → NO commit.

### Task 11: Interactive stickers — poll + question creation and results

**Files:**
- Modify: `lib/pages/stories/create/create_story_screen.dart` (sticker menu: Poll / Question)
- Create: `lib/pages/stories/create/poll_sticker_editor.dart`, `question_sticker_editor.dart`
- Modify: `lib/pages/stories/viewer/story_viewer_screen.dart` + existing `story_poll_widget.dart` / `story_question_box_widget.dart` (owner results view)

**Interfaces:**
- Consumes: existing create payload fields `poll: {question, options[]}` and `questionBox: {prompt}` (StoriesService.createStory already forwards them); vote/answer endpoints + display widgets already exist.
- Produces: sticker button in creator → editors (poll: question + 2-4 options; question: prompt) → attached to the story payload; viewer renders the existing widgets (verify they're actually mounted for stories carrying polls/questions — wire if not); OWNER sees results: poll percentages on the widget, question responses via `getQuestionResponses` in a sheet.

- [ ] Steps: editors → creator wiring → viewer mount + owner results → analyze → NO commit.

### Task 12: Highlights on profile

**Files:**
- Modify: own-profile page + public profile (`single_community_screen.dart` area — locate profile header sections) to add a highlights row
- Create: `lib/pages/stories/highlights/highlights_row.dart`, `highlight_editor_sheet.dart`
- Modify: `story_viewer_screen.dart` (accept a highlight's story list as source; "Add to highlight" action on own stories)

**Interfaces:**
- Consumes: full existing highlights service (getMyHighlights, getUserHighlights, create/update/delete, add/removeFromHighlight).
- Produces: circular highlights row under the profile header (cover + title, "New" button on own profile); tap → viewer plays the highlight's stories (reuse viewer with a story-list source); own-story viewer overflow gains "Add to highlight" (picker: existing highlight or create new with title).

- [ ] Steps: row + editor → profile integration (own + public) → viewer source param + add-to-highlight action → analyze → NO commit.

### Task 13: Viewer/creator cool-factor polish

**Files:**
- Modify: `story_viewer_screen.dart`, `create_story_screen.dart`, `stories_feed_widget.dart`

**Work items (all small):**
- Close-friends stories show the green ring on feed circles + a "Close friends" badge in the viewer (privacy field already delivered)
- Link sticker: when `story.link.url` present, render a tappable pill → `url_launcher` (check pubspec first; if absent, render non-tappable with copy action instead of adding a dependency)
- Save own story to gallery (overflow action; use existing image/video save capability if a package exists in pubspec — otherwise share_plus fallback)
- Feed circles: gradient ring animation on unviewed (story_gradient_ring.dart exists — add subtle rotation/shimmer), viewed = greyed
- Creator: hashtag text field (backend field exists) chips-style
- [ ] Steps: item-by-item, analyze after each file, NO commit.

## Phase 3 — Gate

### Task 14: Combined gate + final review + single commits

- [ ] **Step 1:** `flutter analyze` (full) 0 errors/warnings; `flutter test` all green; backend `node --check` on all touched files.
- [ ] **Step 2:** Final whole-branch review (both diffs), focus: old-app compatibility of getMoments changes (no-param behavior identical), feed fallback paths for the 66 same-language + 98 empty-language users, upload auth on the audio endpoint, comment serialization of corrections.
- [ ] **Step 3:** One batched fix round if findings.
- [ ] **Step 4:** Single commit per repo; merge+push on user go-ahead. Post-deploy server step: run `node migrations/seedPrompts.js` once.
- [ ] **Step 5:** Success metric: moments/week (baseline ~2) — re-measure with the saved query.

## Ads-readiness (user direction: ads come later — don't block them)
- The existing native-ad insertion (every 4th item in MomentsFeedWidget) must survive untouched: all three tabs (For You/Following/Trending) render through the same feed widget, so ad slots apply to every tab automatically. T5/T9 must not restructure that insertion loop.
- The prompt card (T6) sits ABOVE the list, never inside the ad cadence.
- Story viewer's story-list source parameter (T12) is the future hook for interstitial story ads (inject sponsored story into the list) — keep the source a plain `List<Story>` so injection stays trivial.
- No ad work in this workstream; this section only protects the seams.

## Self-review notes
- Spec coverage: For You ✓ (T1/T5), prompts ✓ (T2/T6), corrections ✓ (T3/T7), audio ✓ (T4/T8), UI refresh (card/comments/edit/empty) ✓ (T9). USER-ADDED stories scope ✓ (T10-T13: viewer list, poll/question stickers, highlights, polish). Out of scope: video re-enable for moments, ML ranking, ads (readiness only), music picker + drawing tools for stories (biggest remaining IG gaps — deliberate cut, note for later).
- Sequencing/parallelism: backend T1 first, then T2+T3 parallel, then T4 (shared controllers/moments.js). App: T5 first, then T6/T7/T8 parallel (T6 before T8 — both touch create_moment.dart). Stories T10-T13 are independent of moments tasks and parallel-safe among themselves EXCEPT T10/T11/T12/T13 all touch story_viewer_screen.dart — sequence stories serially T10→T11→T12→T13, running in parallel WITH the moments track. T9 last on the moments track. T14 gate last overall.
- Type consistency: promptId String on both sides; correction field names identical (originalText/correctedText/explanation) across schema, controller, Dart model, sheet; story tasks reuse existing service signatures verbatim.
