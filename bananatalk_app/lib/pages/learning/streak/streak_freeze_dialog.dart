import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_snackbar.dart';

/// Dialog shown when the user taps the streak freeze badge.
/// Displays freeze count, description, current streak and a "Use freeze" button.
class StreakFreezeDialog extends ConsumerStatefulWidget {
  const StreakFreezeDialog({super.key});

  @override
  ConsumerState<StreakFreezeDialog> createState() => _StreakFreezeDialogState();
}

class _StreakFreezeDialogState extends ConsumerState<StreakFreezeDialog> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(learningProgressProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.ac_unit_rounded, color: Colors.lightBlue.shade300),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.learningStreakFreezeUse)),
        ],
      ),
      content: progressAsync.when(
        data: (progress) {
          final available = progress?.streakFreezes ?? 0;
          final currentStreak = progress?.currentStreak ?? 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.learningStreakFreezeAvailable(available)),
              const SizedBox(height: 12),
              Text(l10n.learningStreakFreezeDescription),
              const SizedBox(height: 12),
              Text(
                '${l10n.learningStreakCurrent}: $currentStreak',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(l10n.learningErrorGeneric),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _onUseFreeze(context),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.learningStreakFreezeUse),
        ),
      ],
    );
  }

  Future<void> _onUseFreeze(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final result = await LearningService.useStreakFreeze();
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to use freeze');
      }
      ref.invalidate(learningProgressProvider);
      if (!context.mounted) return;
      Navigator.pop(context);
      showLearningSnackBar(context, l10n.learningStreakFreezeProtected);
    } catch (e) {
      if (!context.mounted) return;
      showLearningSnackBar(context, l10n.learningErrorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
