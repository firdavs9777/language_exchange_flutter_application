import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// The reward moment. The streak and the XP are the whole point of finishing,
/// and the old screen showed them as one line of body text.
class DayCompleteSheet extends StatelessWidget {
  final int? streak;
  final int xpAwarded;
  final String? themeTopic;
  final VoidCallback onClose;

  const DayCompleteSheet({
    super.key,
    required this.onClose,
    this.streak,
    this.xpAwarded = 0,
    this.themeTopic,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      key: const Key('day-complete-sheet'),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          if (streak != null)
            Text(l10n.dailyStreakDays(streak!), style: theme.textTheme.headlineSmall),
          if (xpAwarded > 0)
            Text(l10n.dailyXpEarned(xpAwarded), style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (themeTopic != null)
            Text(
              l10n.packTomorrowTeaser(themeTopic!),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('day-complete-close'),
            onPressed: onClose,
            child: Text(l10n.packDone),
          ),
        ],
      ),
    );
  }
}
