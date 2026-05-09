# Step 4 — Community Wave 2 + Voice Room Polish — Design

**Date:** 2026-05-09
**Branch:** `refactor/step4-community-wave2` (off `main`)
**Scope:** `lib/pages/community/voice_rooms/`, `lib/pages/community/main/`, `lib/pages/community/card/`, `lib/pages/community/tabs/`, `lib/pages/community/filter/` + paired backend
**Shape:** Headline feature (scheduled rooms) + 4 smalls + 5 bundled wave-1 followups, mirroring Step 2 cadence

## Goal

Stack the headline feature (scheduled voice rooms with RSVP and reminder pushes) on the existing wave-1 voice-room infrastructure (heartbeat, host transfer, reconnect, presence), plus four high-leverage smalls and five bundled wave-1 followups deferred from earlier rounds.

## Non-goals (explicit)

- **No mesh→SFU migration** — separate deferred round; LiveKit pick already locked in.
- **No smart match-score** — still needs behavioral data.
- **No friend-of-friends graph** — separate design round.
- **No Stories work** — Step 3 shipped; Step 5 covers Moments.
- **No new big features beyond scheduled rooms** — the smalls + followups are bounded.

## Current state diagnostics

**Voice room infrastructure** (already wave-1):
- `models/VoiceRoom.js` has `status: ['waiting', 'active', 'ended']` enum + `lastHeartbeatAt` (Step 1 C24)
- Heartbeat cron in `jobs/voiceRoomCleanupJob.js` (just widened to 30min for legacy clients)
- Host transfer state machine in `socket/voiceRoomHandler.js`
- Reconnect banner in `voice_rooms/voice_room_reconnect_banner.dart`
- Speaking indicator wired remote-only in `voice_room_manager.dart` (C22 deferred local)

**Scheduler infrastructure** (existing):
- `jobs/scheduler.js` is a robust setTimeout-based scheduler with KST helpers (`getKoreaTime`, `getMillisecondsUntil`)
- 14 existing scheduled jobs (inactivity, weekly digest, story archival, token cleanup, etc.)
- New cron added the same way: define `scheduleX` → call from `startScheduler`

**Profile visitor data** (existing):
- `lib/providers/provider_root/profile_visitor_provider.dart` + `lib/services/profile_visitor_service.dart` already implement visitor tracking
- Backend endpoints `auth/users/{id}/visitors`, `auth/users/me/visitor-stats` exist (per `endpoints.dart`)

**Wave model** (Step 1):
- `Wave.js` has `from`, `to`, `message`, `isRead`, `createdAt`
- `getWavesReceived({page, limit, unreadOnly})` exists; archive flag would be a new bool

**Topics filter** (Step 2):
- `FilterState.topics` ships with UI (Step 2 C12)
- `buildUsersQuery` honors `?topics=a,b,c`
- Mutual-interests-minimum is a natural extension

---

## Architecture

### Big — Scheduled rooms

#### Schema additions (`models/VoiceRoom.js`)

```js
status: {
  type: String,
  enum: ['scheduled', 'waiting', 'active', 'ended'],  // 'scheduled' added
  default: 'active',
},
scheduledFor: { type: Date, default: null },  // null = start-now
rsvps: [{
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  rsvpAt: { type: Date, default: Date.now },
}],
remindersSent: { type: [String], default: [] },  // ['1h', '15min']
category: {
  type: String,
  enum: ['casual', 'language_practice', 'topic', 'qa', null],
  default: null,
},
```

Index: `{status: 1, scheduledFor: 1}` (for the start-cron query).

#### Endpoints

| Method | Path | Body / Query | Returns |
|---|---|---|---|
| POST | `/voicerooms/:id/rsvp` | `{}` | `{success, data: {rsvpCount}}` |
| DELETE | `/voicerooms/:id/rsvp` | `{}` | `{success, data: {rsvpCount}}` |
| (existing) GET | `/voicerooms` | + `?status=scheduled\|active\|all` (default `active`) | list |

The `/voicerooms` list endpoint extends to include `status=scheduled` filtering for the upcoming-section query.

#### Cron — `jobs/voiceRoomSchedulerJob.js`

