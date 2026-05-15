# Step 18 — Chat → Vocabulary auto-extraction (Recon)

Date: 2026-05-15
Branch: (planning) — execute on `feat/step18-chat-vocab`

## TL;DR

The AI tutor already emits `vocab_card` messages (`{ word, language, definition, example, ipa? }`) when it teaches a new word. **Those payloads are rendered on the client and then thrown away** — nothing writes them into the `Vocabulary` collection. Step 18 closes that loop with the same pattern Step 17 used for pronunciation weak words: upsert into `Vocabulary` with `$setOnInsert` so the existing SRS queue (and the Step 17 review card on the AI Study tab) picks them up automatically.

Pre-built: **~70%**. Vocab model is mature, SRS is wired, message persistence already stores the payload, the review-card surface already exists. The gap is one bridge in `controllers/tutor.js#sendMessage`.

## Surface map

### Tutor chat (in scope)
- `POST /api/v1/tutor/sessions/:id/message` → `controllers/tutor.js#sendMessage` (lines 210–265).
- After AI reply parse, the controller pushes `{ role:'assistant', content, messageType, payload, createdAt }` onto `session.messages` and saves.
- `messageType: 'vocab_card'` is one of 6 card types defined in `services/tutorService.js#RESPONSE_SCHEMA` (lines 21–40). Payload shape:
  ```js
  { word: string, language: string, definition: string, example?: string, ipa?: string }
  ```
- **Insertion point for the bridge:** between `session.save()` and `res.status(200).json(...)` (around line 258).

### Roleplay chat (out of scope)
- `POST /api/v1/tutor/sessions/roleplay` + same `sendMessage` controller.
- Controller forces `messageType: 'text'` on every roleplay reply (tutor.js:242–243). vocab_card can never reach persistence in roleplay mode, so no bridge needed.

### Image-vocab (already covered)
- Image vocab teaches words via its own dedicated screen + endpoint. Out of scope for this wave; revisit later if user requests.

### P2P chat (excluded by design)
- `models/Message.js` user↔user chat. No AI in the loop. Privacy-sensitive. Step 17 + Step 18 stay within the AI tutor surface.

### Existing Vocabulary writers (don't duplicate)
1. `controllers/learning.js#addVocabulary` — manual add (line 205)
2. `controllers/advancedMessages.js#saveToVocabulary` — explicit "save this message word" (line 319)
3. `controllers/tutor.js#submitPronunciationSummary` — Step 17 pronunciation bridge (lines 718–743)
4. (Step 18 adds the 4th: tutor chat vocab_card bridge)

### Vocabulary schema (relevant fields)
- `word`, `translation`, `language`, `nativeLanguage` — direct map
- `partOfSpeech` enum includes `'other'` — we'll use it (vocab_card payload doesn't include POS)
- `context.source` enum: `['conversation', 'lesson', 'manual', 'quiz', 'import']` — **no `'tutor_chat'`**
- `context.example` — direct map from payload.example
- SRS init: `srsLevel: 0, easeFactor: 2.5, interval: 0, nextReview: now` (same as Step 17)
- Unique index on `(user, word)` — upsert is the right primitive

## Design decisions

### DD1 — Trigger: inline at AI-reply persist time
**Decision:** Run the upsert inside `sendMessage`, immediately after `session.save()`, whenever `parsed.messageType === 'vocab_card'`.

**Why:** Same pattern as Step 17 (pronunciation bridge runs inline at submit time). The user sees the vocab_card UI in the same response cycle that queues the SRS card. The Step 17 review-card on AI Study tab reflects the new count on the next provider refresh — no extra signal needed.

**Rejected — Background sweep:** Cron over all sessions every N minutes. Adds infra, delays the SRS surface, fails on session-end edge cases. No upside vs inline.

**Rejected — Endpoint to flush vocab from a finished session:** Adds a new API call and a "flushed/not-flushed" flag on the session. Same outcome as inline with more state.

**Rejected — Whole-transcript NLP extraction on session end:** Expensive (extra model call), async, hard to test. We already get structured vocab from `vocab_card`; no need to re-extract.

