import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/community_fixture.dart';
import '../support/moment_fixture.dart';

/// The Moments tab after the 2026-10-17 layout pass: the header scrolls away
/// with the feed, the tab row stays pinned, the list pages and refreshes.
class _Feed {
  final List<int> requested = [];
  int refreshes = 0;

  Future<MomentsFeedPage> fetch(Ref ref, int page) async {
    requested.add(page);
    if (page == 1) refreshes++;
    final ids = List.generate(10, (i) => 'p$page-$i');
    return MomentsFeedPage(
      ids
          .map((id) => buildMoment(id: id, description: 'moment $id'))
          .toList(),
      hasMore: page < 3,
    );
  }
}

Widget _host(_Feed feed) => ProviderScope(
      overrides: [
        forYouMomentsProvider
            .overrideWith(() => PagedMomentsFeedNotifier(feed.fetch)),
        userProvider.overrideWith((ref) async => buildCommunity()),
        appConfigProvider.overrideWith((ref) async => const AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false, iosUrl: '', androidUrl: '', releaseNotes: '')),
        blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
        promptOfDayProvider.overrideWith((ref) async => <String, dynamic>{}),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MomentsMain(),
      ),
    );

/// The trailing "loading more" spinner never settles, so after a scroll wait
/// a fixed time instead of pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'userId': 'me'});
  });

  testWidgets('shows the For You feed under one compact tab row', (tester) async {
    final feed = _Feed();
    await tester.pumpWidget(_host(feed));
    await tester.pumpAndSettle();

    expect(find.text('moment p1-0'), findsOneWidget);
    expect(find.byKey(const Key('moments-tab-forYou')), findsOneWidget);
    expect(find.byKey(const Key('moments-filter-button')), findsOneWidget);
    // The old Recent / Popular sort chips are gone.
    expect(find.text('Recent'), findsNothing);
    expect(find.text('Popular'), findsNothing);
  });

  testWidgets('the tab row stays pinned while the header scrolls away',
      (tester) async {
    final feed = _Feed();
    await tester.pumpWidget(_host(feed));
    await tester.pumpAndSettle();

    final tabsTop = tester.getTopLeft(find.byKey(const Key('moments-tab-forYou'))).dy;
    await tester.drag(find.text('moment p1-1'), const Offset(0, -600));
    await _settle(tester);
    final tabsTopAfter =
        tester.getTopLeft(find.byKey(const Key('moments-tab-forYou'))).dy;
    expect(tabsTopAfter, lessThan(tabsTop), reason: 'header above scrolled away');
    expect(tabsTopAfter, greaterThanOrEqualTo(kToolbarHeight - 1),
        reason: 'tab row pinned under the app bar');
  });

  testWidgets('scrolling to the end asks for the next page', (tester) async {
    final feed = _Feed();
    await tester.pumpWidget(_host(feed));
    await tester.pumpAndSettle();
    expect(feed.requested, isNot(contains(2)),
        reason: 'a first page that fills the screen does not fetch page 2 by itself');

    for (var i = 0; i < 8 && !feed.requested.contains(2); i++) {
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -800));
      await _settle(tester);
    }
    expect(feed.requested, contains(2));
  });

  testWidgets('pull to refresh reloads page 1', (tester) async {
    final feed = _Feed();
    await tester.pumpWidget(_host(feed));
    await tester.pumpAndSettle();
    final before = feed.refreshes;

    await tester.fling(find.text('moment p1-0'), const Offset(0, 500), 1000);
    await _settle(tester);
    await _settle(tester);
    expect(feed.refreshes, before + 1);
  });
}
