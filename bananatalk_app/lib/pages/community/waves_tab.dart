import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Waves Tab - Shows waves received from other users
class WavesTab extends ConsumerStatefulWidget {
  const WavesTab({super.key});

  @override
  ConsumerState<WavesTab> createState() => _WavesTabState();
}

class _WavesTabState extends ConsumerState<WavesTab> {
  List<Wave> _waves = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWaves();
  }

  Future<void> _loadWaves() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final service = ref.read(communityServiceProvider);
      final waves = await service.getWavesReceived();

      setState(() {
        _waves = waves;
        _unreadCount = waves.where((w) => !w.isRead).length;
        _isLoading = false;
      });

      // Mark waves as read after loading
      if (_unreadCount > 0) {
        await service.markWavesAsRead();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _viewProfile(Wave wave) async {
    if (wave.fromUserId == null) return;

    try {
      final service = ref.read(communityServiceProvider);
      final fullProfile = await service.getSingleCommunity(id: wave.fromUserId!);
      if (fullProfile != null && mounted) {
        Navigator.push(
          context,
          AppPageRoute(
            builder: (_) => SingleCommunity(community: fullProfile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            Spacing.gapMD,
            Builder(
              builder: (context) => Text(
                'Failed to load waves',
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
            ),
            Spacing.gapMD,
            ElevatedButton.icon(
              onPressed: _loadWaves,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_waves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand,
                size: 48,
                color: Color(0xFF00BFA5),
              ),
            ),
            Spacing.gapLG,
            Builder(
              builder: (context) => Text(
                'No waves yet',
                style: context.titleMedium.copyWith(
                  color: context.textPrimary,
                ),
              ),
            ),
            Spacing.gapSM,
            Builder(
              builder: (context) => Text(
                'When someone waves at you,\nyou\'ll see them here',
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWaves,
      color: const Color(0xFF00BFA5),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _waves.length,
        itemBuilder: (context, index) {
          final wave = _waves[index];
          return _WaveCard(
            wave: wave,
            onTap: () => _viewProfile(wave),
          );
        },
      ),
    );
  }
}

class _WaveCard extends StatelessWidget {
  final Wave wave;
  final VoidCallback onTap;

  const _WaveCard({
    required this.wave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = wave.createdAt != null
        ? timeago.format(wave.createdAt!)
        : 'Recently';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: wave.isRead ? Colors.white : const Color(0xFF00BFA5).withOpacity(0.05),
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: wave.isRead ? Colors.grey.shade200 : const Color(0xFF00BFA5).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMD,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CachedImageWidget(
                      imageUrl: wave.fromUserImage ?? '',
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(28),
                      placeholder: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF00BFA5),
                          size: 28,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Text('👋', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
                Spacing.hGapMD,
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              wave.fromUserName ?? 'Someone',
                              style: context.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!wave.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00BFA5),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      Spacing.gapXS,
                      Text(
                        wave.message?.isNotEmpty == true
                            ? wave.message!
                            : 'Waved at you',
                        style: context.bodyMedium.copyWith(
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.gapXS,
                      Text(
                        timeAgo,
                        style: context.caption.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
