# Package 0 — Bidirectional App ↔ Web Linking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `banatalk.com` content links open the native BananaTalk app on the exact screen (or store), and make app shares produce rich-preview `banatalk.com` links — in both directions.

**Architecture:** iOS Universal Links + Android App Links on `banatalk.com` (external taps) plus a `bananatalk://` custom scheme (on-page button), backed by matched `.well-known` files (web) and entitlements/intent-filters (native). A single canonical URL scheme is shared by web routes, app GoRouter routes, and `.well-known` path patterns. Rich previews come from a server-rendered OG endpoint that nginx routes crawler user-agents to; humans get the CRA SPA.

**Tech Stack:** Web — React 18 (CRA), TypeScript, RTK Query, react-router v6, Jest + React Testing Library (`npm test`). Native — Flutter, GoRouter, `app_links`, `share_plus`, `flutter test`. Infra — nginx on `banatalk.com`, backend on `api.banatalk.com`.

## Global Constraints

- Canonical paths (web route = app GoRoute = `.well-known` pattern, verbatim): `/moment/:momentId`, `/profile/:userId`, `/community/:communityId`. Custom scheme mirrors them: `bananatalk://moment/<id>` etc.
- Identifiers (do not alter): iOS bundle `com.bananatalk.bananatalkApp`, App Store id `6755862146`, Android package `com.bananatalk.app`, web domain `banatalk.com`.
- v1 content types only: `moment`, `profile`, `community`. Do NOT add `room`/`story`/`chat` share links in this package.
- No deferred install tracking; no third-party linking SDK (no Branch/Firebase Dynamic Links).
- Credentials are placeholders until provided: `TODO_APPLE_TEAM_ID`, `TODO_SHA256_UPLOAD`, `TODO_SHA256_PLAY_APP_SIGNING`.
- Profile URLs use `:userId` only (never username) in v1.
- Do not remove existing OAuth URL schemes (Google/Facebook) when adding `bananatalk://`.
- Web domain must be referenced through a single constant/builder, never hardcoded per call site.

---

## WEB REPO — `/Users/firdavsmutalipov/Projects/BananaTalk/front`

### Task 1: Web `.well-known` association files

**Files:**
- Create: `public/.well-known/apple-app-site-association` (no extension)
- Create: `public/.well-known/assetlinks.json`

**Interfaces:**
- Produces: two static files served at `https://banatalk.com/.well-known/...`. Consumed by iOS/Android OS verification (Tasks 9–10) — the `appIDs`/`package_name` must match native exactly.

- [ ] **Step 1: Create the AASA file**

`public/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["TODO_APPLE_TEAM_ID.com.bananatalk.bananatalkApp"],
        "components": [
          { "/": "/moment/*" },
          { "/": "/profile/*" },
          { "/": "/community/*" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Create the assetlinks file**

`public/.well-known/assetlinks.json`:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.bananatalk.app",
      "sha256_cert_fingerprints": ["TODO_SHA256_UPLOAD", "TODO_SHA256_PLAY_APP_SIGNING"]
    }
  }
]
```

- [ ] **Step 3: Verify the build copies them**

Run: `npm run build && ls build/.well-known/`
Expected: both `apple-app-site-association` and `assetlinks.json` present in `build/`.

- [ ] **Step 4: Commit**

```bash
git add public/.well-known/apple-app-site-association public/.well-known/assetlinks.json
git commit -m "feat(linking): add AASA + assetlinks association files (placeholder creds)"
```

**Note (deploy, not code):** nginx must serve `/.well-known/*` before the SPA catch-all, with `Content-Type: application/json` (the AASA file has no extension — add an explicit `location = /.well-known/apple-app-site-association { default_type application/json; }`). Document in the deploy step; real credentials replace the `TODO_*` values before production.

---

### Task 2: `shareUrl` builder (web)

**Files:**
- Create: `src/utils/shareUrl.ts`
- Test: `src/utils/shareUrl.test.ts`

**Interfaces:**
- Produces: `export type ShareType = 'moment' | 'profile' | 'community';` and `export function shareUrl(type: ShareType, id: string): string`. Used by Tasks 4, 6.

- [ ] **Step 1: Write the failing test**

`src/utils/shareUrl.test.ts`:
```ts
import { shareUrl } from './shareUrl';

describe('shareUrl', () => {
  it('builds a moment url', () => {
    expect(shareUrl('moment', '123')).toBe('https://banatalk.com/moment/123');
  });
  it('builds a profile url', () => {
    expect(shareUrl('profile', 'u42')).toBe('https://banatalk.com/profile/u42');
  });
  it('builds a community url', () => {
    expect(shareUrl('community', 'c7')).toBe('https://banatalk.com/community/c7');
  });
  it('encodes ids', () => {
    expect(shareUrl('profile', 'a b')).toBe('https://banatalk.com/profile/a%20b');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- --watchAll=false src/utils/shareUrl.test.ts`
