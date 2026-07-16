/// Coins v1 — the 3 fixed consumable coin packs sold via IAP.
///
/// Product IDs and prices are pinned per the design spec
/// (`docs/superpowers/specs/2026-07-13-coins-v1-design.md`, "IAP — 3
/// consumable coin packs"). These are NOT server-driven — the store
/// products, prices, and coin grants are fixed at build time, same as the
/// VIP plan tiers in `VipPlan`. The backend's `unlock-catalog` endpoint is
/// the one source of truth that IS read live (unlock costs), because those
/// are tunable without a store review cycle.
class CoinPack {
  final String id;
  final String iosProductId;
  final String androidProductId;

  /// Base coins granted by the pack (excludes [bonusCoins]).
  final int coins;

  /// Extra "bonus" coins bundled with medium/large packs (e.g. Medium is
  /// "500 (+25)"). Zero for the small pack.
  final int bonusCoins;

  /// Display-only USD price. The store's localized price (via
  /// `ProductDetails.price`) should be preferred when available; this is
  /// the fallback shown before products have loaded.
  final double usdPrice;

  const CoinPack({
    required this.id,
    required this.iosProductId,
    required this.androidProductId,
    required this.coins,
    required this.usdPrice,
    this.bonusCoins = 0,
  });

  /// Total coins credited for this pack (base + bonus).
  int get totalCoins => coins + bonusCoins;

  /// Platform-appropriate store product ID.
  String productId(bool isIOS) => isIOS ? iosProductId : androidProductId;

  static const CoinPack small = CoinPack(
    id: 'small',
    iosProductId: 'com.bananatalk.bananatalkApp.coins.100',
    androidProductId: 'com.bananatalk.app.coins.100',
    coins: 100,
    usdPrice: 0.99,
  );

  static const CoinPack medium = CoinPack(
    id: 'medium',
    iosProductId: 'com.bananatalk.bananatalkApp.coins.500',
    androidProductId: 'com.bananatalk.app.coins.500',
    coins: 500,
    bonusCoins: 25,
    usdPrice: 3.99,
  );

  static const CoinPack large = CoinPack(
    id: 'large',
    iosProductId: 'com.bananatalk.bananatalkApp.coins.1500',
    androidProductId: 'com.bananatalk.app.coins.1500',
    coins: 1500,
    bonusCoins: 250,
    usdPrice: 9.99,
  );

  /// All packs, small → large, in display order.
  static const List<CoinPack> all = [small, medium, large];

  /// Find a pack by either its iOS or Android product ID. Used to map a
  /// completed store purchase back to its pack (e.g. for the "Coins
  /// added!" confirmation copy). Returns null for an unrecognized ID.
  static CoinPack? byProductId(String productId) {
    for (final pack in all) {
      if (pack.iosProductId == productId || pack.androidProductId == productId) {
        return pack;
      }
    }
    return null;
  }
}
