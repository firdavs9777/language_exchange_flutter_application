import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/story_upload_payload.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';

/// A queued story must never be lost and never be posted twice.
///
/// No test touches the network or real waiting: the poster, the clock, the
/// retry timers, the documents directory and connectivity are all injected.
class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);
  final Duration duration;
  final void Function() callback;
  bool cancelled = false;
  bool fired = false;

  @override
  bool get isActive => !cancelled && !fired;
  @override
  int get tick => fired ? 1 : 0;
  @override
  void cancel() => cancelled = true;
}

class _Call {
  _Call(this.payload, this.key);
  final StoryUploadPayload payload;
  final String key;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late Directory src;
  late UploadQueueService queue;
  late DateTime now;
  late List<_FakeTimer> timers;
  late List<_Call> calls;
  late StreamController<List<ConnectivityResult>> connectivity;

  /// What the fake server answers next; the last one repeats.
  late List<FutureOr<SingleStoryResponse> Function()> answers;

  SingleStoryResponse ok([String id = 's1']) => SingleStoryResponse(
      success: true,
      data: Story.fromJson({
        '_id': id,
        'user': {'_id': 'u1', 'name': 'me'},
        'mediaType': 'image',
      }));
  SingleStoryResponse fail([String error = 'boom']) =>
      SingleStoryResponse(success: false, error: error);
  SingleStoryResponse withFailure(StoryPostFailure f) =>
      SingleStoryResponse(success: false, failure: f, error: 'x');
  SingleStoryResponse limit() =>
      SingleStoryResponse(success: false, limitReached: true, error: 'limit');

  setUp(() async {
    SharedPreferences.setMockInitialValues({'token': 'jwt', 'userId': 'u1'});
    docs = await Directory.systemTemp.createTemp('story-docs');
    src = await Directory.systemTemp.createTemp('story-src');
    now = DateTime.utc(2026, 11, 13, 12);
    timers = [];
    calls = [];
    answers = [() => ok()];
    connectivity = StreamController<List<ConnectivityResult>>.broadcast();

    UploadQueueService.documentsDirectory = () async => docs;
    UploadQueueService.clock = () => now;
    UploadQueueService.startTimer = (d, cb) {
      final t = _FakeTimer(d, cb);
      timers.add(t);
      return t;
    };
    UploadQueueService.connectivityChanges = () => connectivity.stream;
    UploadQueueService.storyPoster = (payload, key) async {
      calls.add(_Call(payload, key));
      final answer =
          answers.length > 1 ? answers.removeAt(0) : answers.single;
      return answer();
    };
    UploadQueueService.retryDelay = (_) => Duration.zero;

    queue = UploadQueueService();
    await queue.endSession(); // singleton: start clean
    timers.clear();
  });

  tearDown(() async {
    await queue.endSession();
    UploadQueueService.resetStorySeamsForTest();
    UploadQueueService.retryDelay = UploadQueueService.defaultRetryDelay;
    await connectivity.close();
    await docs.delete(recursive: true);
    await src.delete(recursive: true);
  });

  File source([String name = 'pic.jpg']) =>
      File('${src.path}/$name')..writeAsBytesSync([1, 2, 3, 4]);