Expected: FAIL — cannot find module `./shareUrl`.

- [ ] **Step 3: Write minimal implementation**

`src/utils/shareUrl.ts`:
```ts
export const WEB_ORIGIN = 'https://banatalk.com';

export type ShareType = 'moment' | 'profile' | 'community';

export function shareUrl(type: ShareType, id: string): string {
  return `${WEB_ORIGIN}/${type}/${encodeURIComponent(id)}`;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- --watchAll=false src/utils/shareUrl.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add src/utils/shareUrl.ts src/utils/shareUrl.test.ts
git commit -m "feat(linking): add canonical shareUrl builder"
```

---

### Task 3: Platform detection helper (web)

**Files:**
- Create: `src/utils/platform.ts`
- Test: `src/utils/platform.test.ts`

**Interfaces:**
- Produces: `export type MobilePlatform = 'ios' | 'android' | 'other';` and `export function detectPlatform(ua: string): MobilePlatform`. Used by Tasks 4, 7. Extracts the UA logic currently inline in `src/components/download/DownloadApp.tsx`.

- [ ] **Step 1: Write the failing test**

`src/utils/platform.test.ts`:
```ts
import { detectPlatform } from './platform';

describe('detectPlatform', () => {
  it('detects ios from iphone UA', () => {
    expect(detectPlatform('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)')).toBe('ios');
  });
  it('detects ios from ipad UA', () => {
    expect(detectPlatform('Mozilla/5.0 (iPad; CPU OS 17_0)')).toBe('ios');
  });
  it('detects android', () => {
    expect(detectPlatform('Mozilla/5.0 (Linux; Android 14; Pixel 8)')).toBe('android');
  });
  it('falls back to other on desktop', () => {
    expect(detectPlatform('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)')).toBe('other');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- --watchAll=false src/utils/platform.test.ts`
Expected: FAIL — cannot find module `./platform`.

- [ ] **Step 3: Write minimal implementation**

`src/utils/platform.ts`:
```ts
export type MobilePlatform = 'ios' | 'android' | 'other';

export const APP_STORE_URL = 'https://apps.apple.com/app/id6755862146';
export const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.bananatalk.app';

export function detectPlatform(ua: string): MobilePlatform {
  const s = ua.toLowerCase();
  if (/iphone|ipad|ipod/.test(s)) return 'ios';
  if (/android/.test(s)) return 'android';
  return 'other';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- --watchAll=false src/utils/platform.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Refactor DownloadApp to use the helper**

In `src/components/download/DownloadApp.tsx`, replace the inline UA regex + store URLs with imports from `src/utils/platform.ts` (`detectPlatform`, `APP_STORE_URL`, `PLAY_STORE_URL`). Keep existing behavior identical.

- [ ] **Step 6: Verify app still builds**

Run: `npm run build`
Expected: build succeeds, no type errors.

- [ ] **Step 7: Commit**

```bash
git add src/utils/platform.ts src/utils/platform.test.ts src/components/download/DownloadApp.tsx
git commit -m "feat(linking): extract platform detection helper, reuse in DownloadApp"
```

---

### Task 4: `<OpenInApp>` component + hook (web)

**Files:**
- Create: `src/components/linking/openInApp.ts` (pure logic)
- Create: `src/components/linking/OpenInApp.tsx` (component)
- Test: `src/components/linking/openInApp.test.ts`

**Interfaces:**
- Consumes: `detectPlatform`, `APP_STORE_URL`, `PLAY_STORE_URL` (Task 3); `ShareType` (Task 2).
- Produces: `export function appSchemeUrl(type: ShareType, id: string): string` → `bananatalk://<type>/<id>`; `export function openInApp(opts: { type: ShareType; id: string; ua: string; now: () => number; navigate: (url: string) => void; schedule: (fn: () => void, ms: number) => void; isVisible: () => boolean }): void`. Component `OpenInApp` (default export) props `{ type: ShareType; id: string; className?: string; children?: React.ReactNode }`.

- [ ] **Step 1: Write the failing test**

