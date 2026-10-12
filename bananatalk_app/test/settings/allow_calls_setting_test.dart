import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';

class _Recording extends NotificationSettingsNotifier {
  _Recording(super.initial) : super.forTest();
  final toggled = <String>[];
  @override
  Future<void> toggleSetting(String settingName, bool value) async {
    toggled.add('$settingName:$value');
    state = AsyncValue.data(state.value!.copyWith(allowCalls: value));
  }
}

void main() {
  test('allowCalls defaults to true and round-trips', () {
    expect(NotificationSettings.fromJson({}).allowCalls, isTrue);
    final off = NotificationSettings.fromJson({'allowCalls': false});
    expect(off.allowCalls, isFalse);
    expect(off.toJson()['allowCalls'], isFalse);
    expect(off.copyWith(allowCalls: true).allowCalls, isTrue);
  });

  testWidgets('the Allow calls switch writes allowCalls; quiet hours mention calls', (tester) async {
    final notifier = _Recording(NotificationSettings.defaultSettings()
        .copyWith(quietHours: const QuietHours(enabled: true)));
    await tester.pumpWidget(ProviderScope(
      overrides: [notificationSettingsProvider.overrideWith((ref) => notifier)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationSettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Allow calls'), 200);
    // Quiet hours hold calls only when "Allow urgent" is off (backend ruling),
    // so the note must not contradict the "Allow urgent" subtitle.
    expect(
        find.text('With “Allow urgent notifications” off, calls are held during quiet hours too.'),
        findsOneWidget);
    expect(find.text('Calls are held during quiet hours too.'), findsNothing);
    await tester.tap(find.text('Allow calls')); // the tile's InkWell toggles
    await tester.pumpAndSettle();
    expect(notifier.toggled, ['allowCalls:false']);
  });
}
