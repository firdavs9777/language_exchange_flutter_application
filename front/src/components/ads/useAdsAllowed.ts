import { useSelector } from "react-redux";
import { shouldShowAds } from "./adsGate";

/**
 * True unless the signed-in user is VIP. Logged out counts as allowed.
 *
 * `userInfo` normally wraps the user document (`{ user, token }`), but a few
 * older call sites read the fields straight off `userInfo`, so both shapes are
 * accepted here rather than silently showing ads to a VIP.
 */
export function useAdsAllowed(): boolean {
  return useSelector((state: any) => {
    const info = state?.auth?.userInfo;
    return shouldShowAds(info?.user || info || null);
  });
}