`src/components/linking/openInApp.test.ts`:
```ts
import { appSchemeUrl, openInApp } from './openInApp';

describe('appSchemeUrl', () => {
  it('builds a custom scheme url', () => {
    expect(appSchemeUrl('moment', '123')).toBe('bananatalk://moment/123');
  });
});

describe('openInApp', () => {
  function harness(ua: string, stayVisible: boolean) {
    const navigations: string[] = [];
    let scheduled: (() => void) | null = null;
    openInApp({
      type: 'moment',
      id: '123',
      ua,
      now: () => 0,
      navigate: (u) => navigations.push(u),
      schedule: (fn) => { scheduled = fn; },
      isVisible: () => stayVisible,
    });
    return { navigations, run: () => scheduled && scheduled() };
  }

  it('on ios: navigates to scheme, then store if still visible', () => {
    const h = harness('iPhone', true);
    expect(h.navigations[0]).toBe('bananatalk://moment/123');
    h.run();
    expect(h.navigations[1]).toBe('https://apps.apple.com/app/id6755862146');
  });

  it('on android: falls back to play store', () => {
    const h = harness('Android', true);
    h.run();
    expect(h.navigations[1]).toContain('play.google.com');
  });

  it('does NOT fall back to store if app took over (page hidden)', () => {
    const h = harness('iPhone', false);
    h.run();
    expect(h.navigations).toHaveLength(1);
  });

  it('on desktop: navigates to /download only', () => {
    const h = harness('Macintosh', true);
    expect(h.navigations).toEqual(['/download']);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- --watchAll=false src/components/linking/openInApp.test.ts`
Expected: FAIL — cannot find module `./openInApp`.

- [ ] **Step 3: Write minimal implementation**

`src/components/linking/openInApp.ts`:
```ts
import { ShareType } from '../../utils/shareUrl';
import { detectPlatform, APP_STORE_URL, PLAY_STORE_URL } from '../../utils/platform';

export function appSchemeUrl(type: ShareType, id: string): string {
  return `bananatalk://${type}/${id}`;
}

export interface OpenInAppOptions {
  type: ShareType;
  id: string;
  ua: string;
  now: () => number;
  navigate: (url: string) => void;
  schedule: (fn: () => void, ms: number) => void;
  isVisible: () => boolean;
}

const FALLBACK_MS = 1500;

