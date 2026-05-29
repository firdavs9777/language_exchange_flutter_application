# Notification System v2 — Phase C1: Quiet Hours, Bundling, Frequency Caps, Localized Templates, Action Buttons

**Status:** Design (awaiting review)
**Date:** 2026-05-04
**Author:** Claude (with @firdavs9777)
**Phase:** C1 of Notification System v2 (foundations layer)

---

## 1. Context

The current BananaTalk notification stack is mature for transactional events (chat, moments, follows, profile visits) but missing the polish layer that makes notifications respectful and engaging:

- No quiet hours / DND — users get pinged at 3am if a partner in another timezone messages them.
- No bundling — 5 likes on a moment = 5 separate pushes within seconds.
- No frequency caps per type — a user reading 20 moments in a row could get 20 follow-up pushes.
- Templates are hardcoded English strings on backend (`backend/services/notificationService.js`).
- Notifications have title + body only — no inline reply, no "View" / "Mark Read" actions.

This phase ships the **foundations** — without them, the "cool" notifications planned in Phase C2 (streaks, learning prompts, milestone celebrations) become noise. Phase C1 makes the system trustworthy first, fun second.

### What already exists (do not duplicate)

| Capability | Where |
|---|---|
| FCM via firebase-admin (multi-device) | `backend/services/fcmService.js` |
| 60s dedup window per (user, type) | `backend/services/notificationBatchService.js` |
| Notification model + 30d TTL | `backend/models/Notification.js` |
| Per-conversation mute | `User.mutedChats[]`, `notifications.js` route |
| Cron-like scheduler (KST) | `backend/jobs/scheduler.js` |
| Re-engagement push (7d inactive) | `backend/jobs/notificationJobs.js` |
| Weekly digest (Sun 10am KST) | `backend/jobs/weeklyDigestJob.js` |
| 11 toggle settings client-side | `lib/providers/notification_settings_provider.dart` |
| Deep-link router | `lib/services/notification_router.dart` |

---

## 2. Goals

1. **Quiet Hours**: User-configurable "do not disturb" window; backend suppresses non-urgent pushes during it; client suppresses local notifications during it.
2. **Smart Bundling**: Coalesce same-type events for the same user within a configurable window; replace per-event push with a digest push ("3 people liked your moment").
3. **Frequency Caps**: Hard ceilings per (user, type, day) and per (user, type, week) to prevent runaway pushes.
4. **Localized Templates**: Server-side i18n for notification copy; user's `preferredLocale` drives template selection.
5. **Action Buttons**: Inline reply on chat (iOS Quick Reply, Android RemoteInput); "View" / "Profile" actions on social notifications.

## 3. Non-goals

- **A/B testing framework** (deferred to Phase C3).
- **Send-time learning** based on user activity (Phase C3).
- **New notification types** — no streaks, no learning prompts, no milestones (Phase C2).
- **In-app banners** for foreground messages (deferred; current foreground handler skips chat msgs since socket handles them).
- **Marketing automation / drip campaigns** (out of scope entirely; product-level decision).

---

## 4. Architecture

### 4.1 Quiet Hours

**Storage** (User model):

```javascript
// backend/models/User.js — add to schema
quietHours: {
  enabled: { type: Boolean, default: false },
  start: { type: String, default: '22:00' },   // HH:mm in user's local timezone
  end:   { type: String, default: '08:00' },
  timezone: { type: String, default: 'Asia/Seoul' }, // IANA TZ
  allowUrgent: { type: Boolean, default: true } // calls + direct chat from VIP partners bypass
}
```

**Backend gate** (`fcmService.sendToUser`):

Before sending, check `isInQuietHours(user, now)`. Logic:
- Convert `now` to user's `quietHours.timezone`.
- Compare HH:mm against `start`/`end` (handle overnight wrap, e.g. 22:00–08:00).
- If in window AND notification type is not in `URGENT_TYPES = ['incoming_call', 'chat_message_vip_partner']` → drop the push (still write to Notification history with `suppressedReason: 'quiet_hours'`).

**Client gate** (`notification_service.dart` foreground handler):

When a foreground RemoteMessage arrives, if user is in quiet hours and type isn't urgent, do not call `_showLocalNotification`. Still write to in-app history.

**UI** (`notification_settings_screen.dart`):

New section "Quiet Hours" with:
- Master toggle.
- Time pickers for start / end (use Flutter `showTimePicker`).
- Sub-toggle "Allow calls & VIP messages".
- Display: "Quiet hours: 10:00 PM – 8:00 AM (your local time)".

