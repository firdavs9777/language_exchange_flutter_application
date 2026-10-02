/// Pure policy for the "one interstitial per session" rule (Growth C6).
///
/// Gated on the server's `rewardedLimitsEnabled` flag: with it off no
/// interstitial is ever requested from the new call sites. Mirrors
/// `shouldShowFullScreenAd` — an unknown ad-free status is "not allowed", so a
/// VIP is never shown an ad.
bool shouldShowInterstitial({
  required bool flagOn,
  required bool adFreeKnown,
  required bool isAdFree,
  required bool alreadyShownThisSession,
  required bool loaded,
}) =>
    flagOn && adFreeKnown && !isAdFree && !alreadyShownThisSession && loaded;
