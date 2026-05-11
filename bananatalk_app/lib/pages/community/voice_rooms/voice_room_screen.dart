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
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_chat_panel.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_host_menu.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_participant_actions.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_reconnect_banner.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/voice_room/floating_reaction.dart';
import 'package:bananatalk_app/widgets/voice_room/reaction_picker.dart';
import 'package:bananatalk_app/widgets/voice_room/room_ended_modal.dart';

/// Voice Room Screen — active voice chat room.
class VoiceRoomScreen extends ConsumerStatefulWidget {
  final VoiceRoom room;

  const VoiceRoomScreen({super.key, required this.room});

  @override
  ConsumerState<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends ConsumerState<VoiceRoomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _chatVisible = false;
  int _lastSeenChatCount = 0;

  /// GlobalKeys for each participant tile so [_showReactionFor] can
  /// resolve a tile's screen position and anchor a floating emoji over
  /// its avatar. Keyed by [RoomParticipant.id]; we never recycle keys
  /// for the same id, so the same tile keeps a stable RenderBox lookup
  /// across rebuilds.
  final Map<String, GlobalKey> _participantKeys = <String, GlobalKey>{};

  GlobalKey _keyForParticipant(String userId) {
    return _participantKeys.putIfAbsent(userId, () => GlobalKey());
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = ref.read(voiceRoomProvider).manager;
      manager.onHostChanged = (newHostId, _) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final myId = ref.read(authServiceProvider).userId;
        final isMe = newHostId == myId;
        if (isMe) {
          showCommunitySnackBar(
            context,
            message: l10n.voiceRoomYouAreHostNow,
            type: CommunitySnackBarType.success,
          );
        } else {
          final participants = ref.read(voiceRoomProvider).participants;
          final newHost = participants.firstWhere(
            (p) => p.id == newHostId,
            orElse: () =>
                RoomParticipant(id: '', name: '', joinedAt: DateTime.now()),
          );
          if (newHost.name.isNotEmpty) {
            showCommunitySnackBar(
              context,
              message: l10n.voiceRoomHostChanged(newHost.name),
              type: CommunitySnackBarType.info,
            );
          }
        }
      };

      manager.onForcedMuteSelf = () {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        showCommunitySnackBar(
          context,
          message: l10n.mutedByHost,
          type: CommunitySnackBarType.info,
        );
      };

