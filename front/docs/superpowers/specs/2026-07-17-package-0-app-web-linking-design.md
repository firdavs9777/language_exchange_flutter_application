# Package 0 — Bidirectional App ↔ Web Linking + Sharing (Design Spec)

**Date:** 2026-07-17
**Parent roadmap:** `2026-07-17-mobile-parity-roadmap.md`
**Status:** Approved design — ready for implementation planning.

## Purpose

Make links work in both directions between `banatalk.com` (web, React 18 CRA) and the BananaTalk native app (Flutter):

- **Web → app:** a `banatalk.com/...` content link, or an on-page "Open in app" button, opens the native app on the exact screen if installed; otherwise the app/play store.
- **App → web:** the app's share sheet produces a real `banatalk.com/...` link with a rich preview that opens the app for installers and the web page for everyone else.

## Approved decisions (v1)

- **No deferred install tracking.** Simple *open-or-store*: content is not preserved through a fresh install. No third-party SDK (Branch, etc.).
- **Profile URL = `/profile/:userId`** — matches the app's existing share/route exactly; no app-share change needed for profiles.
- **Rich previews via a server-rendered OG endpoint** (hosted on the existing `api.banatalk.com` backend), with nginx routing crawler user-agents to it. Humans get the normal SPA.
- **v1 content types:** `moment`, `profile`, `community`. (`room`, `story` are added when Packages 2/3 build those pages.)
- **Two link mechanisms:** iOS Universal Links / Android App Links on `banatalk.com` for links tapped from other apps, **plus** a custom `bananatalk://` scheme for the on-page "Open in app" button (universal links do not fire from same-domain in-page buttons).
- **Credentials:** `.well-known` files scaffolded with `TODO` placeholders for Apple Team ID and Android SHA-256; filled before deploy.

## Canonical URL scheme (single source of truth)

Web routes, app GoRouter routes, and `.well-known` path patterns MUST all agree on these:

| Path | Web page | App route | v1 |
|---|---|---|---|
| `/moment/:momentId` | exists | `/moment/:momentId` (exists) | ✅ |
| `/profile/:userId` | **new public route** | `/profile/:userId` (exists) | ✅ |
| `/community/:communityId` | exists | **new GoRoute** | ✅ |
| `/chat/:userId` | exists (auth-gated) | `/chat/:userId?prefill=` (exists) | app-open only, not shared |
| `/room/:roomId` | later (Pkg 2) | later | deferred |
| `/story/:storyId` | later (Pkg 3) | later | deferred |

`bananatalk://` scheme mirrors the same paths, e.g. `bananatalk://moment/123`.

## Identifiers (verified consistent across both repos)

- iOS bundle id: `com.bananatalk.bananatalkApp`; App Store id: `6755862146`
- Android package: `com.bananatalk.app`
- Web domain: `banatalk.com`

---

## Component 1 — Web `.well-known` association files

**Files (served at the domain root, unhashed, `Content-Type: application/json`, HTTPS, no redirect):**

`public/.well-known/apple-app-site-association` (no file extension):
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["<APPLE_TEAM_ID>.com.bananatalk.bananatalkApp"],
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
`<APPLE_TEAM_ID>` = `TODO_APPLE_TEAM_ID` placeholder until provided.

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

**Acceptance:** CRA `build` copies `public/.well-known/*` into `build/`. Deploy/nginx serves both files at `https://banatalk.com/.well-known/...` with `application/json` and no SPA-catch-all rewrite. Apple AASA validator + Android statement-list test pass once real credentials are in.

**Deploy note:** the existing nginx config + deploy script must (a) serve `.well-known` before the SPA fallback, (b) set MIME for the extensionless AASA file.

## Component 2 — Web public profile route `/profile/:userId`

Today `/profile` renders the logged-in user only. Add a param route rendering a **read-only** public view of any user, fetched via existing `auth/users/:userId` (RTK Query hook already exists per audit).

- Route in `src/router/AppRouter.tsx`: `/profile/:userId` → public profile view.
- Reuse existing profile view components; hide owner-only edit affordances when `:userId` ≠ current user.
- Unauthenticated visitors see the public view + an "Open in app" / login prompt (no auth wall on the read-only view, so shared links work for logged-out users).
- Keep `/profile` (own profile) unchanged.

## Component 3 — Web share layer

- `src/utils/shareUrl.ts`: `shareUrl(type: 'moment'|'profile'|'community', id: string): string` → `https://banatalk.com/<type>/<id>`. Single builder used everywhere.
- Web Share API buttons (with clipboard fallback) on: moment (refactor existing inline logic in `MomentDetail.tsx` to use the builder), **profile**, **community**.
- No behavior change to the existing moment share URL (stays `/moment/:id`).

## Component 4 — Web `<OpenInApp>` component

`src/components/linking/OpenInApp.tsx` + `useOpenInApp` hook.

