import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/pages/announcements/announcement_screen.dart';
import 'package:bananatalk_app/providers/announcement_provider.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/api_client.dart';

Widget _wrap(Future<Announcement?> Function() load, {String id = 'a1'}) =>
    ProviderScope(
      overrides: [
        announcementDetailProvider(id).overrideWith((ref) => load()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AnnouncementScreen(id: id),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the announcement and marks it seen', (t) async {
    await t.pumpWidget(_wrap(() async => const Announcement(
        id: 'a1',
        title: 'Big news',
        body: 'Details',
        buttonLabel: 'Open',
        buttonUrl: 'https://banatalk.com')));
    await t.pumpAndSettle();
    expect(find.text('Big news'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(await AnnouncementSeenStore.read(), contains('a1'));
  });

  testWidgets('no button when the link is not openable', (t) async {
    await t.pumpWidget(_wrap(() async => const Announcement(
        id: 'a1',
        title: 'T',
        body: 'B',
        buttonLabel: 'Go',
        buttonUrl: 'javascript:alert(1)')));
    await t.pumpAndSettle();
    expect(find.text('Go'), findsNothing);
  });

  testWidgets('loading state shows a spinner', (t) async {
    await t.pumpWidget(_wrap(() => Future.delayed(
        const Duration(seconds: 1), () => null)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.pumpAndSettle();
  });

  testWidgets('gone (404): unavailable, no retry, not marked seen', (t) async {
    await t.pumpWidget(_wrap(() async => null));
    await t.pumpAndSettle();
    expect(
        find.text('This announcement is no longer available.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(await AnnouncementSeenStore.read(), isEmpty);
  });

  testWidgets('failure: unavailable with retry', (t) async {
    await t.pumpWidget(_wrap(() async => throw Exception('offline')));
    await t.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('blank id shows unavailable without any request', (t) async {
    await t.pumpWidget(_wrap(() async => null, id: '  '));
    await t.pumpAndSettle();
    expect(
        find.text('This announcement is no longer available.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  group('response mapping (backend real shapes)', () {
    // controllers/announcements.js: 200 { success, data: toPublic(doc) };
    // unknown / draft / scheduled / malformed id -> 404
    // { success:false, error:'Announcement not found' }; no/expired token -> 401.
    test('200 fixture parses', () {
      final a = announcementFromResponse(ApiResponse(
        success: true,
        statusCode: 200,
        data: {
          'id': '65f1c0ffee0000000000abcd',
          'title': 'Big news',
          'body': 'Details',
          'emoji': '🎉',
          'imageUrl': null,
          'buttonLabel': 'Open',
          'buttonUrl': 'bananatalk://boost',
          'priority': 5,
        },
      ));
      expect(a, isNotNull);
      expect(a!.id, '65f1c0ffee0000000000abcd');
      expect(a.emoji, '🎉');
      expect(a.hasButton, isTrue);
      expect(a.priority, 5);
    });

    test('404 (unknown, draft, ended-and-removed, bad id) -> null', () {
      expect(
          announcementFromResponse(ApiResponse(
              success: false,
              statusCode: 404,
              error: 'Announcement not found')),
          isNull);
    });

    test('401, 500 and network failure throw so Retry shows', () {
      for (final code in [401, 500, 0]) {
        expect(
            () => announcementFromResponse(
                ApiResponse(success: false, statusCode: code, error: 'x')),
            throwsException);
      }
    });

    test('200 with a non-object body throws', () {
      expect(
          () => announcementFromResponse(
              ApiResponse(success: true, statusCode: 200, data: 'oops')),
          throwsException);
    });
  });

  test('the route exists', () {
    expect(
        File('lib/router/app_router.dart')
            .readAsStringSync()
            .contains("path: '/announcement/:id'"),
        isTrue);
  });
}
