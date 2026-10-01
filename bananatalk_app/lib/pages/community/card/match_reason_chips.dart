import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';

/// Localized text for a server reason key, or null for unknown keys
/// (forward-compatible: new server reasons render nothing).
String? matchReasonText(
  AppLocalizations l10n,
  String key,
  DailyMatch match,
) {
  if (key == 'reciprocal_pair') return l10n.matchReasonReciprocal;
  if (key == 'same_target_language') {
    return l10n.matchReasonSameTarget(match.user.language_to_learn);
  }
  if (key == 'active_today') return l10n.matchReasonActiveToday;
  if (key == 'same_city') return l10n.matchReasonSameCity;
  if (key.startsWith('shared_topic:')) {
    final topic = key.substring(key.indexOf(':') + 1).trim();
    if (topic.isEmpty) return null;
    return l10n.matchReasonSharedTopic(topic);
  }
  return null;
}

class MatchReasonChips extends StatelessWidget {
  const MatchReasonChips({super.key, required this.match});

  final DailyMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final texts = <String>[];
    for (final key in match.matchReasons) {
      final t = matchReasonText(l10n, key, match);
      if (t != null && !texts.contains(t)) texts.add(t);
    }
    if (texts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in texts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.matchReasonTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.matchReasonText,
              ),
            ),
          ),
      ],
    );
  }
}