- Given a content `type` + `id`, builds `bananatalk://<type>/<id>`.
- On click (mobile UA): sets `window.location.href = bananatalk://...`; starts a ~1500ms timer; if the page is still visible when it fires (app didn't take over), redirect to the correct store (`6755862146` iOS / `com.bananatalk.app` Android) using existing UA detection from `DownloadApp`.
- On desktop UA: link to `/download` (or show store badges).
- Reuse/extract the UA-detection helper currently inline in `src/components/download/DownloadApp.tsx`.

## Component 5 — Smart app banner

- iOS Safari: extend the existing `<meta name="apple-itunes-app">` in `public/index.html` with `app-argument=https://banatalk.com<current-path>` so the native banner deep-links to content. (Static tag can carry a path via JS injection per route, or a sensible default; per-route `app-argument` needs runtime injection — acceptable to start with app root and enhance.)
- Android/other: a lightweight dismissible in-app banner component ("Open in app") shown on content pages on mobile web, using `<OpenInApp>`.

## Component 6 — OG preview service (server-rendered previews)

- An endpoint on `api.banatalk.com` (e.g. `GET /og/:type/:id`) that fetches the content's public metadata and returns minimal HTML containing `og:title`, `og:description`, `og:image`, `og:url` (canonical `banatalk.com/<type>/<id>`), Twitter card tags, and a `<meta http-equiv="refresh">`/JS redirect to the SPA URL for humans who somehow hit it.
- **nginx** on `banatalk.com`: for `/moment/:id`, `/profile/:id`, `/community/:id`, if the `User-Agent` matches known preview crawlers (facebookexternalhit, Twitterbot, Slackbot, WhatsApp, Discordbot, LinkedInBot, TelegramBot, etc.), proxy to the OG endpoint; otherwise serve `index.html` (SPA) as today.
- Images: use the content's existing image (first moment image / profile avatar / community image). Fallback to the generic BananaTalk OG image already in `index.html`.
- **Open question for review:** confirm the OG endpoint should live on the existing backend vs. a separate small service; confirm nginx is the right UA-routing point (vs. a CDN edge). Default: backend endpoint + nginx UA routing.

## Component 7 — Native: iOS config (`bananatalk_app/ios`)

- `Runner/Runner.entitlements`: add
  ```xml
  <key>com.apple.developer.associated-domains</key>
  <array><string>applinks:banatalk.com</string></array>
  ```
- `Runner/Info.plist`: add a `CFBundleURLTypes` entry for scheme `bananatalk` (alongside existing OAuth schemes; do not remove those).
- Requires the `applinks:banatalk.com` domain to be enabled on the App ID in the Apple Developer portal (provisioning) — noted as a native prerequisite.

## Component 8 — Native: Android config (`bananatalk_app/android`)

- `app/src/main/AndroidManifest.xml`, MainActivity: add two intent-filters (keep the existing LAUNCHER filter):
  - App Link: `android:autoVerify="true"`, `VIEW` + `BROWSABLE` + `DEFAULT`, `<data android:scheme="https" android:host="banatalk.com"/>`.
  - Custom scheme: `VIEW` + `BROWSABLE` + `DEFAULT`, `<data android:scheme="bananatalk"/>`.

## Component 9 — Native: Dart deep-link capture + routing (`bananatalk_app/lib`)

- Add `app_links` package (uni_links is deprecated).
- On app start: handle the initial link (cold start) and subscribe to the link stream (warm). Parse the incoming URI (both `https://banatalk.com/...` and `bananatalk://...`) and forward the path to the existing `GoRouter` via `router.go(path)`.
- Reuse the existing route table; the path formats already match. Guard auth-gated routes (`/chat/...`) behind the existing auth redirect.
- Handle unknown/incomplete paths gracefully (fall back to `/home`).

## Component 10 — Native: routes, domain constant, sharing (`bananatalk_app/lib`)

- Add GoRoute `/community/:communityId` (currently pushed via `Navigator`, no deep-linkable route).
- Add a single web-domain constant (e.g. in `endpoints.dart` or a `link_constants.dart`): `https://banatalk.com`.
- Add `String shareUrl(type, id)` builder; refactor the existing moment share (`single_moment.dart`) to use it; add share actions for **profile** and **community** via `share_plus`.

---

## Out of scope (Package 0)

- Deferred deep linking (install-survival), Branch/Firebase SDKs.
- `room`/`story` links (added with their packages).
- Username-based profile URLs (userId only for v1).
- Non-content deep routes (leaderboard, exam-study, AI conversation).

## Cross-repo prerequisites / inputs

- **Apple Team ID** (10 chars) → AASA `appID`. *(placeholder `TODO_APPLE_TEAM_ID` until provided)*
- **Android SHA-256 fingerprints** (upload key + Play App Signing) → assetlinks. *(placeholders until provided)*
- **Apple Developer portal:** enable Associated Domains capability + `applinks:banatalk.com` on the App ID.
- **Hosting:** `banatalk.com` must serve `/.well-known/*` correctly and support nginx UA-based routing for the OG endpoint.

## Verification plan

1. **AASA:** Apple's `app-site-association` validator + `swcutil` on-device shows `banatalk.com` verified.
2. **Android:** `adb shell pm get-app-links com.bananatalk.app` shows `verified`; statement-list test tool passes.
3. **Web→app (installed):** tap a `banatalk.com/moment/:id` link from Messages → app opens that moment (iOS + Android). On-page "Open in app" button (`bananatalk://`) opens the app.
4. **Web→store (not installed):** same tap → store; on-page button → store after fallback timer.
5. **App→web:** share moment/profile/community from app → link renders correct page; pasted in Slack/iMessage shows per-content preview (title + image).
6. **Regression:** existing OAuth schemes still work; `/profile` (own) unchanged; existing moment share unchanged in format.

## Definition of done

All 10 components implemented across both repos; verification steps 1–6 pass on real iOS + Android devices with real credentials filled into the `.well-known` files; OG previews confirmed in at least two crawlers.
