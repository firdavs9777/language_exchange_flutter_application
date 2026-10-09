import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/pages/coins/boost_screen.dart';
import 'package:bananatalk_app/pages/community/card/match_card.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/pages/community/first_session/matches_first_session_panel.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/services/interaction_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';

/// Daily batch size + the most extra cards purchasable per day (3 buys of
/// +3). Mirrors backend `BATCH_SIZE` (lib/dailyMatches.js) and
/// `EXTRA_MATCHES_MAX` (config/coinCatalog.js).
const int kDailyMatchesBatchSize = 6;
const int kExtraMatchesMax = 9;

/// Offer "+3 more matches" until the server's daily ceiling (6 + 9 = 15) is
/// reached. Past it the server answers 409 `extra_matches_maxed`.
@visibleForTesting
bool shouldShowExtraMatchesCta({
  required bool boostsEnabled,
  required int count,
}) => boostsEnabled && count < kDailyMatchesBatchSize + kExtraMatchesMax;

/// "Your N matches today" list. Self-contained; mounted by the community page.
class MatchesTab extends ConsumerStatefulWidget {
  const MatchesTab({
    super.key,
    this.onBrowsePartners,
    this.primeNotifications = maybePrimeNotifications,
  });

  /// Offered once after the first non-empty load. Injectable for tests.
  final Future<void> Function(BuildContext) primeNotifications;

