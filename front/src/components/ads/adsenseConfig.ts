// Google AdSense configuration — all values come from environment variables so
// the app is a complete no-op until a publisher id is provided.
//
// Required env (see src/components/ads/README.md):
//   REACT_APP_ADSENSE_CLIENT              e.g. ca-pub-XXXXXXXXXXXXXXXX
//   REACT_APP_ADSENSE_SLOT_MOMENT_DETAIL  numeric slot id
//   REACT_APP_ADSENSE_SLOT_FEED           numeric slot id
//   REACT_APP_ADSENSE_SLOT_COMMENTS       numeric slot id
//   REACT_APP_ADSENSE_SLOT_HOME           numeric slot id
//   REACT_APP_ADSENSE_SLOT_COMMUNITY      numeric slot id
//   REACT_APP_ADSENSE_SLOT_PROFILE        numeric slot id
//   REACT_APP_ADSENSE_AUTO_ADS=true       load the script on every page so the
//                                         Auto ads configured in the AdSense
//                                         console can place ads site-wide
//   REACT_APP_ADS_DEV=true                enable ads outside production builds
//   REACT_APP_ADS_TEST=true               force data-adtest="on" in production

// Publisher id, e.g. "ca-pub-XXXXXXXXXXXXXXXX".
//
// Read through a function rather than a module-level constant. Webpack still
// inlines `process.env.REACT_APP_*` at build time wherever it appears, so the
// production result is identical, but the modules that depend on it stay
// testable without rebuilding the whole module graph per case.
export const adsenseClient = (): string =>
  process.env.REACT_APP_ADSENSE_CLIENT || "";

// Auto ads: AdSense places ads itself once the script is on the page. Which
// pages get them is configured in the console (page exclusions), not here.
export const autoAdsEnabled = (): boolean =>
  process.env.REACT_APP_ADSENSE_AUTO_ADS === "true";

// Ad unit slot ids (numeric strings from the AdSense console).
export const AD_SLOTS = {
  momentDetail: process.env.REACT_APP_ADSENSE_SLOT_MOMENT_DETAIL || "",
  feed: process.env.REACT_APP_ADSENSE_SLOT_FEED || "",
  comments: process.env.REACT_APP_ADSENSE_SLOT_COMMENTS || "",
  home: process.env.REACT_APP_ADSENSE_SLOT_HOME || "",
  community: process.env.REACT_APP_ADSENSE_SLOT_COMMUNITY || "",
  profile: process.env.REACT_APP_ADSENSE_SLOT_PROFILE || "",
};

// Ads only render when a client id is configured AND we're either in a
// production build or dev has explicitly opted in.
export const adsEnabled = (): boolean =>
  !!adsenseClient() &&
  (process.env.NODE_ENV === "production" ||
    process.env.REACT_APP_ADS_DEV === "true");

// Test mode adds data-adtest="on" so impressions in dev/staging don't count as
// invalid traffic (which can trigger AdSense policy strikes).
export const adsTestMode = (): boolean =>
  process.env.NODE_ENV !== "production" ||
  process.env.REACT_APP_ADS_TEST === "true";
