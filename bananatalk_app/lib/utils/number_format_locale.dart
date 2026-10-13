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

/// [formatCompactNumberForLocaleName] for the locale of [context].
String formatCompactNumberForLocale(BuildContext context, num n) =>
    formatCompactNumberForLocaleName(Localizations.localeOf(context).toString(), n);
