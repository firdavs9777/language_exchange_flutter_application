import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Language chip + participant count chip row shown beneath the AppBar.
class VoiceRoomInfoBar extends StatelessWidget {
  final VoiceRoom room;

  const VoiceRoomInfoBar({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        children: [
          _LanguageChip(language: room.language),
          Spacing.hGapMD,
          _ParticipantCountChip(countText: room.participantCountText),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String language;

  const _LanguageChip({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
        borderRadius: AppRadius.borderSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language_rounded,
            size: 16,
            color: Color(0xFF00BFA5),
          ),
          Spacing.hGapSM,
          Text(
            language,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00BFA5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCountChip extends StatelessWidget {
  final String countText;

  const _ParticipantCountChip({required this.countText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: AppRadius.borderSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_rounded, size: 16, color: Color(0xB3FFFFFF)),
          Spacing.hGapSM,
          Text(
            countText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
