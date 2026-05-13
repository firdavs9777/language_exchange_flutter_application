import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/tutor/tutor_memory.dart';
import '../../../models/tutor/tutor_session.dart';
import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'tutor_chat_screen.dart';
import 'persona_picker_screen.dart';
import 'scenario_picker_screen.dart';
import 'story_setup_screen.dart';
import 'image_vocab_screen.dart';

const _personaAvatars = {'nana': '🐻', 'sensei': '🤖', 'riko': '🐙'};
const _personaNames = {'nana': 'Nana', 'sensei': 'Sensei', 'riko': 'Riko'};

class TutorHomeScreen extends ConsumerWidget {
  const TutorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final memoryAsync = ref.watch(tutorMemoryProvider);
    final planAsync = ref.watch(tutorDailyPlanProvider);
    final sessionsAsync = ref.watch(tutorRecentSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiTutorHomeTitle),
        actions: [
          IconButton(
            tooltip: l10n.aiTutorHomeChangeTutor,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PersonaPickerScreen(isFirstRun: false),
              ),
            ),
          ),
        ],
      ),
      body: memoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load tutor: $e')),
        data: (memory) {
          if (memory.persona == null) {
            // First-time user — bounce to picker.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PersonaPickerScreen()),
              );
            });
            return const SizedBox.shrink();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tutorMemoryProvider);
              ref.invalidate(tutorDailyPlanProvider);
              ref.invalidate(tutorRecentSessionsProvider);
              await Future.wait([
                ref.read(tutorMemoryProvider.future),
                ref.read(tutorDailyPlanProvider.future),
                ref.read(tutorRecentSessionsProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroGreeting(memory: memory),
                const SizedBox(height: 16),
                _PlanCard(planAsync: planAsync),
                const SizedBox(height: 16),
                const _StartChatButton(),
                const SizedBox(height: 12),
                const _PracticeScenariosCard(),
                const SizedBox(height: 12),
                const _StoryCard(),
                const SizedBox(height: 12),
                const _ImageVocabCard(),
                const SizedBox(height: 24),
                _RecentSessions(sessionsAsync: sessionsAsync),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroGreeting extends StatelessWidget {
  final TutorMemory memory;
  const _HeroGreeting({required this.memory});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatar = _personaAvatars[memory.persona] ?? '🐻';
    final name = _personaNames[memory.persona] ?? 'Nana';
    final lastSummary = memory.recentChatSummaries.isNotEmpty
        ? memory.recentChatSummaries.first.summary
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        children: [
          Text(avatar, style: const TextStyle(fontSize: 56)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: context.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  lastSummary != null
                      ? l10n.aiTutorHeroSubtitleLast(lastSummary)
                      : l10n.aiTutorHomeGreetingDefault,
                  style: context.bodyMedium.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final AsyncValue<DailyPlan?> planAsync;
  const _PlanCard({required this.planAsync});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: AppRadius.borderMD,
      ),
      child: planAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Plan unavailable: $e'),
        data: (plan) {
          if (plan == null || plan.tasks.isEmpty) {
            return Text(l10n.aiTutorHomePlanEmpty, style: context.bodyMedium);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.aiTutorHomeTodaysPlan,
                  style: context.titleSmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final t in plan.tasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: t.isDone ? AppColors.primary : context.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_taskLabel(context, t), style: context.bodyMedium)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _taskLabel(BuildContext context, DailyPlanTask t) {
    final l10n = AppLocalizations.of(context)!;
    switch (t.type) {
      case 'srs_review':
        return l10n.aiTutorPlanSrsReview(
          t.count ?? 0,
          (t.completed is num ? (t.completed as num).toInt() : 0),
        );
      case 'grammar_drill':
        return l10n.aiTutorPlanGrammar(t.topic ?? 'grammar');
      case 'tutor_chat':
        return l10n.aiTutorPlanChat(
          t.minutes ?? 5,
          (t.completed is num ? (t.completed as num).toInt() : 0),
        );
      case 'tutor_pronunciation':
        return l10n.aiTutorPlanPronunciation(
          t.count ?? 1,
          (t.completed is num ? (t.completed as num).toInt() : 0),
        );
      default:
        return t.type;
    }
  }
}

class _StartChatButton extends StatelessWidget {
  const _StartChatButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TutorChatScreen()),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(l10n.aiTutorHomeStartChat),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
        ),
      ),
    );
  }
}

class _PracticeScenariosCard extends StatelessWidget {
  const _PracticeScenariosCard();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.10),
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        borderRadius: AppRadius.borderMD,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScenarioPickerScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('🎭', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.aiTutorHomePracticeScenarios,
                        style: context.titleSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.aiTutorHomePracticeScenariosSubtitle,
                      style: context.bodySmall
                          .copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.indigo.withValues(alpha: 0.10),
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        borderRadius: AppRadius.borderMD,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StorySetupScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.aiTutorHomeReadStory,
                        style: context.titleSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.aiTutorHomeReadStorySubtitle,
                      style: context.bodySmall
                          .copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageVocabCard extends StatelessWidget {
  const _ImageVocabCard();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.teal.withValues(alpha: 0.10),
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        borderRadius: AppRadius.borderMD,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImageVocabScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('📷', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.aiTutorHomeDescribePhoto,
                        style: context.titleSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.aiTutorHomeDescribePhotoSubtitle,
                      style: context.bodySmall
                          .copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSessions extends StatelessWidget {
  final AsyncValue<List<TutorSession>> sessionsAsync;
  const _RecentSessions({required this.sessionsAsync});

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.aiTutorHomeRecent,
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final s in sessions.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  s.summary ?? '(no summary)',
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                ),
              ),
          ],
        );
      },
    );
  }
}
