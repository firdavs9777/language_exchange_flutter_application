import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One new word: headword, definition, example. The audio affordance is a
/// callback so wave 1 can render text-only clips while TTS is wired.
class WordCard extends StatelessWidget {
  final PackWord word;
  final VoidCallback? onSpeak;

  const WordCard({super.key, required this.word, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(word.word, style: theme.textTheme.headlineSmall)),
            if (onSpeak != null)
              IconButton(
                key: const Key('word-speak'),
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(word.definition, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Text(
          word.example,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
