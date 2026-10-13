import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

class _FakeApi extends NotificationApiClient {
  final sent = <NotificationSettings>[];
  @override
  Future<Map<String, dynamic>> updateSettings(NotificationSettings settings) async {
    sent.add(settings);
    return {'success': true};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  NotificationSettings saved({String tz = 'Asia/Seoul'}) =>
      NotificationSettings.defaultSettings().copyWith(quietHours: QuietHours(timezone: tz));

  test('saving quiet hours sends the device IANA zone, not the saved Asia/Seoul', () async {
    final api = _FakeApi();
    final n = NotificationSettingsNotifier.forTest(saved(),
        apiClient: api, deviceTimezone: () async => 'Asia/Tashkent');
    await n.updateQuietHours(n.state.value!.quietHours.copyWith(enabled: true, start: '23:00'));
    final qh = api.sent.single.quietHours;
    expect(qh.timezone, 'Asia/Tashkent');
    expect(qh.enabled, isTrue);
    expect(qh.start, '23:00');
    expect(n.state.value!.quietHours.timezone, 'Asia/Tashkent');
  });

  test('an old saved zone never overrides the device zone (any settings save)', () async {
    final api = _FakeApi();
    final n = NotificationSettingsNotifier.forTest(saved(tz: 'Europe/Berlin'),
        apiClient: api, deviceTimezone: () async => 'America/New_York');
    await n.toggleSetting('chatMessages', false);
    expect(api.sent.single.quietHours.timezone, 'America/New_York');
  });

  test('the cached snapshot for the foreground handler carries the device zone', () async {
    final n = NotificationSettingsNotifier.forTest(saved(),
        apiClient: _FakeApi(), deviceTimezone: () async => 'Asia/Tashkent');
    await n.updateQuietHours(const QuietHours(enabled: true));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('qh_snapshot'), contains('Asia/Tashkent'));
  });

  test('device zone unknown: the saved zone is kept', () async {
    final api = _FakeApi();
    final n = NotificationSettingsNotifier.forTest(saved(tz: 'Europe/Berlin'),
        apiClient: api, deviceTimezone: () async => null);
    await n.updateQuietHours(const QuietHours(enabled: true, timezone: 'Europe/Berlin'));
    expect(api.sent.single.quietHours.timezone, 'Europe/Berlin');
  });
}
