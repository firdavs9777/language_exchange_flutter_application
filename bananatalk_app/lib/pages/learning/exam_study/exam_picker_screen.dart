import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/exam_card.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocab_packs_screen.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pushed after the user taps a language card. Shows exams available
/// for that language.
class ExamPickerScreen extends ConsumerWidget {
  const ExamPickerScreen({super.key, required this.language});

  final ExamLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final examsAsync = ref.watch(examsForLanguageProvider(language.id));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: const AppBackButton(),
        title: Row(
          children: [
            Text(language.icon ?? '🏳️', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              language.name,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(examsForLanguageProvider(language.id)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              l10n.examPickExam,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.examPickExamSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Vocabulary Packs live under the English section — surfaced here
            // (rather than buried in the AI Tools grid) so English learners
            // find them while choosing an exam. Packs are English content.
            if (language.code.toLowerCase() == 'en') ...[
              _buildVocabPacksCard(context),
              const SizedBox(height: 20),
            ],
            examsAsync.when(
              data: (exams) => _buildExamsList(context, exams, l10n),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _examsError(context, ref, l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// Featured entry into the curated Vocabulary Packs, shown at the top of
  /// the English exam list.
  Widget _buildVocabPacksCard(BuildContext context) {
    const accent = Color(0xFF14B8A6);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VocabPacksScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.style_rounded, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vocabulary Packs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Themed word sets to build your vocabulary',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsList(
    BuildContext context,
    List<ExamType> exams,
    AppLocalizations l10n,
  ) {
    if (exams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            l10n.examPickEmpty,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final exam in exams) ...[
          ExamCard(
            exam: exam,
            onTap: () => context.push('/exam-study/exam/${exam.id}', extra: exam),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _examsError(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
            l10n.examStudyError,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.invalidate(examsForLanguageProvider(language.id)),
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }
}