### 4.2 Smart Bundling

**New service**: `backend/services/notificationBundlingService.js`.

**Algorithm** (per (userId, bundleKey) where `bundleKey = type` or `type:contextId`):

1. On notification trigger, check Redis (or in-memory if no Redis) for an open bundle:
   - `bundle:{userId}:{bundleKey}` → `{ count: N, firstAt, actorIds: [], targetData: {...} }`.
2. If no open bundle: open one with TTL = `BUNDLE_WINDOW` (default 60s for likes, 300s for visits, 30s for moment comments). Schedule a delayed flush.
3. If open bundle: increment `count`, push `actorId`. Reset TTL only for "rolling" types (visits); use fixed window for "burst" types (likes). Defer the push.
4. On flush: build the bundle push using a localized template that takes `count` and the latest 1–2 actor names. Send via existing `sendToUser`. Write a single Notification history row (`type` retained, `bundleSize: N`, `bundleActors: [...]`).

**Bundleable types** (Phase C1):
- `moment_like` — bundle window 60s, key by `momentId`.
- `profile_visit` — bundle window 300s, key by user (no per-target).
- `follower_moment` — bundle window 60s, key by `momentId`.
- `friend_request` — bundle window 60s, key by user.

**Non-bundled** (always immediate):
- `chat_message`, `incoming_call`, `moment_comment` (replies are personal), `system`, `re_engagement`, `digest`, `milestone`.

**Redis fallback**: If no Redis instance configured (`process.env.REDIS_URL` empty), use in-memory `Map` with `setTimeout` for flush. **Document that this loses bundles across server restarts**; acceptable for now since restarts are rare.

### 4.3 Frequency Caps

**Storage** (User model):

```javascript
notificationCounters: {
  // Reset by daily cron (00:00 user TZ)
  daily: { type: Map, of: Number, default: {} },  // { 'moment_like': 2, 'profile_visit': 1 }
  weekly: { type: Map, of: Number, default: {} }, // { 're_engagement': 1, 'digest': 1 }
  resetAt: Date
}
```

**Caps config** (`backend/config/notificationCaps.js`):

```javascript
module.exports = {
  daily: {
    moment_like:      5,   // bundled, so 5 bundles/day max
    moment_comment:  10,
    profile_visit:    3,   // already bundled
    follower_moment:  5,
    friend_request:  10,
  },
  weekly: {
    re_engagement: 1,
    digest:        1,
  },
};
```

**Gate location**: `fcmService.sendToUser`, after quiet-hours gate. If cap exceeded, drop with `suppressedReason: 'frequency_cap'`. Increment counter atomically (`$inc` on `notificationCounters.daily.{type}`). Reset by cron `dailyCounterResetJob` and `weeklyCounterResetJob` in `backend/jobs/`.

### 4.4 Localized Templates

**Layout**:

```
backend/notification_templates/
  en.json
  ko.json
  ja.json
  ...
```

Each file:

```json
{
  "chat_message": {
    "title": "{senderName}",
    "body": "{message}"
  },
  "moment_like_single": {
    "title": "❤️ {actorName}",
    "body": "liked your moment"
  },
  "moment_like_bundle": {
    "title": "❤️ {actorName} and {count} others",
    "body": "liked your moment"
  },
  "profile_visit_bundle": {
    "title": "👀 {count} new profile visitors",
    "body": "Tap to see who's interested"
  },
  ...
}
```

**Loader**: `backend/services/notificationTemplateService.js` exposes `render(type, locale, vars)`. Falls back to `en` if locale missing. Uses simple `{var}` interpolation.

**User locale source**: `User.preferredLocale` (already exists, defaults to `en`). Set on signup from device locale.

**Migration** of existing call sites: search `backend/services/notificationService.js` for hardcoded `title`/`body` strings, replace with `templateService.render('moment_like_single', user.preferredLocale, { actorName })`.

### 4.5 Action Buttons (Rich Notifications)

**Android** (FCM message):

```javascript
android: {
  notification: {
    channel_id: 'high_importance_channel',
    actions: [
      { action: 'reply', title: 'Reply' },         // chat
      { action: 'view',  title: 'View' },          // moment
      { action: 'profile', title: 'View Profile' } // visit, follow
    ]
  }
}
```

Client handles via `flutter_local_notifications` action callback: parse action key, route to appropriate screen or open inline-reply dialog.

**iOS** (APNS payload via FCM):

