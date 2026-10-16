# Web ↔ app parity and connection — design

Date: 2026-10-16. Source: the four read-only audits in `docs/audits/2026-10-16-web-parity/`
(`chat.md`, `moments.md`, `community.md`, `links.md`). Each finding there has a number; this spec
refers to them as `chat#3`, `moments#13`, `community#1`, `links#9`.

Repos: app `bananatalk_app` (this repo), backend `language_exchange_backend_application`,
web `language_exchange_web_front` (CRA/React/TS, pushes to `main` deploy live via GitHub Actions).

## 1. Goal

A web user and an app user can chat, see each other's moments/stories and find each other in
community with nothing broken, missing or leaked; links between banatalk.com and the app work both
ways; and the website gets the features it never had: reels, gatherings/clubs, voice rooms, calls,
Sign in with Apple.

Success = every P0/P1 in the four audits closed (or moved to an owner step), P2s closed unless
listed under Non-goals, new web features built behind flags, all suites green, device-only checks
written into the QA sheet.

## 2. Constraints

- **Web and backend are always live.** A push to either `main` deploys to production immediately.
  - Never push without a passing build + full test suite for that repo.
  - Web bug fixes ship in small area-sized pushes (chat, moments, community, links), each revertible.
  - New web features are **dark until their flag is on** (see §4). They ship incrementally but
    stay invisible.
  - Backend changes are **backward compatible** with the live website (origin/main) and app 2.6.1:
    old request shapes keep working, response changes are additive, nothing a live client reads is
    removed — except fields removed for privacy (§3.1), which no client may rely on.
- App changes ship with 2.7.0 (not built yet), so they are not live on push.
- House rules: `package:` imports (app); REMAINING_WORK.md updated in every commit (app + backend;
  web: `docs/` if it has a tracker, else the app's REMAINING_WORK carries web items); no AI
  attribution in commits.

## 3. Phases

Executed in order; inside a phase, independent areas run in parallel worktrees. Each phase is
merged, tested and pushed before the next starts.

### Phase 0 — web repo baseline

The web repo's local `main` has 23 unpushed commits from another session (story rendering, prompt
chip, my-moments paging, privacy settings page). One of them (`9ba0eb9`, merged by `ab59100`)
deletes every unit test.

- Rebuild those 23 commits as **one commit** on top of `origin/main`, without the test deletion.
- Run the restored tests; fix tests the other session's changes legitimately broke (update the
  test, not the behaviour, unless the behaviour is a bug).
- `npm run build` + `npm test` green → push (deploys).

### Phase 1 — backend

