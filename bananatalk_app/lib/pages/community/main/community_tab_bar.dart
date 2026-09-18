import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

/// Scrollable chip bar for the Community screen.
///
/// Renders the community tabs in order: All, Gender, 모임 / Gatherings,
/// (when enabled) Rooms, Nearby, City, Topics, Waves — the two group tabs
/// are grouped right after Gender.
///
/// This is a RENDERING change only. The TabController, the TabBarView, the
/// conditional-Rooms index arithmetic in community_main.dart, and both kill
/// switches are untouched: eight icon+label tabs under an underline were what
/// made the strip feel crowded, not the destinations themselves.
class CommunityTabBar extends ConsumerWidget {
  const CommunityTabBar({
    super.key,
    required this.tabController,
    this.showRoomsTab = true,
    this.gatheringsEnabled = true,
  });

  final TabController tabController;

  /// 모임 REPLACES the voice-rooms entry rather than adding a ninth tab.
  /// Gatherings are voice rooms with commitment attached, and voice rooms
  /// failed 93 times out of 93 by depending on people being online at the
  /// same moment — so the fix is to retire that entry, not to sit beside it.
  ///
  /// When the server's kill switch is off this slot falls back to the old
  /// Voice Rooms tab. It does NOT disappear: the tab count stays flat in both
  /// states, which keeps the conditional-Rooms index arithmetic below (and
  /// `remapTabIndexForRoomsFlag`) untouched by this flag.
  final bool gatheringsEnabled;

  /// Workstream D: hides the 8th "Rooms" tab when the server-side
  /// `roomsEnabled` kill switch is off. Must stay in sync with
  /// `CommunityMain`'s `TabBarView` children count — see
  /// `_syncTabCountWithRoomsFlag`.
  final bool showRoomsTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unread =
        ref.watch(wavesUnreadProvider).maybeWhen(data: (n) => n, orElse: () => 0);

    // Order MUST mirror community_main.dart's TabBarView children exactly, and
    // the conditional Rooms entry must stay at index 3 — see
    // remapTabIndexForRoomsFlag.
    final labels = <String>[
      l10n.communityTabAll,
      l10n.communityTabGender,
      gatheringsEnabled ? l10n.gatheringsTabLabel : l10n.voiceRooms,
      if (showRoomsTab) 'Rooms',
      l10n.nearby,
      l10n.communityTabCity,
      l10n.topics,
      l10n.wavesTab,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: AnimatedBuilder(
        // The chips are driven by the controller, so they must repaint when it
        // moves -- including when the move came from a SWIPE rather than a tap.
        animation: tabController,
        builder: (context, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: _Chip(
                    key: Key('community-chip-$i'),
                    label: labels[i],
                    selected: tabController.index == i,
                    showDot: labels[i] == l10n.wavesTab && unread > 0,
                    onTap: () => tabController.animateTo(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRound,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.borderRound,
            border: Border.all(
              color: selected ? AppColors.primary : context.dividerColor,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                label,
                style: context.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.textSecondary,
                ),
              ),
              if (showDot)
                Positioned(
                  right: -8,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
