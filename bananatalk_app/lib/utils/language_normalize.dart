import 'package:bananatalk_app/utils/language_codes.dart';

/// Client mirror of the backend's `utils/languageNormalize.js`.
///
/// Normalizes a language value written to `User.language_to_learn` /
/// `User.native_language` — a display name (e.g. "English", "Korean",
/// "Chinese (Simplified)") or a catalog code (e.g. "en", "zh-CN", "fil")
/// — to a base language code, for surfaces that group those values (e.g.
/// daily-content selection).
///
/// This is a THIN composition over [LanguageCodes], not a re-derivation
/// of it, plus exactly ONE addition on top:
///
/// 1. Chinese script detection on the ORIGINAL input — the one new
///    thing. Simplified and Traditional are different written content
///    with separate learner populations, so — unlike every other
///    language — they are NOT collapsed to one base code. A bare
///    "Chinese" or "zh" stays plain 'zh': script is never guessed.
/// 2. Code-shaped input (e.g. 'en', 'ko', 'pt-BR', 'fil', 'prs') is
///    resolved by [LanguageCodes.toBaseIso6391], which already handles
///    every code in the shared ~127-language catalog generically
///    (hyphen-suffix stripping + the two documented 639-3 exceptions) —
///    not a hand-picked subset.
/// 3. Name-shaped input (e.g. 'Korean', 'English (US)') is resolved by
///    stripping the regional parenthetical
///    ([LanguageCodes.stripVariant]) and matching the result against
///    [LanguageCatalog.taggable] — the live, session-wide cache of the
///    SAME full catalog `GET /languages` returns, built via
///    [LanguageCodes.buildTaggableLanguages].
///
/// CAVEAT (flagged rather than papered over): the backend's
/// `languageCodes.js` holds a static, always-complete display-name map
/// (`NAME_TO_ISO`), so it can resolve names with zero runtime state.
/// There is no Dart equivalent of that static name map — the app's only
/// complete name catalog is the one fetched over the network. So
/// name-shaped input here resolves correctly once [LanguageCatalog] has
/// been populated at least once this session (normally by
/// `languagesProvider`'s startup fetch — see
/// `lib/providers/languages_provider.dart`), and returns null — never a
/// guess — if called before that. Code-shaped input is unaffected by
/// catalog load state and always resolves correctly.
///
/// Returns null for null/empty/whitespace-only/unrecognized input.
String? toBaseLanguage(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();

  // Chinese script detection from the ORIGINAL input. Same patterns,
  // same order, as the backend's languageNormalize.js.
  const simplifiedPatterns = {'chinese (simplified)', 'zh-hans', 'zh-cn'};
  const traditionalPatterns = {'chinese (traditional)', 'zh-hant', 'zh-tw'};
  if (simplifiedPatterns.contains(lower)) return 'zh-Hans';
  if (traditionalPatterns.contains(lower)) return 'zh-Hant';

  // Code-shaped input: delegate to the generic, full-catalog resolver.
  final asCode = LanguageCodes.toBaseIso6391(trimmed);
  if (asCode != null) return asCode;

  // Name-shaped input: strip the regional parenthetical and match
  // against the live catalog, if it has loaded this session.
  final taggable = LanguageCatalog.taggable;
  if (taggable == null) return null;

  final strippedLower =
      LanguageCodes.stripVariant(trimmed).trim().toLowerCase();
  if (strippedLower.isEmpty) return null;

  for (final entry in taggable) {
    if (entry['name']?.toLowerCase() == strippedLower) {
      return entry['code'];
    }
  }
  return null;
}
