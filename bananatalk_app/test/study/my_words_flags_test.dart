import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/my_words_providers.dart';

void main() {
  const base = {
    'minVersion': '0',
    'latestVersion': '0',
    'forceUpdate': false,
    'iosUrl': '',
    'androidUrl': '',
    'releaseNotes': '',
  };

  test('both flags parse from app-config and default to false', () {
    final off = AppConfig.fromJson({...base});
    expect(off.studyFromChatsEnabled, isFalse);
    expect(off.studyDoorsEnabled, isFalse);
    final on = AppConfig.fromJson({
      ...base,
      'studyFromChatsEnabled': true,
      'studyDoorsEnabled': true,
    });
    expect(on.studyFromChatsEnabled, isTrue);
    expect(on.studyDoorsEnabled, isTrue);
    final odd = AppConfig.fromJson({...base, 'studyDoorsEnabled': 'true'});
    expect(odd.studyDoorsEnabled, isFalse);
  });

  test('myWordsProvider makes no request when studyFromChatsEnabled is false',
      () async {
    SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
    var requests = 0;
    final result = await http.runWithClient(() async {
      final c = ProviderContainer(overrides: [
        studyFromChatsEnabledProvider.overrideWithValue(false),
      ]);
      addTearDown(c.dispose);
      return c.read(myWordsProvider.future);
    }, () => MockClient((req) async {
          requests++;
          return http.Response('{}', 200);
        }));
    expect(result, same(MyWords.empty));
    expect(requests, 0);
  });

  test('myWordsProvider fetches exactly once when studyFromChatsEnabled is '
      'true', () async {
    SharedPreferences.setMockInitialValues({'userId': 'me', 'token': 't'});
    final paths = <String>[];
    final result = await http.runWithClient(() async {
      final c = ProviderContainer(overrides: [
        appConfigProvider.overrideWith(
          (ref) async => AppConfig.fromJson({
            ...base,
            'studyFromChatsEnabled': true,
          }),
        ),
      ]);
      addTearDown(c.dispose);
      // Kept alive while the config arrives, as a widget watching it would.
      final sub = c.listen(myWordsProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(appConfigProvider.future);
      await Future<void>.delayed(Duration.zero);
      return c.read(myWordsProvider.future);
    }, () => MockClient((req) async {
          paths.add(req.url.path);
          return http.Response(
            '{"success":true,"data":{"counts":{"candidates":1,"mistakes":0,'
            '"dueWords":0},"candidates":[{"id":"c1","text":"chat",'
            '"translation":"cat","language":"fr","seenCount":1,'
            '"lastSeenAt":"2026-11-14T00:00:00Z"}],"mistakes":[]}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }));
    expect(result.candidateCount, 1);
    expect(paths.where((p) => p.endsWith('/study/my-words')), hasLength(1));
  });
}
