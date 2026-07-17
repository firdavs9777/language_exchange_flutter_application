# BananaTalk Web ↔ Mobile Feature-Parity Roadmap

**Date:** 2026-07-17
**Status:** Program roadmap (decomposition record). Each package below gets its own design spec → implementation plan → build cycle.

## Goal

Bring the **web frontend** (`/Users/firdavsmutalipov/Projects/BananaTalk/front`, React 18 + CRA + Redux Toolkit / RTK Query + socket.io + react-bootstrap) to feature parity with the **Flutter mobile app** (`bananatalk_app`) across Auth, Chat, Community/Moments, and Profile — plus an **app-link handoff layer** so web can bounce users into the native app for app-only actions.

The mobile app is the **source of truth**. Both talk to the same backend (`https://api.banatalk.com`, dev `http://localhost:5003`).

## Cross-cutting decisions

- **Voice Rooms:** NOT built on web. Web surfaces that rooms exist and **deep-links into the native app** to join. (No WebRTC on web.)
- **Coins:** web may **display** balance / VIP economy, but **all purchases redirect to the app**. No in-browser purchase (also required by store policy).
- **App handoff mechanism:** **Universal Links / App Links** — one smart link (e.g. `bananatalk.applink.com/...`) opens the app if installed, else falls back to App Store / Play Store. Requires `apple-app-site-association` + `assetlinks.json` served from the domain.
- **State/UX conventions:** follow existing web patterns — RTK Query endpoints in `src/store/slices/`, routes in `src/router/AppRouter.tsx`, components under `src/components/` with co-located SCSS, socket work through `src/components/chat/hooks/useSocket.ts`, i18n strings in `src/utils/locales/*.json`.

## Explicitly OUT of scope

- Apple Sign-In and Facebook **native** OAuth (mobile-only endpoints; web keeps Google OAuth).
- FCM push tokens, `ClientInfo`/device-metadata injection, biometric auth (native concerns).
- In-browser coin purchase and in-browser WebRTC voice rooms (both deep-link to app).

## Package 0 — Bidirectional App ↔ Web Linking + Sharing (foundational)

A single, matched universal-link layer so links work **both directions**:
- **Web → app:** a `banatalk.com/...` link (or "Open in app" button) opens the native app on the exact screen if installed, else the store — with the destination preserved after install (deferred deep link).
- **App → web:** share from the app produces a real `banatalk.com/...` link with a rich preview; opens the app for installers, web for everyone else.

**Domain:** `banatalk.com` (no separate applink subdomain). **App IDs (source of truth, already consistent):** iOS bundle `com.bananatalk.bananatalkApp`, App Store ID `6755862146`; Android package `com.bananatalk.app`.

### Canonical URL scheme (ONE source of truth — web routes = app GoRouter routes = `.well-known` path patterns)
| Path | Web page | App route | Shareable |
|---|---|---|---|
| `/moment/:momentId` | exists ✅ | `/moment/:momentId` ✅ | already both |
| `/profile/:userId` | **ADD (web has own-profile only)** | `/profile/:userId` ✅ | new |
| `/chat/:userId` | exists (auth-gated) | `/chat/:userId?prefill=` ✅ | app-open only |
| `/community/:id` | exists ✅ | **ADD GoRoute** | new |
| `/room/:roomId` | ADD (Language Rooms, Pkg 2) | **ADD GoRoute** | new |
| `/story/:storyId` | ADD | **ADD GoRoute** | new |

### Web-side work (this repo)
- `public/.well-known/apple-app-site-association` (JSON, no extension, served as `application/json`) declaring `<AppleTeamID>.com.bananatalk.bananatalkApp` + the path patterns above.
- `public/.well-known/assetlinks.json` declaring `com.bananatalk.app` + release/Play-App-Signing SHA-256 fingerprints.
- Ensure hosting (nginx in deploy script) serves `.well-known/*` over HTTPS, correct MIME, no redirect.
- Add public route `/profile/:userId` (+ `/room/:id`, `/story/:id` as their packages land).
- `<OpenInApp>` component/hook: build smart link, attempt app open, UA-based store fallback; interstitial `/open` route for deferred deep links.
- Smart app banner (iOS `apple-itunes-app` with `app-argument`=content path; custom Android banner).
- Central `shareUrl(type, id)` builder + Web Share buttons on moment/profile/community/story (today only moments).

