# Notification System v2 — Phase C1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the foundations layer of Notification System v2: quiet hours, smart bundling, frequency caps, localized templates, and rich-action notification buttons. After this lands, the system is trustworthy enough for the new engagement-notification types in Phase C2.

**Architecture:** Two repos. Backend (Node.js, MongoDB, FCM via firebase-admin, optional Redis) gains gating logic in `fcmService.sendToUser` (quiet hours → frequency cap → bundling), a server-side i18n template service, and two new daily/weekly counter-reset cron jobs. Frontend (Flutter, Riverpod) gains a Quiet Hours UI section, action-button categories registered with `flutter_local_notifications`, and history-screen polish for bundle counts + suppressed badges.

**Tech Stack:**
- **Backend**: Node 20, Express 4, Mongoose 6, firebase-admin 13, ioredis 5, `node:test` (native, no new deps)
- **Frontend**: Flutter, Riverpod 2.x, `firebase_messaging`, `flutter_local_notifications`
- **Tooling**: `dart analyze`, `node --test`, `mongosh` for migration check

---

## Spec reference

`docs/superpowers/specs/2026-05-04-notification-system-v2-c1-quiet-hours-bundling-design.md`

Re-read Sections 4 (Architecture), 6 (API changes), 7 (Sequencing) before starting.

---

## File structure (what gets touched)

### Backend (`/Users/firdavsmutalipov/Projects/BananaTalk/backend/`)

| File | Action | Purpose |
|---|---|---|
| `models/User.js` | modify (add ~20 lines around L130) | `quietHours`, `notificationCounters` schema fields |
| `migrations/addQuietHoursAndCounters.js` | **new** | Backfill defaults on existing users |
| `lib/quietHours.js` | **new** | `isInQuietHours(user, now)` pure helper |
| `services/notificationTemplateService.js` | **new** | `render(type, locale, vars)` with locale fallback |
| `notification_templates/en.json` | **new** | English templates (existing strings extracted) |
| `notification_templates/ko.json` | **new** | Korean templates |
| `notification_templates/ja.json` | **new** | Japanese templates |
| `config/notificationCaps.js` | **new** | Per-type daily / weekly caps |
| `services/fcmService.js` | modify (wrap `sendToUser`) | Quiet-hours gate, frequency-cap gate, suppressed-history write |
| `services/notificationService.js` | modify (5 send-sites) | Use templateService instead of hardcoded English |
| `services/notificationBundlingService.js` | **new** | Coalesce `moment_like`, `profile_visit`, `follower_moment`, `friend_request` |
| `jobs/dailyCounterResetJob.js` | **new** | Reset `notificationCounters.daily` per user TZ |
| `jobs/weeklyCounterResetJob.js` | **new** | Reset `notificationCounters.weekly` |
| `jobs/scheduler.js` | modify | Register the two new reset crons |
| `controllers/notifications.js` | modify (`getSettings` / `updateSettings`) | Include `quietHours` field |
| `routes/notifications.js` | (no change — existing routes pass through) | – |
| `models/Notification.js` | modify (add `bundleSize`, `bundleActors`, `suppressedReason`) | Bundle metadata in history |
| `test/quietHours.test.js` | **new** | `node:test` for `isInQuietHours` |
| `test/notificationTemplate.test.js` | **new** | `node:test` for `render` |
| `test/notificationCaps.test.js` | **new** | `node:test` for cap enforcement |
| `test/notificationBundling.test.js` | **new** | `node:test` for bundling windows |

### Frontend (`/Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app/`)

| File | Action | Purpose |
|---|---|---|
| `lib/providers/notification_settings_provider.dart` | modify | Add `QuietHours` model + `updateQuietHours()` method |
| `lib/services/notification_api_client.dart` | modify | Send/receive `quietHours` in settings GET/PUT |
| `lib/pages/notifications/notification_settings_screen.dart` | modify (add ~120 lines) | Quiet Hours section: toggle, time pickers, allow-urgent sub-toggle |
| `lib/services/notification_service.dart` | modify | Register iOS categories, populate Android actions, gate `_handleForegroundMessage` on quiet hours |
| `lib/services/notification_router.dart` | modify | Handle action keys (`reply`, `view`, `profile`) and inline-reply payload |
| `lib/pages/notifications/notification_history_screen.dart` | modify | Bundle-count chip + suppressed badge |
| `lib/l10n/app_en.arb` | modify | Add ~12 new keys for Quiet Hours UI + history badges |

---

## Conventions

- **Commit message style**: `feat(notifications): <what>` or `test(notifications): <what>` — match existing repo style (`feat(...)`, `fix(...)`).
- **Test runner (backend)**: `node --test test/<file>.test.js` (Node 20 native runner; no Jest, no Mocha).
- **TDD loop**: every implementation task lists test → run-fail → impl → run-pass → commit as separate steps.
- **No editing both repos in one commit** — commit backend & frontend separately even if they're conceptually paired.
- **Branch**: do all of Phase C1 on `feat/notif-v2-c1`. Each task = its own commit.

---

## Task 1: Backend — Quiet Hours

**Goal:** User can set quiet hours. Backend `sendToUser` drops non-urgent pushes during the window.

**Files:**
- Modify: `backend/models/User.js`
- Create: `backend/migrations/addQuietHoursAndCounters.js`
- Create: `backend/lib/quietHours.js`
- Create: `backend/test/quietHours.test.js`
- Modify: `backend/services/fcmService.js`
- Modify: `backend/controllers/notifications.js`

### Step 1.1: Add `quietHours` and `notificationCounters` to User schema

- [ ] Open `backend/models/User.js`. Locate `notificationSettings: { ... }` (around line 89). After the closing brace and comma of `notificationSettings`, add the two new sub-schemas before `mutedChats`:

```javascript
  quietHours: {
    enabled: { type: Boolean, default: false },
    start: { type: String, default: '22:00' },
    end: { type: String, default: '08:00' },
    timezone: { type: String, default: 'Asia/Seoul' },
    allowUrgent: { type: Boolean, default: true },
  },
  notificationCounters: {
    daily: { type: Map, of: Number, default: () => new Map() },
    weekly: { type: Map, of: Number, default: () => new Map() },
    dailyResetAt: { type: Date, default: null },
    weeklyResetAt: { type: Date, default: null },
  },
```

- [ ] **Commit:**
```bash
git add backend/models/User.js
git commit -m "feat(notifications): add quietHours and notificationCounters fields to User schema"
```

### Step 1.2: Write migration to backfill defaults on existing users

- [ ] Create `backend/migrations/addQuietHoursAndCounters.js`:

```javascript
const mongoose = require('mongoose');
require('dotenv').config();
const User = require('../models/User');

async function migrate() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected. Backfilling quietHours + notificationCounters…');

  const result = await User.updateMany(
    { $or: [{ quietHours: { $exists: false } }, { notificationCounters: { $exists: false } }] },
    {
      $set: {
        quietHours: {
          enabled: false,
          start: '22:00',
          end: '08:00',
          timezone: 'Asia/Seoul',
          allowUrgent: true,
        },
        notificationCounters: {
          daily: {},
          weekly: {},
          dailyResetAt: null,
          weeklyResetAt: null,
        },
      },
    },
    { strict: false },
  );

  console.log(`Updated ${result.modifiedCount} users.`);
  await mongoose.disconnect();
  process.exit(0);
}

migrate().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] Add migration script to `backend/package.json` `scripts`:

```json
"migrate:notif-v2-c1": "node migrations/addQuietHoursAndCounters.js"
```

- [ ] Run against a **dev/staging** MongoDB (NOT production yet):
```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
npm run migrate:notif-v2-c1
```
Expected stdout: `Connected. Backfilling… Updated <N> users.`

- [ ] **Commit:**
```bash
git add backend/migrations/addQuietHoursAndCounters.js backend/package.json
git commit -m "feat(notifications): migration to backfill quietHours + counters defaults"
```

### Step 1.3: Write failing test for `isInQuietHours`

- [ ] Create `backend/test/quietHours.test.js`:

```javascript
const test = require('node:test');
const assert = require('node:assert/strict');
const { isInQuietHours } = require('../lib/quietHours');

