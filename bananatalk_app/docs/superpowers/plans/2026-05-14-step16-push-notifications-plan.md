# Step 16 — Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the five event-driven pushes (new chat message when offline / new follower / wave received / comment on your moment or story / VIP renewal warning) end-to-end. Fix four bugs surfaced during recon: chat push fires regardless of online status, VIP renewal warning is a stub, story comment owner isn't notified, Flutter router has missing cases for live push types.

**Architecture:** Backend push pipeline (`services/fcmService.js` + `services/notificationService.js`) already implements ~900 lines of the send mechanics — quiet hours, frequency caps, history persistence, invalid-token pruning. Most of the wave is gap-filling: add three missing `User.notificationPreferences` fields with a lazy fallback in `_shouldSendNotification`; gate the existing `sendChatMessage` call by online status; replace the VIP renewal stub with a typed `sendVipRenewalWarning` helper; add the missing notification for story comment owners. Flutter side closes router gaps for `wave`, `comment_reply`, `comment_reaction`, `comment_mention`, `vip_renewal_warning` plus three preference toggles.

**Tech Stack:** Node.js / Express / Mongoose / FCM Admin SDK (backend); Flutter / Riverpod / firebase_messaging / flutter_local_notifications (mobile). No new dependencies.

**Recon reference:** `docs/superpowers/recon/2026-05-14-step16-push-notifications-recon.md` — read before executing.

**Branches:** `feat/step16-push-notifications` on both repos.

**Estimated commits:** 8 (B1-B5 backend, F1-F2 Flutter, G1 glue).

**Pacing:** Drive uninterrupted through tasks per the user's recorded preference. Surface only at G1 or on a genuine blocker.

---

## Hard constraints (from the user)

- **Out of scope:** Scheduled / timed pushes (streak reminders, daily quota refresh, story expiring), in-app SnackBar / banner foreground UX, `friend_request` → `new_follower` type rename, mentions parsing, voice room invite push, user-facing notification inbox screen, quiet hours UI.
- **No refactoring of unrelated code.** The chat-gate change touches `socket/socketHandler.js`; the VIP-renewal stub fix touches `jobs/subscriptionExpiryJob.js`; the story-comment notification touches `controllers/comments.js`. Nothing else changes outside the push pipeline + Flutter router + preferences screen.
- **No new dependencies without explicit user approval.**
- **Match existing commit-message style** — no Co-Authored-By trailers, no marketing copy.
- **Both repos use branch `feat/step16-push-notifications`** for execution.

---

## Edge cases handled

- **Chat push during voice call.** Caller is connected to chat socket; chat push won't fire (correct — they're in the app).
- **Chat push with stale socket connection.** User's app crashed but socket cleanup hasn't run yet; `userConnections` still has them. Push won't fire until cleanup (~30s heartbeat). Acceptable; matches today's "user appears online for 30s after crash."
- **Multi-device chat presence.** User has phone + tablet. Phone is connected (in `userConnections`), tablet is not. Push doesn't fire to either device — that's correct, since one device has the live socket and FCM tokens deliver to all devices anyway.
- **Wave anti-spam survives.** Existing `>3 waves in 6h` suppression in `sendWave` is preserved.
- **Comment on own moment / story.** Existing self-comment gate in `controllers/comments.js:199` carries to the new story-comment path.
- **VIP renewal warning races with cancellation.** User cancels at day 6, warning job fires at day 7 because `endDate` is still > now. Warning still fires — by design. Cancelled VIPs should know their access is ending. Don't gate by `autoRenew`.
- **VIP renewal warning + grace period.** Existing `gracePeriodNotified` flag and `7day/3day/1day` warning flags are independent. Don't unify.
- **Preference field missing on existing user docs.** Three new fields default to `true`. Existing docs return `undefined` on property access until next save. `_shouldSendNotification` gets a `?? true` fallback so unknown-key reads default-allow. No DB migration.
- **Banned user receives a push.** Existing Step 14 ban clears `fcmTokens: []`. `fcmService.sendToUser` finds no active tokens, silently no-ops. Audit log not touched. Correct.
- **Frequency caps interaction.** A burst of waves / comments / followers / VIP warnings could exhaust the per-type daily cap. Existing `isCapped` returns suppression; `Notification` model records `suppressedReason`. No change.
- **Flutter router falls through to home for unknown type.** New cases prevent this, but if a future type ships without a case, today's behavior is "go to home" — acceptable fallback.

---

## Design decisions

