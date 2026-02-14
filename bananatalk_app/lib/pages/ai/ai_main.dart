import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/ai/conversation/ai_conversation_screen.dart';
import 'package:bananatalk_app/pages/ai/grammar/grammar_feedback_screen.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/ai/translation/translation_screen.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/ai/lesson_builder/lesson_builder_screen.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Main AI Features Hub Screen
class AIMain extends ConsumerWidget {
  const AIMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakAreasAsync = ref.watch(weakAreasProvider);
    final quizStatsAsync = ref.watch(aiQuizStatsProvider);
    final userAsync = ref.watch(userProvider);
    final isVip = userAsync.valueOrNull?.isVip ?? false;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        title: Text(
          'AI Tutor',
          style: context.titleLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weakAreasProvider);
          ref.invalidate(aiQuizStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
              _buildHeroCard(context, isVip),
              Spacing.gapXXL,

              // AI Features Grid
              _buildSectionHeader(context, 'AI Features'),
              Spacing.gapMD,
              _buildFeaturesGrid(context, isVip),
              Spacing.gapXXL,

              // Quick Stats
              quizStatsAsync.when(
                data: (stats) {
                  if (stats == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Your Progress'),
                      Spacing.gapMD,
                      _buildStatsRow(context, stats),
                      Spacing.gapXXL,
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Weak Areas Section
              weakAreasAsync.when(
                data: (areas) {
                  if (areas.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Focus Areas'),
                      Spacing.gapMD,
                      _buildWeakAreas(context, areas),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isVip) {
    final heroContent = Container(
      padding: Spacing.paddingXL,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderXL,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppRadius.borderLG,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              Spacing.hGapLG,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Conversation Partner',
                          style: context.titleLarge.copyWith(color: Colors.white),
                        ),
                        if (!isVip) ...[
                          Spacing.hGapSM,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: AppRadius.borderXS,
                            ),
                            child: Text(
                              'VIP',
                              style: context.captionSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Spacing.gapXS,
                    Text(
                      'Practice speaking with your AI tutor',
                      style: context.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.gapXL,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIConversationScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: Text(
                'Start Conversation',
                style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    return VipLockedFeature(
      isVip: isVip,
      featureName: 'AI Conversation Partner',
      description: 'Practice speaking with an AI language tutor. Get instant feedback and improve your fluency!',
      borderRadius: AppRadius.borderXL,
      child: heroContent,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: context.titleLarge,
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isVip) {
    final features = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'AI Lessons',
        'subtitle': 'Learn with AI help',
        'color': const Color(0xFF8B5CF6),
        'vipOnly': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LessonsScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.spellcheck_rounded,
        'title': 'Grammar Check',
        'subtitle': 'Analyze your writing',
        'color': const Color(0xFF10B981),
        'vipOnly': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GrammarFeedbackScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.mic_rounded,
        'title': 'Pronunciation',
        'subtitle': 'Improve your speaking',
        'color': const Color(0xFFF59E0B),
        'vipOnly': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PronunciationScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.translate_rounded,
        'title': 'Translation',
        'subtitle': 'Smart translations',
        'color': const Color(0xFF3B82F6),
        'vipOnly': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TranslationScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.quiz_rounded,
        'title': 'AI Quizzes',
        'subtitle': 'Test your knowledge',
        'color': const Color(0xFFEF4444),
        'vipOnly': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AIQuizScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'Lesson Builder',
        'subtitle': 'Generate custom lessons',
        'color': const Color(0xFFEC4899),
        'vipOnly': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LessonBuilderScreen(),
            ),
          );
        },
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: features.map((f) => _buildFeatureCard(
        context,
        icon: f['icon'] as IconData,
        title: f['title'] as String,
        subtitle: f['subtitle'] as String,
        color: f['color'] as Color,
        onTap: f['onTap'] as VoidCallback,
        isVip: isVip,
        vipOnly: f['vipOnly'] as bool,
      )).toList(),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isVip,
    required bool vipOnly,
  }) {
    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLG,
      child: Container(
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                if (vipOnly && !isVip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: AppRadius.borderXS,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, size: 10, color: Colors.white),
                        Spacing.hGapXXS,
                        Text(
                          'VIP',
                          style: context.captionSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: context.titleSmall,
            ),
            Spacing.gapXXS,
            Text(
              subtitle,
              style: context.caption,
            ),
          ],
        ),
      ),
    );

    // Apply VIP lock only for VIP-only features when user is not VIP
    if (vipOnly && !isVip) {
      return VipLockedFeature(
        isVip: isVip,
        featureName: title,
        description: 'Upgrade to VIP to unlock $title and boost your language learning!',
        borderRadius: AppRadius.borderLG,
        showLabel: false,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildStatsRow(BuildContext context, stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            '${stats.completedQuizzes}',
            'Quizzes Done',
            const Color(0xFF6366F1),
          ),
        ),
        Spacing.hGapMD,
        Expanded(
          child: _buildStatItem(
            context,
            '${stats.averageScore.toStringAsFixed(0)}%',
            'Avg Score',
            const Color(0xFF10B981),
          ),
        ),
        Spacing.hGapMD,
        Expanded(
          child: _buildStatItem(
            context,
            '${stats.currentStreak}',
            'Day Streak',
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderMD,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: context.displaySmall.copyWith(color: color),
          ),
          Spacing.gapXS,
          Text(
            label,
            style: context.captionSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakAreas(BuildContext context, List areas) {
    return Column(
      children: areas.take(3).map((area) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: Spacing.paddingLG,
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: AppRadius.borderMD,
            boxShadow: AppShadows.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
              ),
              Spacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: context.labelLarge,
                    ),
                    Text(
                      '${(area.accuracy * 100).toStringAsFixed(0)}% accuracy',
                      style: context.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIQuizScreen(),
                    ),
                  );
                },
                child: const Text('Practice'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
