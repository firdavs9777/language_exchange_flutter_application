import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One grammar unit, taken from the learner's own position in the syllabus.
class GrammarStation extends StatelessWidget {
  final GrammarPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const GrammarStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return CheckSequence(
      checks: payload.checks,
      onSubmit: onSubmit,
      onDone: onDone,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(payload.section, style: theme.textTheme.labelMedium),
          Text(
            l10n.packGrammarUnit(payload.unit),
            style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(payload.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(payload.explanation, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          ...payload.examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  e,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              )),
        ],
      ),
    );
  }
}
