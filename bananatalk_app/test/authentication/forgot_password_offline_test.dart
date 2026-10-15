import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_email_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_error_state.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

/// sendPasswordResetCode never throws offline: it returns the
/// `isNetworkError` result map (AuthService._networkFailure).
class _OfflineAuth extends AuthService {
  @override
  Future<Map<String, dynamic>> sendPasswordResetCode({
    required String email,
  }) async =>
      {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'isNetworkError': true,
      };
}

void main() {
  testWidgets('offline: the illustrated network panel shows', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWith((ref) => _OfflineAuth())],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ForgotPasswordEmail(),
      ),
    ));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'a@b.co');
    await tester.tap(find.byType(AuthGradientButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // THE BUG: only a thrown error set the network panel; the returned
    // isNetworkError result fell through to a plain English snackbar.
    final panel = tester.widget<AuthErrorState>(find.byType(AuthErrorState));
    expect(panel.kind, AuthErrorKind.network);
  });
}
