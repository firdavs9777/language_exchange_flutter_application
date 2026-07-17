import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/coin_pack.dart';
import 'package:bananatalk_app/pages/coins/coin_history_screen.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/android_purchase_service.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';

/// Coin shop — 3 fixed consumable coin packs, purchased via IAP. Mirrors
/// `VipPlansScreen`'s branded-header + gradient-CTA visual style so the
/// two monetization surfaces feel like one family.
///
/// Purchase flow (Task 7 contract — see `IOSPurchaseService.
/// purchaseCoinPack` / `AndroidPurchaseService.purchaseCoinPack`):
///   1. `buyConsumable(autoConsume: false)` — store charges the user.
///   2. `CoinApiClient.verifyPurchase` — backend verifies the receipt and
///      credits coins, keyed on the platform's idempotency id.
///   3. ONLY on a successful verify: `completeCoinPurchase` finishes
///      (iOS) / consumes (Android) the store transaction so the pack is
///      repurchasable. A failed verify leaves the purchase un-consumed so
///      the store can retry or refund it.
class CoinShopScreen extends ConsumerStatefulWidget {
  const CoinShopScreen({super.key});

  @override
  ConsumerState<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends ConsumerState<CoinShopScreen> {
  final bool _isIOS = Platform.isIOS;
  final bool _isAndroid = Platform.isAndroid;

  /// Pack id currently mid-purchase, or null when idle. Guards against
  /// double-taps launching two store sheets at once.
  String? _purchasingPackId;

  // Coins v2 (Task 17) — "Earn free coins" section state.
  bool _dailyClaiming = false;
  // Overrides the initial GET status once the user claims in this session,
  // so the card flips to "Claimed today" without an extra status re-fetch.
  bool? _dailyClaimedOverride;
  bool _adClaiming = false;
  // Set once a claim gets a 429 — no status endpoint exists for the ad cap
  // (unlike the daily reward), so this is session-local rather than
  // loaded up front.
  bool _adCapReached = false;

  @override
  void initState() {
    super.initState();
    if (_isIOS) {
      IOSPurchaseService.initializeStore();
    } else if (_isAndroid) {
      AndroidPurchaseService.initializeStore();
    }
  }

  CoinApiClient get _coinApi => ref.read(coinApiClientProvider);

  Future<void> _purchase(CoinPack pack) async {
    if (_purchasingPackId != null) return;
    if (!_isIOS && !_isAndroid) {
      _showSnack('Coin purchases are only available on iOS and Android.');
      return;
    }

    setState(() => _purchasingPackId = pack.id);

    try {
      final productId = pack.productId(_isIOS);
      final purchase = _isIOS
          ? await IOSPurchaseService.purchaseCoinPack(productId)
          : await AndroidPurchaseService.purchaseCoinPack(productId);

      if (purchase == null) {
        if (mounted) {
          _showSnack('Purchase was canceled or could not be started.');
        }
        return;
      }

      final String platform = _isIOS ? 'ios' : 'android';
      final String receipt;
      final String transactionId;
      if (_isIOS) {
        receipt = IOSPurchaseService.getReceiptFromPurchase(purchase) ?? '';
        // Pinned idempotency id (reviewer C3): StoreKit `transactionId` of
        // THIS consumable purchase, not `originalTransactionId`.
        transactionId = purchase.purchaseID ?? '';
      } else {
        // Android: both the receipt payload and the idempotency id are the
        // Play Billing `purchaseToken` — the backend needs it to call the
        // Play Developer API AND to dedupe retries of this same purchase.
        final token = AndroidPurchaseService.getPurchaseToken(purchase) ?? '';
        receipt = token;
        transactionId = token;
      }

      if (receipt.isEmpty || transactionId.isEmpty) {
        if (mounted) {
          _showSnack('Could not read purchase receipt. Please try again.');
        }
        return;
      }

      final response = await _coinApi.verifyPurchase(
        platform: platform,
        productId: productId,
        receipt: receipt,
        transactionId: transactionId,
      );

      if (response.success) {
        // Only now is it safe to finish/consume — the backend confirmed
        // the receipt and credited coins, so the store transaction is
        // done and the pack becomes repurchasable.
        if (_isIOS) {
          await IOSPurchaseService.completeCoinPurchase(purchase);
        } else {
          await AndroidPurchaseService.completeCoinPurchase(purchase);
        }
        refreshCoinBalance(ref);
        if (mounted) {
          _showSnack('Coins added! 💎');
        }
      } else {
        // Verify failed after the store charged the user — leave the
        // purchase un-consumed so it can be retried (e.g. via
        // restorePurchases) or refunded. Never grant coins here.
        if (mounted) {
          _showSnack(
            response.error ??
                'Purchase could not be verified. It will be retried automatically — try restoring purchases if coins don\'t appear.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _purchasingPackId = null);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _claimDailyReward() async {
    if (_dailyClaiming || (_dailyClaimedOverride ?? false)) return;
    setState(() => _dailyClaiming = true);
    try {
      final response = await _coinApi.claimDailyReward();
      if (!mounted) return;
      if (response.success) {
        final data = response.data;
        final alreadyClaimed =
            data is Map && data['alreadyClaimed'] == true;
        setState(() => _dailyClaimedOverride = true);
        refreshCoinBalance(ref);
        // Reviewer finding: without this, `dailyRewardStatusProvider` (not
        // autoDispose) keeps serving its pre-claim cached `false` for the
        // rest of the session, so reopening the shop after a remount reads
        // stale status. `_dailyClaimedOverride` covers this screen instance;
        // invalidating keeps every other reader (and this one, post-remount)
        // correct too.
        refreshDailyRewardStatus(ref);
        _showSnack(
          alreadyClaimed
              ? 'Already claimed today — come back tomorrow!'
              : 'Daily reward claimed! +10 💎',
        );
      } else {
        _showSnack(response.error ?? 'Could not claim the daily reward.');
      }
    } finally {
      if (mounted) setState(() => _dailyClaiming = false);
    }
  }

  /// Called from [RewardedAdButton]'s reward callback once the ad SDK
  /// fires `onUserEarnedReward` — that callback is synchronous
  /// (`VoidCallback`), so this kicks off the async credit call and returns.
  void _handleAdRewarded() {
    _claimAdReward();
  }

  Future<void> _claimAdReward() async {
    if (_adClaiming || _adCapReached) return;
    setState(() => _adClaiming = true);
    try {
      final response = await _coinApi.claimAdReward();
      if (!mounted) return;
      if (response.success) {
        refreshCoinBalance(ref);
        _showSnack('Thanks for watching! +5 💎');
      } else if (response.statusCode == 429) {
        setState(() => _adCapReached = true);
        // Explicit friendly literal, not `response.error` — the backend's
        // 'daily ad reward limit reached' message doesn't match any of
        // `_getReadableRateLimitError`'s substrings, so `response.error`
        // would otherwise be the generic "Too many requests. Please wait a
        // moment" fallback. `claimAdReward` also sets
        // `suppressRateLimitToast: true`, so this is the ONLY snackbar shown
        // for the ad cap (no duplicate global rate-limit toast).
        _showSnack("You've reached today's ad reward limit — come back tomorrow!");
      } else {
        _showSnack(response.error ?? 'Could not credit the ad reward.');
      }
    } finally {
      if (mounted) setState(() => _adClaiming = false);
    }
  }

  ProductDetails? _storeProduct(WidgetRef ref, String productId) {
    final productsAsync = _isIOS
        ? ref.watch(iosProductsProvider)
        : _isAndroid
            ? ref.watch(androidProductsProvider)
            : const AsyncValue<List<ProductDetails>>.data(<ProductDetails>[]);
    return productsAsync.maybeWhen(
      data: (products) {
        for (final p in products) {
          if (p.id == productId) return p;
        }
        return null;
      },
      orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: const Text('Coin Shop'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBalanceRow(),
              const SizedBox(height: 20),
              _buildEarnSection(),
              const SizedBox(height: 8),
              ...CoinPack.all.map(
                (pack) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildPackCard(pack),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coins are used to unlock extra uses of translations, AI tutor '
                'chats, and moments once you hit your free daily limit. '
                'Purchases are non-refundable once coins are spent.',
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('💎', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Coins',
                style: context.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock extra translations, tutor chats & moments instantly.',
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceRow() {
    final balanceAsync = ref.watch(coinBalanceProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const CoinHistoryScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              Text('Your balance', style: context.bodyMedium.copyWith(color: context.textSecondary)),
              const Spacer(),
              balanceAsync.when(
                data: (balance) => Text(
                  '💎 $balance',
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Text('—', style: context.bodyMedium),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: context.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// "Earn free coins" — daily reward + watch-ad cards, above the packs so
  /// the free earn loop is discovered before the paid one.
  Widget _buildEarnSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earn free coins',
          style: context.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _buildDailyRewardCard(),
        const SizedBox(height: 10),
        _buildWatchAdCard(),
      ],
    );
  }

  Widget _buildDailyRewardCard() {
    const accent = AppColors.primary; // Teal
    final statusAsync = ref.watch(dailyRewardStatusProvider);
    final claimedFromServer = statusAsync.maybeWhen(
      data: (claimed) => claimed,
      orElse: () => false,
    );
    final isClaimed = _dailyClaimedOverride ?? claimedFromServer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily reward',
                  style: context.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isClaimed ? 'Come back tomorrow' : '+10 coins, once a day',
                  style: context.captionSmall.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: (isClaimed || _dailyClaiming) ? null : _claimDailyReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: context.dividerColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
              ),
              child: _dailyClaiming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isClaimed ? 'Claimed' : 'Claim',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdCard() {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🎬', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch an ad',
                      style: context.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _adCapReached
                          ? 'Daily limit reached — come back tomorrow'
                          : '+5 coins per ad, up to 5 a day',
                      style: context.captionSmall.copyWith(color: context.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_adCapReached)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Limit reached',
                  style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: RewardedAdButton(
                onRewarded: _handleAdRewarded,
                enabled: !_adClaiming,
                label: _adClaiming ? 'Crediting…' : 'Watch ad (+5 💎)',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackCard(CoinPack pack) {
    const accent = Color(0xFF1E88E5);
    final productId = pack.productId(_isIOS);
    final product = _storeProduct(ref, productId);
    final priceText = product?.price ?? '\$${pack.usdPrice.toStringAsFixed(2)}';
    final isBusy = _purchasingPackId == pack.id;
    final isBestValue = pack.id == 'large';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBestValue ? accent : context.dividerColor,
          width: isBestValue ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          // Coin glyph in a soft-tinted tile.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('💎', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${pack.totalCoins}',
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'coins',
                      style: context.bodyMedium
                          .copyWith(color: context.textSecondary),
                    ),
                    if (isBestValue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BEST VALUE',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (pack.bonusCoins > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${pack.bonusCoins} bonus included',
                    style: context.captionSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price as a clean rounded button with room to breathe.
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: isBusy ? null : () => _purchase(pack),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      priceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
