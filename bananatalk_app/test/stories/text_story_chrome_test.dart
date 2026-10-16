import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/story/story_poll_widget.dart';
import 'package:bananatalk_app/widgets/story/story_question_box_widget.dart';

import '../helpers/community_fixture.dart';

Story _story(Map<String, dynamic> extra) => Story.fromJson({
      '_id': '64b7f0c2a1b2c3d4e5f60718',
      'user': {'_id': 'author1', 'name': 'Ana'},
      'mediaType': 'text',
      'text': 'Hello',
      'backgroundColor': '#336699',
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(hours: 20)).toIso8601String(),
      ...extra,
    });

Future<void> _pump(WidgetTester tester, Story story, {bool own = false}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [userProvider.overrideWith((ref) async => communityFixture())],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StoryViewerScreen(stories: [story], isOwnStory: own),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('a text story shows header, location, poll, link and reply bar', (tester) async {
    await _pump(tester, _story({
      'location': {'name': 'Seoul'},
      'poll': {
        'question': 'Best snack?',
        'options': [
          {'text': 'Tteok'},
          {'text': 'Kimbap'},
        ],
      },
      'link': {'url': 'https://example.com', 'displayText': 'Open', 'host': 'example.com'},
      'hashtags': ['korean'],
    }));
    expect(find.byKey(const Key('story-author-name')), findsOneWidget);
    expect(find.byKey(const Key('story-location-label')), findsOneWidget);
    expect(find.byType(StoryPollWidget), findsOneWidget);
    expect(find.text('Best snack?'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('#korean'), findsOneWidget);
    expect(find.text('Reply to story...'), findsOneWidget);
    // The story text is drawn by the text layer only, not again as a caption.
    expect(find.text('Hello'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('a text story with a question box shows it', (tester) async {
    await _pump(tester, _story({
      'questionBox': {'prompt': 'Ask me anything', 'responses': []},
    }));
    expect(find.byType(StoryQuestionBoxWidget), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('own text story: menu, no reply bar', (tester) async {
    await _pump(tester, _story({}), own: true);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text('Reply to story...'), findsNothing);
    await _dispose(tester);
  });
}
