import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/main/sections/learn_tab.dart';
import 'package:bananatalk_app/pages/learning/main/sections/progress_card.dart';
import 'package:bananatalk_app/pages/learning/main/sections/recommended_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/spotlight_carousel.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/pages/learning/main/sections/today_pack_row.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/widgets/coins/coin_balance_pill.dart';
import 'package:bananatalk_app/widgets/guides/page_guide.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';
import 'package:bananatalk_app/widgets/notifications/notification_bell.dart';
import 'package:bananatalk_app/widgets/vip_up_pill.dart';

/// The one-scroll AI Study hub (spec 2026-10-13 §3), shown when
/// `AppConfig.studyHubEnabled` is on. [LearningMain] owns the celebration
/// listeners; this widget is only the page.
class StudyHub extends ConsumerStatefulWidget {
  const StudyHub({super.key});

  /// Marks the Explore groups for tests (`find.byKey`). The scroll target
  /// itself is a per-instance GlobalKey in the State: a static one broke as
  /// soon as two hubs were mounted at once (a `daily_drop` notification pushes
  /// a second LearningMain over the shell's).
  static const groupsSectionKey = ValueKey('study-hub-groups');

  @override
  ConsumerState<StudyHub> createState() => _StudyHubState();
}

class _StudyHubState extends ConsumerState<StudyHub> {
  static const double _expandedHeight = 110;
  static const double _toolbarHeight = 56;
  static const _gradientLight = [Color(0xFF667EEA), Color(0xFF764BA2)];
  static const _gradientDark = [Color(0xFF1A1A2E), Color(0xFF16213E)];

  final _scroll = ScrollController();

  /// What "See all features" scrolls to. A GlobalKey because
  /// [Scrollable.ensureVisible] needs its context; per instance so two
  /// mounted hubs never share it.
  final _groupsKey = GlobalKey(debugLabel: 'study-hub-groups');

  @visibleForTesting
  GlobalKey get groupsKey => _groupsKey;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The guide's primary action. Mirrors the today row's precedence: a
  /// learner with no target language picks one first; an empty pack has
  /// nothing to open.
  void _openPack() {
    final pack = ref.read(dailyPackProvider).valueOrNull;
    if (pack == null) return;
    if (pack.needsLanguage) {
      pickLearningLanguage(context, ref);
      return;
    }
    if (pack.theme == null && pack.stations.isEmpty) return;
    openDailyPack(context, ref, pack);
  }

