import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class MessageReactionWidget extends StatelessWidget {
  final List<MessageReaction> reactions;
  final Function(String emoji)? onReactionTap;
  final String? currentUserId;

  const MessageReactionWidget({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    // Group reactions by emoji
    final Map<String, List<MessageReaction>> groupedReactions = {};
    for (var reaction in reactions) {
      if (!groupedReactions.containsKey(reaction.emoji)) {
        groupedReactions[reaction.emoji] = [];
      }
      groupedReactions[reaction.emoji]!.add(reaction);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: groupedReactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final count = users.length;
        final isCurrentUserReacted = currentUserId != null &&
            users.any((r) => r.user.id == currentUserId);

        return GestureDetector(
          onTap: onReactionTap != null ? () => onReactionTap!(emoji) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentUserReacted
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentUserReacted
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isCurrentUserReacted ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCurrentUserReacted
                          ? colorScheme.primary
                          : context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget for showing reaction picker
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  final List<String>? currentReactions;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
    this.currentReactions,
  });

  static const List<String> defaultEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: defaultEmojis.map((emoji) {
          final isSelected = currentReactions?.contains(emoji) ?? false;
          return GestureDetector(
            onTap: () => onEmojiSelected(emoji),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 24,
                  opacity: isSelected ? 0.5 : 1.0,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

