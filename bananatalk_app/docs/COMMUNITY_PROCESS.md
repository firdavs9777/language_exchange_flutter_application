# Community — How the whole thing works

This document explains the Community tab in plain English. No code, no schemas — just what happens when a user opens the tab, what each feature does, and how the pieces feed each other. Read this if you want to understand the product, not the codebase.

---

## 1. The big picture

Community is bottom-nav tab **#2** (right after AI Study). It's the social-discovery surface — where users find language-exchange partners, send greetings (waves), join live voice conversations, and browse by interest. If AI Study is "me + AI," Community is "me + other humans."

The tab is a **7-sub-tab horizontal scroller** below a sticky app bar. Each sub-tab is a different way to slice the same underlying pool of users — by relevance, by gender, by proximity, by country, by interest, by live voice rooms, by who already greeted you. There's no separate "feed" — every sub-tab is a list (or grid, or map) of *people*.

The core flow is:
- **Browse** users in one of the sub-tabs
- **Tap** a user → full profile
- **Act** — wave (lightweight hello), message (start a chat), or call (voice/video)
- **Join** a live voice room as a passive alternative path

Voice rooms are the synchronous social layer; everything else is async.

---

## 2. The Tab Structure

The Community screen has these elements stacked vertically:

```
┌────────────────────────────────────────────┐
│  App bar: "Community"  [⚡Smart] [🔍] [🎚️] │
├────────────────────────────────────────────┤
│  (Animated search bar — appears on tap)    │
├────────────────────────────────────────────┤
│  Visitor Recall Card                       │
│  "5 people visited your profile" + avatars │
├────────────────────────────────────────────┤
│  Active filter chips (removable)           │
├────────────────────────────────────────────┤
│  Tab bar: All / Gender / Nearby / City /   │
│           Topics / Voice Rooms / Waves     │
├────────────────────────────────────────────┤
│                                            │
│        [active sub-tab body]               │
│                                            │
└────────────────────────────────────────────┘
```

**App bar** has three controls in the top-right:
- **⚡ Smart Match** — opens the dedicated smart-recommendation screen (separate route, not in the sub-tabs)
- **🔍 Search** — toggles an animated search bar; supports `@username` lookup for direct profile navigation
- **🎚️ Filter** — opens the filter bottom sheet (see §8)

**Visitor Recall Card** sits below the app bar, above the tab bar. Shows up to 5 recent visitors with avatars; tap to view that visitor's profile. Hides entirely when there are no visitors. This is the "who came to see me?" loop that drives re-engagement.

**Active filter chips** appear when any filter is set, with a "clear all" option. The chips persist via `SharedPreferences` so the next session opens with the same filters applied.

---

## 3. The Discovery Loop — what makes this work

Three independent loops compound to drive Community engagement. Each is documented in detail below; understand the loop first.

### Loop 1 — Browse → wave → mutual wave → conversation

1. User scrolls Partner Discovery
2. Sees a card they like, taps the wave button
3. Backend records the Wave, mirrors it into the recipient's chat as a sticker, pushes a notification
4. Recipient receives wave → opens chat → message thread begins
5. If recipient ALSO waved back → **mutual wave** is flagged → both get a "you matched!" style notification (warmer than a one-sided wave)

The 24-hour cooldown on the wave button keeps it from being spam — you literally cannot wave the same person twice in a day. The 100-character optional message lets you say more than just 👋 if you have something specific to open with.

### Loop 2 — Profile visit → visitor recall → reciprocal visit

1. User A views User B's profile (auto-recorded via `ProfileVisitorService`)
2. User B opens Community → Visitor Recall Card surfaces "User A visited you"
3. User B taps A's avatar, views A's profile
4. User A's visitor recall card later surfaces B back

Profile views are tier-limited (regular = 100/day, visitor = 20/day, VIP unlimited) which prevents bots from gaming the recall surface.

### Loop 3 — Voice room presence → joining strangers' rooms