const userInKST = (over) => ({
  quietHours: {
    enabled: true,
    start: '22:00',
    end: '08:00',
    timezone: 'Asia/Seoul',
    allowUrgent: true,
    ...over,
  },
});

test('returns false when disabled', () => {
  assert.equal(isInQuietHours(userInKST({ enabled: false }), new Date()), false);
});

test('detects overnight window — inside (23:30 KST)', () => {
  // 2026-05-04 14:30 UTC = 23:30 KST
  const now = new Date('2026-05-04T14:30:00Z');
  assert.equal(isInQuietHours(userInKST(), now), true);
});

test('detects overnight window — outside (10:00 KST)', () => {
  // 2026-05-04 01:00 UTC = 10:00 KST
  const now = new Date('2026-05-04T01:00:00Z');
  assert.equal(isInQuietHours(userInKST(), now), false);
});

test('detects intra-day window (13:00–15:00 local)', () => {
  // user with same-day window in UTC for simplicity
  const u = userInKST({ start: '13:00', end: '15:00', timezone: 'UTC' });
  assert.equal(isInQuietHours(u, new Date('2026-05-04T14:00:00Z')), true);
  assert.equal(isInQuietHours(u, new Date('2026-05-04T16:00:00Z')), false);
});

test('exact start boundary is inside window', () => {
  const u = userInKST({ start: '22:00', end: '08:00', timezone: 'UTC' });
  assert.equal(isInQuietHours(u, new Date('2026-05-04T22:00:00Z')), true);
});

test('exact end boundary is outside window', () => {
  const u = userInKST({ start: '22:00', end: '08:00', timezone: 'UTC' });
  assert.equal(isInQuietHours(u, new Date('2026-05-04T08:00:00Z')), false);
});
```

- [ ] Run to verify it FAILS (module doesn't exist):
```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
node --test test/quietHours.test.js
```
Expected: `Cannot find module '../lib/quietHours'` errors on all 6 tests.

### Step 1.4: Implement `isInQuietHours`

- [ ] Create `backend/lib/quietHours.js`:

```javascript
'use strict';

/**
 * Format a Date as 'HH:mm' in the given IANA timezone.
 */
function formatHHmm(date, timezone) {
  return new Intl.DateTimeFormat('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: timezone,
  }).format(date);
}

/**
 * Returns true if `now` falls within the user's quiet-hours window.
 * Handles overnight wrap (e.g. 22:00–08:00 = 22:00-23:59 OR 00:00-07:59).
 */
function isInQuietHours(user, now = new Date()) {
  const qh = user && user.quietHours;
  if (!qh || !qh.enabled) return false;

  const tz = qh.timezone || 'Asia/Seoul';
  const current = formatHHmm(now, tz); // 'HH:mm'
  const { start, end } = qh;

  if (start === end) return false; // empty window

  if (start < end) {
    // intra-day, e.g. 13:00–15:00 → start <= current < end
    return current >= start && current < end;
  }
  // overnight wrap, e.g. 22:00–08:00 → current >= start OR current < end
  return current >= start || current < end;
}

module.exports = { isInQuietHours };
```

- [ ] Run tests to verify PASS:
```bash
node --test test/quietHours.test.js
```
Expected: `# tests 6` `# pass 6` `# fail 0`.

- [ ] **Commit:**
```bash
git add backend/lib/quietHours.js backend/test/quietHours.test.js
git commit -m "feat(notifications): isInQuietHours helper with overnight-wrap + TZ tests"
```

### Step 1.5: Wire quiet-hours gate into `fcmService.sendToUser`

- [ ] Open `backend/services/fcmService.js`. At the top, add the import:

```javascript
const { isInQuietHours } = require('../lib/quietHours');
const Notification = require('../models/Notification');

const URGENT_TYPES = new Set(['incoming_call', 'missed_call']);
```

- [ ] Inside `sendToUser(userId, notification, data = {})`, immediately after the user is loaded (find `const user = await User.findById(userId)` or the existing user-fetch line) and before any FCM dispatch, insert:

```javascript
  // Quiet-hours gate
  const type = data && data.type;
  if (
    isInQuietHours(user, new Date()) &&
    !URGENT_TYPES.has(type) &&
    !(user.quietHours.allowUrgent && type === 'chat_message' /* TODO: VIP-partner gating in C2 */)
  ) {
    await Notification.create({
      userId,
      type: type || 'unknown',
      title: notification.title,
      body: notification.body,
      data,
      suppressedReason: 'quiet_hours',
      sentAt: new Date(),
    });
    return { suppressed: true, reason: 'quiet_hours' };
  }
```

- [ ] **Commit:**
```bash
git add backend/services/fcmService.js
git commit -m "feat(notifications): suppress non-urgent pushes during quiet hours"
```

### Step 1.6: Surface `quietHours` in the settings API

- [ ] Open `backend/controllers/notifications.js`. Locate the `getSettings` handler. Modify the response to include `quietHours`:

```javascript
const getSettings = async (req, res) => {
  const user = await User.findById(req.user._id).select('notificationSettings quietHours mutedChats');
  res.json({
    success: true,
    data: {
      ...user.notificationSettings.toObject(),
      mutedChats: user.mutedChats,
      quietHours: user.quietHours || {
        enabled: false, start: '22:00', end: '08:00',
        timezone: 'Asia/Seoul', allowUrgent: true,
      },
    },
  });
};
```

- [ ] In `updateSettings`, accept and validate `quietHours`:

```javascript
const updateSettings = async (req, res) => {
  const { quietHours, ...rest } = req.body;
  const update = {};

  // Existing notificationSettings keys
  for (const k of Object.keys(rest)) {
    if (rest[k] !== undefined) update[`notificationSettings.${k}`] = rest[k];
  }

  if (quietHours && typeof quietHours === 'object') {
    const HHMM = /^([01]\d|2[0-3]):([0-5]\d)$/;
    if (quietHours.start && !HHMM.test(quietHours.start)) {
      return res.status(400).json({ success: false, error: 'Invalid quietHours.start; use HH:mm' });
    }
    if (quietHours.end && !HHMM.test(quietHours.end)) {
      return res.status(400).json({ success: false, error: 'Invalid quietHours.end; use HH:mm' });
    }
    for (const k of ['enabled', 'start', 'end', 'timezone', 'allowUrgent']) {
      if (quietHours[k] !== undefined) update[`quietHours.${k}`] = quietHours[k];
    }
  }

  await User.findByIdAndUpdate(req.user._id, { $set: update });
  res.json({ success: true });
};
```

