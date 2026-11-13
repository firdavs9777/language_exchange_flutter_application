import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/session_reset.dart';
import 'package:bananatalk_app/widgets/community/partner_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task 4: with the fast-list flag on, a Partners list loaded under 10 minutes
/// ago for the same filters survives a tab switch (the tab State is rebuilt,
/// the provider is not). Flag off: every mount reloads, as before.
Community _u(String id) => Community.fromJson({
  '_id': id,
  'name': 'Person $id',
  'native_language': 'Korean',
  'language_to_learn': 'English',
  'location': {'type': 'Point', 'coordinates': [0, 0], 'city': '', 'country': ''},
});

class _FakeService extends CommunityService {
  final queries = <Map<String, String>>[];
  Completer<PaginatedCommunityResponse>? gate;
  bool fail = false;

  @override
  Future<PaginatedCommunityResponse> getUsersPage(Map<String, String> query) {
    queries.add(query);
    if (gate != null) return gate!.future;
    if (fail) return Future.error(Exception('down'));
    return Future.value(
      PaginatedCommunityResponse(
        users: [_u('a'), _u('b'), _u('c'), _u('d'), _u('e'), _u('f')],
        total: 6,
        page: 1,
        pages: 1,
        hasMore: false,
      ),
    );
  }
}

Community _me() => Community.fromJson({
  '_id': 'me',
  'name': 'Me',
  'native_language': 'English',
  'language_to_learn': 'Korean',
  'location': {'type': 'Point', 'coordinates': [0, 0], 'city': 'Seoul', 'country': 'Korea'},
});

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  const a = PartnerFilterParams(gender: 'female');
  const b = PartnerFilterParams(gender: 'male');
  final t0 = DateTime(2026, 11, 14, 12);

  group('PartnerFilterNotifier.isFreshFor', () {
    late _FakeService service;
    late DateTime now;
    late bool flag;
    late PartnerFilterNotifier n;

    setUp(() {
      service = _FakeService();
      now = t0;
      flag = true;
      n = PartnerFilterNotifier(service, () => false, () => flag, () => now);
    });

    test('false before anything was loaded', () {
      expect(n.isFreshFor(a), isFalse);
    });

    test('true right after a successful page 1, for equal filters only', () async {
      await n.loadWithFilters(a);
      expect(n.isFreshFor(a), isTrue);
      expect(n.isFreshFor(const PartnerFilterParams(gender: 'female')), isTrue);
      expect(n.isFreshFor(b), isFalse);
      // The search query is part of the filters.
      expect(n.isFreshFor(a.copyWith(search: 'kim')), isFalse);
    });

    test('false from 10 minutes on', () async {
      await n.loadWithFilters(a);
      expect(n.isFreshFor(a, now: t0.add(const Duration(minutes: 9, seconds: 59))), isTrue);
      expect(n.isFreshFor(a, now: t0.add(const Duration(minutes: 10))), isFalse);
      now = t0.add(const Duration(minutes: 11));
      expect(n.isFreshFor(a), isFalse);
    });

    test('false with the flag off, however fresh', () async {
      await n.loadWithFilters(a);
      flag = false;
      expect(n.isFreshFor(a), isFalse);
    });

    test('false when the last page-1 load failed', () async {
      await n.loadWithFilters(a);
      service.fail = true;
      await n.refresh();
      expect(n.isFreshFor(a), isFalse);
    });

    test('false after clear()', () async {
      await n.loadWithFilters(a);
      n.clear();
      expect(n.isFreshFor(a), isFalse);
    });

    test('kept exclusions: server set plus local hides; flag off keeps nothing', () {
      n.rememberServerExcluded({'x'});
      n.hideLocally('y');
      expect(n.hasKeptExclusions, isTrue);
      expect(n.keptExclusions, {'x', 'y'});
      n.rememberServerExcluded({'z'});
      expect(n.keptExclusions, {'z', 'y'});
      n.clearLocalHides();
      expect(n.keptExclusions, {'z'});
      n.clear();
      expect(n.hasKeptExclusions, isFalse);

      flag = false;
      n.rememberServerExcluded({'x'});
      n.hideLocally('y');
      expect(n.hasKeptExclusions, isFalse);
      expect(n.keptExclusions, isEmpty);
    });
  });

  group('Partners tab remount', () {
    late _FakeService service;
    late DateTime now;
    late bool flag;
    late int excludedCalls;
    late Set<String> excludedIds;
    Completer<void>? excludedGate;
    late ProviderContainer container;
    late http.Client client;
    var showTab = true;
    late StateSetter swap;
    Map<String, dynamic> filters = {};

    Future<void> pumpHost(WidgetTester tester, {bool settleNow = true}) async {
      container = ProviderContainer(
        overrides: [
          communityFastListEnabledProvider.overrideWith((ref) => flag),
          userProvider.overrideWith((ref) async => _me()),
          // Never refetched after the block, as when the fetch is slow or
          // failed (the real provider swallows errors into a stale/empty set).
          blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
          partnerFilterProvider.overrideWith(
            (ref) => PartnerFilterNotifier(
              service,
              () => false,
              () => flag,
              () => now,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, set) {
                  swap = set;
                  return showTab
                      ? PartnerDiscoveryTab(filters: filters, searchQuery: '')
                      : const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      if (settleNow) await settle(tester);
    }

    Future<void> switchAwayAndBack(WidgetTester tester, {Map<String, dynamic>? whileAway}) async {
      swap(() => showTab = false);
      await tester.pump();
      if (whileAway != null) filters = whileAway;
      swap(() => showTab = true);
      await settle(tester);
    }

    void run(String name, Future<void> Function(WidgetTester) body, {String? view}) {
      testWidgets(name, (tester) async {
        SharedPreferences.setMockInitialValues({
          'userId': 'me',
          if (view != null) 'partner_discovery_view_mode': view,
        });
        service = _FakeService();
        now = DateTime(2026, 11, 14, 12);
        flag = true;
        excludedCalls = 0;
        excludedIds = {};
        excludedGate = null;
        showTab = true;
        filters = {};
        client = MockClient((req) async {
          if (req.url.path.endsWith('interactions/excluded')) {
            excludedCalls++;
            final gate = excludedGate;
            if (gate != null) await gate.future;
            return http.Response('{"data": ${excludedIds.map((e) => '"$e"').toList()}}', 200);
          }
          return http.Response('{"message": "ok"}', 200);
        });
        await http.runWithClient(() => body(tester), () => client);
      });
    }

    run('flag off: remount reloads page 1 and re-asks for exclusions', (tester) async {
      flag = false;
      await pumpHost(tester);
      expect(service.queries.length, 1);
      expect(excludedCalls, 1);
      await switchAwayAndBack(tester);
      expect(service.queries.length, 2);
      expect(excludedCalls, 2);
    });

    run('flag on: remount within 10 minutes asks for neither', (tester) async {
      await pumpHost(tester);
      expect(service.queries.length, 1);
      expect(excludedCalls, 1);
      now = now.add(const Duration(minutes: 9));
      await switchAwayAndBack(tester);
      expect(service.queries.length, 1);
      expect(excludedCalls, 1);
      expect(find.text('Person a'), findsOneWidget);
    });

    run('flag on: remount after 11 minutes asks for both', (tester) async {
      await pumpHost(tester);
      now = now.add(const Duration(minutes: 11));
      await switchAwayAndBack(tester);
      expect(service.queries.length, 2);
      expect(excludedCalls, 2);
    });

    run('flag on: a filter changed while away reloads', (tester) async {
      await pumpHost(tester);
      await switchAwayAndBack(tester, whileAway: {'gender': 'male'});
      expect(service.queries.length, 2);
    });

    run('flag on: a mount while page 1 is in flight starts no second load', (tester) async {
      service.gate = Completer();
      await pumpHost(tester);
      expect(service.queries.length, 1);
      await switchAwayAndBack(tester);
      expect(service.queries.length, 1);
      service.gate!.complete(
        PaginatedCommunityResponse(users: [_u('a')], total: 1, page: 1, pages: 1, hasMore: false),
      );
      await settle(tester);
      expect(find.text('Person a'), findsOneWidget);
    });

    run('flag on: the kept list is still filtered by the server exclusions', (tester) async {
      excludedIds = {'a'};
      await pumpHost(tester);
      expect(find.text('Person a'), findsNothing);
      expect(find.text('Person c'), findsOneWidget);
      excludedIds = {};
      await switchAwayAndBack(tester);
      expect(excludedCalls, 1);
      expect(find.text('Person a'), findsNothing);
      expect(find.text('Person c'), findsOneWidget);
    });

    run('flag on: a user skipped this session stays hidden after a remount', (tester) async {
      await pumpHost(tester);
      expect(find.text('Person a'), findsOneWidget);
      // Swipe view shows one card at a time; skip the first one.
      final skipped = container.read(partnerFilterProvider.notifier);
      tester
          .widgetList<PartnerCard>(find.byType(PartnerCard))
          .firstWhere((c) => c.onSkip != null)
          .onSkip!();
      await settle(tester);
      expect(skipped.keptExclusions, isNotEmpty);
      final gone = skipped.keptExclusions.single;
      await switchAwayAndBack(tester);
      expect(service.queries.length, 1);
      expect(find.text('Person $gone'), findsNothing);
    }, view: 'swipe');

    run('flag on: a user blocked while the tab is away is gone on return, even if the blocked-ids provider is not refetched', (tester) async {
      await pumpHost(tester);
      expect(find.text('Person a'), findsOneWidget);
      swap(() => showTab = false);
      await tester.pump();
      SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
      final result = await BlockService.blockUser(
        currentUserId: 'me',
        blockedUserId: 'a',
        blockedUserName: 'B',
      );
      expect(result['success'], isTrue);
      swap(() => showTab = true);
      await settle(tester);
      expect(service.queries.length, 1);
      expect(find.text('Person a'), findsNothing);
    });

    run('flag on: blocked while away, then unblocked: back after a '
        'pull-to-refresh', (tester) async {
      await pumpHost(tester);
      swap(() => showTab = false);
      await tester.pump();
      SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
      await BlockService.blockUser(
        currentUserId: 'me',
        blockedUserId: 'a',
        blockedUserName: 'B',
      );
      swap(() => showTab = true);
      await settle(tester);
      expect(find.text('Person a'), findsNothing);
      final result = await BlockService.unblockUser(
        currentUserId: 'me',
        blockedUserId: 'a',
      );
      expect(result['success'], isTrue);
      await settle(tester);
      // Not re-inserted until a reload.
      expect(find.text('Person a'), findsNothing);
      unawaited(tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show());
      await settle(tester);
      expect(service.queries.length, 2);
      expect(find.text('Person a'), findsOneWidget);
    });

    test('removeUser: flag off changes nothing', () async {
      final n = PartnerFilterNotifier(_FakeService(), () => false, () => false);
      await n.loadWithFilters(a);
      n.removeUser('a');
      expect(n.state.users.map((u) => u.id), contains('a'));
      expect(n.keptExclusions, isEmpty);
    });

    run('sign-out then another user: nothing of the previous list or exclusions survives', (tester) async {
      excludedIds = {'a'};
      await pumpHost(tester);
      expect(find.text('Person a'), findsNothing);
      swap(() => showTab = false);
      await tester.pump();
      invalidateUserScopedProviders(container.invalidate);
      excludedIds = {};
      swap(() => showTab = true);
      await settle(tester);
      expect(service.queries.length, 2);
      expect(excludedCalls, 2);
      expect(find.text('Person a'), findsOneWidget);
    });

    run('flag on: a session skip stays hidden on a remount before any '
        'exclusions fetch has answered', (tester) async {
      excludedGate = Completer();
      await pumpHost(tester);
      final kept = container.read(partnerFilterProvider.notifier);
      expect(kept.hasKeptExclusions, isFalse);
      tester
          .widgetList<PartnerCard>(find.byType(PartnerCard))
          .firstWhere((c) => c.onSkip != null)
          .onSkip!();
      await settle(tester);
      final gone = kept.keptExclusions.single;
      await switchAwayAndBack(tester);
      expect(service.queries.length, 1);
      expect(excludedCalls, 2);
      expect(find.text('Person $gone'), findsNothing);
      excludedGate!.complete();
      await settle(tester);
      // The fetch landing (the server has no record of the skip yet) does
      // not bring them back either.
      expect(find.text('Person $gone'), findsNothing);
    }, view: 'swipe');

    for (final on in [false, true]) {
      run('flag ${on ? 'on' : 'off'}: the first load lands on the live '
          'notifier when the provider is reset before it starts', (tester) async {
        flag = on;
        await pumpHost(tester, settleNow: false);
        // Reset the provider after every frame until the load has started:
        // the frame that schedules the load is followed by a reset before
        // the scheduled load runs.
        for (var i = 0; i < 20 && service.queries.isEmpty; i++) {
          await tester.pump();
          if (service.queries.isEmpty) {
            container.invalidate(partnerFilterProvider);
          }
        }
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(service.queries.length, 1);
        expect(container.read(partnerFilterProvider).filters, isNotNull);
        expect(find.text('Person a'), findsOneWidget);
      });
    }

    run('flag on: pull-to-refresh still reloads', (tester) async {
      await pumpHost(tester);
      unawaited(tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show());
      await settle(tester);
      expect(service.queries.length, 2);
    });
  });
}
