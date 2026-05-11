# Step 8 — LiveKit Migration: What Shipped

**Date completed:** 2026-05-11
**Branches merged to `main`:** `feat/step8-livekit-migration` (Wave A) + `feat/step8-wave-bc` (Waves B + C)
**Total commits across both repos:** 19 (Flutter 13, Backend 6)
**Result:** Voice rooms + 1:1 voice/video calls migrated off mesh WebRTC onto LiveKit Cloud's SFU.

---

## The headache this fixed

Before this wave, voice rooms and 1:1 calls used **mesh WebRTC over socket.io signaling**. Symptoms:
- Voice rooms with 4+ participants joined slowly (5–10s) and connections were `O(n²)`
- ICE-candidate exchange sometimes silently failed behind certain NATs
- Audio cut in/out under bandwidth pressure (no congestion control)
- Reconnection after a mobile-network swap required a full rejoin (no SFU state)

After this wave: a single LiveKit Cloud SFU carries all media. Joining is sub-second, the SFU handles congestion control automatically, and clients reconnect transparently across network switches.

---

## What was delivered

### Bootstrap (already on main before this wave)
- `livekit-server-sdk` on backend, `livekit_client ^2.7.0` on Flutter
- `services/livekitService.js` exporting `mintRoomToken({ identity, name, roomName, metadata?, ttlSeconds? })`
- `lib/services/livekit_service.dart` — thin Room wrapper
- `POST /api/v1/livekit/test-token` + `LiveKitTestScreen` (debug-only entry in profile drawer)
- `flutter_webrtc` bumped 1.2 → 1.4, `connectivity_plus` 6 → 7, `device_info_plus` 10 → 12 to satisfy LiveKit constraints (verified no call-site breakage)

### Wave A — Voice Rooms migration (6 tasks)
| Task | Repo | Commit | What |
|------|------|--------|------|
| A1 | Backend | `b7836ad` | `POST /api/v1/voicerooms/:id/token` — re-uses joinVoiceRoom access checks, encodes role in metadata |
| A2 | Flutter | `1935774` | `VoiceRoomLiveKitManager` transport layer (182 lines) |
| A3 | Flutter | `07401d8` | `voice_room_manager.dart` delegates transport to LiveKit; mesh offer/answer/ICE signaling removed |
| A4 | Flutter | `805567c` | voice_room_screen lifecycle observer + dead audio-level polling removed (-13 LOC) |
| A5 | Flutter | `9ebaf6d` | Speaking indicator: Material 3 teal ring + glow, 150ms `AnimatedContainer` fade, zero layout shift |
| A6 | Backend | `0c59229` | `voiceroom:rtc_offer/rtc_answer/ice_candidate` handlers removed; deprecation-log stubs (-125 LOC) |

### Wave B — 1:1 voice/video calls migration (6 tasks)
| Task | Repo | Commit | What |
|------|------|--------|------|
| B1 | Backend | `3b00144` | Call lifecycle endpoints: `/initiate`, `/:id/accept`, `/:id/decline`, `/:id/end` + FCM data push carrying receiver's LiveKit token + `notificationPreferences.calls` flag |
| B2 | Flutter | `e19af79` | `CallLiveKitManager` transport layer (221 lines) for n=2 audio/video calls |
| B3 | Flutter | `3c1f84c` | `call_manager.dart` delegates transport to LiveKit; mesh PeerConnection/SDP code removed |
| B4 | Flutter | `ce3e9b7` | `active_call_screen` swapped to `VideoTrackRenderer`; connection-quality badge top-right; reconnect banner with 15s auto-end |
| B5 | Flutter | `fba83c7` | `incoming_call_screen` accepts via FCM-delivered token; CallKit `extra` map carries the token across native ring → app resume |
| B6 | Backend | `5659ff0` | `call:offer/answer-sdp/ice-candidate` handlers removed; deprecation-log stubs |

### Wave C — Polish + cleanup (4 tasks, C5 deferred)
| Task | Repo | Commit | What |
|------|------|--------|------|
| C1 | Flutter | `1b28c3f` | In-room emoji reactions via LiveKit data channels (👏 ❤️ 🎉 🔥 😂 👍); `ReactionPicker` bottom sheet + `FloatingReaction` animated overlay anchored at sender avatars |
| C2 | Flutter | `6fb59d1` | iOS audio session defaults per call type (voice → earpiece, video/voice-rooms → speaker); `voip` background mode added |
| C3 (Flutter) | Flutter | `f7ee16b` | `lib/services/webrtc_service.dart` deleted (-707 LOC); stub fields cleaned from both managers; `flutter_webrtc` removed from pubspec (still transitive via LiveKit) |
| C3 (Backend) | Backend | `b57c7f5` | `/calls/ice-servers` returns 410 Gone with clear deprecation message |
| C4 | Backend | `d2900cb` | `POST /api/v1/livekit/webhook` with signed-JWT verification (`WebhookReceiver`); reconciles Mongo state on `room_finished` + `participant_left` |
| C5 | — | (deferred) | Telemetry pipeline doesn't exist yet; punted to a future step rather than build it from scratch in this wave |