      manager.onReactionReceived = (participantId, emoji) {
        _showReactionFor(participantId, emoji);
      };
    });
  }

  /// Anchor a floating-emoji animation over the sender's avatar tile.
  ///
  /// We look up the tile's RenderBox via its GlobalKey and pin the emoji
  /// at the top-center. If the tile is offscreen (long scroll, host
  /// long-press kicked it off the layout, participant just left) we fall
  /// back to a screen-top-quarter center anchor so the user still gets
  /// visual feedback.
  void _showReactionFor(String participantId, String emoji) {
    if (!mounted) return;

    Offset? anchor;
    final key = _participantKeys[participantId];
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.attached) {
      final size = box.size;
      // Top-center of the tile — the avatar sits at the top of the tile,
      // so this lands the emoji just above the avatar.
      anchor = box.localToGlobal(Offset(size.width / 2, 0));
    }
    if (anchor == null) {
      final mq = MediaQuery.of(context).size;
      anchor = Offset(mq.width / 2, mq.height * 0.25);
    }

    showFloatingReaction(
      context: context,
      anchor: anchor,
      emoji: emoji,
    );
  }

  Future<void> _sendReaction() async {
    final emoji = await showReactionPicker(context);
    if (emoji == null || !mounted) return;
    final manager = ref.read(voiceRoomProvider).manager;
    await manager.sendReaction(emoji);
    // LiveKit does not echo published data to the publisher; surface our
    // own emoji locally so the sender sees their reaction float too.
    final myId = ref.read(authServiceProvider).userId;
    if (myId.isNotEmpty && mounted) {
      _showReactionFor(myId, emoji);
    }
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

  void _toggleChat() {
    setState(() {
      _chatVisible = !_chatVisible;
      if (_chatVisible) {
        _lastSeenChatCount = ref.read(voiceRoomProvider).chatMessages.length;
      }
    });
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

  List<RoomParticipant> _sortedParticipants(List<RoomParticipant> raw) {
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
    final currentUserId = ref.read(authServiceProvider).userId;
    final isHost = currentUserId == widget.room.hostId;
    final isReconnecting = voiceRoom.isReconnecting;

    // Auto-pop when room ends. If the room ended because the host pressed
    // End (or we were kicked), show an acknowledgement modal first so the
    // user sees an explicit reason rather than the screen vanishing.
    ref.listen<VoiceRoomNotifier>(voiceRoomProvider, (previous, next) async {
      final wasInRoom = previous?.currentRoom != null;
      final nowOutOfRoom = next.currentRoom == null;
      if (!(wasInRoom && nowOutOfRoom)) return;
      if (!context.mounted) return;

      // The host's own end flow already popped via the host menu (see
      // showEndRoomConfirm); skip the modal for the host since they
      // explicitly initiated the action.
      if (isHost) {
        Navigator.of(context).maybePop();
        return;
      }

      final reason = next.state.error ?? 'Room ended';
      await showRoomEndedModal(context, reason: reason);
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).maybePop();
      }
    });

    final rawParticipants = voiceRoom.participants.isNotEmpty
        ? voiceRoom.participants
        : widget.room.participants;
    final participants = _sortedParticipants(rawParticipants);

    final messages = voiceRoom.chatMessages;
    final unread = (messages.length - _lastSeenChatCount).clamp(0, 999);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: VoiceRoomHeader(
        room: widget.room,
        onLeave: _leaveRoom,
        pulseAnimation: _pulseAnimation,
      ),
      body: Stack(
        children: [
          Column(
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
                  onTileLongPress: isHost
                      ? (participant) {
                          final participantIsHost =
                              participant.isHost ||
                              participant.id == widget.room.hostId;
                          if (!participantIsHost) {
                            showParticipantActions(context, ref, participant);
                          }
                        }
                      : null,
                  keyForParticipant: (participant) =>
                      participant.id.isNotEmpty
                          ? _keyForParticipant(participant.id)
                          : null,
                ),
              ),
              IgnorePointer(
                ignoring: isReconnecting,
                child: VoiceRoomControls(
                  isMuted: voiceRoom.isMuted,
                  isHandRaised: voiceRoom.isHandRaised,
                  onRaiseHand: _toggleHandRaise,
                  onMute: _toggleMute,
                  onLeave: _leaveRoom,
                  isHost: isHost,
                  onEnd: () => showHostMenu(context, ref),
                  unreadChatCount: _chatVisible ? 0 : unread,
                  onChatToggle: _toggleChat,
                  raiseHandLabel: l10n.raiseHand,
                  lowerHandLabel: l10n.lowerHand,
                  muteLabel: l10n.mute,
                  unmuteLabel: l10n.unmute,
                  leaveLabel: l10n.leave,
                  endRoomLabel: l10n.voiceRoomEnd,
                ),
              ),
            ],
          ),
          if (_chatVisible) ...[
            // Tap-outside-to-dismiss backdrop. Sits below the sheet so it
            // catches taps on the area above the chat panel only.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleChat,
                child: Container(color: Colors.black54),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.0,
              maxChildSize: 0.85,
              builder: (_, scrollController) => VoiceRoomChatPanel(
                scrollController: scrollController,
                onClose: _toggleChat,
              ),
            ),
          ],
          // Floating "React" FAB pinned above the bottom controls bar.
          // Hidden while the chat panel is open so it doesn't fight for
          // the same touch region as the chat input.
          if (!_chatVisible)
            Positioned(
              right: 16,
              bottom: 160,
              child: SafeArea(
                child: FloatingActionButton.small(
                  heroTag: 'voice_room_react_fab',
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  tooltip: 'React',
                  onPressed: isReconnecting ? null : _sendReaction,
                  child: const Icon(Icons.add_reaction_outlined),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VoiceRoomReconnectBanner(isReconnecting: isReconnecting),
          ),
        ],
      ),
    );
  }
}
