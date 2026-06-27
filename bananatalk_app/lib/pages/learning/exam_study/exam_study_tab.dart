import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/language_card.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root of the Exam Study flow — mounted as the third tab inside
/// LearningMain. Chunk A renders the language picker only; subsequent
/// chunks push exam-picker, dashboard, practice, etc.
class ExamStudyTab extends ConsumerWidget {
  const ExamStudyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languagesAsync = ref.watch(examLanguagesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(examLanguagesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            l10n.examStudyChooseLanguage,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.examStudyChooseLanguageSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          languagesAsync.when(
            data: (languages) {
              if (languages.isEmpty) {
                return _EmptyState(message: l10n.examStudyEmptyLanguages);
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: languages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final language = languages[index];
                  return LanguageCard(
                    language: language,
                    onTap: () => context.push(
                      '/exam-study/language/${language.id}',
                      extra: language,
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _ErrorState(
              message: l10n.examStudyError,
              retryLabel: l10n.examStudyRetry,
              onRetry: () => ref.invalidate(examLanguagesProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: context.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
