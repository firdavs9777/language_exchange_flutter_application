/// Pure policy for the "one interstitial per session" rule (Growth C6).
///
/// Gated on the server's `rewardedLimitsEnabled` flag: with it off no
/// interstitial is ever requested from the new call sites. Mirrors
/// `shouldShowFullScreenAd` — an unknown ad-free status is "not allowed", so a
/// VIP is never shown an ad.
/// Whether a legacy `maybeShowInterstitial(everyN: …)` site may show. With
/// the session cap on (`rewardedLimitsEnabled`), every interstitial shares
/// the once-per-session budget; with it off the old behaviour is untouched.
bool everyNInterstitialAllowed({
  required bool sessionCapOn,
  required bool alreadyShownThisSession,
}) =>
    !(sessionCapOn && alreadyShownThisSession);

bool shouldShowInterstitial({
  required bool flagOn,
  required bool adFreeKnown,
  required bool isAdFree,
  required bool alreadyShownThisSession,
  required bool loaded,
}) =>
    flagOn && adFreeKnown && !isAdFree && !alreadyShownThisSession && loaded;
