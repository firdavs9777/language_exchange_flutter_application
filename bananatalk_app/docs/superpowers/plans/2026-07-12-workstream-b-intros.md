# Workstream B: Wave → Intro Requests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make waves visible and actionable — intro strip in the chat list, push taps land in the conversation, wave parsing fixed — so the 1.1% wave read rate becomes a real conversation funnel.

**Architecture (revised from spec after code scout):** The backend already mirrors every wave into chat as a sticker Message with socket delivery, and already pushes via `notificationService.sendWave` (with >3-per-6h suppression). No new accept endpoint is needed — the conversation already exists when the wave lands. The gaps are all last-mile: (1) app `Wave.fromJson` mismatches the backend's populated `from` object, (2) push tap routes to profile instead of chat, (3) nothing surfaces unread waves where users look (chat list), (4) blank wave composer. Backend work is a caps entry + template data fix only. Kill switch deviation from spec: `WAVE_INTRO_V2_ENABLED` is unnecessary — no new backend behavior ships; the strip is pure client UI over existing endpoints.

**Tech Stack:** Node/Express + Mongoose (tiny), Flutter + Riverpod. Repos on branch `workstream-b-intros` (app base 0b8e8f8, backend base 911306a).

## Global Constraints

- `package:` imports only in Dart
- Design tokens: teal #00BFA5, banana #FFD54F; dark-mode parity on all new UI
- Backend response shapes stay additive — old app versions must keep working
- Notification type strings: service sends `'wave'`, template data carries `type: 'wave_received'` — the app router must handle BOTH
- Tests: `flutter analyze` 0 errors/warnings; new pure logic gets `flutter test` coverage; backend `node --check`
- Do not start the backend server locally (config.env → production Mongo)
- Commits allowed per task (user re-enabled committing); trailer: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

---

### Task 1: Backend — wave notification caps + deep-link data

**Files:**
- Modify: `config/notificationCaps.js` (add `wave: 5` to `daily`)
- Modify: `utils/notificationTemplates.js:207-222` (`getWaveTemplate`)

**Interfaces:**
- Produces: template `data` gains `senderName` and keeps `userId` (waver id); `route` changes to `/chat/{userId}`; `screen: 'chat'`. Type strings unchanged (`'wave_received'` in data, `'wave'` at send site) for old-app compatibility.

- [ ] **Step 1:** Add `wave: 5,` to the `daily` object in `config/notificationCaps.js`.
- [ ] **Step 2:** In `getWaveTemplate`, change the `data` block to:

```javascript
    data: {
      type: 'wave_received',
      userId: waveData.userId || '',
      waveId: waveData.waveId || '',
      senderName: waverName || '',
      isMutual: isMutual ? 'true' : 'false',
      screen: 'chat',
      route: `/chat/${waveData.userId || ''}`
    }
```

- [ ] **Step 3:** Verify: `node --check config/notificationCaps.js utils/notificationTemplates.js` → both OK; `node -e` assert `getWaveTemplate('Kim', false, {userId:'u1',waveId:'w1'}).data.route === '/chat/u1'`.
- [ ] **Step 4:** Commit `feat(waves): notification cap + chat deep-link in wave template`.

### Task 2: App — fix Wave parsing + pending-intros provider

**Files:**
- Modify: `lib/providers/provider_root/community_provider.dart` (`Wave.fromJson` ~line 632; `getWavesReceived` ~312)
- Test: `test/community/wave_model_test.dart` (new)

**Interfaces:**
- Produces: `Wave.fromJson` handles the REAL backend shape — `{waveId, from: {_id, name, images[]}, message, createdAt, isRead}` — AND the legacy flat shape as fallback. New provider `pendingIntrosProvider` = FutureProvider yielding unread waves (`getWavesReceived(unreadOnly: true)`), consumed by Task 4's strip and Task 5's badge.

- [ ] **Step 1 (TDD):** Write failing test: `Wave.fromJson` on a backend-shaped fixture `{"waveId":"w1","from":{"_id":"u1","name":"Kim","images":["http://x/a.jpg"]},"message":"hi","isRead":false,"createdAt":"2026-07-12T00:00:00Z"}` → id 'w1', fromUserId 'u1', fromUserName 'Kim', fromUserImage set; plus legacy flat fixture still parses. Run → FAIL.
- [ ] **Step 2:** Fix `Wave.fromJson`:

```dart
  factory Wave.fromJson(Map<String, dynamic> json) {
    final from = json['from'];
    final fromMap = from is Map<String, dynamic> ? from : null;
    final images = fromMap?['images'];
    return Wave(
      id: json['waveId'] ?? json['_id'] ?? json['id'] ?? '',
      fromUserId: fromMap?['_id'] ?? json['fromUserId'] ?? '',
      fromUserName: fromMap?['name'] ?? json['fromUserName'] ?? '',
      fromUserImage: (images is List && images.isNotEmpty)
          ? images.first as String?
          : json['fromUserImage'] as String?,
      message: json['message'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
```

- [ ] **Step 3:** Add `pendingIntrosProvider` near the existing waves providers: `final pendingIntrosProvider = FutureProvider<List<Wave>>((ref) => ref.read(communityServiceProvider).getWavesReceived(unreadOnly: true, limit: 20));`
- [ ] **Step 4:** Run tests → PASS; `flutter analyze` clean on touched paths.
- [ ] **Step 5:** Commit `fix(waves): parse populated from object; add pendingIntrosProvider`.

