import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/edit/change_password_screen.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';

Future<bool> _canSaveWith(WidgetTester tester, String newPassword) async {
  await tester.pumpWidget(const ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangePasswordScreen(),
    ),
  ));
  await tester.pump();
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'OldPassw0rd');
  await tester.enterText(fields.at(1), newPassword);
  await tester.enterText(fields.at(2), newPassword);
  await tester.pump();
  return tester
      .widget<GradientSaveButton>(find.byType(GradientSaveButton))
      .canSave;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // THE BUG: a character whitelist ([A-Za-z0-9@$!%*?&]) kept Save greyed
  // while all four checklist rows were green; the backend has no whitelist.
  for (final pwd in ['NewPass1#', 'New.Pass_1', 'New Pass 1', 'Pässwort12']) {
    testWidgets('Save enabled for "$pwd" (checklist green)', (tester) async {
      expect(await _canSaveWith(tester, pwd), isTrue);
    });
  }

  testWidgets('Save still disabled when a checklist rule fails',
      (tester) async {
    expect(await _canSaveWith(tester, 'newpass1#'), isFalse); // no upper
    expect(await _canSaveWith(tester, 'NewPa1#'), isFalse); // too short
  });
}
