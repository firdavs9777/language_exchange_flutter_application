// Idempotent loader for the Google AdSense script. The tag is injected at most
// once, only when ads are enabled and a publisher id is configured. AdUnit
// calls this on mount; hardcoding the script in index.html is intentionally
// avoided so the app stays ad-free until configured.
import { ADSENSE_CLIENT, adsEnabled } from "./adsenseConfig";

const ADSENSE_SRC =
  "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js";

// Module-level guard so repeated calls in the same session are cheap no-ops.
let injected = false;

export const loadAdSense = (): void => {
  if (typeof document === "undefined") return;
  if (!adsEnabled() || !ADSENSE_CLIENT) return;
  if (injected) return;

  // Also guard against a script that already exists in the DOM (e.g. HMR).
  const existing = document.querySelector(
    'script[src^="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"]'
  );
  if (existing) {
    injected = true;
    return;
  }

  const script = document.createElement("script");
  script.src = `${ADSENSE_SRC}?client=${ADSENSE_CLIENT}`;
  script.async = true;
  script.crossOrigin = "anonymous";
  document.head.appendChild(script);
  injected = true;
};
