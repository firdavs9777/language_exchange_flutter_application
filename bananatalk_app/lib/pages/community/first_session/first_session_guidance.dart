/// How many times the first-session panel may be shown before it stops.
///
/// Without a cap, someone who never messages sees the same banner every
/// session for the six days `Community.isNewUser` covers, which is nagging
/// rather than guidance.
const int kMaxGuidanceViews = 3;

/// Whether the Matches first-session panel should be shown.
///
/// Pure so it can be tested without driving the widget, and so the rule
/// cannot drift from the UI that reads it — the registration photo step and
/// its submit gate drifted exactly that way and locked OAuth users out of
/// signup entirely.
bool shouldShowFirstSessionGuidance({
  required bool isNewUser,
  required bool hasMessaged,
  required int timesShown,
}) =>
    isNewUser && !hasMessaged && timesShown < kMaxGuidanceViews;
