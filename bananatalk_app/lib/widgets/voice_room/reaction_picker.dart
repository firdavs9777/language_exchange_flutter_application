import 'package:flutter/material.dart';

/// Bottom-sheet picker that surfaces a small fixed set of emoji reactions
/// for the active voice room. Tapping an emoji pops the sheet with the
/// chosen glyph; the caller (see [showReactionPicker]) then broadcasts it
/// via `VoiceRoomManager.sendReaction`.
///
/// Kept intentionally small (6 glyphs) so the picker fits one row on a
/// phone-width screen and the user can react in well under a second.
class ReactionPicker extends StatelessWidget {
  /// Invoked when the user taps an emoji. The default helper
  /// [showReactionPicker] uses `Navigator.pop(context, emoji)` here.
  final ValueChanged<String> onSelected;

  /// The six default reactions. Tuned for "live group voice chat" affect:
  /// applause / love / celebration / fire / laughter / agreement.
  static const List<String> defaultEmojis = [
    '\u{1F44F}', // clap
    '\u{2764}\u{FE0F}', // red heart
    '\u{1F389}', // party popper
    '\u{1F525}', // fire
    '\u{1F602}', // joy
    '\u{1F44D}', // thumbs up
  ];

  const ReactionPicker({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle — matches Material 3 bottom-sheet convention.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'React',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final emoji in defaultEmojis)
                  _EmojiButton(
                    emoji: emoji,
                    onTap: () => onSelected(emoji),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the reaction picker as a modal bottom sheet. Resolves with the
/// chosen emoji, or `null` if the user dismissed the sheet without
/// picking.
Future<String?> showReactionPicker(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReactionPicker(
      onSelected: (e) => Navigator.pop(context, e),
    ),
  );
}
