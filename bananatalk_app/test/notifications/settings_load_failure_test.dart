import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

class _FakeApi extends NotificationApiClient {
  _FakeApi({this.load, this.saveOk = true});
  NotificationSettings? load;
  bool throwOnLoad = false;
  final bool saveOk;
  final sent = <NotificationSettings>[];

  @override
  Future<NotificationSettings?> getSettings() async {
    if (throwOnLoad) throw Exception('offline');
    return load;
  }

  @override
  Future<Map<String, dynamic>> updateSettings(NotificationSettings settings) async {
    sent.add(settings);
    return {'success': saveOk};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  NotificationSettings server() =>
      NotificationSettings.defaultSettings().copyWith(chatMessages: false, sound: false);

  test('a failed load is an error, not defaults', () async {
    final api = _FakeApi(load: null);
    final n = NotificationSettingsNotifier.forTest(server(), apiClient: api);
    await n.fetchSettings();
    expect(n.state.hasError, isTrue);
    expect(n.state.valueOrNull, isNull);
  });

  test('a thrown load is an error, not defaults', () async {
    final api = _FakeApi()..throwOnLoad = true;
    final n = NotificationSettingsNotifier.forTest(server(), apiClient: api);
    await n.fetchSettings();
    expect(n.state.hasError, isTrue);
    expect(n.state.valueOrNull, isNull);
  });

  test('after a failed load a toggle never saves defaults over the server', () async {
    final api = _FakeApi(load: null);
    final n = NotificationSettingsNotifier.forTest(server(), apiClient: api);
    await n.fetchSettings();
    await n.toggleSetting('moments', false);
    await n.updateQuietHours(const QuietHours(enabled: true));
    expect(api.sent, isEmpty);
  });

  test('retry after a failed load restores the server settings', () async {
    final api = _FakeApi(load: null);
    final n = NotificationSettingsNotifier.forTest(server(), apiClient: api);
    await n.fetchSettings();
    api.load = server();
    await n.fetchSettings();
    expect(n.state.value!.chatMessages, isFalse);
    expect(n.state.value!.sound, isFalse);
  });

  test('a failed save puts back the last known settings', () async {
    final api = _FakeApi(load: null, saveOk: false);
    final n = NotificationSettingsNotifier.forTest(server(), apiClient: api);
    await n.toggleSetting('moments', false);
    expect(n.state.value!.moments, isTrue);
    expect(n.state.value!.chatMessages, isFalse);
  });
}
