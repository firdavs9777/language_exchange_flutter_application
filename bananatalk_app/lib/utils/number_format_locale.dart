import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Compact number (e.g. "1.2K") for [locale], or for English when intl has
/// no number symbols for it (Tajik `tg`, where `NumberFormat.compact` throws
/// "Invalid locale"): never throws. The number counterpart of
/// `lib/utils/date_format_locale.dart`.
String formatCompactNumberForLocaleName(String locale, num n) {
  try {
    final name = NumberFormat.localeExists(locale) ? locale : 'en';
    return NumberFormat.compact(locale: name).format(n);
  } catch (_) {
    return NumberFormat.compact(locale: 'en').format(n);
  }
}

/// The count to pick a plural form with when the shown number is a compact
/// label: [n] rounded to the 3 significant digits the label keeps (1001 →
/// 1000, 1249 → 1250). Without it ru would read "1 тыс. участник" (1001 is
/// CLDR `one`); every rounded value ends in 0, so it gets the genitive
/// plural that an abbreviation like "тыс." takes. Below 1000 it is [n].
int compactPluralCount(int n) {
  if (n < 1000) return n;
  var scale = 1;
  while (n ~/ scale >= 1000) {
    scale *= 10;
  }
  return (n / scale).round() * scale;
}

/// [formatCompactNumberForLocaleName] for the locale of [context].
String formatCompactNumberForLocale(BuildContext context, num n) =>
    formatCompactNumberForLocaleName(Localizations.localeOf(context).toString(), n);
