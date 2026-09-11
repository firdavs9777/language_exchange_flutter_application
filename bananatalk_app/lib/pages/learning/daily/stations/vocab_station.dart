import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/word_card.dart';

/// Five new words, walked one at a time, then checked. The words are taught
/// before any question appears — a check on a word the learner has not met is
/// a quiz, not a lesson.
class VocabStation extends StatefulWidget {
  final VocabPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const VocabStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<VocabStation> createState() => _VocabStationState();
}

class _VocabStationState extends State<VocabStation> {
  int _wordIndex = 0;

  bool get _taught => _wordIndex >= widget.payload.words.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_taught) {
      return CheckSequence(
        checks: widget.payload.checks,
        onSubmit: widget.onSubmit,
        onDone: widget.onDone,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.packWordProgress(_wordIndex + 1, widget.payload.words.length),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: WordCard(word: widget.payload.words[_wordIndex]),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('word-next'),
              onPressed: () => setState(() => _wordIndex += 1),
              child: Text(l10n.packGotIt),
            ),
          ),
        ],
      ),
    );
  }
}