- [ ] Manual smoke (assumes a logged-in user token in `$TOKEN`):
```bash
curl -s -H "Authorization: Bearer $TOKEN" $API_BASE/api/v1/notifications/settings | jq .data.quietHours
# Expect: {enabled: false, start: "22:00", end: "08:00", timezone: "Asia/Seoul", allowUrgent: true}

curl -sX PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"quietHours":{"enabled":true,"start":"22:00","end":"08:00"}}' \
  $API_BASE/api/v1/notifications/settings
# Expect: {success: true}
```

- [ ] **Commit:**
```bash
git add backend/controllers/notifications.js
git commit -m "feat(notifications): expose and validate quietHours in settings API"
```

---

## Task 2: Frontend — Quiet Hours UI

**Goal:** Settings screen has a Quiet Hours section that toggles, picks times, and persists to backend. Foreground handler suppresses local notifications during the window.

**Files:**
- Modify: `lib/providers/notification_settings_provider.dart`
- Modify: `lib/services/notification_api_client.dart`
- Modify: `lib/pages/notifications/notification_settings_screen.dart`
- Modify: `lib/services/notification_service.dart`
- Modify: `lib/l10n/app_en.arb`

### Step 2.1: Add `QuietHours` model class + provider field

- [ ] Open `lib/providers/notification_settings_provider.dart`. Find the `NotificationSettings` data class. Add at the top of the file:

```dart
class QuietHours {
  final bool enabled;
  final String start; // 'HH:mm'
  final String end;
  final String timezone; // IANA
  final bool allowUrgent;

  const QuietHours({
    this.enabled = false,
    this.start = '22:00',
    this.end = '08:00',
    this.timezone = 'Asia/Seoul',
    this.allowUrgent = true,
  });

  QuietHours copyWith({bool? enabled, String? start, String? end, String? timezone, bool? allowUrgent}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
        timezone: timezone ?? this.timezone,
        allowUrgent: allowUrgent ?? this.allowUrgent,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'start': start,
        'end': end,
        'timezone': timezone,
        'allowUrgent': allowUrgent,
      };

  factory QuietHours.fromJson(Map<String, dynamic> j) => QuietHours(
        enabled: j['enabled'] ?? false,
        start: j['start'] ?? '22:00',
        end: j['end'] ?? '08:00',
        timezone: j['timezone'] ?? 'Asia/Seoul',
        allowUrgent: j['allowUrgent'] ?? true,
      );
}
```

- [ ] In `NotificationSettings`, add the field, copyWith arg, and fromJson/toJson handling:

```dart
final QuietHours quietHours;
```

(thread it through constructor, `copyWith`, `fromJson`, `toJson` consistently with existing fields).

- [ ] In `NotificationSettingsNotifier`, add a method:

```dart
Future<void> updateQuietHours(QuietHours qh) async {
  final current = state.value;
  if (current == null) return;
  state = AsyncValue.data(current.copyWith(quietHours: qh));
  await _apiClient.updateSettings({'quietHours': qh.toJson()});
}
```

- [ ] **Commit:**
```bash
git add lib/providers/notification_settings_provider.dart
git commit -m "feat(notifications): add QuietHours model + updateQuietHours notifier method"
```

### Step 2.2: API client passes through `quietHours`

- [ ] Open `lib/services/notification_api_client.dart`. In `getSettings`, ensure the JSON parser reads `quietHours` (delegated to `NotificationSettings.fromJson`). In `updateSettings`, accept `Map<String, dynamic>` body unchanged — already works since the controller accepts `quietHours` at the top level.

- [ ] Verify with `dart analyze`:
```bash
dart analyze lib/services/notification_api_client.dart lib/providers/notification_settings_provider.dart
```
Expected: `No issues found!`

- [ ] **Commit:**
```bash
git add lib/services/notification_api_client.dart
git commit -m "feat(notifications): pass quietHours through settings API client"
```

### Step 2.3: Add Quiet Hours section to settings screen

- [ ] Open `lib/pages/notifications/notification_settings_screen.dart`. Below the existing notification-types card and above any other sections, insert:

```dart
// Quiet Hours
Padding(
  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
  child: Text(
    AppLocalizations.of(context)!.quietHours,
    style: context.labelSmall.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
  ),
),
Container(
  margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  decoration: BoxDecoration(
    color: context.surfaceColor,
    borderRadius: AppRadius.borderMD,
    boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
  ),
  child: Column(
    children: [
      SwitchListTile(
        contentPadding: AppSpacing.paddingLG,
        title: Text(AppLocalizations.of(context)!.quietHoursEnable, style: context.titleMedium),
        subtitle: Text(
          AppLocalizations.of(context)!.quietHoursSubtitle,
          style: context.bodySmall,
        ),
        value: settings.quietHours.enabled,
        activeColor: AppColors.primary,
        onChanged: (v) => ref.read(notificationSettingsProvider.notifier)
            .updateQuietHours(settings.quietHours.copyWith(enabled: v)),
      ),
      if (settings.quietHours.enabled) ...[
        Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
        ListTile(
          contentPadding: AppSpacing.paddingLG,
          title: Text(AppLocalizations.of(context)!.quietHoursStart, style: context.titleSmall),
          trailing: Text(settings.quietHours.start, style: context.bodyMedium),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: _parseHHmm(settings.quietHours.start),
            );
            if (t != null) {
              ref.read(notificationSettingsProvider.notifier)
                  .updateQuietHours(settings.quietHours.copyWith(start: _formatHHmm(t)));
            }
          },
        ),
        Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
        ListTile(
          contentPadding: AppSpacing.paddingLG,
          title: Text(AppLocalizations.of(context)!.quietHoursEnd, style: context.titleSmall),
          trailing: Text(settings.quietHours.end, style: context.bodyMedium),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: _parseHHmm(settings.quietHours.end),
            );
            if (t != null) {
              ref.read(notificationSettingsProvider.notifier)
                  .updateQuietHours(settings.quietHours.copyWith(end: _formatHHmm(t)));
            }
          },
        ),
        Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
        SwitchListTile(
          contentPadding: AppSpacing.paddingLG,
          title: Text(AppLocalizations.of(context)!.quietHoursAllowUrgent, style: context.titleSmall),
          subtitle: Text(
            AppLocalizations.of(context)!.quietHoursAllowUrgentSubtitle,
            style: context.bodySmall,
          ),
          value: settings.quietHours.allowUrgent,
          activeColor: AppColors.primary,
          onChanged: (v) => ref.read(notificationSettingsProvider.notifier)
              .updateQuietHours(settings.quietHours.copyWith(allowUrgent: v)),
        ),
      ],
    ],
  ),
),
```

- [ ] At the bottom of the file (outside the build method), add the helpers:

```dart
TimeOfDay _parseHHmm(String s) {
  final parts = s.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _formatHHmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
```

- [ ] Open `lib/l10n/app_en.arb`. Before the closing `}`, add:

```json
"quietHours": "Quiet Hours",
"quietHoursEnable": "Enable Quiet Hours",
"quietHoursSubtitle": "Pause non-urgent notifications during a time window",
"quietHoursStart": "Start time",
"quietHoursEnd": "End time",
"quietHoursAllowUrgent": "Allow urgent notifications",
"quietHoursAllowUrgentSubtitle": "Calls and messages from VIP partners can still come through",
```

- [ ] Regenerate localizations:
```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
flutter gen-l10n
```

- [ ] Verify:
```bash
dart analyze lib/pages/notifications/notification_settings_screen.dart
```
Expected: `No issues found!` (or pre-existing warnings only).

- [ ] **Commit:**
```bash
git add lib/pages/notifications/notification_settings_screen.dart lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "feat(notifications): add Quiet Hours section to settings screen"
```

