import 'package:flutter/widgets.dart';

/// One row in the long-press context menu shown above a chat message.
/// Used by message_bubble.dart's context-menu builder.
class MessageContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  /// Optional override for the row's accent color. Used to make the
  /// language-learning power actions (Correct / Translate / Save Phrase)
  /// pop visually instead of all blending into the same default grey.
  final Color? accentColor;

  const MessageContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.accentColor,
  });
}
