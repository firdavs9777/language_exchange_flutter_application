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
//   REACT_APP_ADS_DEV=true                enable ads outside production builds
//   REACT_APP_ADS_TEST=true               force data-adtest="on" in production

// Publisher id, e.g. "ca-pub-XXXXXXXXXXXXXXXX".
export const ADSENSE_CLIENT = process.env.REACT_APP_ADSENSE_CLIENT || "";

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
  !!ADSENSE_CLIENT &&
  (process.env.NODE_ENV === "production" ||
    process.env.REACT_APP_ADS_DEV === "true");

// Test mode adds data-adtest="on" so impressions in dev/staging don't count as
// invalid traffic (which can trigger AdSense policy strikes).
export const adsTestMode = (): boolean =>
  process.env.NODE_ENV !== "production" ||
  process.env.REACT_APP_ADS_TEST === "true";
