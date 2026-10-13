# Web Announcements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show admin announcements on banatalk.com as a hero-card pop-up or a floating banner (chosen per announcement), with zero change for mobile app users.

**Architecture:** The backend gains a `web` platform and a `displayStyle` field, and a pure helper decides whether an announcement can reach the app (only those get pushes/list rows and only those appear in app-config for app callers). The website reads `/app-config?platform=web&lang=` (already public), filters out ones dismissed in localStorage, and renders one pop-up and one banner through the existing growth surface registry. The admin form gets the new controls and website previews that render the real components.

**Tech Stack:** Backend Node/Express/Mongoose, `node:test` + mongodb-memory-server. Web: React 18 + TypeScript, Redux Toolkit Query, react-router v6, i18next, Tailwind, jest + Testing Library (CRA `react-scripts test`).

**Spec:** `bananatalk_app/docs/superpowers/specs/2026-10-13-web-announcements-design.md` (app repo).

## Global Constraints

- **App: no change.** No file under the Flutter app repo changes except docs. App callers (`platform=ios|android|<none>`) must get exactly today's announcements; the only response change for them is an extra `displayStyle` key on list items.
- `displayStyle` values: `'popup' | 'banner'`, default `'popup'`. Unknown value on the web → treat as `'popup'`.
- `PLATFORMS = ['all', 'ios', 'android', 'web']`.
- An announcement **reaches the app** iff `displayStyle !== 'banner'` AND its platforms are empty or include `all`, `ios` or `android`. Only such announcements may have `notify: true`, be delivered (push + list rows), or appear in app-config for non-web callers.
- Web dismissal storage key: `bt_ann_dismissed_v1` (JSON array of ids, newest last, capped at 50). Every storage access in try/catch.
- Login redirect: the web's Login reads `?redirect=` (not `next`). Use `/login?redirect=<encodeURIComponent(path)>`.
- Web locales: `src/utils/locales/{eng,kor,zho,zh_TW,ar,de,es,fr,hi,id,it,ja,pt,ru,th,tl,tr,vi}.json` — a parity test requires every key in every file.
- Commits: **no `Co-Authored-By` trailer, no AI attribution.** Every commit updates that repo's `docs/REMAINING_WORK.md` (tick/add items) and lists still-open items in the commit body.
- Backend tests run one file at a time: `node --experimental-test-module-mocks --test --test-force-exit test/<file>` (`npm test` is broken under Node 25). Web tests: `CI=true npx react-scripts test --watchAll=false <pattern>`; build check `CI=false npm run build`.
- Ruling vs spec §5: instead of "the pop-up waits for the consent bar to be answered", the consent bar **steps aside while the announcement pop-up is open**, exactly as it already does for the download pop-up (same mechanism, less new code).
- Ruling vs spec §4: rather than skipping delivery at run time only, the model **forces `notify = false`** when the announcement can't reach the app, and `deliver()` also refuses such a doc (belt and braces). Outcome is the spec's: no rows, no push, delivery state stays `none`.
- Ruling: for `platform=web`, the env-var fallback announcement (`ANNOUNCEMENT_*`, written for the app) is **not** used.

## Review Focus

1. A `platforms:['all']`, `displayStyle:'banner'` announcement with `notify:true` sent by an admin API call (not the form) → saved with `notify:false`, never delivered, absent for app callers. (Task 1 + Task 2 tests.)
2. `platforms:['web','ios']` with notify → only iOS users are pushed; `signupPlatform:'web'` users without an iOS token are not targeted. (Task 3 test.)
3. localStorage throws (Safari private mode) → pop-up and banner still render; ✕ hides for this page session; no crash. (Task 4 + Task 5 tests.)
4. A logged-out visitor clicks "Read more" → `/login?redirect=%2Fannouncement%2F<id>`; after login, the page opens. (Task 5 + Task 7 tests.)
5. Announcement with an `imageUrl` that 404s → hero header falls back to the gradient + emoji, no broken-image icon. (Task 5 test.)

---

## File Structure

Backend (`language_exchange_backend_application`):
- Create `lib/announcementReach.js` — pure `reachesApp(doc)` / `appPlatformsOf(doc)`.
- Modify `models/Announcement.js` — `web` platform, `displayStyle`, force `notify=false` when `!reachesApp`.
- Modify `services/announcementService.js` — `toPublic` adds `displayStyle`; `liveAnnouncementsFor` filters by reach for non-web callers; `audienceQuery` drops `web`.
- Modify `controllers/appConfig.js` — no env fallback for `platform=web`.
- Modify `controllers/adminAnnouncements.js` — `displayStyle` editable (pre-live), audience count `reason`.
- Modify `services/announcementDelivery.js` — refuse to deliver a doc that can't reach the app.
- Tests: `test/announcementReach.test.js` (new), `test/announcementModel.test.js`, `test/appConfigAnnouncements.test.js`, `test/announcementService.test.js`, `test/adminAnnouncements.crud.test.js`, `test/announcementDelivery.test.js`.

Web (`language_exchange_web_front`):
- Modify `src/store/slices/appConfigSlice.ts` — query args `{ platform, lang }`, typed `PublicAnnouncement`.
- Create `src/components/announcements/announcementLinks.ts` — pure link mapping.
- Create `src/components/announcements/dismissals.ts` — pure localStorage helpers.
- Create `src/components/announcements/useWebAnnouncements.ts` — hook.
- Create `src/components/announcements/AnnouncementModal.tsx`, `AnnouncementBanner.tsx`, `AnnouncementSurfaces.tsx`.
- Create `src/components/announcements/AnnouncementPage.tsx` + slice endpoint in `src/store/slices/announcementsSlice.ts`.
- Modify `src/App.tsx`, `src/router/routes.tsx`, `src/components/growth/ConsentBar.tsx`, `src/components/growth/AppDownloadPopup.tsx`, `src/components/growth/StickyAppBanner.tsx`, `src/components/growth/surfaceRegistry.ts`.
- Modify all 18 `src/utils/locales/*.json` (new `announcements.*` keys).
- Modify admin: `src/store/slices/adminSlice.ts`, `src/components/admin/parts/announcementForm.ts`, `src/components/admin/pages/AdminAnnouncementEditor.tsx`, `src/components/admin/parts/AnnouncementPublishBar.tsx` (audience reason text).

---

### Task 1: Backend — reach helper, `web` platform, `displayStyle`

**Files:**
- Create: `lib/announcementReach.js`
- Modify: `models/Announcement.js` (PLATFORMS line ~23; schema near `platforms` ~line 52; `pre('validate')` ~line 94)
- Test: `test/announcementReach.test.js` (new), `test/announcementModel.test.js`

**Interfaces:**
- Produces: `reachesApp(doc) -> boolean`, `appPlatformsOf(doc) -> string[]` from `lib/announcementReach.js`; `Announcement.DISPLAY_STYLES = ['popup','banner']`; schema field `displayStyle`.

- [ ] **Step 1: Write the failing tests**

`test/announcementReach.test.js`:
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { reachesApp, appPlatformsOf } = require('../lib/announcementReach');

test('popup on all/ios/android/empty reaches the app', () => {
  for (const platforms of [['all'], ['ios'], ['android'], [], undefined, ['web', 'ios']]) {
    assert.equal(reachesApp({ platforms, displayStyle: 'popup' }), true, JSON.stringify(platforms));
  }
  assert.equal(reachesApp({ platforms: ['all'] }), true, 'missing displayStyle = popup');
});

test('banner never reaches the app; web-only never reaches the app', () => {
  assert.equal(reachesApp({ platforms: ['all'], displayStyle: 'banner' }), false);
  assert.equal(reachesApp({ platforms: ['web'], displayStyle: 'popup' }), false);
});

test('appPlatformsOf drops web', () => {
  assert.deepEqual(appPlatformsOf({ platforms: ['web', 'ios'] }), ['ios']);
  assert.deepEqual(appPlatformsOf({ platforms: ['web'] }), []);
  assert.deepEqual(appPlatformsOf({ platforms: ['all'] }), ['all']);
  assert.deepEqual(appPlatformsOf({}), []);
});
```

Append to `test/announcementModel.test.js` (reuse its existing DB setup and helper that builds a valid doc; if the file names it differently, use the same `translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en'` shape):
```js
test('displayStyle defaults to popup and accepts banner; web is a platform', async () => {
  const a = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en' });
  assert.equal(a.displayStyle, 'popup');
  const b = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', displayStyle: 'banner', platforms: ['web'] });
  assert.equal(b.displayStyle, 'banner');
  await assert.rejects(Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', displayStyle: 'toast' }));
});

test('notify is forced off when the announcement cannot reach the app', async () => {
  const banner = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', displayStyle: 'banner', notify: true });
  assert.equal(banner.notify, false);
  const webOnly = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', platforms: ['web'], notify: true });
  assert.equal(webOnly.notify, false);
  const app = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', platforms: ['web', 'android'], notify: true });
  assert.equal(app.notify, true);
});
```

