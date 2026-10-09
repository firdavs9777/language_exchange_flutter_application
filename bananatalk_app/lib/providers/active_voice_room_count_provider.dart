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
/// `autoDispose` so polling stops when nothing is watching it — e.g. when the
/// Community screen isn't on screen — instead of running forever in the
/// background. It is held open for one poll interval after the last listener
/// leaves (see `_idleCacheWindow` below) so that an app-bar rebuild reuses the
/// count rather than paying another request for it.
const _idleCacheWindow = Duration(seconds: 30);

final activeVoiceRoomCountProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  // Hold the provider open for one poll interval after the last listener
  // leaves, instead of tearing down the moment the app bar rebuilds.
  //
  // The body below fetches IMMEDIATELY before the periodic stream starts, so
  // every dispose -> recreate used to cost a `GET /voicerooms`. A device log
  // on 2026-10-09 caught ~14 back-to-back requests ~570ms apart, still firing
  // during an active call, instead of one per 30 seconds.
  //
  // This keeps `autoDispose` doing its job -- after the window with nobody
  // watching, the link closes and polling genuinely stops -- while making a
  // rebuild reuse the count it already has.
  final link = ref.keepAlive();
  Timer? idle;
  ref.onDispose(() => idle?.cancel());
  ref.onCancel(() {
    idle?.cancel();
    idle = Timer(_idleCacheWindow, link.close);
  });
  ref.onResume(() {
    idle?.cancel();
    idle = null;
  });

  final notifier = ref.read(voiceRoomProvider.notifier);

  Future<int> fetchCount() async {
    final rooms = await notifier.fetchRooms();
    return rooms.length;
  }

  yield await fetchCount();

  yield* Stream<void>.periodic(const Duration(seconds: 30))
      .asyncMap((_) => fetchCount());
});
