import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/pages/stories/feed/stories_feed_widget.dart';
import 'package:bananatalk_app/pages/stories/feed/story_upload_ring.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/upload_manager_provider.dart';
import 'package:bananatalk_app/services/story_upload_payload.dart';

import 'support/fake_upload_manager.dart';

void main() {
  group('storyTaskForRing', () {
    test('a failed task wins over a waiting one', () {
      final t = storyTaskForRing([
        storyTask(UploadStatus.uploading, id: 'a'),
        storyTask(UploadStatus.failed, id: 'b'),
      ], 'me');
      expect(t!.id, 'b');
    });

    test('completed, cancelled, moment and foreign-owner tasks show nothing',
        () {
      expect(
        storyTaskForRing([
          storyTask(UploadStatus.completed),
          storyTask(UploadStatus.cancelled, id: 'c'),
          storyTask(UploadStatus.queued, id: 'd', owner: 'someone-else'),
          UploadTask(type: UploadType.moment, localFilePath: ''),
        ], 'me'),
        isNull,
      );
    });

    test('until the user is known the ring shows nothing, never any owner', () {
      final tasks = [storyTask(UploadStatus.failed), storyTask(UploadStatus.queued, id: 'b', owner: null)];
      expect(storyTaskForRing(tasks, null), isNull);
      expect(storyTaskForRing(tasks, ''), isNull);
      expect(storyTaskForRing(tasks, 'me'), isNotNull);
    });

    test('a task without an owner belongs to the signed-in user', () {
      expect(storyTaskForRing([storyTask(UploadStatus.queued, owner: null)], 'me'),
          isNotNull);
    });
  });

  test('Retry is offered for everything except a deleted file', () {
    expect(storyFailureRetryable(null), isTrue);
    expect(storyFailureRetryable(StoryUploadFailure.failed), isTrue);
    expect(storyFailureRetryable(StoryUploadFailure.limitReached), isTrue);
    expect(storyFailureRetryable(StoryUploadFailure.fileMissing), isFalse);
  });

  group('failure text', () {
    test('every code has its own localized sentence', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(storyUploadFailureText(l10n, StoryUploadFailure.failed),
          l10n.storyUploadFailed);
      expect(storyUploadFailureText(l10n, null), l10n.storyUploadFailed);
      expect(storyUploadFailureText(l10n, StoryUploadFailure.fileMissing),
          l10n.storyUploadFileMissing);
      expect(storyUploadFailureText(l10n, StoryUploadFailure.limitReached),
          l10n.limitDescStories);
    });
  });

  group('own ring on the rail', () {
    late FakeUploadManager manager;
    late StreamController<String> posted;
    var loads = 0;
    var managerCreated = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      await useFakeQueueSeams();
      loads = 0;
      managerCreated = 0;
      posted = StreamController<String>.broadcast();
      addTearDown(posted.close);
    });

    Future<void> pumpRail(WidgetTester tester,
        {required bool flag,
        Future<StoriesFeedResult> Function(int call)? feed,
        bool underneath = false}) async {
      await tester.runAsync(() async {
        manager = FakeUploadManager();
        await manager.ready();
      });
      final railScreen = Scaffold(
            body: StoriesFeedWidget(
              feedLoader: () async {
                loads++;
                return feed != null
                    ? feed(loads)
                    : StoriesFeedResult(success: true);
              },
              myStoriesLoader: () async => StoriesResponse(success: true),
              railPrecacheAllowed: () async => false,
              storyPostedStream: () => posted.stream,
            ),
          );
      var pushed = false;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
          appConfigProvider.overrideWith((ref) async =>
              AppConfig.fromJson({'storyUploadQueueEnabled': flag})),
          uploadManagerProvider.overrideWith((ref) {
            managerCreated++;
            return manager;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: underneath
              ? Builder(builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (pushed) return;
                    pushed = true;
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => railScreen));
                  });
                  return const Scaffold(body: Text('underneath'));
                })
              : railScreen,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }

    Map<String, dynamic> group(String id) => {
          'user': {'_id': id, 'name': 'U$id'},
          'stories': [
            {
              '_id': 's-$id',
              'user': {'_id': id, 'name': 'U$id'},
              'mediaType': 'image',
              'mediaUrl': 'https://x.test/$id.jpg',
              'privacy': 'public',
              'isActive': true,
              'isArchived': false,
              'expiresAt': DateTime.now()
                  .add(const Duration(hours: 5))
                  .toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
              'views': <dynamic>[],
            },
          ],
          'hasUnviewed': 1,
        };

    testWidgets('queued: a progress chip with the posting text', (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([storyTask(UploadStatus.queued)]);
      await t.pump();
      expect(find.byKey(const Key('story-upload-progress')), findsOneWidget);
      expect(find.text('Posting your story…'), findsOneWidget);
      expect(find.byKey(const Key('story-upload-failed')), findsNothing);
    });

    testWidgets('uploading: the same progress chip', (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([storyTask(UploadStatus.uploading)]);
      await t.pump();
      expect(find.byKey(const Key('story-upload-progress')), findsOneWidget);
    });

    testWidgets('no task: no chip', (t) async {
      await pumpRail(t, flag: true);
      expect(find.byKey(const Key('story-upload-progress')), findsNothing);
      expect(find.byKey(const Key('story-upload-failed')), findsNothing);
    });

    testWidgets('failed: a warning chip with Tap to retry; Retry calls retryUpload',
        (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([storyTask(UploadStatus.failed, id: 'x')]);
      await t.pump();
      expect(find.text('Tap to retry'), findsOneWidget);
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      expect(find.text("Your story couldn't be posted."), findsOneWidget);
      await t.tap(find.byKey(const Key('story-upload-retry')));
      await t.pumpAndSettle();
      expect(manager.retried, ['x']);
      expect(manager.removed, isEmpty);
    });

    testWidgets('failed: Remove calls removeTask, chip goes with the task',
        (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([storyTask(UploadStatus.failed, id: 'x')]);
      await t.pump();
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('story-upload-remove')));
      await t.pumpAndSettle();
      expect(manager.removed, ['x']);
      manager.setTasks([]);
      await t.pump();
      expect(find.byKey(const Key('story-upload-failed')), findsNothing);
    });

    testWidgets('a missing file cannot be retried, only removed', (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([
        storyTask(UploadStatus.failed, failure: StoryUploadFailure.fileMissing)
      ]);
      await t.pump();
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('story-upload-retry')), findsNothing);
      expect(find.byKey(const Key('story-upload-remove')), findsOneWidget);
      expect(find.textContaining('no longer on your device'), findsOneWidget);
    });

    testWidgets('the daily limit opens the existing story-limit dialog',
        (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([
        storyTask(UploadStatus.failed, failure: StoryUploadFailure.limitReached)
      ]);
      await t.pump();
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('a story landing reloads the rail exactly once', (t) async {
      await pumpRail(t, flag: true);
      final before = loads;
      posted.add('t1');
      await t.pump(const Duration(milliseconds: 50));
      expect(loads, before + 1);
    });

    testWidgets('a story landing during a load still reloads, once, afterwards',
        (t) async {
      final first = Completer<StoriesFeedResult>();
      await pumpRail(t, flag: true, feed: (call) {
        if (call == 1) return first.future;
        return Future.value(StoriesFeedResult.fromJson(
            {'success': true, 'data': [group('f1')]}, 'me'));
      });
      expect(loads, 1, reason: 'the first load is held in flight');
      posted.add('t1');
      await t.pump(const Duration(milliseconds: 50));
      expect(loads, 1, reason: 'not started on top of the running one');
      first.complete(StoriesFeedResult(success: true));
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 50));
      expect(loads, 2);
      expect(find.text('Uf1'), findsOneWidget);
    });

    testWidgets('chip text: retry for failed and the limit, failed for a missing file',
        (t) async {
      await pumpRail(t, flag: true);
      for (final f in [
        null,
        StoryUploadFailure.failed,
        StoryUploadFailure.limitReached
      ]) {
        manager.setTasks([storyTask(UploadStatus.failed, failure: f)]);
        await t.pump();
        expect(find.text('Tap to retry'), findsOneWidget, reason: '$f');
      }
      manager.setTasks([
        storyTask(UploadStatus.failed, failure: StoryUploadFailure.fileMissing)
      ]);
      await t.pump();
      expect(find.text('Tap to retry'), findsNothing);
      expect(find.text("Your story couldn't be posted."), findsOneWidget);
    });

    testWidgets('the limit: dialog first, then a sheet with Retry and Remove',
        (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([
        storyTask(UploadStatus.failed,
            id: 'x', failure: StoryUploadFailure.limitReached)
      ]);
      await t.pump();
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byKey(const Key('story-upload-retry')), findsNothing);
      // Close the (non-dismissible) dialog the way its own button does.
      Navigator.of(t.element(find.byType(AlertDialog))).pop();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('story-upload-retry')), findsOneWidget);
      expect(find.byKey(const Key('story-upload-remove')), findsOneWidget);
      await t.tap(find.byKey(const Key('story-upload-retry')));
      await t.pumpAndSettle();
      expect(manager.retried, ['x']);
    });

    testWidgets('two notifications while the sheet closes pop it only once',
        (t) async {
      await pumpRail(t, flag: true, underneath: true);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      manager.setTasks([storyTask(UploadStatus.failed, id: 'x')]);
      await t.pump();
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      manager.setTasks([storyTask(UploadStatus.uploading, id: 'x')]);
      await t.pump();
      manager.setTasks([storyTask(UploadStatus.uploading, id: 'x', owner: 'me')]);
      await t.pump(const Duration(milliseconds: 20));
      manager.setTasks([storyTask(UploadStatus.uploading, id: 'x')]);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('story-upload-remove')), findsNothing);
      expect(find.byType(StoriesFeedWidget), findsOneWidget,
          reason: 'the rail screen under the sheet is still there');
      expect(find.text('underneath'), findsNothing,
          reason: 'a second pop would have taken the rail screen too');
    });

    testWidgets('an attempt starting while the sheet is open closes it without acting',
        (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([storyTask(UploadStatus.failed, id: 'x')]);
      await t.pump();
      await t.tap(find.byKey(const Key('story-upload-failed')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('story-upload-remove')), findsOneWidget);
      manager.setTasks([storyTask(UploadStatus.uploading, id: 'x')]);
      // The progress chip animates forever: pump, do not settle.
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('story-upload-remove')), findsNothing);
      expect(manager.removed, isEmpty);
      expect(manager.retried, isEmpty);
    });

    testWidgets('a tap on a chip whose task is no longer failed opens nothing',
        (t) async {
      await pumpRail(t, flag: true);
      manager.setTasks([storyTask(UploadStatus.failed, id: 'x')]);
      await t.pump();
      final chip = find.byKey(const Key('story-upload-failed'));
      manager.setTasks([storyTask(UploadStatus.uploading, id: 'x')]);
      // No pump: the chip on screen is still the failed one.
      await t.tap(chip, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('story-upload-remove')), findsNothing);
    });

    testWidgets('flag on: the upload manager is started with the rail',
        (t) async {
      await pumpRail(t, flag: true);
      expect(managerCreated, 1);
    });

    testWidgets('flag off: no ring widget, no queue subscription, no reload',
        (t) async {
      await pumpRail(t, flag: false);
      manager.setTasks([storyTask(UploadStatus.failed)]);
      await t.pump();
      expect(managerCreated, 0, reason: 'flag off: the queue is never started');
      expect(find.byType(StoryUploadRing), findsNothing);
      expect(find.byType(StoryUploadChip), findsNothing);
      final before = loads;
      posted.add('t1');
      await t.pump(const Duration(milliseconds: 50));
      expect(loads, before);
    });
  });
}
