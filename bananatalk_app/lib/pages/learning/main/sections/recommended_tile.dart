import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// "For you: <weak area>" quiz shortcut. Hidden while loading, on error, or
/// when no area has enough attempts to recommend.
class RecommendedTile extends ConsumerWidget {
  const RecommendedTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(weakAreasProvider).valueOrNull;
    final area = areas == null ? null : pickRecommended(areas);
    if (area == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final percent = (area.accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: StudyHubMetrics.tileGap),
      child: Material(
        color: const Color(0xFFFEF0D9).withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 1),
        borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
          onTap: () {
            AnalyticsService.instance.studyRecommendedTap(area.name);
            Navigator.push(context, AppPageRoute(builder: (_) => const AIQuizScreen()));
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: StudyHubMetrics.recommendedHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const Icon(Icons.gps_fixed_rounded, color: Color(0xFFA85E00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.studyRecommended(area.name, percent),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
