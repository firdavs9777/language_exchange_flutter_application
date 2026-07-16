import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/vip_up_pill.dart';
import 'package:bananatalk_app/widgets/coins/coin_balance_pill.dart';
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
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // Hamburger opens the shared app-shell drawer (mounted on Scaffold by
      // community_main.dart). Builder needed so the IconButton's context
      // can find the Scaffold above it.
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: context.textPrimary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
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
        // VIP upgrade entry — same gold pill used in the chat list.
        const VipUpPill(),
        // Coin balance — Coins v1 entry point, hidden when coinsEnabled is off.
        const CoinBalancePill(),
        // Smart Match — soft primary-tinted pill to signal the AI feature.
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.borderMD,
          ),
          child: IconButton(
            onPressed: () => context.push('/matching'),
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
            tooltip: AppLocalizations.of(context)!.findPartners,
          ),
        ),
        // Search toggle — bare neutral, lowest weight.
        IconButton(
          onPressed: onSearchToggle,
          icon: Icon(
            isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: context.textPrimary,
          ),
        ),
        // Filter — filled-primary pill, highest weight (most-used action).
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