- [ ] **Step 2: Run to verify they fail**

Run: `node --experimental-test-module-mocks --test --test-force-exit test/announcementReach.test.js` → FAIL (`Cannot find module '../lib/announcementReach'`).
Run: `node --experimental-test-module-mocks --test --test-force-exit test/announcementModel.test.js` → new tests FAIL.

- [ ] **Step 3: Implement**

`lib/announcementReach.js`:
```js
'use strict';

/**
 * Whether an announcement can reach the mobile app (spec 2026-10-13 §3).
 * The app always shows a pop-up and knows nothing about banners or the web,
 * so a banner, or one targeted only at the web, must never be delivered to
 * app users or listed in app-config for app callers.
 */
const APP_PLATFORMS = ['all', 'ios', 'android'];

function appPlatformsOf(doc) {
  return (doc.platforms || []).filter((p) => APP_PLATFORMS.includes(p));
}

function reachesApp(doc) {
  if ((doc.displayStyle || 'popup') === 'banner') return false;
  const platforms = doc.platforms || [];
  return platforms.length === 0 || appPlatformsOf(doc).length > 0;
}

module.exports = { reachesApp, appPlatformsOf, APP_PLATFORMS };
```

`models/Announcement.js`:
- Change `const PLATFORMS = ['all', 'ios', 'android'];` to `const PLATFORMS = ['all', 'ios', 'android', 'web'];`
- Add below it: `const DISPLAY_STYLES = ['popup', 'banner'];`
- Add `const { reachesApp } = require('../lib/announcementReach');` next to the other requires.
- Add to the schema right after `platforms`:
```js
  // How the WEBSITE shows it (spec 2026-10-13). The app always shows a
  // pop-up; a banner never reaches the app (lib/announcementReach.js).
  displayStyle: { type: String, enum: DISPLAY_STYLES, default: 'popup' },
```
- At the end of the `pre('validate')` function body, before `next();`:
```js
  // Only an announcement that can reach the app may push or write list rows.
  if (this.notify && !reachesApp(this)) this.notify = false;
```
- Add `AnnouncementSchema.statics.DISPLAY_STYLES = DISPLAY_STYLES;` with the other statics.

- [ ] **Step 4: Run tests to verify they pass**

Run both files again → PASS. Also run `test/adminAnnouncements.crud.test.js`, `test/adminAnnouncements.publish.test.js`, `test/announcementJob.test.js` → PASS (unchanged behaviour for popup/all).

- [ ] **Step 5: Commit**

Update `docs/REMAINING_WORK.md` (§4 Announcements: add "[ ] Web announcements — backend (Task 1 of plan 2026-10-13) in progress" or tick when all backend tasks land).
```bash
git add lib/announcementReach.js models/Announcement.js test/announcementReach.test.js test/announcementModel.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): web platform and displayStyle; only app-reachable announcements may notify"
```

---

### Task 2: Backend — app-config and service filtering (the no-impact guarantees)

**Files:**
- Modify: `services/announcementService.js` (`toPublic` ~line 29; `liveAnnouncementsFor` ~line 56; `audienceQuery` ~line 76)
- Modify: `controllers/appConfig.js` (env fallback block ~line 92-104 of the handler: `if (announcements.length === 0 && envAnnouncement.active)`)
- Test: `test/appConfigAnnouncements.test.js`, `test/announcementService.test.js`

**Interfaces:**
- Consumes: `reachesApp`, `appPlatformsOf` (Task 1).
- Produces: public announcement shape gains `displayStyle: 'popup'|'banner'`.

- [ ] **Step 1: Write the failing tests** — append to `test/appConfigAnnouncements.test.js` (it already has `live(over)` and `call(query)`):

```js
test('no app impact: web-only and banner announcements never reach app callers', async () => {
  const appPopup = await live({ priority: 1 });
  await live({ priority: 9, platforms: ['web'] });
  await live({ priority: 8, displayStyle: 'banner' });
  for (const query of [{ platform: 'ios' }, { platform: 'android' }, {}]) {
    const { body } = await call(query);
    assert.deepEqual(body.data.announcements.map((x) => x.id), [String(appPopup._id)], JSON.stringify(query));
    assert.equal(body.data.announcement.id, String(appPopup._id), JSON.stringify(query));
  }
});

test('no app impact: app callers see today\'s shape plus displayStyle', async () => {
  await live({ priority: 1, emoji: '🎉' });
  const { body } = await call({ platform: 'ios' });
  assert.deepEqual(Object.keys(body.data.announcements[0]).sort(),
    ['body', 'buttonLabel', 'buttonUrl', 'displayStyle', 'emoji', 'id', 'imageUrl', 'priority', 'title']);
  assert.equal(body.data.announcements[0].displayStyle, 'popup');
  assert.deepEqual(Object.keys(body.data.announcement).sort(),
    ['active', 'body', 'buttonLabel', 'buttonUrl', 'emoji', 'id', 'title']);
});

test('web callers get web, all-platform popups and banners, with displayStyle', async () => {
  const banner = await live({ priority: 5, displayStyle: 'banner' });
  const webPopup = await live({ priority: 4, platforms: ['web'] });
  const allPopup = await live({ priority: 3 });
  await live({ priority: 9, platforms: ['ios'] });
  const { body } = await call({ platform: 'web', lang: 'en' });
  assert.deepEqual(body.data.announcements.map((x) => [x.id, x.displayStyle]), [
    [String(banner._id), 'banner'], [String(webPopup._id), 'popup'], [String(allPopup._id), 'popup'],
  ]);
});

test('web callers never get the env fallback announcement', async () => {
  Object.assign(process.env, { ANNOUNCEMENT_ACTIVE: 'true', ANNOUNCEMENT_ID: 'env-1', ANNOUNCEMENT_TITLE: 'Env', ANNOUNCEMENT_BODY: 'From env' });
  const { body } = await call({ platform: 'web' });
  assert.deepEqual(body.data.announcements, []);
});
```

Append to `test/announcementService.test.js` (use its existing requires; add `const { audienceQuery } = require('../services/announcementService');` if not already destructured):
```js
test('audienceQuery ignores web: web-only targets nobody by platform, web+ios targets ios only', () => {
  const webIos = audienceQuery({ platforms: ['web', 'ios'], languages: [] });
  const json = JSON.stringify(webIos);
  assert.ok(json.includes('"ios"'));
  assert.ok(!json.includes('"web"'));
  const webOnly = audienceQuery({ platforms: ['web'], languages: [] });
  assert.ok(JSON.stringify(webOnly).includes('"$in":[]'), 'web-only matches no platform');
});
```

- [ ] **Step 2: Run to verify they fail**

`node --experimental-test-module-mocks --test --test-force-exit test/appConfigAnnouncements.test.js` → the 4 new tests FAIL.
`... test/announcementService.test.js` → new test FAILS.

- [ ] **Step 3: Implement**

`services/announcementService.js`:
- Add `const { reachesApp, appPlatformsOf } = require('../lib/announcementReach');`
- In `toPublic`, add after `priority: doc.priority || 0,`:
```js
    displayStyle: doc.displayStyle === 'banner' ? 'banner' : 'popup',
```
- In `liveAnnouncementsFor`, replace the `.filter(...)` line with:
```js
    .filter((d) => matchesPlatform(d, platform) && fitsLanguage(d)
      // App callers (ios/android/none) only ever see what the app can show.
      && (platform === 'web' || reachesApp(d)))
```
- In `audienceQuery`, replace
```js
  const platforms = doc.platforms || [];
  if (platforms.length && !platforms.includes('all')) {
```
with
```js
  // Delivery is app-only: the web has no push and no notification list.
  const platforms = appPlatformsOf(doc);
  if ((doc.platforms || []).length && !platforms.includes('all')) {
```
(the inner `$in: platforms` now uses the filtered list; a web-only doc yields `$in: []`, matching no one.)

`controllers/appConfig.js`: change
```js
  if (announcements.length === 0 && envAnnouncement.active) {
```
to
```js
  // The env announcement is written for the app; the website never shows it.
  if (announcements.length === 0 && envAnnouncement.active && platform !== 'web') {
```

- [ ] **Step 4: Run tests to verify they pass**

Run `test/appConfigAnnouncements.test.js`, `test/announcementService.test.js`, `test/announcementDetail.test.js`, `test/announcementDelivery.test.js` → all PASS.

- [ ] **Step 5: Commit**
```bash
git add services/announcementService.js controllers/appConfig.js test/appConfigAnnouncements.test.js test/announcementService.test.js docs/REMAINING_WORK.md
git commit -m "feat(app-config): platform=web returns web announcements with displayStyle; app callers unchanged"
```

