import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/paywall/paywall_navigation.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

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
/// 409 `extra_matches_maxed`: the daily extra-matches ceiling is reached.
bool isExtraMatchesMaxed(int statusCode, String? error) =>
    statusCode == 409 && error == 'extra_matches_maxed';

/// Paywall placement for a coin-unlock feature key, used when the surface
/// did not hand its own flow to [UnlockCta].
String paywallPlacementForFeature(String featureKey) {
  switch (featureKey) {
    case 'translation':
      return PaywallPlacement.translationCap;
    case 'moment':
      return PaywallPlacement.momentCap;
    case 'dm':
      return PaywallPlacement.dmCap;
    case 'wave':
      return PaywallPlacement.waveCap;
    case 'extra_matches':
      return PaywallPlacement.extraMatches;
    case 'who_waved':
      return PaywallPlacement.visitorList;
    case 'chat':
    case 'roleplay':
    case 'story':
    case 'photo':
    case 'pronunciation':
      return PaywallPlacement.tutorQuota;
    default:
      return PaywallPlacement.other;
  }
}

class UnlockCta extends ConsumerWidget {
  const UnlockCta({
    super.key,
    required this.featureKey,
    this.onUnlocked,
    this.labelBuilder,
    this.onMaxed,
    this.flow,
    this.onCtaTapped,
  });

  final String featureKey;

  /// The showing this button belongs to. Without one the button starts its
  /// own flow (placement by [featureKey]) the first time it is tapped.
  final PaywallFlow? flow;

  /// Called when the button is tapped, so the host surface can tell that the
  /// person acted (and not log `dismissed`).
  final VoidCallback? onCtaTapped;

  /// Called when the server refuses because the daily ceiling is reached
  /// (409 `extra_matches_maxed`). The CTA hides itself either way.
  final VoidCallback? onMaxed;

  /// Optional localized label (e.g. "+3 more matches — 40 coins") built from
  /// the live catalog cost/grant; defaults to "Unlock N for 💎X".
  final String Function(int cost, int grant)? labelBuilder;

  /// Called after a successful unlock (balance already refreshed) so the
  /// caller can retry the gated action inline. Optional — surfaces that
  /// can't retry inline (e.g. a globally-triggered sheet with no handle
  /// back to the original action) may leave this null; the CTA still
  /// shows a "try again" confirmation via snackbar.
  final VoidCallback? onUnlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsEnabled = ref
        .watch(appConfigProvider)
        .maybeWhen(
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
          labelBuilder: labelBuilder,
          onMaxed: onMaxed,
          flow: flow,
          onCtaTapped: onCtaTapped,
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
    this.labelBuilder,
    this.onMaxed,
    this.flow,
    this.onCtaTapped,
  });

  final String featureKey;
  final PaywallFlow? flow;
  final VoidCallback? onCtaTapped;
  final VoidCallback? onMaxed;
  final int cost;
  final int grant;
  final VoidCallback? onUnlocked;
  final String Function(int cost, int grant)? labelBuilder;

  @override
  ConsumerState<_UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends ConsumerState<_UnlockButton> {
  bool _busy = false;

  /// Server said the daily ceiling is reached; render nothing from now on.
  bool _maxed = false;

  PaywallFlow? _ownFlow;

  PaywallFlow get _flow =>
      widget.flow ??
      (_ownFlow ??= PaywallFlow.start(
        paywallPlacementForFeature(widget.featureKey),
        detail: widget.featureKey,
      ));

  /// The flow the shop opens on after a 402: same id, own placement.
  PaywallFlow get _shopFlow => PaywallFlow(
    placement: PaywallPlacement.notEnoughCoins,
    flowId: _flow.flowId,
    offerId: _flow.offerId,
    detail: widget.featureKey,
  );

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    widget.onCtaTapped?.call();
    paywallLog(_flow, PaywallAction.ctaCoins);

    try {
      final client = ref.read(coinApiClientProvider);
      final response = await client.unlock(widget.featureKey);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (response.success) {
        paywallLog(
          _flow,
          PaywallAction.unlockSucceeded,
          detail: widget.featureKey,
        );
        refreshCoinBalance(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.unlockedMore(widget.grant)} 💎')),
        );
        widget.onUnlocked?.call();
      } else if (response.statusCode == 402) {
        _showInsufficientCoinsDialog();
      } else if (isExtraMatchesMaxed(response.statusCode, response.error)) {
        _notify(l10n.extraMatchesMaxed);
        setState(() => _maxed = true);
        widget.onMaxed?.call();
      } else {
        _notify(response.error ?? l10n.unlockFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Inside a bottom sheet or dialog a SnackBar lands on the Scaffold
  /// UNDER the sheet and is never seen (2026-10-17: "not enough coins" on
  /// the tutor upgrade sheet). There, tell the user in a dialog instead.
  bool get _inPopup => ModalRoute.of(context) is PopupRoute;

  void _notify(String message) {
    if (_inPopup) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInsufficientCoinsDialog() {
    final l10n = AppLocalizations.of(context)!;
    if (_inPopup) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('unlock-not-enough-coins'),
          content: Text(l10n.notEnoughCoins),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                openCoinShop<void>(context, _shopFlow, route: PaywallRoute.app);
              },
              child: Text(l10n.getMoreCoins),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.notEnoughCoins),
        action: SnackBarAction(
          label: l10n.getMoreCoins,
          onPressed: () {
            openCoinShop<void>(context, _shopFlow, route: PaywallRoute.app);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_maxed) return const SizedBox.shrink();
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
              widget.labelBuilder?.call(widget.cost, widget.grant) ??
                  AppLocalizations.of(
                    context,
                  )!.unlockGrantForCoins(widget.grant, widget.cost),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }
}
