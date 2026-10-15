import 'package:bananatalk_app/l10n/app_localizations.dart';

/// What to tell the user when an inline translate returned no text, or null
/// when there is nothing to say: it worked, or they just declined the coin
/// unlock sheet (which already explained the cap).
String? inlineTranslateErrorText(
  AppLocalizations l10n, {
  required bool hasTranslation,
  required bool limitReached,
  bool unlockDeclined = false,
}) {
  if (hasTranslation) return null;
  if (limitReached) {
    return unlockDeclined ? null : l10n.chatTranslationLimitReached;
  }
  return l10n.translationFailed;
}
