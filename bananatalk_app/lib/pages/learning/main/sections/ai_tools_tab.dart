import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/pages/ai/conversation/ai_conversation_screen.dart';
import 'package:bananatalk_app/pages/ai/grammar/grammar_feedback_screen.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/ai/translation/translation_screen.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/ai/lesson_builder/lesson_builder_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_home_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_chat_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/persona_picker_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/scenario_picker_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/story_setup_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/image_vocab_screen.dart';
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
            // AI Tutor hero (replaces the old AI Chat banner)
            _AITutorHero(),
            const SizedBox(height: 12),

            // 4 tutor-mode chips — direct entry to the Step 9 features
            const _TutorModeChips(),
            const SizedBox(height: 24),

            // More AI tools — grid of legacy AI tools (now demoted under the tutor)
            _buildSectionHeader(context, 'More AI tools'),
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

  Widget _buildFeaturesGrid(BuildContext context, bool isVip, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final features = [
      _AIFeature(Icons.chat_bubble_outline_rounded, 'AI Conversation', 'Practice with an AI partner',
          const Color(0xFF6366F1), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const AIConversationScreen()))),
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

const _personaAvatars = {'nana': '🐻', 'sensei': '🤖', 'riko': '🐙'};
const _personaNames = {'nana': 'Nana', 'sensei': 'Sensei', 'riko': 'Riko'};

/// New AI Tutor hero — replaces the legacy AI Chat banner. Persona-aware:
/// shows the user's chosen character if set, or "Meet your AI Tutor" if not.
class _AITutorHero extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memAsync = ref.watch(tutorMemoryProvider);
    final isDark = context.isDarkMode;

    return memAsync.when(
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox.shrink(),
      data: (memory) {
        final hasPersona = memory.persona != null;
        final avatar = hasPersona ? (_personaAvatars[memory.persona] ?? '🐻') : '🐻';
        final name = hasPersona ? (_personaNames[memory.persona] ?? 'Nana') : null;
        final lastSummary = memory.recentChatSummaries.isNotEmpty
            ? memory.recentChatSummaries.first.summary
            : null;

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => hasPersona ? const TutorHomeScreen() : const PersonaPickerScreen(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00897B), Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFA5).withValues(alpha: isDark ? 0.25 : 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(avatar, style: const TextStyle(fontSize: 38)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPersona ? 'Your AI Tutor · $name' : 'Meet your AI Tutor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasPersona
                            ? (lastSummary != null
                                ? 'Last time: $lastSummary'
                                : 'Tap to chat or see today\'s plan')
                            : 'Pick a persona — Nana, Sensei, or Riko',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 26),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Four tutor-mode chips: Chat / Roleplay / Story / Photo.
/// Each routes directly to its destination — but bounces through the
/// persona picker first if the user hasn't picked a persona yet.
class _TutorModeChips extends ConsumerWidget {
  const _TutorModeChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            emoji: '💬',
            label: 'Chat',
            onTap: () => _open(context, ref, const TutorChatScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeChip(
            emoji: '🎭',
            label: 'Roleplay',
            onTap: () => _open(context, ref, const ScenarioPickerScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeChip(
            emoji: '📖',
            label: 'Story',
            onTap: () => _open(context, ref, const StorySetupScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeChip(
            emoji: '📷',
            label: 'Photo',
            onTap: () => _open(context, ref, const ImageVocabScreen()),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, WidgetRef ref, Widget destination) {
    final mem = ref.read(tutorMemoryProvider).valueOrNull;
    if (mem?.persona == null) {
      // First-time user — picker preserves the intended destination so
      // they land on the feature they picked, not on TutorHomeScreen.
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => PersonaPickerScreen(destinationAfterPick: destination),
        ),
      );
      return;
    }
    Navigator.push(context, AppPageRoute(builder: (_) => destination));
  }
}

class _ModeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _ModeChip({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Material(
      color: isDark ? context.cardBackground : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00BFA5).withValues(alpha: isDark ? 0.25 : 0.18),
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