---

## How the new architecture works

**Token flow (no media on our backend):**
```
Flutter ──► POST /voicerooms/:id/token  (our JWT auth)
            ◄── { token, url: wss://....livekit.cloud, roomName, role }
Flutter ──► Room().connect(url, token)   (direct to LiveKit Cloud)
```

**1:1 call flow:**
```
Caller  ──► POST /calls/initiate { receiverId, type }
            ◄── { call, token, url, roomName }  
                + FCM data push to receiver with receiverToken
Caller  ──► LiveKit Cloud.connect(...)
Receiver ──► (FCM payload triggers CallKit ring)
         ──► tap accept → POST /calls/:id/accept
            ◄── { token, url }  // fresh, in case FCM token expired
Receiver ──► LiveKit Cloud.connect(...)
Both    ──► media flows P2P-style through LiveKit's SFU
            (sub-200ms latency, automatic congestion control)
On end  ──► POST /calls/:id/end → Call.status='ended', duration computed
            Socket call:ended fanout to both peers
```

**Crash recovery:** LiveKit Cloud emits `participant_left` / `room_finished` webhooks to our backend; `verifyLivekitWebhook` middleware verifies the signed JWT; controller pulls the participant from `VoiceRoom.participants` array and auto-ends rooms that empty out. Calls get marked ended on `room_finished`.

---

## What's deliberately not in this wave

- **C5 — Telemetry events** (call_initiated / call_connected / call_quality_drop / room_joined / room_reaction_sent). Skipped because we'd need to set up a fresh analytics pipeline (Firebase Analytics or custom backend events). That's a separate step worth scoping properly.
- **Group video calls** (3+ participants). Voice rooms already handle group audio at scale; group video can come later when there's a user need.
- **Recording / transcription**. LiveKit supports both; future wave.
- **Self-hosted LiveKit**. We're on LiveKit Cloud (free tier covers early users). The exact same server code can run self-hosted later with zero changes if costs grow.

---

## What's required from you (manual, post-merge)

1. **Register the webhook URL** in the LiveKit Cloud dashboard:
   ```
   https://api.banatalk.com/api/v1/livekit/webhook
   ```
   (under Settings → Webhooks in the project).

2. **Manual smoke test** when you have two devices:
   - Profile drawer → Support → "LiveKit smoke test" → Connect on both → confirm participants see each other
   - Then in voice rooms tab → create a room → join from second device → verify audio + speaking indicators
   - Then make a 1:1 voice call between the two test accounts; same with video
   - For 1:1 calls: pull wifi mid-call on one device → reconnect banner should appear → audio resumes when wifi returns (within 15s) or call ends with "Connection lost"

3. **iOS audio matrix** (re-test on physical device):
   - Voice call defaults to earpiece, tap speaker button to switch
   - Video call defaults to speaker
   - Bluetooth headset / AirPods route correctly when connected
   - Background → foreground during a call: audio session restores

4. **iOS App Store note:** `UIBackgroundModes` now includes `voip`. App Review may scrutinize this — pair it with the existing `flutter_callkit_incoming` CallKit/PushKit integration in submission notes.

---

## Numbers

- **Total Flutter LOC change:** +1,699 / −1,464 (net +235 across two merges)
- **Total Backend LOC change:** +551 / −199 (net +352 across two merges)
- **Files deleted:** `lib/services/webrtc_service.dart` (-707 LOC)
- **Mesh signaling removed:** 6 socket handlers (3 voicerooms + 3 calls) + ~250 LOC of peer-connection management
- **LiveKit Cloud free tier headroom:** 5,000 participant-minutes/month — comfortable for early users; $50/mo flat Build plan when we outgrow it

---

## Files for future reference

**Spec + plan (committed):**
- `docs/superpowers/specs/2026-05-11-step8-livekit-migration-design.md`
- `docs/superpowers/plans/2026-05-11-step8-livekit-migration.md`

**Bootstrap commits (pre-wave):**
- Backend `011f242`, Flutter `57fcb0f`, spec `77408c8`, plan `7439685`

**Merge commits:**
- Wave A Flutter `9448839` (merged 2026-05-11)
- Wave A Backend `6656b1a` + merge `d3dd7fa`
- Wave B+C Flutter + Backend — merges from this session
