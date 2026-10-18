# Remaining work — web

Last updated: 2026-10-18. Tick items off in the same commit that finishes them.

See also: app `bananatalk_app/docs/REMAINING_WORK.md` (release, store consoles, device QA) ·
backend `language_exchange_backend_application/docs/REMAINING_WORK.md` (server env, prod DB, flags, ops).

## 1. Status

- **`main` 2ce0c93 is DEPLOYED (2026-10-13)**: admin announcements console with the 2026-10-13 audit fixes,
  delivery status incl. "Stopped at end time" / "Ended by admin", and the `/moments/:id` → `/moment/:id` redirect.
- Backend a9a0b6e (deployed) has everything the console needs. App 2.7.0 is not released yet.
- `public/.well-known/assetlinks.json` has the Play App Signing fingerprint (2026-10-16); the upload-key fingerprint is still to add (internal/sideloaded builds).

## 2. Owner — manual steps (in order)

1. Paste the **upload-key** and **Play app-signing** SHA-256 (Play Console → App integrity → App signing) into
   `public/.well-known/assetlinks.json`, deploy (app handoff `2.7.0-handoff.md` §5; device check is in the app file).
2. Optional: apply `deploy/nginx.snippet.conf` on the droplet (serves the Apple association file as `application/json`, real 404s).
3. Phase 5: apply the link-preview locations in `deploy/nginx.snippet.conf` (they must sit above the `nginx.routes.conf` include), `nginx -t`, reload, then run the two `curl` checks in README "Link previews". Previews in KakaoTalk / Telegram / WhatsApp are rows in the app's `docs/qa/regression-suite.csv` (Web area).

## 3. Production QA

