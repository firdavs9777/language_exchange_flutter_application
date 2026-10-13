# Web announcements — design

Date: 2026-10-13. Status: approved in conversation, pending written-spec review.
Repos: backend (small, additive), web front (new UI), web admin (form + preview). **App: no change.**

## 1. Goal

Admin announcements (built 2026-10-12, live in the mobile app) also reach people on banatalk.com, with a modern look:

- a **pop-up** (hero card) for big news, and
- a **banner** (floating card under the navbar) for small notices that shouldn't interrupt.

The admin picks the style per announcement. Everyone sees them, logged in or not; acting on one (button / "Read more") requires login.

Success: an admin can publish a web announcement, choose pop-up or banner, preview both, and visitors see exactly one pop-up and at most one banner, in their language, without anything changing for mobile app users.

## 2. Decisions (from the conversation)

| # | Decision |
|---|---|
| D1 | Display style is chosen per announcement: `popup` or `banner`. **Website only**; the app keeps its pop-up and is not changed. |
| D2 | Everyone on the website sees announcements, including logged-out visitors on public pages. A logged-out click on the button or "Read more" goes to login, then back. |
| D3 | When several are live: the highest-priority pop-up and the highest-priority banner only. Closing one lets the next show on a later page load. |
| D4 | Data comes from the public `/app-config` the website already loads, with `platform=web&lang=<site language>`. Closing is remembered per announcement in the browser (localStorage). |
| D5 | Pop-up look: **hero card** (mockup A): image header (or teal gradient + emoji), NEW tag, title, body, primary button, "Read more", ✕. |
| D6 | Banner look: **floating card** (mockup B of the banner screen) restyled to match the hero card: emoji tile, title, one-line text, button, ✕. |

## 3. No impact on the mobile app (hard requirement)

The app (2.6.1 live, 2.7.0 pending) must see **exactly** what it sees today. Guarantees and the test that pins each:

1. **Web-only announcements never reach app clients.** `matchesPlatform` already excludes them: the app sends `platform=ios|android` (2.7.0) or nothing (2.6.1, which only gets `all`/empty). Test: a `platforms:['web']` announcement is absent from app-config for `platform=ios`, `android` and no platform, in both the `announcements` list and the legacy `announcement` field.
2. **Banner-style announcements never reach app clients**, even when targeted at `all`, because the app would show them as a pop-up. app-config filters `displayStyle: 'banner'` out unless `platform=web`. Test: an `all`-platform banner is absent for ios/android/none and present for web.
3. **Pop-up announcements targeted at `all` behave as today in the app.** The only response change is an extra `displayStyle` field per item, which the app's `Announcement.fromJson` ignores (unknown keys are dropped). Test: response for `platform=ios` equals today's shape plus `displayStyle`.
4. **Delivery (push + notifications-list rows) never targets the web.** `web` is removed from the platforms used by `audienceQuery` (otherwise `signupPlatform: 'web'` users who also use the app would get rows/pushes for a web-only announcement). Delivery runs only when the announcement is a `popup` that targets at least one mobile platform (`all`, `ios` or `android`); otherwise delivery is skipped entirely (no rows, no push, state stays `none`). Tests: `['web']` → no delivery; `['web','ios']` → iOS audience only; banner with `notify:true` → no delivery.
5. **Existing documents** have no `displayStyle`; the default `popup` keeps them identical. No migration.
6. **No app code, ARB or release change.** The 2.7.0 build is untouched.

## 4. Backend

- `models/Announcement.js`
  - `PLATFORMS = ['all', 'ios', 'android', 'web']`.
  - `displayStyle: { type: String, enum: ['popup', 'banner'], default: 'popup' }`.
- `services/announcementService.js`
  - `liveAnnouncementsFor` gains the banner rule (D3/§3.2): drop `displayStyle === 'banner'` unless `platform === 'web'`.
  - `toPublic` adds `displayStyle`.
  - `audienceQuery` ignores `web`; a helper `deliversToApp(doc)` (popup + a mobile platform) gates delivery.
