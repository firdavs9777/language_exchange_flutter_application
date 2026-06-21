import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';

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
          onTap: onReactionTap != null ? () {
            HapticUtils.onLike();
            onReactionTap!(emoji);
          } : null,
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
    Key? key,
    required this.onEmojiSelected,
    this.currentReactions,
  }) : super(key: key);

  /// Reaction set shown in the floating picker. Tuned to cover the common
  /// chat emotions (positive / negative / surprise / agreement / language-
  /// learning praise) without becoming a full keyboard — the row scrolls
  /// horizontally on narrow screens so any count fits.
  static const List<String> defaultEmojis = [
    '👍', // like
    '❤️', // love
    '😂', // laugh
    '🤣', // rolling
    '😮', // wow
    '😢', // sad
    '😡', // angry
    '🙏', // thanks
    '👏', // clap
    '🔥', // fire
    '🎉', // celebrate
    '💯', // hundred
    '😍', // heart eyes
    '🤔', // thinking
    '😎', // cool
    '👎', // dislike
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...defaultEmojis.map((emoji) {
              final isSelected = currentReactions?.contains(emoji) ?? false;
              return GestureDetector(
                onTap: () {
                  HapticUtils.onLike();
                  onEmojiSelected(emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }),
            // "More reactions" launcher — opens a categorized emoji grid.
            GestureDetector(
              onTap: () => _openMoreReactionsSheet(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMoreReactionsSheet(BuildContext context) async {
    HapticUtils.onLike();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreReactionsSheet(
        currentReactions: currentReactions ?? const [],
      ),
    );
    if (picked != null && picked.isNotEmpty) {
      onEmojiSelected(picked);
    }
  }
}

/// Full categorized emoji grid for "more reactions". Returns the picked
/// emoji on pop; null if dismissed.
class _MoreReactionsSheet extends StatelessWidget {
  final List<String> currentReactions;

  const _MoreReactionsSheet({required this.currentReactions});

  /// Reaction catalog — broad enough to cover most chat emotions. Each
  /// category fits ~6 rows of 8 in the grid sheet.
  static const Map<String, List<String>> _categories = {
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
      '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
      '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
      '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳',
      '😶', '😐', '😑', '😬', '🫡', '🤐', '🤫', '🤥',
      '🫢', '🫣', '🙄', '😪', '🤤', '😴', '🥱', '😷',
    ],
    'Feels': [
      '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
      '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤',
      '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱',
      '😨', '😰', '😥', '😓', '🫠', '🫥', '🫨', '🥹',
      '🤒', '🤕', '🤢', '🤮', '🥴', '🤧', '😵', '😵‍💫',
      '🤥', '😈', '👿', '👻', '💀', '☠️', '👽', '🤡',
    ],
    'Gestures': [
      '👍', '👎', '👌', '🤌', '🤏', '✌️', '🤞', '🫰',
      '🤟', '🤘', '🤙', '👈', '👉', '👆', '👇', '☝️',
      '👋', '🤚', '🖐️', '✋', '🖖', '👏', '🙌', '👐',
      '🤝', '🙏', '✍️', '💅', '🤳', '💪', '🦾', '🧠',
      '🦵', '🦶', '👂', '🦻', '👃', '👀', '👁️', '👅',
      '👄', '🫦', '💋', '🩷', '🫶', '🤲', '🫳', '🫴',
    ],
    'Hearts': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '🩷', '🩵', '🩶', '❤️‍🔥', '❤️‍🩹', '💔', '❣️',
      '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟',
      '♥️', '💌', '💋', '💍', '💐', '🌷', '🌹', '🌺',
    ],
    'Hype': [
      '🔥', '✨', '🎉', '🎊', '💯', '🏆', '🥇', '🎯',
      '⭐', '🌟', '💫', '⚡', '💥', '💢', '💦', '💨',
      '🚀', '🌈', '☀️', '🌙', '⛅', '🍀', '🌹', '🌸',
      '🎂', '🥂', '🍻', '🎁', '🎀', '🎈', '🎵', '🎶',
      '📣', '📢', '🔔', '👑', '💎', '💰', '🥳', '🪅',
    ],
    'Animals': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
      '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🙈',
      '🙉', '🙊', '🐔', '🐧', '🐦', '🦆', '🦉', '🦄',
      '🐝', '🐛', '🦋', '🐢', '🐬', '🐳', '🦈', '🐙',
    ],
    'Food': [
      '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓',
      '🍒', '🍑', '🍍', '🥭', '🥑', '🍅', '🌶️', '🌽',
      '🥕', '🥯', '🍞', '🥐', '🥖', '🧀', '🥚', '🍳',
      '🥞', '🧇', '🍗', '🍔', '🍟', '🍕', '🌭', '🌮',
      '🍣', '🍜', '🍝', '🍰', '🎂', '🍩', '🍪', '🍫',
      '🍿', '☕', '🍵', '🧋', '🥤', '🍷', '🍺', '🍾',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: _categories.length,
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              TabBar(
                isScrollable: true,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: colorScheme.primary,
                dividerColor: Colors.transparent,
                tabs: _categories.keys
                    .map((name) => Tab(text: name))
                    .toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: _categories.values.map((emojis) {
                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: emojis.length,
                      itemBuilder: (_, i) {
                        final emoji = emojis[i];
                        final isSelected = currentReactions.contains(emoji);
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(ctx).pop(emoji),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

