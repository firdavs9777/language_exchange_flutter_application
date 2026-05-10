import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/pages/ai/conversation/ai_conversation_screen.dart';
import 'package:bananatalk_app/pages/ai/grammar/grammar_feedback_screen.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/ai/translation/translation_screen.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/ai/lesson_builder/lesson_builder_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// The "AI Tools" tab inside the Study Hub.
class AIToolsTab extends ConsumerWidget {
  const AIToolsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakAreasAsync = ref.watch(weakAreasProvider);
    final quizStatsAsync = ref.watch(aiQuizStatsProvider);
    final userAsync = ref.watch(userProvider);
    final isVip = userAsync.valueOrNull?.isVip ?? false;
    final isDark = context.isDarkMode;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weakAreasProvider);
        ref.invalidate(aiQuizStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Chat Hero Card
            _buildAIChatHero(context, isVip, isDark),
            const SizedBox(height: 24),

            // AI Features Grid
            _buildSectionHeader(context, AppLocalizations.of(context)!.aiFeatures),
            const SizedBox(height: 12),
            _buildFeaturesGrid(context, isVip, isDark),
            const SizedBox(height: 24),

            // Quick Stats
            quizStatsAsync.when(
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, AppLocalizations.of(context)!.yourAIProgress),
                    const SizedBox(height: 12),
                    _buildStatsRow(context, stats, isDark),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Weak Areas
            weakAreasAsync.when(
              data: (areas) {
                if (areas.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, AppLocalizations.of(context)!.focusAreas),
                    const SizedBox(height: 12),
                    _buildWeakAreas(context, areas, isDark),
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAIChatHero(BuildContext context, bool isVip, bool isDark) {
    final heroContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 20,
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.aiConversationPartner,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.practiceWithAITutor,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                AppPageRoute(builder: (_) => const AIConversationScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.startConversation,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );

    return VipLockedFeature(
      isVip: isVip,
      featureName: AppLocalizations.of(context)!.aiConversationPartner,
      description: 'Practice speaking with an AI language tutor. Get instant feedback and improve your fluency!',
      borderRadius: BorderRadius.circular(22),
      child: heroContent,
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isVip, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final features = [
      _AIFeature(Icons.menu_book_rounded, l10n.aiLessons, l10n.learnWithAI, const Color(0xFF8B5CF6), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const LessonsScreen()))),
      _AIFeature(Icons.spellcheck_rounded, l10n.grammar, l10n.checkWriting, const Color(0xFF10B981), false,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const GrammarFeedbackScreen()))),
      _AIFeature(Icons.mic_rounded, l10n.pronunciation, l10n.improveSpeaking, const Color(0xFFF59E0B), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const PronunciationScreen()))),
      _AIFeature(Icons.translate_rounded, l10n.translation, l10n.smartTranslate, const Color(0xFF3B82F6), false,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const TranslationScreen()))),
      _AIFeature(Icons.quiz_rounded, l10n.aiQuizzes, l10n.testKnowledge, const Color(0xFFEF4444), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const AIQuizScreen()))),
      _AIFeature(Icons.auto_awesome_rounded, l10n.lessonBuilder, l10n.customLessons, const Color(0xFFEC4899), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const LessonBuilderScreen()))),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: features.map((f) {
        final card = GestureDetector(
          onTap: f.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? context.cardBackground : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: f.color.withValues(alpha: isDark ? 0.1 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: f.color.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: f.color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(f.icon, color: f.color, size: 24),
                    ),
                    if (f.vipOnly && !isVip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text('VIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  f.title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  f.subtitle,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
        );

        if (f.vipOnly && !isVip) {
          return VipLockedFeature(
            isVip: isVip,
            featureName: f.title,
            description: 'Upgrade to VIP to unlock ${f.title}!',
            borderRadius: BorderRadius.circular(18),
            showLabel: false,
            child: card,
          );
        }
        return card;
      }).toList(),
    );
  }

  Widget _buildStatsRow(BuildContext context, stats, bool isDark) {
    return Row(
      children: [
        Expanded(child: _MiniStatCard('${stats.completedQuizzes}', AppLocalizations.of(context)!.quizzes, const Color(0xFF6366F1), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard('${stats.averageScore.toStringAsFixed(0)}%', AppLocalizations.of(context)!.avgScore, const Color(0xFF10B981), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard('${stats.currentStreak}', AppLocalizations.of(context)!.streak, const Color(0xFFF59E0B), isDark)),
      ],
    );
  }

  Widget _buildWeakAreas(BuildContext context, List areas, bool isDark) {
    return Column(
      children: areas.take(3).map((area) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? context.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary),
                    ),
                    Text(
                      AppLocalizations.of(context)!.accuracyPercent((area.accuracy * 100).toStringAsFixed(0)),
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const AIQuizScreen()),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: Text(AppLocalizations.of(context)!.practice),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ========== AIToolsTab private helpers ==========

class _AIFeature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool vipOnly;
  final VoidCallback onTap;

  const _AIFeature(this.icon, this.title, this.subtitle, this.color, this.vipOnly, this.onTap);
}

class _MiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _MiniStatCard(this.value, this.label, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? context.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.15 : 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
