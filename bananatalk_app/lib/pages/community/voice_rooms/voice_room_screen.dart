import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/services/ad_service.dart';
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

    // All manager callback wiring happens in this SAME post-frame callback,
    // BEFORE `joinRoom()` is called below. Previously these were split
    // across two independently-scheduled `addPostFrameCallback`s — since
    // `joinRoom()` is an async REST+LiveKit connect, it could complete (and
    // fire host-change/forced-mute/reaction events) before the second
    // callback ever attached its listeners, silently dropping them. Wiring
    // everything first closes that window.
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

      manager.onMicPermissionDenied = () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission needed'),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.openSettings,
              onPressed: () => AppSettings.openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      };

      // Callbacks are attached — now safe to kick off the join.
      ref.read(voiceRoomProvider).joinRoom(widget.room);
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
              final adService = AdService();
              if (adService.isRewardedAdReady && context.mounted) {
                await adService.showRewarded(onRewarded: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for participating! +10 XP 🎉')),
                    );
                  }
                });
              }
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
    // Perf note (rooms perf refactor): this used to be a single unscoped
    // `ref.watch(voiceRoomProvider)`, which meant EVERY event the notifier
    // fires — participant join/left, chat, mute, hand-raise, host-change,
    // and critically every active-speaker transition (which can fire
    // multiple times a second) — rebuilt this entire screen: info bar,
    // grid, controls, all of it. Now the screen itself only watches the
    // two flags it truly needs at this level (`isReconnecting` gates the
    // `IgnorePointer`/reconnect banner/react-FAB), and each section below
    // (participants grid, controls) reads its own slice independently via
    // `voiceRoomProvider.select` inside its own `Consumer`, so unrelated
    // churn no longer cascades up here.
    final isReconnecting =
        ref.watch(voiceRoomProvider.select((n) => n.isReconnecting));
    final currentUserId = ref.read(authServiceProvider).userId;
    final isHost = currentUserId == widget.room.hostId;

    // Auto-pop when room ends (including during reconnect gap), OR when the
    // initial join itself fails/times out — `VoiceRoomNotifier.joinRoom`
    // (~15s timeout) sets `isLoading: false` + `error` in that case without
    // ever having set `currentRoom`, so `wasInRoom` alone wouldn't catch it.
    // `ref.listen` fires on every notifier change independent of whether
    // this widget rebuilds via `ref.watch`, so narrowing the watch above
    // doesn't affect this listener's ability to see every transition.
    ref.listen<VoiceRoomNotifier>(voiceRoomProvider, (previous, next) {
      final wasInRoom = previous?.currentRoom != null;
      final wasJoining = previous?.isLoading ?? false;
      final nowOutOfRoom = next.currentRoom == null;
      final joinFailed =
          wasJoining && !next.isLoading && nowOutOfRoom && next.state.error != null;
      if ((wasInRoom || joinFailed) && nowOutOfRoom && context.mounted) {
        final reason = next.state.error;
        if (reason != null && reason.isNotEmpty) {
          showCommunitySnackBar(
            context,
            message: reason,
            type: CommunitySnackBarType.error,
          );
        }
        Navigator.of(context).maybePop();
      }
    });

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
                child: Consumer(
                  builder: (context, ref, _) {
                    // `select` returns a comma-joined String of the sorted
                    // (host-first) participant ids -- a value type with
                    // proper `==`, unlike a raw `List<RoomParticipant>`
                    // which compares by identity and would "change" (and
                    // force a rebuild) on every single event. Because of
                    // that, this Consumer -- and the sort inside the
                    // selector -- only re-runs when membership or host
                    // order actually changes, NOT when a single
                    // participant's isSpeaking/isMuted/isHandRaised flips,
                    // which is the high-frequency case this refactor
                    // targets. Mongo ids never contain a comma, so
                    // splitting the key reconstructs the id list exactly,
                    // with no second sort/read needed to stay in sync.
                    final orderedIdsKey =
                        ref.watch(voiceRoomProvider.select((n) {
                      final raw = n.participants.isNotEmpty
                          ? n.participants
                          : widget.room.participants;
                      return _sortedParticipants(raw)
                          .map((p) => p.id)
                          .join(',');
                    }));
                    final orderedIds = orderedIdsKey.isEmpty
                        ? const <String>[]
                        : orderedIdsKey.split(',');

                    return VoiceRoomParticipantsGrid(
                      room: widget.room,
                      participantIds: orderedIds,
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
                                showParticipantActions(
                                    context, ref, participant);
                              }
                            }
                          : null,
                      keyForParticipant: (participant) =>
                          participant.id.isNotEmpty
                              ? _keyForParticipant(participant.id)
                              : null,
                    );
                  },
                ),
              ),
              IgnorePointer(
                ignoring: isReconnecting,
                child: Consumer(
                  builder: (context, ref, _) {
                    // Local control state — isMuted/isHandRaised are
                    // primitives, so `select` already dedupes correctly
                    // without needing the manager-level list caching that
                    // `participants`/`chatMessages` required.
                    final isMuted =
                        ref.watch(voiceRoomProvider.select((n) => n.isMuted));
                    final isHandRaised = ref
                        .watch(voiceRoomProvider.select((n) => n.isHandRaised));
                    final chatCount = ref.watch(
                        voiceRoomProvider.select((n) => n.chatMessages.length));
                    final unread =
                        (chatCount - _lastSeenChatCount).clamp(0, 999);
                    return VoiceRoomControls(
                      isMuted: isMuted,
                      isHandRaised: isHandRaised,
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
                      chatLabel: l10n.voiceRoomChat,
                    );
                  },
                ),
              ),
            ],
          ),
          if (_chatVisible)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.0,
              maxChildSize: 0.85,
              builder: (_, scrollController) =>
                  VoiceRoomChatPanel(scrollController: scrollController),
            ),
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
                  tooltip: AppLocalizations.of(context)!.voiceRoomReactTooltip,
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
