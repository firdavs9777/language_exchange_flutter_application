import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard: moments, comments and stories screens show failures through
/// `friendlyErrorMessage`, not as `e.toString()` with the "Exception: " cut
/// off (which still put "SocketException: Failed host lookup ..." on screen),
/// and their services no longer dress every thrown failure up as
/// "Network error: ...".
void main() {
  List<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('no raw exception text in moments/comments/stories screens', () {
    final offenders = <String>[];
    for (final dir in ['lib/pages/moments', 'lib/pages/comments', 'lib/pages/stories']) {
      for (final f in dartFiles(dir)) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains("toString().replaceFirst('Exception: '")) {
            offenders.add('${f.path}:${i + 1}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Use friendlyErrorMessage:\n${offenders.join('\n')}');
  });

  test('services return raw failure text, not English wrapped round it', () {
    // Screens classify the raw `e.toString()` with friendlyErrorMessage
    // (offline vs. everything else); an English "Network error: " /
    // "Error: " prefix in front of it was shown verbatim by screens that
    // echoed the string, and called a JSON parse failure a network error.
    // admin_provider (admin-only screens that show raw text on purpose) is
    // the known exception.
    const allowed = {
      'lib/providers/provider_root/admin_provider.dart',
    };
    final pattern = RegExp(r"'(Network error|Error): \$\{?e\b");
    final offenders = <String>[];
    for (final dir in ['lib/services', 'lib/providers']) {
      for (final f in dartFiles(dir)) {
        if (allowed.contains(f.path)) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].trimLeft().startsWith('//')) continue;
          if (pattern.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Return e.toString():\n${offenders.join('\n')}');
  });

  test('moments/stories services do not label every failure a network error', () {
    for (final path in ['lib/services/moments_service.dart', 'lib/services/stories_service.dart']) {
      expect(File(path).readAsStringSync(), isNot(contains("'Network error: ")), reason: path);
    }
  });
}
