import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/login/login_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

/// login() succeeds at once; the post-login user fetch hangs, standing in
/// for the terms/profile/biometric gates that run before navigation.
class _FakeAuth extends AuthService {
  int loginCalls = 0;
  final userFetch = Completer<Community>();

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return {'success': true, 'token': 't', 'refreshToken': 'r'};
  }

  @override
  Future<Community> getLoggedInUser() => userFetch.future;
}

void main() {
  testWidgets('a second tap during the post-login gates does not log in again',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = _FakeAuth();

    await tester.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWith((ref) => auth)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Login(),
      ),
    ));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a@b.co');
    await tester.enterText(fields.at(1), 'Password1!');

    await tester.tap(find.byType(AuthGradientButton));
    await tester.pump();
    await tester.pump();
    expect(auth.loginCalls, 1);

    // THE BUG: _isLoading was cleared as soon as login() returned, so the
    // button was live again while the gates awaited.
    final button =
        tester.widget<AuthGradientButton>(find.byType(AuthGradientButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(AuthGradientButton), warnIfMissed: false);
    await tester.pump();
    expect(auth.loginCalls, 1);
  });
}
