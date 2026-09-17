# Notification Reach Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the daily study reminder reach and be *seen by* the users who already have the app.

**Architecture:** The decision of what to do about notification permission is extracted into a pure, Flutter-free Dart module that maps a permission status plus local history to one of four actions. `NotificationService` becomes a thin caller of that module. Timezone reporting is lifted out of the token-registration block so it no longer depends on a permission it never needed. The backend gains one field so the authorization level is measurable at all.

**Tech Stack:** Flutter 3 + Riverpod, `firebase_messaging`, `app_settings`, `flutter_timezone`, `shared_preferences`; Node 20 + Mongoose, `node:test`, `mongodb-memory-server`.

**Spec:** `docs/superpowers/specs/2026-09-17-notification-reach-design.md`

## Global Constraints

- Dart: no new pubspec dependencies. `permission_handler ^11.0.1`, `app_settings ^5.1.1`, `flutter_timezone ^5.1.0`, `firebase_messaging ^15.0.0` are already present.
- Backend: `notificationAuthorization` enum values are exactly `authorized`, `provisional`, `denied`, `notDetermined`. Default `null` (never reported).
- A user whose status is `authorized` must see **no behavioural change whatsoever**. This is the safety property of the whole change.
- Timezone reporting must never block startup and must swallow its own failures, as it does today.
- All new user-visible strings go through `AppLocalizations` and must be added to all 19 `.arb` locales; run `flutter gen-l10n` before analyzing.
- Never ask for permission on the splash screen or in `main.dart`.
- App tests: `flutter test`. Backend tests: `npm test` (already `--test-force-exit`).

---

## File Structure

**Create:**
- `bananatalk_app/lib/services/notification_permission.dart` — pure decision logic. No Flutter, no Firebase imports. Owns `NotificationPermission`, `NotificationAction`, `notificationActionFor`, `permissionFromStatusName`.
- `bananatalk_app/test/services/notification_permission_test.dart` — table tests for the above.
- `bananatalk_app/lib/widgets/notifications_off_card.dart` — the recovery surface, used by both settings and the study screen.
- `backend/test/notificationAuthorization.test.js` — backend field + endpoint tests.

**Modify:**
- `backend/models/User.js` — add `notificationAuthorization`.
- `backend/controllers/notifications.js:30` — `registerToken` accepts and persists it.
- `bananatalk_app/lib/services/notification_service.dart` — branch on status instead of asking unconditionally; make `reportTimezone()` public; send the authorization level.
- `bananatalk_app/lib/services/notification_api_client.dart:476` — send `authorization` with the token.
- `bananatalk_app/lib/pages/settings/notification_preferences_screen.dart` — recovery card; disable toggles when denied.

---

## Task 1: Backend stores the authorization level

**Files:**
- Modify: `backend/models/User.js`
- Modify: `backend/controllers/notifications.js:30-72`
- Test: `backend/test/notificationAuthorization.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `User.notificationAuthorization: 'authorized'|'provisional'|'denied'|'notDetermined'|null`, settable via `POST /notifications/register-token` body field `authorization`.

- [ ] **Step 1: Write the failing test**

```js
// backend/test/notificationAuthorization.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
});
test.after(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});

const User = require('../models/User');

test('notificationAuthorization accepts the four real statuses', async () => {
  for (const value of ['authorized', 'provisional', 'denied', 'notDetermined']) {
    const u = new User({ name: 'x', email: `${value}@e.com`, password: 'secret123', notificationAuthorization: value });
    await assert.doesNotReject(u.validate(), `${value} should be valid`);
  }
});

test('notificationAuthorization rejects anything else', async () => {
  const u = new User({ name: 'x', email: 'bad@e.com', password: 'secret123', notificationAuthorization: 'granted' });
  await assert.rejects(u.validate(), /notificationAuthorization/);
});

