import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/utils/language_codes.dart';
import 'package:bananatalk_app/utils/language_normalize.dart';

Language _lang(String code, String name) =>
    Language(id: '', code: code, name: name, nativeName: name);

/// A representative slice of the real production catalog (backend
/// seeds/languages.js — the actual GET /languages source of truth), used
/// to prime [LanguageCatalog] the same way `languagesProvider` does after
/// a successful fetch (see providers/languages_provider.dart).
///
/// Order matters for Chinese: [LanguageCodes.buildTaggableLanguages]
/// dedupes variants to the FIRST occurrence's (parenthetical-stripped)
/// name, so 'Chinese (Simplified)' must precede 'Cantonese' here — exactly
/// as in the real seed file — or bare "Chinese" would resolve toward
/// "Cantonese" instead of "Chinese".
final List<Language> _catalog = [
  _lang('en', 'English'),
  _lang('ko', 'Korean'),
  _lang('zh-CN', 'Chinese (Simplified)'),
  _lang('zh-TW', 'Chinese (Traditional)'),
  _lang('zh-HK', 'Cantonese'),
  _lang('ja', 'Japanese'),
  _lang('fr', 'French'),
  _lang('ru', 'Russian'),
  _lang('de', 'German'),
  _lang('es', 'Spanish'),
  _lang('ar', 'Arabic'),
  _lang('hi', 'Hindi'),
  _lang('ur', 'Urdu'),
  _lang('it', 'Italian'),
  _lang('tl', 'Tagalog'),
  _lang('fil', 'Filipino'),
  _lang('af', 'Afrikaans'),
  _lang('tr', 'Turkish'),
  _lang('vi', 'Vietnamese'),
  _lang('th', 'Thai'),
  _lang('id', 'Indonesian'),
  _lang('pt', 'Portuguese'),
  _lang('tg', 'Tajik'),
  // Beyond the ~20-entry table the brief proposed:
  _lang('sw', 'Swahili'),
  _lang('is', 'Icelandic'),
  _lang('cy', 'Welsh'),
  _lang('zu', 'Zulu'),
  _lang('ha', 'Hausa'),
  _lang('ky', 'Kyrgyz'),
];

void main() {
  setUp(() {
    // Simulates the catalog having loaded this session, as it normally
    // would via languagesProvider before this function is ever called.
    LanguageCatalog.update(_catalog);
  });

  tearDown(() {
    LanguageCatalog.reset();
  });

  test('all four English variants collapse to en', () {
    expect(toBaseLanguage('English'), 'en');
    expect(toBaseLanguage('English (US)'), 'en');
    expect(toBaseLanguage('English (UK)'), 'en');
    expect(toBaseLanguage('en'), 'en');
  });

  test('Chinese scripts stay distinct', () {
    expect(toBaseLanguage('Chinese (Simplified)'), 'zh-Hans');
    expect(toBaseLanguage('Chinese (Traditional)'), 'zh-Hant');
  });

  test('matching is case and whitespace insensitive', () {
    expect(toBaseLanguage('  english '), 'en');
    expect(toBaseLanguage('KOREAN'), 'ko');
  });

  test('empty, null and unknown values return null', () {
    expect(toBaseLanguage(''), isNull);
    expect(toBaseLanguage('   '), isNull);
    expect(toBaseLanguage(null), isNull);
    expect(toBaseLanguage('Klingon'), isNull);
  });

  test('bare Chinese/zh never guesses a script', () {
    expect(toBaseLanguage('Chinese'), 'zh');
    expect(toBaseLanguage('zh'), 'zh');
  });

  test('Chinese script region tags, both cases', () {
    expect(toBaseLanguage('zh-CN'), 'zh-Hans');
    expect(toBaseLanguage('zh-TW'), 'zh-Hant');
    expect(toBaseLanguage('zh-hans'), 'zh-Hans');
    expect(toBaseLanguage('zh-hant'), 'zh-Hant');
  });

  group('coverage beyond a hand-picked ~20-language table', () {
    test('languages the brief\'s map omitted resolve by display name', () {
      // None of these three appear in the brief's hand-written map at
      // all. They resolve here because toBaseLanguage matches against
      // the live, full LanguageCatalog rather than a short static table.
      expect(toBaseLanguage('Swahili'), 'sw');
      expect(toBaseLanguage('Icelandic'), 'is');
      expect(toBaseLanguage('Welsh'), 'cy');
    });

    test('catalog codes resolve generically even with no catalog loaded',
        () {
      LanguageCatalog.reset();
      // LanguageCodes.toBaseIso6391 covers every code in the shared
      // catalog generically (not a hand-picked subset), so these resolve
      // with zero network/catalog state.
      expect(toBaseLanguage('sw'), 'sw');
      expect(toBaseLanguage('zu'), 'zu');
      expect(toBaseLanguage('ky'), 'ky');
      // The two documented 639-3 exceptions the brief's map never
      // mentioned as codes at all.
      expect(toBaseLanguage('fil'), 'tl'); // Filipino → Tagalog
      expect(toBaseLanguage('prs'), 'fa'); // Dari → Persian
    });
  });

  test('name-shaped input is honest about needing the catalog loaded', () {
    LanguageCatalog.reset();
    // No hand-written fallback table is used to guess this — until the
    // catalog loads, an un-loaded name-shaped value returns null rather
    // than a guess.
    expect(toBaseLanguage('Korean'), isNull);
  });
}
