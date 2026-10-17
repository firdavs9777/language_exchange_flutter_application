import 'package:flutter/widgets.dart';

import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/language_names.g.dart';

/// Language names in the app's language.
///
/// Users' languages are stored as English names ("Korean"), so a non-English
/// UI showed them in English ("Speaks Korean" in an Arabic sentence). The
/// names come from CLDR (lib/utils/language_names.g.dart, regenerated with
/// `node tool/build_language_names.js`), like CountryNames.
class LanguageNames {
  LanguageNames._();

  static String? _tableKey(Locale locale) {
    final lang = locale.languageCode;
    if (lang == 'en') return null;
    if (lang == 'zh') {
      final traditional = locale.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
      return traditional ? 'zh_TW' : 'zh';
    }
    return kLanguageNamesByLocale.containsKey(lang) ? lang : null;
  }

  /// [stored] in [locale]; the stored value itself (title-cased) when the
  /// UI is English or the language is unknown.
  static String display(String stored, Locale locale) {
    if (stored.trim().isEmpty) return stored;
    final key = _tableKey(locale);
    final code = LanguageFlags.codeForName(stored);
    final localized =
        (key == null || code == null) ? null : kLanguageNamesByLocale[key]?[code];
    return localized ?? LanguageFlags.displayName(stored);
  }

  /// [display] in the app's current locale.
  static String of(BuildContext context, String stored) =>
      display(stored, Localizations.localeOf(context));
}
