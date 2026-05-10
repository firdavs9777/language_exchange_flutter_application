import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_empty_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class WavesArchiveScreen extends ConsumerStatefulWidget {
  const WavesArchiveScreen({super.key});

  @override
  ConsumerState<WavesArchiveScreen> createState() =>
      _WavesArchiveScreenState();
}

class _WavesArchiveScreenState extends ConsumerState<WavesArchiveScreen> {
  List<Wave> _waves = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final waves = await ref
          .read(communityServiceProvider)
          .getWavesReceived(archive: true, limit: 50);
      if (!mounted) return;
      setState(() {
        _waves = waves;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _viewProfile(Wave wave) async {
    if (wave.fromUserId.isEmpty) return;
    try {
      final service = ref.read(communityServiceProvider);
      final fullProfile = await service.getSingleCommunity(id: wave.fromUserId);
      if (fullProfile != null && mounted) {
        Navigator.push(
          context,
          AppPageRoute(builder: (_) => SingleCommunity(community: fullProfile)),
        );
      }
    } catch (e) {
      if (mounted) {
        showCommunitySnackBar(
          context,
          message: 'Failed to load profile',
          type: CommunitySnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.archivedWaves),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        foregroundColor: context.textPrimary,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: context.textMuted),
                      Spacing.gapMD,
                      Text(
                        'Failed to load archived waves',
                        style: context.bodyMedium
                            .copyWith(color: context.textSecondary),
                      ),
                      Spacing.gapMD,
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _waves.isEmpty
                  ? CommunityEmptyState(
                      icon: Icons.inbox_outlined,
                      title: l10n.noArchivedWaves,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF00BFA5),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _waves.length,
                        itemBuilder: (context, index) {
                          final wave = _waves[index];
                          return _ArchiveWaveCard(
                            wave: wave,
                            onTap: () => _viewProfile(wave),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ArchiveWaveCard extends StatelessWidget {
  final Wave wave;
  final VoidCallback onTap;

  const _ArchiveWaveCard({required this.wave, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeAgo = timeago.format(wave.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                          color:
                              const Color(0xFF00BFA5).withValues(alpha: 0.2),
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
                        child:
                            const Text('👋', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
                Spacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wave.fromUserName,
                        style: context.titleMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.gapXS,
                      Text(
                        wave.message?.isNotEmpty == true
                            ? wave.message!
                            : 'Waved at you',
                        style: context.bodyMedium
                            .copyWith(color: context.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.gapXS,
                      Text(
                        timeAgo,
                        style: context.caption
                            .copyWith(color: context.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