test('it defaults to null so "never reported" is distinguishable from "denied"', async () => {
  const u = new User({ name: 'x', email: 'null@e.com', password: 'secret123' });
  assert.equal(u.notificationAuthorization, null);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test test/notificationAuthorization.test.js`
Expected: FAIL — the enum test passes vacuously but the rejection test fails, because an unknown field is silently ignored by Mongoose until the path exists.

- [ ] **Step 3: Add the field**

In `backend/models/User.js`, directly after the `fcmTokens` array definition:

```js
  // Which authorization level the device reported at its last token
  // registration. Needed because provisional (iOS) delivers QUIETLY -- no
  // banner, no sound, no lock screen -- and is otherwise indistinguishable
  // from full authorization server-side. Without this, "407 iOS users have
  // tokens" cannot be turned into "how many can actually see a reminder".
  // null means never reported, which is NOT the same as denied.
  notificationAuthorization: {
    type: String,
    enum: ['authorized', 'provisional', 'denied', 'notDetermined'],
    default: null,
  },
```

- [ ] **Step 4: Run the test again**

Run: `cd backend && node --test test/notificationAuthorization.test.js`
Expected: PASS (3/3)

- [ ] **Step 5: Persist it on token registration**

In `backend/controllers/notifications.js`, change line 31 to destructure it and persist it before `await user.save()`:

```js
  const { token, platform, deviceId, deviceLocale, authorization } = req.body;
```

and immediately before `await user.save();`:

```js
  // Recorded rather than trusted for gating: the device is the only thing that
  // knows its real authorization level, but an old app build sends nothing, so
  // a missing value must never clobber a previously reported one.
  const AUTHORIZATIONS = ['authorized', 'provisional', 'denied', 'notDetermined'];
  if (AUTHORIZATIONS.includes(authorization)) {
    user.notificationAuthorization = authorization;
  }
```

- [ ] **Step 6: Add the endpoint test**

Append to `backend/test/notificationAuthorization.test.js`:

```js
test('an unknown authorization value never clobbers a stored one', async () => {
  const AUTHORIZATIONS = ['authorized', 'provisional', 'denied', 'notDetermined'];
  const apply = (user, authorization) => {
    if (AUTHORIZATIONS.includes(authorization)) user.notificationAuthorization = authorization;
    return user;
  };
  const user = { notificationAuthorization: 'authorized' };
  assert.equal(apply({ ...user }, undefined).notificationAuthorization, 'authorized');
  assert.equal(apply({ ...user }, 'garbage').notificationAuthorization, 'authorized');
  assert.equal(apply({ ...user }, 'denied').notificationAuthorization, 'denied');
});
```

- [ ] **Step 7: Run the whole backend suite**

Run: `cd backend && npm test`
Expected: all tests pass, count increased by 4.

- [ ] **Step 8: Commit**

```bash
cd backend
git add models/User.js controllers/notifications.js test/notificationAuthorization.test.js
git commit -m "feat(notifications): record the device's authorization level"
```

---

## Task 2: The pure permission decision module

**Files:**
- Create: `bananatalk_app/lib/services/notification_permission.dart`
- Test: `bananatalk_app/test/services/notification_permission_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum NotificationPermission { authorized, provisional, notDetermined, denied }`
  - `enum NotificationAction { none, ask, upgrade, recover }`
  - `NotificationAction notificationActionFor({required NotificationPermission permission, required bool alreadyPrompted})`
  - `NotificationPermission permissionFromStatusName(String name)`
  - `const String kPromptedPrefsKey = 'notification_prompt_shown';`

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/services/notification_permission_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/notification_permission.dart';

void main() {
  group('notificationActionFor', () {
    test('an authorized user is never disturbed', () {
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.authorized,
            alreadyPrompted: prompted,
          ),
          NotificationAction.none,
        );
      }
    });

    test('a provisional iOS user is offered an upgrade, once', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.provisional,
          alreadyPrompted: false,
        ),
        NotificationAction.upgrade,
      );
      expect(
        notificationActionFor(
          permission: NotificationPermission.provisional,
          alreadyPrompted: true,
        ),
        NotificationAction.none,
      );
    });

    test('an unasked user is asked, once', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.notDetermined,
          alreadyPrompted: false,
        ),
        NotificationAction.ask,
      );
      expect(
        notificationActionFor(
          permission: NotificationPermission.notDetermined,
          alreadyPrompted: true,
        ),
        NotificationAction.none,
      );
    });

    test('a denied user is offered recovery, and asking again is never attempted', () {
      // The OS will not show the dialog again, so `ask` here would be a no-op
      // that silently burns the one chance the UI has to say something useful.
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.denied,
            alreadyPrompted: prompted,
          ),
          NotificationAction.recover,
        );
      }
    });
  });

  group('permissionFromStatusName', () {
    test('maps the Firebase AuthorizationStatus names', () {
      expect(permissionFromStatusName('authorized'), NotificationPermission.authorized);
      expect(permissionFromStatusName('provisional'), NotificationPermission.provisional);
      expect(permissionFromStatusName('denied'), NotificationPermission.denied);
      expect(permissionFromStatusName('notDetermined'), NotificationPermission.notDetermined);
    });

    test('an unknown name is treated as notDetermined, never as authorized', () {
      // Guessing "authorized" would suppress the ask forever on a platform
      // whose status name we failed to anticipate.
      expect(permissionFromStatusName('ephemeral'), NotificationPermission.notDetermined);
      expect(permissionFromStatusName(''), NotificationPermission.notDetermined);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/services/notification_permission_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:bananatalk_app/services/notification_permission.dart'`

- [ ] **Step 3: Write the module**

```dart
// bananatalk_app/lib/services/notification_permission.dart
/// What to do about notification permission, decided without touching the OS.
///
/// Pure and Firebase-free so the decision can be tested without a device. The
/// logic it replaces lived inline in `NotificationService.initialize()`, where
/// it asked unconditionally on the splash screen and treated `provisional` as
/// equivalent to `authorized` -- which is why hundreds of iOS users hold a
/// token that only ever delivers silently.
library;

/// The permission states that change what we do. Mirrors Firebase's
/// `AuthorizationStatus` by name, deliberately decoupled from its type so this
/// file imports nothing.
enum NotificationPermission { authorized, provisional, notDetermined, denied }

/// What the app should do next.
///
/// - [none]    leave the user alone
/// - [ask]     request permission for the first time (raises the OS dialog)
/// - [upgrade] ask a provisional iOS user for full, visible delivery
/// - [recover] the OS will not ask again; point at system settings instead
enum NotificationAction { none, ask, upgrade, recover }

/// SharedPreferences key recording that we have already used our one chance.
const String kPromptedPrefsKey = 'notification_prompt_shown';

/// Decide what to do.
///
/// [alreadyPrompted] deliberately does NOT suppress [recover]: recovery is a
/// piece of UI the user can act on at any time, not a one-shot OS dialog, and
/// someone who denied months ago should still be told why notifications are
/// silent.
NotificationAction notificationActionFor({
  required NotificationPermission permission,
  required bool alreadyPrompted,
}) {
  switch (permission) {
    case NotificationPermission.authorized:
      return NotificationAction.none;
    case NotificationPermission.denied:
      return NotificationAction.recover;
    case NotificationPermission.provisional:
      return alreadyPrompted ? NotificationAction.none : NotificationAction.upgrade;
    case NotificationPermission.notDetermined:
      return alreadyPrompted ? NotificationAction.none : NotificationAction.ask;
  }
}

/// Map a Firebase `AuthorizationStatus.name` onto [NotificationPermission].
///
/// Anything unrecognised becomes [NotificationPermission.notDetermined] rather
/// than `authorized`: guessing "authorized" would permanently suppress the ask
/// on a platform whose status name we failed to anticipate, which is the
/// failure mode that is invisible in production.
NotificationPermission permissionFromStatusName(String name) {
  switch (name) {
    case 'authorized':
      return NotificationPermission.authorized;
    case 'provisional':
      return NotificationPermission.provisional;
    case 'denied':
      return NotificationPermission.denied;
    default:
      return NotificationPermission.notDetermined;
  }
}
```

- [ ] **Step 4: Run the test again**

Run: `cd bananatalk_app && flutter test test/services/notification_permission_test.dart`
Expected: PASS (6/6)

- [ ] **Step 5: Commit**

```bash
cd bananatalk_app
git add lib/services/notification_permission.dart test/services/notification_permission_test.dart
git commit -m "feat(notifications): pure permission decision module"
```

---

## Task 3: Timezone stops depending on notification permission

**Files:**
- Modify: `bananatalk_app/lib/services/notification_service.dart:571,583`
- Modify: `bananatalk_app/lib/services/notification_service.dart:593` (`registerToken`)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `Future<void> NotificationService.reportTimezone()` — public, callable regardless of permission state.

- [ ] **Step 1: Make the method public**

In `notification_service.dart`, rename `_reportTimezone` to `reportTimezone` and replace its doc comment's first line with:

```dart
  /// Report the device's real IANA timezone identifier (e.g.
  /// "Asia/Shanghai").
  ///
  /// PUBLIC and called independently of notification permission. It used to
  /// live inside the FCM token-registration block, so a user who never granted
  /// notifications also never reported a timezone -- and `localHourFor` then
  /// fell back to UTC, putting their 19:00 daily drop at 04:00 in Seoul and
  /// 03:00 in Shanghai. Timezone never needed that permission.
```

- [ ] **Step 2: Call it on login, not only on token registration**

In `registerToken(String userId)`, insert immediately after `_currentUserId = userId;`:

```dart
    // Before the early returns below: a user with no FCM token still has a
    // timezone, and scheduled sends for every OTHER channel depend on it.
    unawaited(reportTimezone());
```

Leave the existing `unawaited(_reportTimezone())` call site renamed to `reportTimezone()`. It is now redundant on the happy path and harmless — the endpoint is idempotent — and it still covers token refresh, which does not go through `registerToken`.

- [ ] **Step 3: Verify it compiles and nothing regressed**

Run: `cd bananatalk_app && flutter analyze lib/services/notification_service.dart && flutter test`
Expected: no analyzer issues; full suite passes.

- [ ] **Step 4: Commit**

```bash
cd bananatalk_app
git add lib/services/notification_service.dart
git commit -m "fix(notifications): report timezone regardless of permission"
```

---

## Task 4: `initialize()` branches instead of asking

**Files:**
- Modify: `bananatalk_app/lib/services/notification_service.dart:96-135`
- Modify: `bananatalk_app/lib/services/notification_api_client.dart`

**Interfaces:**
- Consumes: `notificationActionFor`, `permissionFromStatusName`, `NotificationPermission`, `NotificationAction`, `kPromptedPrefsKey` from Task 2.
- Produces:
  - `NotificationAction? NotificationService.pendingAction` — what the UI should do at the next primed moment; null when nothing is pending.
  - `Future<bool> NotificationService.requestFullAuthorization()` — raises the real dialog (`provisional: false`); returns whether the result is `authorized`.

- [ ] **Step 1: Stop asking unconditionally**

In `initialize()`, replace the line `final settings = await _requestPermission();` with:

```dart
      // Read, do not ask. Asking here means asking on the splash screen,
      // before the user has seen a single screen or has any reason to accept.
      final settings = await _fcm!.getNotificationSettings();
      final permission = permissionFromStatusName(settings.authorizationStatus.name);

      final prefs = await SharedPreferences.getInstance();
      final alreadyPrompted = prefs.getBool(kPromptedPrefsKey) ?? false;
      _pendingAction = notificationActionFor(
        permission: permission,
        alreadyPrompted: alreadyPrompted,
      );
```

- [ ] **Step 2: Keep set-up running for provisional and notDetermined**

The existing guard is:

```dart
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
```

Replace it with:

```dart
      // Handlers and local-notification set-up run for everyone except a hard
      // denial: a notDetermined user may grant later in this same session, and
      // nothing below shows anything to the user by itself.
      if (permission != NotificationPermission.denied) {
```

- [ ] **Step 3: Expose the pending action and the upgrade call**

Add to the class, next to `fcmToken`:

```dart
  NotificationAction? _pendingAction;

  /// What the UI should do at the next primed moment, or null when the user
  /// needs nothing. Read by the chat trigger and the recovery surfaces.
  NotificationAction? get pendingAction => _pendingAction;

  /// Raise the REAL permission dialog.
  ///
  /// `provisional: false` is the whole point: the app has only ever requested
  /// provisional authorization, which iOS grants silently and then delivers
  /// quietly -- no banner, no sound, no lock screen. This is the call that
  /// converts an invisible reminder into a visible one.
  Future<bool> requestFullAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPromptedPrefsKey, true);
    _pendingAction = null;

    final settings = await _fcm!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
    if (granted) {
      await _getFCMToken();
    }
    return granted;
  }
```

- [ ] **Step 4: Send the authorization level with the token**

In `notification_api_client.dart`, add an `authorization` parameter to the register-token body. In `_registerTokenWithBackend`, pass `(await _fcm!.getNotificationSettings()).authorizationStatus.name`.

- [ ] **Step 5: Verify**

Run: `cd bananatalk_app && flutter analyze && flutter test`
Expected: no analyzer issues; full suite passes.

- [ ] **Step 6: Commit**

```bash
cd bananatalk_app
git add lib/services/notification_service.dart lib/services/notification_api_client.dart
git commit -m "fix(notifications): branch on status instead of asking at splash"
```

---

## Task 5: Prime the ask on first chat interaction

**Files:**
- Modify: `bananatalk_app/lib/pages/chat/conversation/chat_conversation_screen.dart`
- Modify: all 19 `bananatalk_app/lib/l10n/app_*.arb`

**Interfaces:**
- Consumes: `NotificationService.pendingAction`, `NotificationService.requestFullAuthorization()` from Task 4.
- Produces: nothing consumed later.

- [ ] **Step 1: Add the strings**

To `lib/l10n/app_en.arb` (and a translation to each of the other 18):

```json
  "notifyRepliesTitle": "Get notified when someone replies",
  "notifyRepliesBody": "We'll let you know about new messages and your daily study reminder. You can turn either off any time.",
  "notifyRepliesEnable": "Turn on",
  "notifyRepliesLater": "Not now",
```

The body mentions the study reminder deliberately: the permission is one switch, and asking under chat framing while silently using it for study would be a bait-and-switch.

- [ ] **Step 2: Regenerate localizations**

Run: `cd bananatalk_app && flutter gen-l10n`
Expected: `lib/l10n/app_localizations*.dart` regenerated with the four new getters.

- [ ] **Step 3: Show the sheet once, on entering a conversation**

In `chat_conversation_screen.dart`'s `initState`, after existing set-up:

```dart
    // Primed here rather than at splash: 43% of active users send a message in
    // a month, 4% have ever finished a daily drop. Priming on study completion
    // would reach almost nobody -- it is the same chicken-and-egg that produced
    // the current numbers. One OS permission covers both.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrimeNotifications());
```

and the method:

```dart
  Future<void> _maybePrimeNotifications() async {
    final service = NotificationService();
    final action = service.pendingAction;
    if (action != NotificationAction.ask && action != NotificationAction.upgrade) {
      return;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.notifyRepliesTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.notifyRepliesBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.notifyRepliesEnable),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.notifyRepliesLater),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await service.requestFullAuthorization();
    } else {
      // Dismissal burns the one chance too: nagging on every conversation open
      // is how an app teaches people to refuse reflexively.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPromptedPrefsKey, true);
    }
  }
```

- [ ] **Step 4: Verify**

Run: `cd bananatalk_app && flutter analyze && flutter test`
Expected: no analyzer issues; full suite passes.

- [ ] **Step 5: Commit**

```bash
cd bananatalk_app
git add lib/pages/chat/conversation/chat_conversation_screen.dart lib/l10n/
git commit -m "feat(notifications): prime the permission ask in chat"
```

---

## Task 6: Recovery surface for users who already denied

**Files:**
- Create: `bananatalk_app/lib/widgets/notifications_off_card.dart`
- Modify: `bananatalk_app/lib/pages/settings/notification_preferences_screen.dart`
- Modify: all 19 `bananatalk_app/lib/l10n/app_*.arb`

**Interfaces:**
- Consumes: `NotificationService.pendingAction`, `NotificationAction` from Tasks 2 and 4.
- Produces: `NotificationsOffCard` — a `StatelessWidget` taking no required arguments.

- [ ] **Step 1: Add the strings**

To `lib/l10n/app_en.arb` (and each of the other 18):

```json
  "notificationsOffTitle": "Notifications are off",
  "notificationsOffBody": "Your device is blocking notifications from BananaTalk, so reminders and messages can't reach you. The settings below won't take effect until you turn them on.",
  "notificationsOffOpen": "Open settings",
```

- [ ] **Step 2: Write the card**

```dart
// bananatalk_app/lib/widgets/notifications_off_card.dart
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/notification_permission.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Shown when the OS is blocking notifications.
///
/// This is the ONLY route back for a user who has already denied: iOS and
/// Android 13+ never show the permission dialog a second time, so priming is
/// irrelevant to them and a button into system settings is all that is left.
///
/// Renders nothing unless the pending action is [NotificationAction.recover],
/// so it is safe to place unconditionally.
class NotificationsOffCard extends StatelessWidget {
  const NotificationsOffCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (NotificationService().pendingAction != NotificationAction.recover) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('notifications-off-card'),
      color: scheme.errorContainer,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.notificationsOffTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 6),
            Text(l10n.notificationsOffBody,
                style: TextStyle(color: scheme.onErrorContainer)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => AppSettings.openAppSettings(
                type: AppSettingsType.notification,
              ),
              child: Text(l10n.notificationsOffOpen),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Place it and disable the dead toggles**

In `notification_preferences_screen.dart`, insert `const NotificationsOffCard()` as the first child of the settings list, and wrap the existing toggle list in:

```dart
    // Toggles that cannot fire are worse than no toggles: they tell the user
    // notifications are configured when the OS is discarding all of them.
    IgnorePointer(
      ignoring: NotificationService().pendingAction == NotificationAction.recover,
      child: Opacity(
        opacity: NotificationService().pendingAction == NotificationAction.recover ? 0.5 : 1.0,
        child: /* existing toggle list */,
      ),
    ),
```

- [ ] **Step 4: Regenerate, analyze, test**

Run: `cd bananatalk_app && flutter gen-l10n && flutter analyze && flutter test`
Expected: no analyzer issues; full suite passes.

- [ ] **Step 5: Commit**

```bash
cd bananatalk_app
git add lib/widgets/notifications_off_card.dart lib/pages/settings/notification_preferences_screen.dart lib/l10n/
git commit -m "feat(notifications): recovery path for users who denied"
```

---

## Task 7: Record the measurement baseline

**Files:**
- Create: `backend/migrations/reportNotificationReach.js`

**Interfaces:**
- Consumes: `User.notificationAuthorization` from Task 1.
- Produces: a read-only report; writes nothing.

- [ ] **Step 1: Write the reporter**

```js
// backend/migrations/reportNotificationReach.js
'use strict';

/**
 * Read-only reach report. Writes nothing.
 *
 * The spec's claim -- that hundreds of iOS users hold a token that only ever
 * delivers silently -- is an inference until this prints a provisional count.
 * Run it before and after the app release that lands this work.
 *
 *   node migrations/reportNotificationReach.js
 */

require('dotenv').config({ path: './config/config.env' });
const mongoose = require('mongoose');

const D = (n) => new Date(Date.now() - n * 86400000);

const run = async () => {
  if (!process.env.MONGO_URI) {
    console.error('✗ MONGO_URI is not set');
    process.exit(1);
  }
  await mongoose.connect(process.env.MONGO_URI);
  const users = mongoose.connection.collection('users');

  const active = { lastActive: { $gte: D(30) } };
  const hasToken = { 'fcmTokens.0': { $exists: true } };
  const row = async (label, filter) =>
    console.log(`  ${label.padEnd(44)} ${await users.countDocuments(filter)}`);

  console.log('REACH');
  await row('registered', {});
  await row('active in 30d', active);
  await row('active + has token', { ...active, ...hasToken });
  await row('active + has token + has timezone', {
    ...active, ...hasToken, timezone: { $exists: true, $nin: [null, ''] },
  });

  console.log('\nAUTHORIZATION LEVEL (null = never reported)');
  const byAuth = await users.aggregate([
    { $match: active },
    { $group: { _id: '$notificationAuthorization', n: { $sum: 1 } } },
    { $sort: { n: -1 } },
  ]).toArray();
  for (const r of byAuth) console.log(`  ${String(r._id).padEnd(44)} ${r.n}`);

  console.log('\nSTUDY');
  const C = require('../models/DailyDropCompletion');
  console.log(`  completions, last 7d                         ${await C.countDocuments({ createdAt: { $gte: D(7) } })}`);
  console.log(`  completions, all time                        ${await C.countDocuments()}`);
  console.log(`  distinct users who ever completed one        ${(await C.distinct('user')).length}`);

  await mongoose.disconnect();
};

run().catch(async (err) => {
  console.error('✗ report failed:', err && err.message);
  try { await mongoose.disconnect(); } catch { /* already down */ }
  process.exit(1);
});
```

- [ ] **Step 2: Run it against production**

Run: `cd backend && node migrations/reportNotificationReach.js`
Expected: prints the table. Every `notificationAuthorization` is `null` before the app release — that is the correct "before" reading, not a bug.

- [ ] **Step 3: Commit**

```bash
cd backend
git add migrations/reportNotificationReach.js
git commit -m "chore(notifications): read-only reach report"
```

---

## Manual verification before release

Not coverable by any test in this plan, and required:

1. **iOS, fresh install:** no permission dialog at splash. Open a chat — the sheet appears. Accept → the real iOS dialog appears. Grant → a test push arrives with a banner and sound, not silently.
2. **iOS, existing provisional user:** the upgrade sheet appears once on opening a chat, and never again after dismissal.
3. **iOS, denied:** the settings screen shows the red card, the toggles are visibly disabled, and the button opens the BananaTalk notification settings page.
4. **Android 13+, fresh install:** no dialog at splash; the runtime dialog appears only after accepting the sheet in a chat.
5. **Any platform, denied notifications:** confirm a timezone still reaches the server — `node migrations/reportNotificationReach.js` should show `active + has token + has timezone` rising independently of token counts.

Item 5 is the regression this whole plan exists to prevent.
