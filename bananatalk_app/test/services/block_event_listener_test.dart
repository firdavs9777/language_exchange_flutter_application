import 'dart:async';

import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/blocked_ids_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `BlockService.blockedUserIds` is a sync broadcast stream fired before the
/// local cleanup. A listener that throws must not break the block: its error
/// goes to the listener's zone, not out of the event `add`.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {'userId': 'me', 'token': 't'}));

  test('a throwing block-event listener does not break the block', () async {
    final zoneErrors = <Object>[];
    final seen = <String>[];
    late StreamSubscription<String> bad;
    late StreamSubscription<String> good;
    runZonedGuarded(() {
      bad = BlockService.blockedUserIds.listen((_) => throw StateError('boom'));
    }, (e, _) => zoneErrors.add(e));
    good = BlockService.blockedUserIds.listen(seen.add);
    addTearDown(() async {
      await bad.cancel();
      await good.cancel();
    });

    final result = await http.runWithClient(
      () => BlockService.blockUser(
        currentUserId: 'me',
        blockedUserId: 'x',
        blockedUserName: 'X',
      ),
      () => MockClient((req) async => http.Response('{}', 200)),
    );

    expect(result['success'], isTrue);
    expect(zoneErrors.single, isA<StateError>());
    // The other listener and the local cleanup after the event still ran.
    expect(seen, ['x']);
    expect(await BlockedIdsStore().read(userId: 'me'), contains('x'));
  });
}
