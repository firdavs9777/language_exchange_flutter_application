import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/hashtag/hashtag_page_screen.dart';
import 'package:bananatalk_app/providers/hashtag_providers.dart';
import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/services/hashtag_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/moment_fixture.dart';

class _FakeService extends HashtagService {
  _FakeService(this.handler);
  final Future<HashtagPage> Function(String tag, String sort, int page) handler;
  final calls = <({String tag, String sort, int page})>[];

  @override
  Future<HashtagPage> moments(
    String tag, {
    String sort = 'top',
    int page = 1,
    int limit = 12,
  }) {
    calls.add((tag: tag, sort: sort, page: page));
    return handler(tag, sort, page);
  }
}

HashtagPage _page({
  String tag = 'korean',
  int postCount = 3,
  String? related,
  List<String> ids = const ['a', 'b'],
  bool hasNext = false,
}) => HashtagPage(
  tag: tag,
  postCount: postCount,
  relatedTopic: related,
  moments: [for (final id in ids) buildMoment(id: id, description: 'post $id')],
  hasNextPage: hasNext,
);

Widget _app(_FakeService service, {String tag = '#Korean'}) => ProviderScope(
  overrides: [hashtagServiceProvider.overrideWithValue(service)],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HashtagPageScreen(tag: tag),
  ),
);

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(HashtagPageScreen)))!;

void main() {
  testWidgets('title is the tag as typed, then the server tag; shows count', (
    tester,
  ) async {
    final gate = Completer<HashtagPage>();
    final service = _FakeService((_, __, ___) => gate.future);
    await tester.pumpWidget(_app(service));
    expect(find.text('#korean'), findsOneWidget); // decoded + normalised
    expect(find.byKey(const ValueKey('hashtag-skeleton')), findsOneWidget);
    gate.complete(_page(tag: 'korean', postCount: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_l10n(tester).hashtagPostCount(3)), findsOneWidget);
    expect(find.text('post a'), findsOneWidget);
    expect(service.calls.single.sort, 'top');
  });

  testWidgets('Top to Recent reloads with sort recent', (tester) async {
    final service = _FakeService((_, __, ___) async => _page());
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(_l10n(tester).hashtagSortRecent));
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls.map((c) => c.sort), ['top', 'recent']);
  });

  testWidgets('related topic banner', (tester) async {
    final service = _FakeService(
      (_, __, ___) async => _page(related: 'cooking'),
    );
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(_l10n(tester).hashtagShowingRelated('cooking')),
      findsOneWidget,
    );
  });

  testWidgets('no related topic: no banner', (tester) async {
    final service = _FakeService((_, __, ___) async => _page());
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('cooking'), findsNothing);
    expect(find.byKey(const ValueKey('hashtag-related')), findsNothing);
  });

  testWidgets('empty state (also what a 404 / flag-off deep link gives)', (
    tester,
  ) async {
    final service = _FakeService((tag, _, __) async => HashtagPage.empty(tag));
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_l10n(tester).hashtagEmpty), findsOneWidget);
  });

  testWidgets('error shows Retry, which loads again', (tester) async {
    var fail = true;
    final service = _FakeService((_, __, ___) async {
      if (fail) throw Exception('boom');
      return _page();
    });
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(seconds: 1));
    final l10n = _l10n(tester);
    expect(find.text(l10n.failedToLoadMoments), findsOneWidget);
    fail = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pump(); // the reload starts
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('post a'), findsOneWidget);
  });

  testWidgets('unusable tag: empty state without a request', (tester) async {
    final service = _FakeService((_, __, ___) async => _page());
    await tester.pumpWidget(_app(service, tag: '# !'));
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, isEmpty);
    expect(find.text(_l10n(tester).hashtagEmpty), findsOneWidget);
  });

  testWidgets('load more failure: Retry row shows a spinner while retrying', (
    tester,
  ) async {
    final retry = Completer<HashtagPage>();
    var failOnce = true;
    final service = _FakeService((_, __, page) {
      if (page == 1) return Future.value(_page(ids: ['a'], hasNext: true));
      if (failOnce) {
        failOnce = false;
        return Future.error(Exception('x'));
      }
      return retry.future;
    });
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(seconds: 1));
    final row = find.byKey(const ValueKey('feed-load-more-failed'));
    await tester.scrollUntilVisible(row, 300);
    await tester.pump(const Duration(seconds: 1));
    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.retry));
    await tester.pump();
    expect(find.text(l10n.retry), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feed-load-more-failed')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    retry.complete(_page(ids: ['z'], hasNext: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('feed-load-more-failed')), findsNothing);
  });

  testWidgets('a literal % in the (already decoded) tag does not throw', (
    tester,
  ) async {
    final service = _FakeService((_, __, ___) async => _page(tag: '100'));
    await tester.pumpWidget(_app(service, tag: '100%'));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(service.calls.single.tag, '100');
    expect(find.text('#100'), findsOneWidget);
  });

  testWidgets('an already decoded %41 is not decoded again', (tester) async {
    final service = _FakeService((_, __, ___) async => _page(tag: '41'));
    await tester.pumpWidget(_app(service, tag: '%41'));
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls.single.tag, '41');
  });
}
