# Step 4 — Community Wave 2 + Voice Room Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship scheduled voice rooms with RSVP + reminder cron, four community/voice-room smalls (recently-active sort, profile-visitor recall, mute-all, conversation-starter prompts), and five wave-1 followups bundled (local-user speaking indicator, voice room categories, reconnect banner UX, wave history archive, mutual interests minimum filter).

**Architecture:** Stack on existing wave-1 voice-room infra (heartbeat, host transfer, reconnect, presence). One new backend cron in the existing `jobs/scheduler.js` setTimeout pattern. Schema additions all default-safe; everything additive for back-compat with the currently-deployed app.

**Tech Stack:** Flutter + Riverpod, Node.js/Express + MongoDB (backend), Socket.IO, FCM, go_router

**Spec:** `docs/superpowers/specs/2026-05-09-step4-community-wave2-design.md`

**Branch:** `refactor/step4-community-wave2` (off `main`)

**Project pattern:** No new Flutter widget tests — verification is `flutter analyze` clean + manual smoke. Backend additions get unit tests where indicated.

---

## Branch setup

- [ ] **Step 1: Create branch off main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull
git checkout -b refactor/step4-community-wave2
```

- [ ] **Step 2: Verify clean state**

```bash
git status -s | grep -v -E "(Podfile.lock|generated_plugin_registrant|GeneratedPluginRegistrant)"
flutter analyze lib/pages/community/voice_rooms/ 2>&1 | tail -5
```

Expected: zero analyzer errors (warnings/info OK).

---

## Task C0 — chore(community): branch + deps audit

- [ ] **Step 1: Confirm no new deps needed**

Step 4 introduces no new packages. Uses `flutter_riverpod`, `shared_preferences`, `http`, `socket_io_client`, `go_router`, `intl` (for date picker), `flutter_webrtc` — all present.

```bash
grep -E "^  (flutter_riverpod|shared_preferences|http|socket_io_client|go_router|intl|flutter_webrtc):" pubspec.yaml
```

If anything missing, add via `flutter pub add <name>`. Otherwise skip.

---

## Task C1 — refactor(community): add ~30 English ARB keys

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_localizations.dart` (regenerated), `lib/l10n/app_localizations_en.dart` (regenerated)

- [ ] **Step 1: Insert keys into `app_en.arb`** (skip any that exist with the same value)

```json
"scheduleForLater": "Schedule for later",
"pickDate": "Pick date",
"pickTime": "Pick time",
"upcomingRooms": "Upcoming",
"inHours": "in {h}h {m}m",
"@inHours": {"placeholders": {"h": {"type": "int"}, "m": {"type": "int"}}},
"inMinutes": "in {m}m",
"@inMinutes": {"placeholders": {"m": {"type": "int"}}},
"startsNow": "Starting now",
"iWillBeThere": "I'll be there",
"cantMakeIt": "Can't make it",
"rsvpCount": "{count, plural, =0{No RSVPs} =1{1 RSVP} other{{count} RSVPs}}",
"@rsvpCount": {"placeholders": {"count": {"type": "int"}}},
"roomStartsIn1h": "{title} starts in 1 hour",
"@roomStartsIn1h": {"placeholders": {"title": {"type": "String"}}},
"roomStartsIn15min": "{title} starts in 15 minutes",
"@roomStartsIn15min": {"placeholders": {"title": {"type": "String"}}},
"roomStarted": "{title} is starting now",
"@roomStarted": {"placeholders": {"title": {"type": "String"}}},
"cancelRoom": "Cancel room",
"muteAll": "Mute all",
"mutedByHost": "Host muted everyone",
"muteAllConfirm": "Mute everyone in the room?",
"categoryCasual": "Casual",
"categoryLanguagePractice": "Language practice",
"categoryTopic": "Topic",
"categoryQA": "Q&A",
"pickCategory": "Category",
"sortRecentlyActive": "Recently active",
"visitedYourProfile": "{count, plural, =1{1 person visited your profile} other{{count} people visited your profile}}",
"@visitedYourProfile": {"placeholders": {"count": {"type": "int"}}},
"noRecentVisitors": "No recent visitors",
"viewArchive": "View archive",
"archivedWaves": "Archived waves",
"noArchivedWaves": "No archived waves",
"mutualInterestsMin": "Mutual interests (min)",
"atLeastNTopics": "{n, plural, =0{Any} =1{At least 1 topic in common} other{At least {n} topics in common}}",
"@atLeastNTopics": {"placeholders": {"n": {"type": "int"}}},
"starterAskMoment": "Ask about their last moment",
"starterSayHi": "Say hi in their language",
"starterCurious": "What are they curious about?",
"starterFromCountry": "Hi from {country}!",
"@starterFromCountry": {"placeholders": {"country": {"type": "String"}}},
"starterPracticeLang": "Help them practice {language}!",
"@starterPracticeLang": {"placeholders": {"language": {"type": "String"}}}
```

- [ ] **Step 2: Regenerate**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
git commit -m "refactor(community): C1 — add ~32 English ARB keys for Step 4"
```

---

## Task C2 — refactor(community): translate ARB keys to 17 locales

- [ ] **Step 1: For each of the 17 locales** (`ar de es fr hi id it ja ko pt ru th tl tr vi zh zh_TW`), add the same keys with locale-appropriate translations.

Critical rules:
- Preserve ICU placeholders (`{count}`, `{h}`, `{m}`, `{title}`, `{country}`, `{language}`, `{n}`)
- Preserve plural ICU syntax for `rsvpCount`, `visitedYourProfile`, `atLeastNTopics`
- Skip keys that already exist with any value
- Korean/Japanese/Chinese can use `=1`/`other` only

For agentic execution: dispatch one agent across all 17 locales (per Step 2/3 cadence).

- [ ] **Step 2: Verify**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -10
```

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "refactor(community): C2 — translate ~32 Step 4 keys to 17 locales"
```

---

## Task C3 — feat(voice-rooms) + backend: VoiceRoom schema additions

**Files (backend):**
- Modify: `models/VoiceRoom.js` — add `scheduledFor`, `rsvps`, `remindersSent`, `category`; extend `status` enum

- [ ] **Step 1: Survey existing schema**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
grep -n "status:\|enum:\|VoiceRoomSchema.index" models/VoiceRoom.js | head -20
```

- [ ] **Step 2: Add fields**

In `models/VoiceRoom.js`, locate the `status` field (around line 80) and update its enum:

```js
status: {
  type: String,
  enum: ['scheduled', 'waiting', 'active', 'ended'],  // 'scheduled' added
  default: 'active',
},
```

Add the new fields nearby (e.g., after `status` block):

```js
scheduledFor: { type: Date, default: null },
rsvps: [{
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  rsvpAt: { type: Date, default: Date.now },
}],
remindersSent: { type: [String], default: [] },
category: {
  type: String,
  enum: ['casual', 'language_practice', 'topic', 'qa'],
  default: null,
},
```

(Note: omit `null` from the `enum` array — Mongoose treats unspecified field as `null` by default. The `default: null` is what makes it optional.)

Add a new index alongside the existing ones:

```js
VoiceRoomSchema.index({ status: 1, scheduledFor: 1 });
```

- [ ] **Step 3: Verify syntax**

```bash
node --check models/VoiceRoom.js
```

- [ ] **Step 4: Commit**

```bash
git add models/VoiceRoom.js
git commit -m "feat(voice-rooms): C3 — VoiceRoom schema additions for scheduled rooms (scheduledFor, rsvps, remindersSent, category, status:'scheduled')"
```

---

## Task C4 — feat(voice-rooms) + backend: RSVP routes + controller

**Files (backend):**
- Modify: `controllers/voiceRooms.js` — add `rsvp`, `unrsvp` actions; extend list endpoint to support `?status=` filter
- Modify: `routes/voicerooms.js` (or wherever voice room routes live) — add 2 routes

