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
