# Package 3 — Moments + Stories parity — Implementation Plan

Spec: `docs/superpowers/specs/2026-07-18-package-3-moments-stories-parity-design.md`
Branch: `feat/moments-stories-parity`. Execute via subagent-driven-development, low-risk-first.
All backend endpoints already exist (web-only). Tailwind only; no new `.scss`. Verify each task with
`CI=true npx react-scripts test <touched dir> --watchAll=false` + `CI=false react-scripts build`. Never `tsc --noEmit`.
Commit locally per task; do NOT push. After each monolith/shared-file edit, verify `git show --stat` scope.

## Phase A — Moments engagement (backend-ready, mostly isolated)

### Task 1 — momentsSlice endpoints + unified Moment type
Add RTK Query endpoints to `src/store/slices/momentsSlice.ts` (verify against backend `routes/moments.js`):
`reactToMoment` POST `/:id/react {emoji}`, `unreactToMoment` DELETE `/:id/react`, `shareMoment` POST `/:id/share`,
`uploadMomentVideo` PUT `/:id/video` (FormData `video`), `deleteMomentVideo` DELETE `/:id/video`,
`uploadMomentAudio` PUT `/:id/audio` (FormData `audio` + `duration` + `waveform` JSON), `getPromptOfDay` GET `/prompt-of-day?language=`,
`getReelsFeed` GET `/reels?before=&limit=`. Add proper provides/invalidates `Moments` tags.
Introduce ONE canonical `Moment` type in `src/components/moments/types.ts` covering all fields (incl. `video`, `audio{url,duration,waveform}`, `mediaType`, `backgroundColor`, `reactions[]`, `reactionCount`, `shareCount`, `saveCount`, `isSaved`). Add endpoint unit tests (mirror `chatActionsEndpoints.test.ts`). Do NOT rewire components yet.

### Task 2 — MomentReactionRow component (isolated)
`src/components/moments/actions/MomentReactionRow.tsx` — reuse the chat `ReactionRow` pattern (aggregated emoji chips + counts, own-reaction highlight, quick-pick `❤️ 🔥 😂 😢 😮 👏`). Props `{reactions, myUserId, onToggle, showQuickPick}`. RTL test.

### Task 3 — Wire engagement into feed + detail
In `SingleMoment.tsx` + `MomentDetail.tsx`: mount `MomentReactionRow` (long-press/secondary trigger → quick-pick; toggle via react/unreact), add share button (calls `/share`, shows `shareCount`, uses existing `ShareButton` for the OS/clipboard share), add save/bookmark toggle, add double-tap-to-like on the media. Wire the already-present translate + report + delete endpoints. Smallest surgical edits.

## Phase B — Moments media (isolated components, then compose)

### Task 4 — Text/gradient moment renderer
`src/components/moments/media/GradientMomentCard.tsx` — renders `description` centered over the `backgroundColor` gradient preset (13 presets from Flutter `MomentGradients`; map keys→CSS gradients). Used when `mediaType==='text'` or `backgroundColor` set and no images/video. Render in feed + detail. Test.

### Task 5 — Video player (isolated)
`src/components/moments/media/MomentVideoPlayer.tsx` — `<video>` with poster=`video.thumbnail`, controls, tap-to-fullscreen, duration badge. Render for `mediaType==='video'` in feed + detail.

### Task 6 — Voice-note player + recorder
`src/components/moments/media/VoiceNotePlayer.tsx` (waveform + play/scrub from `audio.url`+`audio.waveform`) and `VoiceNoteRecorder.tsx` (MediaRecorder ≤60s, capture waveform samples). Reuse any existing chat voice player/waveform util if present. Tests where feasible.

### Task 7 — CreateMoment richness
Extend `CreateMoment.tsx`: text-only + gradient background picker (reuse Task 4 presets); video attach → two-step upload (create JSON → `uploadMomentVideo`, handle mid-failure retry); voice-note record → `uploadMomentAudio` with duration+waveform. Media types mutually exclusive (image XOR video XOR audio). Keep image path working.

## Phase C — Feed richness

### Task 8 — Feed tabs + prompt-of-day
Add For You / Trending / Explore tabs to `MainMoments.tsx` (consume existing `getMoments`/`getTrendingMoments`/`getExploreMoments`); add a dismissible Prompt-of-Day card (For You) via `getPromptOfDay`, "Answer" → CreateMoment prefilled with `promptId`.

## Phase D — Reels (gated, DEFERRABLE)

### Task 9 — Reels feed (only if REELS_ENABLED)
Feature-detect `/reels` (hide tab on 404). Vertical `PageView`-style video feed + 3-col grid. Defer unless env confirms flag on.

## Phase E — Stories (revive orphaned UI)

### Task 10 — Stories routes + feed strip wiring
Add routes `/create-story` and `/stories/:userId` in `AppRouter.tsx`; replace stub `MainStories`. Mount `StoriesFeed` at the top of the moments feed (own "add" bubble + seen/unseen rings). Delete dead `stories.ts` slice + empty `SingleStory.tsx`/`type.ts`.

### Task 11 — StoryViewer (revive + Tailwind)
Convert `StoryViewer.tsx` off SCSS to Tailwind: segmented progress bars, tap-to-advance (L/R), 5s image timing / video duration, pause-on-hold, header (author+time+close), reactions quick-bar (`/react`), reply→DM (`/reply`), view tracking (`/view`), poll vote + question answer stickers, owner viewers sheet (`/views`+`/reactions`). Handle 403/blocked.

### Task 12 — CreateStory (revive + Tailwind)
Convert `CreateStory.tsx` to Tailwind: image/video/text+gradient modes, caption, hashtags (≤10), privacy (everyone/friends/close), poll + question stickers (mutually exclusive), mention picker. Multipart create (JSON sub-objects as strings); video via `/stories/video`.

## Phase F — Data hygiene

### Task 13 — Cleanup
Collapse remaining divergent Moment shapes onto the Task 1 canonical type; resolve the two comment implementations (pick `comments.ts`, fix its provides/invalidates tag; retire `momentsSlice` comment endpoints or align them); delete `ReservedCreateMoment.tsx`; fill/remove empty `LoadingSpinner.tsx`. Tests + build green.

## Execution notes
- Reactions reuse the shipped chat `src/components/chat/actions/ReactionRow.tsx` as the pattern reference.
- Phases A→C are the high-value core; D (reels) and heavy Stories studio features are deferrable.
- Each task: isolated where possible; commit locally; report scope. Checkpoint with user after Phase A.