- [ ] **Step 1: Survey existing voice room controller + routes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
ls controllers/ routes/ | grep -i voice
grep -n "exports\.\|router\." controllers/voiceRooms.js routes/voicerooms.js 2>/dev/null | head -30
```

Identify:
- The existing route file path (likely `routes/voicerooms.js` or `routes/voiceRooms.js`)
- Which controller handles room list (`getRooms`, `listRooms`, `getActiveRooms`)
- Auth middleware name (likely `protect`)
- Response wrapper (`{success, data}`)

- [ ] **Step 2: Add `rsvp` controller method**

In `controllers/voiceRooms.js`, append:

```js
exports.rsvp = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;
  const room = await VoiceRoom.findById(req.params.id);
  if (!room) return next(new ErrorResponse('Room not found', 404));
  if (room.status !== 'scheduled') {
    return next(new ErrorResponse('Can only RSVP to scheduled rooms', 400));
  }
  // Check if already RSVP'd
  const existing = room.rsvps.find(r => String(r.user) === String(userId));
  if (existing) {
    return res.status(200).json({
      success: true,
      data: { rsvpCount: room.rsvps.length },
    });
  }
  room.rsvps.push({ user: userId, rsvpAt: new Date() });
  await room.save();
  res.status(200).json({
    success: true,
    data: { rsvpCount: room.rsvps.length },
  });
});

exports.unrsvp = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;
  const room = await VoiceRoom.findById(req.params.id);
  if (!room) return next(new ErrorResponse('Room not found', 404));
  room.rsvps = room.rsvps.filter(r => String(r.user) !== String(userId));
  await room.save();
  res.status(200).json({
    success: true,
    data: { rsvpCount: room.rsvps.length },
  });
});
```

Adapt `asyncHandler` and `ErrorResponse` to actual paths used by other handlers in the file.

- [ ] **Step 3: Extend list endpoint to support `?status=`**

In the existing `getRooms` (or whatever it's called) handler, accept the param:

```js
// Inside the list handler, near other query parsing:
const statusFilter = req.query.status;
let statusQuery;
if (statusFilter === 'scheduled') {
  statusQuery = 'scheduled';
} else if (statusFilter === 'all') {
  statusQuery = { $in: ['scheduled', 'waiting', 'active'] };
} else {
  // Default = old behavior (active rooms only)
  statusQuery = { $in: ['waiting', 'active'] };
}
// Use statusQuery in the find filter
```

The default preserves backward compatibility — old clients calling without `?status=` still get only active/waiting rooms (no scheduled ones leak in).

- [ ] **Step 4: Wire routes**

In `routes/voicerooms.js`:

```js
const { rsvp, unrsvp } = require('../controllers/voiceRooms');

router.post('/:id/rsvp', protect, rsvp);
router.delete('/:id/rsvp', protect, unrsvp);
```

- [ ] **Step 5: Verify syntax**

```bash
node --check controllers/voiceRooms.js
node --check routes/voicerooms.js
```

- [ ] **Step 6: Commit**

```bash
git add controllers/voiceRooms.js routes/voicerooms.js
git commit -m "feat(voice-rooms): C4 — RSVP routes + status filter on list endpoint"
```

---

## Task C5 — feat(voice-rooms) + backend: voiceRoomSchedulerJob

**Files (backend):**
- Create: `jobs/voiceRoomSchedulerJob.js`
- Modify: `jobs/scheduler.js` (wire the new job)
- Modify: `services/notificationService.js` (add `sendScheduledRoomReminder` + `sendScheduledRoomStarted`)

- [ ] **Step 1: Create the job file**

`jobs/voiceRoomSchedulerJob.js`:

```js
/**
 * Voice Room Scheduler Job
 *
 * Two responsibilities:
 * 1. Flip scheduled rooms with `scheduledFor <= now` to `status: 'active'`
 *    and broadcast/push to RSVPs + host
 * 2. Fire 1h and 15min reminder pushes for upcoming rooms
 *
 * Runs every 60s. Idempotent via `remindersSent` array.
 */

const VoiceRoom = require('../models/VoiceRoom');
const {
  sendScheduledRoomStarted,
  sendScheduledRoomReminder,
} = require('../services/notificationService');

const TICK_MS = 60 * 1000;

let _intervalHandle = null;

async function _runStarts() {
  const now = new Date();
  const toStart = await VoiceRoom.find({
    status: 'scheduled',
    scheduledFor: { $lte: now },
  }).select('_id host title rsvps');

  for (const room of toStart) {
    try {
      // Atomic flip — guard against double-firing if cron overruns
      const updated = await VoiceRoom.findOneAndUpdate(
        { _id: room._id, status: 'scheduled' },
        { $set: { status: 'active', lastHeartbeatAt: now } },
        { new: true }
      );
      if (!updated) continue;  // someone else flipped it first

      // Notify host + RSVPs
      const recipients = [String(updated.host)];
      for (const r of updated.rsvps) {
        recipients.push(String(r.user));
      }
      const unique = [...new Set(recipients)];
      for (const userId of unique) {
        sendScheduledRoomStarted(userId, updated._id, updated.title).catch(err =>
          console.error('[voiceRoomScheduler/start] push failed:', err.message)
        );
      }
    } catch (err) {
      console.error('[voiceRoomScheduler/_runStarts]', err);
    }
  }
}

async function _runReminders() {
  const now = new Date();
  const in1h = new Date(now.getTime() + 60 * 60 * 1000);
  const in15min = new Date(now.getTime() + 15 * 60 * 1000);

  // 1h reminders
  const due1h = await VoiceRoom.find({
    status: 'scheduled',
    scheduledFor: { $lte: in1h, $gt: in15min },
    remindersSent: { $nin: ['1h'] },
  }).select('_id title rsvps remindersSent');
  for (const room of due1h) {
    try {
      // Atomic add
      const updated = await VoiceRoom.findOneAndUpdate(
        { _id: room._id, remindersSent: { $nin: ['1h'] } },
        { $push: { remindersSent: '1h' } },
        { new: true }
      );
      if (!updated) continue;
      for (const r of updated.rsvps) {
        sendScheduledRoomReminder(r.user, updated._id, updated.title, '1h').catch(err =>
          console.error('[voiceRoomScheduler/reminder1h] push failed:', err.message)
        );
      }
    } catch (err) {
      console.error('[voiceRoomScheduler/_runReminders 1h]', err);
    }
  }

  // 15min reminders
  const due15 = await VoiceRoom.find({
    status: 'scheduled',
    scheduledFor: { $lte: in15min, $gt: now },
    remindersSent: { $nin: ['15min'] },
  }).select('_id title rsvps remindersSent');
  for (const room of due15) {
    try {
      const updated = await VoiceRoom.findOneAndUpdate(
        { _id: room._id, remindersSent: { $nin: ['15min'] } },
        { $push: { remindersSent: '15min' } },
        { new: true }
      );
      if (!updated) continue;
      for (const r of updated.rsvps) {
        sendScheduledRoomReminder(r.user, updated._id, updated.title, '15min').catch(err =>
          console.error('[voiceRoomScheduler/reminder15] push failed:', err.message)
        );
      }
    } catch (err) {
      console.error('[voiceRoomScheduler/_runReminders 15min]', err);
    }
  }
}

function start() {
  if (_intervalHandle) return;
  _intervalHandle = setInterval(() => {
    _runStarts().catch(err => console.error('[voiceRoomScheduler]', err));
    _runReminders().catch(err => console.error('[voiceRoomScheduler]', err));
  }, TICK_MS);
  console.log('[voiceRoomScheduler] job started (every 60s)');
}

function stop() {
  if (_intervalHandle) {
    clearInterval(_intervalHandle);
    _intervalHandle = null;
  }
}

module.exports = { start, stop, _runStarts, _runReminders };
```

- [ ] **Step 2: Add notification helpers**

In `services/notificationService.js`, append two new functions (mirror the existing `sendWave` / `sendVoiceRoomInvite` pattern):

```js
exports.sendScheduledRoomStarted = async (userId, roomId, title) => {
  const user = await User.findById(userId).select('fcmToken notificationPreferences');
  if (!user?.fcmToken) return;
  if (!shouldNotify(user, 'voiceRoomStart')) return;

  await fcmService.sendToUser({
    userId: user._id,
    token: user.fcmToken,
    notification: {
      title: 'Room starting now',
      body: `${title} is starting now`,
    },
    data: {
      type: 'voice_room_start',
      roomId: String(roomId),
      route: `/voicerooms/${roomId}`,
    },
  });
};

