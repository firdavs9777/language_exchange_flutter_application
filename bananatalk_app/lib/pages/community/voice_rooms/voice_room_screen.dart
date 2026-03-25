import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Voice Room Screen - Active voice chat room
class VoiceRoomScreen extends ConsumerStatefulWidget {
  final VoiceRoom room;

  const VoiceRoomScreen({
    super.key,
    required this.room,
  });

  @override
  ConsumerState<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends ConsumerState<VoiceRoomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Join the room via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceRoomProvider).joinRoom(widget.room);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    ref.read(voiceRoomProvider).toggleMute();
  }

  void _toggleHandRaise() {
    HapticFeedback.lightImpact();
    ref.read(voiceRoomProvider).toggleHandRaised();
    final l10n = AppLocalizations.of(context)!;
    final isHandRaised = ref.read(voiceRoomProvider).isHandRaised;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHandRaised ? l10n.handRaisedNotification : l10n.handLoweredNotification,
        ),
        backgroundColor: const Color(0xFF00BFA5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _leaveRoom() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.leaveRoomConfirm),
        content: Text(l10n.leaveRoomMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.stay),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(voiceRoomProvider).leaveRoom();
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Leave room
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.leave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _leaveRoom,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          color: Colors.white,
        ),
        title: Column(
          children: [
            Text(
              widget.room.topic,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              widget.room.title,
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
              color: const Color(0xFFE91E63).withOpacity(0.2),
              borderRadius: AppRadius.borderMD,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPulsingDot(),
                Spacing.hGapSM,
                Text(
                  widget.room.durationText,
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
      ),
      body: Column(
        children: [
          // Room info
          _buildRoomInfo(),
          // Participants
          Expanded(
            child: _buildParticipants(),
          ),
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
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

  Widget _buildRoomInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.2),
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
                  widget.room.language,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00BFA5),
                  ),
                ),
              ],
            ),
          ),
          Spacing.hGapMD,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                Spacing.hGapSM,
                Text(
                  widget.room.participantCountText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants() {
    final voiceRoom = ref.watch(voiceRoomProvider);
    final providerParticipants = voiceRoom.participants;

    // Use provider participants if available, otherwise fall back to room data
    final allParticipants = providerParticipants.isNotEmpty
        ? [
            // Add host as first participant
            RoomParticipant(
              id: widget.room.hostId,
              name: widget.room.hostName,
              avatar: widget.room.hostAvatar,
              isHost: true,
              isSpeaking: true,
              joinedAt: widget.room.createdAt,
            ),
            ...providerParticipants.where((p) => p.id != widget.room.hostId),
          ]
        : [
            // Add host as first participant
            RoomParticipant(
              id: widget.room.hostId,
              name: widget.room.hostName,
              avatar: widget.room.hostAvatar,
              isHost: true,
              isSpeaking: true,
              joinedAt: widget.room.createdAt,
            ),
            ...widget.room.participants,
          ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        return _ParticipantTile(
          participant: participant,
          isHost: index == 0,
          hostLabel: AppLocalizations.of(context)!.roomHost,
        );
      },
    );
  }

  Widget _buildControls() {
    final l10n = AppLocalizations.of(context)!;
    final voiceRoom = ref.watch(voiceRoomProvider);
    final isMuted = voiceRoom.isMuted;
    final isHandRaised = voiceRoom.isHandRaised;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Raise hand
            _ControlButton(
              icon: isHandRaised
                  ? Icons.front_hand_rounded
                  : Icons.front_hand_outlined,
              label: isHandRaised ? l10n.lowerHand : l10n.raiseHand,
              color: isHandRaised ? const Color(0xFFFFB74D) : Colors.white,
              backgroundColor: isHandRaised
                  ? const Color(0xFFFFB74D).withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              onTap: _toggleHandRaise,
            ),
            // Mute/Unmute
            _ControlButton(
              icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: isMuted ? l10n.unmute : l10n.mute,
              color: isMuted ? Colors.red : const Color(0xFF00BFA5),
              backgroundColor: isMuted
                  ? Colors.red.withOpacity(0.2)
                  : const Color(0xFF00BFA5).withOpacity(0.2),
              onTap: _toggleMute,
              isLarge: true,
            ),
            // Leave
            _ControlButton(
              icon: Icons.call_end_rounded,
              label: l10n.leave,
              color: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.2),
              onTap: _leaveRoom,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final RoomParticipant participant;
  final bool isHost;
  final String hostLabel;

  const _ParticipantTile({
    required this.participant,
    required this.hostLabel,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with speaking indicator
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
                          color: const Color(0xFF00BFA5).withOpacity(0.4),
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
          ],
        ),
        Spacing.gapSM,
        // Name
        Text(
          participant.name,
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
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF00BFA5),
      child: Center(
        child: Text(
          participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 72.0 : 56.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
          ),
        ),
        Spacing.gapSM,
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