  void _scrollToGroups() {
    final target = _groupsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(learningProgressProvider);
    ref.invalidate(dailyPackProvider);
    ref.invalidate(weakAreasProvider);
    ref.invalidate(tutorMemoryAndQuotasProvider);
    ref.invalidate(vocabularyStatsProvider(null));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const gap = SizedBox(height: StudyHubMetrics.tileGap);
    const m = StudyHubMetrics.pageMargin;

    // Coarser than PageGuide's own rule (no per-surface `acted` or retired
    // flag), so the carousel can stay hidden a little longer than the guide
    // card does. Acceptable: both are first-week only.
    final guideOn = ref.watch(isGuidePeriodProvider).valueOrNull ?? false;
    // Checked here rather than left to the carousel so an empty carousel
    // does not leave a stray gap at the top of the page.
    final announcements =
        ref.watch(appConfigProvider).valueOrNull?.announcements ??
        const <Announcement>[];
    final dismissed =
        ref.watch(spotlightDismissedProvider).valueOrNull ?? const <String>{};
    final showSpotlight =
        !guideOn && spotlightItems(announcements, dismissed).isNotEmpty;
    final progress = ref.watch(learningProgressProvider).valueOrNull;
    final showAds = ref.watch(showAdsProvider);

    // Re-tapping the AI Study tab (index 0) scrolls back to the top.
    ref.listen(tabReselectProvider, (_, next) {
      if (next.tab == 0 && _scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: RefreshIndicator(
        edgeOffset: MediaQuery.paddingOf(context).top + _toolbarHeight,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _header(context, l),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                m,
                m,
                m,
                FloatingTabBar.clearance(context),
              ),
              // One eager Column, not a lazy SliverList: "See all features"
              // scrolls to the groups with Scrollable.ensureVisible, which
              // needs them built. A lazy list leaves them unbuilt on a short
              // phone, so the button did nothing. The page is short enough
              // that building it all costs nothing.
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hides itself outside the first week; its padding (the
                    // gap below it) only exists while it shows.
                    PageGuide(
                      surface: GuideSurface.aiStudy,
                      icon: Icons.auto_awesome_rounded,
                      accent: const Color(0xFF667EEA),
                      title: l.guideStudyHubTitle,
                      body: l.guideStudyHubBody,
                      ctaLabel: l.guideStudyHubCta,
                      onCta: _openPack,
                      secondaryLabel: l.guideStudyHubSecondary,
                      onSecondary: _scrollToGroups,
                      padding: const EdgeInsets.only(
                        bottom: StudyHubMetrics.tileGap,
                      ),
                    ),
                    if (showSpotlight) ...[const SpotlightCarousel(), gap],
                    ref
                        .watch(dailyPackProvider)
                        .when(
                          loading: () => const SizedBox(
                            height: StudyHubMetrics.todayRowHeight,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (pack) => TodayPackRow(
                            pack: pack,
                            onOpen: () => openDailyPack(context, ref, pack),
                            onPickLanguage: () =>
                                pickLearningLanguage(context, ref),
                            onTakePlacement: () => openPlacement(context, ref),
                          ),
                        ),
                    gap,
                    // Renders nothing until a weak area with enough attempts
                    // exists.
                    const RecommendedTile(),
                    const SizedBox(height: StudyHubMetrics.groupGap),
                    KeyedSubtree(
                      key: _groupsKey,
                      child: const StudyFeatureGroups(
                        key: StudyHub.groupsSectionKey,
                      ),
                    ),
                    // Always shown: its shortcuts (achievements, vocabulary,
                    // review) are the hub's only way to those screens.
                    const SizedBox(height: StudyHubMetrics.groupGap),
                    ProgressCard(
                      progress: progress,
                      onFullReport: () => openProgress(context, ref),
                    ),
                    if (showAds) ...[
                      gap,
                      const NativeAdWidget(key: ValueKey('study-hub-native')),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l) {
    final isDark = context.isDarkMode;
    final colors = isDark ? _gradientDark : _gradientLight;
    return SliverAppBar(
      pinned: true,
      expandedHeight: _expandedHeight,
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.first,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, box) {
          final top = MediaQuery.paddingOf(context).top;
          // 1 fully expanded, 0 collapsed to the title.
          final t =
              ((box.maxHeight - top - _toolbarHeight) /
                      (_expandedHeight - _toolbarHeight))
                  .clamp(0.0, 1.0);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudyHubMetrics.pageMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: _toolbarHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.study,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (t > 0)
                            Opacity(
                              opacity: t,
                              child: IgnorePointer(
                                ignoring: t < 0.5,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    VipUpPill(onLight: false),
                                    CoinBalancePill(onLight: false),
                                    NotificationBell(color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (t > 0)
                      Expanded(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            child: Opacity(
                              opacity: t,
                              child: const _HeaderChips(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The pack's CEFR level for the header chip: what was served, else what
/// was asked for; null unless it looks like A1–C2 (the server sends the bare
/// code, as the hero card's fallback line shows).
@visibleForTesting
String? packCefrLevel(DailyPack? pack) {
  for (final raw in [pack?.servedLevel, pack?.requestedLevel]) {
    final v = raw?.trim().toUpperCase();
    if (v != null && RegExp(r'^[ABC][12]$').hasMatch(v)) return v;
  }
  return null;
}

/// Header line 2: streak, level and target language.
class _HeaderChips extends ConsumerWidget {
  const _HeaderChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final progress = ref.watch(learningProgressProvider).valueOrNull;
    final target = ref.watch(userProvider).valueOrNull?.language_to_learn ?? '';
    final cefr = packCefrLevel(ref.watch(dailyPackProvider).valueOrNull);
    final chips = <String>[
      if (progress != null) l.studyStreakDays(progress.currentStreak),
      if (progress != null) l.studyLevelShort(progress.level),
      // Spec §3: target language + CEFR level, one chip.
      if (target.isNotEmpty) cefr == null ? target : '$target · $cefr',
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: Colors.white);
    return Row(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                chips[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
