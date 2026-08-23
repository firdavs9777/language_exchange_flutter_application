# Reels Playback Performance — Manual Device Verification

**Status: UNRUN.** Nothing on the `feat/reels-playback-performance` branch has been
verified on a simulator or a device. This repo has no `VideoPlayerController` test
harness, so the branch's central constraint — never more than 3 live video
decoders — cannot be checked by any automated test here. Everything below is the
real merge gate.

Why it matters: Android's MediaCodec commonly permits only 4-8 concurrent codec
instances. The pre-fix code reached 6 on every back-out from the full-screen
viewer and left 3 running for the whole app session after one visit to the Reels
tab, so this is a plausible hard playback failure rather than a theoretical one.

Static state at the time of writing: `flutter analyze lib/` reports 1483 issues,
which is the exact pre-existing baseline measured at the branch point (`aec07e4`)
— the branch adds none. `flutter test` reports 152 passing and 1 failing; that
failure is `test/widget_test.dart`, the untouched Flutter template counter test,
pre-existing and unrelated.

## Manual verification script (do Android first — MediaCodec is the tighter cap)

Instrument by counting live decoders, not by watching the UI. Easiest reliable
readout on Android: `adb shell dumpsys media.player | grep -c OMX` or, better,
`adb logcat | grep -E "MediaCodec|CCodec"` and count `createCodec`/`release`
pairs; on iOS use Xcode's Instruments → Video toolbox / `AVPlayer` allocations.
A simpler proxy that catches every case below: add a temporary
`debugPrint`/counter increment in `_ReelGridTileState._start`/`_stop` and in
`ReelControllerPool._createController`/`_disposeController`.

Notation: **G** = grid tile controllers, **V** = viewer pool controllers.

| # | Action | Expect |
| --- | --- | --- |
| 1 | Cold launch → Moments tab → Reels segment, accept policy | G=0 → G≤3 once the first frame settles, V=0 |
| 2 | Fling the grid down several screens, keep the finger moving | G=0 for the whole fling (nothing plays mid-scroll) |
| 3 | Release, let it settle | G≤3 (the 3 rows nearest the viewport centre), V=0 |
| 4 | Tap a tile | G drops to **0 before** the push transition starts; V ramps to ≤3. **Never G+V > 3.** |
| 5 | Swipe 3-5 pages in the viewer (this fires the viewer's own `loadMore`, which mutates `reelsFeedProvider` — the exact C1 trigger) | V≤3 throughout, **G stays 0** (pre-fix: G jumped back to 3 here and stayed) |
| 6 | Like a reel in the viewer (fires `updateReel`, same provider path) | G stays 0 |
| 7 | Press back; watch across the full 250ms reverse transition | V drops to 0 first; G only starts climbing after the viewer's page is gone. **Peak during the transition must be ≤3, not 6** (pre-fix: 6 on every single back-out) |
| 8 | Settled back on the grid | G≤3, V=0 |
| 9 | Switch to the Chats tab (grid is *not* disposed — it's still in the Stack at opacity 0) | G=0 within a frame. Also confirm no further reel byte downloads: `adb logcat` shows no new cache writes, or watch the app's network graph go quiet |
| 10 | Open a chat with video / start a LiveKit call from Chats | Total decoders exclude anything reel-shaped; no `MediaCodec` allocation failures in logcat |
| 11 | Switch back to Moments → Reels | G≤3 again after settle |
| 12 | Background the app (home button / app switcher) | G=0 (stopped, not paused — check for *dispose*, not just pause) |
| 13 | Foreground the app | G≤3 after settle |
| 14 | Tap the "+" FAB (create flow, camera + video preview) | G=0 **before** the camera opens; on back-out G returns only after the transition, same as step 7 |
| 15 | Repeat steps 4→8 ten times in a row | G+V peak never exceeds 3; no monotonic growth in the decoder count, no `Failed to allocate component instance` / `MediaCodec` errors in logcat |

Pass condition, stated once: **at no instant, in any of the 15 steps, should live
`VideoPlayerController`s exceed 3.**

## Concerns / known gaps (deliberately not fixed here)

1. **Foreign pushes are not gated.** `_pushOccluding` covers routes *the grid
   pushes*. `MomentsMain`'s app-bar "+" (`CreateMoment`) pushes over the grid
   from the parent widget while the Reels segment is showing, so 3 grid tiles can
   still contend with that camera. Fixing it generally needs a route-visibility
   signal the grid can pull (a `RouteObserver` registered in go_router's
   `navigatorObservers`, or `ModalRoute.secondaryAnimation`). I deliberately did
   not use `secondaryAnimation`: whether it animates at all depends on
   `canTransitionTo`/`canTransitionFrom` between go_router's shell route and
   `AppPageRoute` (a `PageRouteBuilder`), and a silently-always-dismissed
   animation would make the gate look implemented while doing nothing — worse
   than a documented gap. Small blast radius, worth its own change.
2. **In-flight cache downloads are not cancelled**, only orphaned. When the gate
   shuts, a tile's `ReelVideoCache.prefetch` future that has already started
   finishes writing to disk (its result is then discarded by the `_bail` epoch
   check). Bytes, not decoders — bounded by 3 files.
3. Out of scope as instructed and untouched: `ReelVideoCache`'s 60-object count
   cap (byte cap is a sizing decision), `_getOrCreateController`'s missing url
   comparison (latent only), `test/widget_test.dart`, the formatter work.
