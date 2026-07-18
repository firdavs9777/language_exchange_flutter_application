import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/voice_room_provider.dart';

/// Count of currently-live voice rooms, polled every 30s.
///
/// Backs the "N live now" app-bar pill called for in the rooms audit
/// (`.superpowers/sdd/rooms-audit-report.md` §3 Engagement / §6 Tier 1 #3):
/// Rooms/Voice Rooms currently has zero always-visible entry point outside
/// the buried Community tab strip, unlike Coins/Notifications which get
/// dedicated app-bar real estate.
///
/// Reuses [VoiceRoomNotifier.fetchRooms] (no status filter) which already
/// hits `GET voicerooms` — the backend defaults that query to
/// `status: { $in: ['waiting', 'active'] }` within the heartbeat window
/// (`backend/controllers/voiceRooms.js`), i.e. exactly "live right now"
/// rooms, so `.length` is the count we want with no extra endpoint.
///
/// `autoDispose` (no `keepAlive`) so polling stops the moment nothing is
/// watching it — e.g. when the Community screen isn't on screen — instead
/// of running forever in the background.
final activeVoiceRoomCountProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  final notifier = ref.read(voiceRoomProvider.notifier);

  Future<int> fetchCount() async {
    final rooms = await notifier.fetchRooms();
    return rooms.length;
  }

  yield await fetchCount();

  yield* Stream<void>.periodic(const Duration(seconds: 30))
      .asyncMap((_) => fetchCount());
});
