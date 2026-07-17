import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/models/coin_pack.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/android_purchase_service.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

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
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildPackCard(CoinPack pack) {
    final productId = pack.productId(_isIOS);
    final product = _storeProduct(ref, productId);
    final priceText = product?.price ?? '\$${pack.usdPrice.toStringAsFixed(2)}';
    final isBusy = _purchasingPackId == pack.id;
    final isBestValue = pack.id == 'large';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestValue ? const Color(0xFF1E88E5) : context.dividerColor,
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBestValue) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  '💎 ${pack.coins}${pack.bonusCoins > 0 ? ' +${pack.bonusCoins}' : ''}',
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pack.totalCoins} coins total',
                  style: context.captionSmall.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: isBusy ? null : () => _purchase(pack),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(priceText, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
