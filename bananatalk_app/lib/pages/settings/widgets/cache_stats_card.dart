import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/storage_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class CacheStatsCard extends StatelessWidget {
  const CacheStatsCard({
    super.key,
    required this.breakdown,
    required this.isClearing,
    this.clearingType,
    required this.onClearImages,
    required this.onClearVoice,
    required this.onClearVideo,
  });

  final StorageBreakdown breakdown;
  final bool isClearing;
  final String? clearingType;
  final VoidCallback onClearImages;
  final VoidCallback onClearVoice;
  final VoidCallback onClearVideo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          // Total Storage Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: const Icon(Icons.storage, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.totalCacheSize, style: context.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        StorageBreakdown.formatBytes(breakdown.total),
                        style: context.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Individual cache items
          _CacheStatItem(
            icon: Icons.image,
            iconColor: Colors.blue,
            title: l10n.imageCache,
            size: breakdown.imageCache,
            isClearing: isClearing,
            clearingType: clearingType,
            onClear: onClearImages,
          ),
          Divider(height: 1, color: context.dividerColor),
          _CacheStatItem(
            icon: Icons.mic,
            iconColor: Colors.orange,
            title: l10n.voiceMessagesCache,
            size: breakdown.voiceMessages,
            isClearing: isClearing,
            clearingType: clearingType,
            onClear: onClearVoice,
          ),
          Divider(height: 1, color: context.dividerColor),
          _CacheStatItem(
            icon: Icons.videocam,
            iconColor: Colors.purple,
            title: l10n.videoCache,
            size: breakdown.videoCache,
            isClearing: isClearing,
            clearingType: clearingType,
            onClear: onClearVideo,
          ),
          if (breakdown.otherCache > 0) ...[
            Divider(height: 1, color: context.dividerColor),
            _CacheStatItem(
              icon: Icons.folder,
              iconColor: context.textMuted,
              title: l10n.otherCache,
              size: breakdown.otherCache,
              isClearing: false,
              clearingType: null,
              onClear: null,
              showClearButton: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _CacheStatItem extends StatelessWidget {
  const _CacheStatItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.size,
    required this.isClearing,
    required this.clearingType,
    required this.onClear,
    this.showClearButton = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int size;
  final bool isClearing;
  final String? clearingType;
  final VoidCallback? onClear;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isClearingThis = isClearing && clearingType == title.toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.titleSmall),
                Text(
                  StorageBreakdown.formatBytes(size),
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          if (showClearButton && size > 0)
            isClearingThis
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: isClearing ? null : onClear,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.clear),
                  ),
        ],
      ),
    );
  }
}
