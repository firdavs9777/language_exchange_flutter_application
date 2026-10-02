import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

/// A "someone waved / viewed you" row whose identity the server masked
/// (`revealed == false`). Shared by the Waves tab and the Visitors screen.
///
/// There is deliberately no tap-to-open: a masked row has no id. The two
/// actions are the coins unlock (`who_waved`, 24h; hidden by [UnlockCta]
/// itself when coins are off) and "Go VIP".
///
/// Callers render ONE tile for all masked rows ([count]); one unlock reveals
/// everyone, so a tile per row would offer N buttons for the same purchase.
class MaskedPersonTile extends ConsumerWidget {
  const MaskedPersonTile({
    super.key,
    required this.onUnlocked,
    this.trailing,
    this.count = 1,
    this.title,
    this.body,
  });

  /// Called after a successful unlock so the caller can reload its list.
  final VoidCallback onUnlocked;

  /// How many masked people this tile stands for.
  final int count;

  /// Overrides the waves title (e.g. the visitors copy).
  final String? title;

  /// Overrides the waves body; receives the live unlock cost, or null when
  /// coins are off / the catalog has no `who_waved` entry.
  final String Function(int? cost)? body;

  /// Optional line under the body (e.g. relative time).
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cost = ref.watch(coinUnlockCatalogProvider).maybeWhen(
          data: (c) {
            final entry = c['who_waved'];
            return entry != null && entry.cost > 0 ? entry.cost : null;
          },
          orElse: () => null,
        );

    return Container(
      key: const ValueKey('masked-person-tile'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF00BFA5), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? l10n.wavesMaskedTitleCount(count),
                  style: context.titleMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  body?.call(cost) ??
                      (cost != null
                          ? l10n.wavesMaskedBody(cost)
                          : l10n.wavesMaskedBodyVip),
                  style:
                      context.bodyMedium.copyWith(color: context.textSecondary),
                ),
                if (trailing != null) ...[const SizedBox(height: 4), trailing!],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    UnlockCta(
                      featureKey: 'who_waved',
                      onUnlocked: onUnlocked,
                      labelBuilder: (cost, _) => l10n.coinAmount(cost),
                    ),
                    TextButton(
                      key: const ValueKey('masked-go-vip'),
                      onPressed: () => Navigator.push(
                        context,
                        AppPageRoute<void>(
                            builder: (_) => const VipPlansScreen()),
                      ),
                      child: Text(l10n.goVip),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
