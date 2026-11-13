import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/community_first_page_cache.dart';
import 'package:bananatalk_app/services/session_reset.dart';
import 'package:bananatalk_app/widgets/community/partner_card.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/recording_prefs.dart';

/// Task 5: with the fast-list flag on, page 1 of the default Partners view is
/// kept on disk per user and painted on the next cold open, then replaced by
/// the network page. Flag off: nothing is read or written.
Map<String, dynamic> _raw(String id) => {
      '_id': id,
      'name': 'Person $id',
      'native_language': 'Korean',
      'language_to_learn': 'English',
      'location': {'type': 'Point', 'coordinates': [0, 0], 'city': '', 'country': ''},
    };

PaginatedCommunityResponse _page(List<String> ids, {bool hasMore = false}) {
  final raws = [for (final id in ids) _raw(id)];
  return PaginatedCommunityResponse(
    users: [for (final r in raws) Community.fromJson(r)],
    rawUsers: raws,
    total: ids.length,
    page: 1,
    pages: 1,
    hasMore: hasMore,
  );
}

class _FakeService extends CommunityService {
  final queries = <Map<String, String>>[];
  Completer<PaginatedCommunityResponse>? gate;
  bool fail = false;
  List<String> ids = ['a', 'b', 'c', 'd', 'e', 'f'];