  UploadTask? taskOf(String id) {
    for (final t in queue.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Real-time poll until [done]; the queue does real file I/O.
  Future<void> until(bool Function() done, [String what = 'condition']) async {
    for (var i = 0; i < 500; i++) {
      if (done()) {
        // Let the post-attempt bookkeeping (save, notify) finish.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('never reached: $what');
  }

  List<_FakeTimer> active() => timers.where((t) => t.isActive).toList();

  /// Waits until the task is idle: settled, or waiting on a retry timer.
  Future<UploadTask?> idle(String id) async {
    await until(() {
      final t = taskOf(id);
      if (t == null) return true;
      if (t.status == UploadStatus.completed ||
          t.status == UploadStatus.failed ||
          t.status == UploadStatus.cancelled) {
        return true;
      }
      return t.status == UploadStatus.queued && active().isNotEmpty;
    }, 'task $id idle');
    return taskOf(id);
  }

  /// Advances the fake clock to the pending retry and fires it.
  Future<Duration> fireRetry(String id) async {
    final pending = active();
    expect(pending, hasLength(1), reason: 'one wake-up timer at a time');
    final t = pending.single;
    now = now.add(t.duration);
    t.fired = true;
    final before = calls.length;
    t.callback();
    await until(() => calls.length > before, 'retry attempt');
    await idle(id);
    return t.duration;
  }

  StoryUploadPayload photo({String? owner}) => StoryUploadPayload(
        mediaPath: source().path,
        text: 'cap',
        backgroundColor: '#000000',
        privacy: StoryPrivacy.friends,
        quizSticker: const StoryQuizSticker(
          question: 'q',
          options: [
            StoryQuizOption(index: 0, text: 'a'),
            StoryQuizOption(index: 1, text: 'b'),
          ],
          correctIndex: 1,
        ),
        overlays: const [
          {'type': 'text', 'content': 'hi'},
        ],
        ownerUserId: owner,
      );

  Directory uploadsDir() => Directory('${docs.path}/story_uploads');

  group('queueing', () {
    test('the media is a private copy that survives deleting the source',
        () async {
      final p = photo();
      answers = [() => fail(), () => ok()];
      final id = await queue.queueStoryUpload(p);

      final task = taskOf(id)!;
      final copy = File('${uploadsDir().path}/$id.jpg');
      expect(task.isStory, isTrue);
      expect(task.type, UploadType.story);
      expect(task.localFilePath, copy.path);
      expect(task.metadata['mediaPath'], copy.path);
      expect(task.metadata['ownerUserId'], 'u1',
          reason: 'stamped from the signed-in user');

      await idle(id);
      File(p.mediaPath!).deleteSync(); // gallery file / cache cleared
      expect(copy.existsSync(), isTrue);

      await fireRetry(id);
      expect(taskOf(id)!.status, UploadStatus.completed);
      expect(calls.last.payload.mediaPath, copy.path);
      expect(calls.last.payload.quizSticker!.toCreateJson(),
          p.quizSticker!.toCreateJson());
      expect(copy.existsSync(), isFalse, reason: 'success deletes the copy');
    });

    test('a video keeps its extension, so it is sent as a video', () async {
      final v = source('clip.mp4');
      final id = await queue.queueStoryUpload(
          StoryUploadPayload(mediaPath: v.path, isVideo: true));
      expect(taskOf(id)!.type, UploadType.storyVideo);
      expect(taskOf(id)!.localFilePath, endsWith('/story_uploads/$id.mp4'));
      await idle(id);
      expect(calls.single.payload.mediaPath, endsWith('$id.mp4'));
    });

    test('a failed copy queues nothing and throws', () async {
      final missing = '${src.path}/gone.jpg';
      await expectLater(
        queue.queueStoryUpload(StoryUploadPayload(mediaPath: missing)),
        throwsA(isA<StoryUploadQueueException>()),
      );
      expect(queue.tasks, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('upload_queue_tasks');
      expect(stored == null || (jsonDecode(stored) as List).isEmpty, isTrue);
      expect(calls, isEmpty);
    });

    test('a text story has no file and goes through as text', () async {
      final id = await queue.queueStoryUpload(const StoryUploadPayload(
          text: 'hello', backgroundColor: 'sunset'));
      final t = await idle(id);
      expect(t!.status, UploadStatus.completed);
      expect(calls.single.payload.isTextStory, isTrue);
      expect(calls.single.payload.text, 'hello');
      expect(uploadsDir().existsSync() ? uploadsDir().listSync() : const [],
          isEmpty);
    });

    test('the old five-parameter call still works', () async {
      final f = source();
      final id = await queue.queueSimpleStoryUpload(
        mediaPath: f.path,
        text: 'old',
        backgroundColor: '#123456',
        privacy: StoryPrivacy.closeFriends,
      );
      final t = await idle(id);
      expect(t!.status, UploadStatus.completed);
      final sent = calls.single.payload;
      expect(sent.text, 'old');
      expect(sent.backgroundColor, '#123456');
      expect(sent.privacy, StoryPrivacy.closeFriends);
      expect(calls.single.key, id);
    });
  });

  group('idempotency', () {
    test('the key is the task id on every attempt, including a manual retry',
        () async {
      answers = [for (var i = 0; i < 6; i++) () => fail(), () => ok()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      for (var i = 0; i < 5; i++) {
        await fireRetry(id);
      }
      expect(taskOf(id)!.status, UploadStatus.failed);

      await queue.retryUpload(id);
      final t = await idle(id);
      expect(t!.status, UploadStatus.completed);
      expect(calls, hasLength(7));
      expect(calls.map((c) => c.key).toSet(), {id});
    });
  });

  group('outcomes', () {
    test('ordinary failures retry after 5 s, 15 s, 45 s, 2 min, 5 min, then fail',
        () async {
      answers = [() => fail()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      final delays = <Duration>[];
      for (var i = 0; i < 5; i++) {
        delays.add(await fireRetry(id));
      }
      expect(delays, const [
        Duration(seconds: 5),
        Duration(seconds: 15),
        Duration(seconds: 45),
        Duration(minutes: 2),
        Duration(minutes: 5),
      ]);
      final t = taskOf(id)!;
      expect(t.status, UploadStatus.failed);
      expect(t.storyFailure, StoryUploadFailure.failed);
      expect(calls, hasLength(6));
      expect(active(), isEmpty, reason: 'failed waits for the user');
      expect(File(t.localFilePath).existsSync(), isTrue,
          reason: 'the copy is kept for a manual retry');
    });

    test('"in progress" backs off 30 s, 2 min, 5 min, 10 min without using an attempt',
        () async {
      answers = [
        for (var i = 0; i < 5; i++) () => withFailure(StoryPostFailure.inProgress),
        () => ok(),
      ];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      final delays = <Duration>[];
      for (var i = 0; i < 5; i++) {
        delays.add(await fireRetry(id));
      }
      expect(delays, const [
        Duration(seconds: 30),
        Duration(minutes: 2),
        Duration(minutes: 5),
        Duration(minutes: 10),
        Duration(minutes: 10),
      ]);
      final t = taskOf(id)!;
      expect(t.status, UploadStatus.completed);
      expect(t.retryCount, 0, reason: 'in progress never consumes an attempt');
    });

    test('"in progress" gives up as failed after 30 minutes', () async {
      answers = [() => withFailure(StoryPostFailure.inProgress)];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      final start = now;
      final delays = <Duration>[];
      while (taskOf(id)!.status != UploadStatus.failed) {
        expect(now.difference(start), lessThan(const Duration(minutes: 30)),
            reason: 'still trying at 30 min');
        delays.add(await fireRetry(id));
        expect(calls.length, lessThan(20));
      }
      // Looks at 0, 0.5, 2.5, 7.5, 17.5, 27.5 and finally exactly 30 min.
      expect(delays, const [
        Duration(seconds: 30),
        Duration(minutes: 2),
        Duration(minutes: 5),
        Duration(minutes: 10),
        Duration(minutes: 10),
        Duration(minutes: 2, seconds: 30),
      ]);
      expect(now.difference(start), const Duration(minutes: 30),
          reason: 'fails at the 30-minute mark, not up to 10 min later');
      expect(taskOf(id)!.storyFailure, StoryUploadFailure.failed);
      expect(active(), isEmpty);
    });

    test('503 retries after 30 s up to 5 times in a row, then counts as a failure',
        () async {
      answers = [
        for (var i = 0; i < 6; i++) () => withFailure(StoryPostFailure.tryAgain),
        () => ok(),
      ];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      final delays = <Duration>[];
      for (var i = 0; i < 6; i++) {
        delays.add(await fireRetry(id));
        if (i < 4) expect(taskOf(id)!.retryCount, 0);
      }
      expect(delays.take(5), everyElement(const Duration(seconds: 30)));
      expect(delays.last, const Duration(seconds: 5),
          reason: 'the sixth 503 in a row is an ordinary failure');
      final t = taskOf(id)!;
      expect(t.status, UploadStatus.completed);
      expect(t.retryCount, 1);
    });

    test('the daily limit fails at once with no automatic retry', () async {
      answers = [() => limit()];
      final id = await queue.queueStoryUpload(photo());
      final t = await idle(id);
      expect(t!.status, UploadStatus.failed);
      expect(t.storyFailure, StoryUploadFailure.limitReached);
      expect(active(), isEmpty);

      connectivity.add([ConnectivityResult.none]);
      connectivity.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, hasLength(1), reason: 'reconnecting does not retry a 429');
    });

    test('"already posted" completes, leaves the queue and deletes the copy',
        () async {
      answers = [() => withFailure(StoryPostFailure.alreadyPosted)];
      final posted = <String>[];
      final sub = queue.storyPostedStream.listen(posted.add);
      final id = await queue.queueStoryUpload(photo());
      final copy = File(taskOf(id)!.localFilePath);
      await until(() => taskOf(id) == null, 'removed');
      expect(copy.existsSync(), isFalse);
      expect(active(), isEmpty);
      expect(posted, [id]);
      await sub.cancel();
    });

    test('success reports the story once on the posted stream', () async {
      final posted = <String>[];
      final sub = queue.storyPostedStream.listen(posted.add);
      final id = await queue.queueStoryUpload(photo());
      final t = await idle(id);
      expect(t!.status, UploadStatus.completed);
      expect(t.resultId, 's1');
      await Future<void>.delayed(Duration.zero);
      expect(posted, [id]);
      await sub.cancel();
    });

    test('a hung attempt times out and is retried like a failure', () async {
      UploadQueueService.storyAttemptTimeout =
          const Duration(milliseconds: 30);
      final never = Completer<SingleStoryResponse>();
      answers = [() => never.future, () => ok()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      expect(taskOf(id)!.status, UploadStatus.queued);
      expect(active().single.duration, const Duration(seconds: 5));
      await fireRetry(id);
      expect(taskOf(id)!.status, UploadStatus.completed);
      expect(calls.map((c) => c.key).toSet(), {id});
    });
  });

  group('restart and ownership', () {
    Future<void> store(List<Map<String, dynamic>> tasks,
        {String userId = 'u1'}) async {
      SharedPreferences.setMockInitialValues({
        'token': 'jwt',
        'userId': userId,
        'upload_queue_tasks': jsonEncode(tasks),
      });
    }

    test("today's five-field story task and a moment task still upload",
        () async {
      final f = source('old.jpg');
      await store([
        {
          'id': 'legacy-story',
          'type': 'story',
          'localFilePath': f.path,
          'metadata': {
            'mediaPath': f.path,
            'isVideo': false,
            'text': 'from 2.x',
            'backgroundColor': '#000000',
            'privacy': 'friends',
          },
          'status': 'uploading',
          'progress': 0.1,
          'createdAt': '2026-11-13T11:00:00.000',
          'completedAt': null,
          'error': null,
          'resultId': null,
          'retryCount': 0,
        },
        {
          'id': 'legacy-moment',
          'type': 'moment',
          'localFilePath': '',
          'metadata': {
            'description': 'hello',
            'privacy': 'public',
            'category': 'general',
            'language': 'en',
            'mood': null,
            'tags': null,
            'location': null,
            'imagePaths': null,
            'videoPath': null,
            'backgroundColor': null,
            'promptId': null,
            'isReel': false,
            'scheduledFor': null,
          },
          'status': 'queued',
          'progress': 0.0,
          'createdAt': '2026-11-13T11:00:00.000',
          'completedAt': null,
          'error': null,
          'resultId': null,
          'retryCount': 0,
        },
      ]);
      final momentCreates = <String>[];
      await http.runWithClient(() async {
        await queue.initialize();
        await until(
            () =>
                taskOf('legacy-story')?.status == UploadStatus.completed &&
                taskOf('legacy-moment')?.status == UploadStatus.completed,
            'both legacy tasks completed');
      }, () => MockClient((req) async {
            momentCreates.add('${req.method} ${req.url.path}');
            return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {'_id': 'm1', 'description': 'hello'},
                }),
                201);
          }));

      final sent = calls.single;
      expect(sent.key, 'legacy-story');
      expect(sent.payload.mediaPath, f.path);
      expect(sent.payload.text, 'from 2.x');
      expect(sent.payload.backgroundColor, '#000000');
      expect(sent.payload.privacy, StoryPrivacy.friends);
      expect(momentCreates.where((c) => c.startsWith('POST')), hasLength(1));
    });

    test('a persisted story resumes after a restart with the same key',
        () async {
      final id = await queue.queueStoryUpload(photo());
      // Simulate a kill mid-upload: what is on disk is the queue state.
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('upload_queue_tasks')!;
      final tasks = (jsonDecode(saved) as List).cast<Map<String, dynamic>>();
      final mine = tasks.firstWhere((t) => t['id'] == id);
      mine['status'] = 'uploading';
      await idle(id);
      calls.clear();
      SharedPreferences.setMockInitialValues({
        'token': 'jwt',
        'userId': 'u1',
        'upload_queue_tasks': jsonEncode([mine]),
      });
      // The copy was deleted by that first success; put it back as it was.
      File(mine['localFilePath'] as String)
        ..createSync(recursive: true)
        ..writeAsBytesSync([9]);

      await queue.initialize();
      await until(() => taskOf(id)?.status == UploadStatus.completed,
          'resumed upload completed');
      expect(calls.single.key, id);
      expect(calls.single.payload.ownerUserId, 'u1');
    });

    test('a waiting retry survives a restart and is honoured', () async {
      answers = [() => fail(), () => ok()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('upload_queue_tasks')!;
      calls.clear();
      timers.clear();
      SharedPreferences.setMockInitialValues({
        'token': 'jwt',
        'userId': 'u1',
        'upload_queue_tasks': saved,
      });
      await queue.initialize();
      await until(() => active().isNotEmpty, 'wake-up timer armed');
      expect(calls, isEmpty, reason: 'not before its retry time');
      await fireRetry(id);
      expect(taskOf(id)!.status, UploadStatus.completed);
      expect(calls.single.key, id);
    });

    test('a missing private file fails once with the file-missing code',
        () async {
      await store([
        {
          'id': 'gone',
          'type': 'story',
          'localFilePath': '${docs.path}/story_uploads/gone.jpg',
          'metadata': {
            'mediaPath': '${docs.path}/story_uploads/gone.jpg',
            'ownerUserId': 'u1',
          },
          'status': 'queued',
          'createdAt': '2026-11-13T11:00:00.000',
          'retryCount': 0,
        },
      ]);
      await queue.initialize();
      final t = await idle('gone');
      expect(t!.status, UploadStatus.failed);
      expect(t.storyFailure, StoryUploadFailure.fileMissing);
      expect(calls, isEmpty);
      expect(active(), isEmpty);
    });

    test("another user's story is dropped, never uploaded, and its file deleted",
        () async {
      final f = File('${docs.path}/story_uploads/theirs.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      await store([
        {
          'id': 'theirs',
          'type': 'story',
          'localFilePath': f.path,
          'metadata': {'mediaPath': f.path, 'ownerUserId': 'u2'},
          'status': 'queued',
          'createdAt': '2026-11-13T11:00:00.000',
          'retryCount': 0,
        },
      ]);
      await queue.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
      expect(taskOf('theirs'), isNull);
      expect(f.existsSync(), isFalse);
    });

    test('with nobody signed in a story waits; it is neither sent nor dropped',
        () async {
      final f = File('${docs.path}/story_uploads/mine.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      SharedPreferences.setMockInitialValues({
        'upload_queue_tasks': jsonEncode([
          {
            'id': 'mine',
            'type': 'story',
            'localFilePath': f.path,
            // No owner: a task from before owners were recorded.
            'metadata': {'mediaPath': f.path},
            'status': 'queued',
            'createdAt': '2026-11-13T11:00:00.000',
            'retryCount': 0,
          },
        ]),
      });
      await queue.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
      expect(taskOf('mine')!.status, UploadStatus.queued);
      expect(f.existsSync(), isTrue);
    });

    test('the owner is whoever is signed in when it is queued', () async {
      SharedPreferences.setMockInitialValues(
          {'token': 'jwt', 'userId': 'u2'});
      final id = await queue.queueStoryUpload(
          StoryUploadPayload(mediaPath: source().path));
      await idle(id);
      expect(calls.single.key, id);
      expect(taskOf(id)!.metadata['ownerUserId'], 'u2');
    });

    test("a copy stored under an old app-container path is found in today's",
        () async {
      // iOS moves the app container on update; the stored absolute path of
      // our own copy goes stale while the file itself is still there.
      File('${docs.path}/story_uploads/moved.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      const stale = '/var/old-container/Documents/story_uploads/moved.jpg';
      await store([
        {
          'id': 'moved',
          'type': 'story',
          'localFilePath': stale,
          'metadata': {'mediaPath': stale, 'ownerUserId': 'u1'},
          'status': 'queued',
          'createdAt': '2026-11-13T11:00:00.000',
          'retryCount': 0,
        },
      ]);
      await queue.initialize();
      final t = await idle('moved');
      expect(t!.status, UploadStatus.completed);
      expect(calls.single.payload.mediaPath,
          '${docs.path}/story_uploads/moved.jpg');
      expect(File('${docs.path}/story_uploads/moved.jpg').existsSync(),
          isFalse);
    });

    test('a story queued while the sweep is listing keeps its copy',
        () async {
      File('${docs.path}/story_uploads/orphan.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      final listing = Completer<void>();
      final gate = Completer<void>();
      UploadQueueService.storyDirLister = (dir) async* {
        listing.complete();
        await gate.future; // the listing is slow
        yield* dir.list();
      };
      final release = Completer<SingleStoryResponse>();
      answers = [() => release.future];
      await store([]);

      final init = queue.initialize();
      await listing.future;
      final id = await queue.queueStoryUpload(photo());
      final copy = File(taskOf(id)!.localFilePath);
      gate.complete();
      await init;

      expect(copy.existsSync(), isTrue, reason: 'the sweep spared it');
      expect(File('${docs.path}/story_uploads/orphan.jpg').existsSync(),
          isFalse);
      release.complete(ok());
      final t = await idle(id);
      expect(t!.status, UploadStatus.completed);
      expect(calls.single.key, id);
    });

    test('no readable user id: the story looks again after 30 s, then 2 min',
        () async {
      String? user;
      UploadQueueService.signedInUserId = () async => user;
      final f = File('${docs.path}/story_uploads/wait.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      await store([
        {
          'id': 'wait',
          'type': 'story',
          'localFilePath': f.path,
          'metadata': {'mediaPath': f.path, 'ownerUserId': 'u1'},
          'status': 'queued',
          'createdAt': '2026-11-13T11:00:00.000',
          'retryCount': 0,
        },
      ]);
      await queue.initialize();
      await until(() => active().isNotEmpty, 'first look armed');
      expect(active().single.duration, const Duration(seconds: 30));
      expect(calls, isEmpty);

      Future<void> fire() async {
        final t = active().single;
        now = now.add(t.duration);
        t.fired = true;
        t.callback();
      }

      await fire(); // still nobody readable
      await until(() => active().isNotEmpty, 'second look armed');
      expect(active().single.duration, const Duration(minutes: 2));
      expect(calls, isEmpty);
      expect(timers, hasLength(2), reason: 'no tight loop');

      user = 'u1';
      await fire();
      await until(() => taskOf('wait')!.status == UploadStatus.completed,
          'uploaded once the user is readable');
      expect(calls.single.key, 'wait');
      expect(active(), isEmpty);
    });

    test('orphaned files in the uploads folder are swept on start', () async {
      final keep = File('${docs.path}/story_uploads/keep.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      final orphan = File('${docs.path}/story_uploads/orphan.jpg')
        ..writeAsBytesSync([1]);
      answers = [() => limit()];
      await store([
        {
          'id': 'keep',
          'type': 'story',
          'localFilePath': keep.path,
          'metadata': {'mediaPath': keep.path, 'ownerUserId': 'u1'},
          'status': 'queued',
          'createdAt': '2026-11-13T11:00:00.000',
          'retryCount': 0,
        },
      ]);
      await queue.initialize();
      await idle('keep');
      expect(orphan.existsSync(), isFalse);
      expect(keep.existsSync(), isTrue);
    });
  });

  group('sign-out, cancel and remove', () {
    test('endSession stops story retries, deletes copies, drops story tasks',
        () async {
      answers = [() => fail()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      final copy = File(taskOf(id)!.localFilePath);
      final timer = active().single;

      await queue.endSession();
      expect(queue.tasks, isEmpty);
      expect(copy.existsSync(), isFalse);
      expect(timer.cancelled, isTrue);

      // A late connectivity event or timer cannot resurrect it.
      connectivity.add([ConnectivityResult.none]);
      connectivity.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, hasLength(1));
    });

    test('an attempt in flight at sign-out writes nothing back', () async {
      final release = Completer<SingleStoryResponse>();
      answers = [() => release.future];
      final id = await queue.queueStoryUpload(photo());
      await until(() => calls.isNotEmpty, 'attempt started');
      await queue.endSession();
      release.complete(fail());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(taskOf(id), isNull);
      expect(queue.tasks, isEmpty);
      expect(active(), isEmpty);
    });

    test(
        'removing a failed story while a moment uploads: the moment completes '
        'and the queue keeps draining', () async {
      answers = [() => limit()];
      final story = await queue.queueStoryUpload(photo());
      await idle(story);
      expect(taskOf(story)!.status, UploadStatus.failed);

      final createStarted = Completer<void>();
      final releaseCreate = Completer<void>();
      var creates = 0;
      late String moment;
      late String later;
      await http.runWithClient(() async {
        // The story sits failed at index 0; the moment is index 1.
        moment = await queue.queueMomentUpload(description: 'first');
        await createStarted.future;

        // The ring's Remove, while the moment's create is on the wire.
        await queue.removeTask(story);
        releaseCreate.complete();

        await until(() => taskOf(moment)?.status == UploadStatus.completed,
            'moment completed');
        later = await queue.queueMomentUpload(description: 'second');
        await until(() => taskOf(later)?.status == UploadStatus.completed,
            'later moment completed');
      }, () => MockClient((req) async {
            creates++;
            if (!createStarted.isCompleted) createStarted.complete();
            await releaseCreate.future;
            return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {'_id': 'm$creates', 'description': 'x'},
                }),
                201);
          }));

      expect(taskOf(story), isNull);
      expect(taskOf(moment)!.resultId, 'm1');
      expect(taskOf(later)!.resultId, 'm2');
      expect(creates, 2, reason: 'each moment is created exactly once');
    });

    test('remove and cancel delete the private copy', () async {
      answers = [() => limit()];
      final a = await queue.queueStoryUpload(photo());
      await idle(a);
      final copyA = File(taskOf(a)!.localFilePath);
      await queue.removeTask(a);
      expect(copyA.existsSync(), isFalse);
      expect(taskOf(a), isNull);

      final b = await queue.queueStoryUpload(photo());
      await idle(b);
      final copyB = File(taskOf(b)!.localFilePath);
      await queue.cancelUpload(b);
      expect(copyB.existsSync(), isFalse);
      expect(taskOf(b)!.status, UploadStatus.cancelled);
    });
  });

  group('connectivity', () {
    test('coming back online retries a waiting story at once, once', () async {
      answers = [() => fail(), () => ok()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      expect(active(), hasLength(1));

      connectivity.add([ConnectivityResult.none]);
      connectivity.add([ConnectivityResult.mobile]);
      await until(() => taskOf(id)!.status == UploadStatus.completed,
          'retried on reconnect');
      expect(calls, hasLength(2));
      expect(calls.map((c) => c.key).toSet(), {id});
    });

    test('coming back online gives a failed story one more attempt', () async {
      answers = [() => fail()];
      final id = await queue.queueStoryUpload(photo());
      await idle(id);
      for (var i = 0; i < 5; i++) {
        await fireRetry(id);
      }
      expect(taskOf(id)!.status, UploadStatus.failed);
      expect(calls, hasLength(6));

      connectivity.add([ConnectivityResult.none]);
      connectivity.add([ConnectivityResult.wifi]);
      await until(() => calls.length == 7, 'one more attempt');
      await idle(id);
      expect(taskOf(id)!.status, UploadStatus.failed);
      expect(active(), isEmpty, reason: 'no new automatic schedule');
    });

    test('no retry while an attempt is in flight', () async {
      final release = Completer<SingleStoryResponse>();
      answers = [() => release.future, () => ok()];
      final id = await queue.queueStoryUpload(photo());
      await until(() => calls.isNotEmpty, 'attempt started');

      connectivity.add([ConnectivityResult.none]);
      connectivity.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, hasLength(1));

      release.complete(ok());
      final t = await idle(id);
      expect(t!.status, UploadStatus.completed);
      expect(calls, hasLength(1));
    });
  });

  group('default poster', () {
    tearDown(() => StoriesService.httpClient = null);

    test('a media story sends the key, the file and every sticker', () async {
      UploadQueueService.storyPoster = UploadQueueService.defaultStoryPoster;
      final seen = <http.BaseRequest>[];
      StoriesService.httpClient = MockClient.streaming((req, body) async {
        seen.add(req);
        await body.drain<void>();
        return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'success': true,
              'data': {'_id': 's9', 'user': {'_id': 'u1'}},
            }))),
            201);
      });
      final id = await queue.queueStoryUpload(photo());
      await until(() => taskOf(id)?.status == UploadStatus.completed,
          'posted through StoriesService');
      final req = seen.single as http.MultipartRequest;
      expect(req.headers['Idempotency-Key'], id);
      expect(req.url.path, endsWith('/stories'));
      expect(req.files.single.filename, '$id.jpg');
      expect(jsonDecode(req.fields['quizSticker']!),
          {'question': 'q', 'options': ['a', 'b'], 'correctIndex': 1});
      expect(req.fields['privacy'], 'friends');
      expect(req.fields['text'], 'cap');
    });

    test('a text story goes through the text endpoint with the key', () async {
      UploadQueueService.storyPoster = UploadQueueService.defaultStoryPoster;
      final seen = <http.Request>[];
      StoriesService.httpClient = MockClient((req) async {
        seen.add(req);
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {'_id': 's9', 'user': {'_id': 'u1'}},
            }),
            201);
      });
      final id = await queue.queueStoryUpload(const StoryUploadPayload(
        text: 'hi',
        backgroundColor: 'sunset',
        wordSticker: StoryWordSticker(word: 'w', meaning: 'm'),
      ));
      await until(() => taskOf(id)?.status == UploadStatus.completed,
          'text story posted');
      final req = seen.single;
      expect(req.headers['Idempotency-Key'], id);
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['mediaType'], 'text');
      expect(body['backgroundColor'], 'sunset');
      expect(body['wordSticker'], {'word': 'w', 'meaning': 'm', 'x': 0.5, 'y': 0.5});
    });
  });
}
