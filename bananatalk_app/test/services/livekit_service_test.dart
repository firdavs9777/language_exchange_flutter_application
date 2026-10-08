import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

import 'package:bananatalk_app/services/livekit_service.dart';

/// A Room that records what the service does with it; connect waits on [gate].
class _FakeRoom implements Room {
  final Completer<void> gate = Completer<void>();
  int disconnects = 0;
  int disposes = 0;
  int localParticipantReads = 0;

  @override
  Future<void> connect(String url, String token,
      {ConnectOptions? connectOptions, RoomOptions? roomOptions, FastConnectOptions? fastConnectOptions}) =>
      gate.future;

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  Future<bool> dispose() async {
    disposes++;
    return true;
  }

  @override
  LocalParticipant? get localParticipant {
    localParticipantReads++;
    return null;
  }

  @override
  ConnectionState get connectionState => ConnectionState.connected;

  @override
  UnmodifiableMapView<String, RemoteParticipant> get remoteParticipants => UnmodifiableMapView({});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a disconnect while connecting wins: no mic / camera on the stale room, and it is disposed', () async {
    final rooms = <_FakeRoom>[];
    final service = LiveKitService(roomFactory: () {
      final r = _FakeRoom();
      rooms.add(r);
      return r;
    });
    final connecting = service.connect(url: 'wss://lk.test', token: 't', enableCamera: true);
    await pumpEventQueue();
    await service.disconnect();
    rooms.single.gate.complete();
    await connecting;
    expect(rooms.single.localParticipantReads, 0, reason: 'mic/camera must not be enabled');
    expect(service.room, isNull);
    expect(rooms.single.disposes, greaterThanOrEqualTo(1));
  });

  test('a normal connect enables the microphone on its room', () async {
    final room = _FakeRoom()..gate.complete();
    final service = LiveKitService(roomFactory: () => room);
    await service.connect(url: 'wss://lk.test', token: 't');
    expect(room.localParticipantReads, greaterThan(0));
    expect(identical(service.room, room), isTrue);
  });
}