---

### Task 3: Backend — admin editing, audience count reason, delivery guard

**Files:**
- Modify: `controllers/adminAnnouncements.js` (`EDITABLE` ~line 23; `getAudienceCount` ~line 217)
- Modify: `services/announcementDelivery.js` (`deliver()` entry, before `claim`)
- Test: `test/adminAnnouncements.crud.test.js`, `test/announcementDelivery.test.js`

**Interfaces:**
- Consumes: `reachesApp` (Task 1).
- Produces: `GET /admin/announcements/:id/audience-count` → `{ count, listed, reason? }` where `reason === 'web_only'` when the announcement can't reach the app (then `count = listed = 0`). `displayStyle` accepted by POST/PUT while draft/scheduled; rejected (400, existing message) while live.

- [ ] **Step 1: Write the failing tests**

Append to `test/adminAnnouncements.crud.test.js` (it has helpers to call the controller as admin; follow the file's existing `create`/`update` call pattern — e.g. `asHandler(c.createAnnouncement)({ body, user: admin })`):
```js
test('displayStyle is editable before live and rejected while live', async () => {
  const created = await callCreate({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', displayStyle: 'banner', platforms: ['web'] });
  assert.equal(created.body.data.displayStyle, 'banner');
  const id = created.body.data.id;
  const upd = await callUpdate(id, { displayStyle: 'popup' });
  assert.equal(upd.body.data.displayStyle, 'popup');
  await Announcement.updateOne({ _id: id }, { status: 'live', startsAt: new Date(Date.now() - 1000) });
  const live = await callUpdate(id, { displayStyle: 'banner' });
  assert.equal(live.status, 400);
});

test('audience count is 0 with reason web_only for a banner or web-only announcement', async () => {
  await User.create({ ...userFixture('w1'), signupPlatform: 'web' });
  const banner = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', displayStyle: 'banner' });
  const res = await callAudience(String(banner._id));
  assert.deepEqual(res.body.data, { count: 0, listed: 0, reason: 'web_only' });
});
```
(If the file has no `callCreate/callUpdate/callAudience/userFixture` helpers, add them at the top using the same `asHandler` + admin `req.user` the existing tests use.)

Append to `test/announcementDelivery.test.js` (it already creates live announcements and users with tokens):
```js
test('deliver refuses an announcement that cannot reach the app', async () => {
  const doc = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', status: 'live', startsAt: new Date(Date.now() - 1000), platforms: ['web'] });
  // Bypass the model's notify normalisation to prove the delivery guard itself.
  await Announcement.collection.updateOne({ _id: doc._id }, { $set: { notify: true, 'delivery.state': 'queued' } });
  await announcementDelivery.deliver(doc._id);
  const after = await Announcement.findById(doc._id).lean();
  assert.equal(after.delivery.state, 'queued');
  assert.equal(after.delivery.attempts || 0, 0);
});

test('web+ios targets only users on ios (token or signup), not web signups', async () => {
  const iosUser = await makeUser({ fcmTokens: [{ token: 'tok-ios', platform: 'ios', active: true }] });
  const webUser = await makeUser({ signupPlatform: 'web' });
  const doc = await Announcement.create({ translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', status: 'live', startsAt: new Date(Date.now() - 1000), platforms: ['web', 'ios'], notify: true });
  await announcementDelivery.deliver(doc._id);
  const rows = await Notification.find({ 'data.announcementId': String(doc._id) }).lean();
  const users = rows.map((r) => String(r.user));
  assert.ok(users.includes(String(iosUser._id)));
  assert.ok(!users.includes(String(webUser._id)));
});
```
(Use the file's existing user factory and notification model/field names — check how existing tests assert rows, and match that query exactly.)

- [ ] **Step 2: Run to verify they fail**

Run both files → new tests FAIL.

- [ ] **Step 3: Implement**

`controllers/adminAnnouncements.js`:
- Add `'displayStyle'` to `EDITABLE` (not to `LIVE_EDITABLE`).
- Add `const { reachesApp } = require('../lib/announcementReach');`
- At the top of `getAudienceCount` after the `notFound` check:
```js
  if (!reachesApp(doc)) {
    // Banner or web-only: the website shows it, but nobody gets a push or a list row.
    return res.status(200).json({ success: true, data: { count: 0, listed: 0, reason: 'web_only' } });
  }
```

`services/announcementDelivery.js`, at the start of `deliver(announcementId, ...)` before the claim:
```js
  const target = await Announcement.findById(announcementId).select('platforms displayStyle').lean();
  // Belt and braces with the model's notify rule: never deliver what the app can't show.
  if (!target || !reachesApp(target)) return { delivered: false, reason: 'not_app' };
```
and `const { reachesApp } = require('../lib/announcementReach');` at the top. (Keep the function's existing return shape for other paths; if `deliver` returns nothing elsewhere, return `undefined` here instead.)

- [ ] **Step 4: Run tests to verify they pass**

Run `test/adminAnnouncements.crud.test.js`, `test/adminAnnouncements.publish.test.js`, `test/announcementDelivery.test.js`, `test/announcementJob.test.js` → PASS.

- [ ] **Step 5: Commit** (REMAINING_WORK: backend part done; list web tasks as open)
```bash
git add controllers/adminAnnouncements.js services/announcementDelivery.js test/adminAnnouncements.crud.test.js test/announcementDelivery.test.js docs/REMAINING_WORK.md
git commit -m "feat(admin-announcements): displayStyle editable pre-live; web-only audience reason; delivery refuses non-app announcements"
```

---

### Task 4: Web — data layer: app-config args, links, dismissals, hook

**Files:**
- Modify: `src/store/slices/appConfigSlice.ts`
- Create: `src/components/announcements/announcementLinks.ts`, `dismissals.ts`, `useWebAnnouncements.ts`
- Test: `src/components/announcements/announcementLinks.test.ts`, `dismissals.test.ts`, `useWebAnnouncements.test.tsx`

**Interfaces:**
- Produces:
  - `export interface PublicAnnouncement { id: string; title: string; body: string; emoji: string | null; imageUrl: string | null; buttonLabel: string | null; buttonUrl: string | null; priority: number; displayStyle: "popup" | "banner"; }` (in `appConfigSlice.ts`)
  - `useGetAppConfigQuery(args?: { platform?: string; lang?: string })` — existing no-arg callers keep working.
  - `webTargetFor(buttonUrl: string | null): { kind: "external"; href: string } | { kind: "internal"; path: string } | null`
  - `readDismissed(): string[]`, `dismiss(id: string): void`, `isDismissed(id: string): boolean`, `DISMISS_KEY = "bt_ann_dismissed_v1"`
  - `useWebAnnouncements(): { popup: PublicAnnouncement | null; banner: PublicAnnouncement | null; dismiss: (id: string) => void }`

- [ ] **Step 1: Write the failing tests**

`announcementLinks.test.ts`:
```ts
import { webTargetFor } from "./announcementLinks";

test.each([
  ["https://example.com/x", { kind: "external", href: "https://example.com/x" }],
  ["http://example.com", { kind: "external", href: "http://example.com" }],
  ["bananatalk://moment/abc", { kind: "internal", path: "/moment/abc" }],
  ["bananatalk://moments/abc", { kind: "internal", path: "/moment/abc" }],
  ["bananatalk://profile/u1", { kind: "internal", path: "/profile/u1" }],
  ["bananatalk://community/u1", { kind: "internal", path: "/community/u1" }],
  ["bananatalk://i/CODE", { kind: "internal", path: "/i/CODE" }],
  ["bananatalk://announcement/a1", { kind: "internal", path: "/announcement/a1" }],
  ["bananatalk://study", null],
  ["bananatalk://", null],
  ["javascript:alert(1)", null],
  ["", null],
  [null, null],
])("%s", (url, expected) => {
  expect(webTargetFor(url as any)).toEqual(expected);
});
```

`dismissals.test.ts`:
```ts
import { readDismissed, dismiss, isDismissed, DISMISS_KEY } from "./dismissals";

beforeEach(() => window.localStorage.clear());

test("dismiss remembers ids, newest last, capped at 50", () => {
  for (let i = 0; i < 55; i++) dismiss(`id${i}`);
  const ids = readDismissed();
  expect(ids).toHaveLength(50);
  expect(ids[0]).toBe("id5");
  expect(isDismissed("id54")).toBe(true);
  expect(isDismissed("id0")).toBe(false);
});

test("corrupt storage reads as empty", () => {
  window.localStorage.setItem(DISMISS_KEY, "{not json");
  expect(readDismissed()).toEqual([]);
});

test("storage that throws never crashes; dismissal lasts for this page session", () => {
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
  const spy2 = jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => { throw new Error("blocked"); });
  expect(() => dismiss("x")).not.toThrow();
  expect(isDismissed("x")).toBe(true);
  spy.mockRestore(); spy2.mockRestore();
});
```

`useWebAnnouncements.test.tsx`:
```tsx
import { renderHook, act } from "@testing-library/react";
import { useWebAnnouncements } from "./useWebAnnouncements";

const mockQuery = jest.fn();
jest.mock("../../store/slices/appConfigSlice", () => ({ useGetAppConfigQuery: (...a: any[]) => mockQuery(...a) }));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ i18n: { language: "ko" } }) }));

const a = (id: string, displayStyle: string, priority = 0) =>
  ({ id, title: id, body: "b", emoji: "🎉", imageUrl: null, buttonLabel: null, buttonUrl: null, priority, displayStyle });

beforeEach(() => { window.localStorage.clear(); mockQuery.mockReset(); });

test("asks app-config for platform=web in the site language", () => {
  mockQuery.mockReturnValue({ data: { announcements: [] } });
  renderHook(() => useWebAnnouncements());
  expect(mockQuery).toHaveBeenCalledWith({ platform: "web", lang: "ko" });
});

test("first popup and first banner (server order = priority); unknown style is a popup", () => {
  mockQuery.mockReturnValue({ data: { announcements: [a("b1", "banner", 9), a("p1", "weird", 8), a("p2", "popup", 1), a("b2", "banner", 0)] } });
  const { result } = renderHook(() => useWebAnnouncements());
  expect(result.current.popup!.id).toBe("p1");
  expect(result.current.banner!.id).toBe("b1");
});

test("dismissed ones are skipped and dismiss moves to the next", () => {
  mockQuery.mockReturnValue({ data: { announcements: [a("b1", "banner"), a("b2", "banner")] } });
  const { result } = renderHook(() => useWebAnnouncements());
  act(() => result.current.dismiss("b1"));
  expect(result.current.banner!.id).toBe("b2");
});

test("no data or error → nothing", () => {
  mockQuery.mockReturnValue({ data: undefined, isError: true });
  const { result } = renderHook(() => useWebAnnouncements());
  expect(result.current.popup).toBeNull();
  expect(result.current.banner).toBeNull();
});
```

- [ ] **Step 2: Run to verify they fail**

`CI=true npx react-scripts test --watchAll=false src/components/announcements` → FAIL (modules missing).

- [ ] **Step 3: Implement**

`src/store/slices/appConfigSlice.ts` — replace the endpoint and add the type:
```ts
/** One live announcement as app-config returns it (backend services/announcementService.js toPublic). */
export interface PublicAnnouncement {
  id: string;
  title: string;
  body: string;
  emoji: string | null;
  imageUrl: string | null;
  buttonLabel: string | null;
  buttonUrl: string | null;
  priority: number;
  displayStyle: "popup" | "banner";
}

export interface AppConfigArgs { platform?: string; lang?: string }

export const appConfigApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getAppConfig: builder.query({
      query: (args?: AppConfigArgs) => {
        const params = new URLSearchParams();
        if (args && args.platform) params.set("platform", args.platform);
        if (args && args.lang) params.set("lang", args.lang);
        const qs = params.toString();
        return { url: `/api/v1/app-config${qs ? `?${qs}` : ""}` };
      },
      transformResponse: (response: any): AppConfig => (response && response.data) || {},
      keepUnusedDataFor: 300,
    }),
  }),
});
```
(Add `announcements?: PublicAnnouncement[];` to the `AppConfig` interface.)

`announcementLinks.ts`:
```ts
export type WebTarget = { kind: "external"; href: string } | { kind: "internal"; path: string } | null;

const ROUTES: Array<[RegExp, (m: RegExpMatchArray) => string]> = [
  [/^moments?\/([^/?#]+)$/, (m) => `/moment/${m[1]}`],
  [/^profile\/([^/?#]+)$/, (m) => `/profile/${m[1]}`],
  [/^community\/([^/?#]+)$/, (m) => `/community/${m[1]}`],
  [/^i\/([^/?#]+)$/, (m) => `/i/${m[1]}`],
  [/^announcement\/([^/?#]+)$/, (m) => `/announcement/${m[1]}`],
];

/** Where an announcement button goes on the website; null hides the button. */
export function webTargetFor(buttonUrl: string | null | undefined): WebTarget {
  const url = (buttonUrl || "").trim();
  if (/^https?:\/\/[^\s/?#]+/i.test(url)) return { kind: "external", href: url };
  const m = /^bananatalk:\/\/(.+)$/i.exec(url);
  if (!m) return null;
  for (const [re, to] of ROUTES) {
    const hit = m[1].match(re);
    if (hit) return { kind: "internal", path: to(hit) };
  }
  return null;
}
```

`dismissals.ts`:
```ts
export const DISMISS_KEY = "bt_ann_dismissed_v1";
const MAX = 50;
// Fallback when storage is blocked: dismissal lasts for this page session.
const memory = new Set<string>();

export function readDismissed(): string[] {
  try {
    const raw = window.localStorage.getItem(DISMISS_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed.filter((x) => typeof x === "string") : [];
  } catch {
    return [];
  }
}

export function isDismissed(id: string): boolean {
  return memory.has(id) || readDismissed().indexOf(id) >= 0;
}

export function dismiss(id: string): void {
  memory.add(id);
  try {
    const next = readDismissed().filter((x) => x !== id).concat(id).slice(-MAX);
    window.localStorage.setItem(DISMISS_KEY, JSON.stringify(next));
  } catch {
    /* storage blocked: the in-memory set covers this page session */
  }
}

export function _resetDismissalsForTests(): void {
  memory.clear();
}
```
(Call `_resetDismissalsForTests()` in the `beforeEach` of `dismissals.test.ts` and `useWebAnnouncements.test.tsx`.)

`useWebAnnouncements.ts`:
```ts
import { useCallback, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { useGetAppConfigQuery, PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { dismiss as remember, isDismissed } from "./dismissals";

export interface WebAnnouncements {
  popup: PublicAnnouncement | null;
  banner: PublicAnnouncement | null;
  dismiss: (id: string) => void;
}

export function useWebAnnouncements(): WebAnnouncements {
  const { i18n } = useTranslation();
  const { data } = useGetAppConfigQuery({ platform: "web", lang: i18n.language });
  const [tick, setTick] = useState(0);

  const dismiss = useCallback((id: string) => {
    remember(id);
    setTick((n) => n + 1);
  }, []);

  return useMemo(() => {
    const list: PublicAnnouncement[] = (data && Array.isArray(data.announcements) ? data.announcements : [])
      .filter((a: PublicAnnouncement) => a && a.id && !isDismissed(a.id));
    const banner = list.find((a) => a.displayStyle === "banner") || null;
    const popup = list.find((a) => a.displayStyle !== "banner") || null;
    return { popup, banner, dismiss };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, tick, dismiss]);
}
```

- [ ] **Step 4: Run tests** → PASS. Also run the existing `useMomentSchedulingEnabled` tests (no-arg caller) → PASS.

- [ ] **Step 5: Commit**
```bash
git add src/store/slices/appConfigSlice.ts src/components/announcements docs/REMAINING_WORK.md
git commit -m "feat(announcements): web data layer — app-config platform=web, link mapping, dismissals"
```

---

### Task 5: Web — AnnouncementModal (hero card) and AnnouncementBanner (floating card)

**Files:**
- Create: `src/components/announcements/AnnouncementModal.tsx`, `AnnouncementBanner.tsx`, `AnnouncementActions.ts`
- Modify: all 18 `src/utils/locales/*.json` (add `announcements` block)
- Test: `AnnouncementModal.test.tsx`, `AnnouncementBanner.test.tsx`

**Interfaces:**
- Consumes: `PublicAnnouncement`, `webTargetFor` (Task 4).
- Produces:
  - `<AnnouncementModal announcement={a} onClose={(remember: boolean) => void} preview?: boolean />`
  - `<AnnouncementBanner announcement={a} onClose={() => void} preview?: boolean />`
  - `useAnnouncementActions(a)` → `{ primary: null | (() => void); readMore: () => void }` in `AnnouncementActions.ts` (logged-out → `/login?redirect=...`).
- i18n keys (English values; translate the same keys in every locale file):
  - `announcements.new`: "New"
  - `announcements.readMore`: "Read more"
  - `announcements.close`: "Close"
  - `announcements.ended`: "This announcement has ended."
  - `announcements.back`: "Back"

- [ ] **Step 1: Write the failing tests**

`AnnouncementModal.test.tsx`:
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import AnnouncementModal from "./AnnouncementModal";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
let mockUser: any = null;
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: mockUser } }) }));

