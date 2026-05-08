import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A single participant tile shown in the voice room grid.
///
/// [isHandRaised] is a placeholder field (default false) — rendering the
/// hand-raise badge is wired in C21.
class VoiceRoomParticipantTile extends StatelessWidget {
  final RoomParticipant participant;
  final bool isHost;
  final String hostLabel;
  final VoidCallback? onTap;

  /// Placeholder for C21 hand-raise badge rendering.
  final bool isHandRaised;

  const VoiceRoomParticipantTile({
    super.key,
    required this.participant,
    required this.hostLabel,
    this.isHost = false,
    this.onTap,
    this.isHandRaised = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with speaking / host / muted indicators
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: participant.isSpeaking
                      ? Border.all(
                          color: const Color(0xFF00BFA5),
                          width: 3,
                        )
                      : null,
                  boxShadow: participant.isSpeaking
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00BFA5)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: participant.avatar.isNotEmpty
                      ? Image.network(
                          participant.avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              // Host badge
              if (isHost)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB74D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Muted indicator
              if (participant.isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Hand-raise badge (C21)
              if (participant.isHandRaised)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB74D),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✋', style: TextStyle(fontSize: 12)),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1.0, end: 1.1, duration: 600.ms),
                ),
            ],
          ),
          Spacing.gapSM,
          // Name
          Text(
            participant.name.isNotEmpty ? participant.name : '?',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isHost)
            Text(
              hostLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x80FFFFFF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF00BFA5),
      child: Center(
        child: Text(
          participant.name.isNotEmpty
              ? participant.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
