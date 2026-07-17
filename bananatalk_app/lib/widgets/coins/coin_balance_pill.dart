import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Coin balance pill ("💎 247") — the entry-point CTA for the coin shop,
/// placed alongside [VipUpPill] in the same high-traffic app bars (chat
/// list, community, AI study). Hidden entirely when the server-side
/// `coinsEnabled` kill switch is off, mirroring how Reels hides behind
/// `reelsEnabled`. See `docs/superpowers/specs/2026-07-13-coins-v1-design.md`.
class CoinBalancePill extends ConsumerWidget {
  const CoinBalancePill({super.key, this.onTap, this.onLight = true});

  /// Override tap behavior. When null the pill pushes [CoinShopScreen].
  final VoidCallback? onTap;

  /// True when placed on a light surface (most app bars). On a dark/colored
  /// surface (e.g. the AI Study purple gradient header) the pill gets a
  /// thin white border so it doesn't blend into the background — mirrors
  /// [VipUpPill]'s `onLight` treatment.
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsEnabled = ref.watch(appConfigProvider).maybeWhen(
          data: (config) => config?.coinsEnabled ?? false,
          orElse: () => false,
        );
    if (!coinsEnabled) return const SizedBox.shrink();

    final balanceAsync = ref.watch(coinBalanceProvider);
    final balanceText = balanceAsync.when(
      data: (balance) => '$balance',
      loading: () => '···',
      error: (_, __) => '—',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () => Navigator.push(
                    context,
                    AppPageRoute(builder: (_) => const CoinShopScreen()),
                  ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                // Deeper blue so the white balance number keeps strong
                // contrast (the lighter blue washed the digits out).
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: onLight
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💎', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  balanceText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
