import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/language_flags.dart';

/// The COMPLETE language list from the backend `languages` collection
/// (127 entries, verified against prod 2026-07-15 + seeds/languages.js).
/// Every one of these is a name a user can pick as native_language /
/// language_to_learn — and every one MUST render a flag on profile and
/// community surfaces (getFlagByName), never the 🌐 fallback — except the
/// languages in [kGlobeByChoice].
const List<String> kAllBackendLanguageNames = [
  'English', 'Korean', 'Tagalog', 'Filipino', 'Arabic', 'Japanese',
  'Vietnamese', 'Thai', 'Indonesian', 'Malay', 'Burmese',
  'Chinese (Traditional)', 'Chinese (Simplified)', 'Hindi', 'Bengali',
  'Tamil', 'Telugu', 'Marathi', 'Urdu', 'Nepali', 'Sinhala', 'Spanish',
  'Portuguese', 'Portuguese (Brazil)', 'French', 'German', 'Italian',
  'Russian', 'Ukrainian', 'Dutch', 'Swedish', 'Polish', 'Norwegian',
  'Danish', 'Finnish', 'Greek', 'Hungarian', 'Khmer', 'Lao', 'Turkish',
  'English (US)', 'Cantonese', 'English (UK)', 'Punjabi', 'Gujarati',
  'Kannada', 'Malayalam', 'Odia', 'Assamese', 'Sindhi', 'Kashmiri',
  'Dhivehi', 'Hebrew', 'Persian', 'Pashto', 'Dari', 'Kurdish', 'Swahili',
  'Amharic', 'Tigrinya', 'Oromo', 'Somali', 'Afrikaans', 'Zulu', 'Xhosa',
  'Romanian', 'Setswana', 'Czech', 'Kinyarwanda', 'Luganda', 'Malagasy',
  'Yoruba', 'Chichewa', 'Igbo', 'Hausa', 'Wolof', 'Fula', 'Kazakh',
  'Kyrgyz', 'Uzbek', 'Turkmen', 'Tajik', 'Mongolian', 'Georgian',
  'Azerbaijani', 'Bulgarian', 'Armenian', 'Serbian', 'Croatian', 'Slovak',
  'Slovenian', 'Bosnian', 'Macedonian', 'Belarusian', 'Estonian',
  'Lithuanian', 'Latvian', 'Catalan', 'Galician', 'Basque', 'Occitan',
  'Icelandic', 'Luxembourgish', 'Frisian', 'Faroese', 'Irish', 'Welsh',
  'Scottish Gaelic', 'Breton', 'Maltese', 'Albanian', 'Maori', 'Samoan',
  'Tongan', 'Fijian', 'Hawaiian', 'Haitian Creole', 'Quechua', 'Guarani',
  'Esperanto', 'Latin', 'American Sign Language', 'British Sign Language',
  'Japanese Sign Language', 'Korean Sign Language', 'Sesotho', 'Shona',
  // Seeded but not yet in prod (pending seeder re-run):
  'Spanish (Mexico)', 'French (Canada)', 'Portuguese (Portugal)',
  'English (Australia)', 'English (Canada)', 'Spanish (Argentina)',
  'Arabic (Egyptian)', 'Arabic (Levantine)', 'Arabic (Gulf)',
  'Arabic (Moroccan Darija)',
];

/// Languages with no emoji flag of their own. Showing a state flag (🇪🇸 for
/// Basque, 🇬🇧 for Welsh) reads as "speaks Spanish / English", so they show
/// the globe on purpose (owner decision, 2026-10-17).
const Set<String> kGlobeByChoice = {
  'Basque', 'Catalan', 'Galician', 'Latin', 'Welsh', 'Scottish Gaelic',
  'Breton', 'Kurdish', 'Esperanto',
};

void main() {
  group('LanguageFlags — international completeness', () {
    test('every backend language name resolves to a flag (never 🌐)', () {
      final missing = <String>[];
      for (final name in kAllBackendLanguageNames) {
        if (kGlobeByChoice.contains(name)) continue;
        if (LanguageFlags.getFlagByName(name) == '🌐') {
          missing.add(name);
        }
      }
      expect(missing, isEmpty,
          reason: 'Every pickable language must render a flag:\n'
              '${missing.join('\n')}');
    });
  });

  group('LanguageFlags — regional variants (languages ≠ countries fix)', () {
    test('variant names render their region flag, not the base-country flag', () {
      expect(LanguageFlags.getFlagByName('Portuguese (Brazil)'), '🇧🇷');
      expect(LanguageFlags.getFlagByName('Portuguese (Portugal)'), '🇵🇹');
      expect(LanguageFlags.getFlagByName('English (US)'), '🇺🇸');
      expect(LanguageFlags.getFlagByName('English (UK)'), '🇬🇧');
      expect(LanguageFlags.getFlagByName('Chinese (Traditional)'), '🇹🇼');
      expect(LanguageFlags.getFlagByName('Chinese (Simplified)'), '🇨🇳');
      expect(LanguageFlags.getFlagByName('Cantonese'), '🇭🇰');
      expect(LanguageFlags.getFlagByName('Spanish (Mexico)'), '🇲🇽');
      expect(LanguageFlags.getFlagByName('French (Canada)'), '🇨🇦');
      expect(LanguageFlags.getFlagByName('English (Australia)'), '🇦🇺');
      expect(LanguageFlags.getFlagByName('English (Canada)'), '🇨🇦');
      expect(LanguageFlags.getFlagByName('Spanish (Argentina)'), '🇦🇷');
    });

    test('Arabic varieties render their region flag; plain Arabic (=MSA) keeps 🇸🇦', () {
      expect(LanguageFlags.getFlagByName('Arabic'), '🇸🇦');
      expect(LanguageFlags.getFlagByName('Arabic (MSA)'), '🇸🇦');
      expect(LanguageFlags.getFlagByName('Arabic (Egyptian)'), '🇪🇬');
      expect(LanguageFlags.getFlagByName('Arabic (Levantine)'), '🇱🇧');
      expect(LanguageFlags.getFlagByName('Arabic (Gulf)'), '🇸🇦');
      expect(LanguageFlags.getFlagByName('Arabic (Moroccan Darija)'), '🇲🇦');
    });

    test('base language names keep their existing convention flags', () {
      expect(LanguageFlags.getFlagByName('Portuguese'), '🇵🇹');
      expect(LanguageFlags.getFlagByName('English'), '🇬🇧');
      expect(LanguageFlags.getFlagByName('Spanish'), '🇪🇸');
      expect(LanguageFlags.getFlagByName('Chinese'), '🇨🇳');
    });

    test('languages with no flag of their own show the globe, not a state flag', () {
      // A Basque speaker shown 🇪🇸 reads as "speaks Spanish".
      for (final name in kGlobeByChoice) {
        expect(LanguageFlags.getFlagByName(name), '🌐', reason: name);
      }
      expect(LanguageFlags.getFlag('eu'), '🌐');
      expect(LanguageFlags.getFlag('la'), '🌐');
    });

    test('sign languages render the sign-language hand, not a country flag', () {
      expect(LanguageFlags.getFlagByName('American Sign Language'), '🤟');
      expect(LanguageFlags.getFlagByName('British Sign Language'), '🤟');
      expect(LanguageFlags.getFlagByName('Japanese Sign Language'), '🤟');
      expect(LanguageFlags.getFlagByName('Korean Sign Language'), '🤟');
    });
  });
}