export function openInApp(opts: OpenInAppOptions): void {
  const platform = detectPlatform(opts.ua);
  if (platform === 'other') {
    opts.navigate('/download');
    return;
  }
  opts.navigate(appSchemeUrl(opts.type, opts.id));
  opts.schedule(() => {
    if (opts.isVisible()) {
      opts.navigate(platform === 'ios' ? APP_STORE_URL : PLAY_STORE_URL);
    }
  }, FALLBACK_MS);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- --watchAll=false src/components/linking/openInApp.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 5: Write the component wrapper**

`src/components/linking/OpenInApp.tsx`:
```tsx
import React from 'react';
import { ShareType } from '../../utils/shareUrl';
import { openInApp } from './openInApp';

interface Props {
  type: ShareType;
  id: string;
  className?: string;
  children?: React.ReactNode;
}

const OpenInApp: React.FC<Props> = ({ type, id, className, children }) => {
  const handleClick = () => {
    openInApp({
      type,
      id,
      ua: navigator.userAgent,
      now: () => Date.now(),
      navigate: (url) => { window.location.href = url; },
      schedule: (fn, ms) => { window.setTimeout(fn, ms); },
      isVisible: () => document.visibilityState === 'visible',
    });
  };
  return (
    <button type="button" className={className} onClick={handleClick}>
      {children ?? 'Open in app'}
    </button>
  );
};

export default OpenInApp;
```

- [ ] **Step 6: Verify build**

Run: `npm run build`
Expected: build succeeds.

- [ ] **Step 7: Commit**

```bash
git add src/components/linking/
git commit -m "feat(linking): add OpenInApp component with scheme + store fallback"
```

---

### Task 5: Public profile route `/profile/:userId` (web)

**Files:**
- Modify: `src/router/AppRouter.tsx`
- Create: `src/components/profile/PublicProfile.tsx`

**Interfaces:**
- Consumes: existing profile RTK Query hook for `auth/users/:userId` (per audit, `useGetUserByIdQuery` or equivalent in `src/store/slices/usersSlice.ts` — confirm exact hook name before use) and existing profile view components.
- Produces: route `/profile/:userId` rendering a read-only public profile.

- [ ] **Step 1: Confirm the fetch hook**

Run: `grep -n "auth/users" src/store/slices/usersSlice.ts`
Expected: identify the query hook that GETs a user by id (e.g. `useGetUserProfileByIdQuery`). Use that exact name in Step 2.

- [ ] **Step 2: Create the public profile component**

`src/components/profile/PublicProfile.tsx` (replace `useGetUserProfileByIdQuery` with the exact hook confirmed in Step 1; reuse the existing profile presentational component the app already uses for viewing a user — import it rather than rebuilding markup):
```tsx
import React from 'react';
import { useParams } from 'react-router-dom';
// import { useGetUserProfileByIdQuery } from '../../store/slices/usersSlice';
// import ProfileView from './ProfileView'; // existing read-only view component

const PublicProfile: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  // const { data, isLoading, error } = useGetUserProfileByIdQuery(userId!);
  // if (isLoading) return <div>Loading…</div>;
  // if (error || !data) return <div>Profile not found.</div>;
  // return <ProfileView user={data} readOnly ownerActions={false} />;
  return null; // implementer wires the confirmed hook + existing view component
};

export default PublicProfile;
```

> Implementer note: this component MUST render for logged-out visitors (no auth wall) so shared links resolve. Owner-only actions (edit) are hidden when `userId` !== current user; reuse the existing view component and pass a read-only flag or conditionally render.

- [ ] **Step 3: Add the route**

In `src/router/AppRouter.tsx`, add a public route (NOT behind the auth guard) alongside the existing `/profile` route:
```tsx
{ path: '/profile/:userId', element: <PublicProfile /> },
```
Keep the existing `/profile` (own-profile) route unchanged. Import `PublicProfile`.

- [ ] **Step 4: Verify route renders**

Run: `npm start`, then visit `/profile/<a-real-user-id>` while logged out.
Expected: read-only profile renders (no redirect to login); own-profile edit controls absent.

- [ ] **Step 5: Commit**

```bash
git add src/router/AppRouter.tsx src/components/profile/PublicProfile.tsx
git commit -m "feat(linking): add public /profile/:userId route for shareable profiles"
```

---

### Task 6: Share buttons via shareUrl (web)

**Files:**
- Modify: `src/components/moments/MomentDetail.tsx` (refactor existing share to use `shareUrl`)
- Modify: `src/components/profile/PublicProfile.tsx` (add share button)
- Modify: community detail component `src/components/community/CommunityDetail.tsx` (add share button)
- Create: `src/components/linking/ShareButton.tsx`
- Test: `src/components/linking/shareContent.test.ts`

**Interfaces:**
- Consumes: `shareUrl` (Task 2).
- Produces: `export async function shareContent(opts: { type: ShareType; id: string; title: string; text?: string; nav: Navigator; toast: (m: string) => void }): Promise<void>`; `ShareButton` component `{ type; id; title; text?; className? }`.

- [ ] **Step 1: Write the failing test**

`src/components/linking/shareContent.test.ts`:
```ts
import { shareContent } from './shareContent';

function fakeNav(canShare: boolean) {
  const calls: any = { share: [], clip: [] };
  const nav = {
    share: canShare ? async (d: any) => { calls.share.push(d); } : undefined,
    canShare: canShare ? () => true : undefined,
    clipboard: { writeText: async (t: string) => { calls.clip.push(t); } },
  } as unknown as Navigator;
  return { nav, calls };
}

describe('shareContent', () => {
  it('uses Web Share API when available', async () => {
    const { nav, calls } = fakeNav(true);
    const toasts: string[] = [];
    await shareContent({ type: 'profile', id: 'u1', title: 'Hi', nav, toast: (m) => toasts.push(m) });
    expect(calls.share[0].url).toBe('https://banatalk.com/profile/u1');
  });

  it('falls back to clipboard when Web Share missing', async () => {
    const { nav, calls } = fakeNav(false);
    const toasts: string[] = [];
    await shareContent({ type: 'moment', id: '9', title: 'Hi', nav, toast: (m) => toasts.push(m) });
    expect(calls.clip[0]).toBe('https://banatalk.com/moment/9');
    expect(toasts[0]).toMatch(/copied/i);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- --watchAll=false src/components/linking/shareContent.test.ts`
Expected: FAIL — cannot find module `./shareContent`.

- [ ] **Step 3: Write minimal implementation**

`src/components/linking/shareContent.ts`:
```ts
import { shareUrl, ShareType } from '../../utils/shareUrl';

export interface ShareContentOptions {
  type: ShareType;
  id: string;
  title: string;
  text?: string;
  nav: Navigator;
  toast: (m: string) => void;
}

export async function shareContent(opts: ShareContentOptions): Promise<void> {
  const url = shareUrl(opts.type, opts.id);
  const data = { title: opts.title, text: opts.text ?? opts.title, url };
  const anyNav = opts.nav as any;
  if (anyNav.share && (!anyNav.canShare || anyNav.canShare(data))) {
    await anyNav.share(data);
    return;
  }
  await opts.nav.clipboard.writeText(url);
  opts.toast('Link copied to clipboard!');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- --watchAll=false src/components/linking/shareContent.test.ts`
Expected: PASS (2 tests).

- [ ] **Step 5: Add the ShareButton component**

`src/components/linking/ShareButton.tsx`:
```tsx
import React from 'react';
import { toast } from 'react-toastify';
import { ShareType } from '../../utils/shareUrl';
import { shareContent } from './shareContent';

interface Props { type: ShareType; id: string; title: string; text?: string; className?: string; }

const ShareButton: React.FC<Props> = ({ type, id, title, text, className }) => (
  <button
    type="button"
    className={className}
    onClick={() =>
      shareContent({ type, id, title, text, nav: navigator, toast: (m) => toast.success(m) })
        .catch(() => {})
    }
  >
    Share
  </button>
);

export default ShareButton;
```

- [ ] **Step 6: Wire ShareButton into the three detail views**

- In `MomentDetail.tsx`: replace the existing inline `handleShare` body with `<ShareButton type="moment" id={momentId} title={momentDetails.title} text={momentDetails.description} />` (remove the now-dead inline share code and its hardcoded URL).
- In `PublicProfile.tsx`: add `<ShareButton type="profile" id={userId} title={user.name} />`.
- In `CommunityDetail.tsx`: add `<ShareButton type="community" id={communityId} title={community.name} />`.

- [ ] **Step 7: Verify build + moment share still works**

Run: `npm run build`, then manually confirm moment share produces `https://banatalk.com/moment/:id`.
Expected: build succeeds; shared URL format unchanged from before.

- [ ] **Step 8: Commit**

```bash
git add src/components/linking/ src/components/moments/MomentDetail.tsx src/components/profile/PublicProfile.tsx src/components/community/CommunityDetail.tsx
git commit -m "feat(linking): unify sharing via shareUrl + add profile/community share buttons"
```

---

### Task 7: Smart app banner (web)

**Files:**
- Modify: `public/index.html` (extend `apple-itunes-app` meta)
- Create: `src/components/linking/AppBanner.tsx`
- Modify: `src/App.tsx` (mount banner)

**Interfaces:**
- Consumes: `detectPlatform` (Task 3), `OpenInApp`/`openInApp` logic (Task 4), route params.
- Produces: dismissible `AppBanner` shown on mobile web on content pages.

- [ ] **Step 1: Extend the iOS smart banner meta**

In `public/index.html`, update the existing tag to advertise the app root as the deep-link argument (per-route enhancement is deferred):
```html
<meta name="apple-itunes-app" content="app-id=6755862146, app-argument=https://banatalk.com/" />
```

- [ ] **Step 2: Create the banner component**

`src/components/linking/AppBanner.tsx`:
```tsx
import React, { useState } from 'react';
import { useLocation, matchPath } from 'react-router-dom';
import { detectPlatform } from '../../utils/platform';
import OpenInApp from './OpenInApp';
import { ShareType } from '../../utils/shareUrl';

const PATTERNS: { pattern: string; type: ShareType }[] = [
  { pattern: '/moment/:id', type: 'moment' },
  { pattern: '/profile/:userId', type: 'profile' },
  { pattern: '/community/:id', type: 'community' },
];

const AppBanner: React.FC = () => {
  const location = useLocation();
  const [dismissed, setDismissed] = useState(false);
  if (dismissed) return null;
  if (detectPlatform(navigator.userAgent) === 'other') return null;

  for (const { pattern, type } of PATTERNS) {
    const m = matchPath(pattern, location.pathname);
    if (m) {
      const id = (m.params as any).id ?? (m.params as any).userId;
      return (
        <div className="app-banner">
          <span>Open this in the BananaTalk app</span>
          <OpenInApp type={type} id={id} className="app-banner__open" />
          <button className="app-banner__close" onClick={() => setDismissed(true)}>×</button>
        </div>
      );
    }
  }
  return null;
};

export default AppBanner;
```

- [ ] **Step 3: Mount the banner**

In `src/App.tsx`, render `<AppBanner />` inside the layout (above the routed `<Outlet />`). Import it.

- [ ] **Step 4: Verify**

Run: `npm start`, open a `/moment/:id` page with a mobile UA (devtools device mode).
Expected: banner appears with a working "Open in app" button; "×" dismisses it; no banner on desktop or non-content pages.

- [ ] **Step 5: Commit**

```bash
git add public/index.html src/components/linking/AppBanner.tsx src/App.tsx
git commit -m "feat(linking): add smart app banner on content pages"
```

---

### Task 8: OG preview endpoint + nginx UA routing

**Files:**
- Create (backend repo `api.banatalk.com`): OG route `GET /og/:type/:id`
- Modify (deploy): nginx site config for `banatalk.com`
- Test (backend repo): `og.test.*` for the HTML builder

> This task targets the backend + deploy infra, not the `front` repo. If the backend repo is unavailable to the implementer, deliver the pure HTML-builder function + tests and the nginx snippet as artifacts for the backend owner.

**Interfaces:**
- Produces: `buildOgHtml(meta: { canonicalUrl: string; title: string; description: string; image: string })` → HTML string; endpoint `GET /og/:type/:id` returning that HTML with `text/html`.

- [ ] **Step 1: Write the failing test (HTML builder)**

```ts
import { buildOgHtml } from './og';

it('embeds canonical OG tags and redirect', () => {
  const html = buildOgHtml({
    canonicalUrl: 'https://banatalk.com/moment/1',
    title: 'A moment',
    description: 'desc',
    image: 'https://cdn/x.jpg',
  });
  expect(html).toContain('<meta property="og:title" content="A moment"');
  expect(html).toContain('<meta property="og:image" content="https://cdn/x.jpg"');
  expect(html).toContain('<meta property="og:url" content="https://banatalk.com/moment/1"');
  expect(html).toContain('https://banatalk.com/moment/1'); // human redirect target
});
```

- [ ] **Step 2: Run test — expect FAIL** (module missing).

- [ ] **Step 3: Implement the builder + endpoint**

```ts
export function buildOgHtml(m: {
  canonicalUrl: string; title: string; description: string; image: string;
}): string {
  const esc = (s: string) => s.replace(/"/g, '&quot;').replace(/</g, '&lt;');
  return `<!doctype html><html><head>
<meta charset="utf-8"/>
<meta property="og:type" content="website"/>
<meta property="og:title" content="${esc(m.title)}"/>
<meta property="og:description" content="${esc(m.description)}"/>
<meta property="og:image" content="${esc(m.image)}"/>
<meta property="og:url" content="${esc(m.canonicalUrl)}"/>
<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:title" content="${esc(m.title)}"/>
<meta name="twitter:image" content="${esc(m.image)}"/>
<meta http-equiv="refresh" content="0; url=${esc(m.canonicalUrl)}"/>
</head><body>Redirecting to <a href="${esc(m.canonicalUrl)}">${esc(m.canonicalUrl)}</a></body></html>`;
}
```
Endpoint `GET /og/:type/:id`: validate `type ∈ {moment,profile,community}`; fetch the entity; map to `{title, description, image}` (moment: title/description + first image; profile: name/bio + avatar; community: name/description + image); fall back to the generic BananaTalk OG image when none. Return `buildOgHtml(...)` with `Content-Type: text/html`.

- [ ] **Step 4: Run test — expect PASS.**

- [ ] **Step 5: Add nginx UA routing**

In the `banatalk.com` server block, before the SPA `try_files` fallback:
```nginx
location ~ ^/(moment|profile|community)/[^/]+$ {
  if ($http_user_agent ~* "(facebookexternalhit|Twitterbot|Slackbot|WhatsApp|Discordbot|LinkedInBot|TelegramBot|Pinterest|redditbot|Googlebot)") {
    proxy_pass https://api.banatalk.com/og$request_uri;
    break;
  }
  try_files $uri /index.html;
}
```
(Keep the existing `.well-known` and static-asset locations ordered before this.)

- [ ] **Step 6: Verify with a crawler UA**

Run: `curl -A "facebookexternalhit/1.1" https://banatalk.com/moment/<real-id>`
Expected: HTML with per-content `og:title`/`og:image`. Same URL with a normal browser UA returns the SPA `index.html`.

- [ ] **Step 7: Commit** (backend repo + deploy config)

```bash
git commit -am "feat(linking): OG preview endpoint + nginx crawler routing"
```

---

## NATIVE REPO — `/Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app`

### Task 9: iOS associated domains + custom scheme

**Files:**
- Modify: `ios/Runner/Runner.entitlements`
- Modify: `ios/Runner/Info.plist`

**Interfaces:**
- Produces: iOS accepts `https://banatalk.com/...` universal links and `bananatalk://...` scheme. Path patterns must match Task 1's AASA.

- [ ] **Step 1: Add associated domains entitlement**

In `ios/Runner/Runner.entitlements`, add (keep existing `aps-environment` and Apple Sign-In keys):
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:banatalk.com</string>
</array>
```

- [ ] **Step 2: Add the custom URL scheme**

In `ios/Runner/Info.plist`, append a new dict to the existing `CFBundleURLTypes` array (do NOT remove the Google/Facebook entries):
```xml
<dict>
  <key>CFBundleURLName</key>
  <string>com.bananatalk.deeplink</string>
  <key>CFBundleURLSchemes</key>
  <array><string>bananatalk</string></array>
</dict>
```

- [ ] **Step 3: Verify the app builds**

Run: `flutter build ios --no-codesign`
Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add ios/Runner/Runner.entitlements ios/Runner/Info.plist
git commit -m "feat(linking): iOS associated domains + bananatalk scheme"
```

> Native prerequisite (not code): enable the Associated Domains capability + `applinks:banatalk.com` on the App ID in the Apple Developer portal before device testing.

---

### Task 10: Android app links + custom scheme

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: Android verifies `https://banatalk.com` app links and handles `bananatalk://`. `package_name` must match Task 1's assetlinks.

- [ ] **Step 1: Add the two intent-filters**

Inside the MainActivity `<activity>` in `android/app/src/main/AndroidManifest.xml` (keep the existing LAUNCHER intent-filter):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="banatalk.com" />
</intent-filter>
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="bananatalk" />
</intent-filter>
```

- [ ] **Step 2: Verify the app builds**

Run: `flutter build apk --debug`
Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(linking): Android app links + bananatalk scheme"
```

---

### Task 11: Dart deep-link parsing + routing

**Files:**
- Modify: `pubspec.yaml` (add `app_links`)
- Create: `lib/services/deep_link_parser.dart` (pure)
- Create: `lib/services/deep_link_service.dart` (wires app_links → GoRouter)
- Modify: `lib/main.dart` (start the service)
- Create: `test/deep_link_parser_test.dart`

**Interfaces:**
- Consumes: existing `GoRouter` (`lib/router/app_router.dart`).
- Produces: `String? routePathFromUri(Uri uri)` → app route path (e.g. `/moment/123`) or null for unknown. `DeepLinkService(router).start()`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml` under dependencies: `app_links: ^6.3.0`. Run `flutter pub get`.

- [ ] **Step 2: Write the failing test**

`test/deep_link_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

void main() {
  test('parses https universal link', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/moment/123')), '/moment/123');
  });
  test('parses custom scheme', () {
    expect(routePathFromUri(Uri.parse('bananatalk://profile/u9')), '/profile/u9');
  });
  test('parses community', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/community/c1')), '/community/c1');
  });
  test('returns null for unknown host path', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/settings')), isNull);
  });
  test('returns null for wrong domain', () {
    expect(routePathFromUri(Uri.parse('https://evil.com/moment/1')), isNull);
  });
}
```
(Replace `bananatalk_app` in the import with the package name from `pubspec.yaml`'s `name:` if different.)

- [ ] **Step 3: Run test — expect FAIL** (`flutter test test/deep_link_parser_test.dart`).

- [ ] **Step 4: Implement the parser**

`lib/services/deep_link_parser.dart`:
```dart
const _allowed = {'moment', 'profile', 'community'};

