import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/login/login_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

/// login() succeeds; the account has not accepted Terms.
class _FakeAuth extends AuthService {
  int logoutCalls = 0;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async =>
      {'success': true, 'token': 't', 'refreshToken': 'r'};

  @override
  Future<Community> getLoggedInUser() async =>
      Community.fromJson({'_id': 'u1', 'name': 'Ann', 'termsAccepted': false});

  @override
  Future<Map<String, dynamic>> logout({bool logoutAll = false}) async {
    logoutCalls++;
    return {'success': true};
  }
}

void main() {
  testWidgets('declining Terms after email login signs the user out',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = _FakeAuth();
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWith((ref) => auth)],
      child: MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Login(),
      ),
    ));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a@b.co');
    await tester.enterText(fields.at(1), 'Password1!');
    await tester.tap(find.byType(AuthGradientButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Terms screen is up; back out of it without accepting.
    navKey.currentState!.pop(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // THE BUG: the login screen just returned, leaving the session live.
    expect(auth.logoutCalls, 1);
  });
}
