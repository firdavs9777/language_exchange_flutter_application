import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/providers/languages_provider.dart';
import 'package:bananatalk_app/utils/language_codes.dart';

Language _lang(String code, String name) =>
    Language(id: '', code: code, name: name, nativeName: name);

void main() {
  group('LanguageCodes.toBaseIso6391 — variant → base mapping', () {
    test('regional variants map to their base 639-1 code', () {
      expect(LanguageCodes.toBaseIso6391('pt-BR'), 'pt');
      expect(LanguageCodes.toBaseIso6391('pt-PT'), 'pt');
      expect(LanguageCodes.toBaseIso6391('en-US'), 'en');
      expect(LanguageCodes.toBaseIso6391('en-GB'), 'en');
      expect(LanguageCodes.toBaseIso6391('zh-CN'), 'zh');
      expect(LanguageCodes.toBaseIso6391('zh-TW'), 'zh');
      expect(LanguageCodes.toBaseIso6391('zh-HK'), 'zh'); // Cantonese → zh
      expect(LanguageCodes.toBaseIso6391('es-MX'), 'es');
      expect(LanguageCodes.toBaseIso6391('es-AR'), 'es');
      expect(LanguageCodes.toBaseIso6391('fr-CA'), 'fr');
      expect(LanguageCodes.toBaseIso6391('en-AU'), 'en');
      expect(LanguageCodes.toBaseIso6391('en-CA'), 'en');
      // Arabic varieties: nonstandard region-style subtags (EG/LV/GU/MA)
      // — the prefix rule groups them to base 'ar' regardless of subtag
      // validity, so moment tags/feeds never fragment Arabic.
      expect(LanguageCodes.toBaseIso6391('ar-EG'), 'ar');
      expect(LanguageCodes.toBaseIso6391('ar-LV'), 'ar');
      expect(LanguageCodes.toBaseIso6391('ar-GU'), 'ar');
      expect(LanguageCodes.toBaseIso6391('ar-MA'), 'ar');
    });

    test('plain 639-1 codes pass through (case/whitespace-insensitive)', () {
      expect(LanguageCodes.toBaseIso6391('en'), 'en');
      expect(LanguageCodes.toBaseIso6391(' KO '), 'ko');
    });

    test('639-3 codes with a documented base map to it', () {
      expect(LanguageCodes.toBaseIso6391('fil'), 'tl'); // Filipino → Tagalog
      expect(LanguageCodes.toBaseIso6391('prs'), 'fa'); // Dari → Persian
    });

    test('sign languages and Hawaiian are excluded (null)', () {
      expect(LanguageCodes.toBaseIso6391('ase'), isNull);
      expect(LanguageCodes.toBaseIso6391('bfi'), isNull);
      expect(LanguageCodes.toBaseIso6391('jsl'), isNull);
      expect(LanguageCodes.toBaseIso6391('kvk'), isNull);
      expect(LanguageCodes.toBaseIso6391('haw'), isNull);
    });

    test('unknown 3+ letter codes and empties are excluded (null)', () {
      expect(LanguageCodes.toBaseIso6391('ceb'), isNull);
      expect(LanguageCodes.toBaseIso6391(''), isNull);
      expect(LanguageCodes.toBaseIso6391('   '), isNull);
    });
  });

  group('LanguageCodes.buildTaggableLanguages', () {
    test('collapses variants into one base entry, first occurrence wins', () {
      final catalog = [
        _lang('en', 'English'),
        _lang('en-US', 'English (US)'),
        _lang('en-GB', 'English (UK)'),
        _lang('pt', 'Portuguese'),
        _lang('pt-BR', 'Portuguese (Brazil)'),
      ];
      final result = LanguageCodes.buildTaggableLanguages(catalog);
      expect(result.map((e) => e['code']), ['en', 'pt']);
      expect(result.map((e) => e['name']), ['English', 'Portuguese']);
    });

    test('strips the regional parenthetical when a variant is first', () {
      // Catalog order can put a variant first (e.g. Chinese has no plain
      // "Chinese" row — Traditional/Simplified only).
      final catalog = [
        _lang('zh-TW', 'Chinese (Traditional)'),
        _lang('zh-CN', 'Chinese (Simplified)'),
      ];
      final result = LanguageCodes.buildTaggableLanguages(catalog);
      expect(result.single['code'], 'zh');
      expect(result.single['name'], 'Chinese');
    });

    test('Dari collapses into the earlier Persian entry', () {
      final catalog = [
        _lang('fa', 'Persian'),
        _lang('prs', 'Dari'),
      ];
      final result = LanguageCodes.buildTaggableLanguages(catalog);
      expect(result.single['name'], 'Persian');
      expect(result.single['code'], 'fa');
    });

    test('sign languages are excluded; order otherwise preserved', () {
      final catalog = [
        _lang('ko', 'Korean'),
        _lang('ase', 'American Sign Language'),
        _lang('ja', 'Japanese'),
      ];
      final result = LanguageCodes.buildTaggableLanguages(catalog);
      expect(result.map((e) => e['code']), ['ko', 'ja']);
    });

    test('every entry carries a flag', () {
      final result = LanguageCodes.buildTaggableLanguages([
        _lang('ko', 'Korean'),
        _lang('pt-BR', 'Portuguese (Brazil)'),
      ]);
      expect(result[0]['flag'], '🇰🇷');
      expect(result[1]['flag'], '🇵🇹'); // base 'pt' — tag is base-language
    });
  });

  group('resolveLanguageCatalog — provider fallback precedence', () {
    final fallback = [_lang('en', 'English')];
    final cached = [_lang('en', 'English'), _lang('ko', 'Korean')];
    final fetched = [_lang('en', 'English'), _lang('ko', 'Korean'), _lang('ja', 'Japanese')];

    test('fetched wins when non-empty', () {
      expect(
        resolveLanguageCatalog(fetched: fetched, cached: cached, fallback: fallback),
        fetched,
      );
    });

    test('cached wins when fetch failed/empty', () {
      expect(
        resolveLanguageCatalog(fetched: null, cached: cached, fallback: fallback),
        cached,
      );
      expect(
        resolveLanguageCatalog(fetched: [], cached: cached, fallback: fallback),
        cached,
      );
    });

    test('fallback when neither is available', () {
      expect(
        resolveLanguageCatalog(fetched: null, cached: null, fallback: fallback),
        fallback,
      );
      expect(
        resolveLanguageCatalog(fetched: [], cached: [], fallback: fallback),
        fallback,
      );
    });
  });

  group('parseLanguageCatalog', () {
    test('parses a standard {success, data: [...]} body', () {
      const body =
          '{"success":true,"data":[{"_id":"1","code":"ko","name":"Korean","nativeName":"한국어","flag":"🇰🇷"}]}';
      final result = parseLanguageCatalog(body);
      expect(result.single.code, 'ko');
      expect(result.single.name, 'Korean');
    });

    test('returns [] for malformed/empty bodies (never throws)', () {
      expect(parseLanguageCatalog('not json'), isEmpty);
      expect(parseLanguageCatalog('{}'), isEmpty);
      expect(parseLanguageCatalog('{"data":[{"code":"","name":""}]}'), isEmpty);
    });
  });
}