  /// Invoked by the empty-state button (switch to the Partners tab).
  final VoidCallback? onBrowsePartners;

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab> {
  final Set<String> _skipped = {};

  /// One view per app run, not per rebuild AND not per tab remount. The
  /// ListView header rebuilds every scroll frame, and TabBarView rebuilds a
  /// fresh State whenever the user returns from a non-adjacent tab -- three
  /// tab switches used to burn the whole cap. Both latches therefore live
  /// outside the widget; see first_session_store.dart.
  /// Scheduled after the frame: both latches are providers, and Riverpod
  /// refuses a write during build.
  void _recordGuidanceShownAfterFrame(int timesShown) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recordGuidanceShown(timesShown);
    });
  }

  void _reportMatchesShownAfterFrame(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportMatchesShown(count);
    });
  }

  void _recordGuidanceShown(int timesShown) {
    final latch = ref.read(firstSessionGuidanceRecordedProvider.notifier);
    if (latch.state) return;
    latch.state = true;
    AnalyticsService.instance.firstSessionGuidanceShown(
      timesShown: timesShown + 1,
    );
    // Deliberately NOT invalidating firstSessionStateProvider afterwards: the
    // latch already stops a second record, and refetching mid-view removed
    // the panel milliseconds after it appeared, jumping the list exactly as
    // the user reached for the first card. The new count is read on the next
    // mount.
    FirstSessionStore.recordShown();
  }

  void _reportMatchesShown(int count) {
    if (count == 0) return;
    AnalyticsService.instance.setIsNewUser(true);
    final latch = ref.read(firstSessionMatchesReportedProvider.notifier);
    if (latch.state) return;
    latch.state = true;
    AnalyticsService.instance.firstSessionMatchesShown(matchCount: count);
  }

  /// nextRefreshAt we already invalidated for — guards against refetch loops.
  DateTime? _rolledOverFor;

  /// The notification ask is offered after the first non-empty load only.
  bool _primeOffered = false;

  /// A non-empty batch is loaded, so the ask can be made once visible.
  bool _hasMatches = false;

  /// Top-level index of the Community tab in TabsScreen.
  static const int _communityTab = 1;

  /// TabsScreen builds every page eagerly, so this tab loads while the user
  /// is on another top-level tab. Only offer when Community is selected and
  /// our route is on top; otherwise leave [_primeOffered] unset so the
  /// selectedTabProvider listener can offer when the user switches over.
  void _maybePrimeOnFirstMatches() {
    if (_primeOffered) return;
    if (ref.read(selectedTabProvider) != _communityTab) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _primeOffered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.primeNotifications(context);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(dailyMatchesProvider);
    try {
      await ref.read(dailyMatchesProvider.future);
    } catch (_) {
      // The error state renders its own retry affordance.
    }
  }

  void _maybeRollOver(DailyMatchesResult result) {
    final next = result.nextRefreshAt;
    if (next == null || _rolledOverFor == next) return;
    if (!DateTime.now().isAfter(next)) return;
    _rolledOverFor = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(dailyMatchesProvider);
    });
  }

  void _sayHi(DailyMatch m, {int position = 0}) {
    // Gated on the SAME cohort as its denominator. Firing for everyone while
    // first_session_guidance_shown fires only for new users made
    // say_hi_tapped / guidance_shown exceed 1 and mean nothing -- and the
    // spec's Risks section makes exactly that ratio the decision rule for
    // whether a header is salient enough.
    final isNew = ref.read(userProvider).valueOrNull?.isNewUser ?? false;
    if (isNew) {
      AnalyticsService.instance.firstSessionSayHiTapped(position: position);
    }
    final u = m.user;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          userId: u.id,
          userName: u.name,
          profilePicture: u.profileImageUrl,
          isVip: u.isVip,
        ),
      ),
    );
  }

  void _wave(DailyMatch m) {
    final u = m.user;
    showSendWaveSheet(
      context,
      targetUserId: u.id,
      targetUserName: u.name,
      targetUserCountry: u.location.country.isNotEmpty
          ? u.location.country
          : null,
    );
  }

  void _skip(DailyMatch m) {
    setState(() => _skipped.add(m.user.id));
    InteractionService.skipUser(m.user.id);
  }

  /// A non-empty batch has been shown; only then can "exhausted" fire, so the
  /// interstitial is never the first thing after launch.
  bool _sawNonEmptyBatch = false;
  bool _exhaustedAdFired = false;

  /// Batch exhausted (user cleared the last card, or the list emptied after a
  /// non-empty load). At most one interstitial per session, behind
  /// `rewardedLimitsEnabled`; VIP / ad-free never sees one.
  void _onBatchExhausted() {
    if (!_sawNonEmptyBatch || _exhaustedAdFired) return;
    final flagOn =
        ref.read(appConfigProvider).valueOrNull?.rewardedLimitsEnabled ?? false;
    // Checked before latching, so a flag that resolves later still fires.
    if (!flagOn) return;
    _exhaustedAdFired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AdService().maybeShowInterstitialOncePerSession(
        'matches_exhausted',
        flagOn: flagOn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<int>(selectedTabProvider, (_, next) {
      if (next == _communityTab && _hasMatches) _maybePrimeOnFirstMatches();
    });
    final boostsEnabled = ref
        .watch(appConfigProvider)
        .maybeWhen(
          data: (config) => config?.boostsEnabled ?? false,
          orElse: () => false,
        );
    final async = ref.watch(dailyMatchesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _LoadError(onRetry: _refresh),
            ),
          ],
        ),
      ),
      data: (result) {
        if (result.unavailable) return const SizedBox.shrink();
        _maybeRollOver(result);
        final matches = result.matches
            .where((m) => m.user.id.isNotEmpty && !_skipped.contains(m.user.id))
            .toList();
        if (matches.isEmpty) {
          _hasMatches = false;
          _onBatchExhausted();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(
                    onBrowse: widget.onBrowsePartners,
                    showBoost: boostsEnabled,
                  ),
                ),
              ],
            ),
          );
        }
        _hasMatches = true;
        _sawNonEmptyBatch = true;
        _exhaustedAdFired = false;
        _maybePrimeOnFirstMatches();
        final showExtra = shouldShowExtraMatchesCta(
          boostsEnabled: boostsEnabled,
          count: result.matches.length,
        );

        // An empty or errored batch never reaches here -- those take the
        // _Empty / _LoadError branches above, which render no list header. A
        // new user with no matches has a supply problem, not a guidance one.
        final isNew = ref
            .watch(userProvider)
            .maybeWhen(data: (u) => u.isNewUser, orElse: () => false);
        final session = ref
            .watch(firstSessionStateProvider)
            .maybeWhen(data: (s) => s, orElse: () => FirstSessionState.unknown);
        final showGuidance = shouldShowFirstSessionGuidance(
          isNewUser: isNew,
          hasMessaged: session.hasMessaged,
          timesShown: session.timesShown,
        );
        // Debug-only: the panel has four conditions and used to fail silently,
        // which made it untestable on a device.
        if (kDebugMode) {
          debugPrint(
            '[FirstSession] show=$showGuidance '
            '(isNewUser=$isNew hasMessaged=${session.hasMessaged} '
            'timesShown=${session.timesShown}/$kMaxGuidanceViews '
            'matches=${matches.length})',
          );
        }
        if (isNew) _reportMatchesShownAfterFrame(matches.length);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: matches.length + 1 + (showExtra ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The panel REPLACES the usual header for a first-timer
                      // rather than stacking on it. Stacked, they read the
                      // same count twice -- "N people picked for you today"
                      // then "Your N matches today" -- three lines where the
                      // spec specified two.
                      if (showGuidance)
                        Builder(
                          builder: (_) {
                            _recordGuidanceShownAfterFrame(session.timesShown);
                            return MatchesFirstSessionPanel(
                              matchCount: matches.length,
                            );
                          },
                        )
                      else
                        Text(
                          l10n.matchesTodayTitle(matches.length),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        result.nextRefreshAt == null
                            ? l10n.matchesRefreshHintFallback
                            : l10n.matchesRefreshHint(
                                DateFormat.jm().format(
                                  result.nextRefreshAt!.toLocal(),
                                ),
                              ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.matchMutedText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (i == matches.length + 1) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    child: UnlockCta(
                      key: const Key('extra-matches-cta'),
                      featureKey: 'extra_matches',
                      labelBuilder: (cost, _) => l10n.extraMatchesCta(cost),
                      onUnlocked: () => ref.invalidate(dailyMatchesProvider),
                    ),
                  ),
                );
              }
              final m = matches[i - 1];
              return MatchCard(
                key: ValueKey(m.user.id),
                match: m,
                // Top card only, and only while the guide is up: the panel
                // says "say hi", the ring says which button that is.
                highlightSayHi: showGuidance && i == 1,
                onSayHi: () => _sayHi(m, position: i - 1),
                onWave: () => _wave(m),
                onSkip: () => _skip(m),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.somethingWentWrong,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.matchMutedText),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({this.onBrowse, this.showBoost = false});
  final VoidCallback? onBrowse;
  final bool showBoost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.matchesEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchesEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.matchMutedText),
            ),
            if (onBrowse != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onBrowse,
                child: Text(l10n.matchesEmptyCta),
              ),
            ],
            if (showBoost) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('matches-empty-boost'),
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute<void>(builder: (_) => const BoostScreen()),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(l10n.boostFromMatches),
              ),
              TextButton.icon(
                key: const Key('matches-empty-vip'),
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute<void>(builder: (_) => const VipPlansScreen()),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: Text(l10n.vipFromMatches),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