### Step 2.4: Foreground handler respects quiet hours

- [ ] Open `lib/services/notification_service.dart`. Find `_handleForegroundMessage(RemoteMessage message)` (line ~252). At the top of that method, before `_showLocalNotification(message)`, add a quick check based on cached settings (read from `notificationSettingsProvider` snapshot — exposed via a top-level helper):

```dart
// Quiet-hours guard for foreground locals
final qh = await _readCachedQuietHours();
final type = message.data['type'] as String?;
final urgent = type == 'incoming_call' || type == 'missed_call';
if (qh != null && qh.enabled && !urgent && _isLocalTimeInWindow(qh)) {
  // Skip local display; backend already wrote history.
  return;
}
```

Add the helpers at the bottom of the class:

```dart
Future<QuietHours?> _readCachedQuietHours() async {
  // Read from a JSON snapshot persisted by the provider (key 'qh_snapshot').
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('qh_snapshot');
  if (raw == null) return null;
  return QuietHours.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

bool _isLocalTimeInWindow(QuietHours qh) {
  final now = TimeOfDay.fromDateTime(DateTime.now());
  final start = _parseTOD(qh.start);
  final end = _parseTOD(qh.end);
  final n = now.hour * 60 + now.minute;
  final s = start.hour * 60 + start.minute;
  final e = end.hour * 60 + end.minute;
  if (s == e) return false;
  if (s < e) return n >= s && n < e;
  return n >= s || n < e;
}

TimeOfDay _parseTOD(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}
```

- [ ] In `notification_settings_provider.dart`, persist the snapshot after every `updateQuietHours`:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('qh_snapshot', jsonEncode(qh.toJson()));
```

- [ ] Verify:
```bash
dart analyze lib/services/notification_service.dart lib/providers/notification_settings_provider.dart
```

- [ ] **Commit:**
```bash
git add lib/services/notification_service.dart lib/providers/notification_settings_provider.dart
git commit -m "feat(notifications): foreground handler suppresses non-urgent during quiet hours"
```

---

## Task 3: Backend — Localized Templates

**Goal:** Notification copy is locale-aware. Existing send sites use `templateService.render(type, locale, vars)` instead of hardcoded English.

**Files:**
- Create: `backend/notification_templates/{en,ko,ja}.json`
- Create: `backend/services/notificationTemplateService.js`
- Create: `backend/test/notificationTemplate.test.js`
- Modify: `backend/services/notificationService.js`

### Step 3.1: Create template JSON files

- [ ] Create `backend/notification_templates/en.json`:

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
    "title": "❤️ {actorName} and {othersCount} others",
    "body": "liked your moment"
  },
  "moment_comment": {
    "title": "💬 {actorName}",
    "body": "commented: {snippet}"
  },
  "comment_reply": {
    "title": "↩️ {actorName} replied",
    "body": "{snippet}"
  },
  "comment_reaction": {
    "title": "{emoji} {actorName} reacted",
    "body": "Tap to view"
  },
  "comment_mention": {
    "title": "@ {actorName} mentioned you",
    "body": "{snippet}"
  },
  "friend_request_single": {
    "title": "👋 {actorName}",
    "body": "started following you"
  },
  "friend_request_bundle": {
    "title": "👋 {count} new followers",
    "body": "Tap to see who"
  },
  "profile_visit_single": {
    "title": "👀 {actorName} viewed your profile",
    "body": "Tap to see who"
  },
  "profile_visit_bundle": {
    "title": "👀 {count} new profile visitors",
    "body": "Tap to see who's interested"
  },
  "follower_moment_single": {
    "title": "📸 {actorName} shared a moment",
    "body": "Tap to view"
  },
  "follower_moment_bundle": {
    "title": "📸 {actorName} and {othersCount} others shared moments",
    "body": "Tap to view"
  }
}
```

- [ ] Create `backend/notification_templates/ko.json`:

```json
{
  "chat_message": {
    "title": "{senderName}",
    "body": "{message}"
  },
  "moment_like_single": {
    "title": "❤️ {actorName}",
    "body": "님이 회원님의 모먼트를 좋아합니다"
  },
  "moment_like_bundle": {
    "title": "❤️ {actorName}님 외 {othersCount}명",
    "body": "회원님의 모먼트를 좋아합니다"
  },
  "moment_comment": {
    "title": "💬 {actorName}",
    "body": "님의 댓글: {snippet}"
  },
  "comment_reply": {
    "title": "↩️ {actorName}님이 답글을 남겼습니다",
    "body": "{snippet}"
  },
  "comment_reaction": {
    "title": "{emoji} {actorName}님이 반응했습니다",
    "body": "탭하여 보기"
  },
  "comment_mention": {
    "title": "@ {actorName}님이 회원님을 언급했습니다",
    "body": "{snippet}"
  },
  "friend_request_single": {
    "title": "👋 {actorName}",
    "body": "님이 회원님을 팔로우합니다"
  },
  "friend_request_bundle": {
    "title": "👋 새 팔로워 {count}명",
    "body": "탭하여 확인"
  },
  "profile_visit_single": {
    "title": "👀 {actorName}님이 프로필을 봤습니다",
    "body": "탭하여 확인"
  },
  "profile_visit_bundle": {
    "title": "👀 새 방문자 {count}명",
    "body": "누가 관심을 보였는지 확인하세요"
  },
  "follower_moment_single": {
    "title": "📸 {actorName}님이 모먼트를 공유했습니다",
    "body": "탭하여 보기"
  },
  "follower_moment_bundle": {
    "title": "📸 {actorName}님 외 {othersCount}명이 모먼트를 공유했습니다",
    "body": "탭하여 보기"
  }
}
```

- [ ] Create `backend/notification_templates/ja.json`:

```json
{
  "chat_message": { "title": "{senderName}", "body": "{message}" },
  "moment_like_single": { "title": "❤️ {actorName}", "body": "さんがあなたのモーメントにいいねしました" },
  "moment_like_bundle": { "title": "❤️ {actorName}さん 他{othersCount}名", "body": "があなたのモーメントにいいねしました" },
  "moment_comment": { "title": "💬 {actorName}", "body": "さんからコメント: {snippet}" },
  "comment_reply": { "title": "↩️ {actorName}さんが返信", "body": "{snippet}" },
  "comment_reaction": { "title": "{emoji} {actorName}さんがリアクション", "body": "タップして表示" },
  "comment_mention": { "title": "@ {actorName}さんがあなたをメンションしました", "body": "{snippet}" },
  "friend_request_single": { "title": "👋 {actorName}", "body": "さんがあなたをフォローしました" },
  "friend_request_bundle": { "title": "👋 新しいフォロワー {count}人", "body": "タップして確認" },
  "profile_visit_single": { "title": "👀 {actorName}さんがプロフィールを見ました", "body": "タップして確認" },
  "profile_visit_bundle": { "title": "👀 新しい訪問者 {count}人", "body": "誰が興味を持っているか確認" },
  "follower_moment_single": { "title": "📸 {actorName}さんがモーメントを投稿", "body": "タップして表示" },
  "follower_moment_bundle": { "title": "📸 {actorName}さん 他{othersCount}名がモーメントを投稿", "body": "タップして表示" }
}
```

- [ ] **Commit:**
```bash
git add backend/notification_templates
git commit -m "feat(notifications): add en/ko/ja templates for all notification types"
```

### Step 3.2: Write failing test for `render`

