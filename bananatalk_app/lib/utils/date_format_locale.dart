import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Date and time for [locale] (e.g. "10/12/2026 3:05 PM"). Locales intl has no
/// date symbols for (Tajik `tg`) fall back to English instead of throwing.
String formatDateTimeForLocaleName(String locale, DateTime dt) {
  try {
    final name = DateFormat.localeExists(locale) ? locale : 'en';
    return DateFormat.yMd(name).add_jm().format(dt);
  } catch (_) {
    // Date symbols not initialised for this locale.
    return DateFormat.yMd('en').add_jm().format(dt);
  }
}

/// [formatDateTimeForLocaleName] for the locale of [context].
String formatDateTimeForLocale(BuildContext context, DateTime dt) =>
    formatDateTimeForLocaleName(Localizations.localeOf(context).toString(), dt);

/// Medium date (e.g. "Oct 12, 2026") for [context]'s locale, with the same
/// English fallback as [formatDateTimeForLocaleName] for locales intl lacks.
String formatDateForLocale(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  try {
    final name = DateFormat.localeExists(locale) ? locale : 'en';
    return DateFormat.yMMMd(name).format(dt);
  } catch (_) {
    return DateFormat.yMMMd('en').format(dt);
  }
}
