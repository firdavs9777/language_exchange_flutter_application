import 'package:bananatalk_app/utils/language_flags.dart';

/// Country Flags Utility
///
/// Maps a user's country (the English display name stored in
/// `user.location.country`, e.g. "Brazil", "United States",
/// "Myanmar (Burma)", "Türkiye") to its flag emoji.
///
/// WHY THIS EXISTS: avatar identity badges used to derive the flag from
/// the user's NATIVE LANGUAGE, which misrepresents origin — a Brazilian
/// Portuguese speaker got 🇵🇹 and an American English speaker got 🇬🇧.
/// Languages aren't countries. Identity badges now prefer the user's
/// actual country (privacy-permitting) and only fall back to the
/// language flag when no country is available (~35% of prod users).
///
/// Language-labeled UI (speaks → learns pairs, language filter chips,
/// moment language tags) deliberately KEEPS [LanguageFlags] — there the
/// flag stands for the language, not the person.
class CountryFlags {
  /// English country display name (lowercase) → ISO 3166-1 alpha-2 code.
  /// Keys must be lowercase. Includes every name observed in prod plus
  /// common variants/synonyms (e.g. "usa", "uk", "south korea", "korea").
  static const Map<String, String> _nameToIso2 = {
    // ---- Prod-observed names (2026-07 sweep) ----
    'china': 'CN',
    'morocco': 'MA',
    'russia': 'RU',
    'algeria': 'DZ',
    'south korea': 'KR',
    'saudi arabia': 'SA',
    'iraq': 'IQ',
    'philippines': 'PH',
    'egypt': 'EG',
    'taiwan': 'TW',
    'united states': 'US',
    'nigeria': 'NG',
    'japan': 'JP',
    'türkiye': 'TR',
    'jordan': 'JO',
    'thailand': 'TH',
    'brazil': 'BR',
    'myanmar (burma)': 'MM',
    'india': 'IN',
    'indonesia': 'ID',
    'libya': 'LY',
    'ukraine': 'UA',
    'france': 'FR',
    'italy': 'IT',
    'oman': 'OM',

    // ---- Common variants / synonyms ----
    'usa': 'US',
    'united states of america': 'US',
    'america': 'US',
    'uk': 'GB',
    'united kingdom': 'GB',
    'great britain': 'GB',
    'england': 'GB',
    'scotland': 'GB',
    'wales': 'GB',
    'northern ireland': 'GB',
    'korea': 'KR',
    'republic of korea': 'KR',
    'korea, south': 'KR',
    'north korea': 'KP',
    'turkey': 'TR',
    'myanmar': 'MM',
    'burma': 'MM',
    'uae': 'AE',
    'united arab emirates': 'AE',
    'czechia': 'CZ',
    'czech republic': 'CZ',
    'vietnam': 'VN',
    'viet nam': 'VN',
    'laos': 'LA',
    'ivory coast': 'CI',
    "côte d'ivoire": 'CI',
    'cape verde': 'CV',
    'cabo verde': 'CV',
    'democratic republic of the congo': 'CD',
    'dr congo': 'CD',
    'congo (drc)': 'CD',
    'republic of the congo': 'CG',
    'congo': 'CG',
    'palestine': 'PS',
    'palestinian territories': 'PS',
    'macedonia': 'MK',
    'north macedonia': 'MK',
    'swaziland': 'SZ',
    'eswatini': 'SZ',
    'east timor': 'TL',
    'timor-leste': 'TL',
    'hong kong': 'HK',
    'macau': 'MO',
    'macao': 'MO',

    // ---- Small states & territories (completes the app's kAllCountries
    // picker list — enforced by test/utils/country_flags_test.dart) ----
    'antigua and barbuda': 'AG',
    'puerto rico': 'PR',
    'saint kitts and nevis': 'KN',
    'st kitts and nevis': 'KN',
    'saint lucia': 'LC',
    'st lucia': 'LC',
    'saint vincent': 'VC',
    'saint vincent and the grenadines': 'VC',
    'sao tome and principe': 'ST',
    'são tomé and príncipe': 'ST',
    'vatican city': 'VA',
    'vatican': 'VA',
    'holy see': 'VA',
    'greenland': 'GL',
    'new caledonia': 'NC',
    'french polynesia': 'PF',
    'faroe islands': 'FO',
    'bermuda': 'BM',
    'cayman islands': 'KY',
    'aruba': 'AW',
    'curacao': 'CW',
    'curaçao': 'CW',
    'guam': 'GU',
    'western sahara': 'EH',
    'reunion': 'RE',
    'réunion': 'RE',
    'martinique': 'MQ',
    'guadeloupe': 'GP',
    'gibraltar': 'GI',
    'isle of man': 'IM',
    'jersey': 'JE',
    'guernsey': 'GG',

    // ---- Rest of the world (English display names) ----
    'afghanistan': 'AF',
    'albania': 'AL',
    'andorra': 'AD',
    'angola': 'AO',
    'argentina': 'AR',
    'armenia': 'AM',
    'australia': 'AU',
    'austria': 'AT',
    'azerbaijan': 'AZ',
    'bahamas': 'BS',
    'bahrain': 'BH',
    'bangladesh': 'BD',
    'barbados': 'BB',
    'belarus': 'BY',
    'belgium': 'BE',
    'belize': 'BZ',
    'benin': 'BJ',
    'bhutan': 'BT',
    'bolivia': 'BO',
    'bosnia and herzegovina': 'BA',
    'botswana': 'BW',
    'brunei': 'BN',
    'bulgaria': 'BG',
    'burkina faso': 'BF',
    'burundi': 'BI',
    'cambodia': 'KH',
    'cameroon': 'CM',
    'canada': 'CA',
    'central african republic': 'CF',
    'chad': 'TD',
    'chile': 'CL',
    'colombia': 'CO',
    'comoros': 'KM',
    'costa rica': 'CR',
    'croatia': 'HR',
    'cuba': 'CU',
    'cyprus': 'CY',
    'denmark': 'DK',
    'djibouti': 'DJ',
    'dominica': 'DM',
    'dominican republic': 'DO',
    'ecuador': 'EC',
    'el salvador': 'SV',
    'equatorial guinea': 'GQ',
    'eritrea': 'ER',
    'estonia': 'EE',
    'ethiopia': 'ET',
    'fiji': 'FJ',
    'finland': 'FI',
    'gabon': 'GA',
    'gambia': 'GM',
    'georgia': 'GE',
    'germany': 'DE',
    'ghana': 'GH',
    'greece': 'GR',
    'grenada': 'GD',
    'guatemala': 'GT',
    'guinea': 'GN',
    'guinea-bissau': 'GW',
    'guyana': 'GY',
    'haiti': 'HT',
    'honduras': 'HN',
    'hungary': 'HU',
    'iceland': 'IS',
    'iran': 'IR',
    'ireland': 'IE',
    'israel': 'IL',
    'jamaica': 'JM',
    'kazakhstan': 'KZ',
    'kenya': 'KE',
    'kiribati': 'KI',
    'kosovo': 'XK',
    'kuwait': 'KW',
    'kyrgyzstan': 'KG',
    'latvia': 'LV',
    'lebanon': 'LB',
    'lesotho': 'LS',
    'liberia': 'LR',
    'liechtenstein': 'LI',
    'lithuania': 'LT',
    'luxembourg': 'LU',
    'madagascar': 'MG',
    'malawi': 'MW',
    'malaysia': 'MY',
    'maldives': 'MV',
    'mali': 'ML',
    'malta': 'MT',
    'marshall islands': 'MH',
    'mauritania': 'MR',
    'mauritius': 'MU',
    'mexico': 'MX',
    'micronesia': 'FM',
    'moldova': 'MD',
    'monaco': 'MC',
    'mongolia': 'MN',
    'montenegro': 'ME',
    'mozambique': 'MZ',
    'namibia': 'NA',
    'nauru': 'NR',
    'nepal': 'NP',
    'netherlands': 'NL',
    'new zealand': 'NZ',
    'nicaragua': 'NI',
    'niger': 'NE',
    'norway': 'NO',
    'pakistan': 'PK',
    'palau': 'PW',
    'panama': 'PA',
    'papua new guinea': 'PG',
    'paraguay': 'PY',
    'peru': 'PE',
    'poland': 'PL',
    'portugal': 'PT',
    'qatar': 'QA',
    'romania': 'RO',
    'rwanda': 'RW',
    'samoa': 'WS',
    'san marino': 'SM',
    'senegal': 'SN',
    'serbia': 'RS',
    'seychelles': 'SC',
    'sierra leone': 'SL',
    'singapore': 'SG',
    'slovakia': 'SK',
    'slovenia': 'SI',
    'solomon islands': 'SB',
    'somalia': 'SO',
    'south africa': 'ZA',
    'south sudan': 'SS',
    'spain': 'ES',
    'sri lanka': 'LK',
    'sudan': 'SD',
    'suriname': 'SR',
    'sweden': 'SE',
    'switzerland': 'CH',
    'syria': 'SY',
    'tajikistan': 'TJ',
    'tanzania': 'TZ',
    'togo': 'TG',
    'tonga': 'TO',
    'trinidad and tobago': 'TT',
    'tunisia': 'TN',
    'turkmenistan': 'TM',
    'tuvalu': 'TV',
    'uganda': 'UG',
    'uruguay': 'UY',
    'uzbekistan': 'UZ',
    'vanuatu': 'VU',
    'venezuela': 'VE',
    'yemen': 'YE',
    'zambia': 'ZM',
    'zimbabwe': 'ZW',
  };

