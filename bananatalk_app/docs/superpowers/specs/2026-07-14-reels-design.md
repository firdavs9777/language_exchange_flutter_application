# Reels — Language-Learning Short Video in Moments — Design

**Date:** 2026-07-14
**Status:** Approved by user (2026-07-14, interactive design session)
**Repos:** `bananatalk_app` (Flutter) + `language_exchange_backend_application` (Node/Express + MongoDB)

## Goal

An Instagram/TikTok-style short-video experience inside the Moments menu: a Reels tab with a thumbnail grid landing that opens a full-screen vertical swipe feed of ≤3-minute videos — scoped as **language-learning video** (prompt answers on camera, speaking practice, native-speaker explainers, culture clips), not a generic entertainment feed.

## Why / measured reality (2026-07-14, prod)

| Signal | Number | Implication |
|---|---|---|
| Video stories ever | 11 (3 in last 30d) | Free-form video creation is near-zero today |
| Video chat messages ever | 7 of 17.8k | same |
| Moments last 30d | **28** vs 23 in the prior 2.5 months | **Workstream C's prompt engine revived creation ~10×** — supply responds to product |
| Weekly actives | ~178 | Feed must tolerate thin supply; ranking must concentrate, not fragment |

**The risk is content supply, not engineering.** The design leans on the proven prompt engine as the supply loop. User explicitly deferred seeded starter content and native-speaker creator nudges (phase 2 levers if the feed is thin after 2–3 weeks).

## Infra reality (2026-07-14 scout) — ~70% already exists

**Reuse (verified, file:line in scout report):**
- **Moment model fully supports video**: `video.{url,thumbnail,duration,width,height,mimeType,fileSize}`, `mediaType:'video'` enum, and a purpose-built `{mediaType, privacy, createdAt}` feed index (`models/Moment.js:164-258`). Upload endpoint exists: `PUT /moments/:id/video` (`routes/moments.js:74-81`, controller `moments.js:660+`) with thumbnail generation (ffmpeg on server) + DigitalOcean Spaces + CDN (public-read, byte-range seek works natively).
- **The composer's video button is merely commented out** (`create_moment.dart:2362-2371`, "TODO: Re-enable") — the pick→edit→compress→upload path behind it is intact.
- **A vertical reels pager already exists but is orphaned**: `lib/pages/explore/explore_main.dart` `PageView.builder(scrollDirection: vertical)` + `VideoFeedItem` (autoplay/loop/tap-pause/overlay) — never wired into navigation, and naive (eager-inits every controller).
- On-device: `video_compress` + `video_trimmer` + editor screen with filters; players (`MomentVideoPlayer`, `FullScreenVideoPlayer`, Chewie).
- Social plumbing: likes/comments/reports/notifications all operate on Moment — reels inherit them for free.

**Genuinely new:** feed ranking (kept simple v1), player lifecycle management (preload/dispose), grid landing, prompt-camera entry, duration-cap tightening, report auto-hide rule, kill switch.

## Locked decisions

| Decision | Choice |
|---|---|
| Purpose | **Language-learning video** (differentiates from TikTok; ties to prompt engine) |
| Supply (v1) | **Prompt-of-day "Answer on camera"** + **free-form reels**. Seeding + creator nudges deferred to phase 2 |
| Data model | **Reels ride on Moment** (`isReel: true`) — no new collection; likes/comments/reports/feeds/notifications inherited |
| Experience | **Thumbnail grid landing** (static thumbs) → tap opens **full-screen vertical swipe feed** at that reel. Moving/animated grid tiles = phase 2 (server ffmpeg preview clips) |
| Max duration | **180 seconds** (tightened from the current 600s cap), client- and server-enforced |
| Moderation | **Reactive + kill switch**: per-reel report, **auto-hide at 2 reports pending admin review**, admin remove/ban (existing panel), blocked users filtered, `REELS_ENABLED` flag. No automated scanning v1 (revisit at volume) |
| Ranking (v1) | Language-relevant first (viewer's target language + learners of viewer's native language), then recency. No ML |

## Components

### 1. Data model (additive on Moment)
- `isReel: Boolean` (default false, indexed with the existing video-feed index pattern: `{isReel, privacy, createdAt}`).
- `reportsCount` already derivable from the per-moment report array; add `hiddenPendingReview: Boolean` (set true when report count hits 2; admin clears or deletes).
- Language tag = existing Moment `language` field (defaults from the prompt's language or the poster's `language_to_learn`; editable in composer).
- Prompt linkage = existing `promptId` field from Workstream C (video answers group under the prompt like text answers).

