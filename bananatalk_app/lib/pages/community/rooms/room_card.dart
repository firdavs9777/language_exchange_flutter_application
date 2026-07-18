import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One room row in the Rooms directory: flag, title, member/online counts,
/// and a short description. Mirrors the visual density of
/// `VoiceRoomCard`/community list rows so the Rooms tab feels consistent
/// with the rest of the Community screen.
///
/// Doubles as the row for both backend-seeded hubs and user-created topic
/// rooms (`room.isTopicRoom`) — topic rooms get a small "Topic" chip so
/// they read as distinct from the language hub they're nested under.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.isPinned = false,
  });

  final Room room;
  final VoidCallback onTap;

  /// True for the caller's auto-joined hub, shown first in the directory.
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.containerColor,
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMD,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              _FlagAvatar(emoji: room.emojiFlag),
              Spacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            room.title,
                            style: context.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPinned) ...[
                          Spacing.hGapSM,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: AppRadius.borderSM,
                            ),
                            child: Text(
                              'Your hub',
                              style: context.caption.copyWith(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (room.isTopicRoom) ...[
                          Spacing.hGapSM,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.textMuted.withValues(alpha: 0.14),
                              borderRadius: AppRadius.borderSM,
                            ),
                            child: Text(
                              'Topic',
                              style: context.caption.copyWith(
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (room.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        room.description,
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: context.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.memberCount}',
                          style: context.caption.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                        Spacing.hGapMD,
                        _OnlineDot(online: room.onlineCount > 0),
                        const SizedBox(width: 4),
                        Text(
                          '${room.onlineCount} online',
                          style: context.caption.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagAvatar extends StatelessWidget {
  const _FlagAvatar({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.containerHighColor,
        borderRadius: AppRadius.borderMD,
      ),
      child: Text(
        emoji.isNotEmpty ? emoji : '🌐',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: online ? AppColors.success : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