  /// Convert an ISO 3166-1 alpha-2 code to its flag emoji using regional
  /// indicator symbols ('BR' → 🇧🇷). Kosovo's 'XK' has no official emoji
  /// but the arithmetic still yields a valid pair that most platforms
  /// render as a fallback; acceptable.
  static String _iso2ToEmoji(String iso2) {
    const int regionalIndicatorOffset = 0x1F1E6 - 0x41; // 'A'
    final upper = iso2.toUpperCase();
    return String.fromCharCodes(
      upper.codeUnits.map((c) => c + regionalIndicatorOffset),
    );
  }

  /// Flag emoji for a country display name, or `null` when the name
  /// doesn't resolve — callers decide the fallback (identity badges fall
  /// back to the native-language flag via [userBadgeFlag]).
  ///
  /// Handles: case/whitespace, a trailing parenthetical
  /// ("Myanmar (Burma)" → also tried as "Myanmar"), and raw ISO-2 codes.
  static String? getFlag(String? countryName) {
    if (countryName == null) return null;
    final trimmed = countryName.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();

    final direct = _nameToIso2[lower];
    if (direct != null) return _iso2ToEmoji(direct);

    // "Name (Variant)" → try the part before the parenthetical.
    final parenIndex = lower.indexOf('(');
    if (parenIndex > 0) {
      final base = _nameToIso2[lower.substring(0, parenIndex).trim()];
      if (base != null) return _iso2ToEmoji(base);
    }

    // Already an ISO-2 code? Accept only if it maps to a known country
    // (guards against 2-letter non-codes rendering as bogus flags).
    if (lower.length == 2 && _nameToIso2.containsValue(lower.toUpperCase())) {
      return _iso2ToEmoji(lower);
    }

    return null;
  }

  /// The flag for a user-identity avatar badge: the user's country flag
  /// when known, otherwise their native-language flag, otherwise 🌐.
  ///
  /// Pass `country: null` when the user's privacy settings hide their
  /// country (`showCountryRegion == false`) — the badge then degrades to
  /// the language flag, exactly what was shown before this fix, so no
  /// hidden country is ever leaked.
  static String userBadgeFlag({String? country, String? nativeLanguage}) {
    final countryFlag = getFlag(country);
    if (countryFlag != null) return countryFlag;
    return LanguageFlags.getFlagByName(nativeLanguage ?? '');
  }
}
