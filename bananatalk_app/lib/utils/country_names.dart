import 'package:flutter/widgets.dart';
import 'package:bananatalk_app/utils/country_flags.dart';
import 'package:bananatalk_app/utils/country_names.g.dart';

/// Localized country names for DISPLAY only.
///
/// Countries are stored and sent to the backend as English names
/// (`user.location.country`, the community `country` filter) or ISO codes.
/// Those values never change here — only the label a user reads does.
/// The table is generated from CLDR by `tool/build_country_names.js`.
class CountryNames {
  CountryNames._();

  /// Table key for [locale]: the ARB locale key (`ko`, `zh_TW`, ...), or
  /// `null` for English / an unsupported locale.
  static String? _tableKey(Locale locale) {
    final lang = locale.languageCode;
    if (lang == 'zh') {
      final traditional =
          locale.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
      return traditional ? 'zh_TW' : 'zh';
    }
    final key = lang == 'fil' ? 'tl' : lang;
    return kCountryNamesByLocale.containsKey(key) ? key : null;
  }

  /// Localized name for an ISO 3166-1 alpha-2 [code] in [locale], or `null`
  /// when the locale is English or the code is unknown.
  static String? forCode(String? code, Locale locale) {
    if (code == null) return null;
    final key = _tableKey(locale);
    if (key == null) return null;
    return kCountryNamesByLocale[key]![code.toUpperCase()];
  }

  /// The label to show for a stored country value (English name or ISO
  /// code) in [locale]. Falls back to the stored value when it can't be
  /// resolved or the locale is English.
  static String display(String stored, Locale locale) {
    return forCode(CountryFlags.isoCode(stored), locale) ?? stored;
  }

  /// [display] in the app's current locale.
  static String of(BuildContext context, String stored) {
    return display(stored, Localizations.localeOf(context));
  }
}
