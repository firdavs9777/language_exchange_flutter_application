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

    test('a task without an owner belongs to the signed-in user', () {
      expect(storyTaskForRing([storyTask(UploadStatus.queued, owner: null)], 'me'),
          isNotNull);
    });
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

    Future<void> pumpRail(WidgetTester tester, {required bool flag}) async {
      await tester.runAsync(() async {
        manager = FakeUploadManager();
        await manager.ready();
      });
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
          home: Scaffold(
            body: StoriesFeedWidget(
              feedLoader: () async {
                loads++;
                return StoriesFeedResult(success: true);
              },
              myStoriesLoader: () async => StoriesResponse(success: true),
              railPrecacheAllowed: () async => false,
              storyPostedStream: () => posted.stream,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }

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
