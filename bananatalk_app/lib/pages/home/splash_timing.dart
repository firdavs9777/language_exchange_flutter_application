/// How long the splash should still wait before navigating.
///
/// The splash used `await Future.delayed(Duration(seconds: 2))` placed AFTER
/// notification set-up, auth restore and a version check. That is not a
/// minimum splash duration — it is two seconds added to whatever those already
/// cost, every single launch, and on a cold first launch they cost the most.
///
/// A floor is what was actually wanted: show the branding long enough that it
/// does not flash, and if the real work already took that long, wait no
/// further.
library;

/// Long enough for the entrance animation (1400ms) to land.
///
/// Matched to the animation rather than picked: a splash cut off mid-fade
/// looks broken, and anything beyond it is the user waiting for nothing.
const Duration kMinimumSplash = Duration(milliseconds: 1400);

/// What remains of [minimum] after [elapsed], never negative.
///
/// Returning zero rather than a negative duration matters: `Future.delayed`
/// with a negative value still yields to the event loop, but the intent here
/// is "do not wait at all", and a caller can skip the await entirely.
Duration remainingSplash(Duration elapsed, {Duration minimum = kMinimumSplash}) {
  final left = minimum - elapsed;
  return left.isNegative ? Duration.zero : left;
}