Use category-based actions. Register categories in `notification_service.dart`:

```dart
await FlutterLocalNotificationsPlugin().initialize(
  ...
  iOS: DarwinInitializationSettings(
    notificationCategories: [
      DarwinNotificationCategory(
        'CHAT_MESSAGE',
        actions: [
          DarwinNotificationAction.text(
            'reply', 'Reply',
            buttonTitle: 'Send', placeholder: 'Type a reply…',
          ),
          DarwinNotificationAction.plain('view', 'View'),
        ],
      ),
      DarwinNotificationCategory('MOMENT_SOCIAL', actions: [
        DarwinNotificationAction.plain('view', 'View'),
      ]),
      DarwinNotificationCategory('PROFILE_SOCIAL', actions: [
        DarwinNotificationAction.plain('profile', 'View Profile'),
      ]),
    ],
  ),
);
```

Backend sets APNS `category` based on type:

```javascript
apns: {
  payload: {
    aps: {
      category: typeToCategory(type), // chat_message → CHAT_MESSAGE, etc.
      'mutable-content': 1, // for image attachments (existing flow)
    }
  }
}
```

**Inline reply handler** (chat): When `reply` action is invoked with text, client posts to existing `POST /api/v1/messages` endpoint via `notification_api_client`. No screen open required. Show success toast on next foreground.

---

## 5. Data flow

### 5.1 Outbound notification path (after C1)

```
Trigger (e.g. moment_like)
  ↓
notificationService.sendMomentLike(userId, actorId, momentId)
  ↓
notificationBundlingService.collect(userId, 'moment_like', { momentId, actorId })
  ↓ (after window OR immediate for non-bundled types)
templateService.render('moment_like_bundle', user.preferredLocale, { actorName, count })
  ↓
fcmService.sendToUser(userId, payload)
  ├─ check quietHours → drop if in window (record suppressed)
  ├─ check frequencyCap → drop if exceeded (record suppressed)
  ├─ increment counter
  └─ FCM dispatch
       ↓
   Client receives → notification_router → screen / action handler
```

### 5.2 Suppressed notifications

Suppressed pushes are still written to `Notification` collection so users can see them in history (with a small "muted by quiet hours" badge in UI). Helps debugging and tells the user they didn't miss anything.

---

## 6. API changes

### 6.1 `GET /api/v1/notifications/settings`

Add to response:

```json
{
  "quietHours": {
    "enabled": false,
    "start": "22:00",
    "end": "08:00",
    "timezone": "Asia/Seoul",
    "allowUrgent": true
  }
}
```

### 6.2 `PUT /api/v1/notifications/settings`

Accept the same fields. Validate timezone against IANA list, validate HH:mm format.

### 6.3 `GET /api/v1/notifications/history`

Add to response item:

```json
{
  "_id": "...",
  "type": "moment_like",
  "title": "❤️ Alex and 3 others",
  "body": "liked your moment",
  "bundleSize": 4,
  "bundleActors": ["userId1", "userId2", "userId3", "userId4"],
  "suppressedReason": null  // or "quiet_hours" / "frequency_cap"
}
```

Client UI shows bundle size as a small chip next to title; suppressed shows muted badge.

---

## 7. Sequencing (order of implementation)

Build in dependency order. Each step independently shippable.

1. **Backend: Quiet Hours**
   - Schema migration on User model.
   - `isInQuietHours` helper.
   - Gate in `fcmService.sendToUser`.
   - API additions.
   - **Ship.** Behavior change: pushes silenced during user's window. Default disabled (no impact until user enables).

2. **Client: Quiet Hours UI**
   - New section in `notification_settings_screen.dart`.
   - `notification_settings_provider` field additions.
   - Time picker integration.
   - Foreground handler check.
   - **Ship.**

3. **Backend: Localized Templates**
   - Create `notification_templates/{en,ko,ja}.json` (other locales English-fallback initially).
   - `notificationTemplateService.render`.
   - Migrate existing send-site strings.
   - **Ship.** No user-visible change for English users; Korean/Japanese users get translated copy.

4. **Backend: Frequency Caps**
   - Schema migration (`notificationCounters`).
   - Caps config.
   - Gate in `fcmService.sendToUser`.
   - Daily / weekly reset cron jobs.
   - **Ship.** Behavior change: caps enforced. Monitor logs for unexpected suppressions.