String? routePathFromUri(Uri uri) {
  final isHttps = uri.scheme == 'https' && uri.host == 'banatalk.com';
  final isScheme = uri.scheme == 'bananatalk';
  if (!isHttps && !isScheme) return null;

  // https://banatalk.com/<type>/<id>  → segments [type, id]
  // bananatalk://<type>/<id>          → host=type, segments=[id]
  String? type;
  String? id;
  if (isScheme) {
    type = uri.host;
    id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else {
    if (uri.pathSegments.length >= 2) {
      type = uri.pathSegments[0];
      id = uri.pathSegments[1];
    }
  }
  if (type == null || id == null || id.isEmpty) return null;
  if (!_allowed.contains(type)) return null;
  return '/$type/$id';
}
```

- [ ] **Step 5: Run test — expect PASS** (5 tests).

- [ ] **Step 6: Implement the service**

`lib/services/deep_link_service.dart`:
```dart
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'deep_link_parser.dart';

class DeepLinkService {
  final GoRouter router;
  final AppLinks _appLinks = AppLinks();
  DeepLinkService(this.router);

  Future<void> start() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
    _appLinks.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    final path = routePathFromUri(uri);
    if (path != null) router.go(path);
  }
}
```

- [ ] **Step 7: Start the service on boot**

In `lib/main.dart`, after the `GoRouter` is constructed, call `DeepLinkService(router).start();` (fire-and-forget; ensure it runs after `runApp`/router init). Import the service.

- [ ] **Step 8: Verify build**

Run: `flutter analyze && flutter build apk --debug`
Expected: no analyzer errors; build succeeds.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml lib/services/deep_link_parser.dart lib/services/deep_link_service.dart lib/main.dart test/deep_link_parser_test.dart
git commit -m "feat(linking): capture and route incoming deep links via app_links"
```

