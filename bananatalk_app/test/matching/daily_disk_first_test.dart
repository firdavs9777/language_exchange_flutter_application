import 'dart:async';
import 'dart:convert';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/pages/community/card/match_card.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/community_first_page_cache.dart';
import 'package:bananatalk_app/services/session_reset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/recording_prefs.dart';

/// Task 5: with the fast-list flag on, today's daily batch is kept on disk per
/// user and shown on the next cold open while `matching/daily` loads, until
/// its `nextRefreshAt`. `dailyMatchesProvider` itself is unchanged in shape:
/// the copy from disk is a separate provider the tab shows only while the
/// first fetch has produced nothing. Flag off: nothing is read or written.
Map<String, dynamic> _match(String id) => {
      'user': {
        '_id': id,
        'name': 'Person $id',
        'native_language': 'Korean',
        'language_to_learn': 'English',
      },
      'matchReasons': ['reciprocal_pair'],
    };

final _next = DateTime.now().add(const Duration(hours: 6));

String _body(List<String> ids) => jsonEncode({
      'nextRefreshAt': _next.toUtc().toIso8601String(),
      'matches': [for (final id in ids) _match(id)],
    });

Future<void> _seed(String userId, List<String> ids, {DateTime? next}) =>
    CommunityFirstPageCache().write(
      userId: userId,
      slot: CommunityFirstPageCache.daily,
      rows: [for (final id in ids) _match(id)],
      meta: {'nextRefreshAt': (next ?? _next).toUtc().toIso8601String()},
    );

/// The network: `matching/daily` waits on [dailyGate] (when set) and answers
/// [dailyIds]; skips are recorded.
class _Net {
  Completer<void>? dailyGate;
  List<String> dailyIds = ['n1', 'n2'];
  int dailyStatus = 200;
  int dailyCalls = 0;
  final skips = <String>[];

