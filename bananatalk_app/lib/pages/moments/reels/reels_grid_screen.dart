import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/reels_provider.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_policy_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPolicy());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
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
  }

  Future<void> _onRefresh() => ref.read(reelsFeedProvider.notifier).refresh();

  void _openReel(int index) {
    // TODO(Task 5): push the full-screen vertical swipe feed
    // (reels_feed_screen.dart) opened at `index`.
  }

  void _openCreateFlow() {
    // TODO(Task 6): push the reel creation flow (create_reel_flow.dart).
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
          bottom: 16,
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
        return _ReelTile(
          reel: state.reels[index],
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

class _ReelTile extends StatelessWidget {
  const _ReelTile({required this.reel, required this.onTap});

  final Moments reel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = reel.video?.thumbnail;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            CachedImageWidget(imageUrl: thumbnail, fit: BoxFit.cover)
          else
            Container(
              color: context.containerColor,
              child: Icon(Icons.videocam, color: context.textMuted),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: _LanguageChip(language: reel.language),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                if (reel.likeCount > 0) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${reel.likeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    if (language.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        language.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
