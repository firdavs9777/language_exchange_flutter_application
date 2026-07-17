import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/coins/coin_balance_pill.dart';
import 'package:bananatalk_app/widgets/notifications/notification_bell.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
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
      actions: [
        // Coin balance — Coins v1 entry point, hidden when coinsEnabled is off.
        const CoinBalancePill(),
        // Notification inbox — reachable from every tab, not just chat.
        NotificationBell(color: context.textPrimary),
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
        // Overflow — Smart Match + VIP upgrade moved here to declutter the bar.
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: context.textPrimary),
          tooltip: AppLocalizations.of(context)!.more,
          onSelected: (value) {
            switch (value) {
              case 'smart_match':
                context.push('/matching');
                break;
              case 'vip':
                Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const VipPlansScreen()),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'smart_match',
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.findPartners),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'vip',
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      size: 20, color: Color(0xFFFFA000)),
                  SizedBox(width: 12),
                  Text('Go VIP'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