1. **D-1 chat push delivery gate: GATE BY `userConnections.has(receiverId)`.** Single-line check in `socket/socketHandler.js` around the existing `sendChatMessage` call. Push fires only when receiver's chat socket is disconnected. **Rejected:** always-push (wastes FCM quota, double-notifies in-app users); per-active-chat tracking (bigger refactor, marginal benefit).

2. **D-2 preference field migration: LAZY `?? true` FALLBACK in `_shouldSendNotification`.** No DB migration. New fields added to schema with `default: true`; existing user docs read `undefined`, fallback evaluates to `true`. **Rejected:** eager migration (~1K writes, churn risk); skip fields entirely (breaks trust with users who toggle).

3. **D-3 story comment owner notification: ADD IT (parity with moments).** New type string `story_comment` for clean future surfacing; deep-link target `/story/{storyId}`. **Rejected:** punt to queued (creates inconsistent UX — moment comments notify, story comments don't, confusing).

4. **D-4 `friend_request` type string: KEEP AS-IS.** No rename. Add the `newFollower` *preference* field but the *type string* stays `friend_request`. Documented as semantic legacy. Future cleanup wave can rename with migration. **Rejected:** rename now (wave bloat, risk to in-flight pushes).

5. **D-5 VIP renewal helper: TYPED METHOD `notificationService.sendVipRenewalWarning(userId, daysLeft)`.** Matches the `sendChatMessage` / `sendWave` pattern. Title / body construction lives in `notificationService.js`, not the cron job. **Rejected:** inline `send()` (title/body in job, awkward for future localization).

6. **D-6 foreground UX: KEEP EXISTING BEHAVIOR.** New types render as system notifications when app is in foreground (matches today's wave / comment / follower behavior). SnackBar replacement is polish for a separate wave. **Rejected:** SnackBar / banner (new UI primitive, cross-cutting).

7. **D-7 chat preference field naming: KEEP `chat` (existing).** Don't rename. The other three new fields are `comment`, `newFollower`, `vipRenewalWarning` for forward consistency.

---

## File structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Modify:**
- `models/User.js` — add 3 fields to `notificationPreferences`: `comment`, `newFollower`, `vipRenewalWarning` (all Boolean, default true)
- `services/notificationService.js` — add `?? true` fallback in `_shouldSendNotification`; add `sendVipRenewalWarning(userId, daysLeft)` typed helper; add `sendStoryComment(storyOwnerId, commenterId, storyId, commentText)` typed helper
- `socket/socketHandler.js` — gate `sendChatMessage` call with `!userConnections.has(receiverId)`
- `jobs/subscriptionExpiryJob.js` — replace `sendPushNotification` stub with `notificationService.sendVipRenewalWarning(user._id, daysLeft)` call
- `controllers/comments.js` — when comment type is `story`, fire `notificationService.sendStoryComment(storyOwnerId, ...)`

**No new files on backend.**

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Modify:**
- `lib/services/notification_router.dart` — add cases for `wave`, `comment_reply`, `comment_reaction`, `comment_mention`, `vip_renewal_warning`, `story_comment`
- `lib/pages/settings/notification_preferences_screen.dart` — add toggles for `comment`, `newFollower`, `vipRenewalWarning`. Reorder for logical grouping.

**No new files on Flutter.**

---

## Critical decisions baked in

1. **`notificationService` is the single push-orchestration layer.** Everything routes through `notificationService.send()` (or a typed `sendXxx()` that wraps it). New push types do NOT call `fcmService.sendToUser` directly — that's a layering violation that would skip preference check + history persistence + badge update.

2. **Preference check is fail-open by default for unknown keys.** A type string with no corresponding `notificationPreferences` field returns `true` (send) via the `?? true` fallback. Forward-compatible: future push types ship without breaking on old user docs. Cost: a typo in the type string silently allows the push instead of suppressing it — acceptable trade-off.

3. **Type strings are stable contracts between backend and Flutter.** New types added this wave: `story_comment`, `vip_renewal_warning`. Existing types `wave`, `comment_reply`, `comment_reaction`, `comment_mention`, `friend_request`, `chat_message`, `moment_comment`, `follower_moment` are unchanged. Flutter router cases mirror the backend exactly.

4. **Chat-push online gate is in the socket handler, not in notificationService.** Reason: `userConnections` lives in the socket layer (in-memory Map). Putting the gate in notificationService would couple it to socket state, which is brittle. The gate at the call site is one line and self-documenting.

5. **VIP renewal warning text is server-rendered in English.** Matches existing chat / wave pattern. Localization is a separate concern across all push types — out of scope.

6. **Story comment notification respects the same `comment` preference as moment comments.** Both gated by `user.notificationPreferences.comment`. Single toggle in the settings screen controls both surfaces.

---

## Task 0: Branch setup

**Files:** none

- [ ] **Step 1: Verify clean working trees on both repos.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status --short
# Expected: no output

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git status --short
# Expected: no output (or only ios/Podfile.lock as known-volatile)
```

If anything other than `ios/Podfile.lock` is dirty, STOP and surface.

- [ ] **Step 2: Create execution branches from main.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull --ff-only && git checkout -b feat/step16-push-notifications

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull --ff-only && git checkout -b feat/step16-push-notifications
```

- [ ] **Step 3: Copy plan + recon to backend.**

```bash
cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/recon/2026-05-14-step16-push-notifications-recon.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/recon/

cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/plans/2026-05-14-step16-push-notifications-plan.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/plans/

cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add docs/superpowers/
git commit -m "docs: Step 16 push notifications recon + plan"
```

---

## Task B1: Add missing `notificationPreferences` fields + lazy fallback in `_shouldSendNotification`

**Files:**
- Modify: `models/User.js`
- Modify: `services/notificationService.js`

Working dir: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

- [ ] **Step 1: Add fields to the schema.**

Find the `notificationPreferences` sub-doc (around line 684-717). Add three new fields alongside the existing toggles:

```js
comment: {
  type: Boolean,
  default: true
},
newFollower: {
  type: Boolean,
  default: true
},
vipRenewalWarning: {
  type: Boolean,
  default: true
},
```

- [ ] **Step 2: Add lazy fallback in `_shouldSendNotification`.**

Find `_shouldSendNotification` in `services/notificationService.js` (around line 472). The current preference check is roughly:

```js
const prefKey = _getPreferenceKey(type);
if (prefKey && user.notificationPreferences[prefKey] === false) {
  return false;
}
```

Verify the exact shape; if `_getPreferenceKey` doesn't already exist, the direct read pattern needs `?? true`. Locate where the type → preference key mapping happens and confirm the mapping table includes:

- `'chat_message'` → `'chat'`
- `'wave'` → `'wave'`
- `'friend_request'` → `'newFollower'`
- `'moment_comment'` → `'comment'`
- `'comment_reply'` → `'comment'`
- `'comment_reaction'` → `'comment'`
- `'comment_mention'` → `'comment'`
- `'story_comment'` → `'comment'`
- `'vip_renewal_warning'` → `'vipRenewalWarning'`
- `'follower_moment'` → `'followerMoment'` (existing)
- `'profile_visit'` → `'visitorAlert'` (existing)

If the mapping table is implicit (i.e., the code does `user.notificationPreferences[type]`), restructure to use an explicit map AND ensure unknown types fall through to `true`. Cleanest pattern:

```js
const TYPE_TO_PREF_KEY = {
  chat_message: 'chat',
  wave: 'wave',
  friend_request: 'newFollower',
  moment_comment: 'comment',
  story_comment: 'comment',
  comment_reply: 'comment',
  comment_reaction: 'comment',
  comment_mention: 'comment',
  follower_moment: 'followerMoment',
  profile_visit: 'visitorAlert',
  vip_renewal_warning: 'vipRenewalWarning',
  // Calls / voice rooms / matches retain existing mappings
};

function _shouldSendNotification(user, type) {
  // ... existing global enabled check ...
  const prefKey = TYPE_TO_PREF_KEY[type];
  if (!prefKey) return true; // unknown type → fail-open
  const value = user.notificationPreferences?.[prefKey];
  return value ?? true; // undefined on legacy docs → default true
}
```

Adapt to whatever the current shape is — the principle: explicit type→pref map + `?? true` fallback for missing fields.

- [ ] **Step 3: Verify syntax.**

```bash
node -c models/User.js && node -c services/notificationService.js
```

- [ ] **Step 4: Commit.**

```bash
git add models/User.js services/notificationService.js
git commit -m "feat(push): add comment/newFollower/vipRenewalWarning prefs + lazy fallback

Three new fields on User.notificationPreferences (default true):
- comment           — gates moment / story / reply / reaction / mention pushes
- newFollower       — gates friend_request push (which fires on follow)
- vipRenewalWarning — gates the VIP renewal warning push (B3)

_shouldSendNotification now uses an explicit TYPE_TO_PREF_KEY map
+ ?? true fallback for missing keys on legacy user docs. Forward-
compatible: future push types ship without breaking on old docs.

No DB migration — fields default-true on schema, lazy fallback
handles existing docs. ~1K user records, no churn."
```

---

## Task B2: Fix chat push to gate by online status

**Files:**
- Modify: `socket/socketHandler.js`

- [ ] **Step 1: Locate the existing chat push call.**

Around line 804, the post-message background work calls:

```js
notificationService.sendChatMessage(receiver, userId, {
  // ... message preview, etc.
}).catch(err => console.error('[push] sendChatMessage failed:', err.message));
```

This fires regardless of `receiver`'s online state.

- [ ] **Step 2: Gate by `userConnections`.**

`userConnections` (Map of `userId → Set<socketId>`) is defined at the top of `socket/socketHandler.js` (around line 18). Wrap the `sendChatMessage` call:

```js
// Push only when receiver's chat socket is disconnected — users in the
// app already see the message via the socket newMessage event. Prevents
// double-notification when they're actively browsing.
const receiverIsOnline = userConnections.has(String(receiver));
if (!receiverIsOnline) {
  notificationService.sendChatMessage(receiver, userId, {
    // ... preserved arguments
  }).catch(err => console.error('[push] sendChatMessage failed:', err.message));
}
```

Cast `receiver` to String to match the Map's key type (userConnections keys are stringified ObjectIds).

- [ ] **Step 3: Verify syntax.**

```bash
node -c socket/socketHandler.js
```

- [ ] **Step 4: Commit.**

```bash
git add socket/socketHandler.js
git commit -m "fix(push): gate chat push by receiver online status

Bug: chat push fired regardless of whether the receiver was
connected to the chat socket. Users actively in the app got both
the in-app socket newMessage event AND a system push notification.

Fix: only fire sendChatMessage when userConnections.has(receiverId)
returns false (no live socket). receiver cast to String to match
the Map's stringified ObjectId keys.

Edge: if the socket cleanup heartbeat hasn't fired after an app
crash, the receiver appears online for ~30s and the push is
suppressed. Acceptable — matches today's online-after-crash window.

No change to push payload or preference handling — pure call-site
guard."
```

---

## Task B3: Wire VIP renewal warning push — replace stub

**Files:**
- Modify: `services/notificationService.js`
- Modify: `jobs/subscriptionExpiryJob.js`

- [ ] **Step 1: Add the typed helper.**

In `services/notificationService.js`, after the existing `sendWave` / `sendChatMessage` typed methods, add:

```js
const sendVipRenewalWarning = async (userId, daysLeft) => {
  try {
    const user = await User.findById(userId);
    if (!user) return { success: false, error: 'User not found' };

    const title = daysLeft === 1
      ? 'Your VIP ends tomorrow'
      : `Your VIP ends in ${daysLeft} days`;
    const body = daysLeft === 1
      ? 'Renew now to keep unlimited tutor chips, ads-off, and more.'
      : `${daysLeft} days left of VIP. Renew anytime to keep your benefits.`;

    const notification = {
      title,
      body,
      data: {
        type: 'vip_renewal_warning',
        daysLeft: String(daysLeft),
        screen: 'vip',
      },
    };

    return await send(userId, 'vip_renewal_warning', notification);
  } catch (error) {
    console.error('❌ Error sending VIP renewal warning:', error);
    return { success: false, error: error.message };
  }
};
```

Export it alongside the other `send*` functions at the bottom of the file (around line 869).

- [ ] **Step 2: Replace the stub in `subscriptionExpiryJob.js`.**

Find `sendPushNotification` (around line 22-24 — the stub returning `console.log`). Either remove it entirely (preferred) or leave commented out. Replace the call site (around line 175):

```js
// BEFORE
sendPushNotification(user._id, { title, body, data });

// AFTER
const notificationService = require('../services/notificationService');
await notificationService.sendVipRenewalWarning(user._id, days).catch(err =>
  console.error('[vip-warning] push failed:', err.message)
);
```

Move the `require` to the top of the file if other notification calls already exist there; otherwise inline is fine since this is the only call site.

- [ ] **Step 3: Remove or comment the stub function itself.**

If `sendPushNotification` is defined locally in `subscriptionExpiryJob.js` (recon hints lines 22-24), delete the stub. No callers remain after step 2.

- [ ] **Step 4: Verify.**

```bash
node -c services/notificationService.js && node -c jobs/subscriptionExpiryJob.js
```

- [ ] **Step 5: Commit.**

```bash
git add services/notificationService.js jobs/subscriptionExpiryJob.js
git commit -m "fix(push): wire VIP renewal warning — replace job stub

Bug: subscriptionExpiryJob flipped the 7day/3day/1day warning flag
correctly, but the actual push call was a console.log stub. Users
near VIP expiry got the email (Step 13A) but no push.

Fix: new sendVipRenewalWarning(userId, daysLeft) typed helper in
notificationService.js, paired with the existing sendChatMessage /
sendWave pattern. Title / body construction is server-side in
English (localization is cross-cutting, separate concern).

Job call site replaced with the typed helper; stub function deleted.
The 7day/3day/1day warning flag mechanism is unchanged — still
prevents duplicate sends within the same window.

Push gated by user.notificationPreferences.vipRenewalWarning (added
in B1, default true). VIP users who opted out of renewal warnings
still get the email — opt-out is per-channel."
```

---

## Task B4: Add story comment owner notification (parity with moments)

**Files:**
- Modify: `services/notificationService.js`
- Modify: `controllers/comments.js`

- [ ] **Step 1: Add the typed helper.**

In `services/notificationService.js`, mirroring `sendMomentComment` (around line 241), add:

```js
const sendStoryComment = async (storyOwnerId, commenterId, storyId, commentText) => {
  try {
    const [commenter, owner] = await Promise.all([
      User.findById(commenterId),
      User.findById(storyOwnerId),
    ]);
    if (!commenter || !owner) return { success: false, error: 'User not found' };

    const truncated = (commentText || '').length > 100
      ? `${commentText.substring(0, 100)}...`
      : (commentText || '');

    const { title, body } = templateService.render(
      'story_comment',
      owner?.preferredLocale || 'en',
      { commenterName: commenter.name, comment: truncated },
    );

    const notification = {
      title,
      body,
      data: {
        type: 'story_comment',
        commenterId: String(commenterId),
        storyId: String(storyId),
        screen: 'story',
      },
    };

    if (commenter.images && commenter.images.length > 0) {
      notification.imageUrl = commenter.images[0];
    }

    return await send(storyOwnerId, 'story_comment', notification);
  } catch (error) {
    console.error('❌ Error sending story comment notification:', error);
    return { success: false, error: error.message };
  }
};
```

If `templateService` doesn't have a `story_comment` template, fall back to inline title / body construction:

```js
const title = `${commenter.name} commented on your story`;
const body = truncated || 'Tap to view';
```

Export `sendStoryComment` alongside other helpers.

- [ ] **Step 2: Fire from the comment controller.**

In `controllers/comments.js`, find the existing moment-comment notification path (around line 199-201). Add a parallel branch for stories. Sketch:

```js
// Existing moment-comment branch
if (parentType === 'moment' && String(momentOwnerId) !== String(commenterId)) {
  notificationService.sendMomentComment(momentOwnerId, commenterId, momentId, commentText)
    .catch(err => console.error('[push] moment comment failed:', err.message));
}

// NEW: story-comment branch
if (parentType === 'story' && String(storyOwnerId) !== String(commenterId)) {
  notificationService.sendStoryComment(storyOwnerId, commenterId, storyId, commentText)
    .catch(err => console.error('[push] story comment failed:', err.message));
}
```

The exact variable names and the parent-type discrimination depend on the existing controller structure. The principle: identify the story-comment code path, look up the story owner (`Story.findById(storyId).select('user').lean()` or equivalent), self-comment guard, then fire the push.

If the existing controller doesn't track parent type at the variable level, inspect the route + the Comment model schema to find the existing distinction (e.g. `Comment.parentType` enum).

- [ ] **Step 3: Verify.**

```bash
node -c services/notificationService.js && node -c controllers/comments.js
```

- [ ] **Step 4: Commit.**

```bash
git add services/notificationService.js controllers/comments.js
git commit -m "feat(push): notify story owner on story comment

Bug: moment comments fired sendMomentComment to the moment owner,
but story comments silently dropped — asymmetric UX. Story owners
had no signal their story was getting engagement.

Fix: new sendStoryComment(storyOwnerId, commenterId, storyId,
commentText) typed helper in notificationService.js, mirroring
sendMomentComment exactly. Type string 'story_comment'; deep-link
data.screen 'story' + data.storyId.

controllers/comments.js fires it from the story-comment code path,
with the same self-comment guard the moment path uses.

Gated by user.notificationPreferences.comment (added in B1) —
single preference toggles both moment + story comments. The Flutter
preferences screen exposes one Comment toggle that controls both."
```

---

## Task B5: Backend sanity smoke + curl verification

**Files:** none

- [ ] **Step 1: Start the dev server.**

```bash
npm run dev
```

- [ ] **Step 2: Verify push call sites compile + import resolution.**

Restart-and-watch for crashes during the first 30s of boot. The `notificationService` require chain pulls in several modules; a typo in B3 / B4 will surface here.

- [ ] **Step 3: No commit (verification only).**

If any module fails to load, fix before continuing to Flutter tasks.

---

## Task F1: Add missing router cases — wave / comment / vip_renewal_warning / story_comment

**Files:**
- Modify: `lib/services/notification_router.dart`

Working dir: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

- [ ] **Step 1: Locate the type switch.**

In `lib/services/notification_router.dart` (around lines 58-87), the `switch (data['type'])` block has cases for `chat_message`, `moment_like`, `moment_comment`, `follower_moment`, `friend_request`, `profile_visit`, `incoming_call`, `missed_call`.

- [ ] **Step 2: Add the missing cases.**

```dart
case 'wave':
  // Backend payload: data.userId = waverId, data.waveId
  final waverId = data['userId']?.toString();
  if (waverId != null) targetPath = '/profile/$waverId';
  break;

case 'comment_reply':
case 'comment_reaction':
case 'comment_mention':
  // Backend payload: data.userId (actor), data.momentId
  final momentId = data['momentId']?.toString();
  if (momentId != null) targetPath = '/moment/$momentId';
  break;

case 'story_comment':
  // Backend payload: data.commenterId, data.storyId
  final storyId = data['storyId']?.toString();
  if (storyId != null) targetPath = '/story/$storyId';
  break;

case 'vip_renewal_warning':
  // Backend payload: data.daysLeft
  targetPath = '/vip';
  break;
```

Place the new cases in the switch in a sensible order (group all comment-related together; vip at the bottom). Verify the deep-link paths actually exist in `app_router.dart` — for `/story/{id}` and `/vip`, confirm or adjust to the real route name (might be `/stories/:id` or `/profile/vip` depending on the router config).

- [ ] **Step 3: Verify deep-link paths.**

```bash
grep -nE "GoRoute|path: '/(story|stories|vip|profile/vip)" lib/router/app_router.dart | head -10
```

Adjust the case targets to match the actual route definitions. If `/vip` doesn't exist, fall back to `/profile/me` (or wherever VIP info surfaces in the existing UI).

- [ ] **Step 4: Analyze.**

```bash
flutter analyze lib/services/notification_router.dart 2>&1 | tail -3
```

- [ ] **Step 5: Commit.**

```bash
git add lib/services/notification_router.dart
git commit -m "fix(push): add router cases for wave / comment / vip / story

Bug: the backend fires push notifications with data.type values
'wave', 'comment_reply', 'comment_reaction', 'comment_mention',
'story_comment' (after B4), and 'vip_renewal_warning' (after B3),
but the Flutter NotificationRouter switch had no cases for any of
them. Pushes delivered to the device but tap-to-deep-link fell
through to home — confusing UX.

Fix: six new cases routing to:
- wave           → /profile/{waverId}
- comment_reply  → /moment/{momentId}
- comment_reaction → /moment/{momentId}
- comment_mention → /moment/{momentId}
- story_comment  → /story/{storyId}
- vip_renewal_warning → /vip

Deep-link paths verified against lib/router/app_router.dart. The
existing 300ms-delayed push after go('/home') pattern is preserved.

moment_comment and friend_request cases were already present —
unchanged."
```

---

## Task F2: Add missing preference toggles to settings screen

**Files:**
- Modify: `lib/pages/settings/notification_preferences_screen.dart`

- [ ] **Step 1: Locate the existing toggle list.**

Around lines 23-31, the preferences screen has hardcoded keys: `chat`, `wave`, `voiceRoomStart`, `scheduledRoomReminder`, `followerMoment`, `visitorAlert`, `matchAlert`.

- [ ] **Step 2: Add three new toggles.**

Insert after the existing `wave` row (or wherever fits the visual hierarchy):

```dart
NotificationToggleRow(
  title: 'New follower',
  subtitle: 'When someone follows you',
  prefKey: 'newFollower',
  icon: Icons.person_add_outlined,
  value: _prefs['newFollower'] ?? true,
  onChanged: (v) => _onToggle('newFollower', v),
),
NotificationToggleRow(
  title: 'Comments',
  subtitle: 'When someone comments on your moments or stories',
  prefKey: 'comment',
  icon: Icons.comment_outlined,
  value: _prefs['comment'] ?? true,
  onChanged: (v) => _onToggle('comment', v),
),
NotificationToggleRow(
  title: 'VIP renewal warnings',
  subtitle: 'Reminders before your VIP subscription ends',
  prefKey: 'vipRenewalWarning',
  icon: Icons.workspace_premium_outlined,
  value: _prefs['vipRenewalWarning'] ?? true,
  onChanged: (v) => _onToggle('vipRenewalWarning', v),
),
```

Adapt to the existing `NotificationToggleRow` widget API (or whatever the screen uses — might be a `SwitchListTile` directly). Match the existing pattern exactly.

The `_prefs['xxx'] ?? true` fallback ensures the toggle defaults to ON for legacy users who don't have the field in their preferences map yet (mirrors the backend's lazy fallback from B1).

- [ ] **Step 3: Reorder for grouping (optional polish).**

Suggested grouping order:
1. Chat
2. New follower
3. Comments
4. Wave
5. Follower moments
6. Visitor alert
7. VIP renewal warnings
8. Voice rooms (start + scheduled reminder)
9. Match alerts

Apply only if the screen's structure makes this trivial — don't refactor the screen layout if it's complex.

- [ ] **Step 4: Analyze.**

```bash
flutter analyze lib/pages/settings/notification_preferences_screen.dart 2>&1 | tail -3
```

- [ ] **Step 5: Commit.**

```bash
git add lib/pages/settings/notification_preferences_screen.dart
git commit -m "feat(push): preference toggles for new follower / comment / VIP renewal

Adds three new SwitchListTile rows mapping to the User.notificationPreferences
fields added in B1:
- newFollower       — gates friend_request push
- comment           — gates moment + story + reply + reaction + mention
- vipRenewalWarning — gates the VIP renewal warning push (B3)

Each row defaults ON for legacy users (?? true fallback in the
existing _prefs map read), mirroring the backend's lazy-fallback
in _shouldSendNotification (B1).

Optional grouping rearrangement for visual hierarchy — chat at
top, social actions next, voice rooms and VIP at the bottom."
```

---

## Task G1: Glue — manual smoke + push

**Files:** none

- [ ] **Step 1: Backend smoke (curl + Mongo verification).**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
npm run dev &

TOKEN_USER="<user token>"
TOKEN_TARGET="<target user — has fcmTokens registered>"

# 1. Chat push gating (B2)
# Send a chat message from USER to TARGET while TARGET is online (chat socket connected).
# Expected: TARGET does NOT receive a push (in-app socket newMessage delivers).
# Then disconnect TARGET's chat socket. Send another message.
# Expected: TARGET receives a push.
# Verify in db.notifications: only one entry per disconnected-send, none per online-send.

# 2. Wave push (already works; verify router fix end-to-end)
curl -s -X POST -H "Authorization: Bearer $TOKEN_USER" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/community/wave \
  -d '{"toUserId":"<TARGET_ID>"}' | jq
# Expected: TARGET receives a push titled 'X waved at you' (or similar).
# Tap should deep-link to /profile/<USER_ID> on the Flutter app.

# 3. Story comment push (B4)
# Post a comment on a story where USER != story owner.
# Expected: story owner receives push titled 'X commented on your story'.

# 4. VIP renewal warning (B3) — simulate by setting endDate to 6.9 days out
# In Mongo shell:
#   db.users.updateOne({ _id: ObjectId("<test_vip_id>") },
#     { $set: { 'vipSubscription.endDate': new Date(Date.now() + 6.9 * 24 * 60 * 60 * 1000),
#               'vipSubscription.warnings.7day': false }})
# Trigger the job manually (look for the cron registration in jobs/scheduler.js) or wait
# for next tick. Verify the push fires + the 7day flag flips to true.

# 5. Preferences gate
# Set TARGET's notificationPreferences.comment = false in Mongo.
# Comment on TARGET's moment. Expected: no push fires.
# Verify db.notifications has a suppressed entry OR no entry (depends on
# whether _shouldSendNotification returns before _saveToHistory).
```

- [ ] **Step 2: Flutter device smoke (iOS physical + Android physical).**

1. **Chat push when offline:** User A in foreground, User B sends them a message → no push (chat suppressed in-foreground today, plus newMessage socket event). Then background User A's app. User B sends another → push arrives, tap → opens chat with User B.
2. **Wave push:** User B waves at User A. User A receives push → tap → opens User B's profile.
3. **New follower:** User B follows User A. User A receives push → tap → opens User B's profile.
4. **Comment on moment:** User B comments on User A's moment. User A receives push → tap → opens the moment with the comment.
5. **Comment on story:** User B comments on User A's story. User A receives push → tap → opens the story.
6. **VIP renewal warning:** Simulate via DB as in backend smoke; verify push lands + tap → opens VIP screen.
7. **Preference toggles:** Toggle Comments OFF in settings. Comment on User A's moment from another account. No push fires.
8. **Preferences default-true for legacy:** Find a user whose `notificationPreferences` lacks the new fields (or create one in Mongo by deleting them). Verify pushes still fire for that user.

- [ ] **Step 3: Push both branches.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git push -u origin feat/step16-push-notifications

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "error •" && echo "ERRORS — fix before merge" || echo "no errors"
git push -u origin feat/step16-push-notifications
```

- [ ] **Step 4: Surface to user.**

Report:
- Backend + Flutter commit hashes + push confirmation
- Smoke test results (which passed, any issues)
- Any uncertain decisions encountered

Wait for the user to merge.

---

## Cadence guidance

- **B1 lands first** — schema + fallback are foundational; everything else depends on the type→preference mapping being in place.
- **B2 follows** — chat gate fix is independent of B1 but reads cleanest after the preference plumbing.
- **B3 depends on B1** (needs the `vipRenewalWarning` preference key + mapping).
- **B4 depends on B1** (needs the `comment` mapping to cover story_comment).
- **B5 is the local sanity check** after all backend tasks.
- **F1 + F2 can be authored in parallel** after the backend is deployable.
- **G1 is the manual smoke + merge gate.**

## Risk + rollback

- **Highest risk: B1 `_shouldSendNotification` refactor.** If the explicit type→pref map breaks an existing type's gate (e.g., a typo in `'incoming_call'`), real-world pushes regress (urgent calls don't fire, or always fire bypassing user prefs). Rollback: revert B1; falls back to whatever the existing implicit lookup does. Mitigation: keep all existing keys in the new map verbatim from the current code.
- **Mid-risk: B2 chat gate.** A bug in `userConnections.has(String(receiver))` (e.g., wrong receiver variable, key type mismatch) means EITHER no chat pushes EVER (regression) OR pushes fire to everyone (no change from today). Mitigation: smoke test online + offline cases explicitly in G1.
- **Mid-risk: B3 VIP renewal stub fix.** A bug in `sendVipRenewalWarning` means warnings still don't fire. Rollback: revert B3; behavior reverts to "stub doesn't fire" — net-zero from today.
- **Low risk: B4 story comment.** Pure addition. Rollback: revert; story owners don't get pushes (matches today).
- **Low risk: F1 router cases.** Adding cases doesn't break existing ones. Worst case: a typo in a new case path. Rollback: revert; new types tap-fall-through to home.
- **Low risk: F2 preference toggles.** Pure additive UI. Rollback: revert; users can't toggle the new prefs but defaults are true.

