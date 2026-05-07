import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Scrollable tab bar for the Community screen.
///
/// Renders the six community tabs (All, Gender, Nearby, City, Topics,
/// Voice Rooms) and applies the shared slide-in entrance animation.
class CommunityTabBar extends StatelessWidget {
  const CommunityTabBar({
    super.key,
    required this.tabController,
  });

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: context.primaryColor,
        unselectedLabelColor: context.textSecondary,
        labelStyle: context.labelLarge.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            context.labelLarge.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: context.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        labelPadding:
            const EdgeInsets.symmetric(horizontal: Spacing.lg),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 20),
                Spacing.hGapSM,
                const Text('All'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wc_rounded, size: 20),
                Spacing.hGapSM,
                const Text('Gender'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.near_me_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.nearby),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city_rounded, size: 20),
                Spacing.hGapSM,
                const Text('City'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.topics),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.voiceRooms),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms, delay: 100.ms)
        .slideY(
          begin: -0.03,
          end: 0,
          duration: 250.ms,
          delay: 100.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
