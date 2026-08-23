import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/reels_provider.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart'
    show selectedTabProvider, kMomentsTabIndex;
import 'package:bananatalk_app/pages/moments/reels/create_reel_flow.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_grid_autoplay.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_policy_dialog.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_prefetch_policy.dart';
import 'package:bananatalk_app/pages/moments/reels/reels_feed_screen.dart';
import 'package:bananatalk_app/pages/moments/reels/widgets/reel_grid_tile.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Thumbnail grid landing for the Reels tab (Workstream G, Task 4).
///
/// Renders a designed empty state when supply is thin, an infinite-scroll
/// 3-column grid otherwise, and the one-time content-policy gate
/// (Apple 1.2, see [ReelPolicyGate]) before the first frame of real
/// content. Tapping a tile opens the full-screen vertical swipe feed at
/// that reel (wired in Task 5); the "+" FAB opens the reel creation flow
/// (wired in Task 6) — both are TODO stubs here so this screen compiles
/// and is usable standalone ahead of those tasks landing.
class ReelsGridScreen extends ConsumerStatefulWidget {
  const ReelsGridScreen({super.key, required this.onPolicyDeclined});

  /// Called when the user declines the content-policy gate. The Reels tab
  /// isn't its own route (it's a branch inside `MomentsMain`'s body), so
  /// "back out of the tab" means the caller should switch the active
  /// segmented-tab selection back to For You.
  final VoidCallback onPolicyDeclined;

  @override
  ConsumerState<ReelsGridScreen> createState() => _ReelsGridScreenState();
}

