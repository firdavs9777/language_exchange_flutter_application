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

  // Every page rendered as a tab body or a Community sub-tab, i.e. under the
  // floating bar. Pushed routes cover the shell (and the bar) and are not here.
  const tabBodies = [
    'lib/pages/community/tabs/matches_tab.dart',
    'lib/pages/community/tabs/partner_discovery_tab.dart',
    'lib/pages/community/tabs/genders_tab.dart',
    'lib/pages/community/gatherings/gatherings_tab.dart',
    'lib/pages/community/voice_rooms/voice_rooms_tab.dart',
    'lib/pages/community/rooms/rooms_directory_screen.dart',
    'lib/pages/community/tabs/nearby_tab.dart',
    'lib/pages/community/tabs/city_tab.dart',
    'lib/pages/community/tabs/topics_tab.dart',
    'lib/pages/community/tabs/waves_tab.dart',
    'lib/pages/profile/profile_main.dart',
    'lib/pages/moments/feed/moments_main.dart',
  ];

  final scrollable = RegExp(
      r'\b(ListView(\.builder|\.separated)?|GridView(\.builder|\.count)?|SingleChildScrollView)\(');
  final argsEnd =
      RegExp(r'^\s*(child|children|itemBuilder|slivers|gridDelegate)\b');
  final literalSpacer = RegExp(
      r'(SliverToBoxAdapter\(child: SizedBox\(height: \d+\)\))|(SizedBox\(height: (7[2-9]|[89]\d|1\d\d)\))');

  test('every vertical list on a tab body ends on FloatingTabBar.clearance',
      () {
    final hits = <String>[];
    for (final path in tabBodies) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        // A literal spacer at the end of a sliver list, or a FAB lifted by a
        // literal, is the same bug in another shape.
        if (literalSpacer.hasMatch(l) ||
            (l.contains('floatingActionButton:') &&
                RegExp(r'bottom: \d+').hasMatch(lines
                    .sublist(i, (i + 5).clamp(0, lines.length))
                    .join()))) {
          hits.add('$path:${i + 1}: ${l.trim()}');
        }
        if (!scrollable.hasMatch(l)) {
          continue;
        }
        // The scrollable's own arguments: the lines up to the first
        // child/children/itemBuilder.
        final window = <String>[l];
        for (var j = i + 1; j < lines.length && j < i + 8; j++) {
          if (argsEnd.hasMatch(lines[j])) break;
          window.add(lines[j]);
        }
        final args = window.join('\n');
        if (args.contains('Axis.horizontal')) continue;
        // Not at the bottom of the page (an overlay card, or a scroll view
        // nested in a list that owns the clearance): say why on the line
        // above with `// clearance-exempt: <reason>`.
        if (i > 0 && lines[i - 1].contains('clearance-exempt:')) continue;
        // shrinkWrap lists sit inside another scrollable, which owns the
        // clearance.
        if (args.contains('shrinkWrap: true')) continue;
        if (!args.contains('FloatingTabBar.clearance')) {
          final padding = RegExp(r'padding:[^\n]*').firstMatch(args)?.group(0);
          hits.add('$path:${i + 1}: ${padding ?? '(no padding)'}');
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
