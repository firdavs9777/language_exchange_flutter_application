# Moments Parity with the App — Phase 1 Implementation Plan

> **For agentic workers:** execute task-by-task with a fresh implementer per task and a review after each. Steps use `- [ ]`.

**Goal:** bring the web Moments feed up to the app on the features the backend already supports: translate on tap (moments and comments), corrections, comment engagement (like, emoji react, threaded replies, image comments), a Following tab, and view counting. No backend changes.

**Input:** `docs/superpowers/specs/2026-09-23-moments-parity-inventory.md` (API surface, gap ranking, web feed state).

**Architecture:** all new endpoints land in `src/store/slices/momentsSlice.ts` first (Task 0) so feature tasks only touch components. A reusable `TranslatableText` handles translate-on-tap for any text with a `translate` mutation. `MomentDetail` (995 lines) gains a `comments/` folder of focused components instead of growing. Copy follows `t("moments_section.<area>.<key>") || "English"`; keys for all 18 locales are added once in the final task.

## Global Constraints

- Repo `/Users/davis/Desktop/Personal/language_exchange_web_front`, branch `feat/moments-parity-1` off `main`. **No `Co-Authored-By` trailers on any commit.**
- Tests: `CI=true npx react-scripts test --testPathPattern=<pattern>` (foreground). Baseline 104 suites / 653 tests. TypeScript 3.7.2: no `import type`, no `export type {}`.
- Render-time discipline: no `window`/`document`/`navigator` reads during render (the `/moments` page is prerendered; `src/seo/prerender/renderRoute.test.tsx` must stay green). Anything that needs the viewport (IntersectionObserver for views) runs in effects and is skipped in Node.
- Logged-out visitors can read; every write action (translate, like, react, reply, correction, views) requires auth (backend `protect`). When logged out, actions show the existing sign-in prompt pattern used by like (`moments_section.moment_login_error`), never a crash.
- Backend contracts are read from source before coding: `server.js` mount lines (`/api/v1/moments`, `/api/v1/comments`), `routes/moments.js`, `routes/comment.js`, `controllers/moments.js` (`translateMoment` body `{ targetLanguage }` with ISO 639-1 code; response `data.translatedText`, `sourceLanguage`, `targetLanguage`; `recordViews` body shape — read it), `controllers/comments.js` (`createComment` accepts `text`, optional `parentComment`, optional `correction: { originalText, correctedText, explanation }` (text defaults to "✏️ Correction"); `likeComment`; `reactToComment`/`unreactToComment` with `emoji`; `getReplies` paginated; `uploadCommentImage` multipart `image`; `translateComment` like the moment one), `models/Comment.js` (`text, user, moment, imageUrl, parentComment, replyCount, reactions[], likes[], correction{}`).
- Target language for translation = the viewer's UI language (`i18n.language` mapped to ISO 639-1 via `src/utils/languages.ts` `toBaseIso6391`; `zh_TW` → `zh-TW` if the backend accepts it, else `zh`) unless the text is already in that language (`sourceLanguage === targetLanguage` → show "already in your language").

---

### Task 0: slice endpoints and shared hooks

