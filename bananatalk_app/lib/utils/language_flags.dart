/// Language Flags Utility
/// Maps language codes to their corresponding country flag emojis
class LanguageFlags {
  static const Map<String, String> flags = {
    // Region-specific overrides. Backend uses hyphenated codes like
    // 'zh-CN', 'zh-TW', 'pt-BR' that should map to distinct flags. Listed
    // first so they win over the base-code fallback below.
    'zh-cn': '🇨🇳', // Chinese (Simplified) — Mainland
    'zh-tw': '🇹🇼', // Chinese (Traditional) — Taiwan
    'zh-hk': '🇭🇰', // Chinese (Cantonese) — Hong Kong
    'pt-br': '🇧🇷', // Portuguese (Brazil)
    'pt-pt': '🇵🇹', // Portuguese (Portugal)
    'en-us': '🇺🇸', // English (US)
    'en-gb': '🇬🇧', // English (UK)
    'en-au': '🇦🇺', // English (Australia)
    'en-ca': '🇨🇦', // English (Canada)
    'es-mx': '🇲🇽', // Spanish (Mexico)
    'es-es': '🇪🇸', // Spanish (Spain)
    'es-ar': '🇦🇷', // Spanish (Argentina)
    'fr-ca': '🇨🇦', // French (Canada)
    'fa-tj': '🇹🇯', // Tajik written as Persian-Tajikistan variant
    // Arabic varieties (catalog codes ar-EG/ar-LV/ar-GU/ar-MA — pragmatic
    // region-style tags, see backend seeds/languages.js). Explicit entries
    // required: the hyphen fallback would otherwise collapse them all to
    // 'ar' → 🇸🇦. Levantine → 🇱🇧 (recognized media standard for a
    // dialect spanning LB/SY/JO/PS); Gulf → 🇸🇦 (largest Gulf state).
    'ar-eg': '🇪🇬', // Arabic (Egyptian)
    'ar-lv': '🇱🇧', // Arabic (Levantine)
    'ar-gu': '🇸🇦', // Arabic (Gulf)
    'ar-ma': '🇲🇦', // Arabic (Moroccan Darija)

    // Major Languages
    'en': '🇬🇧', // English
    'es': '🇪🇸', // Spanish
    'fr': '🇫🇷', // French
    'de': '🇩🇪', // German
    'it': '🇮🇹', // Italian
    'pt': '🇵🇹', // Portuguese
    'ru': '🇷🇺', // Russian
    'zh': '🇨🇳', // Chinese
    'ja': '🇯🇵', // Japanese
    'ko': '🇰🇷', // Korean
    'ar': '🇸🇦', // Arabic
    'hi': '🇮🇳', // Hindi
    'nl': '🇳🇱', // Dutch
    'tr': '🇹🇷', // Turkish
    'pl': '🇵🇱', // Polish
    'sv': '🇸🇪', // Swedish
    'da': '🇩🇰', // Danish
    'no': '🇳🇴', // Norwegian
    'fi': '🇫🇮', // Finnish
    'cs': '🇨🇿', // Czech
    'el': '🇬🇷', // Greek
    'he': '🇮🇱', // Hebrew
    'th': '🇹🇭', // Thai
    'vi': '🇻🇳', // Vietnamese
    'id': '🇮🇩', // Indonesian
    'ms': '🇲🇾', // Malay
    'uk': '🇺🇦', // Ukrainian
    'ro': '🇷🇴', // Romanian
    'hu': '🇭🇺', // Hungarian
    'bg': '🇧🇬', // Bulgarian
    'hr': '🇭🇷', // Croatian
    'sr': '🇷🇸', // Serbian
    'sk': '🇸🇰', // Slovak
    'sl': '🇸🇮', // Slovene
    
    // African Languages
    'af': '🇿🇦', // Afrikaans
    'am': '🇪🇹', // Amharic
    'ha': '🇳🇬', // Hausa
    'ig': '🇳🇬', // Igbo
    'sw': '🇰🇪', // Swahili
    'so': '🇸🇴', // Somali
    'yo': '🇳🇬', // Yoruba
    'zu': '🇿🇦', // Zulu
    'xh': '🇿🇦', // Xhosa
    'st': '🇿🇦', // Southern Sotho
    'tn': '🇧🇼', // Tswana
    'sn': '🇿🇼', // Shona
    'rw': '🇷🇼', // Kinyarwanda
    'lg': '🇺🇬', // Luganda
    'wo': '🇸🇳', // Wolof
    
    // Asian Languages
    'bn': '🇧🇩', // Bengali
    'ta': '🇮🇳', // Tamil
    'te': '🇮🇳', // Telugu
    'ur': '🇵🇰', // Urdu
    'fa': '🇮🇷', // Persian/Farsi
    'ps': '🇦🇫', // Pashto
    'ku': '🇮🇶', // Kurdish
    'gu': '🇮🇳', // Gujarati
    'kn': '🇮🇳', // Kannada
    'ml': '🇮🇳', // Malayalam
    'mr': '🇮🇳', // Marathi
    'pa': '🇮🇳', // Punjabi
    'si': '🇱🇰', // Sinhala
    'ne': '🇳🇵', // Nepali
    'my': '🇲🇲', // Burmese
    'km': '🇰🇭', // Khmer
    'lo': '🇱🇦', // Lao
    'ka': '🇬🇪', // Georgian
    'hy': '🇦🇲', // Armenian
    'az': '🇦🇿', // Azerbaijani
    'uz': '🇺🇿', // Uzbek
    'kk': '🇰🇿', // Kazakh
    'ky': '🇰🇬', // Kyrgyz
    'tg': '🇹🇯', // Tajik
    'tk': '🇹🇲', // Turkmen
    'mn': '🇲🇳', // Mongolian
    
    // European Languages
    'sq': '🇦🇱', // Albanian
    'be': '🇧🇾', // Belarusian
    'bs': '🇧🇦', // Bosnian
    'ca': '🇪🇸', // Catalan
    'et': '🇪🇪', // Estonian
    'gl': '🇪🇸', // Galician
    'is': '🇮🇸', // Icelandic
    'ga': '🇮🇪', // Irish
    'lv': '🇱🇻', // Latvian
    'lt': '🇱🇹', // Lithuanian
    'lb': '🇱🇺', // Luxembourgish
    'mk': '🇲🇰', // Macedonian
    'mt': '🇲🇹', // Maltese
    'eu': '🇪🇸', // Basque
    'cy': '🇬🇧', // Welsh
    'gd': '🇬🇧', // Scottish Gaelic
    'br': '🇫🇷', // Breton
    'co': '🇫🇷', // Corsican
    'fy': '🇳🇱', // Western Frisian
    'fo': '🇫🇴', // Faroese
    
    // Pacific Languages
    'tl': '🇵🇭', // Tagalog
    'tajik': '🇹🇯', // Tajik (duplicate flag entry)
    'ceb': '🇵🇭', // Cebuano
    'haw': '🇺🇸', // Hawaiian
    'mi': '🇳🇿', // Maori
    'sm': '🇼🇸', // Samoan
    'to': '🇹🇴', // Tongan
    'fj': '🇫🇯', // Fijian
    
    // Middle Eastern Languages
    'iw': '🇮🇱', // Hebrew (alternative code)
    'yi': '🇮🇱', // Yiddish
    'sd': '🇵🇰', // Sindhi
    'ug': '🇨🇳', // Uyghur
    'ks': '🇮🇳', // Kashmiri
    'prs': '🇦🇫', // Dari

    // Sign languages (backend `languages` collection; flag matches
    // seeds/languages.js — the sign-language hand, not a country flag)
    'fil': '🇵🇭', // Filipino (backend code variant of Tagalog)
    'ase': '🤟', // American Sign Language
    'bfi': '🤟', // British Sign Language
    'jsl': '🤟', // Japanese Sign Language
    'kvk': '🤟', // Korean Sign Language
    
    // Latin American Languages
    'qu': '🇵🇪', // Quechua
    'gn': '🇵🇾', // Guarani
    'ay': '🇧🇴', // Aymara
    'ht': '🇭🇹', // Haitian Creole
    
    // Other Languages
    'eo': '🌍', // Esperanto (global)
    'la': '🇻🇦', // Latin
    'sa': '🇮🇳', // Sanskrit
    'jv': '🇮🇩', // Javanese
    'su': '🇮🇩', // Sundanese
    'mg': '🇲🇬', // Malagasy
    'ny': '🇲🇼', // Chichewa
    'ti': '🇪🇷', // Tigrinya
    'om': '🇪🇹', // Oromo
    'or': '🇮🇳', // Oriya
    'as': '🇮🇳', // Assamese
    'bh': '🇮🇳', // Bihari
    'dv': '🇲🇻', // Divehi
    'rn': '🇧🇮', // Kirundi
    'sg': '🇨🇫', // Sango
    'tt': '🇷🇺', // Tatar
    'bo': '🇨🇳', // Tibetan
    'ts': '🇿🇦', // Tsonga
    've': '🇿🇦', // Venda
    'ss': '🇸🇿', // Swati
    'ee': '🇬🇭', // Ewe
    'tw': '🇬🇭', // Twi
    'ak': '🇬🇭', // Akan
    'ln': '🇨🇩', // Lingala
    'kg': '🇨🇩', // Kongo
    'lu': '🇨🇩', // Luba-Katanga
    
    // Less common languages
    'aa': '🇪🇹', // Afar
    'ab': '🇬🇪', // Abkhaz
    'ae': '🌍', // Avestan
    'av': '🇷🇺', // Avaric
    'ba': '🇷🇺', // Bashkir
    'bi': '🇻🇺', // Bislama
    'bm': '🇲🇱', // Bambara
    'ce': '🇷🇺', // Chechen
    'ch': '🇬🇺', // Chamorro
    'cr': '🇨🇦', // Cree
    'cv': '🇷🇺', // Chuvash
    'ff': '🇳🇬', // Fulah
    'gv': '🇮🇲', // Manx
    'ho': '🇵🇬', // Hiri Motu
    'hz': '🇳🇦', // Herero
    'ia': '🌍', // Interlingua
    'ie': '🌍', // Interlingue
    'ii': '🇨🇳', // Sichuan Yi
    'ik': '🇺🇸', // Inupiaq
    'io': '🌍', // Ido
    'iu': '🇨🇦', // Inuktitut
    'kj': '🇳🇦', // Kuanyama
    'kl': '🇬🇱', // Kalaallisut
    'kr': '🇳🇬', // Kanuri
    'kv': '🇷🇺', // Komi
    'kw': '🇬🇧', // Cornish
    'mh': '🇲🇭', // Marshallese
    'na': '🇳🇷', // Nauru
    'nd': '🇿🇼', // North Ndebele
    'ng': '🇳🇦', // Ndonga
    'nv': '🇺🇸', // Navajo
    'oc': '🇫🇷', // Occitan
    'oj': '🇨🇦', // Ojibwe
    'os': '🇷🇺', // Ossetian
    'pi': '🇮🇳', // Pali
    'rm': '🇨🇭', // Romansh
    'sc': '🇮🇹', // Sardinian
    'se': '🇳🇴', // Northern Sami
    'ty': '🇵🇫', // Tahitian
    'vo': '🌍', // Volapük
    'wa': '🇧🇪', // Walloon
    'za': '🇨🇳', // Zhuang
  };
  
