import 'package:bananatalk_app/l10n/app_localizations.dart';

/// The host's "run it or call it off?" prompt. Exactly one attendee (the
/// host) gets its own sentence ("Only you are coming so far"): it cannot be
/// a plural branch, because gen-l10n maps `=1` and `one` to the same
/// argument and CLDR `one` also covers 2, 3, 5... in Tagalog and 21, 31...
/// in Russian, which then read "only you".
String gatheringHostDecisionText(AppLocalizations l10n, int going, String goingLabel) =>
    going == 1 ? l10n.gatheringHostDecisionAlone : l10n.gatheringHostDecision(going, goingLabel);
