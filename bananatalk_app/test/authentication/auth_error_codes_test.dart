import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/auth_error_codes.dart';

void main() {
  test('parses known codes', () {
    expect(parseAuthErrorCode('CODE_EXPIRED'), AuthErrorCode.codeExpired);
    expect(parseAuthErrorCode('CODE_INVALID'), AuthErrorCode.codeInvalid);
    expect(parseAuthErrorCode('ACCOUNT_LOCKED'), AuthErrorCode.accountLocked);
    expect(parseAuthErrorCode('RATE_LIMITED'), AuthErrorCode.rateLimited);
    expect(parseAuthErrorCode('EMAIL_EXISTS'), AuthErrorCode.emailExists);
    expect(parseAuthErrorCode('PROFILE_INCOMPLETE'), AuthErrorCode.profileIncomplete);
  });
  test('null / unknown map to unknown', () {
    expect(parseAuthErrorCode(null), AuthErrorCode.unknown);
    expect(parseAuthErrorCode('SOMETHING_ELSE'), AuthErrorCode.unknown);
  });
}
