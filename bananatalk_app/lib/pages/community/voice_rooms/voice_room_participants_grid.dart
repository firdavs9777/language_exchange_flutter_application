import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_participant_tile.dart';

/// A 3-column grid of [VoiceRoomParticipantTile] widgets.
///
/// [participants] should already be sorted (host first) by the caller.
/// Host long-press actions land in C23.
class VoiceRoomParticipantsGrid extends StatelessWidget {
  final VoiceRoom room;
  final List<RoomParticipant> participants;
  final String hostLabel;
  final void Function(RoomParticipant participant) onTileTap;

  /// Optional long-press handler — only supplied when the current user is host.
  /// When non-null, each tile is wrapped in a [GestureDetector].
  final void Function(RoomParticipant participant)? onTileLongPress;

  const VoiceRoomParticipantsGrid({
    super.key,
    required this.room,
    required this.participants,
    required this.hostLabel,
    required this.onTileTap,
    this.onTileLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        final isHost =
            participant.isHost || participant.id == room.hostId;
        final tile = VoiceRoomParticipantTile(
          participant: participant,
          isHost: isHost,
          hostLabel: hostLabel,
          onTap: () => onTileTap(participant),
        );
        if (onTileLongPress != null) {
          return GestureDetector(
            onLongPress: () => onTileLongPress!(participant),
            child: tile,
          );
        }
        return tile;
      },
    );
  }
}