const A = { id: "a1", title: "Video calls are here", body: "Line 1\nLine 2", emoji: "🎉", imageUrl: null,
  buttonLabel: "Try it", buttonUrl: "https://example.com/x", priority: 0, displayStyle: "popup" as const };

const Where = () => <div data-testid="where">{useLocation().pathname + useLocation().search}</div>;
const renderAt = (ui: React.ReactElement) => render(
  <MemoryRouter initialEntries={["/feed"]}><Routes><Route path="*" element={<>{ui}<Where /></>} /></Routes></MemoryRouter>);

beforeEach(() => { mockUser = null; });

test("renders the hero card as an accessible dialog", () => {
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveAttribute("aria-modal", "true");
  expect(screen.getByText("Video calls are here")).toBeInTheDocument();
  expect(screen.getByText("announcements.new")).toBeInTheDocument();
  expect(screen.getByTestId("ann-hero-emoji")).toHaveTextContent("🎉");
});

test("✕ and Escape close and remember; backdrop closes without remembering", () => {
  const onClose = jest.fn();
  renderAt(<AnnouncementModal announcement={A} onClose={onClose} />);
  fireEvent.click(screen.getByRole("button", { name: "announcements.close" }));
  expect(onClose).toHaveBeenLastCalledWith(true);
  fireEvent.keyDown(window, { key: "Escape" });
  expect(onClose).toHaveBeenLastCalledWith(true);
  fireEvent.click(screen.getByTestId("ann-backdrop"));
  expect(onClose).toHaveBeenLastCalledWith(false);
});

