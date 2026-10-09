import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every top-level tab must carry a first-session guide.
///
/// The requirement is coverage, not any one card: a new user who only ever
/// gets a hint on Matches learns one thing the app does, and the other four
/// tabs stay rectangles they open once and never tap again. 85% of signups
/// left on day one.
///
/// Source-level because the failure is structural, not behavioural. The four
/// generic guides each have widget coverage in `page_guide_test.dart`; what
/// nothing else can catch is a fifth tab being added, or an existing one
/// being rewritten, with no guide in it at all. `first_message_paths_test`
/// and `session_reset_test` scan lib/ the same way and for the same reason.
void main() {
  /// Tab -> (file that renders it, how it mounts its guide).
  ///
  /// Matches is the odd one out: it predates `PageGuide` and keeps its own
  /// panel because its events are reported against the registration funnel
  /// and must not be merged into the generic `guide_shown`.
  const tabs = <String, ({String file, String mounts})>{
    'AI Study': (
      file: 'lib/pages/learning/main/learning_main_screen.dart',
      mounts: 'GuideSurface.aiStudy',
    ),
    'Community / Matches': (
      file: 'lib/pages/community/tabs/matches_tab.dart',
      mounts: 'MatchesFirstSessionPanel',
    ),
    'Chats': (
      file: 'lib/pages/chat/list/chat_list_screen.dart',
      mounts: 'GuideSurface.chats',
    ),
    'Moments': (
      file: 'lib/pages/moments/feed/moments_main.dart',
      mounts: 'GuideSurface.moments',
    ),
    'Profile': (
      file: 'lib/pages/profile/profile_main.dart',
      mounts: 'GuideSurface.profile',
    ),
  };

  for (final entry in tabs.entries) {
    test('the ${entry.key} tab shows a guide', () {
      final file = File(entry.value.file);
      expect(file.existsSync(), isTrue,
          reason: '${entry.value.file} is missing — if this tab moved, move '
              'its guide with it rather than deleting this row');

      expect(
        file.readAsStringSync().contains(entry.value.mounts),
        isTrue,
        reason: 'A new user opening ${entry.key} is shown nothing about what '
            'it is for. Mount ${entry.value.mounts} in ${entry.value.file}.',
      );
    });
  }

  test('every GuideSurface is mounted by some page', () {
    final source = File('lib/services/guide_store.dart').readAsStringSync();
    final declared = RegExp(r'^\s{2}(\w+)\(', multiLine: true)
        .allMatches(source)
        .map((m) => m.group(1)!)
        .where((n) => n != 'const')
        .toSet();

    final mounted = tabs.values.map((t) => t.mounts).join('\n');
    for (final name in declared) {
      if (name == 'matches') continue; // has its own panel, asserted above
      expect(mounted.contains('GuideSurface.$name'), isTrue,
          reason: 'GuideSurface.$name exists but no page mounts it — a '
              'surface nobody shows is dead code that still burns a slug');
    }
  });
}
