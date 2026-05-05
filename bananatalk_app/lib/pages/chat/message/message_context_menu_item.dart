import 'package:flutter/widgets.dart';

/// One row in the long-press context menu shown above a chat message.
/// Used by message_bubble.dart's context-menu builder.
class MessageContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const MessageContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