exports.sendScheduledRoomReminder = async (userId, roomId, title, when) => {
  // when = '1h' | '15min'
  const user = await User.findById(userId).select('fcmToken notificationPreferences');
  if (!user?.fcmToken) return;
  if (!shouldNotify(user, 'scheduledRoomReminder')) return;

  const body = when === '1h'
    ? `${title} starts in 1 hour`
    : `${title} starts in 15 minutes`;

  await fcmService.sendToUser({
    userId: user._id,
    token: user.fcmToken,
    notification: {
      title: 'Upcoming room',
      body,
    },
    data: {
      type: 'scheduled_room_reminder',
      roomId: String(roomId),
      when,
      route: `/voicerooms/${roomId}`,
    },
  });
};
```

Adapt `fcmService.sendToUser` and `shouldNotify` import paths to the actual module structure (per Step 2 C7, `shouldNotify` is exported from `notificationService.js` itself, so it's a local function reference).

- [ ] **Step 3: Wire into scheduler**

In `jobs/scheduler.js`, near the other job imports + start calls:

```js
const voiceRoomSchedulerJob = require('./voiceRoomSchedulerJob');

// Inside startScheduler():
voiceRoomSchedulerJob.start();
```

- [ ] **Step 4: Verify syntax**

```bash
node --check jobs/voiceRoomSchedulerJob.js
node --check jobs/scheduler.js
node --check services/notificationService.js
```

- [ ] **Step 5: Commit**

```bash
git add jobs/voiceRoomSchedulerJob.js jobs/scheduler.js services/notificationService.js
git commit -m "feat(voice-rooms): C5 — voiceRoomSchedulerJob (start cron + 1h/15min reminders)"
```

---

## Task C6 — feat(voice-rooms): scheduled_room_card + upcoming_section (Flutter)

**Files (Flutter):**
- Create: `lib/pages/community/voice_rooms/scheduled_room_card.dart`
- Create: `lib/pages/community/voice_rooms/upcoming_section.dart`
- Modify: `lib/models/community/voice_room_model.dart` (add `scheduledFor`, `rsvps`, `category`, `'scheduled'` status)

- [ ] **Step 1: Update VoiceRoom model**

In `lib/models/community/voice_room_model.dart`, find the `VoiceRoom` class. Add fields:

```dart
final String? category;
final DateTime? scheduledFor;
final List<String> rsvpUserIds;  // simple list of user IDs from rsvps[]
```

Update `fromJson`:

```dart
category: json['category']?.toString(),
scheduledFor: json['scheduledFor'] != null
    ? DateTime.tryParse(json['scheduledFor'].toString())
    : null,
rsvpUserIds: (json['rsvps'] as List?)
        ?.map((e) => (e is Map ? e['user']?.toString() : null))
        .whereType<String>()
        .toList() ??
    const [],
```

Update `copyWith` if it exists.

- [ ] **Step 2: Create `scheduled_room_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class ScheduledRoomCard extends ConsumerStatefulWidget {
  final VoiceRoom room;
  const ScheduledRoomCard({super.key, required this.room});

  @override
  ConsumerState<ScheduledRoomCard> createState() => _ScheduledRoomCardState();
}

class _ScheduledRoomCardState extends ConsumerState<ScheduledRoomCard> {
  bool _isToggling = false;

