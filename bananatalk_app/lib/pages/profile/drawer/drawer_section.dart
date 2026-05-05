import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Section-title label shown above a group of drawer items.
///
/// Pass [danger] = true to render the label in the error colour (used for the
/// "Account" danger-zone section).
class DrawerSectionTitle extends StatelessWidget {
  final String title;
  final bool danger;

  const DrawerSectionTitle({
    super.key,
    required this.title,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: danger
              ? AppColors.error.withValues(alpha: 0.7)
              : context.textMuted,
        ),
      ),
    );
  }
}

/// Card container that groups a list of [DrawerMenuItem] rows with a rounded
/// border and light shadow (light mode) or subtle border (dark mode).
class DrawerSectionContainer extends StatelessWidget {
  final List<Widget> children;

  const DrawerSectionContainer({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }
}

/// Inset divider placed between consecutive [DrawerMenuItem] rows.
class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.dividerColor.withValues(alpha: 0.4),
      ),
    );
  }
}

/// A single tappable row inside a [DrawerSectionContainer].
///
/// [isFirst] / [isLast] round the corresponding corners so the row blends
/// into the container's 18 px radius without a visible seam.
class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isDestructive;
  final bool showAdminBadge;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isDestructive = false,
    this.showAdminBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 18 : 0),
      topRight: Radius.circular(isFirst ? 18 : 0),
      bottomLeft: Radius.circular(isLast ? 18 : 0),
      bottomRight: Radius.circular(isLast ? 18 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: context.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDestructive
                                  ? AppColors.error
                                  : context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showAdminBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.captionSmall.copyWith(
                        color: context.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