test("logged out: Read more goes to login with redirect back", () => {
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  fireEvent.click(screen.getByRole("button", { name: "announcements.readMore" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/login?redirect=%2Fannouncement%2Fa1");
});

test("logged in: external button opens a new tab; Read more opens the page", () => {
  mockUser = { user: { _id: "u1" } };
  const open = jest.spyOn(window, "open").mockImplementation(() => null);
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  fireEvent.click(screen.getByRole("button", { name: "Try it" }));
  expect(open).toHaveBeenCalledWith("https://example.com/x", "_blank", "noopener,noreferrer");
  fireEvent.click(screen.getByRole("button", { name: "announcements.readMore" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/announcement/a1");
  open.mockRestore();
});

test("app-only link hides the primary button", () => {
  renderAt(<AnnouncementModal announcement={{ ...A, buttonUrl: "bananatalk://study" }} onClose={() => {}} />);
  expect(screen.queryByRole("button", { name: "Try it" })).toBeNull();
});

test("a broken image falls back to the gradient header with the emoji", () => {
  renderAt(<AnnouncementModal announcement={{ ...A, imageUrl: "https://cdn.example.com/missing.png" }} onClose={() => {}} />);
  fireEvent.error(screen.getByTestId("ann-hero-image"));
  expect(screen.queryByTestId("ann-hero-image")).toBeNull();
  expect(screen.getByTestId("ann-hero-emoji")).toBeInTheDocument();
});

test("preview mode: no navigation, no close side effects", () => {
  const onClose = jest.fn();
  renderAt(<AnnouncementModal announcement={A} onClose={onClose} preview />);
  fireEvent.click(screen.getByRole("button", { name: "announcements.readMore" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/feed");
});
```

`AnnouncementBanner.test.tsx`:
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import AnnouncementBanner from "./AnnouncementBanner";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: null } }) }));

const A = { id: "b1", title: "Maintenance tonight", body: "2–3am KST, chats may be slow", emoji: "🛠️", imageUrl: null,
  buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "banner" as const };

test("renders a region with title, one-line body and close", () => {
  const onClose = jest.fn();
  render(<MemoryRouter><AnnouncementBanner announcement={A} onClose={onClose} /></MemoryRouter>);
  expect(screen.getByRole("region", { name: "Maintenance tonight" })).toBeInTheDocument();
  expect(screen.getByTestId("ann-banner-body")).toHaveClass("truncate");
  fireEvent.click(screen.getByRole("button", { name: "announcements.close" }));
  expect(onClose).toHaveBeenCalled();
});

test("no button when there is no label/url", () => {
  render(<MemoryRouter><AnnouncementBanner announcement={A} onClose={() => {}} /></MemoryRouter>);
  expect(screen.queryByTestId("ann-banner-cta")).toBeNull();
});
```

- [ ] **Step 2: Run to verify they fail** → FAIL (modules missing).

- [ ] **Step 3: Implement**

`AnnouncementActions.ts`:
```ts
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { webTargetFor } from "./announcementLinks";

const loginFor = (path: string) => `/login?redirect=${encodeURIComponent(path)}`;

/** Button and "Read more" behaviour shared by the modal, banner and page. Logged out → login, then back. */
export function useAnnouncementActions(a: PublicAnnouncement, preview = false) {
  const navigate = useNavigate();
  const loggedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo));
  const target = a.buttonLabel ? webTargetFor(a.buttonUrl) : null;
  const pagePath = `/announcement/${encodeURIComponent(a.id)}`;

  const go = (path: string) => { if (!preview) navigate(loggedIn ? path : loginFor(path)); };

  const primary = !target ? null : () => {
    if (preview) return;
    if (target.kind === "external") {
      if (loggedIn) window.open(target.href, "_blank", "noopener,noreferrer");
      else navigate(loginFor(pagePath));
      return;
    }
    go(target.path);
  };

  return { primary, readMore: () => go(pagePath) };
}
```

`AnnouncementModal.tsx`:
```tsx
import React, { useEffect, useRef, useState } from "react";
import { X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { useAnnouncementActions } from "./AnnouncementActions";

interface Props {
  announcement: PublicAnnouncement;
  /** remember = true for ✕ / Escape (don't show again); false for a backdrop click. */
  onClose: (remember: boolean) => void;
  preview?: boolean;
}

const AnnouncementModal: React.FC<Props> = ({ announcement: a, onClose, preview = false }) => {
  const { t } = useTranslation();
  const { primary, readMore } = useAnnouncementActions(a, preview);
  const [imageOk, setImageOk] = useState(!!a.imageUrl);
  const closeRef = useRef<HTMLButtonElement>(null);
  const titleId = `ann-title-${a.id}`;

  useEffect(() => {
    if (preview) return;
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(true); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose, preview]);

  const card = (
    <div role="dialog" aria-modal="true" aria-labelledby={titleId} data-testid="ann-modal"
      onClick={(e) => e.stopPropagation()}
      className="relative w-full overflow-hidden rounded-t-3xl bg-surface shadow-float dark:bg-cardbg-dark sm:max-w-[420px] sm:rounded-3xl">
      <button ref={closeRef} type="button" aria-label={t("announcements.close")} onClick={() => onClose(true)}
        className="absolute right-3 top-3 z-10 grid h-8 w-8 place-items-center rounded-full bg-white/25 text-white backdrop-blur hover:bg-white/40 focus:outline-none focus-visible:ring-2 focus-visible:ring-white">
        <X size={16} />
      </button>
      {imageOk && a.imageUrl ? (
        <img data-testid="ann-hero-image" src={a.imageUrl} alt="" onError={() => setImageOk(false)}
          className="h-40 w-full object-cover sm:h-44" />
      ) : (
        <div className="grid h-36 place-items-center bg-gradient-to-br from-brand-deepest via-brand to-brand-light sm:h-40">
          <span data-testid="ann-hero-emoji" aria-hidden="true" className="text-6xl drop-shadow">{a.emoji || "📢"}</span>
        </div>
      )}
      <div className="px-6 pb-5 pt-5">
        <span className="inline-block rounded-full bg-banana-light/60 px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wide text-ink-800">
          {t("announcements.new")}
        </span>
        <h2 id={titleId} className="mt-2.5 text-xl font-bold text-ink-900 dark:text-ink-50">{a.title}</h2>
        <p className="mt-2 line-clamp-5 whitespace-pre-line text-[15px] leading-relaxed text-ink-600 dark:text-ink-300">{a.body}</p>
        <div className="mt-5 grid gap-1.5">
          {primary && a.buttonLabel ? (
            <button type="button" onClick={primary}
              className="w-full rounded-xl bg-brand-deep px-4 py-3 text-[15px] font-bold text-white transition hover:bg-brand-deepest focus:outline-none focus-visible:ring-2 focus-visible:ring-brand">
              {a.buttonLabel}
            </button>
          ) : null}
          <button type="button" onClick={readMore}
            className="w-full rounded-xl px-4 py-2 text-sm font-semibold text-ink-500 hover:text-ink-800 dark:hover:text-ink-100">
            {t("announcements.readMore")}
          </button>
        </div>
      </div>
    </div>
  );

  if (preview) return card;

  return (
    <div data-testid="ann-backdrop" onClick={() => onClose(false)}
      className="fixed inset-0 z-[60] flex items-end justify-center bg-ink-900/55 backdrop-blur-sm sm:items-center sm:p-4 motion-safe:animate-[fadeIn_150ms_ease-out]">
      {card}
    </div>
  );
};

export default AnnouncementModal;
```
(If `line-clamp-5` is not available in this Tailwind config, use `max-h-40 overflow-hidden`. If `lucide-react` is the icon set already imported by `AppDownloadPopup.tsx`, keep it; it is.)

Focus trap (spec §5): `ConsentBar.tsx` already uses a `DialogShell` that brings Escape, backdrop, focus into the panel and focus back to the opener. Read it first; if it can wrap this card while keeping the `ann-backdrop` test id and the remember/no-remember close distinction, use it for the non-preview path. Otherwise add a small Tab/Shift+Tab trap inside the card and restore focus to `document.activeElement` captured on open. Add a test: Tab from the last button moves focus to the close button.

`AnnouncementBanner.tsx`:
```tsx
import React from "react";
import { X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { useAnnouncementActions } from "./AnnouncementActions";

interface Props { announcement: PublicAnnouncement; onClose: () => void; preview?: boolean }

const AnnouncementBanner: React.FC<Props> = ({ announcement: a, onClose, preview = false }) => {
  const { t } = useTranslation();
  const { primary } = useAnnouncementActions(a, preview);
  return (
    <div className="px-3 pt-3 sm:px-6">
      <section role="region" aria-label={a.title} data-testid="ann-banner"
        className="mx-auto flex max-w-5xl items-center gap-3 rounded-2xl border border-ink-200 border-l-4 border-l-brand bg-surface px-3 py-2.5 shadow-[0_6px_20px_rgba(23,30,41,0.08)] dark:border-ink-700 dark:bg-cardbg-dark sm:px-4">
        <div aria-hidden="true" className="grid h-9 w-9 flex-none place-items-center rounded-xl bg-brand/10 text-lg">{a.emoji || "📢"}</div>
        <div className="min-w-0 flex-1">
          <div className="truncate text-sm font-bold text-ink-900 dark:text-ink-50">{a.title}</div>
          <div data-testid="ann-banner-body" className="truncate text-xs text-ink-500 dark:text-ink-300">{a.body}</div>
        </div>
        {primary && a.buttonLabel ? (
          <button type="button" data-testid="ann-banner-cta" onClick={primary}
            className="flex-none whitespace-nowrap rounded-full bg-brand-deep px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-brand-deepest">
            {a.buttonLabel}
          </button>
        ) : null}
        <button type="button" aria-label={t("announcements.close")} onClick={onClose}
          className="grid h-7 w-7 flex-none place-items-center rounded-full text-ink-400 hover:bg-ink-100 hover:text-ink-700 dark:hover:bg-ink-800">
          <X size={14} />
        </button>
      </section>
    </div>
  );
};

export default AnnouncementBanner;
```

Locale files: add to each of the 18 `src/utils/locales/*.json` a top-level `"announcements"` object with the 5 keys. English values above; translate per file language (ko: "새 소식", "더 보기", "닫기", "이 공지는 종료되었습니다.", "뒤로"; follow the same approach for the others). Run the parity test.

- [ ] **Step 4: Run tests** → `src/components/announcements` PASS; `src/utils/locales/localeParity.test.ts` PASS.

- [ ] **Step 5: Commit**
```bash
git add src/components/announcements src/utils/locales docs/REMAINING_WORK.md
git commit -m "feat(announcements): hero-card modal and floating banner for the website"
```

---

### Task 6: Web — mount on every page, take turns with growth surfaces

**Files:**
- Create: `src/components/announcements/AnnouncementSurfaces.tsx`
- Modify: `src/components/growth/surfaceRegistry.ts` (add `isSurfaceOpen`), `src/App.tsx`, `src/components/growth/ConsentBar.tsx`, `src/components/growth/AppDownloadPopup.tsx`, `src/components/growth/StickyAppBanner.tsx`
- Test: `src/components/announcements/AnnouncementSurfaces.test.tsx`, existing `ConsentBar.test.tsx`/`growthSurfaces.test.tsx` must still pass

**Interfaces:**
- Consumes: `useWebAnnouncements`, `AnnouncementModal`, `AnnouncementBanner`.
- Produces: surface keys `"announcement-popup"` and `"announcement-banner"`; `isSurfaceOpen(key): boolean`.

- [ ] **Step 1: Write the failing test** `AnnouncementSurfaces.test.tsx`:
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import AnnouncementSurfaces from "./AnnouncementSurfaces";
import { isSurfaceOpen, _resetSurfacesForTests } from "../growth/surfaceRegistry";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en" } }) }));
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: null } }) }));
const mockHook = jest.fn();
jest.mock("./useWebAnnouncements", () => ({ useWebAnnouncements: () => mockHook() }));

const P = { id: "p1", title: "Pop", body: "b", emoji: "🎉", imageUrl: null, buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "popup" };
const B = { ...P, id: "b1", title: "Ban", displayStyle: "banner" };

beforeEach(() => { _resetSurfacesForTests(); mockHook.mockReset(); });

test("shows the pop-up and the banner, and registers both surfaces", () => {
  const dismiss = jest.fn();
  mockHook.mockReturnValue({ popup: P, banner: B, dismiss });
  render(<MemoryRouter initialEntries={["/feed"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.getByRole("dialog")).toBeInTheDocument();
  expect(screen.getByTestId("ann-banner")).toBeInTheDocument();
  expect(isSurfaceOpen("announcement-popup")).toBe(true);
  expect(isSurfaceOpen("announcement-banner")).toBe(true);
  fireEvent.click(screen.getAllByRole("button", { name: "announcements.close" })[0]);
  expect(dismiss).toHaveBeenCalledWith("p1");
});

test("backdrop close hides the pop-up for this page load only", () => {
  const dismiss = jest.fn();
  mockHook.mockReturnValue({ popup: P, banner: null, dismiss });
  render(<MemoryRouter initialEntries={["/feed"]}><AnnouncementSurfaces /></MemoryRouter>);
  fireEvent.click(screen.getByTestId("ann-backdrop"));
  expect(screen.queryByRole("dialog")).toBeNull();
  expect(dismiss).not.toHaveBeenCalled();
});

test("nothing on admin routes", () => {
  mockHook.mockReturnValue({ popup: P, banner: B, dismiss: jest.fn() });
  render(<MemoryRouter initialEntries={["/admin/announcements"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.queryByRole("dialog")).toBeNull();
  expect(screen.queryByTestId("ann-banner")).toBeNull();
});

test("the pop-up opens only on the first route of the visit", () => {
  mockHook.mockReturnValue({ popup: P, banner: null, dismiss: jest.fn() });
  const { rerender } = render(<MemoryRouter initialEntries={["/feed"]}><AnnouncementSurfaces /></MemoryRouter>);
  fireEvent.click(screen.getByTestId("ann-backdrop"));
  rerender(<MemoryRouter initialEntries={["/chats"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.queryByRole("dialog")).toBeNull();
});
```

- [ ] **Step 2: Run to verify it fails** → FAIL.

- [ ] **Step 3: Implement**

`surfaceRegistry.ts` — add:
```ts
export function isSurfaceOpen(key: string): boolean {
  return open.has(key);
}
```

`AnnouncementSurfaces.tsx`:
```tsx
import React, { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";
import { useWebAnnouncements } from "./useWebAnnouncements";
import AnnouncementModal from "./AnnouncementModal";
import AnnouncementBanner from "./AnnouncementBanner";
import { openSurface, closeSurface } from "../growth/surfaceRegistry";

// Module-level: the pop-up is a once-per-visit ask (one page load), not per route.
let popupShownThisLoad = false;
export function _resetPopupForTests() { popupShownThisLoad = false; }

const AnnouncementSurfaces: React.FC = () => {
  const { pathname } = useLocation();
  const { popup, banner, dismiss } = useWebAnnouncements();
  const [popupOpen, setPopupOpen] = useState(false);
  const onAdmin = pathname.startsWith("/admin");

  useEffect(() => {
    if (onAdmin || !popup || popupShownThisLoad) return;
    popupShownThisLoad = true;
    setPopupOpen(true);
  }, [popup, onAdmin]);

  const showPopup = popupOpen && !!popup && !onAdmin;
  const showBanner = !!banner && !onAdmin;

  useEffect(() => {
    if (!showPopup) return;
    openSurface("announcement-popup");
    return () => closeSurface("announcement-popup");
  }, [showPopup]);

  useEffect(() => {
    if (!showBanner) return;
    openSurface("announcement-banner");
    return () => closeSurface("announcement-banner");
  }, [showBanner]);

  return (
    <>
      {showBanner ? <AnnouncementBanner announcement={banner!} onClose={() => dismiss(banner!.id)} /> : null}
      {showPopup ? (
        <AnnouncementModal announcement={popup!} onClose={(remember) => {
          if (remember) dismiss(popup!.id);
          setPopupOpen(false);
        }} />
      ) : null}
    </>
  );
};

export default AnnouncementSurfaces;
```
(Call `_resetPopupForTests()` in the test `beforeEach`.)

`App.tsx`: import `AnnouncementSurfaces` and render it right after `<AppBanner />` (so the banner sits under the navbar; the modal is fixed-position).

`ConsentBar.tsx`: next to `const popupOpen = useSurfaceOpen("download-popup");` add `const annOpen = useSurfaceOpen("announcement-popup");` and wherever `popupOpen` makes the bar step aside, use `(popupOpen || annOpen)`.

`AppDownloadPopup.tsx`: in `fire`, change to `if (!gated() && !isSurfaceOpen("announcement-popup")) setOpen(true);` (import `isSurfaceOpen`).

`StickyAppBanner.tsx`: read `const annBanner = useSurfaceOpen("announcement-banner");` and return `null` while it is true (import `useSurfaceOpen`).

- [ ] **Step 4: Run tests** — `src/components/announcements`, `src/components/growth` → PASS.

- [ ] **Step 5: Commit**
```bash
git add src/App.tsx src/components/announcements src/components/growth docs/REMAINING_WORK.md
git commit -m "feat(announcements): show the web pop-up and banner on every page, taking turns with growth surfaces"
```

---

### Task 7: Web — `/announcement/:id` page

**Files:**
- Create: `src/store/slices/announcementsSlice.ts`, `src/components/announcements/AnnouncementPage.tsx`
- Modify: `src/router/routes.tsx` (add lazy route near `moment/:id`)
- Test: `src/components/announcements/AnnouncementPage.test.tsx`, `src/router/routes.test.tsx` (route exists)

**Interfaces:**
- Produces: `useGetPublicAnnouncementQuery({ id, lang })` → `GET /api/v1/announcements/:id?lang=` (auth required; returns `{ data: PublicAnnouncement }`).

- [ ] **Step 1: Write the failing test** `AnnouncementPage.test.tsx`:
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import AnnouncementPage from "./AnnouncementPage";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en" } }) }));
let mockUser: any = { user: { _id: "u1" } };
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: mockUser } }) }));
const mockQuery = jest.fn();
jest.mock("../../store/slices/announcementsSlice", () => ({ useGetPublicAnnouncementQuery: (...a: any[]) => mockQuery(...a) }));

const Where = () => <div data-testid="where">{useLocation().pathname + useLocation().search}</div>;
const renderPage = () => render(
  <MemoryRouter initialEntries={["/announcement/a1"]}>
    <Routes>
      <Route path="/announcement/:id" element={<AnnouncementPage />} />
      <Route path="*" element={<Where />} />
    </Routes>
  </MemoryRouter>);

beforeEach(() => { mockUser = { user: { _id: "u1" } }; mockQuery.mockReset(); });

test("shows the full announcement, keeping line breaks", () => {
  mockQuery.mockReturnValue({ data: { id: "a1", title: "T", body: "L1\nL2", emoji: "🎉", imageUrl: null, buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "popup" } });
  renderPage();
  expect(screen.getByRole("heading", { name: "T" })).toBeInTheDocument();
  expect(screen.getByTestId("ann-page-body")).toHaveClass("whitespace-pre-line");
  expect(mockQuery).toHaveBeenCalledWith({ id: "a1", lang: "en" }, { skip: false });
});

test("404 shows the ended message", () => {
  mockQuery.mockReturnValue({ error: { status: 404 } });
  renderPage();
  expect(screen.getByText("announcements.ended")).toBeInTheDocument();
});

test("logged out redirects to login and back", () => {
  mockUser = null;
  mockQuery.mockReturnValue({});
  renderPage();
  expect(screen.getByTestId("where")).toHaveTextContent("/login?redirect=%2Fannouncement%2Fa1");
});
```

- [ ] **Step 2: Run to verify it fails** → FAIL.

- [ ] **Step 3: Implement**

`announcementsSlice.ts`:
```ts
import { apiSlice } from "./apiSlice";
import { PublicAnnouncement } from "./appConfigSlice";

export const announcementsApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    getPublicAnnouncement: builder.query({
      query: ({ id, lang }: { id: string; lang?: string }) =>
        ({ url: `/api/v1/announcements/${encodeURIComponent(id)}${lang ? `?lang=${encodeURIComponent(lang)}` : ""}` }),
      transformResponse: (r: any): PublicAnnouncement => (r && r.data) || r,
    }),
  }),
});

export const { useGetPublicAnnouncementQuery } = announcementsApiSlice as any;
```

`AnnouncementPage.tsx`:
```tsx
import React from "react";
import { Navigate, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { useGetPublicAnnouncementQuery } from "../../store/slices/announcementsSlice";
import { useAnnouncementActions } from "./AnnouncementActions";
import Loader from "../Loader";

const Body: React.FC<{ a: any }> = ({ a }) => {
  const { primary } = useAnnouncementActions(a);
  return (
    <article className="mx-auto my-8 max-w-2xl overflow-hidden rounded-3xl bg-surface shadow-card dark:bg-cardbg-dark">
      {a.imageUrl ? <img src={a.imageUrl} alt="" className="max-h-80 w-full object-cover" /> : (
        <div className="grid h-40 place-items-center bg-gradient-to-br from-brand-deepest via-brand to-brand-light">
          <span aria-hidden="true" className="text-6xl">{a.emoji || "📢"}</span>
        </div>
      )}
      <div className="p-6 sm:p-8">
        <h1 className="text-2xl font-bold text-ink-900 dark:text-ink-50">{a.title}</h1>
        <p data-testid="ann-page-body" className="mt-4 whitespace-pre-line text-base leading-relaxed text-ink-700 dark:text-ink-200">{a.body}</p>
        {primary && a.buttonLabel ? (
          <button type="button" onClick={primary}
            className="mt-6 rounded-xl bg-brand-deep px-5 py-3 font-bold text-white hover:bg-brand-deepest">{a.buttonLabel}</button>
        ) : null}
      </div>
    </article>
  );
};

const AnnouncementPage: React.FC = () => {
  const { id = "" } = useParams();
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const loggedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo));
  const { data, error, isLoading } = useGetPublicAnnouncementQuery({ id, lang: i18n.language }, { skip: !loggedIn });

  if (!loggedIn) return <Navigate to={`/login?redirect=${encodeURIComponent(`/announcement/${id}`)}`} replace />;
  if (isLoading) return <Loader />;
  if (error || !data) {
    return (
      <div className="mx-auto my-16 max-w-md text-center">
        <p className="text-ink-600 dark:text-ink-300">{t("announcements.ended")}</p>
        <button type="button" onClick={() => navigate(-1)} className="mt-4 text-sm font-semibold text-brand-deep">{t("announcements.back")}</button>
      </div>
    );
  }
  return <Body a={data} />;
};

export default AnnouncementPage;
```

`routes.tsx`: next to `<Route path="moment/:id" ... />` add
```tsx
    <Route path="announcement/:id" element={lazyRoute(<AnnouncementPage />)} />
```
with `const AnnouncementPage = lazyWithRetry(() => import("../components/announcements/AnnouncementPage"));` alongside the other lazy imports. Add `/announcement/abc` to the route-matching assertions in `routes.test.tsx` the same way `/moment/abc` is asserted.

- [ ] **Step 4: Run tests** → `src/components/announcements`, `src/router` PASS.

- [ ] **Step 5: Commit**
```bash
git add src/store/slices/announcementsSlice.ts src/components/announcements src/router docs/REMAINING_WORK.md
git commit -m "feat(announcements): /announcement/:id page on the website (login required)"
```

---

### Task 8: Web admin — Web platform, display style, notify rule, website previews

**Files:**
- Modify: `src/store/slices/adminSlice.ts` (`AnnouncementPlatform`, `AdminAnnouncement`, `AnnouncementInput`, `AudienceCount`)
- Modify: `src/components/admin/parts/announcementForm.ts` (form field, `emptyForm`, `fromAnnouncement`, `toInput`, `validateForm`, `targetingSummary`, new `reachesApp`)
- Modify: `src/components/admin/pages/AdminAnnouncementEditor.tsx` (platform list, display style control, notify disabled + hint, previews)
- Modify: `src/components/admin/parts/AnnouncementPublishBar.tsx` (show "Website only — no push" when `reason === 'web_only'`)
- Test: `announcementForm.test.ts`, `AdminAnnouncementEditor.test.tsx`, `AnnouncementPublishBar.test.tsx`

**Interfaces:**
- Consumes: `AnnouncementModal`, `AnnouncementBanner` with `preview` (Task 5).
- Produces: `AnnouncementForm.displayStyle: "popup" | "banner"`; `reachesApp(form): boolean` in `announcementForm.ts` (same rule as backend `lib/announcementReach.js`).

- [ ] **Step 1: Write the failing tests**

Append to `announcementForm.test.ts`:
```ts
import { emptyForm, toInput, fromAnnouncement, reachesApp, targetingSummary } from "./announcementForm";

test("displayStyle round-trips and defaults to popup", () => {
  expect(emptyForm().displayStyle).toBe("popup");
  const f = { ...emptyForm(), displayStyle: "banner" as const, platforms: ["web" as const] };
  expect(toInput(f).displayStyle).toBe("banner");
  expect(fromAnnouncement({ ...(toInput(f) as any), id: "x", _id: "x", status: "draft", translations: { en: { title: "t", body: "b" } }, delivery: {} } as any).displayStyle).toBe("banner");
  expect(fromAnnouncement({ id: "x", _id: "x", status: "draft", translations: { en: { title: "t", body: "b" } }, delivery: {} } as any).displayStyle).toBe("popup");
});

test("reachesApp mirrors the backend rule; toInput forces notify off when it can't", () => {
  expect(reachesApp({ ...emptyForm(), platforms: ["all"] })).toBe(true);
  expect(reachesApp({ ...emptyForm(), platforms: ["web"] })).toBe(false);
  expect(reachesApp({ ...emptyForm(), displayStyle: "banner" })).toBe(false);
  expect(toInput({ ...emptyForm(), displayStyle: "banner", notify: true }).notify).toBe(false);
});

test("targeting summary names Web", () => {
  expect(targetingSummary({ platforms: ["web", "ios"], languages: [] })).toContain("Web");
});
```

Append to `AdminAnnouncementEditor.test.tsx` (new-announcement render path the file already uses):
```tsx
test("Web platform and Display style controls; banner disables Send notification with a hint; website previews render", () => {
  renderNew(); // the file's helper for /admin/announcements/new; if absent, render with MemoryRouter at that path like the existing "new" test
  fireEvent.click(screen.getByLabelText("Web"));
  fireEvent.click(screen.getByLabelText("Banner"));
  expect(screen.getByRole("switch", { name: "Send notification" })).toBeDisabled();
  expect(screen.getByText(/website only/i)).toBeInTheDocument();
  expect(screen.getByTestId("ann-banner")).toBeInTheDocument();
  fireEvent.click(screen.getByLabelText("Pop-up"));
  expect(screen.getByTestId("ann-modal")).toBeInTheDocument();
});
```
(The editor test mocks `react-i18next` with `t: () => ""`; the preview components use `t(...)` — that is fine, labels render empty. Add `jest.mock("react-redux", ...)` returning `userInfo: null` if the previews' `useSelector` needs a store.)

Append to `AnnouncementPublishBar.test.tsx`: when the audience-count mock returns `{ count: 0, listed: 0, reason: "web_only" }`, the confirm dialog text contains "Website only".

- [ ] **Step 2: Run to verify they fail** → FAIL.

- [ ] **Step 3: Implement**

`adminSlice.ts`:
- `export type AnnouncementPlatform = "all" | "ios" | "android" | "web";`
- `export type AnnouncementDisplayStyle = "popup" | "banner";`
- Add `displayStyle?: AnnouncementDisplayStyle;` to `AdminAnnouncement` and `AnnouncementInput`.
- `AudienceCount`: add `reason?: "web_only";`.

`announcementForm.ts`:
- Add `displayStyle: AnnouncementDisplayStyle;` to `AnnouncementForm`; `displayStyle: "popup",` in `emptyForm`; `displayStyle: a.displayStyle === "banner" ? "banner" : "popup",` in `fromAnnouncement`.
- Add:
```ts
/** Same rule as backend lib/announcementReach.js: only these may notify or reach the app. */
export const reachesApp = (f: Pick<AnnouncementForm, "platforms" | "displayStyle">): boolean =>
  f.displayStyle !== "banner" &&
  (f.platforms.length === 0 || f.platforms.some((p) => p === "all" || p === "ios" || p === "android"));
```
- In `toInput` (non-live branch) add `displayStyle: form.displayStyle,` and change `notify: form.notify,` to `notify: form.notify && reachesApp(form),`.
- In `targetingSummary`, map `web` → `"Web"`: `platforms.map((x) => (x === "ios" ? "iOS" : x === "web" ? "Web" : "Android"))`.

`AdminAnnouncementEditor.tsx`:
- Platform list: `(["all", "ios", "android", "web"] as AnnouncementPlatform[])` and label `p === "web" ? "Web" : ...`; cast types to `AnnouncementPlatform[]`.
- After the platforms fieldset add:
```tsx
<fieldset>
  <legend className={labelClass}>{t("admin.announcements.displayStyle") || "Display style"}</legend>
  <div className="mt-1 flex gap-4">
    {(["popup", "banner"] as const).map((s) => (
      <label key={s} className="flex items-center gap-1 text-sm">
        <input type="radio" name="ann-display-style" checked={form.displayStyle === s} disabled={lockTargeting}
          onChange={() => setField("displayStyle", s)} />
        {s === "popup" ? "Pop-up" : "Banner"}
      </label>
    ))}
  </div>
  <p className="mt-1 text-xs text-ink-500">Website only — the mobile app always shows a pop-up.</p>
  {form.displayStyle === "banner" && !form.platforms.some((p) => p === "web" || p === "all") ? (
    <p role="alert" className="mt-1 text-xs text-amber-700">A banner only appears on the website; add Web or All platforms.</p>
  ) : null}
</fieldset>
```
- "Send notification" switch: `disabled={lockTargeting || !reachesApp(form)}`, and when `!reachesApp(form)` render under it `<p className="text-xs text-ink-500">Website only — banners and web-only announcements don't send push notifications.</p>`. When `!reachesApp(form) && form.notify`, call `setField("notify", false)` in an effect so the UI matches what will be saved.
- Previews: replace the single `<AnnouncementPreview .../>` aside content with three labelled previews:
```tsx
<div className="space-y-6">
  <div>
    <div className="mb-1 text-xs font-semibold text-ink-500">App</div>
    <AnnouncementPreview emoji={form.emoji} imageUrl={form.imageUrl} title={text.title} body={text.body} buttonLabel={text.buttonLabel} />
  </div>
  <div>
    <div className="mb-1 text-xs font-semibold text-ink-500">{form.displayStyle === "banner" ? "Website banner" : "Website pop-up"}</div>
    {form.displayStyle === "banner" ? (
      <AnnouncementBanner preview onClose={() => {}} announcement={webPreview} />
    ) : (
      <AnnouncementModal preview onClose={() => {}} announcement={webPreview} />
    )}
  </div>
</div>
```
with
```ts
const webPreview = {
  id: "preview", title: text.title || "Title", body: text.body || "Body", emoji: form.emoji || null,
  imageUrl: form.imageUrl || null, buttonLabel: text.buttonLabel || null, buttonUrl: form.buttonUrl || null,
  priority: 0, displayStyle: form.displayStyle,
};
```
(Hide the "App" preview when `!reachesApp(form)`, replaced by the text "Not shown in the app".)

`AnnouncementPublishBar.tsx`: where the confirm dialog renders the audience numbers, if `audience.reason === "web_only"` render "Website only — no push notifications, no app notification rows." instead of the counts.

- [ ] **Step 4: Run tests** → all admin suites PASS (`CI=true npx react-scripts test --watchAll=false src/components/admin`), then `npx tsc --noEmit -p .` has no errors under `src/`, then `CI=false npm run build` compiles.

- [ ] **Step 5: Commit**
```bash
git add src/store/slices/adminSlice.ts src/components/admin docs/REMAINING_WORK.md
git commit -m "feat(admin): Web platform, Pop-up/Banner display style, website previews; web-only can't notify"
```

---

### Task 9: Whole-suite verification, docs, deploy (controller)

- [ ] Backend: run every `test/*.test.js` one by one; all pass.
- [ ] Web: `CI=true npx react-scripts test --watchAll=false` full suite passes; `CI=false npm run build` compiles.
- [ ] App repo: confirm `git diff` touches only `docs/` (spec, plan, REMAINING_WORK).
- [ ] Update REMAINING_WORK in backend, web and app: tick "Web announcements"; add open items: "first real web announcement end-to-end on banatalk.com (pop-up + banner, logged in and out)", "banner style in the mobile app (later release)".
- [ ] Deploy backend (push main → Deploy to DigitalOcean), verify `GET /api/v1/app-config?platform=ios` unchanged and `?platform=web` 200; then deploy web; load banatalk.com and check no console errors.
