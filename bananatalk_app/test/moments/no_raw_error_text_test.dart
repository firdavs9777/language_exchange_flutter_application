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

  test('moments/stories services do not label every failure a network error', () {
    for (final path in ['lib/services/moments_service.dart', 'lib/services/stories_service.dart']) {
      expect(File(path).readAsStringSync(), isNot(contains("'Network error: ")), reason: path);
    }
  });
}
