import 'dart:convert';

import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/services/room_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A failed GET /rooms used to come back as [] — "No rooms", no retry.
/// (ApiClient keeps its http client across tests, so every test here uses
/// the same failing server.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'jwt'}));

  Future<T> withServer<T>(int status, Future<T> Function() body) =>
      http.runWithClient(
        body,
        () => MockClient((_) async => http.Response(
            jsonEncode({'success': false, 'error': 'boom'}),
            status)),
      );

  test('a server error is thrown, not an empty directory', () async {
    await expectLater(
      withServer(500, () => RoomApiClient().getRooms()),
      throwsA(isA<Exception>()),
    );
  });

  test('the first load failing shows the error state', () async {
    late RoomsNotifier notifier;
    await withServer(500, () async {
      notifier = RoomsNotifier(RoomApiClient());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(notifier.debugState, isA<AsyncError<List<Room>>>());
  });
}
