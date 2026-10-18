import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Price shown on the confirm card. The server charges the authoritative
/// amount (`BOOST_COST` backend-side); a mismatch surfaces as a 402.
const int kProfileBoostCostCoins = 150;

/// Localized remaining time ("3h 5m" / "5m"), or "Ending soon" under a
/// minute.
String formatBoostRemaining(AppLocalizations l10n, Duration d) {
  if (d.inMinutes < 1) return l10n.boostEndingSoon;
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? l10n.boostDurationHm(h, m) : l10n.boostDurationM(m);
}

/// How long after a boost ends its result is still offered with "Boost again".
const Duration kBoostResultWindow = Duration(days: 7);

/// The most recent boost that has ended within [kBoostResultWindow], from
/// `/boosts/history` (newest first); null when there is none.
Boost? lastEndedBoost(List<Boost> history, DateTime now) {
  for (final b in history) {
    if (b.isLive || b.endsAt == null || b.status == 'refunded') continue;
    return now.difference(b.endsAt!) <= kBoostResultWindow ? b : null;
  }
  return null;
}

/// Profile Boost: explain, confirm, then show the live boost with its
/// progress (time used, impressions by place, tips). After it ends, the last
/// result is shown with "Boost again". Reached only behind `boostsEnabled`.
class BoostScreen extends ConsumerStatefulWidget {
  const BoostScreen({super.key});

  @override
  ConsumerState<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends ConsumerState<BoostScreen> {
  Boost? _active;
  Boost? _last;
  bool _loading = true;
  int _ticks = 0;
  bool _busy = false;
  String? _message;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final client = ref.read(boostApiClientProvider);
    try {
      final b = await client.getActive();
      if (!mounted) return;
      if (b == null || !b.isLive) await _loadLast();
      if (!mounted) return;
      _setActive(b);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The last ended boost, for the result card. A failed read shows none.
  Future<void> _loadLast() async {
    try {
      final history = await ref.read(boostApiClientProvider).getHistory();
      _last = lastEndedBoost(history, DateTime.now());
    } catch (_) {
      _last = null;
    }
  }

  /// Re-reads the live boost so its impressions move while the screen is
  /// open; keeps the current one on a failed read.
  Future<void> _refreshActive() async {
    try {
      final b = await ref.read(boostApiClientProvider).getActive();
      if (!mounted || b == null || !b.isLive) return;
      setState(() => _active = b);
    } catch (_) {}
  }

  void _setActive(Boost? b) {
    _tick?.cancel();
    _tick = null;
    if (b != null && b.isLive) {
      _tick = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        if (_active != null && !_active!.isLive) {
          _tick?.cancel();
          // Just ended: show its result with "Boost again".
          _last = _active;
          setState(() => _active = null);
          _loadLast().then((_) {
            if (mounted) setState(() {});
          });
        } else {
          setState(() {});
          if (++_ticks % 2 == 0) _refreshActive();
        }
      });
    }
    setState(() {
      _active = (b != null && b.isLive) ? b : null;
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final b = await ref.read(boostApiClientProvider).purchaseProfileBoost();
      if (!mounted) return;
      refreshCoinBalance(ref);
      _setActive(b);
    } on BoostException catch (e) {
      if (!mounted) return;
      switch (e.error) {
        case BoostError.insufficientCoins:
          Navigator.push(
            context,
            AppPageRoute<void>(builder: (_) => const CoinShopScreen()),
          );
        case BoostError.alreadyBoosted:
          await _load();
          // The server says a boost is live but we could not load it: say
          // so rather than leaving the confirm card silently unchanged.
          if (mounted && _active == null) {
            setState(() => _message = l10n.boostFailed);
          }
        case BoostError.capacityFull:
          setState(() => _message = l10n.boostCapacityFull);
      }
    } catch (_) {
      if (mounted) setState(() => _message = l10n.boostFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    refreshCoinBalance(ref);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.boostTitle)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.rocket_launch_rounded,
              size: 56,
              color: AppColors.matchAccent,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_active != null)
              _activeCard(l10n, _active!)
            else
              _purchaseCard(l10n),
          ],
        ),
      ),
    );
  }

  Widget _purchaseCard(AppLocalizations l10n) {
    final balance = ref.watch(coinBalanceProvider);
    final last = _last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (last != null) ...[
          _lastResultCard(l10n, last),
          const SizedBox(height: 20),
        ],
        Text(
          l10n.boostExplain,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.boostExplainMore,
          key: const Key('boost-explain-more'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.boostCostLine(kProfileBoostCostCoins),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        balance.maybeWhen(
          data: (b) => Text(
            l10n.boostBalanceLine(b),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.matchMutedText),
          ),
          orElse: () => const SizedBox(height: 18),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            key: const ValueKey('boost_confirm'),
            onPressed: _busy ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.matchAccent,
              foregroundColor: AppColors.matchInk,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    last != null ? l10n.boostAgain : l10n.boostConfirm,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Text(
            _message!,
            key: const ValueKey('boost_message'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.matchMutedText),
          ),
        ],
      ],
    );
  }

  Widget _activeCard(AppLocalizations l10n, Boost b) {
    final now = DateTime.now();
    final left = b.endsAt!.difference(now);
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('boost_active'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.boostActiveTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          left.inMinutes < 1
              ? formatBoostRemaining(l10n, left)
              : l10n.boostTimeLeft(formatBoostRemaining(l10n, left)),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            key: const ValueKey('boost_progress'),
            value: b.progressAt(now),
            minHeight: 8,
            backgroundColor: context.containerColor,
            color: AppColors.matchAccent,
          ),
        ),
        const SizedBox(height: 20),
        _impressionsCard(l10n, b, l10n.boostSeenBy(b.impressions)),
        if (b.impressions == 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.boostCountingHint,
            key: const ValueKey('boost_counting_hint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
          ),
        ],
        const SizedBox(height: 20),
        _tipsCard(l10n),
      ],
    );
  }

  /// Total impressions and where they happened.
  Widget _impressionsCard(AppLocalizations l10n, Boost b, String headline) {
    final theme = Theme.of(context);
    Widget row(IconData icon, String label, int n) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: context.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text('$n', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            headline,
            key: const ValueKey('boost_impressions'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          row(Icons.people_alt_rounded, l10n.boostSourcePartners, b.fromPartners),
          row(Icons.favorite_rounded, l10n.boostSourceMatches, b.fromMatches),
          row(Icons.auto_awesome_rounded, l10n.boostSourceMoments, b.fromMoments),
        ],
      ),
    );
  }

  Widget _tipsCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('boost_tips'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: context.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.boostTipsTitle,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('• ${l10n.boostTipMoment}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('• ${l10n.boostTipProfile}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('boost_post_moment'),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(l10n.guideMomentsCta),
              onPressed: () => Navigator.push(
                context,
                AppPageRoute<void>(builder: (_) => const CreateMoment()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The last ended boost's result, above the purchase card.
  Widget _lastResultCard(AppLocalizations l10n, Boost b) =>
      KeyedSubtree(
        key: const ValueKey('boost_last_result'),
        child: _impressionsCard(l10n, b, l10n.boostLastResult(b.impressions)),
      );
}
