import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_participant_tile.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';

/// A 3-column grid of [VoiceRoomParticipantTile] widgets.
///
/// Perf note (rooms perf refactor): this grid is driven by [participantIds]
/// — a membership+order-only list — rather than the full [RoomParticipant]
/// objects. Each item is wrapped in [_ParticipantTile], its own `Consumer`
/// that independently watches just that one participant's data via
/// `voiceRoomProvider.select`. As long as the caller only reconstructs this
/// widget when [participantIds] itself changes (join/leave/host-transfer —
/// i.e. membership or order), a high-frequency event that only touches a
/// single participant's flags (active-speaker, mute, hand-raise — the
/// events that can fire multiple times a second) updates only that one
/// tile's `Consumer` without this grid, or any other tile, rebuilding.
class VoiceRoomParticipantsGrid extends StatelessWidget {
  final VoiceRoom room;
  final List<String> participantIds;
  final String hostLabel;
  final void Function(RoomParticipant participant) onTileTap;

  /// Optional long-press handler — only supplied when the current user is host.
  /// When non-null, each tile is wrapped in a [GestureDetector].
  final void Function(RoomParticipant participant)? onTileLongPress;

  /// Optional builder for a per-participant [GlobalKey] that wraps the tile.
  /// Used by the parent screen to locate a tile's RenderBox so it can
  /// anchor floating-emoji reactions over the right avatar (C1).
  final GlobalKey? Function(RoomParticipant participant)? keyForParticipant;

  const VoiceRoomParticipantsGrid({
    super.key,
    required this.room,
    required this.participantIds,
    required this.hostLabel,
    required this.onTileTap,
    this.onTileLongPress,
    this.keyForParticipant,
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
      itemCount: participantIds.length,
      itemBuilder: (context, index) {
        final id = participantIds[index];
        // ValueKey by participant id (not index) so that a reorder
        // (e.g. a host transfer moving the new host to the front) moves
        // the underlying Element along with its participant instead of
        // Flutter reusing the index-N slot for a different participant's
        // data mid-animation.
        return _ParticipantTile(
          key: ValueKey(id.isNotEmpty ? id : 'idx_$index'),
          participantId: id,
          fallbackParticipants: room.participants,
          room: room,
          hostLabel: hostLabel,
          onTap: onTileTap,
          onLongPress: onTileLongPress,
          keyForParticipant: keyForParticipant,
        );
      },
    );
  }
}

/// Wraps a single tile in its own [ConsumerWidget] so this participant's
/// active-speaker/mute/hand-raise changes rebuild ONLY this tile. See
/// [VoiceRoomParticipantsGrid]'s doc comment for why this matters.
class _ParticipantTile extends ConsumerWidget {
  final String participantId;

  /// Mirrors `VoiceRoomScreen`'s existing fallback: before the manager has
  /// finished seeding live participants, fall back to the static room
  /// snapshot the caller already had. Kept identical to the pre-refactor
  /// behavior in `VoiceRoomScreen.build`.
  final List<RoomParticipant> fallbackParticipants;
  final VoiceRoom room;
  final String hostLabel;
  final void Function(RoomParticipant participant) onTap;
  final void Function(RoomParticipant participant)? onLongPress;
  final GlobalKey? Function(RoomParticipant participant)? keyForParticipant;

  const _ParticipantTile({
    super.key,
    required this.participantId,
    required this.fallbackParticipants,
    required this.room,
    required this.hostLabel,
    required this.onTap,
    this.onLongPress,
    this.keyForParticipant,
  });

  RoomParticipant _find(List<RoomParticipant> list) {
    for (final p in list) {
      if (p.id == participantId) return p;
    }
    // Transient fallback only — the id list this tile was built for should
    // always resolve to a real participant; this just avoids a crash if a
    // leave event and a rebuild race in the same frame.
    return RoomParticipant(id: participantId, name: '', joinedAt: DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(voiceRoomProvider.select((notifier) {
      final live = notifier.participants;
      return _find(live.isNotEmpty ? live : fallbackParticipants);
    }));
    final isHost = participant.isHost || participant.id == room.hostId;

    Widget tile = VoiceRoomParticipantTile(
      participant: participant,
      isHost: isHost,
      hostLabel: hostLabel,
      onTap: () => onTap(participant),
    );
    if (onLongPress != null) {
      tile = GestureDetector(
        onLongPress: () => onLongPress!(participant),
        child: tile,
      );
    }
    final tileKey = keyForParticipant?.call(participant);
    if (tileKey != null) {
      // KeyedSubtree binds the GlobalKey to the tile subtree without
      // disturbing the tile widget's own key (if any).
      tile = KeyedSubtree(key: tileKey, child: tile);
    }
    return tile;
  }
}