class _ReelsGridScreenState extends ConsumerState<ReelsGridScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _policyChecked = false;

  // Single source of truth for the grid's geometry: both the GridView's own
  // delegate/padding below AND the row-pitch arithmetic in `_rowPitch` read
  // these, so the two cannot drift apart the way a second hardcoded literal
  // did (round 1's `_tileHeight = 180` guessed the pitch instead of deriving
  // it, and was off by 48pt/row — by row 10 the accumulated error exceeded
  // two screens and `reelTilesToPlay` pointed at indices GridView never
  // built, so nothing played at all a few screens down).
  static const int _crossAxisCount = 3;
  static const double _gridPadding = 2;
  static const double _gridSpacing = 2;
  static const double _tileAspectRatio = 9 / 16;

  List<int> _playing = const [];
  bool _unmetered = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // ---------------------------------------------------------------------
  // The decoder budget gate.
  //
  // Native video decoders are a hard, small, device-wide resource (Android's
  // MediaCodec commonly allows 4-8 instances). The reels design spends that
  // budget in exactly one place at a time: the full-screen viewer holds up
  // to 3 (ReelControllerPool), or this grid holds up to 3 — never both.
  //
  // `_playbackAllowed` is the single owner of that rule for the grid. Every
  // path that could start grid playback funnels through
  // `_recomputePlaying`, which refuses to hand out controllers unless all
  // three conditions below hold. There is deliberately no second, cleverer
  // route to `_playing`: the previous design cleared `_playing` once at
  // route-push time and had nothing latching it, so the provider listener
  // (a viewer-side `loadMore` or a like) quietly rebuilt all 3 tiles while
  // the viewer's own 3 were live.
  //
  // Conditions:
  //  1. no route pushed over us  — `_occludingRoutes == 0`
  //  2. our tab is the visible one — `selectedTabProvider == Moments`
  //  3. the app is foregrounded  — `_appResumed`
  //
  // (2) matters because `TabsScreen` keeps every tab alive in a `Stack`
  // under an `AnimatedOpacity(opacity: 0)`: switching tabs does NOT dispose
  // this screen, so without the gate a single visit to Reels left 3 muted
  // decoders (and their cache downloads) running for the rest of the
  // session, underneath Chats, stories, moment video and LiveKit calls.

  /// How many routes this screen has pushed that are still on screen.
  /// A counter rather than a bool so overlapping pushes cannot have the
  /// inner one's completion reopen the gate while the outer is still up.
  int _occludingRoutes = 0;

  /// Whether the app is foregrounded. Mirrors the viewer's
  /// `didChangeAppLifecycleState` discipline, which the grid had none of.
  bool _appResumed = true;

  /// True only when the grid is allowed to spend decoders.
  bool get _playbackAllowed =>
      _occludingRoutes == 0 &&
      _appResumed &&
      ref.read(selectedTabProvider) == kMomentsTabIndex;

  // The ScrollPosition we've attached `_onSettleChanged` to. ScrollPosition
  // instances get replaced (e.g. on a viewport metrics change), so tracking
  // this — rather than always reading `_scrollController.position` — lets us
  // detect the swap and re-attach, and lets `dispose` remove the listener
  // from the instance it was actually added to instead of whatever instance
  // happens to be current (which would either no-op or throw).
  ScrollPosition? _observedPosition;

  /// The vertical distance from one row's top edge to the next row's top
  /// edge, derived from the same constants the `GridView`'s delegate below
  /// is built from — so this can never silently disagree with what the grid
  /// actually renders.
  double _rowPitch(double viewportWidth) {
    final usable = viewportWidth -
        _gridPadding * 2 -
        _gridSpacing * (_crossAxisCount - 1);
    final tileWidth = usable / _crossAxisCount;
    final tileHeight = tileWidth / _tileAspectRatio;
    return tileHeight + _gridSpacing;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPolicy());

    Connectivity().checkConnectivity().then((status) {
      if (mounted) {
        setState(() => _unmetered = reelConnectionUnmetered(status));
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) {
      if (mounted) setState(() => _unmetered = reelConnectionUnmetered(status));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed == _appResumed) return;
    _appResumed = resumed;
    // Backgrounding must *stop* (not pause) grid playback: unlike the
    // viewer — which pauses so the reel resumes mid-clip — a muted 90x160
    // thumbnail loop has no state worth preserving, and holding decoders
    // while another app (or a LiveKit call) wants them is the whole problem.
    _applyPlaybackGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _observedPosition?.isScrollingNotifier.removeListener(_onSettleChanged);
    _connectivitySub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPolicy() async {
    final accepted = await ReelPolicyGate.ensureAccepted(context, ref);
    if (!mounted) return;
    if (!accepted) {
      widget.onPolicyDeclined();
      return;
    }
    setState(() => _policyChecked = true);
    // The GridView doesn't exist (so has no ScrollPosition) until this
    // rebuild lands, which is why the very first recompute has to wait for
    // it — an earlier attempt scheduled this from initState, before
    // `_policyChecked` flips, and always no-op'd on a missing client.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePlaying());
  }

  /// Keeps `_onSettleChanged` attached to whichever `ScrollPosition` is
  /// currently live. `isScrollingNotifier` — not a debounce timer — is the
  /// authority on "settled": a fixed-delay `Timer` armed on the last scroll
  /// delta can fire while a held-but-not-moving drag still reads as
  /// scrolling, bail out, and then never get re-armed because a stationary
  /// finger emits no further scroll notifications — freezing the grid on
  /// thumbnails until the user scrolls again. Listening to the notifier
  /// itself means the moment it flips to false (drag release, fling
  /// decay finished) we recompute, regardless of how long the finger sat
  /// still beforehand.
  void _syncSettleListener() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (identical(position, _observedPosition)) return;
    _observedPosition?.isScrollingNotifier.removeListener(_onSettleChanged);
    _observedPosition = position;
    position.isScrollingNotifier.addListener(_onSettleChanged);
  }

  void _onSettleChanged() {
    if (!mounted) return;
    if (_observedPosition?.isScrollingNotifier.value ?? true) return;
    // A loadMore page landing while a ballistic fling still has
    // sub-tolerance velocity can flip this notifier from inside
    // ScrollPosition.applyContentDimensions (goBallistic -> null
    // simulation -> goIdle), which runs during layout. Calling setState
    // synchronously there throws ("setState() called during build"), so
    // when we're in that phase, defer the recompute to the next frame
    // instead of calling it inline.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recomputePlaying();
      });
      return;
    }
    _recomputePlaying();
  }

  void _onScroll() {
    _syncSettleListener();
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(reelsFeedProvider.notifier).loadMore();
    }

    // Nothing plays mid-scroll: flinging through the grid would otherwise
    // spawn and tear down controllers for every row it passed. The resume
    // trigger is `_onSettleChanged` above, not this listener.
    if (_playing.isNotEmpty) {
      setState(() => _playing = const []);
    }
  }

  /// Re-evaluates the gate: stop everything if the budget isn't ours right
  /// now, otherwise recompute which tiles should play. This is the only
  /// thing lifecycle changes, tab changes and route completion call — they
  /// don't each implement their own stop/resume logic.
  void _applyPlaybackGate() {
    if (!mounted) return;
    // Both branches below call setState, and a gate change can arrive from a
    // `ref.listen` callback that fires while another widget is building —
    // same hazard `_onSettleChanged` documents. Defer a frame rather than
    // throw "setState() called during build".
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyPlaybackGate();
      });
      return;
    }
    if (!_playbackAllowed) {
      _stopPlaying();
      return;
    }
    _recomputePlaying();
  }

  void _stopPlaying() {
    if (_playing.isEmpty) return;
    // Handing every tile `shouldPlay: false` is what disposes their
    // controllers (`_ReelGridTileState._stop`) and, because tiles only ever
    // download inside `_start`, is also what stops grid-driven cache
    // downloads.
    setState(() => _playing = const []);
  }

  void _recomputePlaying() {
    _syncSettleListener();
    if (!mounted || !_scrollController.hasClients) return;
    // The one choke point for the decoder budget. Every resume path — the
    // settle listener, the policy gate's first frame, the `ref.listen` on
    // the feed provider (viewer-side `loadMore`/like), returning from a
    // pushed route, a tab switch, foregrounding — ends up here, so the gate
    // only has to be enforced once.
    if (!_playbackAllowed) {
      _stopPlaying();
      return;
    }
    final reels = ref.read(reelsFeedProvider).reels;
    final next = reelTilesToPlay(
      scrollOffset: _scrollController.position.pixels,
      viewportHeight: _scrollController.position.viewportDimension,
      tileHeight: _rowPitch(MediaQuery.sizeOf(context).width),
      crossAxisCount: _crossAxisCount,
      itemCount: reels.length,
      maxPlaying: kReelGridMaxPlaying,
    );
    if (_sameIndices(next, _playing)) return;
    setState(() => _playing = next);
  }

  bool _sameIndices(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _onRefresh() => ref.read(reelsFeedProvider.notifier).refresh();

  /// Pushes [page] with the grid's playback budget handed over for the
  /// route's entire on-screen lifetime — every route this screen opens goes
  /// through here, so no caller has to remember to stop playback.
  ///
  /// Timing is the subtle part. `Navigator.push(...)`'s future (and `await`)
  /// completes in `Route.didComplete`, i.e. at the *start* of the 250ms
  /// reverse transition — while the popped route's widgets are still alive
  /// and its `dispose()`/`disposeAll()` has not run. Resuming there
  /// guaranteed a 3+3 decoder overlap on every single back-out. `TransitionRoute.completed`
  /// instead completes after the transition finished and the route's overlay
  /// entries were removed, which is after the viewer's `State.dispose()` —
  /// so the viewer's 3 are gone before the grid's 3 come back.
  Future<void> _pushOccluding(Widget page) async {
    final route = AppPageRoute<void>(builder: (_) => page);
    _occludingRoutes++;
    _applyPlaybackGate();
    try {
      Navigator.of(context).push(route);
      await route.completed;
    } finally {
      _occludingRoutes--;
      _applyPlaybackGate();
    }
  }

  Future<void> _openReel(int index) =>
      _pushOccluding(ReelsFeedScreen(initialIndex: index));

  Future<void> _openCreateFlow() async {
    // Also gated: `CreateReelFlow` -> `CreateMoment` opens a camera and a
    // video preview, which contend for the same decoders/encoders as 3
    // playing grid tiles.
    await _pushOccluding(const CreateReelFlow());
    if (!mounted) return;
    await ref.read(reelsFeedProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Any time the reel list itself changes identity — first load, refresh,
    // or a loadMore append — recompute what should be playing. `reels` is
    // rebuilt via `copyWith` only when its contents actually change (a
    // loading-flag-only update reuses the same List instance), so reference
    // inequality is exactly "the list changed" here. This is what makes the
    // grid resume after `_onRefresh` shifts indices around, and what gets
    // the first frame of real data playing on cold entry when the fetch
    // resolves after this screen is already built.
    ref.listen<ReelsFeedState>(reelsFeedProvider, (previous, next) {
      if (previous?.reels != next.reels) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePlaying());
      }
    });

    // Tab visibility. `TabsScreen` never disposes an unselected tab (it just
    // fades it to opacity 0 inside a Stack), so this listener is the only
    // signal that our decoders are no longer on screen. It is a trigger
    // only — `_playbackAllowed` re-reads the provider itself, so a missed
    // notification can never leave the gate stuck open or stuck closed.
    ref.listen<int>(selectedTabProvider, (previous, next) {
      _applyPlaybackGate();
    });

    if (!_policyChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = ref.watch(reelsFeedProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: _buildBody(state),
        ),
        Positioned(
          right: 16,
          // 88 = the Scaffold FAB's usual 16 plus the 72 that MomentsMain
          // adds to clear the bottom nav bar (see its own FAB). This screen
          // renders inside MomentsMain's body, so at 16 the button sat
          // behind the nav bar and was effectively unreachable — which is
          // why reels got posted through the Moments composer instead.
          bottom: 88,
          child: FloatingActionButton(
            heroTag: 'reels_create_fab',
            onPressed: () => _openCreateFlow().catchError((_) {}),
            backgroundColor: const Color(0xFF00BFA5),
            child: const Icon(Icons.videocam, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ReelsFeedState state) {
    if (state.isLoading && state.reels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reels.isEmpty) {
      return _buildErrorState(context);
    }

    if (state.reels.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(_gridPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: _gridSpacing,
        mainAxisSpacing: _gridSpacing,
        childAspectRatio: _tileAspectRatio,
      ),
      itemCount: state.reels.length + (state.isLoadingMore ? 3 : 0),
      itemBuilder: (context, index) {
        if (index >= state.reels.length) {
          return Container(
            color: context.containerColor,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final reel = state.reels[index];
        return ReelGridTile(
          // Keyed by reel id, never index: GridView.builder recycles
          // children, and an index key would let a recycled tile inherit the
          // previous cell's controller and play the wrong video.
          key: ValueKey('reel-tile-${reel.id}'),
          reel: reel,
          shouldPlay: _playing.contains(index),
          mayDownload: _unmetered,
          onTap: () => _openReel(index).catchError((_) {}),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: context.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load reels',
                    style: context.bodyMedium
                        .copyWith(color: context.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_camera_back_outlined,
                      size: 64, color: context.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No reels yet',
                    style: context.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Be the first to answer today's prompt on camera, or "
                    'record a free-form language-learning clip.',
                    textAlign: TextAlign.center,
                    style: context.bodySmall
                        .copyWith(color: context.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateFlow().catchError((_) {}),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record a reel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
