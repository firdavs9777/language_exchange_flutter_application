import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/archive/story_archive_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// The archive existed on the backend, in the service and in the endpoint
/// constants — and nothing called any of it, so 112 archived stories sat in a
/// place no one could open.
///
/// The consequence was specific: a highlight is created from ONE story id,
/// and the only screen offering that was the live viewer. A story could be
/// highlighted during its 24 hours and never again.
void main() {
  Widget host({ArchiveLoader? loader}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryArchiveScreen(loader: loader),
      );

  Future<ArchiveResponse> empty(int page) async =>
      ArchiveResponse(success: true, data: const [], pages: 1);

  Future<ArchiveResponse> broken(int page) async =>
      ArchiveResponse(success: false, error: 'Failed to load archive');

  // Built through fromJson rather than the constructor: it needs far fewer
  // fields and it exercises the parsing the real screen depends on.
  Story story(String id) => Story.fromJson({
        '_id': id,
        'user': {'_id': 'u1', 'name': 'Dana'},
        'mediaType': 'text',
        'text': 'hello',
        'backgroundColor': '#112233',
        'expiresAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'createdAt':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'isArchived': true,
      });

  Future<ArchiveResponse> withOne(int page) async =>
      ArchiveResponse(success: true, data: [story('s1')], pages: 1);

  testWidgets('it opens and names itself', (tester) async {
    await tester.pumpWidget(host(loader: empty));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsWidgets);
  });

  testWidgets('it says the archive is private', (tester) async {
    // An archive of your own posts is unsettling until you know nobody else
    // can see it.
    await tester.pumpWidget(host(loader: empty));
    await tester.pumpAndSettle();
    expect(
      find.text('Your expired stories, only visible to you'),
      findsOneWidget,
    );
  });

  testWidgets('an empty archive explains how stories get here', (tester) async {
    // "Nothing archived yet" alone would read as a fault. It has to say the
    // archive fills itself after 24 hours.
    await tester.pumpWidget(host(loader: empty));
    await tester.pumpAndSettle();
    expect(find.text('Nothing archived yet'), findsOneWidget);
    expect(find.textContaining('24 hours'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry rather than an empty grid',
      (tester) async {
    await tester.pumpWidget(host(loader: broken));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load archive'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('an archived text story renders as a tile', (tester) async {
    // Text stories have no thumbnail; without their own background they would
    // be blank squares.
    await tester.pumpWidget(host(loader: withOne));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-archive-grid')), findsOneWidget);
    expect(find.byKey(const Key('archive-tile-s1')), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });
}
