# Package 3 — Moments richness + Stories parity (web) — Design Spec

Date: 2026-07-18
Repo: `front` (React 18 CRA + Redux Toolkit / RTK Query + socket.io)
Source of truth: Flutter app `bananatalk_app` (mobile). Backend: `backend` (Node/Express).

## Goal
Bring web Moments to feature parity with the Flutter Moments module (video, voice notes,
text/gradient moments, emoji reactions, share tracking, prompt-of-day, reels), and ship
Stories on web by wiring up the already-built-but-orphaned Stories UI + slice.

## Ground truth from recon (2026-07-18)

### Backend readiness — EVERYTHING needed already exists (web-only effort)
- **Moments** endpoints all present: CRUD, `/like` `/dislike`, `/react` + `DELETE /react` (emoji, `reactions[]`/`reactionCount`, distinct from likes), `/save` `/unsave` `/saved`, `/share` (increments `shareCount`), `/photo` `/video` `DELETE /video` `/audio` (multipart; audio body carries `duration` + `waveform[]`), `/translate` `/translations`, `/prompt-of-day`, `/reels` (keyset `?before=&limit=`, **gated by `REELS_ENABLED` env → 404 when off**), `/trending`, `/explore`, comments sub-router. `Moment` model already has `video{}`, `audio{url,duration,waveform}`, `mediaType`, `backgroundColor` (gradient enum), `reactions[]`, `shareCount`, `savedBy`, `promptId`, `isReel`.
  - **Two-step media flow:** `POST /moments` (JSON) creates, then `PUT /:id/video|audio|photo` (multipart) attaches. No single multipart-create.
- **Stories** endpoints all present at `/api/v1/stories` (no feature flag): feed, my-stories, user/:id, single, create (multipart `media` ≤5) + `/video`, view, views, react (+remove+list), reply(→DM), poll/vote, question/answer(+responses), share, highlights CRUD (+add/remove story), close-friends, archive, video-config. `Story` model has media/text/gradient, `views[]`, `reactions[]`, `poll{}`, `questionBox{}`, `mentions[]`, `overlays[]`, `highlight`, `expiresAt` (24h, cron-archived). Socket push (owner-only): `storyReaction`, `storyReply`, `storyPollVote`, `storyQuestionAnswer`. No real-time "new story" broadcast — feed is pull. Backend has `docs/STORIES_FRONTEND_GUIDE.md` + `STORIES_API_RESPONSE_EXAMPLES.md`.
- **No quiz sticker, no music/link create** anywhere (schema-only). Reels behind env flag — confirm target env before building reels UI.

### Web current state
**Moments** (`src/components/moments/`, `src/store/slices/momentsSlice.ts`):
- Has: feed (image-only, `MainMoments`), detail (`MomentDetail`, image carousel+lightbox), create (image-only), like/dislike, save/unsave+`SavedMoments`, translate endpoints (unwired), report endpoint (unwired), comments.
- Missing: video render/upload, voice record+waveform, text/gradient compose+render, emoji reactions, share tracking, prompt-of-day, reels, trending/explore tabs, double-tap-like, translate UI, save-in-feed, working delete.
- **Data hygiene debt (prereq risk):** 4 divergent Moment TS shapes (`types.ts`, `MyMoments`, `SavedMoments` uses `content`/`videoUrls`/`likesCount`, `MomentDetail`); two comment implementations (`momentsSlice` `content/parentId` vs `comments.ts` `text`) with a provides/invalidates tag mismatch (`Comments` vs `Comment`). `ReservedCreateMoment.tsx` is a dead mock. `LoadingSpinner.tsx` is empty.

**Stories** (`src/components/stories/`, `src/store/slices/storiesSlice.ts`):
- **Not greenfield.** Full 23-endpoint `storiesSlice` registered in store (`Stories` tag). Built components: `StoriesFeed` (ring strip, SCSS), `StoryViewer` (SCSS), `CreateStory` (SCSS), `MyStories` (SCSS+bootstrap), `Highlights` (Tailwind, routed at `/highlights`). `MainStories` is a stub `<h1>`; `SingleStory.tsx`/`type.ts` are empty.
- **Orphaned:** only `/stories`→stub and `/highlights` are routed. `StoriesFeed`/`StoryViewer`/`CreateStory`/`MyStories` imported nowhere; `StoriesFeed` navigates to non-existent `/create-story` and `/stories/:userId`. Dead second slice `stories.ts` (commented out).

## Design system
Tailwind, dark-mode aware, lucide-react icons. Reference modern look: `EditProfile.tsx` and the just-shipped chat `actions/` components. Reuse the chat `ReactionRow` pattern for moment/story emoji reactions. Do NOT add new `.scss`; convert orphaned Stories SCSS components to Tailwind when reviving them.

## Scope & phases (low-risk / high-value first)
- **Phase A — Moments engagement (backend-ready, isolated):** emoji reactions (reuse ReactionRow), share tracking (`/share` + count), save toggle in feed+detail, double-tap-to-like, wire translate + report + delete. Unify Moment TS type first (data-hygiene prereq).
- **Phase B — Moments media:** video player (feed+detail) + upload; voice-note recorder (≤60s) + waveform capture + player; text-only + gradient composer & renderer (`backgroundColor` presets).
- **Phase C — Moments feed richness:** For You / Trending / Explore tabs; prompt-of-day card (For You).
- **Phase D — Reels (gated):** vertical video feed + grid; only if `REELS_ENABLED` in target env. Deferrable.
- **Phase E — Stories:** add routes (`/create-story`, `/stories/:userId`); wire `StoriesFeed` into the moments feed top; revive+Tailwind-convert `StoryViewer` (progress bars, tap-advance, react, reply→DM, view tracking, poll/question, viewers sheet) and `CreateStory` (image/video/text+gradient, poll/question/mention stickers, privacy); highlights already routed. Interactive-sticker socket updates optional (owner-only push).
- **Phase F — Data hygiene:** collapse the 4 Moment types into one, resolve the two comment slices, delete dead `ReservedCreateMoment`/`stories.ts`, fill empty files.

## Non-goals / deferred
Quiz stickers, story music/link stickers (no backend), story draw/filters studio (heavy — v2), video trim/compression pipeline (upload raw; rely on backend limits), deferred-install linking. Reels deferred unless env-enabled.

## Risks
- Media upload is two-step (create JSON → multipart attach); handle failure between steps (moment exists without media) with retry, mirroring app.
- Multipart JSON sub-objects (overlays/poll/mentions/hashtags) must be JSON-encoded strings.
- Reels 404 when flag off — feature-detect, hide the tab.
- Reviving orphaned Stories components risks stale API assumptions — verify each against `storiesSlice` + backend guide before wiring.
- Data-hygiene refactor touches many files — do it as its own reviewed task, tests+build green.