  /// Get flag emoji for a language code.
  ///
  /// Lookup order:
  ///   1. Exact match on the full code (handles region overrides like
  ///      'zh-tw' → 🇹🇼 differently from 'zh-cn' → 🇨🇳).
  ///   2. Base-code fallback (strip the region suffix). Critical for the
  ///      backend's hyphenated codes — e.g. 'fr-ca' falls through to 'fr'
  ///      if no Canada-specific override exists.
  ///   3. Globe emoji 🌐 if neither resolves.
  static String getFlag(String languageCode) {
    if (languageCode.isEmpty) return '🌐';
    final lower = languageCode.toLowerCase();
    final direct = flags[lower];
    if (direct != null) return direct;
    final hyphen = lower.indexOf('-');
    if (hyphen > 0) {
      final base = flags[lower.substring(0, hyphen)];
      if (base != null) return base;
    }
    return '🌐';
  }

  /// Language name → code mapping for backend values like "Chinese (Simplified)", "Korean", etc.
  static const Map<String, String> _nameToCode = {
    // Exact names with variants.
    //
    // Regional variants map to region-specific flag codes (the `flags` map
    // has zh-tw/pt-br/en-us/... overrides): a user who picks
    // "Portuguese (Brazil)" as their language gets 🇧🇷, not 🇵🇹. These
    // variant names exist in the backend `languages` collection today —
    // this mapping previously collapsed them to the base country's flag,
    // defeating the point of picking a variant.
    'english': 'en',
    'english (us)': 'en-us',
    'english (uk)': 'en-gb',
    'english (australia)': 'en-au',
    'english (canada)': 'en-ca',
    'korean': 'ko',
    'japanese': 'ja',
    'japan': 'ja',
    'chinese': 'zh',
    'chinese (simplified)': 'zh',
    'chinese (traditional)': 'zh-tw',
    'mandarin': 'zh',
    'mandarin chinese': 'zh',
    'cantonese': 'zh-hk',
    'spanish': 'es',
    'spanish (mexico)': 'es-mx',
    'spanish (spain)': 'es-es',
    'spanish (argentina)': 'es-ar',
    'french': 'fr',
    'french (canada)': 'fr-ca',
    'german': 'de',
    'italian': 'it',
    'portuguese': 'pt',
    'portuguese (brazil)': 'pt-br',
    'portuguese (portugal)': 'pt-pt',
    'russian': 'ru',
    'arabic': 'ar', // plain Arabic doubles as MSA
    'arabic (msa)': 'ar',
    'arabic (egyptian)': 'ar-eg',
    'arabic (levantine)': 'ar-lv',
    'arabic (gulf)': 'ar-gu',
    'arabic (moroccan darija)': 'ar-ma',
    'darija': 'ar-ma',
    'hindi': 'hi',
    'thai': 'th',
    'vietnamese': 'vi',
    'dutch': 'nl',
    'danish': 'da',
    'swedish': 'sv',
    'norwegian': 'no',
    'finnish': 'fi',
    'polish': 'pl',
    'turkish': 'tr',
    'greek': 'el',
    'hebrew': 'he',
    'indonesian': 'id',
    'malay': 'ms',
    'ukrainian': 'uk',
    'romanian': 'ro',
    'hungarian': 'hu',
    'czech': 'cs',
    'bulgarian': 'bg',
    'croatian': 'hr',
    'serbian': 'sr',
    'uzbek': 'uz',
    'persian': 'fa',
    'farsi': 'fa',
    'bengali': 'bn',
    'tamil': 'ta',
    'telugu': 'te',
    'urdu': 'ur',
    'punjabi': 'pa',
    'gujarati': 'gu',
    'kannada': 'kn',
    'malayalam': 'ml',
    'marathi': 'mr',
    'nepali': 'ne',
    'sinhala': 'si',
    'sinhalese': 'si',
    'burmese': 'my',
    'khmer': 'km',
    'cambodian': 'km',
    'lao': 'lo',
    'laotian': 'lo',
    'georgian': 'ka',
    'armenian': 'hy',
    'azerbaijani': 'az',
    'kazakh': 'kk',
    'kyrgyz': 'ky',
    'tajik': 'tg',
    'tajiki': 'tg',
    'тоҷикӣ': 'tg',
    'turkmen': 'tk',
    'mongolian': 'mn',
    'albanian': 'sq',
    'belarusian': 'be',
    'bosnian': 'bs',
    'catalan': 'ca',
    'estonian': 'et',
    'galician': 'gl',
    'icelandic': 'is',
    'irish': 'ga',
    'latvian': 'lv',
    'lithuanian': 'lt',
    'luxembourgish': 'lb',
    'macedonian': 'mk',
    'maltese': 'mt',
    'slovak': 'sk',
    'slovenian': 'sl',
    'welsh': 'cy',
    'basque': 'eu',
    'swahili': 'sw',
    'tagalog': 'tl',
    'filipino': 'tl',
    'cebuano': 'ceb',
    'somali': 'so',
    'amharic': 'am',
    'hausa': 'ha',
    'yoruba': 'yo',
    'igbo': 'ig',
    'zulu': 'zu',
    'xhosa': 'xh',
    'afrikaans': 'af',
    'malagasy': 'mg',
    'hawaiian': 'haw',
    'samoan': 'sm',
    'tongan': 'to',
    'fijian': 'fj',
    'maori': 'mi',
    'haitian creole': 'ht',
    'yiddish': 'yi',
    'pashto': 'ps',
    'kurdish': 'ku',
    'tibetan': 'bo',
    'uyghur': 'ug',
    'esperanto': 'eo',
    'latin': 'la',
    'sanskrit': 'sa',
    'javanese': 'jv',
    'sundanese': 'su',

    // Backend `languages` collection completeness (127 names, enforced by
    // test/utils/language_flags_test.dart — every pickable language must
    // resolve; never rely on the fuzzy partial-match fallback).
    'odia': 'or',
    'assamese': 'as',
    'sindhi': 'sd',
    'kashmiri': 'ks',
    'dhivehi': 'dv',
    'dari': 'prs',
    'tigrinya': 'ti',
    'oromo': 'om',
    'setswana': 'tn',
    'tswana': 'tn',
    'sesotho': 'st',
    'shona': 'sn',
    'kinyarwanda': 'rw',
    'luganda': 'lg',
    'chichewa': 'ny',
    'wolof': 'wo',
    'fula': 'ff',
    'fulah': 'ff',
    'fulfulde': 'ff',
    'occitan': 'oc',
    'frisian': 'fy',
    'western frisian': 'fy',
    'faroese': 'fo',
    'scottish gaelic': 'gd',
    'breton': 'br',
    'quechua': 'qu',
    'guarani': 'gn',
    'american sign language': 'ase',
    'asl': 'ase',
    'british sign language': 'bfi',
    'bsl': 'bfi',
    'japanese sign language': 'jsl',
    'korean sign language': 'kvk',
  };