  @override
  Future<PaginatedCommunityResponse> getUsersPage(Map<String, String> query) {
    queries.add(query);
    if (gate != null) return gate!.future;
    if (fail) return Future.error(Exception('down'));
    return Future.value(_page(ids));
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

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

const _default = PartnerFilterParams(learningLanguage: 'Korean', nativeLanguage: 'English');

Future<void> _seed(String userId, List<String> ids,
    {PartnerFilterParams filters = _default, DateTime? at}) {
  return CommunityFirstPageCache(now: at == null ? null : () => at).write(
    userId: userId,
    slot: CommunityFirstPageCache.partners,
    rows: [for (final id in ids) _raw(id)],
    meta: {'fingerprint': PartnerFilterNotifier.diskFingerprint(filters)},
  );
}

List<String> _ids(PartnerFilterState s) => s.users.map((u) => u.id).toList();

void main() {
  group('PartnerFilterNotifier disk-first', () {
    late _FakeService service;
    late bool flag;
    late bool smart;
    late RecordingPrefs prefs;
    late CommunityFirstPageCache cache;

    PartnerFilterNotifier make() => PartnerFilterNotifier(
          service,
          () => smart,
          () => flag,
          DateTime.now,
          cache,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({'userId': 'me'});
      service = _FakeService();
      flag = true;
      smart = false;
      prefs = RecordingPrefs(await SharedPreferences.getInstance());
      cache = CommunityFirstPageCache(prefs: RecordingPrefs.getter(prefs));
    });

    /// A cache whose every preferences access waits for [gate].
    CommunityFirstPageCache gated(Completer<void> gate) =>
        CommunityFirstPageCache(prefs: () async {
          await gate.future;
          return prefs;
        });

    test('flag off: no preferences call at all, no paint, no write', () async {
      await _seed('me', ['x', 'y']);
      flag = false;
      final n = make();
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      expect(n.state.users, isEmpty);
      expect(n.state.fromCache, isFalse);
      service.gate!.complete(_page(['a']));
      await load;
      service.gate = null;
      await n.refresh();
      await n.loadWithFilters(const PartnerFilterParams(gender: 'male'));
      await _flush();
      expect(_ids(n.state), ['a', 'b', 'c', 'd', 'e', 'f']);
      expect(prefs.calls, isEmpty);
      // The seeded entry is untouched.
      final kept = await CommunityFirstPageCache()
          .read(userId: 'me', slot: CommunityFirstPageCache.partners);
      expect(kept!.rows.map((r) => r['_id']), ['x', 'y']);
    });

    test('flag on, cold start: cached rows first, then the network page',
        () async {
      await _seed('me', ['x', 'y']);
      final n = make();
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      expect(_ids(n.state), ['x', 'y']);
      expect(n.state.fromCache, isTrue);
      expect(n.state.isLoading, isTrue);
      expect(service.queries, hasLength(1));
      service.gate!.complete(_page(['a', 'b']));
      await load;
      expect(_ids(n.state), ['a', 'b']);
      expect(n.state.fromCache, isFalse);
      expect(n.state.isLoading, isFalse);
      await _flush();
      final written = await CommunityFirstPageCache()
          .read(userId: 'me', slot: CommunityFirstPageCache.partners);
      expect(written!.rows.map((r) => r['_id']), ['a', 'b']);
      expect(written.meta['fingerprint'],
          PartnerFilterNotifier.diskFingerprint(_default));
    });

    test('someone blocked this session is not painted from disk', () async {
      // The block removes them from disk too; this covers a copy written
      // after that (or a removal that failed).
      await _seed('me', ['x', 'y']);
      final blocks = StreamController<String>.broadcast(sync: true);
      addTearDown(blocks.close);
      final n = PartnerFilterNotifier(
        service,
        () => smart,
        () => flag,
        DateTime.now,
        cache,
        blocks.stream,
      );
      blocks.add('x');
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      expect(_ids(n.state), ['y']);
      expect(n.state.fromCache, isTrue);
      service.gate!.complete(_page(['x', 'a']));
      await load;
      expect(_ids(n.state), ['a']);
    });

    test('a cache for another filter fingerprint is ignored', () async {
      await _seed('me', ['x'], filters: const PartnerFilterParams(gender: 'male'));
      final n = make();
      service.gate = Completer();
      unawaited(n.loadWithFilters(_default, diskCacheable: true));
      await _flush();
      expect(n.state.users, isEmpty);
      expect(n.state.fromCache, isFalse);
    });

    test('a non-default view neither paints nor writes', () async {
      await _seed('me', ['x']);
      final n = make();
      await n.loadWithFilters(_default);
      await _flush();
      expect(n.state.fromCache, isFalse);
      expect(prefs.calls, isEmpty);
      final kept = await CommunityFirstPageCache()
          .read(userId: 'me', slot: CommunityFirstPageCache.partners);
      expect(kept!.rows.map((r) => r['_id']), ['x']);
    });

    test('another user\'s cache is never painted', () async {
      await _seed('someone', ['x']);
      final n = make();
      service.gate = Completer();
      unawaited(n.loadWithFilters(_default, diskCacheable: true));
      await _flush();
      expect(n.state.users, isEmpty);
    });

    test('paints from disk only once: not on refresh, filter change or error',
        () async {
      await _seed('me', ['x']);
      final n = make();
      await n.loadWithFilters(_default, diskCacheable: true);
      expect(_ids(n.state).first, 'a');
      // Put a cache back on disk: a repaint would show it.
      await _seed('me', ['x']);
      service.gate = Completer();
      unawaited(n.refresh());
      await _flush();
      expect(_ids(n.state).first, 'a');
      expect(n.state.fromCache, isFalse);
      service.gate!.completeError(Exception('down'));
      await _flush();
      expect(_ids(n.state).first, 'a');
      service.gate = null;
      // A new filter set, then back to the default one.
      service.gate = Completer();
      unawaited(n.loadWithFilters(const PartnerFilterParams(gender: 'male')));
      await _flush();
      unawaited(n.loadWithFilters(_default, diskCacheable: true));
      await _flush();
      expect(n.state.users, isEmpty);
      expect(n.state.fromCache, isFalse);
    });

    test('flag false at the first load, true later: no late paint', () async {
      await _seed('me', ['x']);
      flag = false;
      final n = make();
      service.fail = true;
      await n.loadWithFilters(_default, diskCacheable: true);
      flag = true;
      service.fail = false;
      service.gate = Completer();
      unawaited(n.refresh());
      await _flush();
      expect(n.state.users, isEmpty);
      expect(n.state.fromCache, isFalse);
    });

    test('loadMore does nothing while the list is from disk', () async {
      await _seed('me', ['x', 'y']);
      final n = make();
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      expect(n.state.fromCache, isTrue);
      await n.loadMore();
      await n.loadMore(force: true);
      expect(service.queries, hasLength(1));
      service.gate!.complete(_page(['a'], hasMore: true));
      await load;
      service.gate = null;
      await n.loadMore();
      expect(service.queries, hasLength(2));
      expect(service.queries.last['page'], '2');
    });

    test('a list painted from disk is not fresh', () async {
      await _seed('me', ['x']);
      final n = make();
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      expect(n.state.fromCache, isTrue);
      expect(n.isFreshFor(_default), isFalse);
      service.gate!.complete(_page(['a']));
      await load;
      expect(n.isFreshFor(_default), isTrue);
    });

    test('network failure: cached rows stay with the error; Retry reloads page 1',
        () async {
      await _seed('me', ['x', 'y']);
      final n = make();
      service.fail = true;
      await n.loadWithFilters(_default, diskCacheable: true);
      expect(_ids(n.state), ['x', 'y']);
      expect(n.state.fromCache, isTrue);
      expect(n.state.error, isNotNull);
      expect(n.state.isLoading, isFalse);
      expect(n.isFreshFor(_default), isFalse);
      // The tab's Retry row calls loadMore(force: true): page 1 again.
      service.fail = false;
      await n.loadMore(force: true);
      expect(service.queries.last['page'], '1');
      expect(_ids(n.state).first, 'a');
      expect(n.state.fromCache, isFalse);
    });

    test('a fetch that outlives an account switch writes nothing', () async {
      final n = make();
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      await prefs.setString('userId', 'other');
      service.gate!.complete(_page(['a']));
      await load;
      await _flush();
      for (final id in ['me', 'other']) {
        expect(
            await CommunityFirstPageCache()
                .read(userId: id, slot: CommunityFirstPageCache.partners),
            isNull);
      }
    });

    test('rows written are the raw maps, without the signed-in user', () async {
      service.ids = ['me', 'a'];
      final n = make();
      await n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      final written = await CommunityFirstPageCache()
          .read(userId: 'me', slot: CommunityFirstPageCache.partners);
      expect(written!.rows.single, _raw('a'));
    });

    test('the fingerprint includes the effective sort', () {
      expect(PartnerFilterNotifier.diskFingerprint(_default, sort: 'smart'),
          isNot(PartnerFilterNotifier.diskFingerprint(_default)));
      expect(
          PartnerFilterNotifier.diskFingerprint(_default, sort: 'smart'),
          PartnerFilterNotifier.diskFingerprint(_default, sort: 'smart'));
    });

    test('a page cached under one ordering is not painted under another',
        () async {
      await _seed('me', ['x']); // written with smart sort off
      smart = true;
      final n = make();
      service.gate = Completer();
      unawaited(n.loadWithFilters(_default, diskCacheable: true));
      await _flush();
      expect(n.state.users, isEmpty);
      expect(n.state.fromCache, isFalse);
    });

    test('a filter change while the disk read is pending wins', () async {
      await _seed('me', ['x']);
      final gate = Completer<void>();
      cache = gated(gate);
      final n = make();
      final first = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      const male = PartnerFilterParams(gender: 'male');
      final second = n.loadWithFilters(male);
      await _flush();
      gate.complete();
      await first;
      await second;
      await _flush();
      expect(n.state.filters, male);
      expect(n.state.fromCache, isFalse);
      expect(_ids(n.state), ['a', 'b', 'c', 'd', 'e', 'f']);
      expect(service.queries.where((q) => q['gender'] == 'male'), hasLength(1));
    });

    test('a notifier disposed during the disk read throws nothing', () async {
      await _seed('me', ['x']);
      final gate = Completer<void>();
      cache = gated(gate);
      final n = make();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      n.dispose();
      gate.complete();
      await load;
      await _flush();
      expect(service.queries, isEmpty);
    });

    test('a page-1 write that straddles a sign-out writes nothing', () async {
      final n = make();
      service.gate = Completer();
      final load = n.loadWithFilters(_default, diskCacheable: true);
      await _flush();
      // Sign-out has cleared the cache; the stored userId is not gone yet.
      await CommunityFirstPageCache().clearAll();
      service.gate!.complete(_page(['a']));
      await load;
      await _flush();
      expect(
          await CommunityFirstPageCache()
              .read(userId: 'me', slot: CommunityFirstPageCache.partners),
          isNull);
    });
  });

  group('Partners tab', () {
    late _FakeService service;
    late bool flag;
    late Set<String> excludedIds;
    late Completer<void>? excludedGate;
    late ProviderContainer container;
    late http.Client client;
    var showTab = true;
    late StateSetter swap;
    String search = '';
    CommunityFirstPageCache? tabCache;

    Future<void> pumpHost(WidgetTester tester) async {
      container = ProviderContainer(
        overrides: [
          communityFastListEnabledProvider.overrideWith((ref) => flag),
          userProvider.overrideWith((ref) async => _me()),
          blockedUserIdsProvider.overrideWith((ref) async => {'blocked'}),
          partnerFilterProvider.overrideWith(
            (ref) => PartnerFilterNotifier(
              service,
              () => false,
              () => flag,
              DateTime.now,
              tabCache ?? CommunityFirstPageCache(),
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
                      ? PartnerDiscoveryTab(filters: const {}, searchQuery: search)
                      : const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await settle(tester);
    }

    void run(String name, Future<void> Function(WidgetTester) body,
        {String? view}) {
      testWidgets(name, (tester) async {
        SharedPreferences.setMockInitialValues({
          'userId': 'me',
          if (view != null) 'partner_discovery_view_mode': view,
        });
        service = _FakeService();
        flag = true;
        excludedIds = {};
        excludedGate = null;
        showTab = true;
        search = '';
        tabCache = null;
        client = MockClient((req) async {
          if (req.url.path.endsWith('interactions/excluded')) {
            await excludedGate?.future;
            return http.Response(
                '{"data": ${excludedIds.map((e) => '"$e"').toList()}}', 200);
          }
          return http.Response('{}', 200);
        });
        await http.runWithClient(() => body(tester), () => client);
      });
    }

    /// An app restart: the tree and the container (so the notifier) go.
    Future<void> restart(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await pumpHost(tester);
    }

    /// A cold start with [cached] on disk for the default view and the
    /// network page held back.
    Future<void> coldStartWithCache(WidgetTester tester, List<String> cached) async {
      await _seed('me', cached);
      service.ids = ['n1', 'n2'];
      service.gate = Completer();
      await pumpHost(tester);
    }

    run('a first session writes the cache that the next cold start paints',
        (tester) async {
      service.ids = ['x', 'y'];
      await pumpHost(tester);
      expect(find.text('Person x'), findsOneWidget);
      service.gate = Completer();
      await restart(tester);
      expect(find.text('Person x'), findsOneWidget);
      expect(container.read(partnerFilterProvider).fromCache, isTrue);
      service.gate!.complete(_page(['n1']));
      await settle(tester);
      expect(find.text('Person x'), findsNothing);
      expect(find.text('Person n1'), findsOneWidget);
    });

    run('flag off: the tab makes no preferences call for the cache',
        (tester) async {
      await _seed('me', ['x']);
      flag = false;
      final rec = RecordingPrefs(await SharedPreferences.getInstance());
      tabCache = CommunityFirstPageCache(prefs: RecordingPrefs.getter(rec));
      service.gate = Completer();
      await pumpHost(tester);
      expect(find.text('Person x'), findsNothing);
      service.gate!.complete(_page(['n1']));
      await settle(tester);
      expect(find.text('Person n1'), findsOneWidget);
      unawaited(tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show());
      await settle(tester);
      expect(rec.calls, isEmpty);
    });

    run('cached rows all filtered out: the loading skeleton, not the empty '
        'state, until the network page lands', (tester) async {
      excludedIds = {'x', 'y'};
      await coldStartWithCache(tester, ['x', 'y']);
      expect(container.read(partnerFilterProvider).fromCache, isTrue);
      expect(find.text('No partners found'), findsNothing);
      expect(find.byType(UserListSkeleton), findsOneWidget);
      service.gate!.complete(_page(['n1']));
      await settle(tester);
      expect(find.byType(UserListSkeleton), findsNothing);
      expect(find.text('Person n1'), findsOneWidget);
    });

    run('cached rows all filtered out and the network fails: the error body',
        (tester) async {
      excludedIds = {'x'};
      await coldStartWithCache(tester, ['x']);
      service.gate!.completeError(Exception('down'));
      await settle(tester);
      expect(find.text('No partners found'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    run('cold start shows cached rows before the network, then replaces them',
        (tester) async {
      await coldStartWithCache(tester, ['x', 'y']);
      expect(find.text('Person x'), findsOneWidget);
      expect(find.text('Person y'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      service.gate!.complete(_page(['n1', 'n2']));
      await settle(tester);
      expect(find.text('Person x'), findsNothing);
      expect(find.text('Person n1'), findsOneWidget);
    });

    run('cached rows are filtered by server exclusions and blocks', (tester) async {
      // Until the exclusions are known nothing from disk is shown.
      excludedIds = {'skipped'};
      excludedGate = Completer();
      await coldStartWithCache(tester, ['x', 'skipped', 'blocked']);
      expect(find.text('Person x'), findsNothing);
      excludedGate!.complete();
      await settle(tester);
      expect(find.text('Person x'), findsOneWidget);
      expect(find.text('Person skipped'), findsNothing);
      expect(find.text('Person blocked'), findsNothing);
    });

    run('network failure keeps the cached rows and shows the Retry row',
        (tester) async {
      await coldStartWithCache(tester, ['x']);
      service.gate!.completeError(Exception('down'));
      await settle(tester);
      expect(find.text('Person x'), findsOneWidget);
      expect(find.byKey(const Key('partners-load-more-retry')), findsOneWidget);
      service.gate = null;
      await tester.tap(find.byKey(const Key('partners-load-more-retry')));
      await settle(tester);
      expect(find.text('Person n1'), findsOneWidget);
      expect(find.text('Person x'), findsNothing);
    });

    run('a skip after the network page is not reverted by a rebuild',
        (tester) async {
      // The person skipped below is on disk too: a repaint from disk
      // would bring them back.
      await coldStartWithCache(tester, ['n1', 'x']);
      expect(container.read(partnerFilterProvider).fromCache, isTrue);
      service.gate!.complete(_page(['n1', 'n2']));
      await settle(tester);
      expect(container.read(partnerFilterProvider).fromCache, isFalse);
      tester
          .widgetList<PartnerCard>(find.byType(PartnerCard))
          .firstWhere((c) => c.onSkip != null)
          .onSkip!();
      await settle(tester);
      // Remount (kept list) and a failed refresh: neither repaints disk.
      swap(() => showTab = false);
      await tester.pump();
      swap(() => showTab = true);
      await settle(tester);
      service.gate = Completer();
      unawaited(container.read(partnerFilterProvider.notifier).refresh());
      await settle(tester);
      service.gate!.completeError(Exception('down'));
      await settle(tester);
      expect(find.text('Person x'), findsNothing);
      expect(find.text('Person n1'), findsNothing);
      expect(container.read(partnerFilterProvider).fromCache, isFalse);
    }, view: 'swipe');

    run('a search is not the default view: nothing is painted or written',
        (tester) async {
      search = 'kim';
      await pumpHost(tester);
      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs.getKeys().where((k) => k.startsWith(CommunityFirstPageCache.keyPrefix)),
          isEmpty);
    });

    run('user A\'s cache is never shown to user B after a session reset',
        (tester) async {
      service.ids = ['x'];
      await pumpHost(tester);
      expect(find.text('Person x'), findsOneWidget);
      // Sign out (the tab leaves) without clearing disk -- the explicit clear
      // is tested apart -- and sign in as B in the same app session.
      swap(() => showTab = false);
      await tester.pump();
      invalidateUserScopedProviders(container.invalidate);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', 'B');
      service.gate = Completer();
      swap(() => showTab = true);
      await settle(tester);
      expect(find.text('Person x'), findsNothing);
      expect(container.read(partnerFilterProvider).users, isEmpty);
      expect(container.read(partnerFilterProvider).fromCache, isFalse);
    });
  });
}
