import React, { useEffect, useState } from 'react';
import { useLocation, matchPath } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react';
import { detectPlatform, MobilePlatform } from '../../utils/platform';
import OpenInApp from './OpenInApp';
import { AppLinkType } from './openInAppAction';
import { setSmartBannerArgument } from './smartBanner';

const PATTERNS: { pattern: string; type: AppLinkType }[] = [
  { pattern: '/moment/:id', type: 'moment' },
  { pattern: '/profile/:userId', type: 'profile' },
  { pattern: '/community/:id', type: 'community' },
  { pattern: '/story/:id', type: 'story' },
  { pattern: '/card/:userId', type: 'card' },
  { pattern: '/i/:code', type: 'i' },
];

// Some real, static sub-routes share their first path segment with one of the
// dynamic detail patterns above (e.g. `/community/nearby` -> NearbyUsers,
// `/profile/edit` -> EditProfile). `matchPath` can't tell those apart from an
// actual `:id`/`:userId`, so we exclude the known static segments per type to
// avoid producing a bogus `bananatalk://community/nearby` deep link.
const EXCLUDED_IDS: { [type: string]: string[] } = {
  profile: ['edit'],
  community: ['nearby'],
};

const AppBanner: React.FC = () => {
  const location = useLocation();
  const [dismissed, setDismissed] = useState(false);
  // Unknown until mounted: the prerender has no user agent, and the first
  // client render must match the prerendered (empty) output.
  const [platform, setPlatform] = useState<MobilePlatform | null>(null);
  const { t } = useTranslation();

  // Safari's smart banner reads <meta name="apple-itunes-app">; the inline
  // script in index.html sets it for the first page, this keeps it right
  // after client-side navigation. Runs on every platform: it is one attribute.
  useEffect(() => {
    setSmartBannerArgument(location.pathname);
  }, [location.pathname]);

  useEffect(() => {
    setPlatform(detectPlatform(navigator.userAgent));
  }, []);

  if (dismissed) return null;
  if (platform === null || platform === 'other') return null;

  for (const { pattern, type } of PATTERNS) {
    const m = matchPath(pattern, location.pathname);
    if (m) {
      const params = m.params as any;
      const id = params.id ?? params.userId ?? params.code;
      if (!id || (EXCLUDED_IDS[type] || []).includes(id)) continue;
      return (
        // `brand-deep` (#00806A), not `brand` (#00BFA5): this strip carries
        // small white text, and white on the lighter brand is 2.33:1 -- well
        // under AA. The stylesheet this replaces hardcoded #14b8a6, which was
        // not even a brand colour, so the banner every deep link surfaces was
        // simultaneously off-palette and unreadable.
        <div className="flex items-center gap-3 bg-brand-deep px-4 py-2 text-white">
          <span className="min-w-0 flex-1 text-sm leading-snug">
            {t('linking.appBanner.text', 'Open this in the BananaTalk app')}
          </span>
          <OpenInApp
            type={type}
            id={id}
            className="shrink-0 whitespace-nowrap rounded-full bg-white px-4 py-1.5 text-[13px] font-bold text-brand-deep transition-colors hover:bg-white/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
          />
          <button
            type="button"
            onClick={() => setDismissed(true)}
            aria-label={t('linking.appBanner.dismiss', 'Dismiss')}
            className="shrink-0 rounded-full p-1 text-white/80 transition-colors hover:bg-white/15 hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
          >
            {/* Was a bare `×` glyph on a button with no accessible name: a
                screen reader announced "multiplication sign, button". */}
            <X className="h-4 w-4" aria-hidden />
          </button>
        </div>
      );
    }
  }
  return null;
};

export default AppBanner;
