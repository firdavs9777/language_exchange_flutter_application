import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Spec §8.2: tab pages clear the floating bar with FloatingTabBar.clearance,
/// never a guessed literal (the bar's height changed; the 100s did not).
void main() {
  const dirs = [
    'lib/pages/learning/main',
    'lib/pages/community',
    'lib/pages/chat/list',
    'lib/pages/moments/feed',
    'lib/pages/profile',
  ];
  final literal = RegExp(
      r'(bottom:\s*(88|90|96|100|110|120)\b)|(EdgeInsets\.fromLTRB\([^)]*,\s*(88|90|96|100|110|120)\))');

  test('no tab page keeps a bottom clearance literal', () {
    final hits = <String>[];
    for (final d in dirs) {
      for (final f in Directory(d)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (literal.hasMatch(lines[i])) {
            hits.add('${f.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the coffee button is gone', () {
    expect(
        File('lib/pages/menu_tab/TabBarMenu.dart')
            .readAsStringSync()
            .contains('_CoffeeButton'),
        isFalse);
  });
}
