import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task 6 (measure first): on the first open of Community, does the first
/// `GET auth/users` wait for the profile fetch? This records the order with
/// delayed fakes -- app-config resolves at 200ms, the profile fetch (started
/// when something first reads userProvider) takes 300ms, and the list
/// request is stamped when it is issued. Times are virtual (tester clock).
Community _me() => Community.fromJson({
  '_id': 'me',
  'name': 'Me',
  'native_language': 'English',
  'language_to_learn': 'Korean',
  'location': {'type': 'Point', 'coordinates': [0, 0], 'city': 'Seoul', 'country': 'Korea'},
});

class _Recording extends CommunityService {
  _Recording(this._at, this.events, this.queries);
  final Duration Function() _at;
  final Map<String, Duration> events;
  final List<Map<String, String>> queries;

  @override
  Future<PaginatedCommunityResponse> getUsersPage(Map<String, String> query) {
    events.putIfAbsent('users-start', _at);
    queries.add(query);
    return Future.value(
      PaginatedCommunityResponse(users: const [], total: 0, page: 1, pages: 1, hasMore: false),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userId': 'me'}));

  // [shellStartsProfile]: TabBarMenu watches userProvider in its own build
  // (TabBarMenu.dart), so in the app the profile fetch starts at launch, before
  // Community is ever opened. False models a cold start where nothing else
  // read it.
  for (final flag in [false, true]) {
  for (final shellStartsProfile in [true, false]) {
    testWidgets(
        'first open order, flag ${flag ? 'on' : 'off'}, '
        'profile ${shellStartsProfile ? 'started by the shell' : 'started by Partners'}',
        (tester) async {
      var elapsed = Duration.zero;
      final events = <String, Duration>{};
      final queries = <Map<String, String>>[];
      final service = _Recording(() => elapsed, events, queries);

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWith((ref) async {
            events['config-start'] = elapsed;
            await Future<void>.delayed(const Duration(milliseconds: 200));
            events['config-done'] = elapsed;
            return AppConfig.fromJson({'communityFastListEnabled': flag});
          }),
          userProvider.overrideWith((ref) async {
            events['user-start'] = elapsed;
            await Future<void>.delayed(const Duration(milliseconds: 300));
            events['user-done'] = elapsed;
            return _me();
          }),
          blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
          communityServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      if (shellStartsProfile) container.read(userProvider);
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
            home: CommunityMain(),
          ),
        ),
      );
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        elapsed += const Duration(milliseconds: 10);
      }

      // ignore: avoid_print
      print('flag ${flag ? 'on' : 'off'}, shell=$shellStartsProfile: ${events.map((k, v) => MapEntry(k, '${v.inMilliseconds}ms'))}');

      final configDone = events['config-done']!;
      final userDone = events['user-done']!;
      final usersStart = events['users-start']!;
      // Virtual clock is stepped by 10ms: allow one step of slack.
      expect((configDone - const Duration(milliseconds: 200)).abs() <=
          const Duration(milliseconds: 20), isTrue);
      // /users needs the profile (the default filter is the viewer's
      // languages; country is VIP-only), so it is issued after the profile
      // fetch completes and after app-config -- and no later than that.
      expect(usersStart >= userDone, isTrue);
      expect(usersStart >= configDone, isTrue);
      final both = userDone > configDone ? userDone : configDone;
      expect(usersStart - both <= const Duration(milliseconds: 20), isTrue,
          reason: 'no extra wait beyond the later of config and profile');
      // Let unrelated timeouts (15s request guards) expire before teardown.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));

      expect(queries, hasLength(1));
      // The request carries the viewer's languages from the profile.
      expect(queries.single['nativeLanguage'], 'English');
      expect(queries.single['learningLanguage'], 'Korean');
    });
  }
  }
}
