/// What the story row should display after a load attempt settles.
///
/// This lived inline in [StoriesFeedWidget] as three scattered assignments to
/// `_error`, and they disagreed with each other: a *successful* load never
/// cleared the field, so once the banner appeared it stayed up for the life of
/// the screen no matter how many times Retry actually refetched the feed.
///
/// Returns the message to show, or null to show the feed.
String? storiesFeedError({
  required bool succeeded,
  required String? error,
  required bool hasCachedStories,
}) {
  // A load that worked always clears the banner. This is the rule whose
  // absence made Retry look dead: the network call succeeded, the stories
  // arrived, and the error row kept rendering on top of them.
  if (succeeded) return null;

  // A failed *refresh* is not worth destroying content the user is already
  // looking at. Losing a visible row of stories to a momentary blip is a
  // worse outcome than silently serving the copy we have.
  if (hasCachedStories) return null;

  return error?.trim().isNotEmpty == true ? error : 'unknown';
}

/// Whether to show the shimmer placeholders for this attempt.
///
/// Keyed on "is there anything on screen", not "is this the first load" — the
/// old `!hasLoadedOnce` test meant an explicit Retry after a failed refresh
/// produced no visible change whatsoever, so the button read as broken even in
/// the cases where it worked.
bool storiesFeedShowsShimmer({
  required bool explicitLoad,
  required bool hasCachedStories,
}) {
  return explicitLoad && !hasCachedStories;
}