```js
const VoiceRoom = require('../models/VoiceRoom');
const User = require('../models/User');
const { sendScheduledRoomStarted, sendScheduledRoomReminder } = require('../services/notificationService');

const TICK_MS = 60 * 1000;  // every minute

async function _runStarts() {
  const now = new Date();
  const toStart = await VoiceRoom.find({
    status: 'scheduled',
    scheduledFor: { $lte: now },
  }).select('_id host rsvps');

  for (const room of toStart) {
    room.status = 'active';
    room.lastHeartbeatAt = now;  // grace window starts now
    await room.save();
    // Notify all RSVPs + the host
    const recipients = [room.host, ...room.rsvps.map(r => r.user)];
    for (const userId of recipients) {
      sendScheduledRoomStarted(userId, room._id).catch(() => {});
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
  }).select('_id rsvps remindersSent');
  for (const room of due1h) {
    for (const r of room.rsvps) {
      sendScheduledRoomReminder(r.user, room._id, '1h').catch(() => {});
    }
    room.remindersSent.push('1h');
    await room.save();
  }

  // 15min reminders
  const due15 = await VoiceRoom.find({
    status: 'scheduled',
    scheduledFor: { $lte: in15min, $gt: now },
    remindersSent: { $nin: ['15min'] },
  }).select('_id rsvps remindersSent');
  for (const room of due15) {
    for (const r of room.rsvps) {
      sendScheduledRoomReminder(r.user, room._id, '15min').catch(() => {});
    }
    room.remindersSent.push('15min');
    await room.save();
  }
}

function start() {
  setInterval(() => {
    _runStarts().catch(err => console.error('[voiceRoomScheduler/starts]', err));
    _runReminders().catch(err => console.error('[voiceRoomScheduler/reminders]', err));
  }, TICK_MS);
  console.log('[voiceRoomScheduler] job started (every 60s)');
}

module.exports = { start, _runStarts, _runReminders };
```

Wire into `jobs/scheduler.js`:

```js
const voiceRoomSchedulerJob = require('./voiceRoomSchedulerJob');
// In startScheduler():
voiceRoomSchedulerJob.start();
```

#### Push gate

`sendScheduledRoomReminder` and `sendScheduledRoomStarted` both call `shouldNotify(user, 'scheduledRoomReminder')` (existing wave 'voiceRoomStart' for started, 'scheduledRoomReminder' for the time-based reminders). Both prefs default true (Step 2 C6).

#### Flutter

- `voice_rooms/scheduled_room_card.dart` (NEW) — compact row: title, host avatar, language pill, countdown ("in 2h 15m"), RSVP toggle button, RSVP count.
- `voice_rooms/upcoming_section.dart` (NEW) — section header + horizontal `ListView` of `ScheduledRoomCard` widgets above the live rooms list in `voice_rooms_tab.dart`.
- `voice_rooms/create_room_sheet.dart` — gains a `_isScheduled: bool` toggle. When true, surface a `showDatePicker` + `showTimePicker` chain (15-min increment hint via initial time, max 30 days out via `firstDate`/`lastDate`).
- New service method `voiceRoomService.rsvp(roomId)` / `unrsvp(roomId)`.

### Smalls

#### a. Recently-active sort

Backend:
```js
// In buildUsersQuery (controllers/users.js):
if (req.query.sort === 'recently_active') {
  // Use lastSeenAt for sorting; null lastSeenAt sorts last
  return { filter, sort: { lastSeenAt: -1 } };
}
```

(`lastSeenAt` index already exists from Step 1 C17.)

The query helper currently returns just `filter` (an object); extend to `{filter, sort}` if cleaner, OR pass sort separately as a second return value. Match existing style — read `buildUsersQuery` first.

Flutter: `partner_discovery_tab.dart` gains a sort chip ("Recently active") that adds `?sort=recently_active` to the user-list query.

#### b. Profile-visitor recall

Frontend-only. New `lib/pages/community/widgets/visitor_recall_card.dart`:

```dart
class VisitorRecallCard extends ConsumerWidget {
  // Watches profile_visitor_provider for recent visitors (last N=5)
  // Renders horizontal scroller of avatars with "X people visited your profile" header
  // Tap any avatar → navigate to single_community
}
```

Insert into `community_main.dart` between the search bar and tab strip. Hide if `visitors.isEmpty`.

#### c. Mute-all (host control)

Backend socket event `voiceroom:mute-all` — when host emits, server broadcasts `voiceroom:mute {userId: <each participant>, isMuted: true}` to all participants:

```js
socket.on('voiceroom:mute-all', async ({ roomId }) => {
  const userId = socket.user?.id;
  const room = await VoiceRoom.findById(roomId);
  if (!room || String(room.host) !== String(userId)) return;
  // Emit a synthetic mute event for every participant
  const participants = await VoiceRoom.findById(roomId).populate('participants.user');
  for (const p of participants.participants) {
    io.to(`voiceroom_${roomId}`).emit('voiceroom:mute', {
      userId: String(p.user._id || p.user),
      isMuted: true,
      forced: true,  // hint for client to show "Host muted everyone" snackbar
    });
  }
});
```

Flutter: add "Mute all" entry to `voice_room_host_menu.dart`. The existing `onVoiceRoomMute` socket listener already handles per-participant mute updates; add a check on `data['forced'] == true` to show "Host muted everyone" snackbar to non-host participants.