1. User opens Voice Rooms tab → sees live rooms with topic/language/host
2. Taps a room → joins via LiveKit token; ends up in a real audio conversation with strangers
3. Conversations expose users to each other organically; users discover partners they'd never have matched on filters alone

Voice rooms are the *only* synchronous discovery surface. Everything else is async. This matters because some users prefer audio-first interaction; the rooms are a meaningful alternative entry point that doesn't require typing.

**The compounding effect:** a user who's active in voice rooms picks up profile visitors (Loop 2) AND gets waved at by people who heard them (Loop 1). One feature feeds the others. That's the social flywheel.

---

## 4. The User Profile — what makes someone discoverable

Every Community surface ultimately filters and ranks `User` records. The fields that matter for discovery:

- **`native_language` + `language_to_learn`** — the core language-exchange axis; required at signup
- **`location`** — GeoJSON Point (lat/lng + indexed for `$geoNear` queries). Optional; powers Nearby + City tabs
- **`topics`** — up to 10 interest tags from a seeded catalog of 99 (food, games, culture, sports, etc.)
- **`birth_year`** — used for age range filtering (not displayed exactly — derived)
- **`gender`** — used for Gender tab + filter
- **`lastActive`** — drives online presence; users seen in the last 5 minutes count as "online"
- **`profileStats`** — view counts (`totalVisits`, `uniqueVisitors`)
- **`privacySettings`** — granular per-field visibility (`showCountryRegion`, `showCity`, `showAge`, `showOnlineStatus`, etc.)
- **`blockedUsers` / `blockedBy`** — bidirectional block lists; both sides exclude each other from discovery
- **`userMode`** — `visitor` / `regular` / `vip`; gates limits + radius

Users with no location can't appear in Nearby or City. Users with no topics can't appear in Topics. Users who set `showOnlineStatus: false` never show the green dot regardless of presence state. The privacy posture is permissive-by-default but flexible.

---

## 5. The 7 Sub-Tabs — what each one does

### 5.1 **All** (Partner Discovery) — the default

The "everyone, ranked by relevance" tab. Two display modes:
- **List view** (default) — vertical scroll of partner cards with ad banner at position 0 (non-VIP)
- **Quick Match view** — full-screen card with swipe gestures; left = skip, right (or tap wave) = wave

Sticky quick-filter chips above the list:
- **Recently Active** — sorts by `lastSeenAt`
- **Online Now** — only users active in the last 5 min
- **Speaks [your learning language]** — appears if user has set a learning language
- **Learning [your native language]** — appears if user has set a native language

Pull-to-refresh resets the session's locally-skipped/locally-waved set so users you skipped come back into rotation.

**Empty states matter here.** Three distinct ones:
- "No Partners Found" — no users match filters at all
- "All Caught Up" — user has skipped everyone; offers "Start Over" or "Change Filters"
- "Filtered/search" — too narrow; offers "Remove All Filters" / "Browse All Users"

### 5.2 **Gender**

