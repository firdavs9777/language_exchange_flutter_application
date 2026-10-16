import 'package:bananatalk_app/utils/help_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HelpLinks', () {
    test('support mail goes to the support address', () {
      final uri = HelpLinks.supportEmailUri();
      expect(uri.scheme, 'mailto');
      expect(uri.path, HelpLinks.supportEmail);
      expect(HelpLinks.supportEmail, 'bananatalkmain@gmail.com');
    });

    test('bug report carries subject and device details', () {
      final uri = HelpLinks.bugReportUri(
        subject: 'Report a Bug',
        clientInfo: const {
          'platform': 'ios',
          'deviceModel': 'iPhone16,1',
          'osVersion': 'iOS 18.1',
          'appVersion': '2.7.0',
          'appBuild': '10580',
        },
      );
      expect(uri.scheme, 'mailto');
      expect(uri.path, HelpLinks.supportEmail);
      // Spaces must be %20, not '+', or mail apps show the plus signs.
      expect(uri.toString(), isNot(contains('+')));
      final params = Uri.splitQueryString(uri.query);
      expect(params['subject'], 'BananaTalk: Report a Bug');
      final body = params['body']!;
      expect(body, contains('App version: 2.7.0 (10580)'));
      expect(body, contains('Device: iPhone16,1'));
      expect(body, contains('OS: iOS 18.1'));
      expect(body, contains('Platform: ios'));
    });

    test('bug report tolerates missing device details', () {
      final uri = HelpLinks.bugReportUri(subject: 'Bug', clientInfo: const {});
      final body = Uri.splitQueryString(uri.query)['body']!;
      expect(body, contains('App version: unknown'));
      expect(body, contains('Device: unknown'));
    });

    test('FAQ points at the public support page', () {
      expect(HelpLinks.faqUri.toString(), 'https://banatalk.com/support');
    });
  });
}
