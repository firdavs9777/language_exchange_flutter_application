import 'package:bananatalk_app/utils/language_codes.dart';
import 'package:bananatalk_app/utils/language_flags.dart';

/// The language a moment is filed under when its author never touched the
/// composer's language dropdown. Same rules as the backend
/// (lib/captionLanguage.js): the caption's script when it names the language,
/// else the author's native language, else English. The dropdown used to
/// default to English, so 152 of 157 posts were `en`.
class CaptionLanguage {
  static final Map<String, RegExp> _scripts = {
    'ko': RegExp(r'[가-힯ᄀ-ᇿ㄰-㆏]'),
    'kana': RegExp(r'[぀-ヿ]'),
    'han': RegExp(r'[一-鿿]'),
    'ru': RegExp(r'[Ѐ-ӿ]'),
    'ar': RegExp(r'[؀-ۿ]'),
    'he': RegExp(r'[֐-׿]'),
    'th': RegExp(r'[฀-๿]'),
    'hi': RegExp(r'[ऀ-ॿ]'),
    'el': RegExp(r'[Ͱ-Ͽ]'),
    'ka': RegExp(r'[Ⴀ-ჿ]'),
    'hy': RegExp(r'[԰-֏]'),
  };
  static final RegExp _latin = RegExp(r'[A-Za-zÀ-ɏ]');

  /// An ISO 639-1 code when one script has the most letters and at least as
  /// many as Latin; null otherwise (Latin, emoji, empty).
  static String? fromScript(String text) {
    if (text.trim().isEmpty) return null;
    final counts = {
      for (final e in _scripts.entries) e.key: e.value.allMatches(text).length,
    };
    final kana = counts.remove('kana')!;
    final han = counts.remove('han')!;
    // Japanese is Han plus kana; Han with no kana is Chinese.
    if (kana > 0) {
      counts['ja'] = kana + han;
    } else {
      counts['zh'] = han;
    }
    final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    final latin = _latin.allMatches(text).length;
    return best.value > 0 && best.value >= latin ? best.key : null;
  }

  static String defaultFor(String caption, String? nativeLanguage) {
    final byScript = fromScript(caption);
    if (byScript != null) return byScript;
    final native = nativeLanguage == null
        ? null
        : LanguageFlags.codeForName(nativeLanguage);
    return (native == null ? null : LanguageCodes.toBaseIso6391(native)) ?? 'en';
  }
}
