import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';

/// A retry of a moment upload must re-run only the step that failed.
///
/// The bug: `_uploadMoment` / `_uploadMomentWithVideo` called createMoments
/// every time the task ran, so a photo or video step that failed and was
/// retried created a second (caption-only) moment per retry.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late UploadQueueService queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    dir = await Directory.systemTemp.createTemp('upl-retry');
    queue = UploadQueueService();
    await queue.endSession(); // the service is a singleton: start clean
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

  http.Response created() => http.Response(
      jsonEncode({
        'success': true,
        'data': {'_id': 'm1', 'description': 'hi'},
      }),
      201);
  http.Response ok() =>
      http.Response(jsonEncode({'success': true, 'data': {}}), 200);
  http.Response boom() =>
      http.Response(jsonEncode({'success': false, 'error': 'boom'}), 500);

  bool isCreate(http.BaseRequest r) =>
      r.method == 'POST' && r.url.path.endsWith('/moments');

  test('a failed photo step retried does NOT create a second moment',
      () async {
    final photo = File('${dir.path}/p.jpg')..writeAsBytesSync([1, 2, 3]);
    final calls = <String>[];
    var photoAttempts = 0;

    late UploadTask done;
    await http.runWithClient(() async {
      final id = await queue.queueMomentUpload(
          description: 'hi', imagePaths: [photo.path]);
      done = await settle(id);
    }, () => MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          if (isCreate(req)) return created();
          if (req.url.path.endsWith('/m1/photo')) {
            return ++photoAttempts == 1 ? boom() : ok();
          }
          return ok();
        }));

    expect(calls.where((c) => c.startsWith('POST')).length, 1,
        reason: 'the retry re-ran create: $calls');
    expect(photoAttempts, 2);
    expect(done.status, UploadStatus.completed);
    expect(done.resultId, 'm1');
  });

  test('a failed video step retried does NOT create a second moment',
      () async {
    final video = File('${dir.path}/v.mp4')..writeAsBytesSync([1, 2, 3, 4]);
    final calls = <String>[];
    var videoAttempts = 0;

    late UploadTask done;
    await http.runWithClient(() async {
      final id = await queue.queueMomentUpload(
          description: '', videoPath: video.path, isReel: true);
      done = await settle(id);
    }, () => MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          if (isCreate(req)) return created();
          if (req.url.path.endsWith('/m1/video')) {
            return ++videoAttempts < 3 ? boom() : ok();
          }
          return ok();
        }));

    expect(calls.where((c) => c.startsWith('POST')).length, 1,
        reason: 'the retry re-ran create: $calls');
    expect(videoAttempts, 3);
    expect(done.status, UploadStatus.completed);
    expect(calls.any((c) => c.startsWith('DELETE')), isFalse);
  });

  test('when the media step finally fails, the half-made moment is deleted',
      () async {
    final photo = File('${dir.path}/p.jpg')..writeAsBytesSync([1, 2, 3]);
    final calls = <String>[];

    late UploadTask done;
    await http.runWithClient(() async {
      final id = await queue.queueMomentUpload(
          description: 'hi', imagePaths: [photo.path]);
      done = await settle(id);
    }, () => MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          if (isCreate(req)) return created();
          if (req.url.path.endsWith('/m1/photo')) return boom();
          return ok();
        }));

    expect(done.status, UploadStatus.failed);
    expect(calls.where((c) => c.startsWith('POST')).length, 1);
    expect(
        calls.where((c) => c.startsWith('DELETE') && c.endsWith('/moments/m1')),
        hasLength(1),
        reason: 'no caption-only orphan may stay in the feed: $calls');
    expect(done.metadata[kCreatedMomentIdKey], isNull,
        reason: 'a manual retry after rollback must create afresh');
  });

  test('a bad photo is refused before any moment is created', () async {
    final heic = File('${dir.path}/p.heic')..writeAsBytesSync([1, 2, 3]);
    final calls = <String>[];

    late UploadTask done;
    await http.runWithClient(() async {
      final id = await queue.queueMomentUpload(
          description: 'hi', imagePaths: [heic.path]);
      done = await settle(id);
    }, () => MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          return created();
        }));

    expect(done.status, UploadStatus.failed);
    expect(calls, isEmpty, reason: 'nothing should hit the server: $calls');
  });
}
