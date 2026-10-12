import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';

class _Fake extends StateNotifier<AsyncValue<NotificationSettings>>
    implements NotificationSettingsNotifier {
  _Fake() : super(AsyncValue.data(NotificationSettings.defaultSettings()));
  final toggles = <(String, bool)>[];
  @override
  Future<void> toggleSetting(String settingName, bool value) async =>
      toggles.add((settingName, value));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('announcements defaults on and round-trips', () {
    expect(NotificationSettings.defaultSettings().announcements, isTrue);
    expect(NotificationSettings.fromJson({}).announcements, isTrue);
    final off = NotificationSettings.fromJson({'announcements': false});
    expect(off.announcements, isFalse);
    expect(off.toJson()['announcements'], isFalse);
    expect(off.copyWith(announcements: true).announcements, isTrue);
  });

  testWidgets('the toggle writes the announcements setting', (t) async {
    final fake = _Fake();
    await t.pumpWidget(ProviderScope(
      overrides: [notificationSettingsProvider.overrideWith((ref) => fake)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationSettingsScreen(),
      ),
    ));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Announcements'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Announcements'));
    await t.pumpAndSettle();
    expect(fake.toggles.last, ('announcements', false));
  });
}
