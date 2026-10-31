import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

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
class CommunityTabBar extends StatelessWidget {
  const CommunityTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    this.gatheringsEnabled = true,
  });

  final TabController tabController;

  /// From `communityTabLayout`; one chip per tab, in order.
  final List<CommunityTabId> tabs;

  /// The Clubs slot is labelled "Voice" while 모임 is off.
  final bool gatheringsEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      for (final tab in tabs)
        switch (tab) {
          CommunityTabId.matches => l10n.communityTabMatches,
          CommunityTabId.partners => l10n.communityTabPartners,
          CommunityTabId.clubs =>
            gatheringsEnabled ? l10n.gatheringsTabLabel : l10n.voiceRooms,
          CommunityTabId.rooms => l10n.communityTabRooms,
        },
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
  });

  final String label;
  final bool selected;
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
            ],
          ),
        ),
      ),
    );
  }
}
