# Step 19 — Real Chat (Plan v3 — pre-execution approved)

Date: 2026-05-15
Supersedes: `2026-05-15-step19-real-chat-plan-v2.md`
Recon: `docs/superpowers/recon/2026-05-15-step19-real-chat-recon.md`
Branch: `feat/step19-real-chat` (off `main`)

## Revision history

| Version | Change |
|---|---|
| v1 | Initial plan — 8 commits including @mentions, pinned list, drafts, disappearing/polls Flutter |
| v2 | Data-validated — 4 production queries dropped 5 commits; corrections diagnosis changed from "discoverability" to "broken accept flow" |
| v3 | Pre-execution clarifications: accept button confirmed **completely absent** (not hidden); Step 18 SRS confirmed live; corrections zero-genuine-use note added; F3 disposition rule made explicit |

---

## Three pre-execution clarifications (resolved)

### 1. Commit 4: Accept button is absent, not hidden

**Finding:** `CorrectionMessageBubble` (`lib/widgets/correction_message_bubble.dart`) is a pure `StatelessWidget` with no `GestureDetector`, no callback, and no Accept action. Lines 102–105 only show a static green check icon when `correction.isAccepted == true` (a read-only indicator for already-accepted corrections). There is no interactive element the receiver can tap.

**Mechanically explains 0 accepts from 9 attempts:** The button was never built. The receiver sees the diff and explanation but has no way to act.

**Commit 4 scope:** Build the Accept button, not fix a hidden one. Effort unchanged: add a `FilledButton.icon(onPressed: _accept, label: 'Accept ✓')` for the `!isMe && !correction.isAccepted` case, wired to `CorrectionService.acceptCorrection()`. ~25 lines. `CorrectionService` already has the REST call.

### 2. Step 18 SRS infrastructure is live

**Confirmed on main:**
- `d0a7066 feat(step18): chat vocab_card → SRS auto-extraction` — merged to main
- `e245bca feat(memory-loop): route pronunciation weak words into SRS queue` (Step 17) — merged to main

**Production Vocabulary collection:** 5 entries, all 5 have `nextReview` and `srsLevel` set correctly. Zero entries with `context.source: 'conversation'` — expected, because vocab_card requires real AI tutor sessions; no such session has triggered in production yet.

**B2 is valid:** The downstream SRS consumer (`_TutorTabReviewCard` on AI Study tab, `VocabularyReviewScreen`) is live and working. B2 fixes the write path from chat translation → SRS queue. The pipeline is real: translate message → save word (B2) → enters SRS queue → appears in review card on AI Study tab → flash-card review. Full loop.

### 3. Corrections: zero genuine use — F1 is cheap insurance

**Historical record:** All 9 corrections are from a 7-day window (March 24–30, 2026 — 7 weeks ago). One user did 6/9. Correction content: appending "^^", "ssss", "ddd", "hehe" to the original text — exploratory testing, not real language corrections. The feature has had **zero genuine use in the last 30 days.**

**Implication:** F1 (accept flow + visible chip) ships as cheap insurance — the accept button being missing is a real bug and cheap to fix. But if usage doesn't move after F1, that is a signal that corrections are not wanted at the current scale (476 users, 20 msg/month, mostly early conversations). Users at this stage haven't formed the trust depth that corrections require. **If corrections show no adoption in the 2 weeks following this wave, consider deprecating the feature or deferring to a future growth wave.** Don't sink more engineering into it without the data signal.

### F3 disposition (explicit rule)

If Story → DM verification finds the path fully working with no code change needed: **drop F3 entirely — no no-op commit.** Only ship F3 if code changes are required. State the outcome explicitly in the G1 surface message.

---

## Commit sequence

