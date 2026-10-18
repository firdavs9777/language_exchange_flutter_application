import { useCallback, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { useGetAppConfigQuery, PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { dismiss as remember, isDismissed } from "./dismissals";

export interface WebAnnouncements {
  popup: PublicAnnouncement | null;
  banner: PublicAnnouncement | null;
  dismiss: (id: string) => void;
}

// Module-level: like the pop-up, a banner is shown at most once per page load.
// Once one has been shown and dismissed, the next waits for a later load.
let bannerDismissedThisLoad = false;
export function _resetBannerForTests() { bannerDismissedThisLoad = false; }

export function useWebAnnouncements(): WebAnnouncements {
  const { i18n } = useTranslation();
  const { data } = useGetAppConfigQuery({ platform: "web", lang: i18n.language });
  const [tick, setTick] = useState(0);

  const bannerId = useRef<string | null>(null);

  const dismiss = useCallback((id: string) => {
    remember(id);
    if (id === bannerId.current) bannerDismissedThisLoad = true;
    setTick((n) => n + 1);
  }, []);

  return useMemo(() => {
    const list: PublicAnnouncement[] = (data && Array.isArray(data.announcements) ? data.announcements : [])
      .filter((a: PublicAnnouncement) => a && a.id && !isDismissed(a.id));
    const banner = bannerDismissedThisLoad ? null : list.find((a) => a.displayStyle === "banner") || null;
    bannerId.current = banner ? banner.id : bannerId.current;
    const popup = list.find((a) => a.displayStyle !== "banner") || null;
    return { popup, banner, dismiss };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, tick, dismiss]);
}
