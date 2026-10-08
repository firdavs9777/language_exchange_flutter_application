import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("logout mid-upload: the next step never runs as the next account",
      () async {
    SharedPreferences.setMockInitialValues({'token': 'A-token'});
    final dir = await Directory.systemTemp.createTemp('upl');
    final photo = File('${dir.path}/p.jpg')..writeAsBytesSync([1, 2, 3]);

    final createStarted = Completer<void>();
    final releaseCreate = Completer<void>();
    final authHeaders = <String>[];
    final queue = UploadQueueService();

    await http.runWithClient(() async {
      await queue.queueMomentUpload(
          description: 'hi', imagePaths: [photo.path]);
      await createStarted.future;

      // User A logs out while "create moment" is on the wire; user B signs in.
      await queue.endSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'B-token');

      releaseCreate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }, () => MockClient((req) async {
          authHeaders.add(req.headers['Authorization'] ?? '');
          if (!createStarted.isCompleted) createStarted.complete();
          await releaseCreate.future;
          return http.Response(
              jsonEncode({'success': true, 'data': {'_id': 'm1'}}), 201);
        }));

    // THE BUG: the photo step read the token fresh and ran as user B.
    expect(authHeaders, ['Bearer A-token']);
    expect(queue.tasks, isEmpty,
        reason: "A's task must not survive into B's queue");
    expect(queue.sessionGenerationForTest, greaterThan(0));
    await dir.delete(recursive: true);
  });

  test('session teardown ends running activities while still authenticated',
      () async {
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    String? tokenSeen;
    AuthService.onSessionEnding = () async {
      tokenSeen = (await SharedPreferences.getInstance()).getString('token');
    };
    addTearDown(() => AuthService.onSessionEnding = null);

    await AuthService().clearLocalSession();

    expect(tokenSeen, 'jwt', reason: 'end-call/leave-room need the token');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), isNull);
  });
}
