import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// AppBar for the Community screen.
///
/// Displays the "Community" title (hidden while [isSearching]) and the three
/// action buttons: Smart Match, Search toggle, and Filter.
class CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityAppBar({
    super.key,
    required this.isSearching,
    required this.onSearchToggle,
    required this.onFilterTap,
  });

  final bool isSearching;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: isSearching
          ? null
          : Text(
              AppLocalizations.of(context)!.community,
              style: context.displayMedium.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
      actions: [
        // Smart Match button
        IconButton(
          onPressed: () => context.push('/matching'),
          icon: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
          tooltip: AppLocalizations.of(context)!.findPartners,
        ),
        // Search toggle button
        IconButton(
          onPressed: onSearchToggle,
          icon: Icon(
            isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: context.textPrimary,
          ),
        ),
        // Filter button
        Container(
          margin: const EdgeInsets.only(right: Spacing.sm),
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: AppRadius.borderMD,
          ),
          child: IconButton(
            onPressed: onFilterTap,
            icon: Icon(Icons.tune_rounded, color: colorScheme.onPrimary),
            tooltip: AppLocalizations.of(context)!.filters,
          ),
        ),
      ],
    );
  }
}
