import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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
            onPressed: () async {
              ref.read(voiceRoomProvider).leaveRoom();
              Navigator.pop(dialogContext);
              await ref.read(adServiceProvider).showInterstitial();
              if (context.mounted) Navigator.pop(context);
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
    final l10n = AppLocalizations.of(context)!;
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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0x99FFFFFF),
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
              color: const Color(0xFFE91E63).withValues(alpha: 0.2),
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
          _buildRoomInfo(l10n),
          Expanded(child: _buildParticipants(l10n)),
          _buildControls(l10n),
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

  Widget _buildRoomInfo(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        children: [
          Container(
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
              color: const Color(0x1AFFFFFF),
              borderRadius: AppRadius.borderSM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: Color(0xB3FFFFFF),
                ),
                Spacing.hGapSM,
                Text(
                  widget.room.participantCountText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants(AppLocalizations l10n) {
    final voiceRoom = ref.watch(voiceRoomProvider);
    final providerParticipants = voiceRoom.participants;

    final rawParticipants = providerParticipants.isNotEmpty
        ? providerParticipants
        : widget.room.participants;

    // Sort so host appears first
    final allParticipants = List<RoomParticipant>.from(rawParticipants);
    allParticipants.sort((a, b) {
      final aIsHost = a.isHost || a.id == widget.room.hostId;
      final bIsHost = b.isHost || b.id == widget.room.hostId;
      if (aIsHost && !bIsHost) return -1;
      if (!aIsHost && bIsHost) return 1;
      return 0;
    });

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
        final isHost = participant.isHost || participant.id == widget.room.hostId;
        return _ParticipantTile(
          participant: participant,
          isHost: isHost,
          hostLabel: l10n.roomHost,
          onTap: () {
            if (participant.id.isNotEmpty) {
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => ProfileWrapper(userId: participant.id),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    final voiceRoom = ref.watch(voiceRoomProvider);
    final isMuted = voiceRoom.isMuted;
    final isHandRaised = voiceRoom.isHandRaised;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0x0DFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: isHandRaised
                  ? Icons.front_hand_rounded
                  : Icons.front_hand_outlined,
              label: isHandRaised ? l10n.lowerHand : l10n.raiseHand,
              color: isHandRaised ? const Color(0xFFFFB74D) : Colors.white,
              backgroundColor: isHandRaised
                  ? const Color(0xFFFFB74D).withValues(alpha: 0.2)
                  : const Color(0x1AFFFFFF),
              onTap: _toggleHandRaise,
            ),
            _ControlButton(
              icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: isMuted ? l10n.unmute : l10n.mute,
              color: isMuted ? Colors.red : const Color(0xFF00BFA5),
              backgroundColor: isMuted
                  ? Colors.red.withValues(alpha: 0.2)
                  : const Color(0xFF00BFA5).withValues(alpha: 0.2),
              onTap: _toggleMute,
              isLarge: true,
            ),
            _ControlButton(
              icon: Icons.call_end_rounded,
              label: l10n.leave,
              color: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.2),
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
  final VoidCallback? onTap;

  const _ParticipantTile({
    required this.participant,
    required this.hostLabel,
    this.isHost = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
                            color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xB3FFFFFF),
          ),
        ),
      ],
    );
  }
}
