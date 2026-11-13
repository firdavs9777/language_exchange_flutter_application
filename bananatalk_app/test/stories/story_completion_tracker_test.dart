import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_completion_tracker.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/stories_service.dart';

import '../helpers/community_fixture.dart';

Story _story(String id) => Story.fromJson({
  '_id': id,
  'user': {'_id': 'author1', 'name': 'Ana'},
  'mediaType': 'text',
  'text': 'Hello $id',
  'backgroundColor': '#336699',
  'createdAt': DateTime.now().toIso8601String(),
  'expiresAt': DateTime.now().add(const Duration(hours: 20)).toIso8601String(),
});

Future<void> _pump(
  WidgetTester tester,
  List<Story> stories,
  StoryCompletionTracker tracker, {
  bool own = false,
  bool flag = true,
}) async {
  SharedPreferences.setMockInitialValues({'token': 't'});
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) async => communityFixture()),
        appConfigProvider.overrideWith(
          (ref) async => AppConfig.fromJson({'storyInsightsEnabled': flag}),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryViewerScreen(
          stories: stories,
          isOwnStory: own,
          completionTracker: tracker,
        ),
      ),
    ),
  );
  // In the app the config is already loaded (it is watched app-wide).
  await ProviderScope.containerOf(
    tester.element(find.byType(StoryViewerScreen)),
  ).read(appConfigProvider.future);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  StoriesService.httpClient = null;
}

void main() {
  group('StoryCompletionTracker', () {
    test('completing the same story twice sends once', () async {
      final sent = <String>[];
      final t = StoryCompletionTracker(send: (id) async => sent.add(id));
      t.completed('a');
      t.completed('a');
      t.completed('b');
      await Future<void>.delayed(Duration.zero);
      expect(sent, ['a', 'b']);
    });

    test('a throwing sender does not throw and is not retried', () async {
      var calls = 0;
      final t = StoryCompletionTracker(send: (id) async {
        calls++;
        throw StateError('offline');
      });
      expect(() => t.completed('a'), returnsNormally);
      await Future<void>.delayed(Duration.zero);
      t.completed('a');
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
    });

    test('a synchronously throwing sender does not throw', () {
      final t = StoryCompletionTracker(send: (id) => throw StateError('x'));
      expect(() => t.completed('a'), returnsNormally);
    });

    test('an empty id is ignored', () async {
      var calls = 0;
      final t = StoryCompletionTracker(send: (id) async => calls++);
      t.completed('');
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
    });
  });

  group('viewer', () {
    testWidgets('a story that plays to the end is reported once (flag on)', (
      tester,
    ) async {
      final sent = <String>[];
      final t = StoryCompletionTracker(send: (id) async => sent.add(id));
      await _pump(tester, [_story('s1'), _story('s2')], t);
      await tester.pump(const Duration(seconds: 6));
      expect(sent, ['s1']);
      await _end(tester);
    });

    testWidgets('pause, resume, then the end still counts', (tester) async {
      final sent = <String>[];
      final t = StoryCompletionTracker(send: (id) async => sent.add(id));
      await _pump(tester, [_story('s1'), _story('s2')], t);
      final g = await tester.startGesture(const Offset(540, 1000));
      await tester.pump(const Duration(milliseconds: 600));
      await g.up();
      await tester.pump(const Duration(seconds: 6));
      expect(sent, ['s1']);
      await _end(tester);
    });

    testWidgets('a tap-skip is not a completion', (tester) async {
      final sent = <String>[];
      final t = StoryCompletionTracker(send: (id) async => sent.add(id));
      await _pump(tester, [_story('s1'), _story('s2')], t);
      await tester.tapAt(const Offset(1000, 1000));
      await tester.pump(const Duration(milliseconds: 300));
      expect(sent, isEmpty);
      await _end(tester);
    });

    testWidgets('flag off: nothing is reported', (tester) async {
      final sent = <String>[];
      final t = StoryCompletionTracker(send: (id) async => sent.add(id));
      await _pump(tester, [_story('s1'), _story('s2')], t, flag: false);
      await tester.pump(const Duration(seconds: 6));
      expect(sent, isEmpty);
      await _end(tester);
    });

    testWidgets('own story: nothing is reported', (tester) async {
      final sent = <String>[];
      final t = StoryCompletionTracker(send: (id) async => sent.add(id));
      await _pump(tester, [_story('s1'), _story('s2')], t, own: true);
      await tester.pump(const Duration(seconds: 6));
      expect(sent, isEmpty);
      await _end(tester);
    });
  });
}