| # | Commit | Repo | Files | Effect |
|---|---|---|---|---|
| 1 | `docs(step19-v3): pre-execution clarifications` | Backend | `docs/superpowers/plans/*step19*-plan-v3.md` | Record |
| 2 | `fix(socket): rate-limit sendMessage to 10 burst / 1/s` | Backend | `socket/socketHandler.js` | Prevent socket spam |
| 3 | `fix(messages): saveToVocabulary sets SRS fields + upsert` | Backend | `controllers/advancedMessages.js` | Words saved from chat enter SRS review queue |
| 4 | `feat(chat-corrections): add Accept action to correction bubble` | Flutter | `lib/widgets/correction_message_bubble.dart` | Closes 0-accept loop; Accept was never built |
| 5 | `feat(chat-corrections): visible Correct chip on partner messages` | Flutter | `lib/pages/chat/message/message_bubble.dart` | Surfaces corrections more prominently |
| 6 | `feat(translation): add Save phrase button to translation bottom sheet` | Flutter | `lib/widgets/translation_bottom_sheet.dart` | Phrase-level save alongside word-chip saves |
| 7 | `fix(chat-story-reply): [if changes needed]` | Flutter | TBD during verification | Only if broken |

---

## Commit 2 — Socket rate limit

**File:** `socket/socketHandler.js` — add near top of file with other Maps (~line 20):

```js
const messageBuckets = new Map(); // userId → { tokens, lastRefill }
const BUCKET_CAPACITY = 10;
const REFILL_RATE_MS  = 1000;

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

Top of `sendMessage` socket handler (~line 654), before validation:
```js
if (!consumeMessageToken(socket.userId)) {
  return socket.emit('messageSendError', { error: 'Too many messages — slow down.' });
}
```

In `disconnect` handler — add:
```js
messageBuckets.delete(socket.userId);
```

---

## Commit 3 — saveToVocabulary SRS fix

**File:** `controllers/advancedMessages.js` — `saveToVocabulary` (lines 289–350)

**Current bugs:** (1) `Vocabulary.create()` omits `nextReview`, so `getDueForReview` (`nextReview ≤ now`) never matches saved words — they're DB-present but SRS-invisible. (2) Race-prone `findOne + create` — concurrent requests can still 11000. Both fixed by the Step 17/18 upsert pattern.

```js
exports.saveToVocabulary = asyncHandler(async (req, res, next) => {
  const { word, translation, pronunciation, language, partOfSpeech } = req.body;
  const messageId = req.params.id;
  const userId    = req.user._id;

  if (!word || !translation) {
    return next(new ErrorResponse('Word and translation are required', 400));
  }

  const message = await Message.findById(messageId).select('message').lean();
  if (!message) return next(new ErrorResponse('Message not found', 404));

  const user = await User.findById(userId).select('native_language').lean();
  const now  = new Date();

  const result = await Vocabulary.findOneAndUpdate(
    { user: userId, word: word.trim() },
    {
      $setOnInsert: {
        user:          userId,
        word:          word.trim(),
        translation:   translation.trim(),
        language:      language || 'unknown',
        nativeLanguage: user?.native_language || 'en',
        pronunciation: pronunciation || null,
        partOfSpeech:  partOfSpeech || 'other',
        context: {
          source:          'conversation',
          messageId:       message._id,
          originalSentence: message.message,
        },
        srsLevel:   0,
        easeFactor: 2.5,
        interval:   0,
        nextReview: now,
        isArchived: false,
        isMastered: false,
      },
    },
    { upsert: true, new: true }
  );

  res.status(201).json({ success: true, data: result, message: 'Word saved to vocabulary' });
});
```

---

## Commit 4 — Corrections: build the Accept action

**File:** `lib/widgets/correction_message_bubble.dart`

**Current state (confirmed):** Pure `StatelessWidget`. No `GestureDetector`, no callbacks. Lines 102–105 show `Icons.check_circle` when `isAccepted` is already true — read-only. The Accept action was never implemented.

**Change:** Convert to `ConsumerStatefulWidget` (needs `ref` for the accept call), add `_accepting`/`_accepted` state, and render the Accept button for `!isMe && !correction.isAccepted`:

```dart
// After the explanation text (after line 157), inside the Column:
if (!isMe && !correction.isAccepted && !_accepted) ...[
  const SizedBox(height: 10),
  SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _accepting ? null : _accept,
      icon: _accepting
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_rounded, size: 16),
      label: Text(_accepting ? 'Accepting…' : 'Accept correction'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green[600],
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    ),
  ),
] else if (!isMe && (_accepted || correction.isAccepted)) ...[
  const SizedBox(height: 6),
  Row(
    children: [
      Icon(Icons.check_circle, size: 13, color: Colors.green[600]),
      const SizedBox(width: 4),
      Text('Correction accepted', style: TextStyle(fontSize: 12, color: Colors.green[600])),
    ],
  ),
],
```

`_accept()` calls `CorrectionService.acceptCorrection(messageId, correctionId)` (already exists in `correction_service.dart`) and sets `_accepted = true` on success.

---

## Commit 5 — Corrections: visible Correct chip

**File:** `lib/pages/chat/message/message_bubble.dart`

Below partner messages (`!isMe`), inline chip:

```dart
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 12, color: Colors.orange),
            SizedBox(width: 4),
            Text('Correct', style: TextStyle(fontSize: 11, color: Colors.orange)),
          ],
        ),
      ),
    ),
  ),