### Native-side work (bananatalk_app repo — authorized to edit)
- iOS: add `com.apple.developer.associated-domains` = `applinks:banatalk.com` to `Runner.entitlements`.
- Android: add `<intent-filter android:autoVerify="true">` for `https://banatalk.com` to MainActivity.
- Add `app_links` package (uni_links is deprecated) to capture cold/warm incoming links → route through existing GoRouter.
- Add missing GoRoutes: `/community/:id`, `/room/:id`, `/story/:id`.
- Centralize the web domain in a constant/.env; add a shared `shareUrl` builder; extend `share_plus` to profile/community/room/story (today only moments).

### Rich link previews ("make it better")
CRA is **client-only**, so per-content Open Graph tags can't be rendered client-side — link-preview bots (iMessage, Slack, Twitter, WhatsApp) would see only the generic static tags. Requires a decision (tracked as an open question): (a) edge/nginx bot-detection serving prerendered OG HTML, (b) a small serverless OG endpoint per content type, or (c) migrate web to SSR (Next.js). Default recommendation: **(b) serverless OG** — smallest blast radius, no framework migration.

### Inputs required from user (blockers for the `.well-known` files)
- **Apple Developer Team ID** (10-char) — for the AASA `appID`.
- **Android signing SHA-256 fingerprint(s)** — release keystore + Play App Signing cert (`gradlew signingReport` / Play Console → App integrity).
- Confirmation that DNS/hosting for `banatalk.com` can serve `.well-known/` (CDN/nginx).

## Package 1 — Auth hardening (FIRST)

Close the real auth gaps; skip platform-only items.

- `auth/accept-terms` flow + terms-acceptance screen (incl. post-OAuth prompt when profile incomplete).
- Registration parity: add **username**, **topics/interests**, and **location** collection to the multi-step signup.
- Error handling: **429 quota-exceeded → paywall/upgrade** routing; **403 account-suspended** detection + UI; typed error codes (code expired/invalid, account locked w/ countdown, rate-limited w/ retry-after, email-exists).
- `auth/logout-all` (logout all devices).
- Harden token refresh: single-flight refresh queue so concurrent 401s don't stampede.

## Package 2 — Chat interactions + rooms (largest)

Existing chat (conversations, messaging, typing, reactions, edit/delete, corrections socket, voice/video messages) stays; add the gaps.

- **Message features:** pinning (socket `messagePinned` + HTTP pin/unpin), bookmarks (HTTP + UI), reply/forward/threads, TTS playback (`GET /messages/:id/tts`), corrections HTTP (fetch/accept history — socket already works).
- **Conversation features:** themes/wallpaper (socket `themeChanged` + HTTP), custom per-conversation nicknames, archive/unarchive, quick replies.
- **Presence:** global/bulk presence (`bulkStatusUpdate`, `onlineUsers`, `presence:online/offline/bulk`) beyond the current per-open-chat listener.
- **Language Rooms:** group text channels — `room:join/leave/message/typing/presence`, room discovery + membership UI. (In scope, built on web.)
- **Voice Rooms:** discovery/list UI only → **deep-link to app** to join (uses Package 0). No WebRTC.

## Package 3 — Moments richness + Reels

- **Media:** video upload + player in moments; voice-note recording + waveform playback; text-only moments with gradient backgrounds.
- **Comment interactions:** comment likes, nested replies, emoji reactions on comments.
- **Moment interactions:** emoji reactions on moments (distinct from like), share tracking, prompt-of-day.
- **Metadata parity:** full category + mood option sets; scheduling UI.
- **Reels:** dedicated vertical video creation flow + reel feed. (In scope.)

## Package 4 — Profile + Community parity

- **Profile display:** language level (A1–C2), response rate, last active, online status, MBTI / blood type / topics on the view (currently edit-only), location; profile Moments tab; profile theme/wallpaper; location editing.
- **Search:** partial username search (endpoint exists, unwired).
- **Community discovery:** advanced filters (language level, search, sort; nearby radius/age/gender/online-only) and member-card fields (language level, response rate, last active, VIP badge).
- **Coins:** display balance / VIP economy; **purchase → deep-link to app** (uses Package 0).

## Build order

Package 1 (Auth) → Package 2 (Chat) → Package 3 (Moments) → Package 4 (Profile/Community). Package 0 (App-Link layer) is built just-in-time before it is first needed (early in Package 2 for voice-room handoff), or pulled earlier if convenient.

Each package will be brainstormed into its own detailed spec before implementation.
