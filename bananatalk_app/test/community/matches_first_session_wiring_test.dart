import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';

/// Review Focus 4: `timesShown` must advance once per SESSION, not once per
/// rebuild. A ListView header rebuilds on every scroll frame, so an unguarded
/// increment would burn the three-view cap in seconds and the panel would
/// never be seen again.
///
/// This pins the guard's shape — the same one-shot latch `_MatchesTabState`
/// uses via `_guidanceRecordedThisSession`.
void main() {
  test('the cap survives a rebuild-heavy session', () {
    var recorded = 0;
    var alreadyRecordedThisSession = false;

    void onPanelBuilt() {
      if (alreadyRecordedThisSession) return;
      alreadyRecordedThisSession = true;
      recorded++;
    }

    for (var frame = 0; frame < 50; frame++) {
      if (shouldShowFirstSessionGuidance(
          isNewUser: true, hasMessaged: false, timesShown: recorded)) {
        onPanelBuilt();
      }
    }

    expect(recorded, 1, reason: 'one session must cost one view, not fifty');
  });

  test('without the latch, fifty frames would burn the whole cap', () {
    // The counterfactual: this is what the guard prevents.
    var recorded = 0;
    for (var frame = 0; frame < 50; frame++) {
      if (shouldShowFirstSessionGuidance(
          isNewUser: true, hasMessaged: false, timesShown: recorded)) {
        recorded++;
      }
    }

    expect(recorded, kMaxGuidanceViews,
        reason: 'an unguarded increment exhausts the cap immediately');
  });
}
