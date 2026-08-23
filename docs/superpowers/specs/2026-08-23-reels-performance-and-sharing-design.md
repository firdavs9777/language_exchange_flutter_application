# Reels — Playback Performance & Sharing — Design Spec

**Date:** 2026-08-23
**Status:** Approved

## Problem

The Reels experience is functional but does not feel like a modern short-video
product:

1. **Nothing is cached.** `ReelControllerPool.activate()` builds every
   controller with `VideoPlayerController.networkUrl`, so re-watching a reel or
   swiping back re-downloads it in full. Only `current + 1` is preloaded, so a
   fast swiper waits on the network on nearly every swipe.
2. **The grid is static.** `ReelsGridScreen` shows still JPEG thumbnails, so
   the landing surface reads as a photo gallery rather than a video feed.
3. **There is no view count.** `Moment` has `likeCount`, `commentCount`,
   `shareCount`, `saveCount` and `reactionCount` — but no view or play count,
   and no endpoint to record one. Tiles have no social-proof signal.
4. **A reel cannot be sent to a friend in-app.** `shareUrl('moment', id)`
   produces an external web link, but there is no way to share a reel into a
   BananaTalk chat, even though the app already does exactly this for stories.

## Goals

- Swiping between reels feels instant; re-watching is instant and offline-cheap.
- The grid conveys motion without exhausting native video decoders.
- Each tile shows a view count.
- A reel can be sent to one or more friends in chat, arriving as a rich card
  that opens the reel in-app.

## Non-Goals

- **Repost / quote-repost.** Explicitly deferred. It is the only piece
  requiring new feed semantics — attribution, whether reposts accrue to the
  original's like count, and cascade rules when the original is deleted or its
  author blocks the reposter. It gets its own spec.
- **Server-generated animated previews** (looping webp per reel). Would be the
  cheapest possible client, but it is new ffmpeg work in the upload pipeline.
- **Unique-viewer analytics** (watch time, retention, unique reach). See
  "Rejected alternatives".

## Decisions Taken

| Question | Decision |
|---|---|
| Repost in scope? | No — deferred to its own spec |
| Prefetch depth | Wi-Fi/ethernet: next 3 · cellular: next 1 · offline: 0 |
| Cache/playback split | Stream the current reel while caching it; fully prefetch upcoming reels |
| Chat share payload | Rich card, mirroring the existing `story_share` pattern |
| View counting | Raw `$inc` counter, throttled client-side |
| Grid autoplay budget | Up to 3 tiles nearest viewport centre, only once scrolling settles |

## Design

### 1. `ReelVideoCache`

New: `lib/pages/moments/reels/reel_video_cache.dart`.

Wraps a **dedicated** `CacheManager` instance (its own store key,
`stalePeriod: 7 days`, capped object count) so reel video files and the
existing image cache (`AppImageCacheManager`) cannot evict one another.
`flutter_cache_manager: ^3.3.1` is already a dependency; no new package.

Interface — deliberately narrow, so `ReelControllerPool` gains a collaborator
rather than download logic:

```dart
Future<File?> cachedFileFor(String url); // on-disk hit or null; NEVER downloads
Future<File?> prefetch(String url);      // downloads, returns the file
void          warm(String url);          // fire-and-forget background download
```

**In-flight de-duplication is required.** `_syncControllers` runs on every page
change; at depth 3 a fast swiper issues overlapping requests for the same URLs.
The cache keeps a `Map<String, Future<File?>>` of in-flight downloads so a
second request joins the first instead of starting another.

**Failure is always soft.** A cache miss, failed download or full disk falls
back to `networkUrl`. The cache is an optimisation and must never be able to
render a reel unplayable.

### 2. `ReelPrefetchPolicy`

New: pure function from connectivity to prefetch depth.

```dart
int reelPrefetchDepth(List<ConnectivityResult> status);
// wifi | ethernet -> 3
// mobile          -> 1
// none            -> 0
```