**Emergency disable:** No env-flag kill switch. If chat push regresses, revert B2. If VIP push goes haywire, revert B3.

**No DB migrations.** The lazy fallback (B1) handles legacy user docs without churn.

---

## Appendix A — what's NOT in this wave

Restated to make the boundary clear during execution:

- ❌ Scheduled / timed pushes (streak reminders, daily quota refresh, story expiring)
- ❌ In-app SnackBar / banner foreground UX
- ❌ `friend_request` → `new_follower` type string rename
- ❌ Mentions parsing in chat messages (the comment_mention type works; chat message @-mentions don't exist yet)
- ❌ Voice room invite push
- ❌ User-facing notification inbox / history screen
- ❌ Quiet hours UI surface (backend logic exists; no Flutter toggle)
- ❌ Per-conversation chat push throttle / coalescing
- ❌ Bundled notification packs (multi-actor "X, Y, and 3 others")
- ❌ Localization of push title / body
- ❌ Notification action buttons beyond what exists today (reply, view, profile)
- ❌ Push delivery analytics dashboard

If during execution you discover something that wants to expand scope, write it to `docs/manual-todos.md` Queued engineering and continue. Do NOT expand the plan.

---

## Appendix B — verification queries (post-merge)

After Step 16 ships, useful Mongo queries:

```js
// All pushes in the last day, grouped by type
db.notifications.aggregate([
  { $match: { sentAt: { $gte: new Date(Date.now() - 24*60*60*1000) } } },
  { $group: { _id: '$type', delivered: { $sum: 1 } } }
])

// Suppressed pushes (preference / quiet hours / cap)
db.notifications.find({ suppressedReason: { $ne: null } })
  .sort({ sentAt: -1 }).limit(50)

// Users who have a specific preference disabled
db.users.find({ 'notificationPreferences.comment': false })
  .count()

// VIP users in their warning window with the 7day flag set
db.users.find({
  'vipSubscription.endDate': {
    $gte: new Date(),
    $lte: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000)
  },
  'vipSubscription.warnings.7day': true
}, { email: 1, 'vipSubscription.endDate': 1 })
```

These are reference queries, not part of the implementation.
