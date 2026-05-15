# Step 19 — Real Chat (Plan v2 — data-validated)

Date: 2026-05-15
Supersedes: `2026-05-15-step19-real-chat-plan.md`
Recon: `docs/superpowers/recon/2026-05-15-step19-real-chat-recon.md`
Branch: `feat/step19-real-chat` (off `main`)

## Why this is v2

Before finalising v1, we ran 4 production queries + 1 corrections deep-dive against the live `test` database. Data invalidated 5 of 8 original commits. This plan reflects what users actually do, not what the schema supports.

### Data gate results (last 30 days)

| Query | Result | Decision |
|---|---|---|
| Message type distribution | text 98.7%, voice 0.7%, sticker/gif/media <0.5%, poll 0, disappearing 0 | Drop disappearing + polls Flutter fixes — zero usage |
| Correction usage | 9 corrections total, 0 accepted, all from one 7-week-old test week | F1 = fix accept flow, not just discoverability |
| Translation usage | 127/9,598 = 1.32% — only language feature with real traction | B2 = close the translation→SRS loop |
| Active users | 476 senders, avg 20 msg/user/month | Drop @mentions, pinned list, drafts — over-engineering at this scale |

### Corrections deep-dive (9 actual records)

Pattern: All 9 from March 24–30, 2026 (7 weeks ago). One power corrector (`69c2ae4ba041405f2add3382`) did 6/9. Correction quality is poor — appending "^^", "ssss", "hehe" — clearly exploratory/testing, not genuine language corrections. Zero accepts.