- [ ] Create `backend/test/notificationTemplate.test.js`:

```javascript
const test = require('node:test');
const assert = require('node:assert/strict');
const { render } = require('../services/notificationTemplateService');

test('renders en template with vars', () => {
  const r = render('moment_like_single', 'en', { actorName: 'Alex' });
  assert.equal(r.title, '❤️ Alex');
  assert.equal(r.body, 'liked your moment');
});

test('falls back to en when locale missing', () => {
  const r = render('moment_like_single', 'xx', { actorName: 'Alex' });
  assert.equal(r.title, '❤️ Alex');
});

test('renders ko template', () => {
  const r = render('moment_like_single', 'ko', { actorName: '민수' });
  assert.match(r.body, /좋아합니다/);
});

test('handles missing var by leaving placeholder unfilled', () => {
  const r = render('moment_like_single', 'en', {});
  assert.equal(r.title, '❤️ {actorName}');
});

test('throws on unknown type', () => {
  assert.throws(() => render('not_a_type', 'en', {}));
});
```

- [ ] Run to verify FAIL:
```bash
node --test test/notificationTemplate.test.js
```
Expected: 5 failures, "Cannot find module".

### Step 3.3: Implement template service

- [ ] Create `backend/services/notificationTemplateService.js`:

```javascript
'use strict';
const fs = require('fs');
const path = require('path');

const TEMPLATES_DIR = path.join(__dirname, '..', 'notification_templates');
const cache = {};

function load(locale) {
  if (cache[locale]) return cache[locale];
  const fp = path.join(TEMPLATES_DIR, `${locale}.json`);
  if (!fs.existsSync(fp)) return null;
  cache[locale] = JSON.parse(fs.readFileSync(fp, 'utf8'));
  return cache[locale];
}

function interpolate(str, vars) {
  return str.replace(/\{(\w+)\}/g, (_, k) =>
    Object.prototype.hasOwnProperty.call(vars, k) ? String(vars[k]) : `{${k}}`,
  );
}

function render(type, locale = 'en', vars = {}) {
  const primary = load(locale) || load('en');
  if (!primary || !primary[type]) {
    throw new Error(`Unknown notification template: ${type}`);
  }
  const t = primary[type];
  return {
    title: interpolate(t.title || '', vars),
    body: interpolate(t.body || '', vars),
  };
}

module.exports = { render };
```

- [ ] Run tests to PASS:
```bash
node --test test/notificationTemplate.test.js
```
Expected: `# pass 5`.

- [ ] **Commit:**
```bash
git add backend/services/notificationTemplateService.js backend/test/notificationTemplate.test.js
git commit -m "feat(notifications): localized template service with en/ko/ja support"
```

### Step 3.4: Migrate `notificationService.js` send-sites

- [ ] Open `backend/services/notificationService.js`. At the top, add:

```javascript
const templateService = require('./notificationTemplateService');
```

- [ ] Find each send-site (lines ~76, ~138, ~180, ~218, ~251, ~507, ~532, ~557 — search for `title:` to verify). For each, replace the hardcoded `title` and `body` with a `render` call that uses the recipient's locale.

Example — `sendMomentLike`:

```javascript
const sendMomentLike = async (momentOwnerId, likerId, momentId) => {
  const owner = await User.findById(momentOwnerId);
  const liker = await User.findById(likerId);
  if (!owner || !liker) return;

  const { title, body } = templateService.render(
    'moment_like_single',
    owner.preferredLocale || 'en',
    { actorName: liker.name },
  );

  await fcmService.sendToUser(momentOwnerId, { title, body }, {
    type: 'moment_like',
    momentId: String(momentId),
    likerId: String(likerId),
  });
};
```

Repeat for `sendChatMessage` (`chat_message`), `sendMomentComment` (`moment_comment`), `sendFriendRequest` (`friend_request_single`), `sendProfileVisit` (`profile_visit_single`), and the inline cases at lines 507/532/557 (`comment_reply`, `comment_reaction`, `comment_mention`).

- [ ] Manual smoke: send yourself a chat message from another account, with `preferredLocale='ko'` set on your user record. Confirm the push title/body are Korean.

- [ ] **Commit:**
```bash
git add backend/services/notificationService.js
git commit -m "feat(notifications): migrate send-sites to localized templates"
```

---

## Task 4: Backend — Frequency Caps

**Goal:** Per-user, per-type ceilings prevent runaway pushes. Daily / weekly counters reset by cron.

**Files:**
- Create: `backend/config/notificationCaps.js`
- Modify: `backend/services/fcmService.js`
- Create: `backend/jobs/dailyCounterResetJob.js`
- Create: `backend/jobs/weeklyCounterResetJob.js`
- Modify: `backend/jobs/scheduler.js`
- Create: `backend/test/notificationCaps.test.js`

### Step 4.1: Caps config

- [ ] Create `backend/config/notificationCaps.js`:

```javascript
'use strict';

module.exports = {
  daily: {
    moment_like: 5,
    moment_comment: 10,
    profile_visit: 3,
    follower_moment: 5,
    friend_request: 10,
    comment_reply: 10,
    comment_reaction: 10,
    comment_mention: 10,
  },
  weekly: {
    re_engagement: 1,
    digest: 1,
  },
};
```

- [ ] **Commit:**
```bash
git add backend/config/notificationCaps.js
git commit -m "feat(notifications): per-type daily and weekly cap config"
```

### Step 4.2: Failing test for cap enforcement

- [ ] Create `backend/test/notificationCaps.test.js`:

```javascript
const test = require('node:test');
const assert = require('node:assert/strict');
const { isCapped, recordSend } = require('../services/fcmService');

const userWithCounts = (daily = {}, weekly = {}) => ({
  _id: 'u1',
  notificationCounters: { daily: new Map(Object.entries(daily)), weekly: new Map(Object.entries(weekly)) },
});

test('not capped under daily limit', () => {
  const u = userWithCounts({ moment_like: 4 });
  assert.equal(isCapped(u, 'moment_like'), false);
});

test('capped at daily limit', () => {
  const u = userWithCounts({ moment_like: 5 });
  assert.equal(isCapped(u, 'moment_like'), true);
});

test('weekly limit applies for re_engagement', () => {
  const u = userWithCounts({}, { re_engagement: 1 });
  assert.equal(isCapped(u, 're_engagement'), true);
});

test('unknown type is never capped', () => {
  const u = userWithCounts({});
  assert.equal(isCapped(u, 'system'), false);
});
```

- [ ] Run — expect FAIL (functions not exported yet).

### Step 4.3: Add `isCapped` + `recordSend` to fcmService

- [ ] Open `backend/services/fcmService.js`. Add:

```javascript
const caps = require('../config/notificationCaps');

function isCapped(user, type) {
  if (!user || !user.notificationCounters) return false;
  const dailyCap = caps.daily[type];
  const weeklyCap = caps.weekly[type];
  if (dailyCap !== undefined) {
    const used = (user.notificationCounters.daily?.get?.(type)) ?? 0;
    if (used >= dailyCap) return true;
  }
  if (weeklyCap !== undefined) {
    const used = (user.notificationCounters.weekly?.get?.(type)) ?? 0;
    if (used >= weeklyCap) return true;
  }
  return false;
}

async function recordSend(userId, type) {
  const updates = {};
  if (caps.daily[type] !== undefined) {
    updates[`notificationCounters.daily.${type}`] = 1;
  }
  if (caps.weekly[type] !== undefined) {
    updates[`notificationCounters.weekly.${type}`] = 1;
  }
  if (Object.keys(updates).length === 0) return;
  await User.updateOne({ _id: userId }, { $inc: updates });
}

module.exports = { sendToUser, sendToUsers, isCapped, recordSend };
```