Pure and dependency-free so it is unit-testable, in the same spirit as the
existing `reelVideoFit`. `connectivity_plus: ^7.0.0` is already a dependency.
The feed subscribes to the connectivity stream and re-reads depth on change.

### 3. `ReelControllerPool` changes

Keeps sole ownership of controller lifecycle. Behaviour changes:

**Byte prefetching and controller creation are separate concerns.** This is the
key structural point: caching a file requires no `VideoPlayerController` at all.
Conflating them would mean 4–5 live decoders in the viewer, contradicting the
decoder-exhaustion concern this design is built around.

- **Live controller window stays `±1`** — three controllers, exactly as today.
  `releaseOutside()` is unchanged.
- **Byte prefetch reaches `depth` ahead** (3 on Wi-Fi) via
  `ReelVideoCache.prefetch()` only. No controllers are created for those
  indices; they are merely on disk.
- **`activate(index, url)`** — if `cachedFileFor(url)` hits, build
  `VideoPlayerController.file()`: instant, zero network. On a miss, build
  `networkUrl` as today *and* call `warm(url)`, so the next view is local.
- **`preload(index, url)`** — unchanged in scope (`current + 1` only), but now
  prefers a cached file when one exists.

So a swipe finds its bytes already local (cheap, disk-bound) and only then pays
for a decoder. Peak live controllers is unchanged at 3 regardless of prefetch
depth.

### 4. Grid autoplay

New: `lib/pages/moments/reels/widgets/reel_grid_tile.dart` plus a small
autoplay coordinator.

- **Visibility by arithmetic, not a new package.** The grid's
  `ScrollController` plus known `crossAxisCount`, tile extent and viewport
  height determine which indices are on screen and which are centre-most.
  Extracted as a pure `visibleTileWindow(...)` and unit-tested, avoiding a
  `visibility_detector` dependency.
- **Settle-gated playback.** `ScrollPosition.isScrollingNotifier` is the
  authority for "settled" — it flips false only when scroll activity including
  the ballistic settle finishes. A short debounce on top swallows micro-jitter.
  Nothing plays while scrolling, so flinging spawns no controllers.
- **Bounded to 3** tiles nearest the centre, always muted and looping, using a
  **separate pool** from the full-screen viewer (shared cache, independent
  controllers) so opening a reel never disturbs grid state.
- **The grid pool releases on navigation.** Pushing `ReelsFeedScreen` leaves the
  grid mounted but invisible; without an explicit release its 3 controllers
  would stay alive alongside the viewer's 3, doubling the decoder budget for no
  benefit. The grid disposes its controllers when it stops being visible and
  rebuilds them on return. Peak across the app therefore stays at 3, not 6.
- **Tiles keyed by reel id, not index.** `GridView.builder` recycles children;
  keying by index makes a recycled tile inherit the previous cell's video.
- **Data policy.** On Wi-Fi, tiles may fetch (bounded to the 3 that play). On
  cellular, a tile animates **only if the file is already cached**, otherwise it
  stays a thumbnail. This preserves the cellular promise made by the prefetch
  policy.

### 5. View counts

**Backend — `models/Moment.js`:**

```js
viewCount: { type: Number, default: 0 }
```

**Backend — `POST /moments/:id/view`:** `protect`ed, behind the existing
`interactionLimiter` used by the like route. Performs a bare
`$inc: { viewCount: 1 }` and returns the new count.

**Client:** counts a reel once per app session, and only once the controller's
reported `position` has advanced by **at least 1000ms cumulatively** — not on
page change, so a fast scroll-past does not inflate the number, and a stalled
buffer does not count as a view. Counted ids held in an in-memory
`Set<String>`; the throttle is a pure, testable unit fed position updates.

**Display:** grid tile shows a play glyph plus a compacted count (`1.2K`),
using a pure, unit-tested formatter.

### 6. Share into chat

