import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/coins/coin_balance_pill.dart';
import 'package:bananatalk_app/widgets/notifications/notification_bell.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:go_router/go_router.dart';

/// AppBar for the Community screen.
///
/// Displays the "Community" title (hidden while [isSearching]) and the three
/// action buttons: Smart Match, Search toggle, and Filter.
class CommunityAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CommunityAppBar({
    super.key,
    required this.isSearching,
    required this.onSearchToggle,
    required this.onFilterTap,
    this.onWavesTap,
    this.matchesLayout = false,
    this.showSearch = true,
  });

  /// False while the Partners list shows Nearby, which has no name search.
  final bool showSearch;

  /// Matches-first layout: the Matches tab replaces the "Find partners"
  /// overflow entry, so it is hidden.
  final bool matchesLayout;

  final bool isSearching;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;

  /// Opens the waves inbox (it was the last of eight tabs).
  final VoidCallback? onWavesTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // Waves inbox, with the unread count. The live voice-rooms pill
        // moved into the Rooms tab, so it only polls while Rooms is open.
        _WavesButton(onTap: onWavesTap),
        // Coin balance — Coins v1 entry point, hidden when coinsEnabled is off.
        const CoinBalancePill(),
        // Notification inbox — reachable from every tab, not just chat.
        NotificationBell(color: context.textPrimary),
        // Search toggle — bare neutral, lowest weight.
        if (showSearch)
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
            if (!matchesLayout)
              PopupMenuItem(
                value: 'smart_match',
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.findPartners),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'vip',
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 20,
                    color: Color(0xFFFFA000),
                  ),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.goVip),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WavesButton extends ConsumerWidget {
  const _WavesButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(wavesUnreadProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    return IconButton(
      key: const Key('community-waves-button'),
      tooltip: AppLocalizations.of(context)!.waves,
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(Icons.waving_hand_outlined, color: context.textPrimary),
      ),
    );
  }
}
