import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../models/community/voice_room_model.dart';
import 'api_client.dart';
import 'livekit_service.dart';

/// Transport layer that adapts the LiveKit SDK to the participant + event
/// shape the existing `VoiceRoomManager` exposes to the UI.
///
/// A3 will rewrite `voice_room_manager.dart` to delegate room transport to an
/// instance of this class; the manager remains responsible for fusing the
/// LiveKit signal (live presence + active speakers) with the canonical room
/// state returned by `POST /voicerooms/:id/join` (avatars, joinedAt, host
/// flag, hand-raised flag).
///
/// Mapping notes (LiveKit -> RoomParticipant):
///   - `id`           : `participant.identity` (Mongo user `_id`, set server-side)
///   - `name`         : `participant.name`     (set server-side)
///   - `isHost`       : parsed from `participant.metadata` JSON `{ "role": "host" }`
///   - `isMuted`      : starts `true` (we mint tokens muted; later refined by
///                      TrackMuted/TrackUnmuted events). Best-effort here.
///   - `isSpeaking`   : `false` at join; updated from ActiveSpeakersChangedEvent.
///   - `avatar`       : `''`        — LiveKit doesn't carry it. A3 reconciles.
///   - `joinedAt`     : `DateTime.now()` at join event. A3 reconciles.
///   - `isHandRaised` : `false`     — purely an app-level flag. A3 reconciles.
class VoiceRoomLiveKitManager {
  VoiceRoomLiveKitManager({LiveKitService? livekit})
      : _livekit = livekit ?? LiveKitService();

  final LiveKitService _livekit;
  lk.EventsListener<lk.RoomEvent>? _listener;

  /// Identities of participants we've most recently observed as actively
  /// speaking, so we can diff against the next ActiveSpeakersChangedEvent
  /// and only emit deltas (start/stop) rather than the full set every tick.
  final Set<String> _activeSpeakers = <String>{};

  // -- Callbacks ------------------------------------------------------------

  void Function(RoomParticipant participant)? onParticipantJoined;
  void Function(String participantId)? onParticipantLeft;
  void Function(String participantId, bool isSpeaking)?
      onParticipantSpeakingChanged;
  void Function(String participantId, bool isMuted)? onParticipantMuteChanged;
  void Function()? onRoomReconnecting;
  void Function()? onRoomReconnected;
  void Function()? onRoomDisconnected;

  // -- Getters --------------------------------------------------------------

  lk.Room? get room => _livekit.room;
  bool get isConnected => _livekit.isConnected;

  // -- API ------------------------------------------------------------------

  /// Mint a join token for [roomId] and connect to LiveKit muted.
  ///
  /// The token endpoint returns `{ success, data: { token, url, roomName,
  /// role } }`. `ApiClient` unwraps `data` for us.
  Future<void> connect({required String roomId}) async {
    final res = await ApiClient().post('voicerooms/$roomId/token');
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Failed to fetch voice room token');
    }
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    final url = data['url'] as String?;
    if (token == null || url == null) {
      throw StateError('Malformed voice room token response: $data');
    }

    await _livekit.connect(
      url: url,
      token: token,
      // Start muted: users opt-in to speak (raise-hand / unmute UI in A3+).
      enableMicrophone: false,
      enableCamera: false,
    );

    _wireRoomEvents();
  }

  /// Tear down the listener and disconnect.
  Future<void> disconnect() async {
    await _listener?.dispose();
    _listener = null;
    _activeSpeakers.clear();
    await _livekit.disconnect();
  }

  /// Toggle the local microphone. [muted] == true mutes; false unmutes.
  Future<void> setMuted(bool muted) async {
    await _livekit.setMicrophoneEnabled(!muted);
  }

  // -- Internal -------------------------------------------------------------

  void _wireRoomEvents() {
    final r = _livekit.room;
    if (r == null) {
      debugPrint('VoiceRoomLiveKitManager: room null after connect, skipping wire');
      return;
    }

    final l = r.createListener();
    _listener = l;

    l.on<lk.ParticipantConnectedEvent>((event) {
      onParticipantJoined?.call(_toRoomParticipant(event.participant));
    });

    l.on<lk.ParticipantDisconnectedEvent>((event) {
      onParticipantLeft?.call(event.participant.identity);
    });

    l.on<lk.ActiveSpeakersChangedEvent>((event) {
      final nowSpeaking = event.speakers.map((p) => p.identity).toSet();
      // Stopped speaking = was in old set, not in new.
      for (final id in _activeSpeakers.difference(nowSpeaking)) {
        onParticipantSpeakingChanged?.call(id, false);
      }
      // Started speaking = in new set, not in old.
      for (final id in nowSpeaking.difference(_activeSpeakers)) {
        onParticipantSpeakingChanged?.call(id, true);
      }
      _activeSpeakers
        ..clear()
        ..addAll(nowSpeaking);
    });

    l.on<lk.TrackMutedEvent>((event) {
      if (event.publication.kind == lk.TrackType.AUDIO) {
        onParticipantMuteChanged?.call(event.participant.identity, true);
      }
    });

    l.on<lk.TrackUnmutedEvent>((event) {
      if (event.publication.kind == lk.TrackType.AUDIO) {
        onParticipantMuteChanged?.call(event.participant.identity, false);
      }
    });

    l.on<lk.RoomReconnectingEvent>((_) => onRoomReconnecting?.call());
    l.on<lk.RoomReconnectedEvent>((_) => onRoomReconnected?.call());
    l.on<lk.RoomDisconnectedEvent>((_) => onRoomDisconnected?.call());
  }

  RoomParticipant _toRoomParticipant(lk.Participant p) {
    final isHost = _roleFromMetadata(p.metadata) == 'host';
    return RoomParticipant(
      id: p.identity,
      name: p.name,
      avatar: '', // Not in LiveKit; A3 reconciles from Mongo room data.
      isSpeaking: false, // Updated by ActiveSpeakersChangedEvent.
      isMuted: true, // We mint join tokens muted; refined on Track(Un)MutedEvent.
      isHost: isHost,
      joinedAt: DateTime.now(), // Approximate; A3 reconciles from join API.
      isHandRaised: false, // App-level flag; A3 reconciles.
    );
  }

  /// LiveKit `metadata` is an opaque string we set server-side to a JSON
  /// blob like `{"role":"host"}`. Defaults to `'participant'` on missing /
  /// malformed input.
  String _roleFromMetadata(String? metadata) {
    if (metadata == null || metadata.isEmpty) return 'participant';
    try {
      final decoded = jsonDecode(metadata);
      if (decoded is Map<String, dynamic>) {
        final role = decoded['role'];
        if (role is String && role.isNotEmpty) return role;
      }
    } catch (_) {
      // Malformed metadata — fall through to default.
    }
    return 'participant';
  }
}
