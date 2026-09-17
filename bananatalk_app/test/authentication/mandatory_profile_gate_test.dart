import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/authentication/register/register_two_screen.dart';

/// The rule the defect broke: a profile-completion screen reached by an
/// already-authenticated user must not be escapable into the app.
///
/// Social sign-ups land on RegisterTwo already logged in (the FCM token is
/// registered before this screen on purpose). Step 0's back button called
/// Navigator.pop, which dropped them into the app with no birthday — and
/// neither Apple nor Google returns one, so nothing else would ever ask. 128
/// users took that exit in the 30 days before this was fixed.
void main() {
  group('RegisterTwo gate flags', () {
    test('ordinary email registration is escapable', () {
      // Backing out of a signup you started yourself is correct behaviour.
      const screen = RegisterTwo();
      expect(screen.mandatory, isFalse);
      expect(screen.completionMode, isFalse);
    });

    test('an OAuth sign-up is marked mandatory', () {
      const screen = RegisterTwo(mandatory: true, name: 'Dana');
      expect(screen.mandatory, isTrue);
    });

    test('completionMode is available for session-restore entries', () {
      // splash_screen and login_screen send the user here only when the
      // profile is already known to be incomplete, so that entry is a gate
      // too — the widget treats completionMode as implying mandatory.
      const screen = RegisterTwo(completionMode: true);
      expect(screen.completionMode, isTrue);
    });

    test('mandatory defaults to false so existing flows are unchanged', () {
      // The flag is opt-in precisely so adding it could not alter the email
      // registration path, which was never broken.
      expect(const RegisterTwo(completionMode: true).mandatory, isFalse);
      expect(const RegisterTwo(name: 'x', email: 'y').mandatory, isFalse);
    });
  });
}
