# Web ↔ app parity and connection — design

Date: 2026-10-16. Source: the four read-only audits in `docs/audits/2026-10-16-web-parity/`
(`chat.md`, `moments.md`, `community.md`, `links.md`). Each finding there has a number; this spec
refers to them as `chat#3`, `moments#13`, `community#1`, `links#9`.

Repos (work happens in integration worktrees of each): app `bananatalk_app` (this repo; worktree
`bt-integration`), backend `language_exchange_backend_application` (worktree `be-integration`),
web `language_exchange_web_front` (CRA/React/TS; pushes to `main` deploy live via GitHub Actions).

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
    removed — except fields removed for privacy (Phase 1 items 1–2), which no client may rely on.
- App changes ship with 2.7.0 (not built yet), so they are not live on push.
- House rules: `package:` imports (app); `docs/REMAINING_WORK.md` updated in every commit in all
  three repos (the web repo has one); no AI attribution in commits.

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

0. **Merge backend `fix/moments-stories-audit` first** (29 commits, not on main). It already adds
   `redactUserForViewer` (`lib/privacySettings.js`) and applies it to `controllers/users.js` lists and
   `controllers/matching.js`, plus story viewer-data privacy and `userReaction` (moments#20). Resolve
   conflicts with main, run the suite, then re-check community#1, community#6 and links#11 against
   the merged code before item 1. The branch also covers moments#18 (video stories keep the link
   sticker, 44bdacf) and the backend part of moments#25 (`link.host` persisted, 1df438c).
