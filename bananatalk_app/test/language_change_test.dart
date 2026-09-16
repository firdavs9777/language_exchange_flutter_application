import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guards the invalidation set in
/// lib/providers/provider_root/learning/language_change.dart.
///
/// A unit test cannot meaningfully assert "Riverpod refetched" without standing
/// up every provider's network call, so this checks the property that actually
/// broke: a provider whose content depends on the learner's language pair, that
/// nobody remembered to invalidate.
///
/// The original bug was exactly this omission — changing `language_to_learn`
/// invalidated only the prompt of the day, leaving the Today tab serving a pack
/// in the language the learner had just abandoned.
void main() {
  final root = Directory.current.path;
  String read(String rel) => File('$root/$rel').readAsStringSync();

  group('language change invalidation', () {
    late String source;

    setUp(() {
      source = read('lib/providers/provider_root/learning/language_change.dart');
    });

    test('invalidates the user, which every watcher cascades from', () {
      expect(source, contains('ref.invalidate(userProvider)'));
    });

    test('invalidates the providers that do NOT watch the user', () {
      // These fetch language-dependent content without reading userProvider, so
      // a cascade cannot save them. dailyPackProvider is the one that actually
      // shipped broken: it watches the app's UI locale, while the SERVER picks
      // the content language from the profile.
      for (final provider in [
        'dailyPackProvider',
        'promptOfDayProvider',
        'tutorMemoryAndQuotasProvider',
      ]) {
        expect(source, contains('ref.invalidate($provider)'),
            reason: '$provider is language-derived and must be invalidated');
      }
    });

    test('resets the lesson filter, which screens seed once in initState', () {
      expect(source, contains('ref.invalidate(lessonFilterProvider)'));
    });

    test('both native and target language changes trigger it', () {
      // Native language is the SOURCE language for lessons and explanations,
      // so it changes content just as much as the target does. The original
      // code only handled the target branch.
      final edit = read('lib/pages/profile/edit/language_edit.dart');
      expect(edit, contains('invalidateLanguageDerived(ref)'));

      // Called once, after the if/else, rather than inside one branch.
      expect(
        'invalidateLanguageDerived(ref)'.allMatches(edit).length,
        1,
        reason: 'one call covering both branches, not one branch only',
      );
    });

    test('the language edit screen no longer hand-rolls its own invalidation', () {
      // If a call site starts invalidating providers itself again, the set
      // drifts and this whole file stops being the single answer.
      final edit = read('lib/pages/profile/edit/language_edit.dart');
      expect(edit, isNot(contains('ref.invalidate(promptOfDayProvider)')),
          reason: 'invalidation belongs in invalidateLanguageDerived');
    });
  });
}
