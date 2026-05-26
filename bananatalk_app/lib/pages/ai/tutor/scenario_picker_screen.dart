import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/ai/tutor/roleplay_chat_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/widgets/tutor/tutor_quota_indicator.dart';

const _levelOrder = ['A1', 'A2', 'B1', 'B2', 'C1'];

int _levelRank(String level) => _levelOrder.indexOf(level.toUpperCase());

class ScenarioPickerScreen extends ConsumerWidget {
  const ScenarioPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(tutorScenariosProvider);

    // Step 13A: fire tutor_chip_used once when the picker first builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isVip = ref.read(userProvider).valueOrNull?.isVip == true;
      AnalyticsService.instance.tutorChipUsed(
        chipName: 'roleplay', userTier: isVip ? 'vip' : 'free',
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice scenarios'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: TutorQuotaIndicator(featureKey: 'roleplay')),
          ),
        ],
      ),
      body: scenariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load scenarios: $e')),
        data: (resp) {
          if (resp.scenarios.isEmpty) {
            return const Center(child: Text('No scenarios available yet.'));
          }
          return _GroupedScenarioList(response: resp);
        },
      ),
    );
  }
}

class _GroupedScenarioList extends StatelessWidget {
  final ScenariosResponse response;
  const _GroupedScenarioList({required this.response});

  @override
  Widget build(BuildContext context) {
    final userLevel = response.userContext.level.toUpperCase();
    final userRank = _levelRank(userLevel);
    // Group scenarios into for-you / easier / harder. If we can't place the
    // user level on the rank scale (unknown CEFR), fall back to one flat list.
    final List<TutorScenario> forYou = [];
    final List<TutorScenario> easier = [];
    final List<TutorScenario> harder = [];
    if (userRank < 0) {
      forYou.addAll(response.scenarios);
    } else {
      for (final s in response.scenarios) {
        final r = _levelRank(s.level);
        if (r < 0) {
          forYou.add(s);
        } else if (r == userRank) {
          forYou.add(s);
        } else if (r < userRank) {
          easier.add(s);
        } else {
          harder.add(s);
        }
      }
    }

    final sections = <_Section>[
      if (forYou.isNotEmpty)
        _Section(title: 'For your level ($userLevel)', items: forYou),
      if (easier.isNotEmpty)
        _Section(title: 'Easier — warm up', items: easier),
      if (harder.isNotEmpty)
        _Section(title: 'Harder — stretch', items: harder),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _GuideHeader(ctx: response.userContext),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          _SectionHeader(title: section.title),
          const SizedBox(height: 8),
          for (final s in section.items) ...[
            _ScenarioCard(scenario: s),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Section {
  final String title;
  final List<TutorScenario> items;
  _Section({required this.title, required this.items});
}

class _GuideHeader extends StatelessWidget {
  final ScenariosUserContext ctx;
  const _GuideHeader({required this.ctx});

  @override
  Widget build(BuildContext context) {
    final target = ctx.targetLanguage?.isNotEmpty == true
        ? ctx.targetLanguage!
        : 'your learning language';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ctx.level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practicing in $target',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pick a scenario at your level, or stretch one up.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: context.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: context.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ScenarioCard extends ConsumerStatefulWidget {
  final TutorScenario scenario;
  const _ScenarioCard({required this.scenario});
  @override
  ConsumerState<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends ConsumerState<_ScenarioCard> {
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      // Navigation only — RoleplayChatScreen owns the session lifecycle
      // (starts in its own initState).
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoleplayChatScreen(scenario: widget.scenario),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start: $e')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    return Material(
      color: context.containerColor,
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        borderRadius: AppRadius.borderMD,
        onTap: _starting ? null : _start,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(s.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            style: context.titleMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LevelChip(level: s.level),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.summary,
                      style: context.bodySmall
                          .copyWith(color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s.goal,
                            style: context.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_starting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