### Task 3: App — push tap lands in the conversation

**Files:**
- Modify: `lib/services/notification_router.dart:77-81`

- [ ] **Step 1:** Replace the `'wave'` case and cover both type strings:

```dart
      case 'wave':
      case 'wave_received':
        final waverId = data['userId']?.toString();
        if (waverId != null && waverId.isNotEmpty) targetPath = '/chat/$waverId';
        break;
```

- [ ] **Step 2:** `flutter analyze lib/services/notification_router.dart` clean.
- [ ] **Step 3:** Commit `fix(waves): wave push tap opens the conversation, not the profile`.

### Task 4: App — intro strip in chat list

**Files:**
- Create: `lib/pages/chat/list/intro_requests_strip.dart`
- Modify: `lib/pages/chat/list/chat_list_screen.dart` (insert strip between filter tabs ~line 1443 and the partner list ~line 1451)

**Interfaces:**
- Consumes: `pendingIntrosProvider` (Task 2), `markWavesAsRead(waveIds:)`, ChatScreen route `/chat/:userId`.
- Produces: `IntroRequestsStrip` — renders nothing when no pending intros (zero-height); horizontal scroll of intro cards.

- [ ] **Step 1:** Build `IntroRequestsStrip` (ConsumerWidget): watches `pendingIntrosProvider`; empty/loading/error → `SizedBox.shrink()`. Otherwise: section header row ("Intro requests" + count chip in banana #FFD54F) and a horizontal `ListView` of cards (~200x88): avatar with teal ring, name, one-line wave message preview (fallback '👋'), timestamp. Tap card → `markWavesAsRead(waveIds: [wave.id])`, invalidate `pendingIntrosProvider` + `wavesUnreadProvider`, then `context.push('/chat/${wave.fromUserId}')`. A small ✕ on each card dismisses quietly (same mark-read, no navigation — decline stays silent per spec). Dark-mode: surfaces from `Theme.of(context).colorScheme`.
- [ ] **Step 2:** Insert into `chat_list_screen.dart` between `ChatListFilterTabs` and `Expanded(child: _buildUsersList())` — plain child in the existing Column, no layout constraints on the list.
- [ ] **Step 3:** Widget test `test/chat/intro_requests_strip_test.dart`: with a provider override supplying 2 fake waves → renders 2 cards + count chip; with empty list → `SizedBox.shrink` (findsNothing for header). Run → PASS.
- [ ] **Step 4:** `flutter analyze` clean; commit `feat(intros): pending intro strip in chat list`.

### Task 5: App — Chats tab badge includes pending intros

**Files:**
- Modify: wherever the Chats tab badge count is computed (chat_list_screen.dart ~1295-1340 reads `badgeCountProvider.notifications`; the tab-level badge lives in the tabs shell — locate `wavesUnreadProvider` consumers and the bottom-nav badge source)

- [ ] **Step 1:** Locate the bottom-nav Chats badge source (grep `badgeCountProvider|unreadMessages` in the tabs shell). Add pending intros: badge = chat unread total + `wavesUnreadProvider` count. If the shell already shows a separate community badge fed by `wavesUnreadProvider`, MOVE it to Chats rather than double-counting — report which pattern was found.
- [ ] **Step 2:** `flutter analyze` clean; manual note for smoke: receiving a wave bumps the Chats tab badge; opening the strip clears it.
- [ ] **Step 3:** Commit `feat(intros): chats tab badge counts pending intros`.

### Task 6: App — icebreaker prompts in the wave composer

**Files:**
- Modify: `lib/pages/community/widgets/send_wave_sheet.dart`

- [ ] **Step 1:** Above the message field add a horizontal chip row of 5 localized icebreakers (use existing l10n keys if any match; otherwise a static const list with `// TODO: l10n batch` marker, consistent with the known backlog): e.g. "What made you start learning {language}?", "Hi! I can help you practice {native} 😊", "What's your favorite word in {language}?", "Coffee-break chat sometime?", "How's your week going?". Tapping a chip fills the message field (editable). Substitute languages from the target-user info already passed to the sheet if available; otherwise use the generic variants.
- [ ] **Step 2:** `flutter analyze` clean; commit `feat(intros): icebreaker chips in wave composer`.

### Task 7: Gate — combined verification + final review

- [ ] **Step 1:** `flutter analyze` (full) → 0 errors/warnings; `flutter test` (auth + community + chat + services dirs) → all pass.
- [ ] **Step 2:** Backend `node --check` on touched files.
- [ ] **Step 3:** Whole-branch review (both repos' diffs) — focus: old-app compatibility of template change, strip performance in the chat-list build path, provider invalidation loops.
- [ ] **Step 4:** Device smoke: wave from device A → push on device B tap lands in conversation; strip shows intro; tap opens chat + clears badge; ✕ dismisses; mutual wave dialog still fires; icebreaker chip prefills.
- [ ] **Step 5:** Merge to main on user go-ahead; re-measure wave read rate after a week.

## Self-review notes
- Spec deviation (documented): no accept endpoint (conversation already exists via the sticker mirror); no `WAVE_INTRO_V2_ENABLED` (no new backend behavior). Spec intent — waves surfaced where users look, accept→conversation, decline silent, push works — is fully covered.
- Parallelizable: Tasks 1, 2, 3, 6 are file-disjoint and can run concurrently; Task 4 needs Task 2; Task 5 after 4 (shares chat_list_screen).
