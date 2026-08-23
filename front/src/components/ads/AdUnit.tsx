// Reusable AdSense ad unit. Renders nothing until ads are configured, so it is
// safe to drop into the UI ahead of go-live. Pushes to the adsbygoogle queue
// exactly once per mounted unit — guarded so React 18 StrictMode double-mounts
// and re-renders don't trigger the "already have ads in this slot" error.
import React, { useEffect, useRef } from "react";
import { ADSENSE_CLIENT, adsEnabled, adsTestMode } from "./adsenseConfig";
import { loadAdSense } from "./loadAdSense";

declare global {
  interface Window {
    adsbygoogle?: unknown[];
  }
}

interface AdUnitProps {
  slot: string;
  format?: string;
  layout?: string;
  responsive?: boolean;
  className?: string;
  style?: React.CSSProperties;
}

const AdUnit: React.FC<AdUnitProps> = ({
  slot,
  format,
  layout,
  responsive,
  className,
  style,
}) => {
  const pushedRef = useRef(false);

  useEffect(() => {
    if (!adsEnabled() || !slot || !ADSENSE_CLIENT) return;
    if (pushedRef.current) return;
    pushedRef.current = true;

    loadAdSense();
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch (err) {
      console.warn("AdSense push failed", err);
    }
  }, [slot]);

  // Non-breaking: render nothing until an ad client + slot are configured.
  if (!adsEnabled() || !slot || !ADSENSE_CLIENT) return null;

  return (
    <div className={className}>
      <ins
        className="adsbygoogle"
        style={{ display: "block", ...style }}
        data-ad-client={ADSENSE_CLIENT}
        data-ad-slot={slot}
        data-ad-format={format || "auto"}
        data-full-width-responsive={responsive === false ? "false" : "true"}
        {...(layout ? { "data-ad-layout": layout } : {})}
        {...(adsTestMode() ? { "data-adtest": "on" } : {})}
      />
    </div>
  );
};

export default AdUnit;
