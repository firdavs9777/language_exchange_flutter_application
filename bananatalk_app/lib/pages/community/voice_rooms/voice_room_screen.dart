import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_header.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_info_bar.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_participants_grid.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_controls.dart';

/// Voice Room Screen — active voice chat room.
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
    showCommunitySnackBar(
      context,
      message: isHandRaised
          ? l10n.handRaisedNotification
          : l10n.handLoweredNotification,
      type: CommunitySnackBarType.success,
      duration: const Duration(seconds: 2),
    );
  }

  void _leaveRoom() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  List<RoomParticipant> _sortedParticipants(
      List<RoomParticipant> raw) {
    final list = List<RoomParticipant>.from(raw);
    list.sort((a, b) {
      final aIsHost = a.isHost || a.id == widget.room.hostId;
      final bIsHost = b.isHost || b.id == widget.room.hostId;
      if (aIsHost && !bIsHost) return -1;
      if (!aIsHost && bIsHost) return 1;
      return 0;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final voiceRoom = ref.watch(voiceRoomProvider);

    final rawParticipants = voiceRoom.participants.isNotEmpty
        ? voiceRoom.participants
        : widget.room.participants;
    final participants = _sortedParticipants(rawParticipants);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: VoiceRoomHeader(
        room: widget.room,
        onLeave: _leaveRoom,
        pulseAnimation: _pulseAnimation,
      ),
      body: Column(
        children: [
          VoiceRoomInfoBar(room: widget.room),
          Expanded(
            child: VoiceRoomParticipantsGrid(
              room: widget.room,
              participants: participants,
              hostLabel: l10n.roomHost,
              onTileTap: (participant) {
                if (participant.id.isNotEmpty) {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) =>
                          ProfileWrapper(userId: participant.id),
                    ),
                  );
                }
              },
            ),
          ),
          VoiceRoomControls(
            isMuted: voiceRoom.isMuted,
            isHandRaised: voiceRoom.isHandRaised,
            onRaiseHand: _toggleHandRaise,
            onMute: _toggleMute,
            onLeave: _leaveRoom,
            raiseHandLabel: l10n.raiseHand,
            lowerHandLabel: l10n.lowerHand,
            muteLabel: l10n.mute,
            unmuteLabel: l10n.unmute,
            leaveLabel: l10n.leave,
          ),
        ],
      ),
    );
  }
}