---

### Task 12: Add GoRoute `/community/:communityId` (native)

**Files:**
- Modify: `lib/router/app_router.dart`

**Interfaces:**
- Consumes: existing community detail screen (currently pushed via `Navigator`).
- Produces: deep-linkable `/community/:communityId` route so Task 11 can route to it.

- [ ] **Step 1: Identify the community detail screen**

Run: `grep -rn "class .*Communit.*Screen\|CommunityDetail" lib/pages/community/`
Expected: the widget currently shown for a single community.

- [ ] **Step 2: Add the route**

In `lib/router/app_router.dart`, add a GoRoute mirroring the existing `/moment/:momentId` pattern:
```dart
GoRoute(
  path: '/community/:communityId',
  builder: (context, state) =>
      CommunityDetailScreen(communityId: state.pathParameters['communityId']!),
),
```
(Use the exact screen class + constructor param from Step 1; if it needs an object rather than an id, load-by-id inside the screen or a small wrapper.)

- [ ] **Step 3: Verify build**

Run: `flutter analyze && flutter build apk --debug`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat(linking): add deep-linkable /community/:communityId route"
```

---

### Task 13: Native domain constant + shareUrl + extend sharing

**Files:**
- Create: `lib/services/link_constants.dart`
- Modify: `lib/pages/moments/single/single_moment.dart` (use builder)
- Modify: profile + community screens (add share actions)
- Create: `test/share_url_test.dart`

**Interfaces:**
- Produces: `const kWebOrigin = 'https://banatalk.com';` and `String shareUrl(String type, String id)`. Used by all app share actions.

- [ ] **Step 1: Write the failing test**

`test/share_url_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/link_constants.dart';