**Backend — `models/Message.js`:**

- `messageType` enum gains `'moment_share'` (alongside the existing
  `'story_share'`).
- New subdocument, mirroring `storyReference`'s shape exactly:

```js
momentReference: {
  momentId:  { type: ObjectId, ref: 'Moment', default: null },
  thumbnail: { type: String, default: null },
  isReel:    { type: Boolean, default: false }
}
```

The denormalised `thumbnail` lets the bubble paint with no second fetch —
the same reason `storyReference` carries one.

**Client — send path:** reuse `ForwardMessageDialog`, which is already a
multi-select user picker returning `List<String>` of user ids with search,
loading and empty states. It needs a **title/CTA parameter** so it can read
"Send" rather than "Forward" (`l10n.forwardCount` is currently hardcoded) —
a small generalisation, not a rewrite. One `moment_share` message is sent per
selected recipient.

**Client — bubble:** thumbnail + play badge + author + caption snippet.
Tapping pushes `ReelsFeedScreen` at that reel, or `SingleMoment` for a
non-reel moment.

**Dangling references must degrade, not throw.** The original can be deleted
(including by the soft-delete path) or its author can block the viewer. The
bubble renders "This reel is no longer available" when the populated reference
is missing.

## Testing

**Pure unit tests** (the pattern already established by `reel_fit_test.dart`):

- `reelPrefetchDepth` — every connectivity state, including empty and unknown.
- `visibleTileWindow` — first/last row, partial rows, viewport smaller than one
  tile, empty list.
- View-count throttle — counts once per session, not on page change, only after
  the playback threshold.
- Count formatter — boundaries at 1000 / 1.0K / 999K / 1.0M.

**Backend `node:test`:**

- `POST /moments/:id/view` — increments, requires auth, is rate-limited, 404s
  on a missing or soft-deleted moment.
- `Message` schema — accepts a well-formed `moment_share`, rejects a malformed
  `momentReference`.

**Manual simulator passes** (no widget-test harness exists for these):

- Vertical swipe *starting on the scrub bar* still changes reels — the scrub
  bar declares only horizontal drag, and this is the interaction most likely to
  break silently.
- Grid recycling — scroll fast, confirm no tile plays another tile's video.
- Wi-Fi vs cellular — depth changes, and cellular tiles stay static unless
  already cached.

## Known Trade-offs

- **Single-tap latency.** Declaring both `onTap` and `onDoubleTap` makes Flutter
  hold the single tap until the double-tap window expires (~300ms), so
  play/pause feels slightly delayed. Accepted — Instagram behaves the same way.
  The alternative is moving liking to the rail only.
- **Grid tiles on Wi-Fi consume data** for videos the user may never open,
  bounded to the 3 that play.
- **View counts measure plays, not people**, and a determined user can inflate
  their own.

## Rejected Alternatives

- **`viewedBy: [ObjectId]` on `Moment`.** Gives true unique viewers, but the
  array grows unbounded on a popular reel, bloats every feed read unless
  carefully projected out, and eventually threatens the 16MB document limit.
- **A separate `MomentView` collection.** Accurate and scalable, and the right
  answer if real analytics are wanted later — but a new collection plus index
  plus aggregation is more moving parts than the rest of this round combined.
- **Cache-then-play for everything.** Simplest and most predictable, but the
  *first* open of a reel would block on a full download instead of streaming,
  making the very thing being optimised feel slower on a poor connection.
- **Faking the share card client-side** by packing a moment id into an existing
  message field. No schema change, looks right in the app, but brittle to parse
  and the web client would render garbage.

## Deployment Notes

Neither view counts nor chat sharing function until the backend is deployed.
Per project history, the app targets production `api.banatalk.com` even in
development, so backend changes are inert until pushed to `main` (which
triggers the DigitalOcean deploy). The `Moment` and `Message` additions are
both additive with defaults, so they are backward-compatible with clients that
have not yet updated.
