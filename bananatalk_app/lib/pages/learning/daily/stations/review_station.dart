import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';

/// Due words from the learner's own SRS backlog. Recall first, reveal second,
/// verdict third — revealing before the learner tries is not a review.
class ReviewStation extends StatefulWidget {
  final ReviewPayload payload;
  final Future<StationResult> Function(List<Map<String, dynamic>>) onSubmit;
  final VoidCallback onDone;

  const ReviewStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<ReviewStation> createState() => _ReviewStationState();
}

class _ReviewStationState extends State<ReviewStation> {
  final List<Map<String, dynamic>> _verdicts = [];
  int _index = 0;
  bool _revealed = false;
  StationResult? _result;
  bool _failed = false;

  Future<void> _record(bool correct) async {
    _verdicts.add({'id': widget.payload.words[_index].id, 'correct': correct});
    if (_index + 1 < widget.payload.words.length) {
      setState(() {
        _index += 1;
        _revealed = false;
      });
      return;
    }
    try {
      final result = await widget.onSubmit(_verdicts);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_result != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.dailyScore(_result!.score, _result!.total),
              key: const Key('station-score'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('station-continue'),
              onPressed: widget.onDone,
              child: Text(l10n.packContinue),
            ),
          ],
        ),
      );
    }

    final word = widget.payload.words[_index];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.packWordProgress(_index + 1, widget.payload.words.length),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 32),
          Center(child: Text(word.word, style: theme.textTheme.headlineMedium)),
          const SizedBox(height: 24),
          if (_revealed)
            Center(child: Text(word.translation, style: theme.textTheme.titleLarge)),
          if (_failed)
            Padding(
              key: const Key('station-error'),
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.packSubmitFailed,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const Spacer(),
          if (!_revealed)
            FilledButton(
              key: const Key('review-reveal'),
              onPressed: () => setState(() => _revealed = true),
              child: Text(l10n.packReveal),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('review-missed'),
                    onPressed: () => _record(false),
                    child: Text(l10n.packMissed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('review-knew'),
                    onPressed: () => _record(true),
                    child: Text(l10n.packKnewIt),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
