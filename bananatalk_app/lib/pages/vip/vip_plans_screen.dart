import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_payment_screen.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/services/android_purchase_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class VipPlansScreen extends ConsumerStatefulWidget {
  final String? userId;

  const VipPlansScreen({Key? key, this.userId}) : super(key: key);

  @override
  ConsumerState<VipPlansScreen> createState() => _VipPlansScreenState();
}

class _VipPlansScreenState extends ConsumerState<VipPlansScreen> {
  VipPlan? selectedPlan;
  bool _isIOS = Platform.isIOS;
  bool _isAndroid = Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    // Initialize store based on platform (initializeStore already loads products)
    if (_isIOS) {
      IOSPurchaseService.initializeStore();
    } else if (_isAndroid) {
      AndroidPurchaseService.initializeStore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while products are loading on iOS or Android
    if (_isIOS || _isAndroid) {
      final productsAsync = _isIOS
          ? ref.watch(iosProductsProvider)
          : ref.watch(androidProductsProvider);
      return productsAsync.when(
        data: (products) => _buildContent(),
        loading: () => Scaffold(
          backgroundColor: context.scaffoldBackground,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.upgradeToVIP, style: context.titleLarge),
            backgroundColor: context.surfaceColor,
            elevation: 0,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: context.scaffoldBackground,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.upgradeToVIP, style: context.titleLarge),
            backgroundColor: context.surfaceColor,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: AppSpacing.paddingLG,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    '${AppLocalizations.of(context)!.errorLoadingProducts}: $error',
                    style: context.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () {
                      if (_isIOS) {
                        ref.invalidate(iosProductsProvider);
                      } else {
                        ref.invalidate(androidProductsProvider);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    // Default to the best-value plan so the screen never lands on "nothing
    // selected". User can override; we just want the CTA enabled on entry.
    selectedPlan ??= VipPlan.yearly;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        // Title intentionally omitted — the branded header below carries it.
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandedHeader(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.vipSelectPlan,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildPlanGrid(),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.vipBenefits,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildComparisonTable(),
              const SizedBox(height: 24),
              _buildContinueButton(),
              const SizedBox(height: 16),
              _buildSubscriptionDisclosure(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Branded header ──────────────────────────────────────────────────────
  Widget _buildBrandedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient wordmark.
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                  ).createShader(bounds),
                  child: Text(
                    AppLocalizations.of(context)!.vipBrandTitle,
                    style: context.displayMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.vipTagline,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Mascot-style flourish: stacked gold stars + premium badge so the
          // header has visual weight on the right without requiring an asset.
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade300,
                  size: 22,
                ),
              ),
              Positioned(
                bottom: -2,
                left: -4,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade200,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3-column plan grid ──────────────────────────────────────────────────
  Widget _buildPlanGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildPlanColumn(VipPlan.monthly)),
            const SizedBox(width: 8),
            Expanded(child: _buildPlanColumn(VipPlan.quarterly)),
            const SizedBox(width: 8),
            Expanded(child: _buildPlanColumn(VipPlan.yearly)),
          ],
        ),
      ),
    );
  }

  /// Per-month equivalent. Returns a raw '$X.XX' string used inside the
  /// localized "{price} / mo" template via [AppLocalizations.vipPerMonth].
  String _formatPerMonth(double total, int months) {
    final perMonth = total / months;
    return '\$${perMonth.toStringAsFixed(2)}';
  }

  /// Computed savings vs monthly. Returns null when below threshold.
  int? _savingsPercent(VipPlan plan) {
    if (plan == VipPlan.monthly) return null;
    final months = plan == VipPlan.quarterly ? 3 : 12;
    final perMonth = plan.price / months;
    final pct = (1 - perMonth / VipPlan.monthly.price) * 100;
    if (pct < 5) return null;
    return pct.round();
  }

  String _planTitle(BuildContext context, VipPlan plan) {
    final l10n = AppLocalizations.of(context)!;
    switch (plan) {
      case VipPlan.monthly:
        return l10n.vipPlanMonth;
      case VipPlan.quarterly:
        return l10n.vipPlanThreeMonths;
      case VipPlan.yearly:
        return l10n.vipPlanTwelveMonths;
    }
  }

  Widget _buildPlanColumn(VipPlan plan) {
    final isSelected = selectedPlan == plan;
    final isYearly = plan == VipPlan.yearly;

    // Use store price when available, otherwise fall back to the plan const.
    String productId;
    if (_isIOS) {
      productId = switch (plan) {
        VipPlan.monthly => 'com.bananatalk.bananatalkApp.vip.month',
        VipPlan.quarterly => 'com.bananatalk.bananatalkApp.vip.quarter',
        VipPlan.yearly => 'com.bananatalk.bananatalkApp.vip.year',
      };
    } else {
      productId = switch (plan) {
        VipPlan.monthly => 'com.bananatalk.app.vip.monthly',
        VipPlan.quarterly => 'com.bananatalk.app.vip.quarterly',
        VipPlan.yearly => 'com.bananatalk.app.vip.yearly',
      };
    }

    ProductDetails? product;
    if (_isIOS) {
      ref.watch(iosProductsProvider).whenData((products) {
        try {
          product = products.firstWhere((p) => p.id == productId);
        } catch (_) {}
      });
    } else if (_isAndroid) {
      ref.watch(androidProductsProvider).whenData((products) {
        try {
          product = products.firstWhere((p) => p.id == productId);
        } catch (_) {}
      });
    }
    final priceText = product?.price ?? '\$${plan.price.toStringAsFixed(2)}';
    final months = plan == VipPlan.monthly
        ? 1
        : plan == VipPlan.quarterly
            ? 3
            : 12;
    final perMonthText = _formatPerMonth(plan.price, months);
    final savingsPct = _savingsPercent(plan);
    final l10n = AppLocalizations.of(context)!;

    final accent = isYearly
        ? const Color(0xFFFFA000) // gold for best-value
        : context.primaryColor;

    return GestureDetector(
      onTap: () => setState(() => selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                if (isYearly) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.vipBestValue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (plan == VipPlan.quarterly) ...[
                  Text(
                    AppLocalizations.of(context)!.mostPopular.toUpperCase(),
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else
                  const SizedBox(height: 22),
                Text(
                  _planTitle(context, plan),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  priceText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                if (savingsPct != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.vipSavePercent(savingsPct),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                isYearly ? l10n.vipOneTime : l10n.vipPerMonth(perMonthText),
                style: TextStyle(
                  fontSize: 11,
                  color: context.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Benefit comparison table ────────────────────────────────────────────
  // Rows here mirror what's actually gated in the codebase — see the
  // VIP feature audit. Don't add a row unless the corresponding gate
  // is enforced; misleading claims are a worse problem than thin lists.
  Widget _buildComparisonTable() {
    final l10n = AppLocalizations.of(context)!;
    final rows = <_BenefitRow>[
      _BenefitRow(
        label: l10n.vipBenefitDailyTranslations,
        nonVip: _BenefitValue.text(l10n.vipBenefitTranslationsLimit),
        vip: _BenefitValue.text(l10n.vipBenefitUnlimited),
      ),
      _BenefitRow(
        label: l10n.vipBenefitAdvancedFilters,
        nonVip: const _BenefitValue.locked(),
        vip: const _BenefitValue.check(),
      ),
      _BenefitRow(
        label: l10n.vipBenefitAdFree,
        nonVip: const _BenefitValue.locked(),
        vip: const _BenefitValue.check(),
      ),
      _BenefitRow(
        label: l10n.vipBenefitVipBadge,
        nonVip: const _BenefitValue.dash(),
        vip: const _BenefitValue.check(),
      ),
      _BenefitRow(
        label: l10n.vipBenefitPrioritySupport,
        nonVip: const _BenefitValue.dash(),
        vip: const _BenefitValue.check(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerColor),
        ),
        child: Column(
          children: [
            _buildComparisonHeader(),
            ...rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              return _buildComparisonRow(entry.value, isLast: isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA000).withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: SizedBox.shrink()),
          Expanded(
            flex: 2,
            child: Text(
              AppLocalizations.of(context)!.vipNonVip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
              ).createShader(bounds),
              child: Text(
                AppLocalizations.of(context)!.vip,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(_BenefitRow row, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.dividerColor.withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: context.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _renderBenefitValue(row.nonVip, isVip: false)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _renderBenefitValue(row.vip, isVip: true)),
          ),
        ],
      ),
    );
  }

  Widget _renderBenefitValue(_BenefitValue value, {required bool isVip}) {
    switch (value.kind) {
      case _BenefitKind.text:
        return Text(
          value.text!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isVip ? FontWeight.w700 : FontWeight.w500,
            color: isVip ? const Color(0xFFFFA000) : context.textSecondary,
          ),
        );
      case _BenefitKind.check:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFFFA000),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        );
      case _BenefitKind.locked:
        return Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: context.textMuted,
        );
      case _BenefitKind.dash:
        return Text(
          '—',
          style: TextStyle(
            fontSize: 14,
            color: context.textMuted,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  // ── Continue button (gradient) ──────────────────────────────────────────
  Widget _buildContinueButton() {
    final disabled = selectedPlan == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                final userId = widget.userId ??
                    ref.read(userProvider).valueOrNull?.id ??
                    '';
                if (userId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.vipLoginRequired,
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VipPaymentScreen(
                      userId: userId,
                      plan: selectedPlan!,
                    ),
                  ),
                );
              },
        child: Opacity(
          opacity: disabled ? 0.55 : 1.0,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              AppLocalizations.of(context)!.continueButton.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Subscription disclosure / legal links ───────────────────────────────
  Widget _buildSubscriptionDisclosure() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.vipDisclosure,
            textAlign: TextAlign.center,
            style: context.captionSmall.copyWith(
              color: context.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => _launchURL('https://banatalk.com/terms-of-use'),
                child: Text(
                  AppLocalizations.of(context)!.termsOfUse,
                  style: TextStyle(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('·', style: TextStyle(color: context.textMuted)),
              TextButton(
                onPressed: () =>
                    _launchURL('https://banatalk.com/privacy-policy'),
                child: Text(
                  AppLocalizations.of(context)!.privacyPolicy,
                  style: TextStyle(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// A row in the VIP comparison table.
class _BenefitRow {
  final String label;
  final _BenefitValue nonVip;
  final _BenefitValue vip;

  const _BenefitRow({
    required this.label,
    required this.nonVip,
    required this.vip,
  });
}

/// Cell content for a benefit row — either a text value, a check, a lock,
/// or a dash. Kept as a small tagged union so the table is data-driven.
class _BenefitValue {
  final _BenefitKind kind;
  final String? text;

  const _BenefitValue._(this.kind, [this.text]);
  const _BenefitValue.text(String t) : this._(_BenefitKind.text, t);
  const _BenefitValue.check() : this._(_BenefitKind.check);
  const _BenefitValue.locked() : this._(_BenefitKind.locked);
  const _BenefitValue.dash() : this._(_BenefitKind.dash);
}

enum _BenefitKind { text, check, locked, dash }
