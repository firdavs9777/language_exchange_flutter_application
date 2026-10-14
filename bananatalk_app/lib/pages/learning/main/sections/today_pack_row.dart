import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';

/// The hub's one-row "today" entry. State precedence: pick a language, then
/// placement, then done-for-today, then the normal topic + Start.
class TodayPackRow extends StatelessWidget {
  final DailyPack pack;
  final VoidCallback onOpen;
  final VoidCallback onPickLanguage;
  final VoidCallback onTakePlacement;

  const TodayPackRow({
    super.key,
    required this.pack,
    required this.onOpen,
    required this.onPickLanguage,
    required this.onTakePlacement,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    String? caption;
    String title;
    VoidCallback onTap = onOpen;
    Widget? trailing;
    if (pack.needsLanguage) {
      title = l.todayPickLanguage;
      onTap = onPickLanguage;
    } else if (!pack.levelPlaced) {
      title = l.packTakePlacement;
      onTap = onTakePlacement;
    } else if (pack.packComplete) {
      title = l.packDoneForToday;
      trailing = const Icon(Icons.check_circle_rounded, color: Colors.white);
    } else {
      caption = l.studyTodayPack;
      title = pack.theme?.topic ?? l.studyTodayPack;
      trailing = FilledButton.tonal(onPressed: onOpen, child: Text(l.studyTodayStart));
    }

    final radius = BorderRadius.circular(StudyHubMetrics.cardRadius);
    return Ink(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: StudyHubMetrics.todayRowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (caption != null)
                          Text(caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: Colors.white70)),
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
