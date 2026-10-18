import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocab_packs_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Vocabulary packs, given their own card high on the AI Study hub
/// (2026-10-18). They were only a small chip at the bottom of the progress
/// card, so most learners never found them.
class VocabPacksCard extends StatelessWidget {
  const VocabPacksCard({super.key});

  static const _gradient = [Color(0xFF0EA5E9), Color(0xFF14B8A6)];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    void open() => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const VocabPacksScreen()),
        );

    return Material(
      key: const Key('study-hub-vocab-packs'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
        onTap: open,
        child: Ink(
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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('📚', style: text.headlineSmall),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.vocabularyPacks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(l.vocabPacksPromo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(l.vocabPacksBrowse,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                              color: const Color(0xFF0E7490), fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