- `services/announcementDelivery.js` / `jobs/announcementJob.js`: skip docs where `deliversToApp` is false (never claimed, state stays `none`).
- `controllers/adminAnnouncements.js`: `displayStyle` editable while draft/scheduled (same lock rules as targeting); audience-count endpoint returns 0 with `reason: 'web_only'` when `deliversToApp` is false.
- `controllers/appConfig.js`: `platform=web` is a recognised value; the legacy `announcement` field is still built only from what the caller may see (so a web caller's legacy field may be a banner — harmless, the website reads the list).
- `GET /announcements/:id` (auth required) unchanged; it already returns any live announcement by id.

## 5. Website (user-facing)

New folder `src/components/announcements/`:

- `useWebAnnouncements()` — reads `useGetAppConfigQuery({ platform: 'web', lang })` (site language from i18next), splits into `popup` / `banner` lists, removes ones dismissed in localStorage key `bt_ann_dismissed_v1` (array of ids, capped at 50, try/catch, works without storage).
- `AnnouncementModal` — hero card (D5). Opens once per page load, only on the first route the visitor lands on. Esc and ✕ close and dismiss; clicking the backdrop closes without dismissing (shows again next visit). Focus trapped, `role="dialog"`, `aria-labelledby`. Phone: full-width bottom sheet style; desktop: centred 420px card. Dark mode via existing tokens.
- `AnnouncementBanner` — floating card under the navbar (D6), on every page until ✕. One line of body, ellipsized; whole card is not a link (only the button).
- Surface registration: both register in the existing `growth/surfaceRegistry` so they take turns with `AppDownloadPopup`, `StickyAppBanner` and `ConsentBar` (the announcement pop-up waits for the consent bar to be answered and outranks the app-download pop-up; the banner hides the sticky app banner while shown).
- Actions:
  - Primary button: `https://` → new tab (`rel="noopener noreferrer"`); `bananatalk://<path>` → mapped web route where one exists (`moment/:id`, `profile/:id`, `community/:id`, `i/:code`, `announcement/:id`), otherwise the button is hidden.
  - "Read more" → `/announcement/:id`.
  - Logged-out: both actions go to `/login?next=<target>`; after login the target opens.
- New route `/announcement/:id` (login required; RequireAuth with `next`): fetches `GET /api/v1/announcements/:id?lang=`, shows image, emoji, title, full body (plain text, line breaks kept, no HTML), button. 404 → friendly "This announcement has ended".
- Text: the API already returns the translated title/body for `lang`; UI chrome strings ("Read more", "New", "Close", "This announcement has ended") go into the web's i18n files for all supported languages, English fallback.
- RTL: inherits `dir` from the existing i18n setup.
- Not shown on `/admin/*` routes.

## 6. Web admin

- Platform picker: add **Web**.
- New **Display style** control: Pop-up / Banner, with the note "Website only — the mobile app always shows a pop-up". Banner + no web platform selected shows a warning ("A banner only appears on the website; add Web or All").
- "Send notification" is disabled with an explanation when the announcement won't deliver to the app (banner, or web-only).
- Previews: add **Website pop-up** and **Website banner** next to the existing app preview, rendering the real `AnnouncementModal` / `AnnouncementBanner` components in preview mode (no dismissal, no navigation).

## 7. Error handling

- app-config failure or timeout → no announcements (already degrades to `[]`).
- Missing/invalid image → gradient header.
- localStorage unavailable → dismissal lasts for the page session only.
- Unknown `displayStyle` value from the server → treated as `popup`.

## 8. Testing

- Backend: §3 tests 1–5; model enum/default; admin edit lock for `displayStyle`; audience count `web_only`.
- Website (jest/RTL): hook filtering and dismissal; modal open-once, Esc/✕/backdrop behaviour, focus; banner render and dismiss; logged-out redirect with `next`; link mapping table; `/announcement/:id` success/404/logged-out; surface-registry ordering with consent bar and app-download pop-up; not on `/admin`.
- Admin: form fields, warnings, notify disabled, previews render.
- Full suites + web production build. Deploy backend → web. App untouched.

## 9. Out of scope

- Banner style in the mobile app (later release, same field).
- Server-side dismissal sync across devices.
- Showing announcements in the website's notification list.