```

---

## Commit 6 — "Save phrase" on main translation view

**File:** `lib/widgets/translation_bottom_sheet.dart`

**Current state:** `_WordDetailSheet` (word chip popup, line 696–863) already has "Save to Vocabulary" via `TranslationService.saveToVocabulary()`. The **main view** (`_TranslationBottomSheetState`) has no phrase-level save.

**Add** `_phraseSaving` / `_phraseSaved` state fields and a `_savePhrase()` method. Add the button to the action row (line ~414, alongside Listen/Copy):

```dart
_buildIconButton(
  icon: _phraseSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
  label: _phraseSaved ? 'Saved' : 'Save phrase',
  isLoading: _phraseSaving,
  onTap: _phraseSaved ? () {} : _savePhrase,
  isDark: isDark,
  theme: theme,
),
```

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
  if (_phraseSaved) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phrase saved to study queue'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {}
  }
}
```

**B2 (Commit 3) ensures** `TranslationService.saveToVocabulary()` now sets SRS fields, so the saved phrase enters the review queue and appears in `_TutorTabReviewCard` on the AI Study tab.

---

## Commit 7 — Story → DM verification

**Rule:** Only commit if code changes are required. If the path works end-to-end, drop this commit. State outcome in G1 surface message.

---

## Post-wave measurement (2-week gate)

Ship the wave, then pull these queries in 2 weeks:

```js
// Vocab saves from chat translation (B2 + F2)
db.vocabularies.countDocuments({ "context.source": "conversation", createdAt: { $gte: new Date(Date.now() - 14*24*60*60*1000) } })

// Correction acceptance rate (F1 accept button)
db.messages.aggregate([
  { $match: { "corrections.0": { $exists: true }, updatedAt: { $gte: new Date(Date.now() - 14*24*60*60*1000) } } },
  { $project: { accepted: { $gt: [{ $size: { $filter: { input: "$corrections", as: "c", cond: "$$c.isAccepted" } } }, 0] } } },
  { $group: { _id: null, total: { $sum: 1 }, accepted: { $sum: { $cond: ["$accepted", 1, 0] } } } }
])
```

**Decision gate:**
- vocab saves > 0 → B2 + F2 working; translation feature growing
- corrections accepted > 0 → F1 fix worked; users want the feature
- corrections accepted = 0 AND new correction attempts = 0 → corrections not wanted at this scale; flag for deprecation in next planning wave

---

## Acceptance criteria

| # | Criterion |
|---|---|
| A1 | 11th message in <1s → `messageSendError` event, no DB write |
| A2 | `POST /messages/:id/vocabulary` → row has `srsLevel:0`, `nextReview ≤ now+1s` |
| A3 | Same word twice → no duplicate, existing SRS state preserved |
| A4 | Receiver sees "Accept correction" button on correction bubble without scrolling |
| A5 | Tapping Accept → button collapses to "Correction accepted ✓", no error |
| A6 | "✏️ Correct" chip visible below partner messages without long-press |
| A7 | "Save phrase" visible in translation sheet alongside Listen/Copy |
| A8 | Tapping "Save phrase" → snackbar, word in DB with `srsLevel:0` and `nextReview` set |
| A9 | Story → DM: state outcome in G1 message (working or fixed) |