#### d. Conversation-starter prompts

Pure frontend. New `lib/pages/community/widgets/conversation_starter_ribbon.dart`:

```dart
class ConversationStarterRibbon extends StatelessWidget {
  final Community community;
  // Picks one prompt at random from a list of ~5 templates:
  //   "Ask about their last moment"
  //   "Say hi in their native language"
  //   "What are they curious about?"
  //   "Hi from {country}!"  (if country available)
  //   "Help them practice {language}!"
  // Renders as a small chip on the card / actions row
  // Tap → navigates to chat with the prompt pre-filled in the input
}
```

Embed in `community_card_actions.dart` (compact form) and `single_community_actions.dart` (full form). Pre-fill via existing chat route's optional `initialMessage` param (verify or add).

### Bundled wave-1 followups

#### e. Local-user speaking indicator

C22 wired remote peers via `RTCPeerConnection.getStats()`. Local user can use Web Audio API to analyze the local mic stream. `flutter_webrtc` exposes the local audio track via `_localStream.getAudioTracks()`.

Add to `webrtc_service.dart`:

```dart
Stream<double> get localAudioLevel => _localAudioLevelController.stream;
final _localAudioLevelController = StreamController<double>.broadcast();

Timer? _localPollTimer;

void startLocalAudioLevelPolling() {
  _localPollTimer?.cancel();
  _localPollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
    if (_localStream == null) return;
    try {
      // Use any peer connection's getStats() — local audio appears as 'media-source' or 'outbound-rtp'
      final pc = _peerConnections.values.firstOrNull;
      if (pc == null) return;
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
```

`VoiceRoomManager` consumes `localAudioLevel` and updates the local `RoomParticipant.isSpeaking` (via `currentUserId` lookup), suppressed when local mute is on.

#### f. Voice room categories

Backend `models/VoiceRoom.js` adds `category` enum field (in the schema additions above). `controllers/voiceRooms.js` list endpoint accepts `?category=casual|language_practice|topic|qa`.

Flutter: `voice_rooms_tab.dart` adds a second filter row above languages with category chips. `create_room_sheet.dart` adds a category dropdown.

#### g. Reconnect banner UX

Currently `voice_room_reconnect_banner.dart` renders at the top as a full-width yellow stripe. Convert to a bottom-anchored toast that:
- Slides up from below
- Smaller height (~32px)
- Auto-dismisses 1s after reconnect
- Doesn't push content (uses `Positioned` over the existing layout, not in the Column)

#### h. Wave history archive

Backend: extend `getWavesReceived(req)` to honor `?archive=true`:
- Default (no flag): waves where `createdAt` within last 7d (already-current behavior, possibly needs verification)
- Archive: waves where `createdAt < now-7d AND createdAt > now-30d`

Flutter: WavesTab gains a "View archive" link in the AppBar (or empty-state section). Opens `lib/pages/community/tabs/waves_archive_screen.dart` (NEW) — same list shape as WavesTab but pulls from archive endpoint.

#### i. Mutual interests minimum filter

Backend: extend `buildUsersQuery` with `?topicsAtLeast=N` query param. When N ≥ 1, only users with `topics` overlapping current user's topics by ≥ N elements are returned.

```js
if (req.query.topicsAtLeast && parseInt(req.query.topicsAtLeast, 10) > 0) {
  const myTopics = req.user.topics || [];
  if (myTopics.length === 0) return { filter, sort };  // skip — no overlap possible
  const minOverlap = parseInt(req.query.topicsAtLeast, 10);
  // Use $expr + $size + $setIntersection
  filter.$expr = {
    $gte: [
      { $size: { $setIntersection: ['$topics', myTopics] } },
      minOverlap,
    ],
  };
}
```

Flutter: `filter_toggles_section.dart` adds a slider "Mutual interests min" 0-5 (default 0 = off). Wires into `FilterState`.

---

## Cross-cutting

### l10n plan

~30 new ARB keys (English first, then 17-locale translation):

| Group | Keys |
|---|---|
| Scheduled rooms | `scheduleForLater`, `pickDate`, `pickTime`, `upcomingRooms`, `inHours`, `inMinutes`, `startsNow`, `iWillBeThere`, `cantMakeIt`, `rsvpCount`, `roomStartsIn1h`, `roomStartsIn15min`, `roomStarted`, `cancelRoom` |
| Mute all | `muteAll`, `mutedByHost`, `muteAllConfirm` |
| Categories | `categoryCasual`, `categoryLanguagePractice`, `categoryTopic`, `categoryQA`, `pickCategory` |
| Recently active | `sortRecentlyActive` |
| Visitor recall | `visitedYourProfile`, `noRecentVisitors` |
| Wave archive | `viewArchive`, `archivedWaves`, `noArchivedWaves` |
| Mutual interests filter | `mutualInterestsMin`, `atLeastNTopics` |
| Conversation starters | `starterAskMoment`, `starterSayHi`, `starterCurious`, `starterFromCountry`, `starterPracticeLang` |