  Future<void> _toggleRsvp() async {
    if (_isToggling) return;
    final myId = ref.read(authServiceProvider).userId;
    final isRsvpd = widget.room.rsvpUserIds.contains(myId);
    setState(() => _isToggling = true);
    try {
      if (isRsvpd) {
        await ref.read(voiceRoomProvider).unrsvp(widget.room.id);
      } else {
        await ref.read(voiceRoomProvider).rsvp(widget.room.id);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  String _countdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheduledFor = widget.room.scheduledFor;
    if (scheduledFor == null) return l10n.startsNow;
    final diff = scheduledFor.difference(DateTime.now());
    if (diff.isNegative) return l10n.startsNow;
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0) return l10n.inHours(h, m);
    return l10n.inMinutes(m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.watch(authServiceProvider).userId;
    final isRsvpd = widget.room.rsvpUserIds.contains(myId);
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.room.title,
              style: context.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(widget.room.hostName,
              style: context.bodySmall.copyWith(color: context.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: context.textMuted),
              const SizedBox(width: 4),
              Text(_countdown(context),
                  style: context.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.rsvpCount(widget.room.rsvpUserIds.length),
              style: context.captionSmall.copyWith(color: context.textMuted)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isToggling ? null : _toggleRsvp,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRsvpd ? context.containerColor : AppColors.primary,
                foregroundColor: isRsvpd ? context.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(isRsvpd ? l10n.cantMakeIt : l10n.iWillBeThere),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `upcoming_section.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/scheduled_room_card.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class UpcomingSection extends StatelessWidget {
  final List<VoiceRoom> rooms;
  const UpcomingSection({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(l10n.upcomingRooms, style: context.titleMedium),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: rooms.length,
            itemBuilder: (_, i) => ScheduledRoomCard(room: rooms[i]),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Add `rsvp` / `unrsvp` to `VoiceRoomNotifier`**

In `lib/providers/voice_room_provider.dart`, add to the notifier:

```dart
Future<void> rsvp(String roomId) async {
  await _apiClient.post('voicerooms/$roomId/rsvp');
  // Optimistic update — refresh fetch list to pick up new RSVP
  // (the parent tab may want to re-fetch; simplest: caller re-fetches)
}

Future<void> unrsvp(String roomId) async {
  await _apiClient.delete('voicerooms/$roomId/rsvp');
}
```

Add a `fetchScheduledRooms()` companion to `fetchRooms`:

```dart
Future<List<VoiceRoom>> fetchScheduledRooms() async {
  try {
    final response = await _apiClient.get('voicerooms?status=scheduled');
    if (response.success) {
      List data;
      if (response.data is List) {
        data = response.data as List;
      } else if (response.data is Map && response.data['data'] is List) {
        data = response.data['data'] as List;
      } else {
        data = [];
      }
      return data.map((r) => VoiceRoom.fromJson(Map<String, dynamic>.from(r))).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/ lib/providers/voice_room_provider.dart lib/models/community/voice_room_model.dart 2>&1 | tail -10
```

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "feat(voice-rooms): C6 — scheduled_room_card + upcoming_section + Flutter VoiceRoom model fields"
```

---

## Task C7 — feat(voice-rooms): create_room_sheet schedule mode + date picker

**Files:**
- Modify: `lib/pages/community/voice_rooms/create_room_sheet.dart`

- [ ] **Step 1: Read the file**

```bash
sed -n '1,80p' lib/pages/community/voice_rooms/create_room_sheet.dart
grep -n "class\|onCreateRoom\|TextField\|setState" lib/pages/community/voice_rooms/create_room_sheet.dart | head -20
```

Identify the existing post-action callback signature (likely `onCreateRoom: (title, topic, language, maxParticipants) async {}`). The new form must extend it with `scheduledFor: DateTime?` and `category: String?`.

- [ ] **Step 2: Update the callback signature + state**

Add to `_CreateRoomSheetState`:

```dart
bool _isScheduled = false;
DateTime? _scheduledFor;
String? _category;
```

Update the `onCreateRoom` callback type in the parent. From `voice_rooms_tab.dart`'s `_createRoom`:

```dart
// Old: onCreateRoom: (title, topic, language, maxParticipants) async { ... }
// New: onCreateRoom: (title, topic, language, maxParticipants, scheduledFor, category) async { ... }
```

Make `scheduledFor` and `category` nullable (`DateTime? scheduledFor, String? category`).

- [ ] **Step 3: Add UI for the toggle + date picker**

Inside the sheet build, after the existing fields:

```dart
SwitchListTile(
  title: Text(AppLocalizations.of(context)!.scheduleForLater),
  value: _isScheduled,
  onChanged: (v) => setState(() {
    _isScheduled = v;
    if (!v) _scheduledFor = null;
  }),
  activeColor: AppColors.primary,
),
if (_isScheduled) ...[
  const SizedBox(height: 8),
  Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(_scheduledFor == null
              ? AppLocalizations.of(context)!.pickDate
              : '${_scheduledFor!.year}-${_scheduledFor!.month.toString().padLeft(2, '0')}-${_scheduledFor!.day.toString().padLeft(2, '0')}'),
          onPressed: _pickDate,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.access_time),
          label: Text(_scheduledFor == null
              ? AppLocalizations.of(context)!.pickTime
              : '${_scheduledFor!.hour.toString().padLeft(2, '0')}:${_scheduledFor!.minute.toString().padLeft(2, '0')}'),
          onPressed: _scheduledFor == null ? null : _pickTime,
        ),
      ),
    ],
  ),
],
```

Add the picker methods:

```dart
Future<void> _pickDate() async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: _scheduledFor ?? now.add(const Duration(hours: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 30)),
  );
  if (picked != null) {
    setState(() {
      _scheduledFor = DateTime(
        picked.year, picked.month, picked.day,
        _scheduledFor?.hour ?? now.hour,
        _scheduledFor?.minute ?? now.minute,
      );
    });
  }
}

Future<void> _pickTime() async {
  if (_scheduledFor == null) return;
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(_scheduledFor!),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );
  if (picked != null) {
    final rounded = picked.minute - (picked.minute % 15);  // 15-min increments
    setState(() {
      _scheduledFor = DateTime(
        _scheduledFor!.year, _scheduledFor!.month, _scheduledFor!.day,
        picked.hour, rounded,
      );
    });
  }
}
```

- [ ] **Step 4: Add category picker**

After the schedule toggle:

```dart
DropdownButtonFormField<String?>(
  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.pickCategory),
  value: _category,
  items: [
    DropdownMenuItem(value: null, child: Text('—')),
    DropdownMenuItem(value: 'casual', child: Text(AppLocalizations.of(context)!.categoryCasual)),
    DropdownMenuItem(value: 'language_practice', child: Text(AppLocalizations.of(context)!.categoryLanguagePractice)),
    DropdownMenuItem(value: 'topic', child: Text(AppLocalizations.of(context)!.categoryTopic)),
    DropdownMenuItem(value: 'qa', child: Text(AppLocalizations.of(context)!.categoryQA)),
  ],
  onChanged: (v) => setState(() => _category = v),
),
```

- [ ] **Step 5: Pass `scheduledFor` + `category` to the create call**

In the existing "Create" button's onPressed, the callback now receives the extra args:

```dart
widget.onCreateRoom(
  _titleController.text,
  _topicController.text,
  _selectedLanguage,
  _maxParticipants,
  _isScheduled ? _scheduledFor : null,
  _category,
);
```

- [ ] **Step 6: Update voice_rooms_tab.dart's _createRoom**

In `voice_rooms_tab.dart`, the `onCreateRoom` callback signature changes — adapt the `CreateRoomRequest` model to include `scheduledFor` + `category`:

```dart
final request = CreateRoomRequest(
  title: title,
  topic: topic,
  language: language,
  maxParticipants: maxParticipants,
  scheduledFor: scheduledFor,
  category: category,
);
```

Add `scheduledFor` + `category` to `CreateRoomRequest` in `lib/models/community/voice_room_model.dart`:

```dart
class CreateRoomRequest {
  final String title;
  final String topic;
  final String language;
  final int maxParticipants;
  final DateTime? scheduledFor;
  final String? category;

  const CreateRoomRequest({
    required this.title,
    required this.topic,
    required this.language,
    this.maxParticipants = 8,
    this.scheduledFor,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'topic': topic,
    'language': language,
    'maxParticipants': maxParticipants,
    if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
    if (scheduledFor != null) 'status': 'scheduled',
    if (category != null) 'category': category,
  };
}
```

(Setting `status: 'scheduled'` in the create request for scheduled rooms — backend honors this since the create handler reads the body.)

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/ lib/models/community/voice_room_model.dart 2>&1 | tail -10
```

- [ ] **Step 8: Commit**

```bash
git add lib/
git commit -m "feat(voice-rooms): C7 — create_room_sheet schedule mode + date picker + category picker"
```

---

## Task C8 — feat(voice-rooms): voice_rooms_tab integration + RSVP wiring

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_rooms_tab.dart`

- [ ] **Step 1: Add a fetched-list state for scheduled rooms**

```dart
List<VoiceRoom> _scheduledRooms = [];

@override
void initState() {
  super.initState();
  _roomsFuture = _fetchWithFilters();
  _loadScheduled();  // fire and forget; refreshed on pull-to-refresh
}

Future<void> _loadScheduled() async {
  final scheduled = await ref.read(voiceRoomProvider).fetchScheduledRooms();
  if (mounted) setState(() => _scheduledRooms = scheduled);
}

Future<void> _refreshAll() async {
  setState(() {
    _roomsFuture = _fetchWithFilters();
  });
  await _loadScheduled();
}
```

- [ ] **Step 2: Render `UpcomingSection` above the live rooms list**

Find `_buildRoomsList` (the body that builds the live rooms slivers). Add a `SliverToBoxAdapter(child: UpcomingSection(rooms: _scheduledRooms))` near the top of the slivers list, before the existing live-rooms content.

```dart
import 'package:bananatalk_app/pages/community/voice_rooms/upcoming_section.dart';

// In the CustomScrollView slivers:
SliverToBoxAdapter(
  child: UpcomingSection(rooms: _scheduledRooms),
),
// ... existing slivers (header, filters, rooms list) ...
```

- [ ] **Step 3: Wire the RefreshIndicator to `_refreshAll`**

```dart
RefreshIndicator(
  onRefresh: _refreshAll,
  child: CustomScrollView(...),
),
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/voice_rooms_tab.dart 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/voice_rooms/voice_rooms_tab.dart
git commit -m "feat(voice-rooms): C8 — voice_rooms_tab integrates UpcomingSection + scheduled-rooms refresh"
```

---

## Task C9 — feat(community) + backend: recently-active sort

**Files (backend):**
- Modify: `controllers/users.js` — extend `buildUsersQuery` with `?sort=recently_active`

**Files (Flutter):**
- Modify: `lib/pages/community/tabs/partner_discovery_tab.dart` — add sort chip

- [ ] **Step 1: Backend — extend buildUsersQuery**

In `controllers/users.js`, find `buildUsersQuery(req)` (line 70). It returns an object — likely shape `{filter, sort, limit, page, ...}` or just `filter`. Read the actual return shape and adapt.

Add a new return key or update existing sort logic:

```js
// Inside buildUsersQuery, near other req.query parsing:
let sortSpec = { lastActive: -1 };  // existing default — adapt to actual default
if (req.query.sort === 'recently_active') {
  sortSpec = { lastSeenAt: -1, _id: -1 };  // tiebreak by _id for stable order
}
// ... rest of helper
return { filter, sort: sortSpec, ... };
```

If the helper currently inlines the sort in `getUsers`, lift it into the helper so both `getUsers` and `getUsersCount` can share the logic.

- [ ] **Step 2: Verify backend syntax**

```bash
node --check controllers/users.js
```

- [ ] **Step 3: Backend commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/users.js
git commit -m "feat(community): C9 — ?sort=recently_active in buildUsersQuery"
```

- [ ] **Step 4: Flutter — sort chip in partner_discovery_tab**

In `lib/pages/community/tabs/partner_discovery_tab.dart`, add a sort state field:

```dart
String? _sort;  // null = default, 'recently_active' otherwise
```

Add a horizontal chip row near the top (above the list):

```dart
Wrap(
  spacing: 8,
  children: [
    ChoiceChip(
      label: Text(AppLocalizations.of(context)!.sortRecentlyActive),
      selected: _sort == 'recently_active',
      onSelected: (selected) {
        setState(() => _sort = selected ? 'recently_active' : null);
        _refresh();  // existing refresh method
      },
    ),
  ],
),
```

In whatever method calls the user-list service, append the sort param when set:

```dart
queryParams['sort'] = _sort ?? '';
```

(Adapt to the actual query-param plumbing in the tab — likely via `PartnerFilterParams` or a Map.)

- [ ] **Step 5: Verify Flutter**

```bash
flutter analyze lib/pages/community/tabs/partner_discovery_tab.dart 2>&1 | tail -10
```

- [ ] **Step 6: Flutter commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/community/tabs/partner_discovery_tab.dart
git commit -m "feat(community): C9 — recently-active sort chip on partner_discovery_tab"
```

---

## Task C10 — feat(community): profile-visitor recall card

**Files:**
- Create: `lib/pages/community/widgets/visitor_recall_card.dart`
- Modify: `lib/pages/community/main/community_main.dart`

- [ ] **Step 1: Read the existing visitor service**

```bash
grep -n "class\|getMyVisitors\|recentVisitors" lib/services/profile_visitor_service.dart lib/providers/provider_root/profile_visitor_provider.dart 2>/dev/null | head -10
```

Identify:
- The provider name (likely `profileVisitorProvider`)
- The data shape (likely `List<Visitor>` with `userId`, `name`, `avatar`, `visitedAt` fields)

- [ ] **Step 2: Create the card**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/profile_visitor_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class VisitorRecallCard extends ConsumerWidget {
  const VisitorRecallCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Adapt to actual provider shape — common pattern is AsyncValue<List<X>>
    final visitorsAsync = ref.watch(profileVisitorProvider);
    return visitorsAsync.when(
      data: (visitors) {
        if (visitors.isEmpty) return const SizedBox.shrink();
        final shown = visitors.take(5).toList();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: AppRadius.borderLG,
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.visitedYourProfile(visitors.length),
                  style: context.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final v = shown[i];
                    // Adapt fields to actual visitor model
                    final id = v.userId ?? v.id ?? '';
                    final avatar = v.avatar ?? v.profilePicture ?? '';
                    return GestureDetector(
                      onTap: () {
                        if (id.isNotEmpty) context.push('/profile/$id');
                      },
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

**Adapt the property accesses (`v.userId`, `v.avatar`)** to the actual visitor model field names. Read the visitor model file before committing.

- [ ] **Step 3: Insert into community_main.dart**

Find `community_main.dart`'s build, between the search bar and the tab strip. Add:

```dart
import 'package:bananatalk_app/pages/community/widgets/visitor_recall_card.dart';

// In the build, between search bar and tabs:
const VisitorRecallCard(),
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/pages/community/widgets/visitor_recall_card.dart lib/pages/community/main/community_main.dart 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add lib/
git commit -m "feat(community): C10 — profile-visitor recall card on community_main"
```

---

## Task C11 — feat(voice-rooms) + backend: mute-all host control

**Files (backend):**
- Modify: `socket/voiceRoomHandler.js` — add `voiceroom:mute-all` handler

**Files (Flutter):**
- Modify: `lib/pages/community/voice_rooms/voice_room_host_menu.dart` — add Mute all entry
- Modify: `lib/services/voice_room_manager.dart` — add `muteAll()` method
- Modify: `lib/services/chat_socket_service.dart` (if needed to handle the `forced` mute flag)

- [ ] **Step 1: Backend — add socket handler**

In `socket/voiceRoomHandler.js`, near other socket handlers:

```js
socket.on('voiceroom:mute-all', async ({ roomId }) => {
  try {
    if (!roomId) return;
    const userId = socket.user?.id;
    const room = await VoiceRoom.findById(roomId).populate('participants.user');
    if (!room) return;
    // Only host can mute all
    if (String(room.host) !== String(userId)) return;
    // Emit a synthetic mute event for every participant
    for (const p of room.participants) {
      const pid = String(p.user?._id || p.user);
      io.to(`voiceroom_${roomId}`).emit('voiceroom:mute', {
        userId: pid,
        isMuted: true,
        forced: true,
      });
    }
  } catch (err) {
    console.error('[voiceroom:mute-all]', err);
  }
});
```

- [ ] **Step 2: Backend commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add socket/voiceRoomHandler.js
git commit -m "feat(voice-rooms): C11 — voiceroom:mute-all socket handler"
```

- [ ] **Step 3: Flutter — add Mute all to host menu**

In `lib/pages/community/voice_rooms/voice_room_host_menu.dart`, add a new ListTile in the host menu:

```dart
ListTile(
  leading: const Icon(Icons.mic_off, color: Colors.orange),
  title: Text(AppLocalizations.of(context)!.muteAll),
  onTap: () async {
    Navigator.pop(sheetContext);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.muteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(d, true),
            child: Text(AppLocalizations.of(context)!.muteAll),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(voiceRoomProvider).muteAll();
    }
  },
),
```

- [ ] **Step 4: Add `muteAll()` to VoiceRoomManager + provider**

In `lib/services/voice_room_manager.dart`:

```dart
void muteAll() {
  if (_currentRoom == null) return;
  _socket?.emit('voiceroom:mute-all', {'roomId': _currentRoom!.id});
}
```

In `lib/providers/voice_room_provider.dart`, expose:

```dart
void muteAll() {
  _manager.muteAll();
}
```

- [ ] **Step 5: Show "Host muted everyone" snackbar on `forced` mute**

In the existing `_muteSub` listener inside `voice_room_manager.dart`, branch on the `forced` flag:

```dart
_muteSub = _chatSocketService!.onVoiceRoomMute.listen((data) {
  final participantId = data['userId']?.toString() ?? '';
  final isMuted = data['isMuted'] == true;
  final forced = data['forced'] == true;
  // ... existing participant flag update
  if (forced && participantId == _chatSocketService?.currentUserId) {
    onForcedMute?.call();  // new callback
  }
});
```

Wire `onForcedMute` from `voice_room_screen.dart` to show:

```dart
manager.onForcedMute = () {
  showCommunitySnackBar(
    context,
    message: AppLocalizations.of(context)!.mutedByHost,
    type: CommunitySnackBarType.info,
  );
};
```

- [ ] **Step 6: Verify Flutter**

```bash
flutter analyze lib/pages/community/voice_rooms/ lib/services/voice_room_manager.dart lib/providers/voice_room_provider.dart 2>&1 | tail -10
```

- [ ] **Step 7: Flutter commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/
git commit -m "feat(voice-rooms): C11 — mute-all host control + 'host muted everyone' snackbar"
```

---

## Task C12 — feat(community): conversation-starter prompts

**Files:**
- Create: `lib/pages/community/widgets/conversation_starter_ribbon.dart`
- Modify: `lib/pages/community/card/community_card_actions.dart` — embed ribbon
- Modify: `lib/pages/community/single/single_community_actions.dart` — embed ribbon
- Modify: `lib/router/app_router.dart` — accept optional `?prefill=` query param on `/chat/:userId`
- Modify: `lib/pages/chat/chat_screen_wrapper.dart` (or wherever `/chat/:userId` lands) — use prefill on first build

- [ ] **Step 1: Create the ribbon widget**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class ConversationStarterRibbon extends StatelessWidget {
  final Community community;
  final bool compact;
  const ConversationStarterRibbon({
    super.key,
    required this.community,
    this.compact = false,
  });

  String _pickPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = community.location?.country;
    final language = community.languageToLearn;
    final candidates = <String>[
      l10n.starterAskMoment,
      l10n.starterSayHi,
      l10n.starterCurious,
      if (country != null && country.isNotEmpty) l10n.starterFromCountry(country),
      if (language != null && language.isNotEmpty) l10n.starterPracticeLang(language),
    ];
    final hash = community.id.hashCode.abs();
    return candidates[hash % candidates.length];
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _pickPrompt(context);
    return GestureDetector(
      onTap: () {
        // Navigate to chat with the prompt pre-filled via query param
        context.push('/chat/${community.id}?prefill=${Uri.encodeComponent(prompt)}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 4 : 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: compact ? 12 : 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                prompt,
                style: (compact ? context.captionSmall : context.bodySmall)
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Adapt `community.location?.country` and `community.languageToLearn` to the actual `Community` model field names.

- [ ] **Step 2: Embed in community_card_actions.dart**

Find the existing wave button + message button row. Add the ribbon below or inline:

```dart
ConversationStarterRibbon(community: widget.community, compact: true),
```

- [ ] **Step 3: Embed in single_community_actions.dart**

Add the ribbon (non-compact) above or below the action buttons row.

- [ ] **Step 4: Update chat route to honor `prefill` query param**

In `lib/router/app_router.dart`, find the `/chat/:userId` route definition. Pass query params through:

```dart
GoRoute(
  path: '/chat/:userId',
  builder: (context, state) => ChatScreenWrapper(
    userId: state.pathParameters['userId']!,
    prefillMessage: state.uri.queryParameters['prefill'],
  ),
  // ... existing transition / pageBuilder if any
),
```

- [ ] **Step 5: Update ChatScreenWrapper (or the chat conversation screen) to consume prefill**

Find the chat conversation entry point (`chat_screen_wrapper.dart` or `chat_conversation_screen.dart`). Add an optional `prefillMessage` constructor param. On first build, set it as the initial value of the input controller:

```dart
class ChatScreenWrapper extends StatelessWidget {
  final String userId;
  final String? prefillMessage;
  const ChatScreenWrapper({super.key, required this.userId, this.prefillMessage});

  @override
  Widget build(BuildContext context) {
    return ChatConversationScreen(
      userId: userId,
      prefillMessage: prefillMessage,
    );
  }
}
```

In `chat_conversation_screen.dart`, in `initState`, if `prefillMessage != null && _inputController.text.isEmpty`:

```dart
@override
void initState() {
  super.initState();
  if (widget.prefillMessage != null && _inputController.text.isEmpty) {
    _inputController.text = widget.prefillMessage!;
  }
  // ... existing init logic
}
```

(Don't overwrite an existing draft.)

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

- [ ] **Step 7: Commit**

```bash
git add lib/
git commit -m "feat(community): C12 — conversation-starter prompts (ribbon + chat prefill)"
```

---

## Task C13 — feat(voice-rooms): local-user speaking indicator

**Files:**
- Modify: `lib/services/webrtc_service.dart` — add local audio level polling
- Modify: `lib/services/voice_room_manager.dart` — consume local audio level

- [ ] **Step 1: Add local audio polling to WebRTCService**

In `lib/services/webrtc_service.dart`:

```dart
final _localAudioLevelController = StreamController<double>.broadcast();
Stream<double> get localAudioLevel => _localAudioLevelController.stream;

Timer? _localPollTimer;

void startLocalAudioLevelPolling() {
  _localPollTimer?.cancel();
  _localPollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
    if (_localStream == null || _peerConnections.isEmpty) return;
    try {
      final pc = _peerConnections.values.first;
      final stats = await pc.getStats();
      for (final report in stats) {
        if (report.type == 'media-source' && report.values['kind'] == 'audio') {
          final level = (report.values['audioLevel'] as num?)?.toDouble() ?? 0;
          if (!_localAudioLevelController.isClosed) {
            _localAudioLevelController.add(level);
          }
          break;
        }
      }
    } catch (_) {}
  });
}

void stopLocalAudioLevelPolling() {
  _localPollTimer?.cancel();
  _localPollTimer = null;
}
```

In existing `dispose`, add `stopLocalAudioLevelPolling()` and `_localAudioLevelController.close()`.

- [ ] **Step 2: Consume in VoiceRoomManager**

In `lib/services/voice_room_manager.dart`:

```dart
StreamSubscription<double>? _localAudioSub;

// In _setupCallbacks (or after initialize):
_localAudioSub = _webrtcService.localAudioLevel.listen((level) {
  final myId = _chatSocketService?.currentUserId;
  if (myId == null) return;
  final i = _participants.indexWhere((p) => p.id == myId);
  if (i == -1) return;
  final p = _participants[i];
  final shouldSpeak = level > 0.05 && !p.isMuted;
  if (p.isSpeaking != shouldSpeak) {
    _participants[i] = p.copyWith(isSpeaking: shouldSpeak);
    onStateChanged?.call();
  }
});

// Start polling on join:
Future<void> joinRoom(VoiceRoom room) async {
  // ... existing join logic ...
  _webrtcService.startAudioLevelPolling();
  _webrtcService.startLocalAudioLevelPolling();  // NEW
}

// Stop in _cleanup:
void _cleanup() {
  _webrtcService.stopAudioLevelPolling();
  _webrtcService.stopLocalAudioLevelPolling();  // NEW
  // ... existing cleanup ...
}

// Cancel sub in dispose:
@override
void dispose() {
  _localAudioSub?.cancel();
  // ... existing
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/services/webrtc_service.dart lib/services/voice_room_manager.dart 2>&1 | tail -10
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/
git commit -m "feat(voice-rooms): C13 — local-user speaking indicator via local audio-level polling"
```

---

## Task C14 — feat(voice-rooms) + backend: voice room categories

**Files (backend):**
- Modify: `controllers/voiceRooms.js` — accept `?category=` filter on list endpoint

**Files (Flutter):**
- Modify: `lib/pages/community/voice_rooms/voice_rooms_tab.dart` — category filter chip row

(Backend schema already added in C3 — `category` field on VoiceRoom model.)

- [ ] **Step 1: Backend — accept `?category=` filter**

In the `getRooms` (or list) handler in `controllers/voiceRooms.js`, near other query parsing:

```js
if (req.query.category) {
  filter.category = req.query.category;
}
```

- [ ] **Step 2: Backend commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/voiceRooms.js
git commit -m "feat(voice-rooms): C14 — ?category= filter on voice rooms list endpoint"
```

- [ ] **Step 3: Flutter — add category filter chip row**

In `voice_rooms_tab.dart`, add state:

```dart
String? _selectedCategory;
```

Add a third chip row above the existing language + topic rows:

```dart
SizedBox(
  height: 44,
  child: ListView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    children: [
      CommunityFilterChip(
        label: 'All',
        isSelected: _selectedCategory == null,
        onTap: () => setState(() {
          _selectedCategory = null;
          _refreshAll();
        }),
      ),
      const SizedBox(width: 8),
      ...['casual', 'language_practice', 'topic', 'qa'].map((cat) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CommunityFilterChip(
          label: switch (cat) {
            'casual' => l10n.categoryCasual,
            'language_practice' => l10n.categoryLanguagePractice,
            'topic' => l10n.categoryTopic,
            'qa' => l10n.categoryQA,
            _ => cat,
          },
          isSelected: _selectedCategory == cat,
          onTap: () => setState(() {
            _selectedCategory = _selectedCategory == cat ? null : cat;
            _refreshAll();
          }),
        ),
      )),
    ],
  ),
),
```

Update `_fetchWithFilters` to pass `category: _selectedCategory` to the provider's `fetchRooms`. Add `category` param to `voice_room_provider.dart`'s `fetchRooms` method:

```dart
Future<List<VoiceRoom>> fetchRooms({
  String? language,
  String? topic,
  String? category,  // NEW
}) async {
  // ... append to query params if not null
}
```

- [ ] **Step 4: Verify Flutter**

```bash
flutter analyze lib/pages/community/voice_rooms/voice_rooms_tab.dart lib/providers/voice_room_provider.dart 2>&1 | tail -10
```

- [ ] **Step 5: Flutter commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/
git commit -m "feat(voice-rooms): C14 — category filter chips on voice_rooms_tab"
```

---

## Task C15 — fix(voice-rooms): reconnect banner → bottom toast UX

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_room_reconnect_banner.dart`
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` — repositioning

- [ ] **Step 1: Update the banner widget to be a bottom-anchored toast**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class VoiceRoomReconnectBanner extends StatelessWidget {
  final bool isReconnecting;
  const VoiceRoomReconnectBanner({super.key, required this.isReconnecting});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: isReconnecting ? Offset.zero : const Offset(0, 1),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isReconnecting ? 1.0 : 0.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.amber,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.voiceRoomReconnecting,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Reposition in voice_room_screen.dart**

In `voice_room_screen.dart`, remove the banner from the top of the body Column (where it was a screen-pushing stripe). Wrap the body in a Stack and put the banner at the bottom:

```dart
body: Stack(
  children: [
    Column(
      children: [
        // existing body content WITHOUT the banner
      ],
    ),
    Positioned(
      left: 0, right: 0, bottom: 0,
      child: Consumer(builder: (_, ref, __) {
        final isRecon = ref.watch(voiceRoomProvider).isReconnecting;
        return VoiceRoomReconnectBanner(isReconnecting: isRecon);
      }),
    ),
  ],
),
```

The `IgnorePointer(ignoring: isReconnecting)` wrap on `VoiceRoomControls` from the original C25 implementation stays — only the banner's visual treatment changes.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/voice_room_reconnect_banner.dart lib/pages/community/voice_rooms/voice_room_screen.dart 2>&1 | tail -10
```

- [ ] **Step 4: Commit**

```bash
git add lib/pages/community/voice_rooms/
git commit -m "fix(voice-rooms): C15 — reconnect banner → bottom toast UX"
```

---

## Task C16 — feat(community) + backend: wave history archive

**Files (backend):**
- Modify: `controllers/community.js` — `getWaves` accepts `?archive=true`

**Files (Flutter):**
- Modify: `lib/services/community_service.dart` (or where `getWavesReceived` lives) — accept `archive` flag
- Create: `lib/pages/community/tabs/waves_archive_screen.dart`
- Modify: `lib/pages/community/tabs/waves_tab.dart` — "View archive" link in AppBar / empty state

- [ ] **Step 1: Backend — extend getWaves**

In `controllers/community.js`'s `getWaves` (line ~276), add archive logic:

```js
const archive = req.query.archive === 'true';
const now = Date.now();
let createdAtFilter;
if (archive) {
  createdAtFilter = {
    $gte: new Date(now - 30 * 24 * 60 * 60 * 1000),  // 30 days
    $lt: new Date(now - 7 * 24 * 60 * 60 * 1000),    // older than 7 days
  };
} else {
  createdAtFilter = {
    $gte: new Date(now - 7 * 24 * 60 * 60 * 1000),  // last 7 days
  };
}
// Add to existing find filter:
const filter = { to: req.user._id, createdAt: createdAtFilter, /* ...other existing... */ };
```

Adapt to whatever the existing filter shape is — read the function before editing.

- [ ] **Step 2: Backend commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/community.js
git commit -m "feat(community): C16 — wave history archive ?archive=true (7-30 days old)"
```

- [ ] **Step 3: Flutter — extend the service method**

In `lib/providers/provider_root/community_provider.dart`, find `getWavesReceived` and add an `archive` flag:

```dart
Future<List<Wave>> getWavesReceived({
  int page = 1,
  int limit = 20,
  bool unreadOnly = false,
  bool archive = false,  // NEW
}) async {
  // ... existing logic, append:
  if (archive) queryParams['archive'] = 'true';
  // ...
}
```

- [ ] **Step 4: Create waves_archive_screen.dart**

Mirror the existing `waves_tab.dart` structure but pass `archive: true` to the fetch:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/pages/community/widgets/community_empty_state.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class WavesArchiveScreen extends ConsumerStatefulWidget {
  const WavesArchiveScreen({super.key});

  @override
  ConsumerState<WavesArchiveScreen> createState() => _WavesArchiveScreenState();
}

class _WavesArchiveScreenState extends ConsumerState<WavesArchiveScreen> {
  List<Wave> _waves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final waves = await ref
          .read(communityServiceProvider)
          .getWavesReceived(archive: true);
      if (mounted) setState(() {
        _waves = waves;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.archivedWaves),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _waves.isEmpty
              ? CommunityEmptyState(
                  icon: Icons.inbox_outlined,
                  title: l10n.noArchivedWaves,
                )
              : ListView.builder(
                  itemCount: _waves.length,
                  itemBuilder: (_, i) {
                    final w = _waves[i];
                    return ListTile(
                      title: Text(w.fromUserName),
                      subtitle: Text(w.message ?? '👋'),
                    );
                  },
                ),
    );
  }
}
```

- [ ] **Step 5: Add "View archive" link to waves_tab.dart**

In `waves_tab.dart`, add an action button to the AppBar (or add a row in the empty state):

```dart
appBar: AppBar(
  // ... existing
  actions: [
    TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WavesArchiveScreen()),
      ),
      child: Text(AppLocalizations.of(context)!.viewArchive),
    ),
  ],
),
```

If `WavesTab` doesn't have its own Scaffold (it's likely embedded in a tab strip), add the link as an inline row at the top of the list instead.

- [ ] **Step 6: Verify Flutter**

```bash
flutter analyze lib/pages/community/tabs/ lib/providers/provider_root/community_provider.dart 2>&1 | tail -10
```

- [ ] **Step 7: Flutter commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/
git commit -m "feat(community): C16 — wave history archive screen + service flag"
```

---

## Task C17 — feat(community) + backend: mutual interests minimum filter

**Files (backend):**
- Modify: `controllers/users.js` — extend `buildUsersQuery` with `?topicsAtLeast=N`

**Files (Flutter):**
- Modify: `lib/pages/community/filter/filter_state.dart` — add `topicsAtLeast: int`
- Modify: `lib/pages/community/filter/filter_toggles_section.dart` — add slider 0-5
- Modify: `lib/pages/community/filter/community_filter_sheet.dart` — wire field through

- [ ] **Step 1: Backend — extend buildUsersQuery**

In `controllers/users.js`'s `buildUsersQuery`, add:

```js
if (req.query.topicsAtLeast) {
  const minOverlap = parseInt(req.query.topicsAtLeast, 10);
  if (minOverlap > 0) {
    const myTopics = req.user.topics || [];
    if (myTopics.length === 0) {
      // No topics on current user → no overlap possible → return empty
      filter._id = { $in: [] };
    } else {
      filter.$expr = {
        $gte: [
          { $size: { $setIntersection: ['$topics', myTopics] } },
          minOverlap,
        ],
      };
    }
  }
}
```

- [ ] **Step 2: Backend commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/users.js
git commit -m "feat(community): C17 — ?topicsAtLeast=N mutual interests minimum filter"
```

- [ ] **Step 3: Flutter — extend FilterState**

In `lib/pages/community/filter/filter_state.dart`, add field:

```dart
final int topicsAtLeast;  // 0 = off
```

Update constructor (default 0), `copyWith`, `toJson`, `fromJson`, `defaults`.

- [ ] **Step 4: Add slider to filter_toggles_section.dart**

```dart
// After the existing toggles in build():
const SizedBox(height: 12),
Row(
  children: [
    Expanded(
      child: Text(AppLocalizations.of(context)!.mutualInterestsMin,
          style: context.bodyMedium),
    ),
    Text(AppLocalizations.of(context)!.atLeastNTopics(filterState.topicsAtLeast)),
  ],
),
Slider(
  value: filterState.topicsAtLeast.toDouble(),
  min: 0, max: 5,
  divisions: 5,
  label: filterState.topicsAtLeast == 0 ? 'Any' : '${filterState.topicsAtLeast}+',
  onChanged: (v) => onChanged(filterState.copyWith(topicsAtLeast: v.round())),
),
```

- [ ] **Step 5: Wire query param through community_filter_sheet.dart's `_buildDraftFiltersMap`**

In `community_filter_sheet.dart`, ensure `_buildDraftFiltersMap` includes:

```dart
if (_topicsAtLeast > 0) 'topicsAtLeast': _topicsAtLeast,
```

And `_applyFilters` includes the same in the output map. Also init from `widget.initialFilters['topicsAtLeast']` and reset to 0 in `_clearAll`.

- [ ] **Step 6: Verify Flutter**

```bash
flutter analyze lib/pages/community/filter/ 2>&1 | tail -10
```

- [ ] **Step 7: Flutter commit**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/
git commit -m "feat(community): C17 — mutual interests minimum filter (slider 0-5)"
```

---

## Task C18 — chore(community): final analyzer + smoke + push + PR

- [ ] **Step 1: Run analyzer scoped to Step 4 areas**

```bash
flutter analyze \
  lib/pages/community/voice_rooms/ \
  lib/pages/community/widgets/ \
  lib/pages/community/main/community_main.dart \
  lib/pages/community/card/community_card_actions.dart \
  lib/pages/community/single/single_community_actions.dart \
  lib/pages/community/tabs/partner_discovery_tab.dart \
  lib/pages/community/tabs/waves_tab.dart \
  lib/pages/community/tabs/waves_archive_screen.dart \
  lib/pages/community/filter/ \
  lib/services/voice_room_manager.dart \
  lib/services/webrtc_service.dart \
  lib/providers/voice_room_provider.dart \
  lib/providers/provider_root/community_provider.dart \
  lib/router/app_router.dart \
  lib/models/community/voice_room_model.dart \
  2>&1 | tail -50
```

Triage: errors must fix; warnings if introduced by Step 4 fix; info-level lints (unused imports introduced by Step 4) → remove.

- [ ] **Step 2: Sweep unused imports**

```bash
flutter analyze lib/ 2>&1 | grep -i "unused_import" | head -10
```

Remove any introduced under Step 4 paths.

- [ ] **Step 3: Verify zero new errors**

```bash
flutter analyze lib/ 2>&1 | grep "error •" | head -10
```

Expected: zero. Fix or revert anything that appears.

- [ ] **Step 4: Optional cleanup commit**

If anything was changed:

```bash
git add lib/
git commit -m "chore(community): C18 — final analyzer cleanup pass"
```

If nothing, skip.

- [ ] **Step 5: Push the Flutter branch**

```bash
git push -u origin refactor/step4-community-wave2 2>&1 | tail -5
```

- [ ] **Step 6: Push backend commits**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status -s
git log --oneline @{u}.. 2>&1 | head -10
git push origin main 2>&1 | tail -5
```

There should be 7 wave-4 backend commits pending: C3 (schema), C4 (RSVP), C5 (scheduler+notifications), C9 (recently-active sort), C11 (mute-all socket), C14 (category filter), C16 (wave archive), C17 (topicsAtLeast). Some may have been combined; push everything.

- [ ] **Step 7: Create PR for the Flutter branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
gh pr create --title "Community wave 2 + voice room polish (Step 4)" --body "$(cat <<'EOF'
## Summary

Step 4 of the post-wave-1 roadmap. Headline + 4 smalls + 5 wave-1 followups bundled.

### Headline — Scheduled voice rooms
- New `status: 'scheduled'` on VoiceRoom + `scheduledFor` / `rsvps` / `remindersSent` fields
- RSVP endpoints (`POST/DELETE /voicerooms/:id/rsvp`)
- New backend cron (`jobs/voiceRoomSchedulerJob.js`) flips scheduled rooms to active at start time and fires 1h/15min reminder pushes
- Flutter: `UpcomingSection` above the live rooms list, `ScheduledRoomCard` with countdown + RSVP toggle, `create_room_sheet.dart` schedule mode + date picker (15-min increments, 30-day max)

### Smalls
- **Recently-active sort** (`?sort=recently_active`) — sort chip on partner_discovery_tab
- **Profile-visitor recall** — horizontal "X visited your profile" card on community_main (uses existing `profile_visitor_provider`)
- **Mute-all** (host control) — new `voiceroom:mute-all` socket event + host menu entry + "Host muted everyone" snackbar
- **Conversation-starter prompts** — small ribbon on community_card + single_community_actions; tap → opens chat with prompt pre-filled via new `?prefill=` query param on `/chat/:userId`

### Wave-1 followups
- **Local-user speaking indicator** — completes wave-1 C22 (which was remote-only)
- **Voice room categories** — new `category` enum field + filter chips + create picker
- **Reconnect banner UX** — top stripe → bottom toast with slide animation, less screen-grabbing
- **Wave history archive** (`?archive=true`) — separate screen for waves 7-30 days old
- **Mutual interests minimum filter** (`?topicsAtLeast=N`) — slider 0-5 on filter sheet

### Backend changes (paired backend repo, on `main`)
- `VoiceRoom.scheduledFor / rsvps / remindersSent / category` + `'scheduled'` status enum
- `voiceRoomSchedulerJob` start cron + 1h/15min reminder cron
- `sendScheduledRoomStarted` / `sendScheduledRoomReminder` notification helpers (gated by `notificationPreferences`)
- `?sort=recently_active`, `?category=`, `?topicsAtLeast=N` query params
- `?archive=true` on `getWaves`
- `voiceroom:mute-all` socket handler

## Test plan

- [ ] Schedule a room 5min in future → RSVP from another account → wait for 15min reminder push (would need to adjust test timing)
- [ ] At scheduled start: room flips to active, push fires to RSVPs + host
- [ ] Mute-all from host menu → all participants see "Host muted everyone" snackbar + their mic mutes
- [ ] Conversation starter ribbon → tap → chat opens with prompt pre-filled
- [ ] Recently-active sort chip → list reorders by `lastSeenAt` desc
- [ ] Visitor recall card renders when `profile_visitor_provider` has data; hidden otherwise
- [ ] Local-user speaking ring lights up when self talks (and self isn't muted)
- [ ] Category filter chips narrow voice room list correctly
- [ ] Reconnect banner slides up from bottom, doesn't push content
- [ ] Wave archive shows waves 7-30 days old
- [ ] Mutual interests min slider at 2 → list narrows to users sharing ≥2 topics

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" 2>&1 | tail -5
```

- [ ] **Step 8: Report**

Output: cleanup-pass commit count (0/1), Flutter branch push result, backend commits pushed count, PR URL, total Flutter commits ahead of main.

---

## Plan complete

**Spec:** `docs/superpowers/specs/2026-05-09-step4-community-wave2-design.md`
**Plan:** this file
**Branch:** `refactor/step4-community-wave2`
**Total: ~18 commits, ~5-6 weeks**

Backend commits (C3, C4, C5, C9, C11, C14, C16, C17) land on `main` of the paired backend repo per project pattern.

---

## Self-review notes (post-write)

**Spec coverage:**
- ✅ Scheduled rooms (C3 schema, C4 RSVP, C5 scheduler, C6 cards, C7 create sheet, C8 tab integration)
- ✅ Recently-active sort (C9)
- ✅ Profile-visitor recall (C10)
- ✅ Mute-all (C11)
- ✅ Conversation-starter prompts (C12)
- ✅ Local-user speaking indicator (C13)
- ✅ Voice room categories (C14 — schema in C3, filter chips in C14)
- ✅ Reconnect banner UX (C15)
- ✅ Wave history archive (C16)
- ✅ Mutual interests minimum filter (C17)
- ✅ ARB keys + 17 locales (C1, C2)
- ✅ Final polish + PR (C18)

**Type consistency:**
- `VoiceRoom.scheduledFor: DateTime?` consistent across model (C6), card (C6), create sheet (C7), backend schema (C3).
- `VoiceRoom.rsvps: [{user, rsvpAt}]` on backend; Flutter exposes as `rsvpUserIds: List<String>` (extracted user IDs only). Consistent across C3 (schema) / C6 (model) / C6 (card consumes).
- `VoiceRoom.category: String?` enum `'casual'|'language_practice'|'topic'|'qa'` consistent across C3 (schema) / C7 (create picker) / C14 (filter chips).
- `voiceroom:mute-all` socket event consistent — server in C11 broadcasts `voiceroom:mute` per participant with `forced: true`; Flutter listens via existing `_muteSub` in `voice_room_manager.dart`.

**Placeholder scan:** no "TBD" / "TODO" / "implement later" placeholders. The `await Future.delayed(...)` pattern is not used anywhere in this plan.

**Cross-PR dependencies:**
- C3 schema must precede C4/C5/C6/C7/C8 (everything that references the new fields).
- C5 (scheduler) must come after C4 (it consumes the RSVP collection).
- C6 (cards) must come after C3 (model fields exist).
- C7 (create sheet) depends on C6 (the model can carry `scheduledFor` + `category`).
- C8 (tab integration) depends on C6 (UpcomingSection) and C7 (create flow).
- C12 (conversation starters) requires the chat route prefill change in `app_router.dart` — both land in the same commit.
- C13 (local audio) is independent of all other commits.
- C14 backend (category filter) depends on C3 (schema field exists); Flutter chip rendering is independent.
- C15 (banner UX) is independent.
- C16 (archive) is independent.
- C17 (topicsAtLeast) depends on Step 2's topics filter UI being shipped (it is — Step 2 C12).
