import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/moments/feed/hashtag_search_panel.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
import 'package:bananatalk_app/pages/moments/reels/reels_grid_screen.dart';
import 'package:bananatalk_app/providers/hashtag_providers.dart';
import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/hashtag_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/community_fixture.dart';
import '../support/moment_fixture.dart';

class _FakeHashtags extends HashtagService {
  final suggested = <String>[];
  int trendingCalls = 0;
  Future<List<HashtagCount>> Function(String q)? onSuggest;
  Future<List<HashtagCount>> Function()? onTrending;

  @override
  Future<List<HashtagCount>> suggest(String q) {
    suggested.add(q);
    return onSuggest?.call(q) ?? Future.value(const []);
  }

  @override
  Future<List<HashtagCount>> trending() {
    trendingCalls++;
    return onTrending?.call() ?? Future.value(const []);
  }
}

const _korean = HashtagCount(tag: 'korean', postCount: 12);

Widget _panel(_FakeHashtags svc, String query, {void Function(String)? onOpen}) =>
    ProviderScope(
      overrides: [hashtagServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HashtagSearchPanel(query: query, onOpen: onOpen),
        ),
      ),
    );

class _Search {
  final queries = <String?>[];
}

class _ReelsTab extends MomentsFeedTabNotifier {
  _ReelsTab() {
    state = MomentsFeedTab.reels;
  }
}

