# Step 16 — Push Notifications — Recon

Read-only reconnaissance for a planned Step 16 Push Notifications wave. Five event-driven pushes are in scope: new chat message (when recipient offline), new follower, wave received, comment on your moment / story, VIP renewal warning. Scheduled / timed pushes (streak reminders, daily quota refresh, story expiring) are out of scope.

The headline finding: **most of the backend push pipeline already exists.** This is a wiring + gap-filling wave, not a greenfield build. The genuine gaps are: chat push fires regardless of online state (should gate); the Flutter dispatcher is missing cases for some live push types (so pushes fire but tap-to-deep-link doesn't work); two `User.notificationPreferences` fields are missing; the VIP renewal warning is a stub.

---

## Cross-cutting findings

### CC-1. Backend FCM pipeline is fully built.

`services/fcmService.js` and `services/notificationService.js` together implement the entire send pipeline (~900 lines). `fcmService.sendToUser(userId, notification, data)` iterates `user.fcmTokens` filtered by `.active`, batches via `admin.messaging().sendEach`, prunes invalid-token entries with `$pull`, supports quiet hours + frequency caps + Notification model persistence (`models/Notification.js`, 30-day TTL, schema fields: userId, type, title, body, data, read, clicked, sentAt, suppressedReason, bundleSize, bundleActors). `notificationService.send(userId, type, payload)` is the high-level orchestrator that wraps `_shouldSendNotification()` preference check + history persistence + badge update.

Implication: the wave does NOT need to touch fcmService.js or rebuild any send primitive.

### CC-2. Four of the five event types already have a push call site that fires.

| Push | Call site | Type string |
|---|---|---|
| Chat message | `socket/socketHandler.js:804` — `sendChatMessage(receiver, userId, message)` | `chat_message` |
| New follower | `controllers/users.js:683` — `sendFriendRequest(targetUserId, userId)` | `friend_request` |
| Wave received | `controllers/community.js:294` — `sendWave(targetUserId, fromUserId, waveId, isMutual)` | `wave` |
| Comment on moment | `controllers/comments.js:201` — `sendMomentComment(momentOwnerId, commenterId, momentId, comment)` | `moment_comment` |
| VIP renewal warning | `jobs/subscriptionExpiryJob.js:175` — `sendPushNotification(...)` ← **STUB** | (none — push never sent) |

Implication: this wave is primarily **fix the gates / fix the stub / wire the Flutter side**, not "add new pushes."

### CC-3. Chat push fires regardless of recipient online status — contradicts the wave's chosen delivery rule.

`socket/socketHandler.js` lines 760-810 do the `sendChatMessage` push call inside a `setImmediate()` after persisting + ACKing. There is NO `if (!userConnections.has(receiver))` gate around the push. So today: every chat message fires a push, even if the recipient is in the app with the chat socket connected. The user has stated the rule should be **"push only when socket disconnected"** (no double-notification of in-app users).

Fix: gate the `sendChatMessage` call with `!userConnections.has(receiverId)`. Single-line change at the call site, no `notificationService` changes needed.

### CC-4. Flutter `NotificationRouter` is missing cases for live push types.

`lib/services/notification_router.dart` lines 58-87 switch on `data['type']`. Cases handled today: `chat_message`, `moment_like`, `moment_comment`, `follower_moment`, `friend_request`, `profile_visit`, `incoming_call`, `missed_call`.

**Missing cases** for push types that the backend actually fires today (live mismatch — push delivers, but tap → no deep-link):

- **`wave`** — backend `sendWave` emits `data.type='wave'` (notificationService.js:139, 457). Flutter has no case → falls through to home.
- **`comment_reply`** — `sendCommentReply` emits `data.type='comment_reply'` (notificationService.js:724).
- **`comment_reaction`** — emits `'comment_reaction'` (notificationService.js:758).
- **`comment_mention`** — emits `'comment_mention'` (notificationService.js:796).
- **`vip_renewal_warning`** — once the B1 stub is fixed, this type will start firing. No case today.

`moment_comment` IS in the router (line 65). It deep-links to `/moment/{momentId}`. That covers the "comment on your moment" half of the wave; the "comment on your story" half requires a separate `story_comment` type (no comment push to story owner exists in `controllers/comments.js` today — the controller only handles moments).

### CC-5. `User.notificationPreferences` is missing two fields the wave needs.

The sub-doc (`models/User.js` lines 684-717) has these Boolean fields (all default true):

`chat`, `wave`, `voiceRoomStart`, `scheduledRoomReminder`, `followerMoment`, `visitorAlert`, `matchAlert`, `calls`.

**Missing for Step 16:**

- **`comment`** — for "comment on your moment / story / message". (`followerMoment` exists but is "your followers' moments showed up in feed", a different surface.)
- **`newFollower`** — for "someone followed you" (distinct from `followerMoment`).
- **`vipRenewalWarning`** — for the renewal warning push.

`_shouldSendNotification` in notificationService.js checks `user.notificationPreferences[type]`. If a type isn't a key, the lookup returns `undefined` which is falsy — preferences-by-default-block any type the schema doesn't know about. So adding the fields is non-optional; without them, even fixing the call sites would silently drop the pushes.

### CC-6. Foreground UX swallows chat-type pushes intentionally; would do the same for new types if not addressed.

`lib/services/notification_service.dart` `_handleForegroundMessage()` (line 289) returns early when `type == 'chat_message' || type == 'incoming_call'` (lines 308, 314). For other types it calls `_showLocalNotification()` which renders via `flutter_local_notifications` system banner.

Behavior implication for the new types:
- `wave`, `comment`, `vip_renewal_warning`, `follower` — would render as system notifications even when the user is in the app. This is probably desired for follower / wave / VIP (low-frequency, signal-worthy), and probably acceptable for comment (medium frequency). The foreground UX may want a SnackBar replacement once the user is on the relevant tab — but that's polish, not table stakes.

### CC-7. Frequency caps + quiet hours already exist in `fcmService.sendToUser`.

Lines 105-142 implement `isInQuietHours(user, date)` (urgent types whitelisted via `URGENT_TYPES` = `['incoming_call', 'missed_call']`) and `isCapped(user, type)` (per-user daily/weekly counters). Suppressed sends are logged to `Notification` model with `suppressedReason: 'quiet_hours'` or `'frequency_cap'`.

Implication: no app-level throttling work needed for the wave; OS-level coalescing + this server-side cap handles the burst-suppression concern.

### CC-8. Notification persistence exists; admin / user history surface does not.

`models/Notification.js` records every push (delivered + suppressed) with title, body, data, type, read, clicked, sentAt. 30-day TTL. Compound index on `(userId, sentAt)`.

Implication: a user-facing "Notification history" inbox screen could be built on this for free — but is out of scope for this wave.

---

## Per-push gap analysis

### Push #1 — New chat message (when recipient offline)

- **Backend send**: works (`sendChatMessage`, well-tested code path)
- **Backend gate**: ❌ MISSING — fires regardless of online status
- **Flutter router**: ✓ has `chat_message` case (line 61 → `/chat/{senderId}`)
- **Flutter prefs toggle**: ✓ `chat` field exists
- **Foreground UX**: chat is suppressed in foreground (correct — in-app users get in-app message)

**Action items**: 1 line at `socket/socketHandler.js` to gate by `userConnections.has`.

### Push #2 — New follower

- **Backend send**: works (`sendFriendRequest` called from `controllers/users.js:683` on follow)
- **Flutter router**: ✓ has `friend_request` case (line 71 → `/profile/{userId}`)
- **Flutter prefs toggle**: ❌ MISSING — no `newFollower` field on `User.notificationPreferences`
- **Foreground UX**: foreground = local notification (correct)

**Action items**: add `newFollower` schema field + preferences screen toggle. Optionally rename type from `friend_request` to `new_follower` for clarity — but that breaks deep-link continuity for any user currently with an unread `friend_request` push pending tap. **Safer**: keep `friend_request` type, just add the corresponding preference field as `newFollower` (or change preference name to `friendRequest` to match — bikeshed). Lean: add `newFollower` for forward consistency and check it inside `_shouldSendNotification` mapping (one line).

### Push #3 — Wave received

- **Backend send**: works (`sendWave` with built-in >3/6h anti-spam)
- **Flutter router**: ❌ MISSING — no `wave` case → tap goes to home
- **Flutter prefs toggle**: ✓ `wave` field exists
- **Foreground UX**: foreground = local notification (correct)

**Action items**: add `case 'wave':` to NotificationRouter (deep-link → `/profile/{waverId}` likely). One case statement.

### Push #4 — Comment on your moment / story

- **Backend send (moments)**: works (`sendMomentComment` at `controllers/comments.js:201`)
- **Backend send (stories)**: ❌ MISSING — `controllers/comments.js` only fires the push for moment comments. Story comment owner is not notified.
- **Backend type strings used**: `moment_comment`, `comment_reply`, `comment_reaction`, `comment_mention` (4 distinct types)
- **Flutter router**: ✓ has `moment_comment` case. ❌ MISSING cases for `comment_reply`, `comment_reaction`, `comment_mention` (live push types that have nowhere to deep-link)
- **Flutter prefs toggle**: ❌ MISSING — no `comment` field on `User.notificationPreferences`
- **Foreground UX**: foreground = local notification (correct)

**Action items**: add `comment` schema field (gates all 4 comment-related push types via the type→pref mapping). Add the 3 missing router cases. **Decision**: do we add a story-comment push to the controller this wave, or queue it? Lean: add it; it's a 5-line addition and the absence is a real product gap.

### Push #5 — VIP renewal warning (7 / 3 / 1 day before expiry)

- **Backend send**: ❌ STUBBED — `jobs/subscriptionExpiryJob.js:175` calls a `sendPushNotification` stub that returns `console.log(...)` and never actually invokes notificationService
- **Backend flag flip**: works — `User.vipSubscription.warnings.{7,3,1}day` correctly flips to `true` to dedupe
- **Backend email**: separate path; emails already fire (per Step 13A wave)
- **Flutter router**: ❌ MISSING — no `vip_renewal_warning` case
- **Flutter prefs toggle**: ❌ MISSING — no `vipRenewalWarning` field
- **Foreground UX**: foreground = local notification (correct)

**Action items**: replace stub in `subscriptionExpiryJob.js` with `notificationService.send(user._id, 'vip_renewal_warning', { title, body, data })`. Add schema preference field. Add Flutter router case (deep-link → `/profile/vip` or wherever the VIP settings live). Add a new template helper (`sendVipRenewalWarning` in notificationService.js) for clean type registration.

---

## Edge cases the plan must address

- **Chat push during voice call.** User is on an active voice call, a chat message arrives. Should the chat push fire? Today it does. The "socket disconnected" gate (CC-3) would skip it (user is online for chat too during a call). Acceptable.
- **Chat push during call from same person.** Person A is calling Person B. A also sends a text. B gets both an `incoming_call` push and a `chat_message` push. The call push is `URGENT_TYPES`-whitelisted so it bypasses quiet hours; chat doesn't. Acceptable noise.
- **Wave anti-spam interaction with new follower.** If user X waves at user Y and then follows Y within seconds, Y gets `wave` + `friend_request`. No dedup — and shouldn't be, semantically.
- **Comment on own moment.** `controllers/comments.js:199` already gates this — push not sent if commenter is the moment owner. Carry this gate to story comments.
- **VIP renewal warning timing.** Job runs once daily. The 7-day push for a user whose end date crosses the 7-day boundary at, say, 11:55pm UTC fires the next day at the job tick. Acceptable; ~24h precision is fine.
- **VIP user already cancelled.** Renewal warning still fires (their VIP is ending; they should be reminded). Even more important if they cancelled — gives them a chance to reconsider. Don't gate by `autoRenew`.
- **`friend_request` semantic naming.** Today the type is called `friend_request` but the app doesn't have friend requests — it has follow. Keep the type string for compatibility but document as legacy in the recon. Future cleanup: rename to `new_follower` in a separate wave with migration logic for in-flight pushes.
- **Foreground push for comment.** A user actively browsing the comments thread on their own moment gets a system notification for a new comment on that moment. Mild redundancy. Acceptable v1; SnackBar replacement is polish.
- **Multi-device.** All `user.fcmTokens.filter(active)` tokens get the push. Acceptable. If user reads on phone, badge clears on phone; tablet still shows it until tapped. Acceptable v1.
- **Preferences migration for existing users.** Adding `comment`, `newFollower`, `vipRenewalWarning` fields with `default: true`. Existing user docs without these fields → Mongoose default kicks in on save, BUT `_shouldSendNotification` reads via plain property access — `user.notificationPreferences.comment` returns `undefined` for old docs until they're re-saved. Need an explicit `?? true` fallback in the preference check OR a one-time migration. Lean: fallback in the check (lazy migration, no DB churn).

---

## Three-option design choices

### D-1. Chat push delivery gate

| Option | Pros | Cons |
|---|---|---|
| **A. Gate by `userConnections.has(receiverId)`** — push only when socket is disconnected | Matches stated user preference. No double-notification. Single-line check. | If user has app open but chat socket dropped (flaky network), they miss the in-app message — but the push catches them. Actually a feature. |
| **B. Always push, let client-side suppress in foreground** | Simpler server. Same end-user UX. | Wasted FCM quota. The OS doesn't know to silence a notification for a user who's "actively in the chat" — the suppress-in-foreground rule applies broadly. |
| **C. Gate by `socket.connected && socket.activeChatId === senderId`** — only suppress if user is actively on that specific chat thread | Most precise. No suppression for users in other chats. | Need per-socket active-chat tracking (not in `userConnections` today). Bigger change. |

**Recommendation tilt: A.** Matches the stated rule, minimal code change, the "flaky network" edge is acceptable.

### D-2. Where to add the missing preference fields

| Option | Pros | Cons |
|---|---|---|
| **A. Add fields to `User.notificationPreferences` with `default: true`** | Schema-honest. Clear field-by-field opt-out. | Existing user docs don't have the fields; reads return `undefined` until re-save. Need fallback in `_shouldSendNotification`. |
| **B. Add fields with `default: true` + one-time migration script to set them on all existing users** | Eager — every user has the fields explicitly. | One-time DB churn (~1K writes); avoids fallback logic. |
| **C. Skip the fields, allow all 5 types unconditionally** | Simplest. | Breaks the "honor preferences" promise. Trust regression. |

**Recommendation tilt: A.** Lazy migration with `??  true` in `_shouldSendNotification`. No DB churn, schema honest, preferences honored.

### D-3. Story comment push — in scope or out?

| Option | Pros | Cons |
|---|---|---|
| **A. Add it (parity with moment comments)** | Closes a real product gap. ~5 lines. The `comment` preference field gates both. | Slightly broader scope. |
| **B. Punt to queued engineering** | Tighter wave. | Story comments silently don't notify — confusing for users. |

**Recommendation tilt: A.** Parity is more valuable than scope discipline here; the marginal cost is negligible.

### D-4. Rename `friend_request` → `new_follower`?

| Option | Pros | Cons |
|---|---|---|
| **A. Keep `friend_request` type** | No deep-link compatibility risk. | Semantic mismatch with app concept. Future confusion. |
| **B. Rename, add forwarding case in Flutter router for legacy** | Cleaner long-term. | Wave bloats with rename + migration. Test surface expands. |

**Recommendation tilt: A.** Keep `friend_request` for this wave. The semantic naming is a "code review polish" issue, not a user-visible one. Queue rename for a future cleanup.

### D-5. New `vip_renewal_warning` template — distinct method or generic `send()`?

| Option | Pros | Cons |
|---|---|---|
| **A. Add `notificationService.sendVipRenewalWarning(userId, daysLeft)` typed method** | Matches existing pattern (sendChatMessage, sendWave). Title/body construction localized. | One more method in an already-large file. |
| **B. Inline the call: `notificationService.send(userId, 'vip_renewal_warning', { title: ..., body: ..., data: ... })`** | Less code. Single call site so no DRY pressure. | Title / body construction lives in the job, awkward when localization comes later. |

**Recommendation tilt: A.** Consistency with the rest of the file wins; the marginal cost is one method.

### D-6. Foreground UX for new push types

| Option | Pros | Cons |
|---|---|---|
| **A. System notification (current default for non-chat types)** | Matches existing wave/comment behavior; no new UI. | A user in the comments tab gets a system notification for a new comment in the same thread. Mild noise. |
| **B. SnackBar / in-app banner when user is in the app** | More polished. | New UI primitive; cross-cutting; bigger change. |
| **C. Conditional — suppress in-foreground for comments + wave; system for follower + VIP** | Per-type tuning. | Inconsistent rules; bikeshed-prone. |

**Recommendation tilt: A.** Keep the existing foreground rule. SnackBar is polish for a future wave once the wiring is solid.

---

## Punted findings (out of scope; queue for future)

- **Story comment owner notification.** Wait — moved to "in scope" per D-3.
- **In-app SnackBar / banner for foreground messages** (D-6 option B). Better UX, separate wave.
- **`friend_request` → `new_follower` type rename** (D-4 option B). Semantic cleanup, separate wave.
- **Scheduled / timed pushes** — streak reminders, daily quota refresh, story expiring soon. Need user-local-time scheduling infra (today's cron is UTC). Step 17 candidate.
- **AI Study tutor chip pushes** — "your daily chips refresh in 1h" etc. Same scheduled-push infra.
- **Mentions** (`comment_mention`, `@-mention in messages`). Type strings exist; router gaps exist; mention parsing in messages does not. Treat as part of a mentions wave.
- **Voice room invite push**. Rare event. Defer.
- **User-facing notification history inbox screen.** `Notification` model already records everything; the surface to view it isn't built. Future wave.
- **Bundled push for moment likes**. `sendMomentLike` already does bundling (up to 3h) per notificationService.js:173. Not in this wave's scope.
- **Per-conversation chat push throttle** (5-minute coalescing if same sender). OS-level summary covers most of the noise; can be added if real-world feedback says noisy.
- **Quiet hours UI** — backend has the logic but no Flutter setting for it. Settings polish.

---

## What this recon does NOT cover

- Exact wording / localization keys for the new push titles + bodies — that's plan territory.
- Specific deep-link target paths for new router cases — same.
- File-by-file commit decomposition — same.

The plan will turn the recommendations above (D-1 through D-6) into locked decisions, with rejected alternatives spelled out per the Step 14 / Step 15 plan format.