void main() {
  test('builds share urls', () {
    expect(shareUrl('moment', '123'), 'https://banatalk.com/moment/123');
    expect(shareUrl('profile', 'u9'), 'https://banatalk.com/profile/u9');
    expect(shareUrl('community', 'c1'), 'https://banatalk.com/community/c1');
  });
}
```

- [ ] **Step 2: Run test — expect FAIL.**

- [ ] **Step 3: Implement the builder**

`lib/services/link_constants.dart`:
```dart
const String kWebOrigin = 'https://banatalk.com';

String shareUrl(String type, String id) => '$kWebOrigin/$type/$id';
```

- [ ] **Step 4: Run test — expect PASS.**

- [ ] **Step 5: Refactor moment share + add profile/community shares**

- In `lib/pages/moments/single/single_moment.dart`, replace the hardcoded `'https://banatalk.com/moment/${widget.moment.id}'` with `shareUrl('moment', widget.moment.id.toString())`.
- Add a share action on the profile screen: `Share.share('${l10n.checkOutProfile}\n\n${shareUrl('profile', user.id.toString())}')`.
- Add a share action on the community detail screen: `Share.share('${l10n.checkOutCommunity}\n\n${shareUrl('community', community.id.toString())}')`.
- Add the two new l10n keys (`checkOutProfile`, `checkOutCommunity`) following the existing `checkOutMoment` pattern in the localization files.

- [ ] **Step 6: Verify build**

Run: `flutter analyze && flutter build apk --debug`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/services/link_constants.dart lib/pages/moments/single/single_moment.dart test/share_url_test.dart lib/l10n/
git commit -m "feat(linking): centralize share URL builder + share profile/community"
```

---

## Integration Verification (after all tasks, with real credentials)

- [ ] Fill real `TODO_APPLE_TEAM_ID` and SHA-256 fingerprints into `public/.well-known/*`; deploy web.
- [ ] iOS: install app; `curl https://banatalk.com/.well-known/apple-app-site-association` returns JSON with `application/json`; tap `banatalk.com/moment/<id>` from Messages → app opens that moment.
- [ ] Android: `adb shell pm get-app-links com.bananatalk.app` shows `verified`; tap link → app opens.
- [ ] Not-installed: link → correct store; on-page "Open in app" → store after fallback.
- [ ] App→web: share moment/profile/community → correct `banatalk.com` page; preview renders in Slack + iMessage.
- [ ] Regression: OAuth login schemes still work; `/profile` (own) unchanged; moment share URL format unchanged.

## Notes on task ordering / parallelism

- Web Tasks 1–7 are independent of native Tasks 9–13 and can proceed in parallel.
- Task 8 (OG) targets backend/deploy; can proceed independently once entity metadata shapes are known.
- Final integration verification requires both repos deployed + real credentials.