**Files:** modify `src/store/slices/momentsSlice.ts` (add `translateComment({ commentId, targetLanguage })`, `likeComment(commentId)`, `reactToComment({ commentId, emoji })`, `unreactToComment({ commentId, emoji })`, `getCommentReplies({ commentId, page, limit })`, `uploadCommentImage({ commentId, file })`, `recordMomentViews({ momentIds })`; extend `getMoments` args to `{ page, limit, feed?: 'forYou' | 'following' }` appending `&feed=` only when given so existing cache keys and the prerender prefetch `{ page: 1, limit: 10 }` are unchanged; tags so `likeComment`/`reactToComment`/`addMomentComment` invalidate the moment's comments). Create `src/hooks/useTargetLanguage.ts` (returns the ISO code for the current UI language). Create `src/store/slices/momentsSlice.endpoints.test.ts` asserting URLs/methods/bodies against a mocked fetch for each new endpoint and that `getMoments` without `feed` produces the same URL as before.
- [ ] TDD; commit `feat(moments): slice endpoints for comment engagement, translation, views and the following feed`.

### Task 1: translate on tap for moments

**Files:** create `src/components/moments/TranslatableText.tsx` (+test): props `{ text, onTranslate(): Promise<{ translatedText, sourceLanguage, targetLanguage }>, className }`; renders the text; tap/click or Enter toggles a translated line beneath (dashed rule, brand color, like the hero demo), with states loading / error (inline, retry) / "already in your language"; caches the result in component state; `aria-expanded`; logged-out → calls `onRequireLogin()` instead. Modify `SingleMoment.tsx` and `MomentDetail.tsx` (moment body only) to wrap the moment text in `TranslatableText` wired to `useTranslateMomentMutation` + `useTargetLanguage`. Keep the existing `getMomentTranslations` unused unless it saves a call (read it).
- [ ] TDD (`TranslatableText.test.tsx`: toggles, loading, error retry, same-language message, login gate; `SingleMoment` test for the wiring); commit `feat(moments): translate any moment on tap`.

### Task 2: comment engagement and corrections in MomentDetail

**Files:** create `src/components/moments/comments/CommentList.tsx`, `CommentItem.tsx` (author, time, text via `TranslatableText` with `translateComment`; like count/button; emoji react row reusing `MomentReactionRow` patterns; reply button; image if `imageUrl`; correction card when `comment.correction` exists: original struck through, corrected in brand, explanation), `CommentComposer.tsx` (text, optional image attach via `uploadCommentImage` after create, reply mode with `parentComment`, correction mode with three fields prefilled from the moment text), `RepliesThread.tsx` (`getCommentReplies`, expand/collapse, paginated). Modify `MomentDetail.tsx` to render these instead of its inline comment code; switch its comment data to `momentsSlice`'s `getMomentComments`/`addMomentComment`; remove the duplicate hooks import from `src/store/slices/comments.ts` (keep that file's reducer if `src/store/index.ts` still registers it; delete only what becomes unused and update its test).
- [ ] TDD per component (mock hooks with `mock`-prefixed vars); commit `feat(moments): comment likes, reactions, threaded replies, images and corrections`.

### Task 3: Following tab

**Files:** modify `src/components/moments/MainMoments.tsx`: add `following` to `FeedTab`; show the tab only when logged in; `useGetMomentsQuery({ page, limit, feed: 'following' }, { skip: activeTab !== 'following' })`; empty state copy "Follow people to see their moments here" with a link to `/communities`; move the tab labels (currently hardcoded at lines ~44-48) to `t("moments_section.tabs.*") || English`.
- [ ] TDD (`MainMoments` test: tab hidden logged out, visible logged in, selecting it queries with `feed: 'following'`); commit `feat(moments): following feed tab`.

### Task 4: view counting

**Files:** create `src/components/moments/useMomentViews.ts` (module-level queue; `observe(momentId, element)` via IntersectionObserver at ≥50% for ≥1s; flushes `recordMomentViews({ momentIds })` every 5s and on `pagehide` (guarded `typeof window`); dedupes per session; no-ops when logged out or when `IntersectionObserver` is undefined). Modify `SingleMoment.tsx` to call it with a ref. Test with a stubbed `IntersectionObserver` and fake timers.
- [ ] TDD; commit `feat(moments): count views for moments seen on web`.

### Task 5: locale keys, verification, merge

- [ ] Inventory `t("moments_section.` keys added by Tasks 1–4; add them to all 18 locales via `scripts/i18n/merge-keys.js` (translate the 17); `localeParity.test.ts` NAMESPACES gains `"moments_section"` only if that namespace is already in parity across locales (check first; if not, add a targeted test for the new keys instead).
- [ ] Full suite; `GENERATE_SOURCEMAP=false npm run build`; `build/moments/index.html` still has one `h1` and real feed content; headless-browser smoke on `/moments` and a `/moment/:id` deep link (logged out: translate tap shows the sign-in prompt; logged in with a mocked session: the translate line, comment composer, reply thread and correction card render; no hydration errors).
- [ ] Merge `feat/moments-parity-1` into `main` with `--no-ff`, push.

## Not in this plan
Reels, story studio, story viewers/questions/close friends, AI Study replies (needs backend), moderation of comments, offline queues.