### 2. Backend
- `GET /moments/reels` — paginated reels feed: `{isReel:true, privacy:'public', hiddenPendingReview:{$ne:true}}`, blocked-user filtering, ranked language-relevant-first then `createdAt` desc (mirrors the For You mode's pattern; uses the existing indexes + a new `{isReel, privacy, createdAt}` index).
- Reuse `PUT /moments/:id/video` upload; **tighten duration validation to 180s when `isReel`** (server-side ffprobe check already runs post-upload; reject + delete on over-limit).
- Report flow: on report create for a reel-moment, if distinct-reporter count ≥ 2 → set `hiddenPendingReview:true` (server-side rule). Admin endpoints reuse the existing moderation panel actions (approve = clear flag; remove = delete moment).
- `REELS_ENABLED` in `config/limitations.js` (server gate on the reels route) + `reelsEnabled` in app-config (same pattern as `roomsEnabled`/`coinsEnabled`).

### 3. Flutter — Reels tab (in Moments)
- **Grid landing**: 3-column thumbnail grid (thumbnails already generated at upload), infinite scroll, language-chip on tiles, "+" FAB for free-form creation. Hidden entirely when `appConfig.reelsEnabled == false`.
- **Full-screen swipe feed**: rehabilitate the orphaned `VideoFeedItem` pager — controller lifecycle fixed to current ±1 (preload next, dispose offscreen), autoplay muted-off, loop, tap-pause, double-tap like. Action rail: like, comments (existing moment comment sheet), share, report, poster avatar → profile. Opens at the tapped grid tile's index.
- **Creation — free-form**: record (camera via image_picker) or gallery → existing trim/filter editor → caption + language tag → post (`isReel:true`). 180s trim cap.
- **Creation — prompt answer**: prompt-of-day card gains "🎥 Answer on camera" beside Write — same composer, pre-tagged with the prompt's id + language.
- Re-enable the moment composer's video button as part of this work (the TODO), since the pipeline is shared.

### 4. Moderation & safety (v1)
Per-reel report via existing `Report type:'moment'`; ≥2 distinct reporters → auto-hidden pending review; admin panel approve/remove/ban (existing); blocked-user reels filtered from feed; kill switch pulls the tab + 404s the route. **No automated content scanning in v1** — documented risk, revisit when volume grows or before any store-review flag.

### 5. Notifications
None new — reel likes/comments flow through the existing (post-E-core, persisted + deep-linked) `moment_like`/`moment_comment` types. Phase 2 candidate: "your prompt answer got X views."

## Out of scope (v1)
Duets/stitches, effects beyond existing filters, subtitle overlays, watch-time analytics/ML ranking, server-side transcoding, animated grid-tile previews (phase 2 via server ffmpeg preview clips), seeded starter content + creator-nudge pushes (phase 2 supply levers), view counts.

## Error handling & edge cases
- Upload failure/over-duration: server deletes the orphan file (existing behavior), composer surfaces retry.
- Feed with < 3 reels: grid shows a designed empty state pointing at the prompt-camera CTA (not a blank screen).
- Player OOM protection: hard cap of 3 live controllers; dispose on page change; thumbnail placeholder while initializing.
- Auto-hide race: report-count check is atomic on the report write; approve clears `hiddenPendingReview` and resets nothing else.
- Kill switch off mid-session: tab hidden on next app-config fetch; direct route 404 tolerated.

## Testing
- Backend (node:test, Node v24 runner): reels-feed query filter (isReel/privacy/hidden/blocked), 180s validation branch, auto-hide-at-2-reports rule, kill-switch gate.
- `flutter analyze` clean; `package:` imports.
- Device smoke (gate): record a 30s prompt answer → appears in grid + swipe feed; swipe through 5+ reels without jank/memory growth; report from a second account twice → reel hides; admin restores; kill switch pulls the tab.

## Success metric
Reels posted/week (target: ≥10 by week 3 — prompt engine drove text moments to ~28/mo) and % of reels-tab openers who watch ≥3 reels. If supply < 5/week by week 3 → activate phase-2 levers (seeding, native-speaker nudges).
