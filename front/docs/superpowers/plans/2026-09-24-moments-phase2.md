# Moments Phase 2 (Stories) Implementation Plan

> **For agentic workers:** execute task-by-task with a fresh implementer per task and a review after each. Steps use `- [ ]`.

**Goal:** make web stories honest and complete against the backend the app already uses: a real question-sticker answer flow with the owner's responses sheet, the viewers sheet, story share, reaction toggle-off, complete highlights (add/remove stories, rename, cover), close-friends privacy in the composer, text overlays and mentions as structured data, and a `stories` locale namespace so the 56 existing keys stop rendering English everywhere. Reels stay app-only (product decision recorded in the marketing copy).

**Input:** `.superpowers/sdd/moments-phase2-inventory.md` (read first: web files, slice endpoints present/unused/missing, every backend route with body/response, app viewer/studio behaviours, prerender + budget constraints). App reference (read-only): `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/stories/**`.

## Global Constraints

- Frontend `/Users/davis/Desktop/Personal/language_exchange_web_front`, branch `feat/stories-2` off `main`. **No `Co-Authored-By` trailers. Commit with an explicit pathspec.** No backend work required.
- Tests `CI=true npx react-scripts test --testPathPattern=<pattern>` (foreground). TypeScript 3.7.2 (no `import type`, no `export type {}`; the build is the type check).
- `/moments` is prerendered and imports `StoriesFeed` eagerly: nothing in this plan may add weight to that eager path or prefetch a protected `/stories/*` endpoint; viewer, composer, highlights and the new sheets stay in lazy routes/chunks; `BUNDLE_BUDGET=1 npm run test:budget` must pass (326 / 307 KB, lazy-chunk floor 35). No browser globals during render.
- Design system: Tailwind + `src/design/*` (Avatar, Badge, ConfirmDialog, DialogShell, SurfaceCard, notify), lucide icons; replace SCSS/hex/inline styles in files this plan touches; reuse `components/moments/comments/*` and `actions/MomentReactionRow.tsx` patterns.
- Copy via `t("stories.<key>") || "English"`; Task S5 creates the `stories` namespace in all 18 locales (existing 56 keys + new ones) and adds `stories` to `localeParity` NAMESPACES.
- Backend contracts are in the inventory; every call must match `routes/story.js`.

---

### Task S1: slice completion and viewer owner tools
**Files:** `src/store/slices/storiesSlice.ts` (add `removeReaction` (`DELETE /stories/:id/react` `{emoji}`), `addStoryToHighlight`, `removeStoryFromHighlight`, `updateHighlight`, `getVideoConfig`; tags so highlight mutations refetch `getHighlights`; tests in a new `storiesEndpoints.test.ts` with mocked fetch), `src/components/stories/StoryViewer.tsx` (+test): question sticker "Answer" → `answerQuestion({ id, text, isAnonymous })` with an inline input + anonymous toggle, success state; reaction toggle uses `removeReaction` when the same emoji is active; owner-only footer button "Viewers" → new `StoryViewersSheet.tsx` (`getStoryViewers`, avatars + names + viewedAt, link to `/community/:id`); owner "Responses" → new `QuestionResponsesSheet.tsx` (`getQuestionResponses`, anonymous rows masked); "Share" → new `StoryShareSheet.tsx` (`shareStory({ id, sharedTo: "dm", receiverId })` with a recent-conversations picker from `getConversations`, plus "Copy link" to `/stories/:id` if such a route exists — check `routes.tsx`); all sheets on `DialogShell`.
- [ ] TDD; commit `feat(stories): real question answers, viewers and responses sheets, share, reaction toggle-off`.

### Task S2: highlights that hold stories
**Files:** `src/components/stories/Highlights.tsx` (+test) → rebuild on `SurfaceCard`: list with covers, create (title + cover from a chosen story), rename/cover edit (`updateHighlight`), delete (confirm), open → grid of its stories with remove; `MyStories.tsx` (+test): per-story "Add to highlight" picker (`addStoryToHighlight`), delete story (`deleteIndividualStory`, confirm), view count opens the viewers sheet from S1; profile `ProfilePage` other-user view: a highlights rail (`getUserHighlights`) above Moments when non-empty (mount-then-decide, lazy chunk for the viewer).
- [ ] TDD; commit `feat(stories): highlights with add, remove, rename and cover; delete stories; highlights rail on profiles`.

### Task S3: composer parity (structured overlays, mentions, link, close friends)
**Files:** `src/components/stories/CreateStory.tsx` (+test; restyle to the design system while touching it): privacy select gains **Close friends** (`privacy: "close_friends"`) with a link to `/settings/close-friends` when the list is empty; text overlays: add/edit/drag (mouse + touch) text with font style, colour and `bgMode`, serialized as the backend's `overlays` JSON (≤ 20; positions normalized 0–1; scale); mentions picker (search users via the existing users search endpoint, ≤ 5, placed like overlays → `mentions` JSON); link sticker (`link` field with URL validation); keep poll XOR question; video stories read `getVideoConfig` and show constraints before upload; `StoryViewer` renders overlays/mentions/link from JSON (mentions tappable → `/community/:id`) — drawing/filters are out of scope (the app bakes them client-side; a canvas editor is its own project).
- [ ] TDD (overlay serialization round-trip, limits, privacy value, viewer rendering positions); commit `feat(stories): text overlays, mentions and link stickers as structured data; close-friends privacy`.

### Task S4: styling and structure
**Files:** `StoriesFeed.tsx/.scss`, `StoryViewer.scss`, `MyStories.scss`, `CreateStory.scss` → Tailwind + tokens (delete the SCSS that becomes empty); `StoriesFeed` stays tiny and eager (ring row only; the viewer opens a lazy chunk); `storiesStyling.test.ts` guard (no hex/inline styles/react-bootstrap/emoji icons in `src/components/stories/**`); keyboard: viewer ←/→/Space/Escape, sheets focus-managed.
- [ ] Commit `refactor(stories): design-system styling, lazy viewer, keyboard support`.

### Task S5: `stories` namespace, verification, merge
- [ ] Extract every `t("stories.…")` key + English fallback from `src/components/stories/**` (script), translate to 17 locales, merge via `scripts/i18n/merge-keys.js`; `localeParity` NAMESPACES += `stories`.
- [ ] Full suite; build; prerender (10 routes; `/moments` HTML unchanged apart from copy); `BUNDLE_BUDGET=1 npm run test:budget`; Playwright with a mocked session at 390/1280: story bar → viewer (progress, hold-to-pause, reaction toggle, question answer POSTs `/question/answer`), owner viewers/responses sheets, highlights add/rename, composer overlays serialize, close-friends option, no console errors/overflow/raw keys.
- [ ] Merge `feat/stories-2` `--no-ff`; push.

## Not in this plan
Reels on web (product decision), drawing/filter canvas, archive screen redesign, music stickers (absent in the app too), AI Study replies (needs backend).
