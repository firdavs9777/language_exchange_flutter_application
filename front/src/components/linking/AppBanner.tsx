import React, { useState } from 'react';
import { useLocation, matchPath } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { detectPlatform } from '../../utils/platform';
import OpenInApp from './OpenInApp';
import { ShareType } from '../../utils/shareUrl';
import './AppBanner.scss';

const PATTERNS: { pattern: string; type: ShareType }[] = [
  { pattern: '/moment/:id', type: 'moment' },
  { pattern: '/profile/:userId', type: 'profile' },
  { pattern: '/community/:id', type: 'community' },
];

// Some real, static sub-routes share their first path segment with one of the
// dynamic detail patterns above (e.g. `/community/nearby` -> NearbyUsers,
// `/profile/edit` -> EditProfile). `matchPath` can't tell those apart from an
// actual `:id`/`:userId`, so we exclude the known static segments per type to
// avoid producing a bogus `bananatalk://community/nearby` deep link.
const EXCLUDED_IDS: Record<ShareType, string[]> = {
  moment: [],
  profile: ['edit'],
  community: ['nearby'],
};

const AppBanner: React.FC = () => {
  const location = useLocation();
  const [dismissed, setDismissed] = useState(false);
  const { t } = useTranslation();
  if (dismissed) return null;
  if (detectPlatform(navigator.userAgent) === 'other') return null;

  for (const { pattern, type } of PATTERNS) {
    const m = matchPath(pattern, location.pathname);
    if (m) {
      const id = (m.params as any).id ?? (m.params as any).userId;
      if (!id || EXCLUDED_IDS[type].includes(id)) continue;
      return (
        <div className="app-banner">
          <span>{t('linking.appBanner.text', 'Open this in the BananaTalk app')}</span>
          <OpenInApp type={type} id={id} className="app-banner__open" />
          <button className="app-banner__close" onClick={() => setDismissed(true)}>×</button>
        </div>
      );
    }
  }
  return null;
};

export default AppBanner;