- [x] `curl https://banatalk.com/.well-known/assetlinks.json` returns the real Play fingerprint (2026-10-16).
- [ ] Add the upload-key SHA-256 (`keytool -list -v -keystore <upload.jks>` on the keystore MacBook) and enable the skipped test in `src/seo/appLinks.test.ts`. S
- [ ] First real announcement end-to-end: publish → push → notifications list → in-app pop-up (rows in the app's `docs/qa/onboarding-matrix.md`); the delivery panel shows state, attempts and counts.
- [ ] An old `https://banatalk.com/moments/<id>` share link lands on `/moment/<id>`.

## 4. Code work — open

Web announcements (plan 2026-10-13)
- [x] Data layer: app-config `platform`/`lang` args, `webTargetFor` link mapping, dismissals storage, `useWebAnnouncements` hook.
- [x] Popup component + banner component (`AnnouncementModal` hero card, `AnnouncementBanner` floating card, `useAnnouncementActions`, 5 `announcements.*` strings in 18 locales); not yet mounted.
- [x] Mount in the app shell (`AnnouncementSurfaces`: every page except /admin, pop-up once per page load, takes turns with consent bar / download pop-up / sticky banner).
- [x] Route `/announcement/:id` if the link mapper's target needs a page.
- [x] Admin console: Web platform, Pop-up/Banner display style, notify switched off when the app can't be reached, website previews use the real components.
- [x] Final-review fixes: modal image reset + max-height, "Show in app and on website" label/preview, one banner per load, no pop-up/banner on auth routes or over its own page, page Back fallback, stale-id content.
- [ ] Localize any fixed strings; live QA against a deployed backend announcement (web-only + banner).

Announcements console
- [ ] "Retry delivery" button for an exhausted `failed` send — needs the backend endpoint first (backend file). S
- [ ] Server-side search + paging — needs backend support (today the console searches the newest 200 client-side). S
- [ ] Optional "Duplicate" / archive for ended rows — needs backend. S
- [ ] Drop or reword the editor's "language targeting can't reach 2.6.1" hint once 2.7.x is the majority build. S

Localization
- [ ] Admin announcement strings are English fallbacks (`t(...) || "..."`, incl. `admin.announcements.startPassed`); add the `admin.announcements.*` keys when the admin console is localized. M

Web/app parity (spec: app `docs/superpowers/specs/2026-10-16-web-app-parity-design.md`)
- [x] Baseline: 23 local commits squashed, tests restored (moments/stories/privacy audit fixes on top of origin/main; 4 suites' expectations updated for intended changes).
Phase 3 Chat (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [x] P3-CHAT-1 Edit sends `{message}`, in an in-app dialog, with the failure shown (chat#1, chat#19)
- [x] P3-CHAT-2 Delete sends body `{deleteForEveryone}`, asks in a dialog, and "deleted for everyone" leaves a placeholder (chat#2, chat#15, chat#19)
- [x] P3-CHAT-3 Opening a chat never posts "Conversation started" (chat#3)
- [x] P3-CHAT-4 Limit, paywall and block refusals open a dialog instead of a bare "Failed" (chat#4)
- [x] P3-CHAT-5 A slow socket ack marks the bubble failed with Retry; no REST fallback, no duplicates (chat#5)
- [x] P3-CHAT-6 Conversation list from `GET /conversations` only; typed previews; unread from the server (chat#10, chat#11, chat#19)
- [x] P3-CHAT-7 Catch up after a reconnect; recover a kicked tab; refresh instead of logging out on `tokenExpired` (chat#12, chat#20)
- [x] P3-CHAT-8 Videos go through `POST /messages/video` with the server's limits checked first (chat#16)
- [x] P3-CHAT-9 Voice recorder picks a type the browser supports (AAC first), names the file to match, and sends a waveform (chat#13)
- [x] P3-CHAT-10 App call-history messages render as a call card, not "File" (chat#6)
- [x] P3-CHAT-11 Location messages render as a map card, and the web can send one (chat#7, chat#17)
- [x] P3-CHAT-12 Waves are a greeting card, only 1–3 emoji are sticker-sized, and a bare-id sender lands on the right side (chat#8)
- [x] P3-CHAT-13 Story shares, replies and reactions keep their story (chat#9)
- [x] P3-CHAT-14 Live pins, the "edited" label, the "Forwarded" chip and every correction (chat#14)
- [x] P3-CHAT-15 The app's six premium wallpapers render on web (chat#18)
- [x] P3-CHAT-16 Search the messages of a conversation (chat#17)
- [x] P3-CHAT-17 Saved (bookmarked) messages: list, open, unbookmark (chat#17)
- [x] P3-CHAT-18 Archive / unarchive conversations, and mute for 1 hour, 8 hours, 1 week or always (chat#17)
- [x] P3-CHAT-19 "You can't message this person" banner when either side blocked (chat#17)
- [x] P3-CHAT-20 The chat's remaining hard-coded English goes through `t()` (chat#19)
- [x] P3-CHAT-I18N New chat strings in all 18 locales
- [x] P3-CHAT-PUSH Push unit chat — suite 3820 pass, build green, deployed 2026-10-16 (backend message search fixed first, 2026-10-16)

Phase 3 Moments (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [x] P3-MOM-1 Post and save photo-, video- or voice-only moments (moments#4)
- [x] P3-MOM-2 The app's 20 moment gradients, same colours (moments#5)
- [x] P3-MOM-3 Remove the Title field from the composer (moments#6)
- [x] P3-MOM-4 The moment's owner can delete other people's comments (moments#9)
- [x] P3-MOM-5 Report a comment, and block an author from a moment or a comment (moments#10, moment/comment part)
- [x] P3-MOM-6 Saved moments load every page and draw every kind of moment (moments#11)
- [x] P3-MOM-7 Feed cards show mood, tags and location (moments#22)
- [x] P3-MOM-8 Comments with a GIF, a photo and no text, and mentions drawn (moments#21)
- [x] P3-MOM-9 Leftovers: `uploadMomentPhotos` typing, no `mediaType: "text"`, dead `reportMoment` (moments#23)
- [x] P3-MOM-10 Moment voice notes record `audio/mp4` where the browser can (moments#2)
- [x] P3-MOM-11 Moments text in every language: Saved Moments keys and hard-coded English (moments#24)
- [x] P3-MOM-12 a story carries one picture (moments#16)
- [x] P3-MOM-13 the story viewer shows the story's location (moments#17)
- [x] P3-MOM-14 report a story and block its author from the viewer (moments#10, story part)
- [x] P3-MOM-15 text-story font style and overlay faces match the app (moments#25)
- [x] P3-MOM-16 solid and semi plates match the app (moments#25)
- [x] P3-MOM-17 overlays honour rotation; centring stays exact; mention pills look like the app's (moments#25)
- [x] P3-MOM-18 the viewer shows a story's hashtags (moments#25)
- [x] P3-MOM-19 the viewer honours `allowReplies` and `allowSharing` (moments#25)
- [x] P3-MOM-20 the link sticker always shows the real host under its label (moments#25)
- [x] P3-MOM-I18N New moments strings in all 18 locales
- [x] P3-MOM-PUSH Push unit moments — suite 3487 pass, build green, deployed 2026-10-16

Phase 3 Community (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [x] P3-COM-1 Nearby works — real params, real fields, real profile route, privacy toggles (community#2)
- [x] P3-COM-2 @username search uses the `/auth/users` routes (community#3)
- [x] P3-COM-3 Language filter offers the whole catalog, labelled in the reader's language (community#4)
- [x] P3-COM-4 Waves inbox — archive, reveal, loadable avatars, a real "Find people" route (community#10)
- [x] P3-COM-5 Wave cap answers with a VIP dialog, not a raw English toast (community#8)
- [x] P3-COM-6 "Serious learners" segment tab (`activeWithin=7d`) (community#9)
- [x] P3-COM-7 Smart sort by default when the server offers it; reciprocal ("perfect partners") filter (community#9)
- [x] P3-COM-8 "More members like X" asks for people who speak X's language (community#11)
- [x] P3-COM-9 Today marks a card "Waved" after a wave (community#14)
- [x] P3-COM-10 Delete the dead community endpoints and wave shims (community#12)
- [x] P3-COM-11 Profile counts from `followersCount` for signed-out visitors; story ring from `hasActiveStory` (community#6, links#11)
- [x] P3-COM-12 Blocked viewers see a neutral card; follow refused by a block says so (community#5)
- [x] P3-COM-13 Community copy through `t()`, and a test that every key exists (community#13)
- [x] P3-COM-I18N New community strings in all 18 locales
- [x] P3-COM-PUSH Push unit community — suite 3359 pass, build green, deployed 2026-10-16
- [x] `/communities` is members-only (owner decision 2026-10-16): signed-out visitors go to `/login?redirect=/communities` and come back; the page left the SEO/prerender/sitemap set, `PublicCommunities` + its slice were deleted, and `nginx.routes.conf` pins `/communities` to the SPA shell so the stale prerendered `build/communities/index.html` on the droplet is never served.
- [ ] After the deploy that ships the members-only `/communities`: optionally `rm -rf build/communities` on the droplet (harmless leftover; nginx no longer serves it), and check `https://banatalk.com/communities` signed out lands on login. The backend `GET /public/communities` route is now unused by the website. S

Phase 3 Links (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase3.md`)
- [x] P3-LINK-1 Crawler rule sends link-preview bots to the backend OG cards (links#4, links#17, moments#13)
- [x] P3-LINK-2 AASA stops claiming `/chat/*` and web-only pages (links#6, links#15)
- [x] P3-LINK-3 Smart banner and app banner open the page being viewed (links#16)
- [x] P3-LINK-4 `/story/:id` page — the target of story share links (links#1, moments#1)
- [x] P3-LINK-5 Google sign-in reads the one-time `code` (links#12)
- [x] P3-LINK-6 Legal pages link to https://banatalk.com (links#19)
- [x] P3-LINK-7 Chat story cards open `/story/:id` (chat#9 follow-up, links#1)
- [x] P3-LINK-I18N New links strings in all 18 locales
- [x] P3-LINK-PUSH Push unit links — suite 3282 pass, build green, deployed 2026-10-16 (story page 200, AASA has no /chat/)
- [ ] Backend follow-up: an OG type for `story` (`/og/story/:id` returns the generic card today; the nginx rule already routes it). S
- [ ] After this web release is live: backend removes the legacy `token=` from the Google callback redirect (backend REMAINING_WORK). S
Phase 4 Reels (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [x] P4-REEL-1 Reels feed endpoint, video-config endpoint and a reel normaliser that survives 2.6.1 data
- [x] P4-REEL-2 One-time reels content-policy gate (Apple 1.2), shared with the app via `reelsPolicyAccepted`
- [x] P4-REEL-3 `/reels` grid: cursor paging, empty/unavailable states, "Create reel" entry
- [x] P4-REEL-4 Full-screen reel viewer: one playing video, muted autoplay with unmute, swipe/wheel/keys, views recorded
- [x] P4-REEL-5 Viewer actions: like, comments drawer, share, report, block
- [x] P4-REEL-6 Create a reel: video ≤ 180 s checked before upload, `isReel: true`, rollback on a failed upload
- [x] P4-REEL-7 Routes, navbar and Moments entry behind `webReelsEnabled` + `reelsEnabled`; flag-off test
- [x] P4-REEL-I18N New reels strings in all 18 locales
- [x] P4-REEL-PUSH Push unit reels (suite + build green, deployed dark, production smoke recorded) — deployed dark 2026-10-16 (suite 3991 pass)

Phase 4 Gatherings/clubs (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [x] P4-GATH-1 Gatherings + clubs endpoints in one slice, same requests the app sends
- [x] P4-GATH-2 Shared helpers: local start time, quorum line, host-decision window, error text
- [x] P4-GATH-3 Browse page: Gatherings and Clubs tabs, the app's filters, load more
- [x] P4-GATH-4 Gathering page: details, RSVP / request / leave, report or block the host
- [x] P4-GATH-5 Host a gathering: create and edit form with the backend's limits
- [x] P4-GATH-6 Host decisions: join requests, run it or call it off, cancel, end
- [x] P4-GATH-7 Club page: members and roles, join/leave, upcoming gatherings, manage members
- [x] P4-GATH-8 Create, edit and delete a club
- [x] P4-GATH-9 Optional cover photo for a gathering or a club
- [x] P4-GATH-10 Routes and nav entry behind `webGatheringsEnabled`; nothing visible while it is off
- [x] P4-GATH-I18N New gatherings/clubs strings in all 18 locales
- [x] P4-GATH-PUSH Push unit gatherings (suite + build green, deployed dark, production smoke recorded) — deployed dark 2026-10-16 (suite 4153 pass)

Phase 4 Rooms — voice rooms, language rooms, City/Genders (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [x] P4-ROOM-1 `livekit-client@2.22.4` behind a JS loader + `.d.ts`, excluded from tsconfig, kept out of the eager graph
- [x] P4-ROOM-2 `lkSession` facade (connect, mic/camera, audio unlock, peers, disconnect reasons) + the shared LiveKit test fake
- [x] P4-ROOM-3 Voice rooms REST slice (list, detail, create, join, token, leave, end, promote, RSVP)
- [x] P4-ROOM-4 Voice rooms list page with create dialog and scheduled-room RSVP
- [x] P4-ROOM-5 `useVoiceRoom`: join → token → socket → LiveKit, heartbeat, live events, rejoin after reconnect, leave
- [x] P4-ROOM-6 Voice room page: listen, take the mic, raise a hand, tap-to-enable-sound, mic-denied help, room chat
- [x] P4-ROOM-7 Host controls: raised hands, mute all, make co-host, end room
- [x] P4-ROOM-8 Language rooms REST slice + list page grouped by language + create topic room
- [x] P4-ROOM-9 Language room page: history, live messages, send with ack, presence, join/leave/request to join
- [x] P4-ROOM-10 Language room owner tools: join requests approve/deny, remove member
- [x] P4-ROOM-11 Community City and Genders tabs (community#7), same queries as the app
- [x] P4-ROOM-12 Routes and nav entries behind `webVoiceRoomsEnabled` / `webLanguageRoomsEnabled`; flag-off test (+ iOS AASA excludes /community/city and /community/genders)
- [x] P4-ROOM-I18N New rooms strings in all 18 locales
- [x] P4-ROOM-PUSH Push unit rooms (suite + build + livekit checks green, deployed dark, production smoke recorded) — deployed dark 2026-10-16 (suite 4318 pass; livekit in its own chunk). Open: bundle budget over (313.6 vs 307 KB app code); backend: voice-room speaker role/kick, raise-hand event names differ app vs backend, city search ignores location.city; German "Sprachräume" wording clash

Phase 4 Calls (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [x] Calls: website chats offer 'call in the app' (owner decision 2026-10-16: no browser calls) — deployed 2026-10-16 (suite 4351 pass); visible to everyone (not flagged)

Phase 4 Sign in with Apple (plan `bananatalk_app/docs/superpowers/plans/2026-10-16-web-app-parity-phase4.md`)
- [x] P4-APPLE-1 Apple JS loader, nonce and popup sign-in wrapper (script fetched only on click)
- [x] P4-APPLE-2 `POST /auth/apple/web` endpoint and the error text for each refusal
- [x] P4-APPLE-3 One "finish social sign-in" path shared by Google and Apple (profile completion included) — decided: new web Google sign-ups also go through the completion wizard (as in the app)
- [x] P4-APPLE-4 "Sign in with Apple" button: nonce → Apple popup → backend → signed in
- [x] P4-APPLE-5 Button on Login and Register; hidden while `webAppleSigninEnabled` is off or no Services ID is configured
- [x] P4-APPLE-I18N New Apple sign-in strings in all 18 locales
- [x] P4-APPLE-PUSH Push unit apple (suite + build green, deployed dark, production smoke recorded) — deployed dark 2026-10-16 (suite 3911 pass)
- [ ] Bundle budget: `npm run test:budget` fails -- first-paint 351.1 KB vs 326 KB budget, app code 317.6 vs 307 KB (main 661c06e was already 349.3 / 315.9; the VIP parity work below adds 1.8 KB). `npm run deploy` now runs `test:budget`, so a deploy through that script stops here until the budget or the bundle is fixed. S

VIP parity with the app (2026-10-18; backend a71aa3c / b2836ac, app d769d971)
- [x] Nearby radius 5/10/25/50/100/200 km; options above the server's `search.maxRadiusKm` (50 until it answers; VIP 500) show a lock and open `/settings/vip`
- [x] VIP page and home pricing list the real perks (no ads, unlimited AI tutor and roleplay, everyone who viewed you, 15 daily matches instead of 6, country filter, unlimited translations); the server's stale plan `features` are no longer rendered
- [x] Country filter is VIP-only: locked with a VIP badge for free members, not sent, not shown as a chip or counted (gender stays free)
- [x] Daily limits (moments, comments, stories: 429; translation: 403 `TRANSLATION_LIMIT_REACHED`) show one "Upgrade to VIP" toast (`src/components/vip/dailyLimit.tsx`)
- [x] Strangers' profiles: "Online now" / "Active today" / nothing (respects `showOnlineStatus`), no join month; the owner still sees both
- [x] "You're learning each other's language" chip on the All list
- [x] VIP status (`/auth/me`), the community list and Nearby re-read on tab focus (per query; the global `refetchOnFocus` stays off)
- [x] New strings in all 18 locales (drafts; native review with the app's batch)
- [ ] Backend: `GET /purchases/plans` still advertises unlimited messages / profile views / waves / voice rooms / premium support -- fix the source (controllers/iosPurchase.js) so the app store sheets match. S
- [ ] Chat's daily-message limit dialog still says "Go VIP for unlimited messages" (`chatPage.sendErrors.dailyBody`) -- keep only while the server enforces a free message cap. S
- [ ] Native review of the 2026-10-18 VIP strings (vip.features.*, vip.limit.*, countryVipOnly, mutualExchange, activeToday, radiusLimit). S

Language rooms — app parity (2026-10-18; backend 468fa90, app 90b4e425). Still behind `webLanguageRoomsEnabled` (+ `roomsEnabled`)
- [x] Directory: languages named from the room's code in the reader's language with a flag, hub languages first, "Active 5m ago", refresh button, "+ New room"
- [x] New room in any language: the whole ISO 639-1 list (signup picker's list, localized names), sends the code
- [x] Opening a room does not join it: visitors read the history and watch live (`room:join`), and get a "Join room" bar instead of the composer; banned users ask to come back
- [x] Room info from the title: language, members / online, description, View members (members), Edit title + description (moderators), Join / Leave; owner's requests + remove inside "View members"
- [x] Messages: avatar and name open the profile; reply with quote (`replyTo`); reactions (chat's ReactionRow, `/messages/:id/reactions`, live `messageReaction`); photo with caption (`POST /rooms/:id/media`); delete own / any for moderators (live `room:messageDeleted`); report (shared report dialog, `type: "message"`)
- [x] Daily prompt pinned as "Question of the day"; typing indicator; blocked senders hidden live; refused send keeps the text and says "Failed to send message"
- [x] New strings in all 18 locales (drafts)
- [ ] Live QA with the flag on: visitor watch → join, reply, react, photo, delete (as moderator), report, daily prompt card. S
- [ ] Native review of the 2026-10-18 `languageRooms.*` drafts. S
- [ ] Rooms show voice / GIF / sticker messages as a label ("open the app"); the web composer sends text and photos only. S

Profile Boost on the website (2026-10-18; backend routes/boosts.js, app boost_screen.dart). Behind `boostsEnabled` (no web-only flag)
- [x] `/boost` page (members only): explain (6th match, near the top of Partners, latest moment in For You), 150-coin cost + balance (`/coins/balance`, only while `coinsEnabled`), confirm; 402 → "you need 150 coins, bought in the app" + link to /download; 409 re-reads the live boost; `capacity_full` → slots-taken message
- [x] While live: 24h progress bar, time left (ticks every 30s, impressions re-read every minute), "Times shown so far: N" with Partners / Daily matches / For You breakdown, hint at 0, tips with "Post a moment"
- [x] After it ends (last ended boost within 7 days, refunds skipped): "Your last boost — times shown: N" + "Boost again"
- [x] Entry points: row at the top of the Community list ("Boost my profile" / "Your boost is live · Xh left"), and "Boost my profile" in the navbar profile menu (desktop + mobile)
- [x] "Boosted" label on community member cards and feed moments when the API sends `boosted: true` (daily matches already had it)
- [x] New `boost.*` strings in all 18 locales (drafts, non-plural phrasing)
- [ ] The website cannot buy coins: an empty wallet is sent to the app (/download). Decide whether web gets a coin shop. S
- [ ] Live QA with `BOOSTS_ENABLED=true`: buy, live card, impressions moving, ended → Boost again, entry row states, Boosted labels on another account. S
- [ ] Native review of the `boost.*` drafts. S
- [ ] Bundle budget: now 353.9 KB first paint / 319.6 KB app code (was 351.1 / 317.6) after rooms + boost; the Community boost row and its slice are in the eager graph. S

## 5. Decided / won't fix

- Audit M2: the client keeps the start < end rule on publish (the backend rejects `endsAt <= startsAt` and publish saves first); the message says to fix start or end.
- PUT on a LIVE announcement sends only translations text, `endsAt`, priority; ended rows are read-only.

## 6. Done (changelog)

- 2026-10-13 — Deployed 2ce0c93. Audit fixes: Publish-now/end rule (5e38c55, eacb9bc); scheduled-row Save re-confirms pushes with a fresh audience count, cancel reverts with one PUT; publish bar re-arms on `updatedAt`; Schedule confirm re-checks the start; image input cleared (688256b); "Stopped at end time" (5f9b4fe) and "Ended by admin" (0a75989) delivery display; `/moments/:id` redirect (83fe482). Backend `startsAt` guard landed in backend 72c2c9e.
- 2026-10-12 — Merges 906efa1 + 1cd9f44: announcements console W1–W5 (list + nav, editor with per-language text and preview, publish/schedule/end with audience confirm), delivery state + attempts + error, client search, priority column, empty states, draft delete, 2.6.1 language hint.

- [x] Sign in with Apple web: Services ID `com.bananatalk.com` (grouped with com.bananatalk.bananatalkApp) set in `.env.production` (2026-10-16); backend needs APPLE_WEB_SERVICES_ID + WEB_APPLE_SIGNIN_ENABLED.

- [x] Real logo everywhere on the website (2026-10-16): login, footer, app banner, download pop-up, invite and download pages, language card (was 🍌 / "B").
