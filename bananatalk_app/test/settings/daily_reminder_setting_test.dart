import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';

/// The daily lesson ("daily drop") push: the server had an on/off switch and
/// an hour, the app showed neither, so everyone got it at 19:00 for good.
class _Recording extends NotificationSettingsNotifier {
  _Recording(super.initial) : super.forTest();
  final calls = <String>[];

  @override
  Future<void> toggleSetting(String settingName, bool value) async {
    calls.add('$settingName:$value');
    if (settingName == 'dailyDropReminders') {
      state = AsyncValue.data(state.value!.copyWith(dailyDropReminders: value));
    }
  }

  @override
  Future<void> setDailyDropHour(int hour) async {
    calls.add('hour:$hour');
    state = AsyncValue.data(state.value!.copyWith(dailyDropHour: hour));
  }
}

Widget _host(_Recording notifier) => ProviderScope(
      overrides: [notificationSettingsProvider.overrideWith((ref) => notifier)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationSettingsScreen(),
      ),
    );

void main() {
  test('defaults: on at 19:00; reads and writes both fields', () {
    final d = NotificationSettings.fromJson({});
    expect(d.dailyDropReminders, isTrue);
    expect(d.dailyDropHour, 19);

    final s = NotificationSettings.fromJson({'dailyDropReminders': false, 'dailyDropHour': 7});
    expect(s.dailyDropReminders, isFalse);
    expect(s.dailyDropHour, 7);
    expect(s.toJson()['dailyDropReminders'], isFalse);
    expect(s.toJson()['dailyDropHour'], 7);

    // A bad stored hour falls back to the server's default instead of crashing.
    expect(NotificationSettings.fromJson({'dailyDropHour': 99}).dailyDropHour, 19);
    expect(NotificationSettings.fromJson({'dailyDropHour': 'x'}).dailyDropHour, 19);
  });

  testWidgets('shows the reminder time and turns the reminder off', (tester) async {
    final notifier = _Recording(NotificationSettings.defaultSettings().copyWith(dailyDropHour: 8));
    await tester.pumpWidget(_host(notifier));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Reminder time'), 200);
    expect(find.text('A short lesson notification once a day'), findsOneWidget);
    expect(find.text('8:00 AM'), findsOneWidget);

    // The section header and the switch share the title; the switch row is
    // the second one.
    final toggle = find.text('Daily lesson reminder').last;
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(notifier.calls, ['dailyDropReminders:false']);
    // Off: no time to pick.
    expect(find.text('Reminder time'), findsNothing);
  });

  testWidgets('picking a time saves the hour', (tester) async {
    final notifier = _Recording(NotificationSettings.defaultSettings());
    await tester.pumpWidget(_host(notifier));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Reminder time'), 200);
    expect(find.text('7:00 PM'), findsOneWidget);
    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    // Confirm the picker's preselected 7:00 PM as-is.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(notifier.calls, ['hour:19']);
  });
}
