import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_email_screen.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_verification_screen.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/reset_password_screen.dart';

/// Regression test for C1: all three password-reset screens wrap
/// AnimatedAuthBackground (a Stack(fit: StackFit.expand)) inside
/// AuthScreenScaffold's body, which is itself inside a SingleChildScrollView
/// (unbounded height in its scroll axis). Previously this was bridged with
/// LayoutBuilder -> ConstrainedBox(minHeight) -> IntrinsicHeight, which
/// throws "BoxConstraints forces an infinite height" because IntrinsicHeight
/// still hands the Stack unbounded constraints. Each screen now uses the
/// viewport-height SizedBox pattern from login_screen.dart instead.
///
/// This test pumps each screen inside a minimal harness (ProviderScope +
/// MaterialApp with the app's localization delegates) and asserts no layout
/// exception was thrown.
void main() {
  Widget harness(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('ForgotPasswordEmail renders without layout exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const ForgotPasswordEmail()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ForgotPasswordVerification renders without layout exceptions',
    (tester) async {
      await tester.pumpWidget(
        harness(const ForgotPasswordVerification(email: 'user@example.com')),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ResetPassword renders without layout exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const ResetPassword(email: 'user@example.com', code: '123456'),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
