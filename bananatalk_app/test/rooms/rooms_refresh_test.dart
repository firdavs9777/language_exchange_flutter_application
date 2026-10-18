import 'dart:async';

import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/services/room_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRooms extends RoomApiClient {
  _FakeRooms(this.answers);
  final List<Future<List<Room>> Function()> answers;
  int calls = 0;
  @override
  Future<List<Room>> getRooms() => answers[calls++]();
}

Room _room(String id, {int members = 0}) =>
    Room.fromJson({'_id': id, 'title': id, 'memberCount': members});

void main() {
  test('a refresh keeps the shown rooms on screen until the new list arrives', () async {
    final second = Completer<List<Room>>();
    final api = _FakeRooms([
      () async => [_room('a')],
      () => second.future,
    ]);
    final notifier = RoomsNotifier(api);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.debugState.valueOrNull?.single.id, 'a');

    final pending = notifier.refresh();
    expect(notifier.debugState.hasValue, isTrue, reason: 'no skeleton while refreshing');
    second.complete([_room('a', members: 3), _room('b')]);
    await pending;
    expect(notifier.debugState.valueOrNull?.length, 2);
    expect(notifier.debugState.valueOrNull?.first.memberCount, 3);
  });

  test('a failed refresh keeps the rooms already shown', () async {
    final api = _FakeRooms([
      () async => [_room('a')],
      () async => throw Exception('offline'),
    ]);
    final notifier = RoomsNotifier(api);
    await Future<void>.delayed(Duration.zero);
    await notifier.refresh();
    expect(notifier.debugState.valueOrNull?.single.id, 'a');
  });
}