Radio-selector at top picks Female / Male (other gender values exist in the schema but aren't surfaced here). User counts shown next to each option. Vertical list below.

Non-VIP users see a "Get VIP" upsell banner and ad banners interleaved with the list. The Gender tab is one of the more aggressive monetization surfaces.

### 5.3 **Nearby**

Grid of avatars sorted by distance from the user's location, computed via MongoDB's `$geoNear` (spherical, in meters). Each card shows the distance ("2.5 km away").

Bottom horizontal selector: 50 km, 100 km, 200 km buttons (the values shown depend on tier — visitor/regular cap at 50 km, VIP can go to 500 km).

**Location permission gating:** requests permission on first open; shows a "Location Denied" state if the user refuses. Without location, the tab is empty and prompts the user to enable it.

### 5.4 **City**

The most visually distinct sub-tab. A `flutter_map` widget with country pins; pin labels show the user count per country. Tap a pin → list of users from that country. Search bar above the map filters countries.

When zoomed out far enough, users are aggregated by country; zooming in reveals city-level grouping. This is the international-discovery surface for users who specifically want to talk to someone in a particular country.

### 5.5 **Topics**

Topic catalog: 99 seeded topics organized by category (food, games, culture, language-learning, hobbies, etc.). Each topic shows an icon + name + user count.

Tap a topic → list of users who have selected that topic in their profile. Compact tile layout with a "Send Hi" button on each (sends a default greeting and opens chat).

Users can edit their own topics via the profile editor; max 10 per user. The topic count per user inflates the discoverable surface — someone with 10 topics appears in 10 different topic lists.

### 5.6 **Voice Rooms**

Live audio rooms powered by LiveKit. Two sections:
- **Live now** — rooms in `active` status with current participant count
- **Upcoming** — scheduled rooms (rooms with `scheduledAt` in the future); user can RSVP

Filters at the top: Language, Topic, Category (`casual` / `language_practice` / `topic` / `qa`).

**Card content:** host name + avatar, participant count (live), language flags, topic tag, category badge.

**Tap a live room** → navigate to the in-room screen (LiveKit audio + participant grid). Joining requires a server-issued token; the backend verifies the user isn't blocked by the host or any participant before issuing.

**Create a room** → bottom-sheet form: title, language, optional secondary language, topic, max participants (2-50; tier-capped), optional scheduled time, category. On create, the user is auto-added as host. Their previous room (if any) gets auto-ended — one room per host at a time.

**Inside the room:**
- Audio is full-duplex via LiveKit
- Participant grid shows speaker indicators
- Text chat panel for non-audio chatter
- Host controls: mute participants, end room, promote co-host
- Raise-hand request flow (if `settings.allowRaiseHand` enabled)

**Lifecycle quirks worth knowing:**
- Rooms have a 30s heartbeat. If a client stops heartbeating, the room is considered stale and excluded from listings.
- If the host leaves, a 30-second grace timer starts. If a co-host or oldest participant doesn't take over within that window, the room ends.
- If the host explicitly taps "end intent" before leaving, the grace timer is skipped and the room ends immediately.
- If every participant leaves, the room ends.
- Rooms have a duration cap: 30 minutes for regular/visitor, unlimited for VIP.

### 5.7 **Waves**

The inbox for received greetings. Vertical list of wave cards:
- **Sender avatar** + name
- **Optional message** (up to 100 chars, if the sender added one)
- **Timestamp** (relative — "5 min ago")
- **Unread tint** — teal background + border highlight; clears when the user views the tab

Unread badge on the tab itself (red dot on the icon) shows the count of unread waves. Auto-clears when the user opens the Waves tab.

**Tap a wave** → opens the sender's profile.

**View Archive button** in the top-right → `WavesArchiveScreen` showing waves older than 7-30 days. Active waves stay in the main view; archive holds the historical record.

---

## 6. The Wave Feature — the lightweight greeting

The "wave" is BananaTalk's specific take on the universal "is this person interesting?" gesture. Variants exist on every dating-adjacent app (Tinder's swipe, Hinge's like, Bumble's hello). Here it's a deliberate one-tap greeting that **also lands as a sticker in the chat** so there's continuity between "I noticed you" and "let's talk."

### Sending

1. User taps the wave button on any user card (Partner Discovery, Nearby, Gender, Topics — wave button is on the card itself)
2. **`SendWaveSheet`** modal opens (bottom sheet); user can:
   - Send the default 👋 wave with no message
   - Type a custom message (max 100 chars)
