import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

/// Scrollable tab bar for the Community screen.
///
/// Renders the community tabs in order: All, Gender, Voice Rooms,
/// (when enabled) Rooms, Nearby, City, Topics, Waves — the two "rooms"
/// tabs are grouped right after Gender — and applies the shared slide-in
/// entrance animation.
class CommunityTabBar extends ConsumerWidget {
  const CommunityTabBar({
    super.key,
    required this.tabController,
    this.showRoomsTab = true,
  });

  final TabController tabController;

  /// Workstream D: hides the 8th "Rooms" tab when the server-side
  /// `roomsEnabled` kill switch is off. Must stay in sync with
  /// `CommunityMain`'s `TabBarView` children count — see
  /// `_syncTabCountWithRoomsFlag`.
  final bool showRoomsTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            labelStyle: context.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: context.labelLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: context.primaryColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            labelPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded, size: 20),
                    Spacing.hGapSM,
                    Text(AppLocalizations.of(context)!.communityTabAll),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diversity_3_rounded, size: 20),
                    Spacing.hGapSM,
                    Text(AppLocalizations.of(context)!.communityTabGender),
                  ],
                ),
              ),
              // Both "rooms" concepts (Voice Rooms + text Rooms) are grouped
              // immediately after Gender so they read as related features —
              // see rooms-audit-report.md §5. Keep `roomsInsertionIndex` in
              // `_syncTabCountWithRoomsFlag` (community_main.dart) equal to
              // this conditional Tab's index (3) if this order ever changes.
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
              if (showRoomsTab)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.forum_rounded, size: 20),
                      Spacing.hGapSM,
                      // TODO(l10n): no `communityTabRooms` key exists yet in
                      // the arb files. Adding one across every locale is
                      // heavy for this batch — following the established
                      // fallback pattern (see plan Task 9) with a plain
                      // string until a follow-up localizes it.
                      Text('Rooms'),
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
                    Text(AppLocalizations.of(context)!.communityTabCity),
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
                    const Icon(Icons.waving_hand_rounded, size: 20),
                    Spacing.hGapSM,
                    Builder(
                      builder: (context) {
                        final unread = ref
                            .watch(wavesUnreadProvider)
                            .maybeWhen(data: (n) => n, orElse: () => 0);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Text(AppLocalizations.of(context)!.wavesTab),
                            if (unread > 0)
                              Positioned(
                                right: -10,
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
                        );
                      },
                    ),
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