5. **Backend: Bundling**
   - `notificationBundlingService` (in-memory first; Redis if env present).
   - Wire `moment_like`, `profile_visit`, `follower_moment`, `friend_request` through bundler.
   - New bundle templates.
   - **Ship.** Major UX change — visible quiet on noisy moments / popular profiles.

6. **Client: Action Buttons**
   - Register iOS categories + Android actions.
   - Action callback router.
   - Inline reply handler for chat.
   - **Ship.** Adds Reply / View affordances.

7. **Client: History UI updates**
   - Bundle chip ("+3").
   - Suppressed badge.
   - **Ship.**

---

## 8. Testing strategy

### Backend

- **Unit**: `isInQuietHours` (overnight wrap, timezone correctness, edge cases at exact start/end).
- **Unit**: `templateService.render` (locale fallback, missing var, missing template).
- **Integration**: `fcmService.sendToUser` happy path + 3 suppression paths (quiet hours, frequency cap, dedup).
- **Integration**: Bundling — fire 5 `moment_like` events within window, assert 1 push with `count: 5` in payload, assert 1 Notification history row.
- **Cron**: Daily counter reset job runs at 00:00 user TZ (mock time), counters zero out.

### Client

- **Widget**: Quiet hours settings UI — toggle on/off, pick times, persists.
- **Manual**: Send test push during quiet hours window → no system notification, history shows muted.
- **Manual**: iOS quick-reply on chat — type reply, send, message arrives in chat backend.
- **Manual**: Android RemoteInput on chat — same.

### End-to-end smoke (after all 7 steps)

1. Set quiet hours 14:00–15:00 (cover current hour).
2. Have another user like 5 of your moments rapidly.
3. Expected: 0 system notifications during window. 1 bundled history entry "+5".
4. Disable quiet hours, like 1 more.
5. Expected: 1 system notification. History shows new entry.

---

## 9. Open questions

1. **Quiet hours default**: ship as `enabled: false` or `enabled: true with sensible defaults`? Recommendation: **false** (don't change behavior for existing users without consent); promote in-app on first launch after upgrade.
2. **Bundle window for likes**: 60s is conservative. Some platforms (Instagram) bundle aggressively (10 minutes). Start at 60s, monitor; adjust based on user complaints / bundle hit rate.
3. **Inline reply UX on iOS**: should it preview in chat or fully bypass? Recommendation: bypass — sent from notification, user sees it next time they open chat. Avoids opening app.
4. **Frequency cap UX**: should we tell the user "you've hit your daily moment-like cap, see them in the app"? Recommendation: **silent for now** — most users won't notice; surface only if telemetry shows confused users.
5. **Multi-device + bundling**: bundling is per-user, dispatched to all devices. ✓ correct. But quiet hours uses user TZ; what if user has devices in 2 timezones? Recommendation: trust `User.quietHours.timezone` (single source); the notification was destined for the user, not a device.

Each is non-blocking; document the chosen default in code comments and revisit during Phase C3.

---

## 10. Out of scope (deferred to C2 / C3)

- New notification types (streaks, milestones, learning prompts, profile-completion nudge) → Phase C2.
- Send-time learning, A/B framework, analytics dashboard → Phase C3.
- Granular preference tiers (Activity / Reminders / Marketing) → Phase C3.
- In-app foreground banners → Phase C3.
- Notification expiry transparency UI ("expires in 30 days") → Phase C3.

---

## 11. Risks

| Risk | Mitigation |
|---|---|
| Bundling loses notifications on server restart (in-memory) | Document; ship with Redis where available; flush bundles on graceful shutdown. |
| Quiet hours misfires due to TZ bugs | Heavy unit tests on TZ logic; default disabled. |
| Frequency caps too tight → users miss important pushes | Conservative defaults + monitor `suppressedReason` counts; tune via config. |
| Localized templates: missing translations cause English fallback (acceptable) but feel jarring mid-app | Phase C1 ships en/ko/ja; remaining locales added incrementally. Engineering doesn't block on translation. |
| Action buttons require correct iOS category registration; wrong category = no buttons shown | Add a smoke test path; document in code. |

---

## 12. Estimate

Rough effort per developer-day equivalents:

- Backend Quiet Hours: 1d
- Client Quiet Hours UI: 0.5d
- Localized Templates (infra + en/ko/ja initial): 1.5d
- Frequency Caps + reset crons: 1d
- Bundling service: 2d
- Client Action Buttons + inline reply: 1.5d
- Client History UI updates: 0.5d
- Tests + polish: 1d

**Total: ~9 dev-days.** Could ship in 2 weeks with usual context-switching overhead.