class _SearchService extends MomentsService {
  _SearchService(this.log);
  final _Search log;
  @override
  Future<Map<String, dynamic>> getMoments(
      {int page = 1, int limit = 10, String? feed, String? q}) async {
    log.queries.add(q);
    return {
      'moments': q == '#zz'
          ? <dynamic>[buildMoment(id: 'zz1', description: 'found zz')]
          : <dynamic>[],
    };
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'me'}));

  group('HashtagSearchPanel', () {
    testWidgets('empty query lists trending tags with counts', (tester) async {
      final svc = _FakeHashtags()
        ..onTrending = () async => [_korean, const HashtagCount(tag: 'food', postCount: 3)];
      String? opened;
      await tester.pumpWidget(_panel(svc, '', onOpen: (t) => opened = t));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(HashtagSearchPanel)))!;
      expect(find.text(l10n.hashtagTrendingTitle), findsOneWidget);
      expect(find.text('#korean'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.text('#food'));
      expect(opened, 'food');
    });

    testWidgets('trending failing or empty shows nothing', (tester) async {
      final svc = _FakeHashtags()..onTrending = () async => throw Exception('x');
      await tester.pumpWidget(_panel(svc, ''));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('Trending hashtags'), findsNothing);
    });

    testWidgets('#ko asks once after 250 ms and lists the results', (tester) async {
      final svc = _FakeHashtags()..onSuggest = (q) async => [_korean];
      await tester.pumpWidget(_panel(svc, '#k'));
      await tester.pumpWidget(_panel(svc, '#ko'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(svc.suggested, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(svc.suggested, ['ko']);
      expect(svc.trendingCalls, 0);
      expect(find.text('#korean'), findsOneWidget);
    });

    testWidgets('a bare # asks nothing', (tester) async {
      final svc = _FakeHashtags();
      await tester.pumpWidget(_panel(svc, '#'));
      await tester.pump(const Duration(seconds: 1));
      expect(svc.suggested, isEmpty);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('a stale response does not replace a newer one', (tester) async {
      final slow = Completer<List<HashtagCount>>();
      final svc = _FakeHashtags()
        ..onSuggest = (q) => q == 'ko'
            ? slow.future
            : Future.value([const HashtagCount(tag: 'korea', postCount: 1)]);
      await tester.pumpWidget(_panel(svc, '#ko'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(_panel(svc, '#kor'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('#korea'), findsOneWidget);
      slow.complete([_korean]);
      await tester.pumpAndSettle();
      expect(find.text('#korea'), findsOneWidget);
      expect(find.text('#korean'), findsNothing);
    });
  });

  group('Moments search', () {
    Widget host(_FakeHashtags svc, _Search log,
            {required bool flag, bool reels = false, List<int>? feedPages}) =>
        ProviderScope(
          overrides: [
            if (reels)
              momentsFeedTabProvider.overrideWith((ref) => _ReelsTab()),
            hashtagServiceProvider.overrideWithValue(svc),
            momentsServiceProvider.overrideWithValue(_SearchService(log)),
            forYouMomentsProvider.overrideWith(() => PagedMomentsFeedNotifier(
                  (ref, page) async {
                    feedPages?.add(page);
                    if (feedPages == null) {
                      return MomentsFeedPage(
                        [buildMoment(id: 'm1', description: 'hello')],
                        hasMore: false,
                      );
                    }
                    return MomentsFeedPage(
                      [
                        for (var i = 0; i < 12; i++)
                          buildMoment(id: 'p$page-$i', description: 'post $i'),
                      ],
                      hasMore: true,
                    );
                  },
                )),
            userProvider.overrideWith((ref) async => buildCommunity()),
            appConfigProvider.overrideWith((ref) async => AppConfig(
                  minVersion: '0',
                  latestVersion: '0',
                  forceUpdate: false,
                  iosUrl: '',
                  androidUrl: '',
                  releaseNotes: '',
                  hashtagsEnabled: flag,
                  reelsEnabled: reels,
                )),
            blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
            promptOfDayProvider.overrideWith((ref) async => <String, dynamic>{}),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MomentsMain(),
          ),
        );

    testWidgets('flag off: no panel, text search runs as today', (tester) async {
      final svc = _FakeHashtags()..onTrending = () async => [_korean];
      final log = _Search();
      await tester.pumpWidget(host(svc, log, flag: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(HashtagSearchPanel), findsNothing);
      await tester.enterText(find.byType(TextField), '#ko');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(log.queries, ['#ko']);
      expect(svc.suggested, isEmpty);
      expect(svc.trendingCalls, 0);
    });

    testWidgets('flag on: empty query shows trending, #ko suggests and skips text search',
        (tester) async {
      final svc = _FakeHashtags()
        ..onTrending = (() async => [_korean])
        ..onSuggest = ((q) async => [_korean]);
      final log = _Search();
      await tester.pumpWidget(host(svc, log, flag: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(HashtagSearchPanel), findsOneWidget);
      expect(find.text('#korean'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '#ko');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(svc.suggested, ['ko']);
      expect(log.queries, isEmpty);

      await tester.enterText(find.byType(TextField), 'ko');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(HashtagSearchPanel), findsNothing);
      expect(log.queries, ['ko']);
    });

    testWidgets('scrolling the panel does not scroll the feed or load more',
        (tester) async {
      final svc = _FakeHashtags()
        ..onTrending = (() async => [
              for (var i = 0; i < 40; i++)
                HashtagCount(tag: 'tag$i', postCount: i),
            ]);
      final pages = <int>[];
      await tester.pumpWidget(
          host(svc, _Search(), flag: true, feedPages: pages));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(HashtagSearchPanel), findsOneWidget);
      final before = List<int>.of(pages);
      for (var i = 0; i < 6; i++) {
        await tester.drag(
          find.descendant(
            of: find.byType(HashtagSearchPanel),
            matching: find.byType(Scrollable),
          ),
          const Offset(0, -600),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('#tag39'), findsOneWidget);
      expect(pages, before);
    });

    testWidgets('trending empty: the feed body stays, no blank screen', (tester) async {
      final svc = _FakeHashtags();
      await tester.pumpWidget(host(svc, _Search(), flag: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('trending failing: the feed body stays', (tester) async {
      final svc = _FakeHashtags()..onTrending = () async => throw Exception('x');
      await tester.pumpWidget(host(svc, _Search(), flag: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('#zz with no suggestions runs the q search once and shows it',
        (tester) async {
      final svc = _FakeHashtags();
      final log = _Search();
      await tester.pumpWidget(host(svc, log, flag: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '#zz');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(svc.suggested, ['zz']);
      expect(log.queries, ['#zz']);
      expect(find.text('found zz'), findsOneWidget);
    });

    testWidgets('a bare # behaves like an empty query', (tester) async {
      final svc = _FakeHashtags();
      final log = _Search();
      await tester.pumpWidget(host(svc, log, flag: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '#');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(svc.suggested, isEmpty);
      expect(log.queries, isEmpty);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('Reels tab: the panel never replaces the grid', (tester) async {
      final svc = _FakeHashtags()..onTrending = () async => [_korean];
      await tester.pumpWidget(host(svc, _Search(), flag: true, reels: true));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ReelsGridScreen), findsOneWidget);
      expect(find.byType(HashtagSearchPanel), findsNothing);
      expect(svc.trendingCalls, 0);
    });
  });
}