- [ ] In `sendToUser`, after the quiet-hours gate, before FCM dispatch:

```javascript
  if (isCapped(user, type)) {
    await Notification.create({
      userId, type, title: notification.title, body: notification.body,
      data, suppressedReason: 'frequency_cap', sentAt: new Date(),
    });
    return { suppressed: true, reason: 'frequency_cap' };
  }
  // … existing FCM dispatch …
  await recordSend(userId, type);
```

- [ ] Run tests:
```bash
node --test test/notificationCaps.test.js
```
Expected: `# pass 4`.

- [ ] **Commit:**
```bash
git add backend/services/fcmService.js backend/test/notificationCaps.test.js
git commit -m "feat(notifications): per-type frequency caps with daily and weekly counters"
```

### Step 4.4: Daily counter reset cron

- [ ] Create `backend/jobs/dailyCounterResetJob.js`:

```javascript
'use strict';
const User = require('../models/User');

/**
 * Reset notificationCounters.daily for users whose local time crossed midnight
 * since their last reset. Run hourly; small per-user check keeps load low.
 */
async function run() {
  const users = await User.find(
    { 'quietHours.timezone': { $exists: true } },
    { _id: 1, 'quietHours.timezone': 1, 'notificationCounters.dailyResetAt': 1 },
  );

  const now = new Date();
  let resetCount = 0;

  for (const u of users) {
    const tz = u.quietHours?.timezone || 'Asia/Seoul';
    const localDate = new Intl.DateTimeFormat('en-CA', { timeZone: tz }).format(now); // 'YYYY-MM-DD'
    const lastReset = u.notificationCounters?.dailyResetAt;
    const lastDate = lastReset
      ? new Intl.DateTimeFormat('en-CA', { timeZone: tz }).format(lastReset)
      : null;

    if (lastDate !== localDate) {
      await User.updateOne(
        { _id: u._id },
        { $set: { 'notificationCounters.daily': {}, 'notificationCounters.dailyResetAt': now } },
      );
      resetCount += 1;
    }
  }

  console.log(`[dailyCounterResetJob] reset ${resetCount} users`);
}

module.exports = { run };
```

- [ ] **Commit:**
```bash
git add backend/jobs/dailyCounterResetJob.js
git commit -m "feat(notifications): daily counter reset job (per-user TZ aware)"
```

### Step 4.5: Weekly counter reset cron

- [ ] Create `backend/jobs/weeklyCounterResetJob.js`:

```javascript
'use strict';
const User = require('../models/User');

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

async function run() {
  const cutoff = new Date(Date.now() - SEVEN_DAYS_MS);
  const result = await User.updateMany(
    { $or: [
      { 'notificationCounters.weeklyResetAt': { $lt: cutoff } },
      { 'notificationCounters.weeklyResetAt': null },
      { 'notificationCounters.weeklyResetAt': { $exists: false } },
    ] },
    { $set: { 'notificationCounters.weekly': {}, 'notificationCounters.weeklyResetAt': new Date() } },
  );
  console.log(`[weeklyCounterResetJob] reset ${result.modifiedCount} users`);
}

module.exports = { run };
```

- [ ] **Commit:**
```bash
git add backend/jobs/weeklyCounterResetJob.js
git commit -m "feat(notifications): weekly counter reset job (rolling 7-day)"
```

### Step 4.6: Register crons in scheduler

- [ ] Open `backend/jobs/scheduler.js`. Add the imports near the top with other job imports:

```javascript
const dailyCounterResetJob = require('./dailyCounterResetJob');
const weeklyCounterResetJob = require('./weeklyCounterResetJob');
```

In the scheduler init, after existing schedules, add:

```javascript
// Daily counter reset — run every hour to catch all timezones crossing midnight
setInterval(() => dailyCounterResetJob.run().catch(e => console.error('[dailyCounterResetJob]', e)),
  60 * 60 * 1000); // 1 hour

// Weekly counter reset — run every 6 hours
setInterval(() => weeklyCounterResetJob.run().catch(e => console.error('[weeklyCounterResetJob]', e)),
  6 * 60 * 60 * 1000);
```

- [ ] **Commit:**
```bash
git add backend/jobs/scheduler.js
git commit -m "feat(notifications): wire counter-reset jobs into scheduler"
```

---

## Task 5: Backend — Bundling

**Goal:** Same-type events for the same user inside a window collapse to one push with a count.

**Files:**
- Create: `backend/services/notificationBundlingService.js`
- Create: `backend/test/notificationBundling.test.js`
- Modify: `backend/services/notificationService.js` (route bundleable types through bundler)
- Modify: `backend/models/Notification.js` (add `bundleSize`, `bundleActors`, `suppressedReason`)

### Step 5.1: Schema fields on Notification

- [ ] Open `backend/models/Notification.js`. Add to the schema:

```javascript
bundleSize: { type: Number, default: 1 },
bundleActors: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
suppressedReason: { type: String, enum: ['quiet_hours', 'frequency_cap', null], default: null },
```

- [ ] **Commit:**
```bash
git add backend/models/Notification.js
git commit -m "feat(notifications): bundle metadata + suppressedReason on Notification model"
```

### Step 5.2: Failing bundling test

- [ ] Create `backend/test/notificationBundling.test.js`:

```javascript
const test = require('node:test');
const assert = require('node:assert/strict');
const { collect, _flushNow, _reset } = require('../services/notificationBundlingService');

test('emits a single push after window for 5 likes', async () => {
  _reset();
  const dispatched = [];
  const dispatcher = (payload) => { dispatched.push(payload); return Promise.resolve(); };

  for (let i = 0; i < 5; i++) {
    await collect('user1', 'moment_like', { momentId: 'm1', actorId: `actor${i}`, actorName: `A${i}` }, dispatcher);
  }
  await _flushNow('user1', 'moment_like', 'm1');

  assert.equal(dispatched.length, 1);
  assert.equal(dispatched[0].count, 5);
  assert.equal(dispatched[0].actorIds.length, 5);
});

test('non-bundleable types pass through immediately', async () => {
  _reset();
  const dispatched = [];
  await collect('user1', 'chat_message', { actorName: 'X', message: 'hi' },
    (p) => { dispatched.push(p); return Promise.resolve(); });
  assert.equal(dispatched.length, 1);
  assert.equal(dispatched[0].count, 1);
});

test('different bundle keys do not coalesce', async () => {
  _reset();
  const dispatched = [];
  await collect('user1', 'moment_like', { momentId: 'm1', actorName: 'A' },
    (p) => { dispatched.push(p); return Promise.resolve(); });
  await collect('user1', 'moment_like', { momentId: 'm2', actorName: 'B' },
    (p) => { dispatched.push(p); return Promise.resolve(); });
  await _flushNow('user1', 'moment_like', 'm1');
  await _flushNow('user1', 'moment_like', 'm2');
  assert.equal(dispatched.length, 2);
});
```

- [ ] Run — expect FAIL.

### Step 5.3: Implement bundling service

- [ ] Create `backend/services/notificationBundlingService.js`:

