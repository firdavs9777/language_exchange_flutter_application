import 'package:bananatalk_app/services/guide_store.dart';

/// Whether the Matches first-session panel should be shown.
///
/// Delegates to [shouldShowGuide] so Matches and the four generic page guides
/// cannot disagree about who is a first-timer — a user who saw Matches nag a
/// day longer than every other tab would read it as a bug in Matches.
///
/// Kept as its own name because the Matches panel reports a different set of
/// events (the registration funnel) and reads a different stored flag ("has
/// ever sent a message" rather than "tapped the card").
///
/// Pure so it can be tested without driving the widget, and so the rule
/// cannot drift from the UI that reads it — the registration photo step and
/// its submit gate drifted exactly that way and locked OAuth users out of
/// signup entirely.
bool shouldShowFirstSessionGuidance({
  required bool withinWindow,
  required bool hasMessaged,
}) =>
    shouldShowGuide(withinWindow: withinWindow, acted: hasMessaged);
