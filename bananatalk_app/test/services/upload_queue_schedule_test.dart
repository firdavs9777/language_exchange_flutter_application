import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';

/// A scheduled video moment goes through the background queue; the chosen
/// time must reach the create request, or the moment posts at once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late UploadQueueService queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    dir = await Directory.systemTemp.createTemp('upl-schedule');
    queue = UploadQueueService();
    await queue.endSession();
    UploadQueueService.retryDelay = (_) => Duration.zero;
  });

  tearDown(() async {
    await queue.endSession();
    UploadQueueService.retryDelay = UploadQueueService.defaultRetryDelay;
    await dir.delete(recursive: true);
  });

  Future<UploadTask> settle(String taskId) async {
    for (var i = 0; i < 400; i++) {
      final task = queue.tasks.firstWhere((t) => t.id == taskId);
      if (task.status == UploadStatus.completed ||
          task.status == UploadStatus.failed) {
        return task;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('task never settled');
  }

  Future<Object?> createBodyScheduledFor({String? scheduledFor}) async {
    final video = File('${dir.path}/v.mp4')..writeAsBytesSync([1, 2, 3, 4]);
    Object? sent = 'not sent';
    await http.runWithClient(() async {
      final id = await queue.queueMomentUpload(
        description: 'later',
        videoPath: video.path,
        scheduledFor: scheduledFor,
      );
      await settle(id);
    }, () => MockClient((req) async {
          if (req.method == 'POST' && req.url.path.endsWith('/moments')) {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            sent = body['scheduledFor'];
            return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {'_id': 'm1', 'description': 'later'},
                }),
                201);
          }
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }));
    return sent;
  }

  test('the scheduled time reaches the create request', () async {
    expect(
      await createBodyScheduledFor(scheduledFor: '2026-11-01T09:00:00.000Z'),
      '2026-11-01T09:00:00.000Z',
    );
  });

  test('no schedule: nothing scheduled is sent', () async {
    expect(await createBodyScheduledFor(), isNull);
  });
}