  /// Get flag emoji for a language name (e.g., "Chinese (Simplified)", "Korean", "Tagalog")
  /// Handles full names, names with variants in parentheses, and 2-letter codes.
  /// Returns a globe emoji 🌐 if no match found.
  static String getFlagByName(String language) {
    if (language.isEmpty) return '🌐';
    final langLower = language.toLowerCase().trim();

    // 1. Exact match
    if (_nameToCode.containsKey(langLower)) {
      return getFlag(_nameToCode[langLower]!);
    }

    // 2. Partial match (e.g., "chinese" in "chinese (simplified)")
    for (final entry in _nameToCode.entries) {
      if (langLower.contains(entry.key) || entry.key.contains(langLower)) {
        return getFlag(entry.value);
      }
    }

    // 3. Maybe it's already a 2-letter code
    if (langLower.length == 2) {
      return getFlag(langLower);
    }

    return '🌐';
  }

  /// Human-readable language name for a value that may be a display name
  /// ("German"), a lowercase name ("german"), or a code ("de"). Returns the
  /// input unchanged if it can't be resolved (e.g. "🔥 Popular"). Use for
  /// display only — never for grouping/matching keys.
  static String displayName(String language) {
    if (language.isEmpty) return language;
    final lower = language.toLowerCase().trim();

    // Already a known language name → title-case it.
    if (_nameToCode.containsKey(lower)) return _titleCase(lower);

    // A code (e.g. "de", "en-gb") → reverse-lookup the first matching name.
    for (final entry in _nameToCode.entries) {
      if (entry.value == lower) return _titleCase(entry.key);
    }

    // Unknown → return as-is (already title-cased names, "🔥 Popular", etc.).
    return language;
  }

  static String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Get recommended languages (most commonly learned - top 10 popular languages)
  static List<String> getRecommendedCodes() {
    return ['en', 'ko', 'ja', 'zh', 'es', 'fr', 'de', 'it', 'pt', 'ru'];
  }
  
  /// Check if a language is recommended
  static bool isRecommended(String languageCode) {
    return getRecommendedCodes().contains(languageCode.toLowerCase());
  }
}

