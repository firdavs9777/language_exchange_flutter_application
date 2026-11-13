import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/stories/create/create_story_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/upload_manager_provider.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';

import 'support/fake_upload_manager.dart';

/// A 1x1 PNG.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

void main() {
  late FakeUploadManager manager;
  late List<http.BaseRequest> requests;
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'token': 'jwt', 'userId': 'me'});
    await useFakeQueueSeams();
    tmp = await Directory.systemTemp.createTemp('composer');
    addTearDown(() => tmp.deleteSync(recursive: true));
    requests = [];
    // A server that refuses every post, so "stays open" is observable.
    StoriesService.httpClient = MockClient((req) async {
      requests.add(req);
      return http.Response(jsonEncode({'success': false, 'error': 'nope'}), 500);
    });
    addTearDown(() => StoriesService.httpClient = null);
  });

  Future<void> open(WidgetTester tester,
      {required bool flag, XFile? image}) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      manager = FakeUploadManager();
      await manager.ready();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async => AppConfig.fromJson({
              'storyUploadQueueEnabled': flag,
              'storyStickerQuizEnabled': true,
            })),
        uploadManagerProvider.overrideWith((ref) => manager),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateStoryScreen(initialImage: image)),
              ),
              child: const Text('open composer'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open composer'));
    await tester.pumpAndSettle();
    await ProviderScope.containerOf(
      tester.element(find.byType(CreateStoryScreen)),
    ).read(appConfigProvider.future);
    await tester.pump();
  }

  Future<void> writeTextStory(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap anywhere to add text'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  Future<void> addQuiz(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('text-story-stickers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sticker-quiz')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quiz-question')), 'Capital?');
    await tester.enterText(find.byKey(const Key('quiz-option-0')), 'Paris');
    await tester.enterText(find.byKey(const Key('quiz-option-1')), 'Rome');
    await tester.tap(find.byKey(const Key('quiz-correct-0')));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  group('flag off: today\'s blocking path', () {
    testWidgets('awaits the server, stays open on failure, queues nothing',
        (tester) async {
      await open(tester, flag: false);
      await writeTextStory(tester);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(manager.queued, isEmpty);
      expect(find.byType(CreateStoryScreen), findsOneWidget);
      expect(find.text('Posting your story…'), findsNothing);
    });
  });

  group('flag on: through the queue', () {
    testWidgets('a text story pops at once with every field in the payload',
        (tester) async {
      await open(tester, flag: true);
      await writeTextStory(tester);
      await addQuiz(tester);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(requests, isEmpty, reason: 'nothing is sent from the composer');
      expect(find.byType(CreateStoryScreen), findsNothing);
      expect(find.text('Posting your story…'), findsOneWidget);
      expect(find.text('Story posted!'), findsNothing);

      final p = manager.queued.single;
      expect(p.isTextStory, isTrue);
      expect(p.text, 'hello');
      expect(p.fontStyle, 'normal');
      expect(p.backgroundColor, isNotEmpty);
      expect(p.overlays!.single['content'], 'hello');
      expect(p.quizSticker!.question, 'Capital?');
      expect(p.quizSticker!.correctIndex, 0);
      expect(p.allowReplies, isTrue);
      expect(p.allowSharing, isTrue);
    });

    testWidgets('a photo story queues the chosen file with its caption',
        (tester) async {
      final f = File('${tmp.path}/pic.png')..writeAsBytesSync(_png);
      await open(tester, flag: true, image: XFile(f.path));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      final p = manager.queued.single;
      expect(p.mediaPath, f.path);
      expect(p.isVideo, isFalse);
      expect(p.isTextStory, isFalse);
      expect(find.byType(CreateStoryScreen), findsNothing);
      expect(requests, isEmpty);
    });

    testWidgets('if the queue refuses, the story still posts the blocking way',
        (tester) async {
      await open(tester, flag: true);
      manager.queueError = StoryUploadQueueException('copy failed');
      await writeTextStory(tester);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(manager.queued, isEmpty);
      // The blocking path failed against the fake server: still open, so the
      // story is not lost.
      expect(find.byType(CreateStoryScreen), findsOneWidget);
    });
  });
}