1. **Profile field visibility (community#1, #6, links#11).** Extend `redactUserForViewer` — no second
   helper — to every remaining path: `GET /auth/users/:id` (app profile), `/:id/public` (web profile,
   including anonymous viewers), recommendations, topic users, and blocked viewers. Anonymous viewers
   never receive coordinates, full birth date, follower/following lists. Field names stay; hidden
   values become absent/null. `/:id/public` gains `hasActiveStory` (community#6).
2. **Blocks (community#5).** `followUser` refuses (403) when either side blocked the other;
   public/profile endpoints give blocked viewers a minimal profile (404 for the blocker's view of
   a blocker is not needed — minimal card is enough).
3. **Chat (chat#2, #3, #8, #10, #11).**
   - `POST /messages/conversations` no longer creates a "Conversation started" message; it runs the
     block check and the new-conversation cap (live web will now show 403 toasts for those — intended).
     Response shape is unchanged: `{isNew, participants, lastMessage (null allowed), isGroupMessage}`
     with **no** top-level `data._id` (live `NewChat.tsx:94` would navigate to a wrong thread if one
     appeared).
   - `DELETE /messages/:id` treats it as delete-for-everyone when body `deleteForEveryone === true`
     **or** query `forEveryone=true` (live web sends the query; Phase 3 web sends the body key).
   - `conversations.js` `lastMessage` populate includes `media.type` so lists show "Photo/Voice/Call"
     instead of blank (chat#10).
   - Thread and `/messages/user/:id` endpoints filter `deletedFor` and deleted/blocked conversations.
   - Socket unread count is the real count, not 1.
   - Wave mirror and `story_share` messages populate `sender` like other messages.
   - Edit accepts `content` as an alias of `message` (old web), so Phase 3 and live web both work.
4. **Moments/stories (moments#12, #19).** (moments#18, #20 and `link.host` come with item 0.)
   Highlights select the full story field set (overlays, mentions, link, font) the viewers use;
   translation validator uses `SUPPORTED_LANGUAGES` plus `tl`, `uz`, `az`, `kk`, `ky`, `tg`, `tk`.
5. **Voice notes (moments#2, chat#13).** Audio uploads (moment voice note, chat voice message)
   whose declared MIME type is not on the pass-through list (`audio/mpeg`, `audio/mp3`, `audio/aac`,
   `audio/x-aac`, `audio/mp4`, `audio/m4a`, `audio/x-m4a` — the AAC/MP3 types already in the upload
   whitelist) are transcoded **synchronously** before the response: those two
   routes stage the upload to local disk (not multer-s3 streaming), run the system ffmpeg
   (`/usr/bin/ffmpeg`, as `utils/videoTranscode.js` does) to AAC `.m4a`, upload that to Spaces, and
   return/store only the AAC URL; the original is deleted locally and never stored. On ffmpeg failure
   the original is uploaded unchanged and the failure logged (today's behaviour, no worse). Voice
   notes are short (moment ≤ the existing cap, chat ≤ the existing cap), so the added latency is
   small. Already-stored WebM notes are not migrated (non-goal).
6. **Links/emails (links#9, #13, #17, #18).** Email buttons point at existing web routes (`/communities`,
   `/chat`, `/chat/<id>`, `/profile`, admin report link); names URL-encoded. OG endpoint gains an
   `i` (invite) type. Pub/Sub audience fallback uses `api.banatalk.com`.
7. **Endpoints for web features (Phase 4).** Phase 4 reuses the app's endpoints: reels feed/create
   (`routes/moments.js`), gatherings + clubs (`routes/gatherings.js`, `routes/clubs.js`), voice rooms
   (`routes/voiceRooms.js` + its LiveKit token route), language rooms (`routes/rooms.js`), calls
   (`routes/calls.js`, `callController` LiveKit tokens + socket signalling). Each gets a contract test
   for the exact request the web sends and the fields it reads. New endpoints:
   - Web Sign in with Apple: verify an Apple identity token for `APPLE_WEB_SERVICES_ID`; returns
     the same token pair as other logins. **Refused (404) while `WEB_APPLE_SIGNIN_ENABLED` is false.**
   - Google web login: callback returns a short-lived one-time code exchanged via POST for tokens.
     The old `?token=` callback stays until the Phase 3 web is live, then is removed.
   - Flags (§4) exposed in app-config.
8. **Leftover wrong-domain references (links#19).** `api.bananatalk.com` / `support@bananatalk.com`
   in docs fixed in all three repos.

### Phase 2 — app (ships with 2.7.0)

- Story share uses `shareUrl('story', id)` → `https://banatalk.com/story/<id>`; the app's parser
  and Android manifest learn `story` (links#1, moments#1). The **AASA** (web repo, live) does not
  claim `/story/*` yet: 2.6.1 would receive links it drops. The web `/story/:id` page (Phase 3) is the
  fallback; claiming `/story/*` and `/chat/*` is an owner step once 2.7.0 is most of the iOS base
  (Phase 5). Until then `/chat/*` is **removed** from the AASA (2.6.1 drops it today).
- QR code encodes `https://banatalk.com/profile/<id>`; scanner accepts both (links#8).
- `FlutterDeepLinkingEnabled=false` (Info.plist) and `flutter_deeplinking_enabled=false`
  (manifest) so only the existing deep-link handler runs (links#7).
- `/chat/<userId>` links open that chat (parser + manifest) so the AASA can claim it again later
  (links#6).
- Text stories draw stickers (poll, question, link, location), header and reply bar (moments#3).
- Merge app `fix/moments-stories-audit` (UTC scheduling, prompt/location/isReel parsing,
  moments#6, #7) — after conflict resolution with main.
- Invite code: manual entry after signup + Play Install Referrer pickup (links#10).

### Phase 3 — web bug fixes (each area its own push)

- **Chat:** edit sends `{message}`; delete sends body `{deleteForEveryone: true}`; render `call`,
  `location`, wave and story messages like the app (location send too); limit/paywall/block errors
  open dialogs; **no REST fallback** after a slow socket ack — the bubble is marked failed with Retry,
  as in the app (chat#5); conversation list from the conversations endpoint only; unread from server;
  refetch after reconnect + `forceDisconnect` recovery; `messagePinned`, edited label, forwarded chip,
  deleted placeholder; video via `/messages/video`; premium wallpapers; message search, bookmarks
  list + unbookmark, archive, mute durations, "you're blocked" banner (chat#17); i18n.
- **Moments:** media-only posts and edits; the app's 20 gradients exactly; remove Title field;
  owner deletes comments; report comment/story + block author; saved paging and media renderer;
  stories limited to 1 image, show location; MediaRecorder prefers `audio/mp4`; feed chips
  (moments#22); comments: GIF picker, photo-only comments sent in one request, mentions rendered
  (moments#21); fix `uploadMomentPhotos` typing, drop `mediaType: "text"`, delete dead `reportMoment`
  (moments#23); story rendering parity — font style, solid-overlay plate colour, overlay/mention
  placement, hashtags shown, `allowReplies`/`allowSharing` honoured in the web viewer, `link.host` read (moments#25;
  the backend part comes with Phase 1 item 0); Saved Moments and other missing i18n keys (moments#24).
  Accepted gap: stickers on web text stories stay invisible to app 2.6.1 users until they update to
  2.7.0 (moments#3); the web keeps offering them.
- **Community:** Nearby params/fields/route/privacy; username search path; language filter from the
  catalog; waves archive + reveal + avatars; wave-cap dialog; Serious segment, smart sort,
  reciprocal; suggested members params; Today tab marks waved cards; dead endpoints removed; i18n.
- **Links:** smart banner/app banner targets the current page; AASA excludes web-only pages
  (`/profile/edit`, `/community/nearby` …) and drops `/chat/*` (see Phase 2); `/story/:id` web route;
  write the crawler rule into `deploy/nginx.snippet.conf` (bot user agents on
  `/(moment|profile|community|story|i)/<id>` proxied to `api.banatalk.com/og/<type>/<id>`) so the owner
  can apply it in Phase 5.

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
- **Language rooms** (`routes/rooms.js`) and the community **City** and **Genders** tabs
  (community#7), same data as the app.
- **Sign in with Apple** on login/register using Apple JS; backend verifies (Phase 1 item 7).

### Phase 5 — owner steps (written to `docs/ops/2026-10-16-web-hosting-steps.md`)

Certificate for `www.banatalk.com` + 301 to apex; apply `deploy/nginx.snippet.conf` (AASA as
`application/json`, SPA 404s) plus a crawler rule proxying `/(moment|profile|community|story|i)/…`
to `api.banatalk.com/og/…`; Play upload + app-signing SHA-256 → `assetlinks.json`; Apple Services
ID + return URLs; check prod `GOOGLE_PUBSUB_AUDIENCE`/`DOMAIN`, `GOOGLE_PUBSUB_SERVICE_ACCOUNT`;
turn on web feature flags one at a time after QA; `REFERRALS_ENABLED` after Android links verify;
once 2.7.0 is most of the iOS base, add `/story/*` and `/chat/*` to the AASA.

## 4. Flags

Server env (`config/limitations.js`) → `/app-config` booleans, default false: `WEB_REELS_ENABLED`,
`WEB_GATHERINGS_ENABLED`, `WEB_VOICE_ROOMS_ENABLED`, `WEB_LANGUAGE_ROOMS_ENABLED`, `WEB_CALLS_ENABLED`,
`WEB_APPLE_SIGNIN_ENABLED`. The website hides the nav entry, routes and buttons while false;
`WEB_APPLE_SIGNIN_ENABLED` also gates its backend endpoint. Existing global switches still apply for
everyone: `REELS_ENABLED` (reels), `GATHERINGS_ENABLED` (gatherings/clubs), `ROOMS_ENABLED`
(**language** rooms, `routes/rooms.js`). Voice rooms have no global switch (only tier limits via
`checkVoiceRoomAccess`); the web flag is their only gate and no global switch is added.

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
