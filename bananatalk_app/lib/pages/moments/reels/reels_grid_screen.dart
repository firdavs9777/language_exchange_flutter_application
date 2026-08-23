import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/reels_provider.dart';
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

class _ReelsGridScreenState extends ConsumerState<ReelsGridScreen> {
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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPolicy());

    Connectivity().checkConnectivity().then((status) {
      if (mounted) {
        setState(() => _unmetered = reelPrefetchDepth(status) > 1);
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) {
      if (mounted) setState(() => _unmetered = reelPrefetchDepth(status) > 1);
    });
  }

  @override
  void dispose() {
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

  void _recomputePlaying() {
    _syncSettleListener();
    if (!mounted || !_scrollController.hasClients) return;
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

  void _openReel(int index) {
    setState(() => _playing = const []);
    Navigator.of(context)
        .push(AppPageRoute(builder: (_) => ReelsFeedScreen(initialIndex: index)))
        .then((_) {
      if (mounted) _recomputePlaying();
    });
  }

  void _openCreateFlow() {
    Navigator.of(context)
        .push(AppPageRoute(builder: (_) => const CreateReelFlow()))
        .then((_) => ref.read(reelsFeedProvider.notifier).refresh());
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
            onPressed: _openCreateFlow,
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
          onTap: () => _openReel(index),
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
                    onPressed: _openCreateFlow,
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
