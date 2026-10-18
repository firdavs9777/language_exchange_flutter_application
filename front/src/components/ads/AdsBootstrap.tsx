// Site-wide AdSense bootstrap, mounted once in App. Renders nothing.
//
// Two jobs, both in an effect so the prerendered pages hydrate untouched:
// - Auto ads: when enabled, put the AdSense script on every page (AdUnit only
//   loads it where a manual slot mounts), unless the user is VIP.
// - Consent: mirror the site's consent decision onto the AdSense queue now and
//   whenever it changes.
import { useEffect } from "react";
import { readConsent, subscribeConsent } from "../../analytics/consent";
import { adsEnabled, autoAdsEnabled } from "./adsenseConfig";
import { applyAdConsent } from "./adsGate";
import { loadAdSense } from "./loadAdSense";
import { useAdsAllowed } from "./useAdsAllowed";

const AdsBootstrap = (): null => {
  const allowed = useAdsAllowed();
  const configured = adsEnabled();

  useEffect(() => {
    if (!configured) return;
    applyAdConsent(readConsent());
    return subscribeConsent((value) => applyAdConsent(value));
  }, [configured]);

  useEffect(() => {
    if (!configured || !autoAdsEnabled() || !allowed) return;
    loadAdSense();
  }, [configured, allowed]);

  return null;
};

export default AdsBootstrap;
