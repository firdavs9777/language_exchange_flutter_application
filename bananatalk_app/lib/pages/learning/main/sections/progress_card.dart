import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/pages/learning/achievements/achievements_screen.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/srs_dashboard_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocab_packs_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Streak / level / daily-XP summary with shortcuts to the detail screens.
/// [progress] null (not loaded, failed, or a brand-new account) shows "–"
/// placeholders; the shortcuts work either way.
///
/// 2026-10-18: a bright gradient card with three coloured stat tiles
/// (streak, level, today's XP) instead of a grey box, so progress is the
/// thing you notice on the page.
class ProgressCard extends StatelessWidget {
  final LearningProgress? progress;
  final VoidCallback onFullReport;

  const ProgressCard({super.key, required this.progress, required this.onFullReport});

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, AppPageRoute(builder: (_) => screen));

  static const _gradient = [Color(0xFF7C3AED), Color(0xFFDB2777)];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    const none = '–';
    final p = progress;
    final goal = p == null || p.dailyGoal <= 0 ? 1 : p.dailyGoal;
    final frac = p == null ? 0.0 : (p.dailyXP / goal).clamp(0.0, 1.0);

    Widget tile({
      required String emoji,
      required String value,
      required String label,
      required Color color,
      Widget? extra,
    }) =>
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(emoji, style: text.titleSmall),
              ),
              const SizedBox(height: 8),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85))),
              if (extra != null) ...[const SizedBox(height: 6), extra],
            ],
          ),
        );

    Widget shortcut(IconData icon, String label, Color color, VoidCallback onTap, {Key? key}) =>
        Material(
          key: key,
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                            color: const Color(0xFF1F2937), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: _gradient.first.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📈', style: text.titleMedium),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l.studyProgressTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: tile(
                  emoji: '🔥',
                  value: p == null ? none : '${p.currentStreak}',
                  label: l.streak,
                  color: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  emoji: '⭐',
                  value: p == null ? none : l.studyLevelShort(p.level),
                  label: 'XP ${p == null ? none : p.totalXP}',
                  color: const Color(0xFFEAB308),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  emoji: '🎯',
                  value: p == null ? '$none XP' : '${p.dailyXP}/${p.dailyGoal}',
                  label: 'XP',
                  color: const Color(0xFF10B981),
                  extra: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 6,
                      color: const Color(0xFF34D399),
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              shortcut(Icons.insights_rounded, l.studyFullReport, const Color(0xFF7C3AED), onFullReport),
              shortcut(Icons.emoji_events_rounded, l.achievements, const Color(0xFFEAB308),
                  () => _go(context, const AchievementsScreen())),
              shortcut(Icons.menu_book_rounded, l.vocabulary, const Color(0xFF2563EB),
                  () => _go(context, const VocabularyScreen())),
              shortcut(Icons.replay_rounded, l.review, const Color(0xFF10B981),
                  () => _go(context, const SrsDashboardScreen())),
              // Packs follow the learner's target language server-side.
              shortcut(Icons.style_rounded, l.vocabularyPacks, const Color(0xFFDB2777),
                  () => _go(context, const VocabPacksScreen()),
                  key: const Key('progress-vocab-packs')),
            ],
          ),
        ],
      ),
    );
  }
}
