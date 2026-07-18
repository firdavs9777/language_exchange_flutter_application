import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// "Unlock N for 💎X" — the coins à-la-carte CTA added as a SECOND action
/// beside "Go VIP" in the 3 limit surfaces (translation, tutor 429,
/// moment creation). Cost/grant are read live from
/// `GET /coins/unlock-catalog` via [coinUnlockCatalogProvider] — never
/// hardcoded — so they can be tuned server-side without an app release.
///
/// [featureKey] must be one of the real backend keys: `translation`,
/// `moment`, `dm` (extra direct messages today — the daily message cap; NOT
/// the tutor `chat` key), or one of the 5 independent tutor chips
/// (`chat`/`roleplay`/`story`/`photo`/`pronunciation`). For the tutor surface this MUST be
/// the specific chip that hit its cap (from the 429's `feature` field),
/// not a generic "tutor" key.
///
/// Renders nothing when coins are disabled server-side, when the catalog
/// hasn't loaded yet, or when [featureKey] isn't in the catalog.
class UnlockCta extends ConsumerWidget {
  const UnlockCta({
    super.key,
    required this.featureKey,
    this.onUnlocked,
  });

  final String featureKey;

  /// Called after a successful unlock (balance already refreshed) so the
  /// caller can retry the gated action inline. Optional — surfaces that
  /// can't retry inline (e.g. a globally-triggered sheet with no handle
  /// back to the original action) may leave this null; the CTA still
  /// shows a "try again" confirmation via snackbar.
  final VoidCallback? onUnlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsEnabled = ref.watch(appConfigProvider).maybeWhen(
          data: (config) => config?.coinsEnabled ?? false,
          orElse: () => false,
        );
    if (!coinsEnabled) return const SizedBox.shrink();

    final catalogAsync = ref.watch(coinUnlockCatalogProvider);
    return catalogAsync.when(
      data: (catalog) {
        final entry = catalog[featureKey];
        if (entry == null || entry.cost <= 0) return const SizedBox.shrink();
        return _UnlockButton(
          featureKey: featureKey,
          cost: entry.cost,
          grant: entry.grant,
          onUnlocked: onUnlocked,
        );
      },
      // Avoid popping the CTA in mid-interaction — safest to render
      // nothing until the live catalog resolves rather than guess a cost.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UnlockButton extends ConsumerStatefulWidget {
  const _UnlockButton({
    required this.featureKey,
    required this.cost,
    required this.grant,
    this.onUnlocked,
  });

  final String featureKey;
  final int cost;
  final int grant;
  final VoidCallback? onUnlocked;

  @override
  ConsumerState<_UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends ConsumerState<_UnlockButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final client = ref.read(coinApiClientProvider);
      final response = await client.unlock(widget.featureKey);

      if (!mounted) return;

      if (response.success) {
        refreshCoinBalance(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unlocked +${widget.grant} more! 💎')),
        );
        widget.onUnlocked?.call();
      } else if (response.statusCode == 402) {
        _showInsufficientCoinsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Could not unlock right now.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showInsufficientCoinsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Not enough coins for that.'),
        action: SnackBarAction(
          label: 'Get more coins',
          onPressed: () {
            Navigator.push(
              context,
              AppPageRoute(builder: (_) => const CoinShopScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy ? null : _handleTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E88E5),
        side: const BorderSide(color: Color(0xFF1E88E5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              'Unlock ${widget.grant} for 💎${widget.cost}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }
}
