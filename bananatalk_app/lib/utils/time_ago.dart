import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

bool _registered = false;

void _ensureRegistered() {
  if (_registered) return;
  _registered = true;
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('hi', timeago.HiMessages());
  timeago.setLocaleMessages('id', timeago.IdMessages());
  timeago.setLocaleMessages('it', timeago.ItMessages());
  timeago.setLocaleMessages('ja', timeago.JaMessages());
  timeago.setLocaleMessages('ko', timeago.KoMessages());
  timeago.setLocaleMessages('pt_br', timeago.PtBrMessages());
  timeago.setLocaleMessages('ru', timeago.RuMessages());
  timeago.setLocaleMessages('th', timeago.ThMessages());
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setLocaleMessages('vi', timeago.ViMessages());
  timeago.setLocaleMessages('zh_cn', timeago.ZhCnMessages()); // Simplified
  timeago.setLocaleMessages('zh', timeago.ZhMessages()); // Traditional
}

/// The timeago locale key for an app [locale]. Locales timeago has no
/// messages for (Tagalog `tl`, Tajik `tg`) map to `en`.
String timeAgoLocaleKey(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      final traditional = locale.scriptCode == 'Hant' || locale.countryCode == 'TW';
      return traditional ? 'zh' : 'zh_cn';
    case 'pt':
      return 'pt_br';
    case 'ar':
    case 'de':
    case 'es':
    case 'fr':
    case 'hi':
    case 'id':
    case 'it':
    case 'ja':
    case 'ko':
    case 'ru':
    case 'th':
    case 'tr':
    case 'vi':
      return locale.languageCode;
    default:
      return 'en';
  }
}

/// Relative time ("5 minutes ago") in [locale]. With [short], English and
/// Spanish use timeago's compact style ("5m"); other locales have no compact
/// style and use the regular localized phrase.
String formatTimeAgo(Locale locale, DateTime date, {bool short = false, DateTime? now}) {
  _ensureRegistered();
  var key = timeAgoLocaleKey(locale);
  if (short && (key == 'en' || key == 'es')) key = '${key}_short';
  return timeago.format(date, locale: key, clock: now);
}

/// [formatTimeAgo] for the locale of [context].
String timeAgoFor(BuildContext context, DateTime date, {bool short = false}) =>
    formatTimeAgo(Localizations.localeOf(context), date, short: short);