Cadence: en commit (C1) → 17-locale translation commit (C2).

### Testing

- `flutter analyze` clean per commit.
- Backend unit tests for: scheduler `_runStarts` (room with `scheduledFor` past hits → flips), `_runReminders` (1h + 15min thresholds + idempotency via `remindersSent`), RSVP add/remove, mute-all (only host can call), `?topicsAtLeast=N` aggregation, `?archive=true` time window.
- Manual smoke: create scheduled room → RSVP → wait for reminder push → wait for start push → join → mute-all → verify all participants muted with snackbar.

### Risk register

| Risk | Mitigation |
|---|---|
| Scheduler cron fires reminders multiple times if `remindersSent` write loses race | Use atomic `findOneAndUpdate({_id, remindersSent: {$nin: ['1h']}}, {$push: {remindersSent: '1h'}})` instead of fetch-then-save |
| Old clients see new `status: 'scheduled'` rooms in their feed and treat them as `active` | List endpoint defaults to `?status=active` — old clients calling without the param get only active rooms. New clients pass `?status=all` or `?status=scheduled` explicitly |
| `?topicsAtLeast=N` `$expr` performs poorly without index | Stage 1: ship without index, monitor query time; if slow, add a denormalized `topicsCount` field on the user join condition. Defer optimization unless a real perf complaint surfaces |
| Mute-all bypasses individual users' "I just unmuted myself" intent | Acceptable — host-initiated mute is authoritative. Snackbar makes it visible. Users can unmute themselves immediately after if they want |
| Conversation starter pre-filled message conflicts with existing draft | If chat route's `initialMessage` would overwrite a user's typed draft, fall back to inserting the prompt at cursor instead of replacing (Flutter-side decision; verify chat route's contract) |
| Reconnect banner UX change loses the "controls disabled" affordance | Keep the `IgnorePointer(ignoring: isReconnecting)` wrap on `VoiceRoomControls` — only the visual treatment changes, not the disable behavior |
| Local-user speaking indicator over-fires when local user just listens | Same threshold as remote (0.05 RMS); suppressed when local mute is on |

---

## PR / commit breakdown

| # | Commit | Type |
|---|---|---|
| C0 | `chore(community)`: branch + deps audit | chore |
| C1 | `refactor(community)`: ARB keys (en) — ~30 keys | refactor |
| C2 | `refactor(community)`: translate to 17 locales | refactor |
| C3 | `feat(voice-rooms)` + backend: VoiceRoom schema additions (scheduledFor, rsvps, category, remindersSent, status:'scheduled') | feat + backend |
| C4 | `feat(voice-rooms)` + backend: RSVP routes + controller | feat + backend |
| C5 | `feat(voice-rooms)` + backend: voiceRoomSchedulerJob (start + reminders) | feat + backend |
| C6 | `feat(voice-rooms)`: scheduled_room_card + upcoming_section (Flutter) | feat |
| C7 | `feat(voice-rooms)`: create_room_sheet schedule mode + date picker | feat |
| C8 | `feat(voice-rooms)`: voice_rooms_tab integration + RSVP wiring | feat |
| C9 | `feat(community)` + backend: recently-active sort | feat + backend |
| C10 | `feat(community)`: profile-visitor recall card on community_main | feat |
| C11 | `feat(voice-rooms)` + backend: mute-all (socket + host menu + snackbar) | feat + backend |
| C12 | `feat(community)`: conversation-starter prompts (card + actions) | feat |
| C13 | `feat(voice-rooms)`: local-user speaking indicator | feat |
| C14 | `feat(voice-rooms)` + backend: voice room categories (enum + filter chips + create picker) | feat + backend |
| C15 | `fix(voice-rooms)`: reconnect banner → bottom toast UX | fix |
| C16 | `feat(community)` + backend: wave history archive | feat + backend |
| C17 | `feat(community)` + backend: mutual interests minimum filter | feat + backend |
| C18 | `chore(community)`: final analyzer + smoke + push + PR | chore |

**Total: 18 commits, ~5-6 weeks.** Backend commits land on `main` of the paired backend repo per project pattern.

---

## Future / deferred

- Mesh→SFU migration (separate dedicated round)
- Smart match-score (still needs behavioral data)
- Friend-of-friends graph (separate design)
- Custom voice room emoji/sticker reactions
- Voice room recording / playback
- Schedule a recurring voice room (weekly cadence)
- "Co-host" role with elevated permissions but not full host (model already has `cohost` role per `enum: ['host', 'cohost', 'speaker', 'listener']` — not yet wired)
