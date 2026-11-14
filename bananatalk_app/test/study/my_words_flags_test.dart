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
}
