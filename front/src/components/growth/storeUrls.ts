// The only place in src/ where the store hostnames are written down --
// src/components/growth/storeUrls.test.ts greps for a second copy. Everything
// else (StoreLink, utils/platform.ts, openInAppAction, growthGate, the SEO
// JSON-LD) imports from here. Zero imports on purpose: growthGate.ts and
// platform.ts are consumed by non-React code and must stay React-free.
export const APP_STORE_URL =
  "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bananatalk.app";

/** Hostnames of the two stores, derived rather than retyped (growthGate). */
export const STORE_HOSTS: string[] = [APP_STORE_URL, PLAY_STORE_URL].map(
  (url) => url.split("/")[2]
);
