import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strings added by spec 2026-10-12 (§3, §5.2). The localization tasks (L*)
/// append their keys to [keys].
const keys = [
  'guideProgress',
  'guideChatTip',
  'announcementTitle',
  'announcementUnavailable',
  'notifyAnnouncementsTitle',
  'notifyAnnouncementsSubtitle',
];

void main() {
  final arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  test('19 locales', () => expect(arbs.length, 19));

  test('every locale defines every onboarding string', () {
    for (final f in arbs) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final k in keys) {
        expect(m[k] is String && (m[k] as String).trim().isNotEmpty, isTrue,
            reason: '${f.path} is missing $k');
      }
    }
  });

  test('guideProgress keeps {count} everywhere', () {
    for (final f in arbs) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      expect((m['guideProgress'] as String).contains('{count}'), isTrue,
          reason: f.path);
    }
  });

  test('the machine drafts are queued for native review', () {
    final csv = File('docs/l10n/native-qa-strings-2026-10.csv').readAsStringSync();
    for (final k in keys) {
      expect(RegExp('^app,ko,$k,', multiLine: true).hasMatch(csv), isTrue,
          reason: k);
    }
  });
}
