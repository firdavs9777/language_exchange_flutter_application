import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/pages/authentication/post_login_error.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('classifyPostLoginError', () {
    test('a network failure after login is retryable, not "session expired"',
        () {
      // THE BUG: any failure here logged the user out with "Session expired".
      expect(classifyPostLoginError(const SocketException('Failed host lookup')),
          PostLoginFailure.retryable);
      expect(classifyPostLoginError(http.ClientException('Connection reset')),
          PostLoginFailure.retryable);
      expect(classifyPostLoginError(Exception('Failed to load user info: 503 x')),
          PostLoginFailure.retryable);
    });

    test('a rejected token or missing account is a session rejection', () {
      expect(
          classifyPostLoginError(
              Exception('Failed to load user info: 401 {"error":"jwt"}')),
          PostLoginFailure.sessionRejected);
      expect(classifyPostLoginError(Exception('Failed to load user info: 404 x')),
          PostLoginFailure.sessionRejected);
      expect(
          classifyPostLoginError(
              Exception('Not authenticated. Please login again.')),
          PostLoginFailure.sessionRejected);
    });
  });

  group('account suspension', () {
    test('a suspended 403 on /auth/me is a suspension, not "session expired"',
        () {
      final e = Exception('Failed to load user info: 403 '
          '{"success":false,"error":"Your account has been suspended. Reason: spam",'
          '"code":"ACCOUNT_BANNED","banReason":"spam"}');
      expect(classifyPostLoginError(e), PostLoginFailure.suspended);
      expect(suspensionFromPostLoginError(e)?.reason, 'spam');
    });

    test('older backend: no banReason key, reason read from the message', () {
      final e = Exception('Failed to load user info: 403 '
          '{"success":false,"error":"Your account has been suspended. Reason: abuse"}');
      expect(classifyPostLoginError(e), PostLoginFailure.suspended);
      expect(suspensionFromPostLoginError(e)?.reason, 'abuse');
    });

    test('any other 403 is still a session rejection', () {
      final e = Exception('Failed to load user info: 403 {"error":"Forbidden"}');
      expect(classifyPostLoginError(e), PostLoginFailure.sessionRejected);
      expect(suspensionFromPostLoginError(e), isNull);
    });

    test('a refused login result (403 ACCOUNT_BANNED) is a suspension', () {
      final s = suspensionFromAuthResult({
        'success': false,
        'message': 'Your account has been suspended.',
        'code': 'ACCOUNT_BANNED',
        'banReason': null,
      });
      expect(s, isNotNull);
      expect(s!.reason, isNull);
      expect(
          suspensionFromAuthResult({
            'success': false,
            'message': 'Your account has been suspended. Reason: x',
            'code': 'ACCOUNT_BANNED',
            'banReason': '  x ',
          })?.reason,
          'x');
    });

    test('other refusals are not suspensions', () {
      expect(
          suspensionFromAuthResult(
              {'success': false, 'message': 'Invalid credentials', 'code': null}),
          isNull);
      // Permanently deleted (BannedIdentity) accounts have their own copy.
      expect(
          suspensionFromAuthResult({
            'success': false,
            'message':
                'This account has been permanently suspended and cannot be reactivated.',
          }),
          isNull);
    });
  });

  group('no raw exception text reaches the user', () {
    test('ClientException maps to the offline string', () {
      final msg = retryablePostLoginMessage(
          l10n, http.ClientException('Connection closed', Uri.parse('x:/')));
      expect(msg, l10n.noInternetConnection);
      expect(msg.contains('ClientException'), isFalse);
    });

    test('Google/Apple errors: no "Details:", cancel is silent', () {
      final msg = socialSignInErrorMessage(
          l10n, PlatformException(code: 'sign_in_failed', message: 'ApiException: 10:'));
      expect(msg, l10n.somethingWentWrong);
      expect(
          socialSignInErrorMessage(
              l10n, PlatformException(code: 'network_error')),
          l10n.noInternetConnection);
      expect(
          socialSignInErrorMessage(
              l10n, PlatformException(code: 'sign_in_canceled')),
          isNull);
    });
  });

  group('authResultMessage', () {
    test('shows the server message (423 lockout minutes, OAuth-only 400)', () {
      expect(
          authResultMessage(l10n,
              {'success': false, 'message': 'Account is locked. Please try again in 14 minutes.'},
              fallback: 'x'),
          'Account is locked. Please try again in 14 minutes.');
      expect(
          authResultMessage(l10n,
              {'success': false, 'message': 'This account uses Google sign-in.'},
              fallback: 'x'),
          'This account uses Google sign-in.');
    });

    test('a network failure shows the localized offline string', () {
      expect(
          authResultMessage(l10n,
              {'success': false, 'message': 'Network error.', 'isNetworkError': true},
              fallback: 'x'),
          l10n.noInternetConnection);
    });
  });
}
