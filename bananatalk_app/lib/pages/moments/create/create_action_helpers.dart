import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Square icon button used in the action bar row of CreateMoment.
///
/// Shows [icon] (or [badge] text if provided) inside a rounded container.
/// When [badge] has more than one character it also shows a red counter badge
/// in the top-right corner.
Widget createActionIcon({
  required BuildContext context,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  bool isActive = false,
  String? badge,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Theme.of(context).dividerColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (badge != null && badge.isNotEmpty)
            Text(
              badge,
              style: TextStyle(fontSize: badge.length == 1 ? 28 : 16),
            )
          else
            Icon(icon, color: color, size: 28),
          if (badge != null && badge.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF44336),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Icon + label button used in the bottom toolbar of CreateMoment.
Widget createBottomButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required Color color,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: AppRadius.borderMD,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          Spacing.gapXS,
          Text(
            label,
            style: context.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    ),
  );
}
