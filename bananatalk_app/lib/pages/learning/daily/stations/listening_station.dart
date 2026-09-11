import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';

/// Two clips from the week's theme. Wave 1 reveals the text on demand rather
/// than streaming audio (a deliberate spec deferral) — but the reveal still has
/// to be an action, or it is a reading exercise.
class ListeningStation extends StatefulWidget {
  final ListeningPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const ListeningStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<ListeningStation> createState() => _ListeningStationState();
}

class _ListeningStationState extends State<ListeningStation> {
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return CheckSequence(
      checks: widget.payload.clips
          .map((c) => PackCheck(
                prompt: l10n.packListeningPrompt,
                options: [c.word, c.text.split(' ').first, c.text.split(' ').last],
              ))
          .toList(),
      onSubmit: widget.onSubmit,
      onDone: widget.onDone,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.payload.clips.length, (i) {
          final clip = widget.payload.clips[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  key: Key('clip-play-$i'),
                  onPressed: () => setState(() => _revealed.add(i)),
                  icon: const Icon(Icons.volume_up),
                  label: Text(l10n.packPlayClip(i + 1)),
                ),
                if (_revealed.contains(i))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(clip.text, style: theme.textTheme.bodyLarge),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
