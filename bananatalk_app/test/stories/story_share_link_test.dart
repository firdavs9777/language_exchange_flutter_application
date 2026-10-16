import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_link_screen.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/link_constants.dart';

import '../helpers/community_fixture.dart';

const kId = '64b7f0c2a1b2c3d4e5f60718';

Widget _host(Widget child) => ProviderScope(
      overrides: [userProvider.overrideWith((ref) async => communityFixture())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

Story _textStory({String userId = 'me'}) => Story.fromJson({
      '_id': kId,
      'user': {'_id': userId, 'name': 'Ana'},
      'mediaType': 'text',
      'text': 'Hello',
      'backgroundColor': '#336699',
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(hours: 20)).toIso8601String(),
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the viewer shares https://banatalk.com/story/<id>, which the app opens', () {
    final src = File('lib/pages/stories/viewer/story_viewer_screen.dart').readAsStringSync();
    expect(src, contains("shareUrl('story', story.id)"));
    expect(src, isNot(contains('bananatalk.com/story')));
    expect(shareUrl('story', kId), 'https://banatalk.com/story/$kId');
    expect(routePathFromUri(Uri.parse(shareUrl('story', kId))), '/story/$kId');
    expect(File('lib/router/app_router.dart').readAsStringSync(), contains("path: '/story/:storyId'"));
  });

  test('no link to the parked bananatalk.com domain anywhere in lib/', () {
    final hits = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('https://bananatalk.com'))
        .map((f) => f.path)
        .toList();
    expect(hits, isEmpty);
  });

  testWidgets('a story that cannot be loaded shows Content not available', (tester) async {
    String? asked;
    await tester.pumpWidget(_host(StoryLinkScreen(
      storyId: kId,
      load: ({required storyId}) async {
        asked = storyId;
        return SingleStoryResponse(success: false, error: 'Story is no longer available');
      },
    )));
    await tester.pump();
    await tester.pump();
    expect(asked, kId);
    expect(find.text('Content not available'), findsOneWidget);
    expect(find.byType(StoryViewerScreen), findsNothing);
  });

  testWidgets('a blocked story shows Content not available', (tester) async {
    await tester.pumpWidget(_host(StoryLinkScreen(
      storyId: kId,
      load: ({required storyId}) async => SingleStoryResponse(success: false, blocked: true),
    )));
    await tester.pump();
    await tester.pump();
    expect(find.text('Content not available'), findsOneWidget);
  });

  testWidgets('a loaded story plays in the story viewer', (tester) async {
    await tester.pumpWidget(_host(StoryLinkScreen(
      storyId: kId,
      load: ({required storyId}) async => SingleStoryResponse(success: true, data: _textStory()),
    )));
    await tester.pump();
    await tester.pump();
    expect(find.byType(StoryViewerScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose the viewer (timers, system UI)
  });
}
