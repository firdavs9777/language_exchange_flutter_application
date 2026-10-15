import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/biometric/enable_biometric_prompt.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_error_state.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_strength_meter.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

void main() {
  final ru = lookupAppLocalizations(const Locale('ru'));

  test('passwordErrorText names the failed rule in the app language', () {
    expect(AuthService.passwordErrorText('', ru), ru.pleaseEnterAPassword);
    expect(AuthService.passwordErrorText('Ab1', ru), ru.passwordErrorLength);
    expect(AuthService.passwordErrorText('abcdefg1', ru), ru.passwordErrorUppercase);
    expect(AuthService.passwordErrorText('ABCDEFG1', ru), ru.passwordErrorLowercase);
    expect(AuthService.passwordErrorText('Abcdefgh', ru), ru.passwordErrorNumber);
    expect(AuthService.passwordErrorText('Abcdefg1', ru), isNull);
  });

  test('the biometric opt-in title only says Face ID on Apple platforms', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(enableBiometricTitleFor(en, TargetPlatform.iOS), contains('Face ID'));
    expect(enableBiometricTitleFor(en, TargetPlatform.android), isNot(contains('Face ID')));
  });

  Widget localized(Widget child) => MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('auth error state and strength meter render in the app language', (tester) async {
    await tester.pumpWidget(localized(const Column(children: [
      AuthErrorState(kind: AuthErrorKind.locked, retryAfter: Duration(minutes: 5)),
      PasswordStrengthMeter(password: 'abc'),
    ])));
    expect(find.text(ru.authLockedTitle), findsOneWidget);
    expect(find.text(ru.authLockedBodyMinutes(5)), findsOneWidget);
    expect(find.text(ru.passwordWeak), findsOneWidget);
  });
}