```javascript
'use strict';

const BUNDLEABLE = {
  moment_like:      { window: 60_000,  keyFn: (d) => d.momentId },
  follower_moment:  { window: 60_000,  keyFn: (d) => d.momentId },
  profile_visit:    { window: 300_000, keyFn: () => 'all' },
  friend_request:   { window: 60_000,  keyFn: () => 'all' },
};

const buckets = new Map(); // `${userId}|${type}|${key}` -> { count, actorIds, vars, timer }

function bucketKey(userId, type, ck) { return `${userId}|${type}|${ck}`; }

async function collect(userId, type, data, dispatcher) {
  const cfg = BUNDLEABLE[type];
  if (!cfg) {
    // Pass-through
    await dispatcher({ userId, type, count: 1, actorIds: data.actorId ? [data.actorId] : [], vars: data });
    return;
  }
  const ck = cfg.keyFn(data) || 'all';
  const k = bucketKey(userId, type, ck);
  let bucket = buckets.get(k);
  if (!bucket) {
    bucket = { count: 0, actorIds: [], vars: data, timer: null };
    buckets.set(k, bucket);
    bucket.timer = setTimeout(() => flush(k, dispatcher), cfg.window);
  }
  bucket.count += 1;
  if (data.actorId) bucket.actorIds.push(data.actorId);
  // Keep most-recent vars (e.g. latest actorName) for template rendering
  bucket.vars = { ...bucket.vars, ...data };
}

async function flush(key, dispatcher) {
  const bucket = buckets.get(key);
  if (!bucket) return;
  buckets.delete(key);
  if (bucket.timer) clearTimeout(bucket.timer);
  const [userId, type] = key.split('|');
  await dispatcher({
    userId,
    type,
    count: bucket.count,
    actorIds: bucket.actorIds,
    vars: bucket.vars,
  });
}

// Test helpers
function _flushNow(userId, type, ck) {
  return flush(bucketKey(userId, type, ck), () => Promise.resolve());
}
function _reset() {
  for (const b of buckets.values()) if (b.timer) clearTimeout(b.timer);
  buckets.clear();
}

module.exports = { collect, _flushNow, _reset, BUNDLEABLE };
```

- [ ] Adapt the test's `_flushNow` to inject the recorded dispatcher: replace bundling-service's `_flushNow` with a version that takes a dispatcher and uses it. (Update both the test and the service to accept `dispatcher` in `_flushNow`. See revised version below.)

```javascript
// In notificationBundlingService.js, replace _flushNow:
function _flushNow(userId, type, ck, dispatcher) {
  return flush(bucketKey(userId, type, ck), dispatcher);
}
```

```javascript
// In test, pass the dispatcher:
await _flushNow('user1', 'moment_like', 'm1', (p) => { dispatched.push(p); return Promise.resolve(); });
```

- [ ] Run tests — expect PASS.

- [ ] **Commit:**
```bash
git add backend/services/notificationBundlingService.js backend/test/notificationBundling.test.js
git commit -m "feat(notifications): in-memory bundling for moment_like, profile_visit, follower_moment, friend_request"
```

### Step 5.4: Wire bundleable types through the bundler

- [ ] Open `backend/services/notificationService.js`. At the top, add:

```javascript
const bundlingService = require('./notificationBundlingService');
```

- [ ] Modify `sendMomentLike` to route through `bundlingService.collect`:

```javascript
const sendMomentLike = async (momentOwnerId, likerId, momentId) => {
  const owner = await User.findById(momentOwnerId);
  const liker = await User.findById(likerId);
  if (!owner || !liker) return;

  await bundlingService.collect(
    String(momentOwnerId),
    'moment_like',
    { momentId: String(momentId), actorId: String(likerId), actorName: liker.name },
    async (bundle) => {
      const tplKey = bundle.count > 1 ? 'moment_like_bundle' : 'moment_like_single';
      const { title, body } = templateService.render(tplKey, owner.preferredLocale || 'en', {
        actorName: bundle.vars.actorName,
        othersCount: bundle.count - 1,
      });
      await fcmService.sendToUser(momentOwnerId, { title, body }, {
        type: 'moment_like',
        momentId: String(momentId),
        bundleSize: bundle.count,
        bundleActors: bundle.actorIds,
      });
    },
  );
};
```

- [ ] Repeat for `sendFriendRequest` (`friend_request_bundle` template), `sendProfileVisit` (`profile_visit_bundle`), and follower-moment trigger if it lives elsewhere — search `backend/` for `type: 'follower_moment'` to locate.

- [ ] In `fcmService.sendToUser`, when writing to Notification history, include `bundleSize` and `bundleActors` from the `data` payload:

```javascript
await Notification.create({
  userId, type,
  title: notification.title, body: notification.body,
  data, sentAt: new Date(),
  bundleSize: data.bundleSize || 1,
  bundleActors: data.bundleActors || [],
});
```

- [ ] **Commit:**
```bash
git add backend/services/notificationService.js backend/services/fcmService.js
git commit -m "feat(notifications): route bundleable types through bundler with localized bundle templates"
```

---

## Task 6: Frontend — Action Buttons

**Goal:** Notifications carry inline-reply (chat) and tap actions (View / Profile). Action callbacks route correctly.

**Files:**
- Modify: `lib/services/notification_service.dart`
- Modify: `lib/services/notification_router.dart`

### Step 6.1: Register iOS categories

- [ ] Open `lib/services/notification_service.dart`. Find `notificationCategories: []` (line ~144). Replace with:

```dart
notificationCategories: [
  DarwinNotificationCategory(
    'CHAT_MESSAGE',
    actions: [
      DarwinNotificationAction.text(
        'reply',
        'Reply',
        buttonTitle: 'Send',
        placeholder: 'Type a reply…',
        options: { DarwinNotificationActionOption.foreground },
      ),
      DarwinNotificationAction.plain('view', 'View'),
    ],
  ),
  DarwinNotificationCategory(
    'MOMENT_SOCIAL',
    actions: [
      DarwinNotificationAction.plain('view', 'View'),
    ],
  ),
  DarwinNotificationCategory(
    'PROFILE_SOCIAL',
    actions: [
      DarwinNotificationAction.plain('profile', 'View Profile'),
    ],
  ),
],
```

- [ ] Verify imports include `DarwinNotificationCategory`, `DarwinNotificationAction`, `DarwinNotificationActionOption` from `package:flutter_local_notifications/flutter_local_notifications.dart`.

- [ ] **Commit:**
```bash
git add lib/services/notification_service.dart
git commit -m "feat(notifications): register iOS notification categories with reply + view + profile actions"
```

### Step 6.2: Handle action callbacks in the router

- [ ] Open `lib/services/notification_router.dart`. At the top of `handleNotification`, branch on `actionId` (the `flutter_local_notifications` callback supplies `actionId` in the response payload). Add to the switch:

```dart
final actionId = data['_actionId'] as String?;
if (actionId == 'reply') {
  // Inline reply — fired from text input
  final replyText = data['_input'] as String?;
  final senderId = data['senderId'] as String?;
  if (replyText != null && replyText.isNotEmpty && senderId != null) {
    await NotificationApiClient().sendQuickReply(receiverId: senderId, message: replyText);
  }
  return; // Don't navigate
}
if (actionId == 'view') {
  // Fall through to default routing for the type
}
if (actionId == 'profile') {
  final userId = data['actorId'] ?? data['senderId'];
  if (userId is String) goRouter.go('/profile/$userId');
  return;
}
```

- [ ] Add `sendQuickReply` to `lib/services/notification_api_client.dart`:

