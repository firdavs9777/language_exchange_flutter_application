import 'package:bananatalk_app/providers/provider_models/exam/vocabulary_word.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Browse-mode card for a single vocabulary word. Tap the speaker icon to
/// play / fetch the TTS audio (handled by the caller).
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.onPlayAudio,
    this.isPlaying = false,
  });

  final VocabularyWord word;
  final VoidCallback onPlayAudio;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word.word,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPlayAudio,
                icon: Icon(
                  isPlaying
                      ? Icons.volume_up_rounded
                      : Icons.play_circle_outline_rounded,
                  color: context.primaryColor,
                ),
                tooltip: 'Listen',
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              _chip(context, word.partOfSpeech),
              _chip(context, word.level),
              if (word.topic != null && word.topic!.isNotEmpty)
                _chip(context, word.topic!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            word.definition,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimary,
              height: 1.45,
            ),
          ),
          if (word.exampleSentence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Text(
                word.exampleSentence,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.primaryColor,
        ),
      ),
    );
  }
}
