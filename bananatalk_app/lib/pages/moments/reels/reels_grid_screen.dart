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

  static const double _tileHeight = 180; // 9:16 at a third of a phone width
  List<int> _playing = const [];
  bool _unmetered = false;
  Timer? _settleTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePlaying());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _settleTimer?.cancel();
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
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(reelsFeedProvider.notifier).loadMore();
    }

    // Nothing plays mid-scroll: flinging through the grid would otherwise
    // spawn and tear down controllers for every row it passed.
    if (_playing.isNotEmpty) {
      setState(() => _playing = const []);
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      // isScrollingNotifier is the authority on "settled" — it stays true
      // through the ballistic phase, which a bare debounce would miss.
      if (_scrollController.hasClients &&
          _scrollController.position.isScrollingNotifier.value) {
        return;
      }
      _recomputePlaying();
    });
  }

  void _recomputePlaying() {
    if (!mounted || !_scrollController.hasClients) return;
    final reels = ref.read(reelsFeedProvider).reels;
    final next = reelTilesToPlay(
      scrollOffset: _scrollController.position.pixels,
      viewportHeight: _scrollController.position.viewportDimension,
      tileHeight: _tileHeight,
      crossAxisCount: 3,
      itemCount: reels.length,
      maxPlaying: kReelGridMaxPlaying,
    );
    setState(() => _playing = next);
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
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
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
