# AI Usage Audit — Design Spec

**Date:** 2026-06-03  
**Status:** Approved

## Problem

`trackUsage()` in `aiProviderService.js` is a stub that only `console.log`s. No AI feature usage is persisted to the database, making it impossible to answer: who used what, and when.

## Goal

Persist a lightweight audit record every time a user invokes any AI feature, with zero changes to the 5 subsystems that already call `trackUsage()`.

## Design

### 1. `AIUsageLog` Model

New MongoDB collection `aiusagelogs`:

```js
{
  userId:    { type: ObjectId, ref: 'User', required: true, index: true },
  feature:   { type: String, required: true, index: true },
  timestamp: { type: Date, default: Date.now, index: true }
}
```

Feature strings (existing values passed by subsystems): `tutor_chat`, `tutor_tts`, `tutor_stt`, `tutor_roleplay`, `tutor_story`, `tutor_image_vocab`, `tutor_pronunciation`, `ai_conversation`, `grammar_feedback`, `translation`, `speech_tts`, `speech_stt`, `speech_pronunciation`.

### 2. `trackUsage()` Implementation

Replace the `console.log` stub in `aiProviderService.js` with a fire-and-forget DB write:

```js
async trackUsage(userId, feature, tokensUsed) {
  AIUsageLog.create({ userId, feature }).catch(err =>
    console.error('AI usage log failed:', err)
  );
}
```

No `await` — never blocks the caller. Errors are caught and logged but not re-thrown.

### 3. Admin Query Endpoint

`GET /api/v1/admin/ai-usage`

Query params: `feature` (optional), `from` / `to` (ISO dates, optional).

Response:
```json
{
  "total": 1420,
  "byFeature": [
    { "feature": "tutor_chat", "count": 850 },
    { "feature": "grammar_feedback", "count": 320 }
  ],
  "byDay": [
    { "date": "2026-06-03", "count": 47 }
  ]
}
```

Secured via existing `requireAdmin` middleware.

## What Does NOT Change

- No changes to any of the 5 AI subsystems
- `tokensUsed` parameter is accepted but not stored (out of scope for now)
- Daily chip quota system on `User` model is untouched

## Files Affected

- `backend/models/AIUsageLog.js` — new file
- `backend/services/aiProviderService.js` — implement `trackUsage()`
- `backend/routes/admin.js` (or equivalent admin router) — new endpoint
- `backend/controllers/adminController.js` (or equivalent) — query logic
