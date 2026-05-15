# Step 19 — Real Chat (Plan)

Date: 2026-05-15
Recon: `docs/superpowers/recon/2026-05-15-step19-real-chat-recon.md`
Branch: `feat/step19-real-chat` (off `main`)

## Wave overview

The chat system is 95% built. This wave makes it production-solid: close the security gap, wire the two partially-built features that show broken behavior to users (@mentions, pinned list), add draft persistence, and verify/fix the three unverified Flutter surfaces (disappearing, polls, story→DM).

**Group chat is NOT in this wave.** It needs its own design doc and separate branch.

---

## Commit sequence

| # | Commit | Repo | Files | Effect |
|---|---|---|---|---|
| 1 | `docs(step19): recon and plan for real chat wave` | Backend | `docs/superpowers/recon/*step19*`, `docs/superpowers/plans/*step19*` | Record |
| 2 | `fix(socket): rate-limit sendMessage to 10 burst / 1 per second` | Backend | `socket/socketHandler.js` | Prevent socket spam |
| 3 | `feat(messages): auto-parse @mentions on message create + notify` | Backend | `controllers/messages.js`, `services/notificationService.js` (if exists) | @mention users get notified |
| 4 | `feat(messages): GET pinned messages for a conversation` | Backend | `controllers/messageManagement.js`, `routes/messages.js` | List pinned messages |
| 5 | `feat(chat-draft): persist draft text per conversation in Riverpod` | Flutter | `lib/pages/chat/conversation/conversation_input_area.dart`, `lib/providers/chat_state_provider.dart` | Draft survives navigation |
| 6 | `fix(chat-disappearing): wire Flutter destruct countdown + trigger` | Flutter | `lib/pages/chat/message/message_bubble.dart`, disappearing-related widgets | Disappearing UX live |
| 7 | `fix(chat-polls): wire Flutter poll vote + result display` | Flutter | `lib/pages/chat/message/`, poll widgets | Polls live end-to-end |
| 8 | `fix(chat-story-reply): wire story→DM bubble display` | Flutter | `lib/pages/chat/message/message_bubble.dart`, story reference widget | Story replies visible |

---

## Commit 2 — Socket rate limit

**File:** `socket/socketHandler.js`

**Pattern:** Token bucket per user in `Map`. Refill rate: 1 token/second. Burst cap: 10. Only applied to `sendMessage`.

```js
// Near top of file, with other Maps (line ~20)
const messageBuckets = new Map(); // userId → { tokens, lastRefill }
const BUCKET_CAPACITY = 10;
const REFILL_RATE_MS  = 1000; // 1 token per second

function consumeMessageToken(userId) {
  const now = Date.now();
  let bucket = messageBuckets.get(userId);
  if (!bucket) {
    bucket = { tokens: BUCKET_CAPACITY, lastRefill: now };
    messageBuckets.set(userId, bucket);
  }
  const elapsed = now - bucket.lastRefill;
  const refill = Math.floor(elapsed / REFILL_RATE_MS);
  if (refill > 0) {
    bucket.tokens = Math.min(BUCKET_CAPACITY, bucket.tokens + refill);
    bucket.lastRefill = now;
  }
  if (bucket.tokens < 1) return false;
  bucket.tokens -= 1;
  return true;
}
```

**Insertion point:** Top of the `sendMessage` socket handler (line ~654), before the validation phase:

```js
if (!consumeMessageToken(socket.userId)) {
  return socket.emit('messageSendError', { error: 'Too many messages — slow down.' });
}
```

**Cleanup:** Clear stale buckets (users who disconnect) on `disconnect` event — add to existing disconnect handler.

---

## Commit 3 — @mentions write-side + notification

**File:** `controllers/messages.js`

**Where:** In the `createMessage` function, after the message document is saved to DB, before the socket emit.

```js
// After: const message = await Message.create({ ... })
// Before: io.to(receiverRoom).emit('newMessage', ...)

if (message.message) {
  await message.parseMentions();
  await message.save(); // persist mentions[] array
  // notify each mentioned user
  for (const mention of message.mentions) {
    if (mention.user.toString() !== req.user._id.toString()) {
      await notificationService.createNotification({
        recipient: mention.user,
        sender: req.user._id,
        type: 'mention',
        data: { messageId: message._id, preview: message.message.slice(0, 100) },
      });
    }
  }
}
```

**Check:** Verify `parseMentions()` resolves username lookups against User collection (it does — reads from User model inside the method). Confirm `notificationService` path exists; if not, fall back to push notification service used in Step 16.

**Also apply to socket `sendMessage`** — confirm whether the socket path calls the same DB creation logic or duplicates it. If duplicate, apply the same `parseMentions()` call there.

---

## Commit 4 — Pinned messages list endpoint

