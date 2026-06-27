import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/services/exam_essay_quota.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// "Daily essay evaluations: X/5" indicator. When the user is VIP we
/// render nothing; when they're out of quota the banner flips into a
/// gold "Upgrade to VIP" prompt that pushes the plans screen.
///
/// Stateless — the parent owns [used] / [isVip] and re-renders on
/// change so this widget is a pure projection.
class QuotaBanner extends StatelessWidget {
  const QuotaBanner({
    super.key,
    required this.used,
    required this.isVip,
  });

  final int used;
  final bool isVip;

  @override
  Widget build(BuildContext context) {
    if (isVip) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final remaining = ExamEssayQuota.dailyLimit - used;
    final exhausted = remaining <= 0;

    if (exhausted) {
      return _exhaustedBanner(context, l10n);
    }
    return _usageChip(context, l10n);
  }

  Widget _usageChip(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: context.primaryColor),
          const SizedBox(width: 6),
          Text(
            l10n.examEssayQuotaUsed(used, ExamEssayQuota.dailyLimit),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exhaustedBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.examEssayQuotaExhausted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              AppPageRoute(builder: (_) => const VipPlansScreen()),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFFA000),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.examEssayQuotaUpgrade,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
