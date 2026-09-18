import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/utils/language_flags.dart';

/// Pure code/name shaping for the shared language catalog
/// (`GET /languages`, 127+ entries — see providers/languages_provider.dart).
///
/// The backend Moment validator only accepts ISO 639-1 codes, so surfaces
/// that write `Moment.language` (composer tag, feed filter) — and, for
/// consistency, the code-keyed learning surfaces (vocabulary, lesson
/// builder) — map catalog codes down to their base 639-1 code here.
/// The backend groups variants the same way (utils/languageCodes.js), so a
/// "Portuguese (Brazil)" moment is tagged/filtered as 'pt'.
class LanguageCodes {
  /// Catalog codes with no usable ISO 639-1 base. Deliberately excluded
  /// from code-keyed surfaces (documented decisions):
  /// - Sign languages (ase/bfi/jsl/kvk): no 639-1 code, and a written
  ///   moment/vocab entry "in ASL" isn't representable — skipped.
  /// - Hawaiian (haw): ISO 639-2 only — the backend validator would
  ///   reject it — skipped until the validator learns 639-2.
  static const Set<String> _untaggable = {'ase', 'bfi', 'jsl', 'kvk', 'haw'};

  /// 639-3/legacy codes that DO have a sensible 639-1 base.
  /// - fil (Filipino) → tl: Filipino is standardized Tagalog; the backend
  ///   already groups them ('filipino' → 'tl').
  /// - prs (Dari) → fa: Dari is a variety of Persian; nearest 639-1 code.
  static const Map<String, String> _threeLetterBases = {
    'fil': 'tl',
    'prs': 'fa',
  };

  /// Base ISO 639-1 code for a catalog code, or null when the language
  /// can't be represented in 639-1 (caller skips it).
  ///
  /// 'pt-BR' → 'pt', 'zh-HK' → 'zh', 'en' → 'en', 'fil' → 'tl',
  /// 'prs' → 'fa', 'ase'/'haw' → null, unknown 3+ letter codes → null.
  static String? toBaseIso6391(String code) {
    final trimmed = code.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    if (_untaggable.contains(trimmed)) return null;

    final mapped = _threeLetterBases[trimmed];
    if (mapped != null) return mapped;

    final hyphen = trimmed.indexOf('-');
    final base = hyphen > 0 ? trimmed.substring(0, hyphen) : trimmed;
    return base.length == 2 ? base : null;
  }

  /// Two-letter display code for a language NAME, uppercased: 'Korean' ->
  /// 'KO', 'Chinese (Traditional)' -> 'ZH', 'en' -> 'EN'.
  ///
  /// ISO-style (KO, ZH), not country-style (KR, CN) -- this is the convention
  /// the app has always shown, and a pill that disagreed with the rest of the
  /// app would be worse than one that disagreed with a competitor.
  ///
  /// Lives here rather than in a widget because two screens rendered their own
  /// copy of this mapping and they had already drifted.
  static String displayCode(String language) {
    final lower = stripVariant(language).toLowerCase().trim();
    if (lower.isEmpty) return '';
    const byName = {
      'japanese': 'JP', 'english': 'EN', 'korean': 'KO', 'chinese': 'ZH',
      'spanish': 'ES', 'french': 'FR', 'german': 'DE', 'italian': 'IT',
      'portuguese': 'PT', 'russian': 'RU', 'arabic': 'AR', 'hindi': 'HI',
      'tajik': 'TG', 'vietnamese': 'VI', 'thai': 'TH', 'indonesian': 'ID',
      'turkish': 'TR', 'filipino': 'TL', 'cantonese': 'YUE',
    };
    for (final entry in byName.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // A bare ISO code ('en', 'ko') or anything unrecognised: show the first
    // two letters rather than nothing.
    final iso = toBaseIso6391(lower);
    if (iso != null) return iso.toUpperCase();
    return language.toUpperCase().substring(0, language.length > 2 ? 2 : language.length);
  }

  /// Strip a trailing regional parenthetical from a display name:
  /// "Portuguese (Brazil)" → "Portuguese", "Chinese (Traditional)" →
  /// "Chinese". Names without one pass through ("Haitian Creole").
  static String stripVariant(String name) {
    return name.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  }

  /// Build the code-keyed picker list from the full catalog:
  /// - each entry's code mapped to its base 639-1 code (nulls skipped),
  /// - deduped by base code (first catalog occurrence wins — catalog
  ///   order puts canonical entries first), so variants collapse:
  ///   English / English (US) / English (UK) → one "English" ('en'),
  ///   and Dari collapses into the earlier Persian ('fa'),
  /// - display name stripped of the regional parenthetical,
  /// - flag resolved per base code (the app-wide language-flag map).
  ///
  /// Returns `{'code','name','flag'}` maps — the exact shape
  /// FilterOptions.languages consumers already use.
  static List<Map<String, String>> buildTaggableLanguages(
    List<Language> catalog,
  ) {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final language in catalog) {
      final base = toBaseIso6391(language.code);
      if (base == null || !seen.add(base)) continue;
      result.add({
        'code': base,
        'name': stripVariant(language.name),
        'flag': LanguageFlags.getFlag(base),
      });
    }
    return result;
  }
}

/// Session-wide sync view of the loaded catalog, populated by
/// languagesProvider (providers/languages_provider.dart) on every
/// successful load (network or persisted cache). Lets synchronous,
/// non-Riverpod call sites — FilterOptions.languages, the moment-card
/// language label — resolve against the full catalog without becoming
/// async; they fall back to their static lists until the first load.
class LanguageCatalog {
  static List<Map<String, String>>? _taggable;

  static void update(List<Language> catalog) {
    _taggable = LanguageCodes.buildTaggableLanguages(catalog);
  }

  /// Taggable (base-639-1, deduped) list, or null before the first load.
  static List<Map<String, String>>? get taggable => _taggable;

  /// Test hook.
  static void reset() => _taggable = null;
}