1. **Profile field visibility (community#1, #6, links#11).** One helper, e.g.
   `lib/profileVisibility.js` `visibleProfile(user, viewer)`, applying the user's privacy toggles
   (hide age, city/location, online, VIP, gifting level) and the relationship (self, follower,
   stranger, anonymous, blocked). Used by: `GET /auth/users` list, `/matching/daily`,
   recommendations, topic users, `GET /auth/users/:id` (app profile), `/:id/public` (web profile).
   Anonymous viewers never receive coordinates, full birth date, follower/following lists.
   Response keeps the same field names; hidden values become absent/null.
2. **Blocks (community#5).** `followUser` refuses (403) when either side blocked the other;
   public/profile endpoints give blocked viewers a minimal profile (404 for the blocker's view of
   a blocker is not needed — minimal card is enough).
3. **Chat (chat#2, #3, #8, #10, #11).**
   - `POST /messages/conversations` creates/returns a conversation **without** creating a message;
     it runs the block check and the new-conversation cap.
   - `DELETE /messages/:id` accepts `forEveryone` from query **or** body.
   - Thread and `/messages/user/:id` endpoints filter `deletedFor` and deleted/blocked conversations.
   - Socket unread count is the real count, not 1.
   - Wave mirror and `story_share` messages populate `sender` like other messages.
   - Edit accepts `content` as an alias of `message` (old web), so Phase 3 and live web both work.
4. **Moments/stories (moments#12, #18, #19, #20).** Merge backend `fix/moments-stories-audit`
   (viewer-data privacy, `userReaction`); video stories parse `link`; highlights select the full
   story field set; translation validator uses `SUPPORTED_LANGUAGES` + `tl`, `uz`, `az`, `kk`, `ky`,
   `tg`, `tk`.
5. **Voice notes (moments#2, chat#13).** Uploaded audio (moments + chat voice) that is not
   AAC/MP4/MP3 is transcoded to AAC (`.m4a`) with ffmpeg (already used for video); the stored URL
   points at the AAC file.
6. **Links/emails (links#9, #13, #16).** Email buttons point at existing web routes (`/communities`,
   `/chat`, `/chat/<id>`, `/profile`, admin report link); names URL-encoded. OG endpoint gains an
   `i` (invite) type. Pub/Sub audience fallback uses `api.banatalk.com`.
7. **Endpoints for web features (§3.5).** Reuse the app's endpoints. New: web Sign in with Apple
   (verify Apple identity token for a configured Services ID, `APPLE_WEB_SERVICES_ID`); Google web
   login returns a one-time code exchanged for tokens (keep the old `?token=` path until the new
   web is live, then remove). Flags in app-config: `webReelsEnabled`, `webGatheringsEnabled`,
   `webVoiceRoomsEnabled`, `webCallsEnabled`, `webAppleSignInEnabled` (env, default false).

### Phase 2 — app (ships with 2.7.0)

- Story share uses `shareUrl('story', id)` → `https://banatalk.com/story/<id>`; parser, manifest,
  AASA learn `story` (links#1, moments#1).
- QR code encodes `https://banatalk.com/profile/<id>`; scanner accepts both (links#8).
- `FlutterDeepLinkingEnabled=false` (Info.plist) and `flutter_deeplinking_enabled=false`
  (manifest) so only the existing deep-link handler runs (links#7).
- `/chat/<userId>` links open that chat (parser + manifest), matching the AASA claim (links#6).
- Text stories draw stickers (poll, question, link, location), header and reply bar (moments#3).
- Merge app `fix/moments-stories-audit` (UTC scheduling, prompt/location/isReel parsing,
  moments#6, #7) — after conflict resolution with main.
- Invite code: manual entry after signup + Play Install Referrer pickup (links#10).

### Phase 3 — web bug fixes (each area its own push)

- **Chat:** edit sends `message`; delete sends body; render `call`, `location`, wave and story
  messages like the app; limit/paywall/block errors open dialogs; no REST fallback after a slow
  ack (or idempotency key); conversation list from conversations endpoint only; unread from
  server; refetch after reconnect + `forceDisconnect` recovery; `messagePinned`, edited label,
  forwarded chip, deleted placeholder; video via `/messages/video`; premium wallpapers; i18n.
- **Moments:** media-only posts and edits; the app's 20 gradients exactly; remove Title field;
  owner deletes comments; report comment/story + block author; saved paging and media renderer;
  stories limited to 1 image, show location; MediaRecorder prefers `audio/mp4`; feed chips;
  remaining moments P2s and i18n.
- **Community:** Nearby params/fields/route/privacy; username search path; language filter from the
  catalog; waves archive + reveal + avatars; wave-cap dialog; Serious segment, smart sort,
  reciprocal; suggested members params; Today tab marks waved cards; dead endpoints removed; i18n.
- **Links:** smart banner/app banner targets the current page; AASA excludes web-only pages
  (`/profile/edit`, `/community/nearby` …); `/story/:id` web route.

### Phase 4 — web features (dark until flagged)

- **Reels:** vertical feed (`getReelsFeed`), viewer, create (video ≤180 s, `isReel`), like/comment/
  share — same endpoints and rules as the app.
- **Gatherings/clubs:** browse, detail, join/leave, host create/edit, host decisions — app endpoints.
- **Voice rooms:** list, join as listener, request/take speaker, host controls — `livekit-client`
  JS SDK with tokens from the existing backend LiveKit routes.
- **Calls:** 1:1 voice/video with app users via the same LiveKit call flow (`/calls/*` + socket
  signalling). Incoming ring while any web tab is open; accept/decline (incl. decline message);
  camera on/off, mute, hang up; call history + missed-call entries. No ring when no tab is open
  (browser limit) — the app's push still rings the user's phone.
- **Sign in with Apple** on login/register using Apple JS; backend verifies (§3.1 item 7).

### Phase 5 — owner steps (written to `docs/ops/2026-10-16-web-hosting-steps.md`)

Certificate for `www.banatalk.com` + 301 to apex; apply `deploy/nginx.snippet.conf` (AASA as
`application/json`, SPA 404s) plus a crawler rule proxying `/(moment|profile|community|story|i)/…`
to `api.banatalk.com/og/…`; Play upload + app-signing SHA-256 → `assetlinks.json`; Apple Services
ID + return URLs; check prod `GOOGLE_PUBSUB_AUDIENCE`/`DOMAIN`, `GOOGLE_PUBSUB_SERVICE_ACCOUNT`;
turn on web feature flags one at a time after QA; `REFERRALS_ENABLED` after Android links verify.

## 4. Flags

Server env → `/app-config` booleans, default false: `WEB_REELS_ENABLED`, `WEB_GATHERINGS_ENABLED`,
`WEB_VOICE_ROOMS_ENABLED`, `WEB_CALLS_ENABLED`, `WEB_APPLE_SIGNIN_ENABLED`. The website hides the
nav entry, routes and buttons while false. Existing `GATHERINGS_ENABLED`, `ROOMS_ENABLED`,
`REELS_ENABLED` still gate the feature for everyone.

## 5. Testing

- Backend: a test per fix; contract tests for every endpoint the web calls in Phases 3–4 (request
  shape web sends → response shape web reads).
- App: unit/widget tests per change; full suite green.
- Web: restored suite + tests per change; `npm test` and `npm run build` green before every push.
- Device/browser QA rows added to `docs/qa/regression-suite.csv` (new "Web" area): iOS playback of
  web voice notes, browser↔app calls both directions, voice room with app + web, Android app links
  after fingerprints, previews in KakaoTalk/Telegram/WhatsApp after the nginx rule, Apple sign-in.

## 6. Non-goals

Background ringing for web calls (needs Web Push + service worker); group calls; reel editing
tools beyond trim; migrating old WebM voice notes already stored (only new uploads are converted —
listed as a follow-up); bananatalk.com domain purchase.

## 7. Risks

- Calls/voice rooms on web are the largest and hardest to verify without two people — built last,
  flagged off.
- Apple web sign-in can't be tested end to end until the Services ID exists.
- Phase 0 deploys another session's changes; mitigated by the green build/test gate.
- Backend list redaction changes what live clients see (hidden fields disappear) — intended.