  late final client = MockClient((req) async {
    if (req.url.path.endsWith('matching/daily')) {
      dailyCalls++;
      final gate = dailyGate;
      if (gate != null) await gate.future;
      return http.Response(
          dailyStatus == 200 ? _body(dailyIds) : '{"success":false}', dailyStatus);
    }
    if (req.url.path.endsWith('interactions/skip')) {
      skips.add(jsonDecode(req.body)['targetUserId'] as String);
      return http.Response('{"data":{}}', 200);
    }
    return http.Response('{}', 200);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late _Net net;
  late bool flag;
  late RecordingPrefs prefs;
  late ProviderContainer container;
  var showTab = true;
  var boosts = false;
  Override? cachedOverride;
  late StateSetter swap;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      communityFastListEnabledProvider.overrideWith((ref) => flag),
      communityFirstPageCacheProvider.overrideWithValue(
        CommunityFirstPageCache(prefs: RecordingPrefs.getter(prefs)),
      ),
      if (boosts)
        appConfigProvider.overrideWith(
            (ref) async => const AppConfig(
                  minVersion: '0',
                  latestVersion: '0',
                  forceUpdate: false,
                  iosUrl: '',
                  androidUrl: '',
                  releaseNotes: '',
                  boostsEnabled: true,
                )),
      if (cachedOverride != null) cachedOverride!,
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pumpTab(WidgetTester tester) async {
    container = makeContainer();
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
                return showTab ? const MatchesTab() : const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> remount(WidgetTester tester) async {
    swap(() => showTab = false);
    await tester.pump();
    swap(() => showTab = true);
    await settle(tester);
  }

  void run(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
      net = _Net();
      flag = true;
      showTab = true;
      boosts = false;
      cachedOverride = null;
      prefs = RecordingPrefs(await SharedPreferences.getInstance());
      await http.runWithClient(() => body(tester), () => net.client);
    });
  }

  Future<CommunityFirstPageSnapshot?> onDisk(String userId) =>
      CommunityFirstPageCache()
          .read(userId: userId, slot: CommunityFirstPageCache.daily);

  run('flag off: no preferences call, no cached paint, nothing written',
      (tester) async {
    await _seed('me', ['x']);
    flag = false;
    net.dailyGate = Completer();
    await pumpTab(tester);
    expect(find.text('Person x'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(container.exists(dailyMatchesCachedProvider), isFalse);
    net.dailyGate!.complete();
    await settle(tester);
    expect(find.text('Person n1'), findsOneWidget);
    expect(prefs.calls, isEmpty);
    expect((await onDisk('me'))!.rows.map(CommunityFirstPageCache.rowUserId), ['x']);
  });

  run('flag on, cold start: the cached batch shows first, then the network one',
      (tester) async {
    await _seed('me', ['x', 'y']);
    net.dailyGate = Completer();
    await pumpTab(tester);
    expect(find.text('Person x'), findsOneWidget);
    expect(find.text('Person y'), findsOneWidget);
    expect(net.dailyCalls, 1);
    net.dailyGate!.complete();
    await settle(tester);
    expect(find.text('Person x'), findsNothing);
    expect(find.text('Person n1'), findsOneWidget);
    final written = await onDisk('me');
    expect(written!.rows.map(CommunityFirstPageCache.rowUserId), ['n1', 'n2']);
    expect(DateTime.parse(written.meta['nextRefreshAt'] as String),
        _next.toUtc());
  });

  run('a cache past its nextRefreshAt is ignored', (tester) async {
    await _seed('me', ['x'],
        next: DateTime.now().subtract(const Duration(minutes: 1)));
    net.dailyGate = Completer();
    await pumpTab(tester);
    expect(find.text('Person x'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    net.dailyGate!.complete();
    await settle(tester);
  });

  run("another user's cache is not shown", (tester) async {
    await _seed('someone', ['x']);
    net.dailyGate = Completer();
    await pumpTab(tester);
    expect(find.text('Person x'), findsNothing);
    net.dailyGate!.complete();
    await settle(tester);
  });

  run('flag false at the first fetch, true later: no late paint',
      (tester) async {
    await _seed('me', ['x']);
    flag = false;
    net.dailyGate = Completer();
    await pumpTab(tester);
    flag = true;
    container.invalidate(communityFastListEnabledProvider);
    await remount(tester);
    expect(find.text('Person x'), findsNothing);
    net.dailyGate!.complete();
    await settle(tester);
  });

  run('session-skipped people are hidden from the cached batch', (tester) async {
    await _seed('me', ['x', 'y']);
    net.dailyGate = Completer();
    container = makeContainer();
    container.read(dailyMatchesSkippedProvider.notifier).state = {'x'};
    // pumpTab makes its own container; reuse this one instead.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MatchesTab()),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Person x'), findsNothing);
    expect(find.text('Person y'), findsOneWidget);
    net.dailyGate!.complete();
    await settle(tester);
  });

  run('card actions work on a cached card: skip hides it, tells the server '
      'and drops it from disk', (tester) async {
    await _seed('me', ['x', 'y']);
    net.dailyGate = Completer();
    await pumpTab(tester);
    for (final card in tester.widgetList<MatchCard>(find.byType(MatchCard))) {
      expect(card.onSayHi, isNotNull);
      expect(card.onWave, isNotNull);
    }
    await tester.tap(find.byKey(const Key('match-skip')).first);
    await settle(tester);
    expect(find.text('Person x'), findsNothing);
    expect(net.skips, ['x']);
    expect((await onDisk('me'))!.rows.map(CommunityFirstPageCache.rowUserId), ['y']);
    net.dailyIds = ['x', 'n1'];
    net.dailyGate!.complete();
    await settle(tester);
    // The session skip set still applies to the network batch.
    expect(find.text('Person x'), findsNothing);
    expect(find.text('Person n1'), findsOneWidget);
  });

  run('a skip after the network batch is not reverted by a rebuild or refresh',
      (tester) async {
    await _seed('me', ['n1', 'x']);
    await pumpTab(tester);
    expect(find.text('Person n1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('match-skip')).first);
    await settle(tester);
    expect(find.text('Person n1'), findsNothing);
    await remount(tester);
    expect(find.text('Person n1'), findsNothing);
    expect(find.text('Person x'), findsNothing);
    net.dailyGate = Completer();
    container.invalidate(dailyMatchesProvider);
    await settle(tester);
    expect(find.text('Person x'), findsNothing);
    expect(find.text('Person n1'), findsNothing);
    net.dailyGate!.complete();
    await settle(tester);
  });

  run('network failure: the error view with Retry, as today', (tester) async {
    await _seed('me', ['x']);
    net.dailyGate = Completer();
    net.dailyStatus = 500;
    await pumpTab(tester);
    expect(find.text('Person x'), findsOneWidget);
    net.dailyGate!.complete();
    await settle(tester);
    expect(find.text('Retry'), findsOneWidget);
    // The disk copy is never painted again in this session.
    net.dailyGate = Completer();
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Person x'), findsNothing);
    net.dailyStatus = 200;
    net.dailyGate!.complete();
    await settle(tester);
    expect(find.text('Person n1'), findsOneWidget);
  });

  run('no extra-matches purchase offer on a cached batch', (tester) async {
    boosts = true;
    await _seed('me', ['x']);
    net.dailyGate = Completer();
    await pumpTab(tester);
    expect(find.text('Person x'), findsOneWidget);
    expect(find.byKey(const Key('extra-matches-cta')), findsNothing);
    net.dailyGate!.complete();
    await settle(tester);
    expect(find.text('Person n1'), findsOneWidget);
    expect(find.byKey(const Key('extra-matches-cta')), findsOneWidget);
  });

  run('the network batch landing before the disk read: the disk copy is '
      'never shown', (tester) async {
    final diskGate = Completer<void>();
    cachedOverride = dailyMatchesCachedProvider.overrideWith((ref) async {
      await diskGate.future;
      return DailyMatchesResult.fromJson({
        'nextRefreshAt': _next.toUtc().toIso8601String(),
        'matches': [_match('x')],
      });
    });
    await pumpTab(tester);
    expect(find.text('Person n1'), findsOneWidget);
    diskGate.complete();
    await settle(tester);
    expect(find.text('Person x'), findsNothing);
    expect(find.text('Person n1'), findsOneWidget);
  });

  run('a batch write that straddles a sign-out writes nothing', (tester) async {
    net.dailyGate = Completer();
    await pumpTab(tester);
    // Sign-out has cleared the cache; the stored userId is not gone yet.
    await CommunityFirstPageCache().clearAll();
    net.dailyGate!.complete();
    await settle(tester);
    expect(await onDisk('me'), isNull);
  });

  run('kill switch (404) removes the cached batch', (tester) async {
    await _seed('me', ['x']);
    net.dailyStatus = 404;
    await pumpTab(tester);
    expect(await onDisk('me'), isNull);
  });

  test("user A's cached batch is never read for user B after a reset",
      () async {
    SharedPreferences.setMockInitialValues({'userId': 'A'});
    flag = true;
    prefs = RecordingPrefs(await SharedPreferences.getInstance());
    await _seed('A', ['x']);
    final c = makeContainer();
    final a = await c.read(dailyMatchesCachedProvider.future);
    expect(a!.matches.single.user.id, 'x');
    // Sign-out without the disk clear (tested below), then B signs in.
    invalidateUserScopedProviders(c.invalidate);
    await prefs.setString('userId', 'B');
    expect(await c.read(dailyMatchesCachedProvider.future), isNull);
  });

  group('removal', () {
    setUp(() => SharedPreferences.setMockInitialValues(
        {'userId': 'me', 'token': 't'}));

    Future<void> seedBoth() async {
      await _seed('me', ['bad', 'ok']);
      await CommunityFirstPageCache().write(
        userId: 'me',
        slot: CommunityFirstPageCache.partners,
        rows: [{'_id': 'bad'}, {'_id': 'ok'}],
      );
    }

    test('sign-out clears both slots', () async {
      await seedBoth();
      await AuthService().clearLocalSession();
      final keys = (await SharedPreferences.getInstance()).getKeys();
      expect(keys.where((k) => k.startsWith(CommunityFirstPageCache.keyPrefix)),
          isEmpty);
    });

    test('a block removes the person from both slots', () async {
      await seedBoth();
      final result = await http.runWithClient(
        () => BlockService.blockUser(
          currentUserId: 'me',
          blockedUserId: 'bad',
          blockedUserName: 'Bad',
        ),
        () => MockClient((req) async => http.Response('{}', 200)),
      );
      expect(result['success'], isTrue);
      final cache = CommunityFirstPageCache();
      for (final slot in CommunityFirstPageCache.slots) {
        final s = await cache.read(userId: 'me', slot: slot);
        expect(s!.rows.map(CommunityFirstPageCache.rowUserId), ['ok'], reason: slot);
      }
    });
  });
}
