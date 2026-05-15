# Step 18 — Chat → Vocabulary auto-extraction (Plan)

Date: 2026-05-15
Recon: `docs/superpowers/recon/2026-05-15-step18-chat-vocab-recon.md`
Branch: `feat/step18-chat-vocab` (off `main`)

## Wave shape

| # | Commit | Files | Effect |
|---|---|---|---|
| 1 | docs: recon + plan | `docs/superpowers/recon/*step18*.md`, `docs/superpowers/plans/*step18*.md` | Record the wave |
| 2 | feat(tutor): persist vocab_card payloads into SRS queue | `controllers/tutor.js` | Inline bridge in `sendMessage` |

Total: 2 commits backend, 0 commits Flutter. Single day.

## Commit 2 — the bridge

**File:** `controllers/tutor.js`

**Location:** Inside `sendMessage`, after `await session.save();` (around line 258), before `res.status(200).json(...)`.

**Logic:**

```js
// Step 18: if the AI emitted a vocab_card, queue the word for SRS review.
// Same upsert pattern as Step 17 pronunciation bridge — $setOnInsert keeps
// existing SRS state intact when the user has already seen the word.
if (parsed.messageType === 'vocab_card' && parsed.payload?.word) {
  try {
    const word = String(parsed.payload.word).trim();
    if (word) {
      const targetLang =
        parsed.payload.language ||
        req.user?.language_to_learn ||
        'en';
      const nativeLang = req.user?.native_language || 'en';
      const example = parsed.payload.example
        ? String(parsed.payload.example).slice(0, 500)
        : undefined;
      const now = new Date();

      await Vocabulary.findOneAndUpdate(
        { user: req.user._id, word },
        {
          $setOnInsert: {
            user: req.user._id,
            word,
            translation: String(parsed.payload.definition || '').slice(0, 500),
            language: targetLang,
            nativeLanguage: nativeLang,
            partOfSpeech: 'other',
            context: {
              source: 'conversation',
              ...(example ? { example } : {}),
            },
            srsLevel: 0,
            easeFactor: 2.5,
            interval: 0,
            nextReview: now,
            isArchived: false,
            isMastered: false,
          },
        },
        { upsert: true, new: false }
      );
    }
  } catch (err) {
    console.error('[tutor.sendMessage] vocab_card → Vocabulary failed:', err.message);
    // never let the bridge fail the chat response
  }
}
```

**Import check:** Verify `Vocabulary` is required at the top of `controllers/tutor.js` (it is — Step 17 added the import). No new imports needed.

**Why no helper extraction:** Inline is ~25 lines and identical to the Step 17 block. Factoring into a `queueVocabForSrs(user, payload)` helper would invite the next two writers to drift the signature. If a third writer joins (image-vocab), we factor then.

## Edge cases — handling

| Case | Behavior |
|---|---|
| Missing payload.word | Skip — no insert |
| Empty payload.definition | Insert with `translation: ''` (manual-todos backfill candidate) |
| DB write error | `try/catch` logs and proceeds; chat response unaffected |
| Same word again | `$setOnInsert` preserves prior SRS state |
| Roleplay session | `messageType` is force-converted to `'text'` upstream — bridge no-op |
| Quota | Already gated by `gateAIQuota` on the chat turn |

## Smoke (manual)

1. `git checkout feat/step18-chat-vocab && npm start`
2. Open the Flutter app → AI Study → AI Tutor → free chat
3. Send: "teach me a new Korean word for 'happy'"
4. Wait for AI to emit a vocab_card (may take 1–2 tries to coax)
5. In Mongo Atlas / Compass: `db.vocabularies.find({ user: <my id> }).sort({ createdAt: -1 }).limit(3)` — confirm the new word with `srsLevel: 0`, `context.source: 'conversation'`
6. Back to app → AI Study tab top — if ≥3 due words, the Step 17 review card shows
7. Re-trigger same word → confirm no duplicate (`db.vocabularies.countDocuments({ user, word: <word> })` === 1)
8. Send a normal text question ("how are you") → no Vocabulary insert
9. Start a roleplay session → exchange a few turns → no Vocabulary inserts

## Merge plan

Same shape as Step 17:
- Commits land on `feat/step18-chat-vocab`
- `git merge --no-ff feat/step18-chat-vocab` to `main`
- Push → backend auto-deploys
- No Flutter changes → no app build needed
- Smoke after deploy

## Out of scope (manual-todos handoff)

If any of these come up during execution, log to `manual-todos.md`, do not expand the wave:
- `'tutor_chat'` enum extension for `context.source`
- Translation backfill for empty-translation Vocabulary records
- "+ added to study" overlay on vocab_card widget
- Image-vocab Vocabulary bridge
- Whole-transcript NLP extraction
- Roleplay vocab extraction (separate model call required)

## Acceptance

- [ ] vocab_card emission produces exactly one Vocabulary row per (user, word)
- [ ] Existing SRS state is preserved on re-emission
- [ ] Chat response time unchanged (write is `await`-ed but local-only Mongo round-trip)
- [ ] No errors in production logs on text-only turns
- [ ] Step 17 review card on AI Study tab reflects new count without code changes
