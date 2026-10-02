import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Price shown on the confirm card. The server charges the authoritative
/// amount (`BOOST_COST` backend-side); a mismatch surfaces as a 402.
const int kProfileBoostCostCoins = 150;

/// Profile Boost: explain, confirm, then show the live boost with a countdown
/// and impression count. Reached only behind `boostsEnabled`.
class BoostScreen extends ConsumerStatefulWidget {
  const BoostScreen({super.key});

  @override
  ConsumerState<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends ConsumerState<BoostScreen> {
  Boost? _active;
  bool _loading = true;
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
    try {
      final b = await ref.read(boostApiClientProvider).getActive();
      if (!mounted) return;
      _setActive(b);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setActive(Boost? b) {
    _tick?.cancel();
    _tick = null;
    if (b != null && b.isLive) {
      _tick = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        if (_active != null && !_active!.isLive) {
          _tick?.cancel();
          setState(() => _active = null);
        } else {
          setState(() {});
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
      refreshCoinBalance(ref);
      if (mounted) _setActive(b);
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

  String _remaining(Duration d) {
    if (d.isNegative) return '0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.boostExplain,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
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
                    l10n.boostConfirm,
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
    final left = b.endsAt!.difference(DateTime.now());
    return Column(
      key: const ValueKey('boost_active'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.boostActiveTitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.boostTimeLeft(_remaining(left)),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.boostSeenBy(b.impressions),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.matchMutedText),
        ),
      ],
    );
  }
}
