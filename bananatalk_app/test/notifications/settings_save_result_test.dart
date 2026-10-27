import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

/// A toggle that failed to save flipped back with no message, and when two
/// quick toggles overlapped, the first one's failure undid the second on
/// screen although the second saved.
class _FakeApi extends NotificationApiClient {
  final answers = <Completer<Map<String, dynamic>>>[];

  @override
  Future<Map<String, dynamic>> updateSettings(NotificationSettings settings) {
    final c = Completer<Map<String, dynamic>>();
    answers.add(c);
    return c.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  NotificationSettings initial() => NotificationSettings.defaultSettings()
      .copyWith(moments: true, sound: true);

  test('a failed save reports false and flips back', () async {
    final api = _FakeApi();
    final n = NotificationSettingsNotifier.forTest(initial(), apiClient: api);
    final saving = n.toggleSetting('moments', false);
    await pumpEventQueue();
    api.answers.single.complete({'success': false});
    expect(await saving, isFalse);
    expect(n.state.value!.moments, isTrue);
  });

  test('a saved toggle reports true', () async {
    final api = _FakeApi();
    final n = NotificationSettingsNotifier.forTest(initial(), apiClient: api);
    final saving = n.toggleSetting('moments', false);
    await pumpEventQueue();
    api.answers.single.complete({'success': true});
    expect(await saving, isTrue);
    expect(n.state.value!.moments, isFalse);
  });

  test("an older failure does not undo a newer toggle", () async {
    final api = _FakeApi();
    final n = NotificationSettingsNotifier.forTest(initial(), apiClient: api);
    final first = n.toggleSetting('moments', false);
    await pumpEventQueue();
    final second = n.toggleSetting('sound', false);
    await pumpEventQueue();

    api.answers[0].complete({'success': false});
    expect(await first, isFalse);
    expect(n.state.value!.sound, isFalse, reason: 'second toggle still shown');

    api.answers[1].complete({'success': true});
    expect(await second, isTrue);
    expect(n.state.value!.sound, isFalse);
    expect(n.state.value!.moments, isFalse,
        reason: 'the second save carried the first toggle and settled it');
  });
}
