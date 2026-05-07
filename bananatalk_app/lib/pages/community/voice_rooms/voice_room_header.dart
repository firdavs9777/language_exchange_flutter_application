import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// AppBar for the voice room screen.
///
/// Displays a down-arrow leave button, topic + title in the center, and a
/// live-duration badge with an animated pulsing dot in the trailing action.
class VoiceRoomHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoiceRoom room;
  final VoidCallback onLeave;
  final Animation<double> pulseAnimation;

  const VoiceRoomHeader({
    super.key,
    required this.room,
    required this.onLeave,
    required this.pulseAnimation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: onLeave,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
        color: Colors.white,
      ),
      title: Column(
        children: [
          Text(
            room.topic,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0x99FFFFFF),
            ),
          ),
          Text(
            room.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63).withValues(alpha: 0.2),
            borderRadius: AppRadius.borderMD,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingDot(animation: pulseAnimation),
              Spacing.hGapSM,
              Text(
                room.durationText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE91E63),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatelessWidget {
  final Animation<double> animation;

  const _PulsingDot({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE91E63),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