**File:** `controllers/messageManagement.js`

**New route:** `GET /api/v1/messages/pinned?conversationPartnerId=:userId`

```js
exports.getPinnedMessages = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;
  const partnerId = req.query.conversationPartnerId;
  if (!partnerId) return next(new ErrorResponse('conversationPartnerId required', 400));

  const messages = await Message.find({
    pinned: true,
    isDeleted: false,
    $or: [
      { sender: userId, receiver: partnerId },
      { sender: partnerId, receiver: userId },
    ],
  })
    .sort({ pinnedAt: -1 })
    .limit(50)
    .populate('sender', 'name profileImage')
    .populate('pinnedBy', 'name');

  res.status(200).json({ success: true, data: messages });
});
```

**Wire in routes/messages.js:**
```js
router.get('/pinned', protect, getPinnedMessages);
```
Place before the `/:id` route to avoid capture.

---

## Commit 5 — Draft persistence (Flutter)

**Approach:** `StateProvider<Map<String, String>>` keyed by `otherUserId`. No SharedPreferences needed for v1.

**File:** `lib/providers/chat_state_provider.dart` (or a new `chat_draft_provider.dart`)

```dart
final chatDraftProvider = StateProvider<Map<String, String>>((ref) => {});
```

**File:** `lib/pages/chat/conversation/conversation_input_area.dart`

In the text input widget:
```dart
// On text change — save draft
onChanged: (text) {
  ref.read(chatDraftProvider.notifier).update(
    (drafts) => {...drafts, widget.otherUserId: text},
  );
},

// In initState — restore draft
final draft = ref.read(chatDraftProvider)[widget.otherUserId] ?? '';
_controller.text = draft;
_controller.selection = TextSelection.fromPosition(
  TextPosition(offset: draft.length),
);
```

**On send:** Clear draft for this conversation:
```dart
ref.read(chatDraftProvider.notifier).update(
  (drafts) => {...drafts}..remove(widget.otherUserId),
);
```

---

## Commits 6–8 — Flutter UI verification + fixes

These commits depend on what we find when we read the current Flutter screens. The plan:

**Commit 6 (disappearing):**
- Find `pages/chat/message/` for existing disappearing message bubble/timer widget
- If missing: add a `DisappearingMessageBubble` widget that shows a countdown timer, calls `POST /:id/trigger-destruct` on first render by receiver, and removes the message from local state when the timer fires
- If exists but broken: fix the specific issue found

**Commit 7 (polls):**
- Find poll message widget in `pages/chat/message/`
- Verify `POST /messages/poll/:id/vote` is called on option tap
- Verify `pollVoteUpdate` socket event updates poll result in real-time
- Fix whatever's broken; if not present, build the poll message bubble

**Commit 8 (story → DM):**
- Find story reply flow — likely in `pages/stories/` where story viewer has a "Reply" button
- Verify that tap creates a message with `storyReference.storyId` populated
- Verify that on the receiving end, `MessageBubble` reads `storyReference` and renders the story thumbnail + "Replied to your story" label
- Fix or build whatever's missing

---

## Acceptance criteria

| # | Criterion | How to verify |
|---|---|---|
| A1 | Socket spam blocked | Send 20 messages/sec via socket test → 11th+ get throttle error, no DB writes |
| A2 | @mentions persist | POST message `"@alice hello"` → message.mentions[0].user === alice's id in DB |
| A3 | @mention push notification | alice receives push "bob mentioned you in a message" |
| A4 | Pinned messages listable | Pin 3 messages → `GET /messages/pinned?conversationPartnerId=X` returns 3 |
| A5 | Draft survives navigation | Type "hello", navigate to profile, return to chat → "hello" still in input |
| A6 | Draft clears on send | Send the message → input is empty, draft is cleared |
| A7 | Disappearing message lifecycle | Send disappearing msg → receiver opens → countdown visible → message disappears |
| A8 | Poll vote real-time | Creator sends poll → partner votes → creator's UI updates without refresh |
| A9 | Story→DM bubble | Reply to story → chat thread shows story thumbnail in bubble |

---

## Scope guardrails

**Do not expand into during this wave:**
- Group chat (separate design + wave)
- E2E encryption (crypto undertaking)
- Call records (separate feature)
- Message edit history (low user impact)
- Waveform server-side generation (minor UX polish)
- VIP chat features (quota on translations, etc. — already gated)

**If encountered during execution, log to manual-todos.md and keep moving.**

---

## Merge plan

- 4 backend commits on `feat/step19-real-chat`
- 3 Flutter commits on `feat/step19-real-chat`
- `git merge --no-ff` each repo → main → push
- Backend auto-deploys
- Flutter requires app rebuild
- Smoke after deploy
