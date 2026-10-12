import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// [build] for [locale], or for English when intl has no date symbols for it
/// (Tajik `tg`) or they are not initialised: never throws.
String _formatSafely(
    String locale, DateFormat Function(String locale) build, DateTime dt) {
  try {
    final name = DateFormat.localeExists(locale) ? locale : 'en';
    return build(name).format(dt);
  } catch (_) {
    return build('en').format(dt);
  }
}

String _localeOf(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// Date and time for [locale] (e.g. "10/12/2026 3:05 PM"). Locales intl has no
/// date symbols for (Tajik `tg`) fall back to English instead of throwing.
String formatDateTimeForLocaleName(String locale, DateTime dt) =>
    _formatSafely(locale, (l) => DateFormat.yMd(l).add_jm(), dt);

/// [formatDateTimeForLocaleName] for the locale of [context].
String formatDateTimeForLocale(BuildContext context, DateTime dt) =>
    formatDateTimeForLocaleName(_localeOf(context), dt);

/// Medium date (e.g. "Oct 12, 2026") for [context]'s locale, with the same
/// English fallback as [formatDateTimeForLocaleName] for locales intl lacks.
String formatDateForLocale(BuildContext context, DateTime dt) =>
    _formatSafely(_localeOf(context), (l) => DateFormat.yMMMd(l), dt);

/// Numeric date (e.g. "10/12/2026") for [context]'s locale; English fallback.
String formatNumericDateForLocale(BuildContext context, DateTime dt) =>
    _formatSafely(_localeOf(context), (l) => DateFormat.yMd(l), dt);

/// Month and day (e.g. "Oct 12") for [locale]; English fallback.
String formatMonthDayForLocaleName(String locale, DateTime dt) =>
    _formatSafely(locale, (l) => DateFormat.MMMd(l), dt);

/// [formatMonthDayForLocaleName] for the locale of [context].
String formatMonthDayForLocale(BuildContext context, DateTime dt) =>
    formatMonthDayForLocaleName(_localeOf(context), dt);
