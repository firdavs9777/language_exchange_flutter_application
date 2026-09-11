import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/clip_audio.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';

/// Two clips from the week's theme, spoken aloud.
///
/// Tapping play asks the backend to speak the line and plays it, then reveals
/// the text so the learner can check themselves. The reveal stays behind the
/// tap: showing the sentence first would make this a reading exercise. If TTS
/// is unavailable the text is still revealed, because a listening station that
/// silently does nothing is worse than one that degrades to reading.
class ListeningStation extends StatefulWidget {
  final ListeningPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;
  final String language;

  /// Injected so widget tests never reach the network or the audio hardware.
  final Future<String?> Function(String text, String language)? fetchAudioUrl;
  final Future<void> Function(String url)? playAudio;

  const ListeningStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
    this.language = 'en',
    this.fetchAudioUrl,
    this.playAudio,
  });

  @override
  State<ListeningStation> createState() => _ListeningStationState();
}

class _ListeningStationState extends State<ListeningStation> {
  final Set<int> _revealed = {};
  final Set<int> _loading = {};
  ClipAudio? _audio;

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  Future<void> _playClip(int index, String text) async {
    if (_loading.contains(index)) return;
    setState(() => _loading.add(index));
    try {
      final fetch = widget.fetchAudioUrl ?? ClipAudio.fetchUrl;
      final url = await fetch(text, widget.language);
      if (url != null && url.isNotEmpty) {
        final play = widget.playAudio ?? (_audio ??= ClipAudio()).play;
        await play(url);
      }
    } catch (e) {
      // Swallowed on purpose: a failed fetch or playback must degrade to
      // reading the line, not surface as an unhandled async error.
      debugPrint('[listening] clip $index failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading.remove(index);
          // Revealed either way: audio being unavailable must not block the
          // station.
          _revealed.add(index);
        });
      }
    }
  }

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
                  onPressed: _loading.contains(i) ? null : () => _playClip(i, clip.text),
                  icon: _loading.contains(i)
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.volume_up),
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
