import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/country_flags.dart';
import 'package:bananatalk_app/pages/community/filter/filter_country_section.dart'
    show kAllCountries;

void main() {
  group('CountryFlags — international completeness', () {
    test('every country in the app-wide picker list (kAllCountries) resolves to its flag', () {
      final missing = <String>[];
      for (final entry in kAllCountries) {
        final name = entry['name']!;
        final expectedFlag = entry['flag']!;
        final resolved = CountryFlags.getFlag(name);
        if (resolved != expectedFlag) {
          missing.add("$name (expected $expectedFlag, got ${resolved ?? 'null'})");
        }
      }
      expect(missing, isEmpty,
          reason: 'CountryFlags must cover the full country picker list:\n'
              '${missing.join('\n')}');
    });
  });

  group('CountryFlags.getFlag', () {
    test('resolves the exact user-reported mismatch cases', () {
      // Brazilian Portuguese speaker: country wins over pt's 🇵🇹.
      expect(CountryFlags.getFlag('Brazil'), '🇧🇷');
      // US English speaker: country wins over en's 🇬🇧.
      expect(CountryFlags.getFlag('United States'), '🇺🇸');
    });

    test('resolves every country name observed in prod (2026-07 sweep)', () {
      const prodNames = {
        'China': '🇨🇳',
        'Morocco': '🇲🇦',
        'Russia': '🇷🇺',
        'Algeria': '🇩🇿',
        'South Korea': '🇰🇷',
        'Saudi Arabia': '🇸🇦',
        'Iraq': '🇮🇶',
        'Philippines': '🇵🇭',
        'Egypt': '🇪🇬',
        'Taiwan': '🇹🇼',
        'United States': '🇺🇸',
        'Nigeria': '🇳🇬',
        'Japan': '🇯🇵',
        'Türkiye': '🇹🇷',
        'Jordan': '🇯🇴',
        'Thailand': '🇹🇭',
        'Brazil': '🇧🇷',
        'Myanmar (Burma)': '🇲🇲',
        'India': '🇮🇳',
        'Indonesia': '🇮🇩',
        'Libya': '🇱🇾',
        'Ukraine': '🇺🇦',
        'France': '🇫🇷',
        'Italy': '🇮🇹',
        'Oman': '🇴🇲',
      };
      prodNames.forEach((name, flag) {
        expect(CountryFlags.getFlag(name), flag, reason: name);
      });
    });

    test('handles case, whitespace, and common synonyms', () {
      expect(CountryFlags.getFlag('  brazil  '), '🇧🇷');
      expect(CountryFlags.getFlag('USA'), '🇺🇸');
      expect(CountryFlags.getFlag('UK'), '🇬🇧');
      expect(CountryFlags.getFlag('Turkey'), '🇹🇷');
      expect(CountryFlags.getFlag('Korea'), '🇰🇷');
    });

    test('parenthetical fallback: "Name (Variant)" resolves via base name', () {
      expect(CountryFlags.getFlag('Congo (DRC)'), '🇨🇩');
    });

    test('returns null for empty/unknown values (caller falls back)', () {
      expect(CountryFlags.getFlag(null), isNull);
      expect(CountryFlags.getFlag(''), isNull);
      expect(CountryFlags.getFlag('   '), isNull);
      expect(CountryFlags.getFlag('Atlantis'), isNull);
    });
  });

  group('CountryFlags.userBadgeFlag', () {
    test('country flag wins when country resolves', () {
      expect(
        CountryFlags.userBadgeFlag(
          country: 'Brazil',
          nativeLanguage: 'Portuguese',
        ),
        '🇧🇷',
      );
    });

    test('falls back to native-language flag when country is null (privacy-hidden or absent)', () {
      expect(
        CountryFlags.userBadgeFlag(
          country: null,
          nativeLanguage: 'Portuguese',
        ),
        '🇵🇹',
      );
    });

    test('falls back to native-language flag when country is unknown', () {
      expect(
        CountryFlags.userBadgeFlag(
          country: 'Atlantis',
          nativeLanguage: 'Korean',
        ),
        '🇰🇷',
      );
    });

    test('globe when neither country nor language resolves', () {
      expect(
        CountryFlags.userBadgeFlag(country: null, nativeLanguage: null),
        '🌐',
      );
    });
  });
}
