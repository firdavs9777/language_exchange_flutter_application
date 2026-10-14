import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_labels.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

enum StudyUpgradeReason { locked, exhausted }

/// Shown before navigating to a locked or exhausted tile (spec §4.4), so the
/// user meets the offer instead of a 429. Resolves true when a coin unlock
/// succeeded and the caller should open the feature.
Future<bool> showStudyUpgradeSheet(
  BuildContext context, {
  required StudyFeature feature,
  required StudyUpgradeReason reason,
}) async {
  AnalyticsService.instance
      .studyUpgradeSheetShown(feature: feature.slug, reason: reason.name);
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _StudyUpgradeSheet(feature: feature, reason: reason),
  );
  return unlocked ?? false;
}

class _StudyUpgradeSheet extends ConsumerWidget {
  const _StudyUpgradeSheet({required this.feature, required this.reason});

  final StudyFeature feature;
  final StudyUpgradeReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = studyGroupColors(feature.group,
        dark: Theme.of(context).brightness == Brightness.dark);
    final name = studyFeatureTitle(l, feature);
    final title = reason == StudyUpgradeReason.locked
        ? l.studyUpgradeLockedTitle(name)
        : l.studyUpgradeExhaustedTitle(name);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: colors.fill, borderRadius: BorderRadius.circular(12)),
                child: Icon(studyFeatureIcon(feature), color: colors.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(studyFeatureDescription(l, feature), style: text.bodyMedium),
            const SizedBox(height: 12),
            _Benefit(l.studyUpgradeBenefitUnlimited),
            _Benefit(l.studyUpgradeBenefitNoAds),
            const SizedBox(height: 16),
            if (feature.quotaKey != null) ...[
              UnlockCta(
                featureKey: feature.quotaKey!,
                onUnlocked: () {
                  AnalyticsService.instance
                      .studyUpgradeUnlock(feature: feature.slug, method: 'coins');
                  ref.invalidate(tutorMemoryAndQuotasProvider);
                  Navigator.of(context).pop(true);
                },
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: () {
                AnalyticsService.instance
                    .studyUpgradeUnlock(feature: feature.slug, method: 'vip');
                final nav = Navigator.of(context);
                nav.pop(false);
                nav.push(AppPageRoute(builder: (_) => const VipPlansScreen()));
              },
              child: Text(l.studyUpgradeGetVip),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.notNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.check_circle_rounded,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        ]),
      );
}
