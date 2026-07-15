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
- `isReel: Boolean` (default false) + new index `{isReel: 1, privacy: 1, createdAt: -1}`. **Index scope stated plainly (reviewer I3):** it serves the prefilter + recency sort; the residual filters (blocked-user `$nin`, `hiddenPendingReview`) and the language partition are non-indexed — acceptable in-memory work at this dataset size, revisit if reels exceed ~10k.
- `hiddenPendingReview: Boolean` (default false) — set when the reel crosses the report threshold (see §4 for the single authoritative report flow).
- Language tag = existing Moment `language` field (defaults from the prompt's language or the poster's `language_to_learn`; editable in composer).
- Prompt linkage = existing `promptId` field (`Moment.js:237`, ref Prompt) — video answers group under the prompt like text answers.
- **Reels are EXCLUDED from the regular card feeds (reviewer I4):** `getMoments` / For You / Following queries gain `isReel: {$ne: true}` so reels live only in the Reels tab (clean identity; no double-surfacing). The existing 11 legacy video moments stay card-feed videos (no backfill to reels).

### 2. Backend
- `GET /moments/reels` — reels feed: `{isReel:true, privacy:'public', hiddenPendingReview:{$ne:true}, isDeleted:{$ne:true}}` + blocked-user `$nin`.
  - **Ranking, specified concretely (reviewer I2 — NOT a mirror of For You, which hard-filters by language and sorts by likeCount):** two buckets, both recency-sorted, concatenated — bucket A = reels whose `language` ∈ {viewer's target language, viewer's native language}; bucket B = everything else. A **soft boost, never a hard filter**, so a thin supply still fills the feed (the "concentrate, don't fragment" rule). No likeCount sort in v1.
  - **Pagination (reviewer M11): cursor-based** on `createdAt` (keyset, `?before=<ts>`), not offset — immune to new-post drift. The grid passes the tapped reel's id + its cursor window to the swipe feed so it opens in place.
- Reuse `PUT /moments/:id/video` upload. **180s enforcement point (reviewer I5):** the upload middleware runs pre-controller with no `isReel` context, so the reel cap is enforced **in the controller** after upload using `req.videoMetadata.duration` (`moments.js:686+`): if the target moment `isReel` and duration > 180s → delete the uploaded object + thumbnail and 400. (The middleware's global 600s cap stays as the outer bound.) Client side, the reel composer caps the trimmer at 180s.
- **Report flow — ONE authoritative store (reviewer C1).** The app has two disjoint report systems: the per-moment `reports[]` array (`POST /moments/:id/report`) and the `Report` collection that the **admin panel actually reads**. Reel reports go through the **`Report` collection** (`type:'moment'`; distinct-reporter dedup comes free from its unique `{reportedBy, type, reportId}` index). On report creation for a reel-moment, count distinct reports for that id — at **≥ 2**, set `Moment.hiddenPendingReview = true` (single atomic `updateOne`; no read-modify-write — reviewer M7 wording corrected: threshold check + flag set are two steps, fine at this volume). **Admin side is a small NEW action, not pure reuse:** the existing admin reports screen gains "restore" (clears `hiddenPendingReview` + resolves the report as no_violation) alongside the existing remove/ban actions (its `content_removed` path already deletes moments).
- `REELS_ENABLED` in `config/limitations.js` (server gate on the reels route) + `reelsEnabled` emitted by app-config (mirrors `roomsEnabled` — the one existing flag precedent).

### 3. Flutter — Reels tab (in Moments)
- **Grid landing**: 3-column thumbnail grid (thumbnails already generated at upload), infinite scroll, language-chip on tiles, "+" FAB for free-form creation. Hidden entirely when `appConfig.reelsEnabled == false`.
- **Full-screen swipe feed**: built FROM the orphaned `VideoFeedItem` pager, but honestly scoped (reviewer M10): the widget self-owns controllers and reads a client-filtered provider, so the real work is a **new controller-pool layer** (hard cap 3 live `VideoPlayerController`s: current ±1; dispose offscreen; thumbnail placeholder while initializing) and a **reels provider backed by the new `GET /moments/reels` endpoint** (not `exploreMomentsProvider`). Autoplay, loop, tap-pause, double-tap like. Action rail: like, comments (existing moment comment sheet), share, report, poster avatar → profile. Opens at the tapped grid tile's reel.
- **Creation — free-form**: record (camera via image_picker — note `_recordVideo` exists but is currently uncalled, reviewer M9) or gallery → existing trim/filter editor (trimmer capped at 180s for reels) → caption + language tag → post (`isReel:true`).
- **Creation — prompt answer**: prompt-of-day card gains "🎥 Answer on camera" beside Write — same composer, pre-tagged with the prompt's id + language.
- **Re-enable moment composer video (reviewer M9 — two commented blocks, not one):** the video button (`create_moment.dart:2362-2371`) AND the video preview section (~`:1958`); also fix the stale "max 3 minutes" comment over the 600s constant in `video_compression_service.dart:55`.
- **UGC compliance gate (reviewer I6 — v1 blocker, not phase 2):** Apple Guideline 1.2 requires an objectionable-content agreement for public UGC video. First open of the Reels tab (or first reel post) shows a one-time **content-policy acceptance** dialog (zero-tolerance terms; stored on the user, reusing the `termsAccepted` pattern). In-feed report AND block affordances are review-checklist items and must be reachable from the action rail/long-press.

### 4. Moderation & safety (v1)
Per-reel report via the **`Report` collection** (`type:'moment'` — the store the admin panel reads; see §2 for why the per-moment array is NOT used); ≥2 distinct reporters → auto-hidden pending review; admin panel gains a small **"restore" action** (clears the flag) beside its existing remove/ban; blocked-user reels filtered from the feed; block reachable from the reel action rail; content-policy acceptance gate before first use (§3); kill switch pulls the tab + 404s the route. **No automated content scanning in v1** — documented risk, revisit when volume grows.

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
