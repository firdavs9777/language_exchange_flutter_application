import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class EngagementStatsBar extends StatelessWidget {
  final Community profile;

  const EngagementStatsBar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = _buildStats(context);

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats,
      ),
    );
  }

  List<Widget> _buildStats(BuildContext context) {
    final stats = <Widget>[];

    // Online status (only show if privacy allows)
    if (PrivacyUtils.shouldShowOnlineStatus(profile)) {
      stats.add(_buildOnlineStatus(context));
    }

    // Response rate (if available)
    if (profile.responseRate != null) {
      if (stats.isNotEmpty) stats.add(_buildDivider(context));
      stats.add(_buildResponseRate(context));
    }

    // New user badge (if applicable)
    if (profile.isNewUser) {
      if (stats.isNotEmpty) stats.add(_buildDivider(context));
      stats.add(_buildNewBadge(context));
    }

    return stats;
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: context.dividerColor,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildOnlineStatus(BuildContext context) {
    final isOnline = profile.isOnline;
    final lastActiveText = profile.lastActiveText;

    Color dotColor;
    String text;

    if (isOnline) {
      dotColor = AppColors.online;
      text = 'Online';
    } else if (lastActiveText.isNotEmpty) {
      // Determine color based on how long ago
      if (lastActiveText.contains('m ago') || lastActiveText.contains('just now')) {
        dotColor = AppColors.away; // Yellow for recently active
      } else if (lastActiveText.contains('h ago')) {
        dotColor = AppColors.gray500;
      } else {
        dotColor = AppColors.offline;
      }
      text = lastActiveText.replaceAll('Active ', '');
    } else {
      dotColor = AppColors.offline;
      text = 'Offline';
    }

    return _StatChip(
      icon: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor,
          boxShadow: isOnline ? [
            BoxShadow(
              color: dotColor.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ] : null,
        ),
      ),
      value: text,
    );
  }

  Widget _buildResponseRate(BuildContext context) {
    final rate = profile.responseRate!;
    Color color;

    if (rate > 80) {
      color = AppColors.success;
    } else if (rate > 50) {
      color = AppColors.warning;
    } else {
      color = AppColors.gray500;
    }

    return _StatChip(
      icon: Icon(Icons.bolt_rounded, size: 14, color: color),
      value: '${rate.round()}%',
      label: 'replies',
    );
  }

  Widget _buildNewBadge(BuildContext context) {
    return _StatChip(
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.auto_awesome,
          size: 12,
          color: AppColors.secondary,
        ),
      ),
      value: 'New',
      valueColor: AppColors.secondary,
    );
  }
}

class _StatChip extends StatelessWidget {
  final Widget icon;
  final String value;
  final String? label;
  final Color? valueColor;

  const _StatChip({
    required this.icon,
    required this.value,
    this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.textPrimary,
              ),
            ),
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: 10,
                  color: context.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
