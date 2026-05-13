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
        data: (scenarios) {
          if (scenarios.isEmpty) {
            return const Center(child: Text('No scenarios available yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scenarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = scenarios[i];
              return _ScenarioCard(scenario: s);
            },
          );
        },
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
      // Use a fresh chat controller for the roleplay so it doesn't
      // clobber any free-chat session in flight.
      await ref
          .read(tutorChatControllerProvider.notifier)
          .startRoleplay(widget.scenario.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RoleplayChatScreen(scenario: widget.scenario),
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
                    Text(s.title,
                        style: context.titleMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(s.summary,
                        style: context.bodySmall
                            .copyWith(color: context.textSecondary)),
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