3. Tap "Send" → haptic feedback, instant UI feedback ("waved!" state on the card)
4. Background:
   - Backend creates a `Wave` record
   - Mirrors it into the recipient's chat conversation as `messageType: 'sticker'` so it shows up in their Chats tab too
   - Fires a socket event (`newMessage` / `messageSent`) so an open chat updates in real time
   - Pushes a notification to the recipient (suppressed if they've received more than 3 waves in the last 6 hours — anti-spam)
5. **Mutual wave detection** — if the recipient previously waved at the sender, both users get the "mutual wave" treatment (warmer notification copy, both flagged)

### The 24-hour cooldown

Client-side: a SharedPreferences timestamp per recipient blocks the wave button for 24h.
Backend: a unique partial Mongo index on `{from, to}` within 24h rejects duplicates server-side. Both layers exist because the client cooldown is the UX guarantee; the backend index is the integrity guarantee.

### Rate limits

- Visitor: 3 waves/day
- Regular: 15 waves/day
- VIP: unlimited

Hit the cap → backend returns a 403 with a "wave limit reached" message. The Flutter side surfaces this as a toast and points to VIP if the user is regular.

### Receiving

Waves arrive via:
- **Push notification** (unless suppressed by the 6h anti-spam window or by `notificationPreferences.wave = false`)
- **Socket event** (real-time update in any open chat)
- **Unread badge** on the Waves tab in Community

The recipient can:
- View their profile → message normally
- Wave back → triggers the mutual flag
- Ignore — the wave sits in the inbox; after some time it moves to archive

### Why this design works

The wave reduces the cost of "should I message this person?" to near zero. No need to craft a hi message; no awkward "saw your profile" opener. It's especially valuable in language exchange where users often hesitate to write a full sentence in a foreign language as their first interaction. A wave is universal; the conversation can start in either language afterward.

---

## 7. Voice Rooms — the synchronous social layer

Voice rooms were originally built on WebRTC and migrated to **LiveKit** in Step 8 (waves B + C of that migration). LiveKit handles the audio plumbing — token issuance, server-side routing, participant management — while our backend handles room lifecycle, eligibility, and lobby state.

### How a room works

**Token issuance:** when a user taps Join, our backend mints a LiveKit JWT scoped to the room. The token encodes the user's identity + role (host / co-host / participant), and the LiveKit server enforces it. Without a valid token, the user can't connect to the audio stream.

**Heartbeat:** every active client beats every 30s to keep the room's `lastHeartbeatAt` fresh. A room without heartbeats for >60s is considered stale and disappears from the lobby — this protects against zombie rooms where the host crashed.

**Host transfer:** the host has lifecycle authority (start, end, promote co-host). If the host disconnects:
1. A 30-second grace timer starts
2. If the host returns within 30s, no transfer
3. If not, the oldest participant (by `joinedAt`) becomes the new host
4. A `voiceroom:host-changed` socket event fans out to everyone in the room
5. If the original host explicitly tapped "end" before leaving, this whole flow is skipped and the room just ends

This avoids the dead-room problem where a host disconnects and nobody knows who's in charge.

**Categories** (`casual` / `language_practice` / `topic` / `qa`) shape the UX:
- **Casual** — open chat; no structure
- **Language practice** — explicit language pairing; users join to practice a specific language
- **Topic** — discussion of a specific topic from the topics catalog
- **Q&A** — host fields questions from participants; raise-hand-only speaking

**Capacity caps:**
- Visitor / regular: 8 participants
- VIP: 50 participants

VIP also unlocks longer rooms (no 30-min cap), recording (`settings.recordingEnabled`), and other co-host privileges.

### Scheduled rooms

Hosts can create a room for a future time (`scheduledAt`). Other users can RSVP (`rsvps[]` array). At T-1h and T-15min before the scheduled time, the backend sends a push notification reminder. When the room actually starts, RSVPs get a "room is live now" notification.

This is the only Community feature with explicit time scheduling.

---

## 8. Filters + Search

### The filter sheet

A bottom-sheet modal that applies across most sub-tabs (Voice Rooms and Waves have their own filter UI). Filter options:

- **Age** — dual-slider, 18-100
- **Gender** — radio (Male / Female / Non-binary)
- **Native Language** — dropdown + toggle "Show users who speak this natively"
- **Learning Language** — dropdown + toggle "Show users learning this"
- **Language Level** — Beginner / Intermediate / Advanced / Fluent
- **Country** — searchable dropdown
- **Online Only** — toggle
- **New Users Only** — toggle (recently joined)
- **Prioritize Nearby** — toggle (sorts results by distance)
- **Topics** — multi-select from the topic catalog

**Persistence:** filters are saved to SharedPreferences. Re-opening the app preserves them. Cleared via the "clear all" button on the active chips above the sub-tab content.

### Search

The search bar at the top of Community is a **direct lookup** tool, not a full-text search. Behaviors:
- Plain text → no action until the user adds `@`
- `@alice` syntax triggers a "Find" button → looks up the exact username, navigates straight to that profile on success
- Pasted `@username` strips the `@` automatically
- Errors surface as a snackbar ("user not found")

This is intentionally narrow — full-text user search across name/bio would be expensive and easy to abuse. Username lookup is precise enough for the "I have someone specific in mind" case.

---

## 9. Failure modes — what happens when things go wrong

| Failure | Surface | Recovery |
|---|---|---|
| **Location permission denied** | Nearby tab shows "Location Denied" state | "Open Settings" CTA opens iOS/Android settings |
| **Network failure on user list fetch** | Sub-tab shows an error state with retry button | Retry re-fires the API call |
| **Wave fails (rate limit / target blocked)** | Toast on the card | User can retry tomorrow or message instead |
| **Voice room: host crashes mid-call** | 30s grace timer → automatic host transfer to oldest participant | Visible via `voiceroom:host-changed` socket event |
| **Voice room: everyone leaves** | Room auto-ends; status flips to `ended` | Listed in user's history, not visible in lobby |
| **Voice room: LiveKit token rejected** | "Could not join room" with retry button | Usually means the token expired or the user was blocked; retry mints a fresh token |
| **Search: `@username` not found** | Snackbar "user not found" | User can correct the spelling and retry |
| **Filter sheet: no matches** | Sub-tab empty state with "Remove filters" / "Browse all" buttons | One-tap clear |
| **Blocked user appears** | Filtered out server-side via `blockedUsers` / `blockedBy` arrays | Block status is bidirectional; both sides see nothing of each other |

**Mid-call disconnections** are the most user-visible failure mode in Community. LiveKit handles audio reconnection automatically; our app shows a "Reconnecting…" banner during the gap. If reconnection fails, the user is dropped from the room and re-shown the lobby. There's no "rejoin where you left off" — they have to tap the room again.

---

## 10. Data privacy — what gets shared in Community

Community is the surface with the most user-visible data exposure in the app. Key things to know:

**Always sent to the backend when discoverable:**
- Profile photos
- Name + bio
- Languages (native + learning)
- Topics
- Age (derived from `birth_year`)
- Gender

**Conditionally shared based on `privacySettings`:**
- City / region (toggle per field)
- Country
- Exact age (vs. derived range)
- Online status
- Last seen timestamp
- Whether the user appears in profile-visited lists

**Real-time:**
- Online status is computed server-side from socket connections + `lastActive` updates
- Voice room participation reveals: which room you're in, your speaker state (muted / speaking), the rest of the room's roster

**Voice room audio:**
- Routed through LiveKit's SFU (Selective Forwarding Unit)
- Not recorded by default; recording requires `settings.recordingEnabled` which is VIP-only
- LiveKit's retention policy for routed-but-not-recorded audio: ephemeral; nothing persists past the room ending

**Location:**
- Stored as GeoJSON Point if the user opted into location sharing
- Not visible to other users as a precise coordinate — only as a distance ("2.5 km away") in Nearby and as a country pin in City
- `privacySettings.showCity` / `showCountryRegion` further restrict what's surfaced

**Blocked-user data:**
- The `blockedUsers` and `blockedBy` arrays are not visible to anyone except the system
- Block is bidirectional and effectively invisible — neither side sees evidence of the other

A more detailed privacy disclosure for the App Store/Play Store privacy nutrition labels should include the location field (Audio Data is already covered for voice rooms).

---

## 11. Block, report, and safety

Community is the highest-risk surface for abuse — strangers talking to strangers in private chat and live audio. Three layers of safety:

### Block

Bidirectional. When User A blocks User B:
- `A.blockedUsers` gets `{userId: B, blockedAt, reason}`
- `B.blockedBy` gets A's userId
- All discovery queries (Nearby, Topics, Partner Discovery) exclude blocked pairs via the `getBlockedUserIds` utility
- Wave attempts in either direction return an error
- Voice room joins are blocked: if A is in a room, B can't join (and vice versa); the backend checks the participant roster on every join

Block is a *soft hide* — the blocked user doesn't get notified. They just stop seeing the blocker anywhere in the app.

### Report

`Report.js` model captures abuse flags. Users can report from:
- The Single Community Screen (user profile) — "Report" button
- Inside a voice room — host can report disruptive participants

Reports are reviewed by admin; severe cases lead to account suspension. The reporter and reported users are NOT notified of each other's existence beyond the original interaction.

### Notification frequency caps

Anti-spam built into the notification service:
- **Wave notifications:** suppressed if the recipient has received >3 waves in the last 6 hours
- **Voice room reminders:** capped at 2 per scheduled room (1h before, 15min before)
- **Re-engagement notifications:** weekly cap (separate from Community-specific events)

Per-user notification preferences exist for granular control (`notificationPreferences.wave`, `.voiceRoomStart`, `.scheduledRoomReminder`).

---

## 12. Cost & rate limits

### Backend rate limits (per user, applied via `aiRateLimiter` and tier-specific middleware)

| Action | Visitor | Regular | VIP |
|---|---|---|---|
| Waves per day | 3 | 15 | unlimited |
| Voice rooms created per day | 3 | 3 | unlimited |
| Voice room duration | 30 min | 30 min | unlimited |
| Max participants per room | 8 | 8 | 50 |
| Nearby radius | 50 km | 50 km | 500 km |
| Profile views per day | 20 | 100 | unlimited |
| Vocabulary list size | 50 words | 500 words | unlimited |

### Server cost per active user per month (approximate)

| Surface | Cost / user / month |
|---|---|
| User discovery queries (Mongo `$geoNear`, topic filters) | ~$0.02 (mostly DB read load) |
| Wave creation + notifications | ~$0.005 |
| Voice rooms (LiveKit minutes — only charged for active rooms) | ~$0.10-0.30 for moderate users, $1+ for heavy room hosts |
| Notifications (FCM + APNs) | free at our volume |
| **Total** | **~$0.20-0.50 / moderate user** |

LiveKit is by far the most expensive piece. Heavy voice-room users (multi-hour sessions, large rooms) can push costs significantly higher. The 30-minute cap for non-VIP exists partly for cost control.

---

## 13. VIP gating in Community

Community is one of the major upgrade-driving surfaces. What VIP unlocks:

- **Unlimited waves** (vs. 15/day regular)
- **Unlimited voice rooms created** (vs. 3/day)
- **Unlimited room duration** (vs. 30 min)
- **50-person rooms** (vs. 8)
- **Room recording** (`settings.recordingEnabled`)
- **500 km nearby radius** (vs. 50 km)
- **Unlimited profile views** (vs. 100/day)
- **Hides ads** in Gender tab and Partner Discovery list
- **VIP badge** on profile + cards (visible to others — social signal)
- **Priority in search results** (`priorityInSearch: true`)
- **Read receipts** in chat (Community-adjacent)
- **"Who viewed my profile"** (sees all visitors vs. just count)

VIP gating is enforced via:
- The `aiRateLimiter` and content-creation daily counters described in §12
- The `checkNearbyAccess` and `checkVoiceRoomAccess` middleware
- The new `checkTutorQuota` work from Step 13A (AI Study only — doesn't apply here)

Community has been on the rate-limited-throttle pattern for a long time; the 13A daily-quota pattern hasn't been ported here yet.

---

## 14. What's NOT in Community (deliberately)

Things a user might expect that aren't there:

- **No public feed** — there's no "what's everyone posting" view. Moments serves that need (separate tab #4).
- **No public threads or wall posts** — users only interact via 1-on-1 (chat) or many-to-many (voice rooms). No persistent group chats outside of voice rooms.
- **No likes / reactions on profiles** — the only "you liked me" signal is the wave, and waves are private (one-to-one). No public like counts.
- **No "interested in" matching algorithm** beyond filter overlap — there's no Tinder-style score-and-stack. Partner Discovery is closer to a "browse" experience than a "match" experience.
- **No video rooms** — audio only. Video would require significant LiveKit + UI work; not on the immediate roadmap.
- **No location obfuscation slider** — location either shares (city + country + distance) or doesn't (per `privacySettings`). No middle ground like "show city but not exact distance."

The deliberate absence of a public feed shapes user expectations: Community is for finding *new* people, not for keeping up with people you already know. The Chats tab is for ongoing conversations; Community is for discovery.

---

## 15. What's coming next (roadmap)

Not promises — the shortlist:

- **Smart Match V2.** The `/matching` route exists but the discovery algorithm is basic (mostly filter-overlap-based). A real ranking model that incorporates wave-back rate, conversation length, and voice-room overlap would dramatically improve match quality.
- **Voice room recording playback.** Recording is enabled for VIP but there's no UI for playing back recorded rooms yet. The data is there; the surface isn't.
- **Group video rooms.** A natural extension of voice rooms — the LiveKit plumbing supports video; the UI doesn't.
- **Real-time presence ticker.** "3 friends are online" / "X people in voice rooms right now" lightweight ambient signal at the top of Community.
- **Voice room search.** Today the Voice Rooms tab is a flat list with filters. As room count grows, a real search box (by title, host name, topic) becomes necessary.
- **In-room reactions** (👏 🎉 🔥) — lightweight engagement signals during live audio without taking the floor.
- **Topic moderation** — currently topics are a fixed seeded catalog. Eventually users may want to propose custom topics, which needs a moderation pipeline.
- **Community quotas** — Step 13A added daily quotas to AI Study. Community could benefit from the same atomic pattern, especially for waves and voice-room creation (currently using the older sync-counter pattern).

---

## 16. Quick reference — what each sub-tab does

| Sub-tab | Surface | Reads | Writes | Tier-gated |
|---|---|---|---|---|
| **All** (Partner Discovery) | Ranked user list | All discovery params | Wave history (per-tap) | Ads / VIP banner shown to non-VIP |
| **Gender** | List by gender | gender filter | Wave history | Ads to non-VIP |
| **Nearby** | Grid by distance | location + radius | Wave history | 50 km cap for non-VIP, 500 km VIP |
| **City** | Map of countries | country aggregation | Wave history | — |
| **Topics** | List per topic | topic match | Wave history; default greeting messages | — |
| **Voice Rooms** | Live + scheduled rooms | room status + filters | RSVPs, room creation | 30-min cap, 8 participants, 3 rooms/day for non-VIP |
| **Waves** | Inbox of received waves | wave list, unread flag | mark-as-read | — |

---

That's the whole picture. Community is a multi-surface discovery layer where each sub-tab is a different way to slice the same underlying user pool, joined by two cross-cutting features (waves + voice rooms) that turn discovery into actual interaction. The product story is: browse → wave → chat, or join a room → meet someone live → wave them later. Both paths converge in the Chats tab.

---

## Doc maintenance

This doc is the source of truth for Community. **Last updated: 2026-05-14.**

When you ship a wave that changes any section, update this doc in the same PR. If you ship a feature that contradicts this doc, **the doc wins — fix the code, not the doc** — unless you've explicitly changed your mind about the product direction, in which case update both.