```dart
Future<bool> sendQuickReply({required String receiverId, required String message}) async {
  final headers = await _getHeaders();
  final res = await http.post(
    Uri.parse('${Endpoints.baseURL}messages'),
    headers: headers,
    body: jsonEncode({'receiver': receiverId, 'message': message}),
  );
  return res.statusCode == 200 || res.statusCode == 201;
}
```

- [ ] In `notification_service.dart`'s `_handleNotificationTap` callback, forward `actionId` and `input` into the data map before delegating:

```dart
void _handleNotificationTap(NotificationResponse response) {
  final payload = response.payload != null ? jsonDecode(response.payload!) : <String, dynamic>{};
  payload['_actionId'] = response.actionId;
  payload['_input'] = response.input;
  NotificationRouter.handleNotification(payload);
}
```

- [ ] Verify:
```bash
dart analyze lib/services/notification_service.dart lib/services/notification_router.dart lib/services/notification_api_client.dart
```

- [ ] **Commit:**
```bash
git add lib/services/notification_router.dart lib/services/notification_api_client.dart lib/services/notification_service.dart
git commit -m "feat(notifications): action-button routing — inline reply, view, profile"
```

### Step 6.3: Backend — set APNS category and Android actions

- [ ] Open `backend/services/fcmService.js`. In `sendToUser`, when building the FCM message, add:

```javascript
const TYPE_TO_CATEGORY = {
  chat_message: 'CHAT_MESSAGE',
  moment_like: 'MOMENT_SOCIAL',
  moment_comment: 'MOMENT_SOCIAL',
  follower_moment: 'MOMENT_SOCIAL',
  friend_request: 'PROFILE_SOCIAL',
  profile_visit: 'PROFILE_SOCIAL',
};

const ANDROID_ACTIONS = {
  CHAT_MESSAGE: [{ action: 'reply', title: 'Reply' }, { action: 'view', title: 'View' }],
  MOMENT_SOCIAL: [{ action: 'view', title: 'View' }],
  PROFILE_SOCIAL: [{ action: 'profile', title: 'View Profile' }],
};

// In the message builder:
const category = TYPE_TO_CATEGORY[type];
if (category) {
  message.apns = message.apns || { payload: { aps: {} } };
  message.apns.payload.aps.category = category;
  message.android = message.android || { notification: {} };
  message.android.notification.actions = ANDROID_ACTIONS[category];
}
```

- [ ] **Commit:**
```bash
git add backend/services/fcmService.js
git commit -m "feat(notifications): set APNS category + Android actions per notification type"
```

---

## Task 7: Frontend — History UI updates

**Goal:** Notification history shows bundle counts (chip) and suppressed badges (muted indicator).

**Files:**
- Modify: `lib/pages/notifications/notification_history_screen.dart`
- Modify: `lib/services/notification_api_client.dart` (model class for history items)
- Modify: `lib/l10n/app_en.arb`

### Step 7.1: Extend `NotificationItem` model

- [ ] Open `lib/services/notification_api_client.dart`. Find the `NotificationItem` class. Add fields:

```dart
final int bundleSize;
final String? suppressedReason;
```

Update constructor + `fromJson`:

```dart
bundleSize: (json['bundleSize'] as int?) ?? 1,
suppressedReason: json['suppressedReason'] as String?,
```

- [ ] **Commit:**
```bash
git add lib/services/notification_api_client.dart
git commit -m "feat(notifications): add bundleSize + suppressedReason to history item model"
```

### Step 7.2: Render bundle chip + suppressed badge

- [ ] Open `lib/pages/notifications/notification_history_screen.dart`. Find the row builder for each notification item. Replace the title-row with:

```dart
Row(
  children: [
    Expanded(
      child: Text(item.title, style: context.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    if (item.bundleSize > 1) ...[
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('+${item.bundleSize}',
          style: context.captionSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    ],
    if (item.suppressedReason != null) ...[
      const SizedBox(width: 6),
      Tooltip(
        message: item.suppressedReason == 'quiet_hours'
            ? AppLocalizations.of(context)!.silencedByQuietHours
            : AppLocalizations.of(context)!.silencedByCap,
        child: Icon(Icons.notifications_paused, size: 14, color: context.textMuted),
      ),
    ],
  ],
),
```

- [ ] Add to `lib/l10n/app_en.arb`:

```json
"silencedByQuietHours": "Silenced by Quiet Hours",
"silencedByCap": "Silenced by daily limit",
```

- [ ] Regenerate localizations:
```bash
flutter gen-l10n
```

- [ ] Verify:
```bash
dart analyze lib/pages/notifications/notification_history_screen.dart
```

- [ ] **Commit:**
```bash
git add lib/pages/notifications/notification_history_screen.dart lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "feat(notifications): bundle-count chip and suppressed badge in history UI"
```

---

## Final verification (run after all 7 tasks)

### Backend

- [ ] All node tests pass:
```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
node --test test/quietHours.test.js test/notificationTemplate.test.js test/notificationCaps.test.js test/notificationBundling.test.js
```
Expected: `# pass 20+`, `# fail 0`.

- [ ] Run migration on dev DB once more, idempotent:
```bash
npm run migrate:notif-v2-c1
```
Expected: `Updated 0 users` (already migrated).

- [ ] Server boot smoke:
```bash
npm run dev
```
Expected: starts without errors. Look for `[scheduler] registered: dailyCounterResetJob, weeklyCounterResetJob` in logs.

### Frontend

- [ ] Static analysis clean on touched files:
```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
dart analyze \
  lib/providers/notification_settings_provider.dart \
  lib/services/notification_service.dart \
  lib/services/notification_router.dart \
  lib/services/notification_api_client.dart \
  lib/pages/notifications/notification_settings_screen.dart \
  lib/pages/notifications/notification_history_screen.dart
```
Expected: no new errors (info-level lints OK).

- [ ] Build smoke:
```bash
flutter build ios --debug --no-codesign
```
Expected: exit 0.

### End-to-end smoke (manual)

1. Set quiet hours in app to **current hour ± 1h**.
2. Have another test account like 5 of your moments rapidly (within 60s).
3. **Expected**: 0 system notifications during the window. History shows 1 entry "❤️ {actor} and 4 others" with `+5` chip and a muted icon.
4. Disable quiet hours, like 1 more.
5. **Expected**: 1 system notification appears. History shows new entry, no chip, no muted icon.
6. From iOS lock screen, long-press the chat notification, type a reply, send.
7. **Expected**: Reply lands in chat (verify on the other test account); app stays closed.

### Acceptance criteria summary

- ✅ Quiet hours toggle persists; backend suppresses non-urgent pushes during window.
- ✅ Templates render in en/ko/ja; users with `preferredLocale='ko'` get Korean copy.
- ✅ Frequency caps prevent runaway pushes; daily/weekly counters reset by cron.
- ✅ Bundling collapses 5 likes within 60s into 1 push.
- ✅ Inline reply on iOS works; "View Profile" action navigates correctly.
- ✅ History shows bundle count chip (`+5`) and muted badge for suppressed entries.

---

## Rollback plan

Each task commits separately, so revert any single task's commits to roll back that feature. The User schema additions are additive (new fields with defaults) and safe to leave on disk even if code is reverted.

For a full rollback of Phase C1 in production:
```bash
git revert <commit-range-of-phase-c1> -m 1 -n
git commit -m "revert: roll back notif v2 c1"
# Migration is reversible by clearing the new fields, but leaving them is harmless.
```
