import { useEffect } from "react";
import { useLocation, useParams } from "react-router-dom";
import { BASE_URL } from "../constants";
import { trackEvent } from "./track";
import { gaEvent } from "./ga";
import { routeTemplate } from "./routeTemplate";

// The legacy visit ping (WebVisit, geo-located server-side) stays as it was;
// it feeds the existing weekly report. The new event channel and GA sit
// alongside it.
function legacyVisitPing(pathname: string): void {
  try {
    fetch(`${BASE_URL}/api/v1/analytics/visit`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        page: pathname,
        referrer: document.referrer || null,
        language: navigator.language || null,
      }),
    }).catch(() => {});
  } catch {
    // analytics must never block the UI
  }
}

export function usePageView(): void {
  const { pathname } = useLocation();
  const params = useParams();
  useEffect(() => {
    // A layout route's useParams() includes params of the whole matched
    // branch (react-router v6), so this covers a leaf like /profile/:userId
    // even though App itself is mounted above the leaf route.
    const tracked = routeTemplate(pathname, params);
    legacyVisitPing(pathname);
    trackEvent("page_view", { path: tracked });
    gaEvent("page_view", { page_path: tracked });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pathname]);
}
