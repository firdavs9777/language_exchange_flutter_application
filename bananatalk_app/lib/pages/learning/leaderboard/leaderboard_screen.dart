import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/tabs/xp_tab.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/tabs/streak_tab.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/tabs/friends_tab.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/tabs/my_ranks_tab.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';

/// Leaderboard screen with rankings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(leaderboardTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              elevation: 0,
              backgroundColor: context.surfaceColor,
              floating: true,
              pinned: true,
              expandedHeight: 200,
              leading: const AppBackButton(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        Spacing.gapSM,
                        Text(
                          l10n.leaderboard,
                          style: context.displayMedium.copyWith(color: Colors.white),
                        ),
                        Spacing.gapXS,
                        Text(
                          l10n.competeWithLearners,
                          style: context.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: context.surfaceColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.textSecondary,
                    indicatorColor: AppColors.primary,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: l10n.xpRankings),
                      Tab(text: l10n.streaks),
                      Tab(text: l10n.friends),
                      Tab(text: l10n.myRanks),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            XpLeaderboardTab(),
            StreakLeaderboardTab(),
            FriendsLeaderboardTab(),
            MyRanksLeaderboardTab(),
          ],
        ),
      ),
    );
  }
}