**Conclusion:** Users found the Correct button (it's in the long-press menu and they used it). The problem is the **accept flow is broken or invisible to receivers** — 9 corrections, 0 accepts is not a discoverability failure, it's a completion loop failure. Making the Correct button more visible is secondary to fixing the accept flow.

---

## Revised scope (4 effective commits, not 8)

**Dropped entirely:** @mentions write-side, pinned list endpoint, draft persistence, disappearing messages Flutter, polls Flutter — all over-engineering at 20 msg/user/month or zero usage.

**Kept:**
- B1 — Socket rate limit (security hygiene regardless of scale)
- B2 — `saveToVocabulary` endpoint: SRS fields + upsert pattern (closes translation→SRS loop for the only language feature with traction)
- F1 — Corrections accept flow fix + visible chip (fix the broken loop, not just discoverability)
- F2 — "Save phrase" button on main translation view (phrase-level gap next to existing word-breakdown save)
- F3 — Story → DM bubble verification

---

## Commit sequence

| # | Commit | Repo | Files | Effect |
|---|---|---|---|---|
| 1 | `docs(step19-v2): data-validated plan revision` | Backend | `docs/superpowers/plans/*step19*-plan-v2.md` | Record |
| 2 | `fix(socket): rate-limit sendMessage to 10 burst / 1/s` | Backend | `socket/socketHandler.js` | Prevent socket spam |
| 3 | `fix(messages): saveToVocabulary sets SRS fields + upsert` | Backend | `controllers/advancedMessages.js` | Words saved from chat enter review queue |
| 4 | `fix(chat-corrections): surface accept action on correction bubbles` | Flutter | `lib/widgets/tutor/correction_message_bubble.dart` (or chat equivalent) | Closes 0-accept loop |
| 5 | `feat(chat-corrections): visible Correct chip on partner messages` | Flutter | `lib/pages/chat/message/message_bubble.dart` | Surfaces corrections more prominently |
| 6 | `feat(translation): add Save phrase button to translation bottom sheet` | Flutter | `lib/widgets/translation_bottom_sheet.dart` | Phrase-level save alongside word-chip saves |
| 7 | `fix(chat-story-reply): verify story→DM bubble display` | Flutter | `lib/pages/chat/message/message_bubble.dart` + story reply files | storyReference renders correctly |

---

## Commit 2 — Socket rate limit

**File:** `socket/socketHandler.js` — near top with other Maps (~line 20)

```js
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
  const refill  = Math.floor(elapsed / REFILL_RATE_MS);
  if (refill > 0) {
    bucket.tokens = Math.min(BUCKET_CAPACITY, bucket.tokens + refill);
    bucket.lastRefill = now;
  }
  if (bucket.tokens < 1) return false;
  bucket.tokens -= 1;
  return true;
}
```

**Insertion** — top of `sendMessage` socket handler (before validation phase, ~line 654):
```js
if (!consumeMessageToken(socket.userId)) {
  return socket.emit('messageSendError', { error: 'Too many messages — slow down.' });
}
```

**Cleanup** — add to the existing `disconnect` handler:
```js
messageBuckets.delete(socket.userId);
```

---

## Commit 3 — saveToVocabulary SRS fix

**File:** `controllers/advancedMessages.js` — `saveToVocabulary` function (lines 289–350)

**Current problems:**
1. Uses `Vocabulary.create()` without SRS fields → words never enter the review queue (`getDueForReview` queries `nextReview ≤ now`; if null, query misses the word)
2. Race-prone `findOne + create` pattern — can still get 11000 duplicate under concurrent requests
3. Silently handles 11000 as "already in vocabulary" success — correct intent, fragile implementation

**Fix:** Replace with `findOneAndUpdate + $setOnInsert` matching the Step 17/18 pattern, including explicit SRS fields:

```js
exports.saveToVocabulary = asyncHandler(async (req, res, next) => {
  const { word, translation, pronunciation, language, partOfSpeech } = req.body;
  const messageId = req.params.id;
  const userId = req.user._id;

  if (!word || !translation) {
    return next(new ErrorResponse('Word and translation are required', 400));
  }

  const message = await Message.findById(messageId).select('message').lean();
  if (!message) return next(new ErrorResponse('Message not found', 404));

  const user = await User.findById(userId).select('native_language').lean();
  const now = new Date();

  const result = await Vocabulary.findOneAndUpdate(
    { user: userId, word: word.trim() },
    {
      $setOnInsert: {
        user: userId,
        word: word.trim(),
        translation: translation.trim(),
        language: language || 'unknown',
        nativeLanguage: user?.native_language || 'en',
        pronunciation: pronunciation || null,
        partOfSpeech: partOfSpeech || 'other',
        context: {
          source: 'conversation',
          messageId: message._id,
          originalSentence: message.message,
        },
        srsLevel: 0,
        easeFactor: 2.5,
        interval: 0,
        nextReview: now,
        isArchived: false,
        isMastered: false,
      },
    },
    { upsert: true, new: true }
  );

  res.status(201).json({
    success: true,
    data: result,
    message: 'Word saved to vocabulary',
  });
});
```

**Note:** The `new: true` option returns the existing doc if already present (upsert no-op), so the response always contains the vocabulary entry.

---

## Commit 4 — Corrections: fix accept flow

**What the data shows:** 9 corrections, 0 accepts. The correction feature is reachable (users sent 9 corrections). The accept UI is the broken piece.

**Files to locate first (verify during execution):**
- `lib/pages/chat/message/correction_message_bubble.dart` — the receiver-side bubble
- OR wherever `corrections[]` is rendered in the chat message list

**What to fix:**
The correction bubble must show a prominent `FilledButton("Accept ✓")` that calls `PUT /api/v1/messages/:id/corrections/:cid/accept` via the existing `correction_service.dart` (or direct `ApiClient` call). If the accept button exists but is hidden below a scroll or inside a collapsed widget, surface it.

**Expected shape of the correction bubble:**
```
┌─────────────────────────────────────────┐
│ ✏️  Suggested correction                 │
│                                         │
│ Original:   "안녕하세요"                  │
│ Corrected:  "안녕하세요^^"                │
│ Note:       good                        │
│                                         │
│  [Accept ✓]    [Dismiss]                │
└─────────────────────────────────────────┘
```

Both buttons must be visible without scrolling. `Accept` calls the endpoint and collapses the bubble to "Correction accepted ✓".

---

## Commit 5 — Corrections: visible chip on partner messages

**File:** `lib/pages/chat/message/message_bubble.dart`

On **partner messages only** (not own messages), add a small "✏️ Correct" chip below the bubble, visible inline:

```dart
// Below the message bubble, only for partner messages
if (!isMe && !message.isDeleted)
  Padding(
    padding: const EdgeInsets.only(top: 4, left: 8),
    child: GestureDetector(
      onTap: () => _showAddCorrectionDialog(context, message),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 12, color: Colors.orange),
            const SizedBox(width: 4),
            Text('Correct', style: TextStyle(fontSize: 11, color: Colors.orange)),
          ],
        ),
      ),
    ),
  ),
```

This calls the existing `_showAddCorrectionDialog` (or equivalent) that opens the correction input sheet.

---

## Commit 6 — "Save phrase" on main translation view

**File:** `lib/widgets/translation_bottom_sheet.dart`

**Current state:** `_WordDetailSheet` (the word-chip popup, line 696–863) already has a working "Save to Vocabulary" button calling `TranslationService.saveToVocabulary()`. The **main view** has no phrase-level save.

**Gap:** If the translation has no word breakdown (or the user just wants to save the whole phrase), there's no save action.

**Fix:** Add a "Save phrase" button alongside the existing Listen / Copy buttons in `_TranslationBottomSheetState.build()`:

```dart
// In _TranslationBottomSheetState — add to the action row at line ~414
// after the Copy button:
_buildIconButton(
  icon: _phraseSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
  label: _phraseSaved ? 'Saved' : 'Save phrase',
  isLoading: _phraseSaving,
  onTap: _phraseSaved ? () {} : _savePhrase,
  isDark: isDark,
  theme: theme,
),
```

New state fields:
```dart
bool _phraseSaving = false;
bool _phraseSaved  = false;
```

New method:
```dart
Future<void> _savePhrase() async {
  if (_translatedText.isEmpty || widget.originalText.isEmpty) return;
  setState(() => _phraseSaving = true);

  final result = await TranslationService.saveToVocabulary(
    messageId: widget.messageId,
    word: widget.originalText,
    translation: _translatedText,
    language: _targetLanguage,
  );

  if (!mounted) return;
  setState(() {
    _phraseSaving = false;
    _phraseSaved  = result['success'] == true;
  });
  if (result['success'] == true) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phrase saved to study queue'), duration: Duration(seconds: 1)),
      );
    } catch (_) {}
  }
}
```

**Note:** `TranslationService.saveToVocabulary` already calls `POST /messages/:id/vocabulary`. Commit 3 (backend) fixes that endpoint to set SRS fields, so the saved phrase will appear in the review queue automatically.

---

## Commit 7 — Story → DM verification

**Approach during execution:**
1. Find where story viewer has a "Reply" button — likely `lib/pages/stories/`
2. Confirm it creates a message with `storyReference.storyId` populated
3. Find where `MessageBubble` checks `message.storyReference` — if missing, add a small story thumbnail widget above the text content
4. If the whole path works, commit is a no-op (just a verification commit with a comment); if broken, fix and commit

---

## Acceptance criteria

| # | Criterion |
|---|---|
| A1 | 11th message in <1s via socket → `messageSendError` event, no DB write |
| A2 | `POST /messages/:id/vocabulary` → Vocabulary row has `srsLevel:0`, `nextReview ≤ now+1s` |
| A3 | Same word twice → no duplicate, existing SRS state preserved |
| A4 | Received correction bubble shows prominent Accept button without scrolling |
| A5 | Tapping Accept → bubble collapses to "Correction accepted ✓", zero network error |
| A6 | "✏️ Correct" chip visible below partner messages without long-press |
| A7 | "Save phrase" button visible in translation sheet alongside Listen/Copy |
| A8 | Tapping "Save phrase" → snackbar "Phrase saved to study queue", word in DB with SRS fields |
| A9 | Story reply → DM thread shows story thumbnail in bubble |

---

## Explicit non-scope (do not expand)

- Group chat (separate design wave)
- @mentions (over-engineering at current scale)
- Pinned messages list endpoint
- Draft persistence
- Disappearing messages Flutter UI (zero usage)
- Polls Flutter UI (zero usage)
- E2E encryption
- Call records
