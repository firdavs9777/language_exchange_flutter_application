import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/pages/community/card/match_card.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/services/interaction_service.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';

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

  /// nextRefreshAt we already invalidated for — guards against refetch loops.
  DateTime? _rolledOverFor;

  /// The notification ask is offered after the first non-empty load only.
  bool _primeOffered = false;

  void _maybePrimeOnFirstMatches() {
    if (_primeOffered) return;
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

  void _sayHi(DailyMatch m) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(onBrowse: widget.onBrowsePartners),
                ),
              ],
            ),
          );
        }
        _maybePrimeOnFirstMatches();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: matches.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              final m = matches[i - 1];
              return MatchCard(
                key: ValueKey(m.user.id),
                match: m,
                onSayHi: () => _sayHi(m),
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
  const _Empty({this.onBrowse});
  final VoidCallback? onBrowse;

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
          ],
        ),
      ),
    );
  }
}
