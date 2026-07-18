import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/active_voice_room_count_provider.dart';
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
    this.onLiveRoomsTap,
  });

  final bool isSearching;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;

  /// Tapped when the "N live" pill is shown. `null` (the current default —
  /// no caller passes this yet) means the pill still renders but taps are a
  /// no-op: switching to the Voice Rooms tab needs the `TabController` that
  /// lives in `community_main.dart`, which isn't wired up yet. See
  /// `.superpowers/sdd/rooms-task-8-report.md` for the follow-up needed in
  /// that file (`CommunityAppBar(... onLiveRoomsTap: () => _tabController
  /// .animateTo(voiceRoomsTabIndex))`).
  final VoidCallback? onLiveRoomsTap;

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
        // "N live" pill — the only always-visible entry point into Voice
        // Rooms outside the buried tab strip (rooms-audit §3/§6#3). Hides
        // itself while loading/errored/zero.
        _LiveRoomsPill(onTap: onLiveRoomsTap),
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

/// "🔴 N live" pill fed by [activeVoiceRoomCountProvider]. Hidden entirely
/// while the count is loading, errored, or zero — a live-room pull is only
/// worth the app-bar real estate once there's actually something to join.
class _LiveRoomsPill extends ConsumerWidget {
  const _LiveRoomsPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(activeVoiceRoomCountProvider);
    final count = countAsync.asData?.value ?? 0;
    if (countAsync.isLoading || countAsync.hasError || count == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count live',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
