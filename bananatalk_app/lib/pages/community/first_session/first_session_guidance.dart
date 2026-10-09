/// How many app launches the first-session panel may appear on.
///
/// Kept in step with `kMaxGuideViews` on the four generic page guides: a user
/// who sees Matches nag one launch longer than every other tab reads it as a
/// bug in Matches.
const int kMaxGuidanceViews = 2;

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