### DD2 — Source enum: reuse `'conversation'`
**Decision:** Use `context.source: 'conversation'`. Same value Step 17 uses for pronunciation weak words.

**Why:** Keeps the enum stable. Avoids a migration. Both pronunciation and chat are conversational AI surfaces; the distinction isn't load-bearing for the SRS queue.

**Rejected — Extend enum to `'tutor_chat'`:** Cleaner taxonomy long-term, but requires schema change + UI filter updates. Logged to manual-todos as a future cleanup alongside the queued `'pronunciation'` extension.

### DD3 — POS: hardcode `'other'`
**Decision:** Set `partOfSpeech: 'other'` for chat-extracted words. Don't try to infer.

**Why:** vocab_card payload doesn't include POS. Asking the model to add it would require RESPONSE_SCHEMA changes and risk breaking existing client renderers. `'other'` is harmless for SRS and matches what Step 17 does for pronunciation weak words (which also default to `'other'`).

### DD4 — UX feedback: zero new UI
**Decision:** No toast, no banner, no card overlay. Existing Step 17 review-card on AI Study tab is the visible surface.

**Why:** The user sees the vocab_card already (the AI just taught them). Adding "+ added to study" is noise. The "N words to review" count on the AI Study tab updates organically next time the user opens the tab — that's the right surface.

**Rejected — "+ added to study" badge on vocab_card:** Pretty but redundant. Save for a polish wave if user requests.

**Rejected — Snackbar on session end ("Added N words to study"):** Requires session-level batching state. Doesn't fit the inline trigger.

## Edge cases

1. **Same word twice in different sessions** — `$setOnInsert` is upsert-with-no-overwrite, so the existing SRS state (interval, easeFactor, history) is preserved. ✓
2. **Payload missing word / definition** — Skip silently and log. Never fail the chat response over a bad payload — the user still sees the AI reply.
3. **AI fabricates junk vocab_card** — Trust the model in v1. Same risk as today (the card already renders); we just additionally queue it for review.
4. **Roleplay slips a vocab_card through** — Controller force-converts to text (line 242–243) before persistence, so `parsed.messageType` is `'text'`. The bridge only fires on `vocab_card` → no-op. Defensive by accident.
5. **User has `language_to_learn` unset** — Fall back to `payload.language` (the card declares its own language), then to `'en'`. Same fallback chain Step 17 uses.
6. **Vocabulary write fails** (DB hiccup) — Wrap in `.catch()` that logs and returns null. Chat response must not depend on the bridge.
7. **Quota gating** — `sendMessage` is already behind `gateAIQuota`. Step 18 doesn't add a new quota; vocab insertions ride along with chat turns the user has already paid for.
8. **Empty translation field** — If `payload.definition` is empty string, we still insert (Vocabulary requires `translation` but allows empty string). Logged in manual-todos as a backfill candidate; ignoring for v1.

## Smoke checklist

- [ ] Send a tutor message that triggers a `vocab_card` reply (e.g. "teach me a new Korean word")
- [ ] Check Mongo: `Vocabulary.findOne({ user: <id>, word: <new word> })` exists with `srsLevel: 0`, `nextReview: <now>`, `context.source: 'conversation'`
- [ ] Open AI Study tab → "N words to review" card increments (or first appears at threshold 3)
- [ ] Send the same vocab_card twice (or trigger same word again) → no duplicate row, existing SRS state intact
- [ ] Send a normal text reply → no Vocabulary write, no errors in logs
- [ ] Start a roleplay session, exchange messages → no Vocabulary writes (text-only)

## Scope summary

**In:** Backend bridge in `sendMessage`. 1 file changed, ~20 lines.

**Out:**
- Roleplay extraction (vocab_card forced off)
- P2P chat extraction (no AI in loop)
- `'tutor_chat'` enum extension (queued)
- "+ added to study" UX overlay (queued)
- Translation backfill (queued)
- Image-vocab Vocabulary bridge (separate surface, revisit later)

**Estimated commits:** 1 feature + 1 docs = 2 commits, single-day wave.
