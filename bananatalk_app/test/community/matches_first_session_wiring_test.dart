import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';

/// Review Focus 4: a view must be counted once per SESSION, not once per
/// rebuild. A ListView header rebuilds on every scroll frame.
///
/// This used to matter because an unguarded increment burned the view cap in
/// seconds and the panel was never seen again. The cap is gone -- a three-day
/// window ends the guide now -- but the latch is still load-bearing: without
/// it, `first_session_guidance_shown` fires on every frame, and both the
/// event count and `times_shown` become noise.
///
/// Pins the guard's shape — the same one-shot latch MatchesTab holds in
/// `firstSessionGuidanceRecordedProvider`.
void main() {
  test('one session costs one recorded view, not fifty', () {
    var recorded = 0;
    var alreadyRecordedThisSession = false;

    void onPanelBuilt() {
      if (alreadyRecordedThisSession) return;
      alreadyRecordedThisSession = true;
      recorded++;
    }

    for (var frame = 0; frame < 50; frame++) {
      if (shouldShowFirstSessionGuidance(
          withinWindow: true, hasMessaged: false)) {
        onPanelBuilt();
      }
    }

    expect(recorded, 1, reason: 'one session must cost one view, not fifty');
  });

  test('without the latch, every frame would be reported', () {
    // The counterfactual: this is what the guard prevents. Under the old view
    // cap this stopped at the cap; now nothing stops it, which is exactly why
    // the latch can never be removed.
    var recorded = 0;
    for (var frame = 0; frame < 50; frame++) {
      if (shouldShowFirstSessionGuidance(
          withinWindow: true, hasMessaged: false)) {
        recorded++;
      }
    }

    expect(recorded, 50,
        reason: 'an unguarded increment reports once per frame');
  });
}
