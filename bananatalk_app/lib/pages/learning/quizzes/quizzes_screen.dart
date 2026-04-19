import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/quiz_model.dart';
import 'package:bananatalk_app/pages/learning/quizzes/quiz_player_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Quizzes screen
class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        title: Text(
          'Quizzes',
          style: context.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: quizzesAsync.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return _buildEmptyState();
          }

          // Group quizzes by type
          final placementQuizzes =
              quizzes.where((q) => q.type == 'placement').toList();
          final assessmentQuizzes =
              quizzes.where((q) => q.type == 'assessment').toList();
          final practiceQuizzes =
              quizzes.where((q) => q.type == 'practice').toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(quizzesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Placement tests
                if (placementQuizzes.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Placement Tests',
                    'Find your level',
                    Icons.assessment_outlined,
                    const Color(0xFF9C27B0),
                  ),
                  const SizedBox(height: 12),
                  ...placementQuizzes.map((quiz) => _QuizCard(
                        quiz: quiz,
                        onTap: () => _openQuiz(context, ref, quiz.id),
                      )),
                  const SizedBox(height: 24),
                ],
                // Assessment quizzes
                if (assessmentQuizzes.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Assessments',
                    'Test your knowledge',
                    Icons.school_outlined,
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  ...assessmentQuizzes.map((quiz) => _QuizCard(
                        quiz: quiz,
                        onTap: () => _openQuiz(context, ref, quiz.id),
                      )),
                  const SizedBox(height: 24),
                ],
                // Practice quizzes
                if (practiceQuizzes.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Practice',
                    'Sharpen your skills',
                    Icons.fitness_center_outlined,
                    const Color(0xFF00BFA5),
                  ),
                  const SizedBox(height: 12),
                  ...practiceQuizzes.map((quiz) => _QuizCard(
                        quiz: quiz,
                        onTap: () => _openQuiz(context, ref, quiz.id),
                      )),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.textMuted),
              Spacing.gapLG,
              Text('Failed to load quizzes',
                  style: context.bodyMedium.copyWith(color: context.textSecondary)),
              Spacing.gapLG,
              ElevatedButton(
                onPressed: () => ref.invalidate(quizzesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context, WidgetRef ref, String quizId) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => QuizPlayerScreen(quizId: quizId),
      ),
    ).then((_) {
      ref.invalidate(quizzesProvider);
    });
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: Spacing.paddingSM,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Spacing.hGapMD,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.titleLarge),
              Text(subtitle, style: context.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: context.textMuted),
            Spacing.gapLG,
            Text(
              'No quizzes available',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              'Check back later for new quizzes',
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const _QuizCard({
    required this.quiz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(),
                        const SizedBox(width: 8),
                        _buildLevelBadge(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quiz.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.help_outline,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.questionCount} questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.timer_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.timeLimit} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFF00BFA5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${quiz.xpReward} XP',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00BFA5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    Color color;
    String label;

    switch (quiz.type.toLowerCase()) {
      case 'placement':
        color = const Color(0xFF9C27B0);
        label = 'PLACEMENT';
        break;
      case 'assessment':
        color = const Color(0xFF2196F3);
        label = 'ASSESSMENT';
        break;
      case 'practice':
        color = const Color(0xFF00BFA5);
        label = 'PRACTICE';
        break;
      default:
        color = Colors.grey;
        label = quiz.type.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    Color color;
    final level = quiz.level ?? 'beginner';

    switch (level.toLowerCase()) {
      case 'beginner':
        color = const Color(0xFF4CAF50);
        break;
      case 'intermediate':
        color = const Color(0xFFFF9800);
        break;
      case 'advanced':
        color = const Color(0xFFE91E63);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
