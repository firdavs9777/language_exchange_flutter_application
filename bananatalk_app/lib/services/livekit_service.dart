import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import 'api_client.dart';

/// Thin wrapper around `livekit_client`'s [Room].
///
/// Provides:
///   - [fetchTestToken] — calls our backend's `/livekit/test-token` smoke endpoint
///   - [connect]        — joins a room with audio (and optionally video)
///   - [disconnect]     — leaves the room and disposes the [Room]
///   - [setMicrophoneEnabled] / [setCameraEnabled] — track toggles
///
/// The real production flow will mint tokens against feature-specific endpoints
/// (e.g. `/voice-rooms/:id/token`, `/calls/:roomName/token`); this service is
/// intentionally minimal so the smoke test can prove the pipe end-to-end first.
class LiveKitService {
  Room? _room;
  Room? get room => _room;

  bool get isConnected =>
      _room != null && _room!.connectionState == ConnectionState.connected;

  /// POST /livekit/test-token — returns `{token, url, roomName}`.
  Future<LiveKitTokenResult> fetchTestToken({String? roomName}) async {
    debugPrint('[LK] fetchTestToken roomName=$roomName');
    final res = await ApiClient().post(
      'livekit/test-token',
      body: roomName != null ? {'roomName': roomName} : null,
    );
    if (!res.success || res.data == null) {
      debugPrint('[LK] fetchTestToken FAILED: ${res.error}');
      throw StateError(res.error ?? 'failed to fetch LiveKit token');
    }
    final data = res.data as Map<String, dynamic>;
    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    debugPrint(
      '[LK] fetchTestToken OK room=${payload['roomName']} url=${payload['url']}',
    );
    return LiveKitTokenResult(
      token: payload['token'] as String,
      url: payload['url'] as String,
      roomName: payload['roomName'] as String,
    );
  }

  Future<void> connect({
    required String url,
    required String token,
    bool enableMicrophone = true,
    bool enableCamera = false,
  }) async {
    debugPrint(
      '[LK] connect url=$url mic=$enableMicrophone cam=$enableCamera',
    );
    if (_room != null) {
      debugPrint('[LK] connect: existing room found, disconnecting first');
      await disconnect();
    }

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    _room = room;

    try {
      await room.connect(
        url,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );
      debugPrint(
        '[LK] connected: state=${room.connectionState} '
        'localId=${room.localParticipant?.identity} '
        'remotes=${room.remoteParticipants.length}',
      );

      await room.localParticipant?.setMicrophoneEnabled(enableMicrophone);
      if (enableCamera) {
        await room.localParticipant?.setCameraEnabled(true);
      }
      debugPrint(
        '[LK] tracks published: mic=$enableMicrophone cam=$enableCamera',
      );
    } catch (e, st) {
      debugPrint('[LK] connect FAILED: $e\n$st');
      _room = null;
      rethrow;
    }
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    debugPrint('[LK] setMicrophoneEnabled=$enabled');
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> setCameraEnabled(bool enabled) async {
    debugPrint('[LK] setCameraEnabled=$enabled');
    await _room?.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> disconnect() async {
    debugPrint('[LK] disconnect (room was ${_room == null ? "null" : "set"})');
    final r = _room;
    _room = null;
    try {
      await r?.disconnect();
      await r?.dispose();
    } catch (e) {
      debugPrint('[LK] disconnect error: $e');
    }
  }
}

class LiveKitTokenResult {
  const LiveKitTokenResult({
    required this.token,
    required this.url,
    required this.roomName,
  });

  final String token;
  final String url;
  final String roomName;
}
