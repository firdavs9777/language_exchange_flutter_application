# Step 13A — VIP Gating for AI Study Tutor Chips

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-user daily quotas to the 5 tutor chips (Chat, Roleplay, Story, Photo, Pronounce) on top of the existing tier-aware rate limit. Free/regular users get small daily caps; VIP gets unlimited. Quota exhaustion routes the user into a persona-aware paywall. Install Firebase Analytics. Fix the post-purchase webhook race. Bundle the AudioCache orphan-blob purge job.

**Architecture:**
- **Backend:** Extend the existing `regularUserLimitations` / `visitorLimitations` daily-counter pattern with 5 new field pairs per tier. New `User.consumeQuota(userId, featureKey)` static does **atomic check-and-increment** via a `findOneAndUpdate` pipeline-update with `$expr` filter — race-safe across concurrent devices. The op also returns a full quotas snapshot in the same DB round trip so handlers don't refetch. A new `middleware/checkTutorQuota.js` factory wraps this, gates 4 of the 5 chip trigger endpoints, and returns `429 {error: 'quota_exceeded', ...}` on cap. The 5th endpoint (`/sessions/:id/message`) uses a specialized session-aware middleware that bypasses the chat quota when the underlying session's mode is `'roleplay'` — the roleplay quota was consumed at session-start, messages within a roleplay session are free. Env-var `AI_QUOTA_ENABLED` is the emergency kill switch. Middleware fails closed on internal errors (503).
- **Flutter:** Extend `ApiClient._handleResponse` to extract `body['quotas']` as a top-level field on `ApiResponse` (separate from `body['data']`); the 429 branch detects `error: 'quota_exceeded'` and routes to a new `onQuotaExceeded` callback. New `TutorQuotaState` is exposed via a public `tutorQuotaProvider` (Provider) backed by a private `_tutorMemoryAndQuotasProvider` (FutureProvider) — invalidating the private provider after a gated action triggers a re-fetch of `/tutor/me` that refreshes both memory and quotas. New `TutorQuotaIndicator` widget (compact pill, modeled on `VisitorUsageIndicator`) shows "N left today" in the chip UI once usage ≥ 50%. Persona-aware paywall sheet opens via the existing `callOverlayNavigatorKey` overlay. Webhook race fixed via retry-with-backoff in `VipPaymentScreen`. Firebase Analytics installed + thin `AnalyticsService` wrapper fires 8 typed events.

**Tech Stack:** Node.js / Express / Mongoose / MongoDB (backend); Flutter / Riverpod / flutter_riverpod / Firebase Analytics (mobile). No new vendor relationships — RevenueCat is NOT used; existing Apple App Store Server Notifications + Google Play RTDN webhooks stay as-is.

**Spec reference:** This plan is the spec.

**Branches:** `feat/step13a-vip-gating` on both repos.

**Estimated commits:** 10 (B1-B5 backend, F1-F4 Flutter, G1 glue).

**Pacing:** Drive uninterrupted through tasks per the user's recorded preference. Surface only at G1 or on a genuine blocker.

---

## Revision notes (vs. first draft)

This is revision 2 of the plan; the first draft was reviewed and 13 issues were called out. Each is annotated in line via `<!-- Issue N -->` HTML comments where the fix lands. Summary:

1. **F3 rewritten** linearly, no stream-of-consciousness — final design only.
2. **`quotas` extraction bug fixed** — F1 now adds `quotas` as a separate top-level field on `ApiResponse`, populated from `body['quotas']` directly. `res.data['quotas']` was a bug because `_handleResponse` already extracts `body['data']` into `ApiResponse.data`.
3. **F2 Prerequisite step added** — verify Firebase Console has Analytics enabled + config files include Analytics tokens before installing the package.
4. **Roleplay session-aware bypass implemented in B4** — message-route middleware now looks up `session.mode` and skips the chat quota if the session is a roleplay. Appendix C deleted; behavior matches locked decision #1.
5. **`_shownToday` renamed to `_shownThisSession`** with documented dedup scope (per-app-session, not per-day).
6. **B4 no longer refetches user docs** — `consumeQuota` returns `{ allowed, used, cap, resetAt, snapshot }` in one DB round trip. Middleware stores both on `req.tutorQuotaResult`. Controllers use `req.tutorQuotaResult.snapshot`. `getMyMemory` uses `req.user.getQuotasSnapshot()` directly.
7. **Global navigator wiring uses `callOverlayNavigatorKey`** (existing global key at `lib/router/app_router.dart:118` for overlay screens above GoRouter). No new key invented.
8. **"Edge cases handled" section added** near top of plan with one-liners for time zone changes, multi-day chat sessions, and backend-down fail-closed behavior.
9. **Co-Authored-By trailers removed** from all drafted commit messages.
10. **G1 smoke test specificity tightened** — iOS physical + Android physical only (no simulator).
11. **Task 0 verifies clean working trees** before branching.
12. **`tutor_chip_completed` (8th event) added** to `AnalyticsService`. Firing wired in F4 at the meaningful end-of-flow action per chip.
13. **`flutter pub get` moved** from F2 Step 1 to F2's verification step.

---

## Edge cases handled

<!-- Issue 8 -->

- **Time zone changes / device clock skew.** Server is the single source of truth for "what day is it" — `consumeQuota` computes UTC midnight server-side. Client never decides reset. Acceptable known asymmetry (Seoul resets at local 9 AM, São Paulo at local 9 PM); user-local midnight is a v2 enhancement, not in this wave.
- **Multi-day chat sessions.** Each `consumeQuota` call re-checks reset freshness via the pipeline update's `$lt: [lastReset, startOfTodayUTC]` clause. A message at Monday 23:55 UTC counts against Monday; the next at Tuesday 00:05 UTC triggers reset and counts against Tuesday. No client-side rollover.
- **Backend down / quota check failure.** `checkTutorQuota` middleware wraps `consumeQuota` in try/catch — internal errors return **503 `{error: 'quota_check_failed', message: 'Try again in a moment.', retryAfter: 5}`**, not `next()`. **Fail closed**, not open. Brief outage feels worse than free unlimited usage for the duration. Documented in B3.
- **VIP grace ends mid-roleplay.** Roleplay quota is consumed once at session-start (`POST /sessions/roleplay`). The chat-message middleware checks the session's `mode` and bypasses the chat quota when `mode === 'roleplay'`. So a user mid-roleplay whose grace expires can finish the conversation — no per-message quota check ever runs. New session start applies the new tier.
- **Race condition on quota increment across devices.** `consumeQuota` uses atomic `findOneAndUpdate` with `$expr` filter — the filter only matches if (we're in a new day) OR (counter < cap). Two concurrent requests at counter=cap-1: one passes the filter and increments to cap; the second sees counter=cap (post-first-update), filter fails, returns `allowed: false` immediately. No double-increment.
- **Refund handling.** No new code — existing `/purchases/*/webhook` handlers + `subscriptionExpiryJob.js` already call `user.deactivateVIP()` which flips `userMode` to `'regular'`. The next request through `checkTutorQuota` reads fresh `userMode` and the regular-tier caps apply.

---

## File Structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Create:**
- `middleware/checkTutorQuota.js` — quota gate factory + `checkChatQuotaSessionAware` for the message route + AI_QUOTA_ENABLED short-circuit + fail-closed error handling
- `jobs/audioCacheOrphanPurgeJob.js` — mirror of `pronunciationAudioPurgeJob.js`, scoped to `AudioCache`

**Modify:**
- `models/User.js` — add 5 counter+reset field pairs to both `regularUserLimitations` and `visitorLimitations`; add `User.consumeQuota` static (returns `{allowed, used, cap, resetAt, snapshot}`); add `User.getQuotasSnapshot` instance method
- `config/limitations.js` — add per-tier `tutorDailyQuotas` block; export `AI_QUOTA_ENABLED` env var
- `routes/tutor.js` — attach `checkTutorQuota(featureKey)` to 4 routes; attach `checkChatQuotaSessionAware` to the message route
- `controllers/tutor.js` — `getMyMemory` calls `req.user.getQuotasSnapshot()` directly; the 5 trigger handlers attach `req.tutorQuotaResult.snapshot` to their `quotas` field
- `jobs/scheduler.js` — register `scheduleAudioCacheOrphanPurge()` (2:15 AM KST)

**Reuse (no change):**
- `routes/purchases.js` + `controllers/iosPurchase.js` + `controllers/androidPurchase.js` — webhook pipeline stays
- `jobs/subscriptionExpiryJob.js` — handles VIP expiry + grace period
- `services/storageService.js#deleteFromSpaces` — used by both purge jobs
- `models/AudioCache.js` — has the 90-day TTL already

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Create:**
- `lib/services/analytics_service.dart` — thin Firebase Analytics wrapper with **8 typed event methods**
- `lib/providers/tutor_quota_provider.dart` — private `_tutorMemoryAndQuotasProvider` + public `tutorQuotaProvider`
- `lib/widgets/tutor/tutor_quota_indicator.dart` — compact "N left today" pill widget
- `lib/widgets/tutor/persona_upgrade_sheet.dart` — persona-aware paywall variant

**Modify:**
- `pubspec.yaml` — add `firebase_analytics: ^11.0.0`
- `lib/main.dart` — initialize `FirebaseAnalytics.instance` in the existing Firebase block; wire `ApiClient.onQuotaExceeded` using `callOverlayNavigatorKey`
- `lib/services/api_client.dart` — extract `body['quotas']` into a top-level `ApiResponse.quotas` field; in the 429 branch detect `quota_exceeded` and route to `onQuotaExceeded`
- `lib/providers/tutor_provider.dart` — `TutorService.getMemory()` returns a Dart record `({memory, quotas})`; refactor `tutorMemoryProvider` to read from the new private provider; 5 controllers invalidate the private provider after gated actions
- `lib/pages/ai/tutor/{tutor_chat_screen,pronunciation_session_screen,scenario_picker_screen,story_setup_screen,image_vocab_screen}.dart` — show `TutorQuotaIndicator` + fire `tutor_chip_used` on entry + fire `tutor_chip_completed` at end-of-flow
- `lib/pages/vip/vip_payment_screen.dart` — replace single invalidate with 3-attempt retry-with-backoff + fire analytics events

**Reuse (no change):**
- `lib/providers/provider_root/vip_provider.dart` — `vipStatusProvider` + `isVipProvider` stay
- `lib/widgets/visitor_usage_indicator.dart` — compact-view styling pattern is copied (not extended)
- `lib/widgets/vip_locked_feature.dart` — existing `VipUpgradeSheet` stays; persona sheet is a sibling
- `lib/router/app_router.dart` — `callOverlayNavigatorKey` reused for the global paywall overlay

---

## Critical decisions

1. **Atomic check-and-increment via pipeline update.** Existing `User.incrementMessageCount` uses synchronous `this.field += 1; this.save()` — race-prone. For the new quotas we establish a new atomic pattern. Existing helpers are NOT refactored in this wave.
2. **Pre-increment in middleware, no decrement on AI failure.** Locked decision. If a downstream AI call fails, the counter is NOT rolled back. Rationale: prevents spam-fail abuse. Documented user-facing trade-off.
3. **UTC daily reset, not user-local midnight.** Matches existing pattern. `User.quietHours.timezone` stays unused. Flagged for v2 in `docs/manual-todos.md` if friction surfaces.
4. **`AI_QUOTA_ENABLED=false` is a full bypass.** When the env var is `'false'` (or any non-`'true'` value), middleware calls `next()` with no DB write. No counter increment, no cap check. Treats the entire quota system as feature-flagged.
5. **`consumeQuota` is the sole DB authority for tier + cap.** Server is the source of truth — clients never compute "is it a new day" or "what's my cap." Snapshot is returned alongside the cap check result in one DB round trip; controllers don't refetch. <!-- Issue 6 -->
6. **VIP path = early return.** Short-circuits when active VIP detected; returns a pre-computed all-unlimited snapshot with zero DB writes.
7. **AudioCache orphan purge bundled here.** Mirroring `pronunciationAudioPurgeJob.js` is trivial enough to fold in. Removes the item from the queued-engineering list in the same commit.
8. **Roleplay session-aware bypass.** Once a roleplay session is started, every message within it bypasses the chat quota check. Implemented via a specialized `checkChatQuotaSessionAware` middleware that reads `session.mode` before applying. <!-- Issue 4 -->
9. **Fail closed on quota-check errors.** 503 with retry hint, NOT free unlimited. Bounded outage > unbounded cost. <!-- Issue 8 -->

---

## Task 0: Branch setup

**Files:** none

- [ ] **Step 1: Verify clean working trees on both repos.** <!-- Issue 11 -->

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status --short
# Expected: no output (clean working tree)

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git status --short
# Expected: no output. If any files show up, STOP — investigate (uncommitted WIP) before branching.
```

If either is dirty, surface to the user before continuing. Do NOT auto-stash.

- [ ] **Step 2: Create branches on both repos.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull && git checkout -b feat/step13a-vip-gating

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull && git checkout -b feat/step13a-vip-gating
```

No commit yet — Task B1 includes the first commit.

---

## Task B1: Schema fields for 5 new daily counters

**Files:**
- Modify: `models/User.js` (lines ~375-424 for `regularUserLimitations`, similar block for `visitorLimitations`)

Working dir: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

- [ ] **Step 1: Add 5 counter+reset pairs to `regularUserLimitations`.**

Inside the `regularUserLimitations` schema object, after `translationsToday` / `lastTranslationReset`, add:

```javascript
  // AI tutor chip daily quotas (Step 13A)
  tutorChatToday: { type: Number, default: 0 },
  lastTutorChatReset: { type: Date, default: Date.now },
  roleplaySessionsToday: { type: Number, default: 0 },
  lastRoleplaySessionReset: { type: Date, default: Date.now },
  storyGenerationsToday: { type: Number, default: 0 },
  lastStoryGenerationReset: { type: Date, default: Date.now },
  photoVocabToday: { type: Number, default: 0 },
  lastPhotoVocabReset: { type: Date, default: Date.now },
  pronunciationDrillsToday: { type: Number, default: 0 },
  lastPronunciationDrillReset: { type: Date, default: Date.now },
```

- [ ] **Step 2: Add the same 5 pairs to `visitorLimitations`.**

Identical fields, identical names. Keep the `Today` suffix in both blocks for consistency.

- [ ] **Step 3: Verify.**

```bash
node -c models/User.js
```

Expected: no output (success).

- [ ] **Step 4: Commit.**

```bash
git add models/User.js
git commit -m "$(cat <<'EOF'
feat(vip): add daily-counter schema fields for 5 tutor chips

Extends regularUserLimitations and visitorLimitations with 5 new
counter+reset pairs:
- tutorChatToday + lastTutorChatReset
- roleplaySessionsToday + lastRoleplaySessionReset
- storyGenerationsToday + lastStoryGenerationReset
- photoVocabToday + lastPhotoVocabReset
- pronunciationDrillsToday + lastPronunciationDrillReset

Matches the existing daily-counter naming convention exactly.
Default 0 / Date.now so the fields are populated for every
existing user without a migration.
EOF
)"
```

---

## Task B2: Atomic `User.consumeQuota` + `getQuotasSnapshot`

**Files:**
- Modify: `models/User.js`

`consumeQuota` does the atomic check-and-increment AND returns a full snapshot from the same `findOneAndUpdate` result. <!-- Issue 6 -->

- [ ] **Step 1: Add the feature-key map.**

Near the top of the file (after the existing requires):

```javascript
// Maps the public feature key (used by middleware + API responses) to the
// pair of schema fields on the limitations sub-doc.
const TUTOR_QUOTA_FIELDS = {
  chat:          { counter: 'tutorChatToday',           reset: 'lastTutorChatReset' },
  roleplay:      { counter: 'roleplaySessionsToday',    reset: 'lastRoleplaySessionReset' },
  story:         { counter: 'storyGenerationsToday',    reset: 'lastStoryGenerationReset' },
  photo:         { counter: 'photoVocabToday',          reset: 'lastPhotoVocabReset' },
  pronunciation: { counter: 'pronunciationDrillsToday', reset: 'lastPronunciationDrillReset' },
};

const TUTOR_QUOTA_KEYS = Object.keys(TUTOR_QUOTA_FIELDS);
```

- [ ] **Step 2: Add `getQuotasSnapshot` instance method.**

```javascript
/**
 * Snapshot of all 5 tutor chip quotas for this user. Pure read; does
 * not mutate counters. Computes resetAt and remaining fresh from
 * stored values + the current UTC date.
 *
 * VIP users: returns all-unlimited entries with unlimited: true.
 */
UserSchema.methods.getQuotasSnapshot = function() {
  const LIMITS = require('../config/limitations');
  const now = new Date();
  const startOfTodayUTC = new Date(Date.UTC(
    now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()
  ));
  const startOfTomorrowUTC = new Date(startOfTodayUTC.getTime() + 24 * 60 * 60 * 1000);

  const isVipActive = this.userMode === 'vip'
    && this.vipSubscription?.isActive
    && this.vipSubscription?.endDate
    && new Date(this.vipSubscription.endDate) > now;

  if (isVipActive) {
    return Object.fromEntries(TUTOR_QUOTA_KEYS.map(k => [k, {
      used: 0, cap: null, remaining: null, resetAt: null, unlimited: true,
    }]));
  }

  const tier = this.userMode === 'visitor' ? 'visitor' : 'regular';
  const tierLimits = LIMITS[tier]?.tutorDailyQuotas || {};
  const limitations = tier === 'visitor' ? this.visitorLimitations : this.regularUserLimitations;

  const snapshot = {};
  for (const [key, { counter, reset }] of Object.entries(TUTOR_QUOTA_FIELDS)) {
    const cap = tierLimits[key] ?? 0;
    const lastReset = limitations?.[reset] ? new Date(limitations[reset]) : new Date(0);
    const stale = lastReset < startOfTodayUTC;
    const used = stale ? 0 : (limitations?.[counter] || 0);
    const unlimited = (cap === -1 || cap === Infinity);
    snapshot[key] = {
      used,
      cap: unlimited ? null : cap,
      remaining: unlimited ? null : Math.max(0, cap - used),
      resetAt: startOfTomorrowUTC,
      unlimited,
    };
  }
  return snapshot;
};
```

- [ ] **Step 3: Add `consumeQuota` static method.**

At the bottom of `User.js`, before `module.exports`:

```javascript
/**
 * Atomic check-and-increment for a tutor-chip quota. Returns BOTH the
 * per-feature result AND the freshly-computed full snapshot in one DB
 * round trip — callers should NOT refetch the user document.
 *
 * @param {String} userId
 * @param {String} featureKey
 * @returns {Promise<{allowed: boolean, used: number, cap: number, resetAt: Date|null, snapshot: object}>}
 */
UserSchema.statics.consumeQuota = async function(userId, featureKey) {
  const LIMITS = require('../config/limitations');
  const fields = TUTOR_QUOTA_FIELDS[featureKey];
  if (!fields) throw new Error(`Unknown featureKey: ${featureKey}`);

  const now = new Date();
  const startOfTodayUTC = new Date(Date.UTC(
    now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()
  ));
  const startOfTomorrowUTC = new Date(startOfTodayUTC.getTime() + 24 * 60 * 60 * 1000);

  // Light tier-check read.
  const probe = await this.findById(userId)
    .select('userMode vipSubscription.isActive vipSubscription.endDate')
    .lean();
  if (!probe) {
    return { allowed: false, used: 0, cap: 0, resetAt: startOfTomorrowUTC, snapshot: null };
  }

  // VIP fast path — no DB write, pre-computed snapshot.
  const isVipActive = probe.userMode === 'vip'
    && probe.vipSubscription?.isActive
    && probe.vipSubscription?.endDate
    && new Date(probe.vipSubscription.endDate) > now;
  if (isVipActive) {
    const vipSnapshot = Object.fromEntries(TUTOR_QUOTA_KEYS.map(k => [k, {
      used: 0, cap: null, remaining: null, resetAt: null, unlimited: true,
    }]));
    return {
      allowed: true, used: 0, cap: Infinity, resetAt: null, snapshot: vipSnapshot,
    };
  }

  const tier = probe.userMode === 'visitor' ? 'visitor' : 'regular';
  const tierLimits = LIMITS[tier]?.tutorDailyQuotas || {};
  const cap = tierLimits[featureKey];
  if (cap === undefined || cap === null) {
    return { allowed: false, used: 0, cap: 0, resetAt: startOfTomorrowUTC, snapshot: null };
  }
  if (cap === -1 || cap === Infinity) {
    // Unlimited for this feature in this tier — allow without touching counter.
    const passthrough = await this.findById(userId);
    return {
      allowed: true, used: 0, cap: Infinity, resetAt: null,
      snapshot: passthrough?.getQuotasSnapshot() || null,
    };
  }

  const limitationsPath = tier === 'visitor' ? 'visitorLimitations' : 'regularUserLimitations';
  const counterPath = `${limitationsPath}.${fields.counter}`;
  const resetPath = `${limitationsPath}.${fields.reset}`;

  // Atomic check-and-increment + return updated doc.
  const updated = await this.findOneAndUpdate(
    {
      _id: userId,
      $expr: {
        $or: [
          { $lt: [`$${resetPath}`, startOfTodayUTC] },
          { $lt: [{ $ifNull: [`$${counterPath}`, 0] }, cap] },
        ],
      },
    },
    [{
      $set: {
        [counterPath]: {
          $cond: [
            { $lt: [`$${resetPath}`, startOfTodayUTC] },
            1,
            { $add: [{ $ifNull: [`$${counterPath}`, 0] }, 1] },
          ],
        },
        [resetPath]: {
          $cond: [
            { $lt: [`$${resetPath}`, startOfTodayUTC] },
            '$$NOW',
            `$${resetPath}`,
          ],
        },
      },
    }],
    { new: true }
  );

  if (!updated) {
    // Filter didn't match → cap hit, not new day. Need a snapshot still.
    const current = await this.findById(userId);
    return {
      allowed: false, used: cap, cap, resetAt: startOfTomorrowUTC,
      snapshot: current?.getQuotasSnapshot() || null,
    };
  }

  const used = updated.get(counterPath);
  return {
    allowed: true, used, cap, resetAt: startOfTomorrowUTC,
    snapshot: updated.getQuotasSnapshot(),
  };
};
```

- [ ] **Step 4: Verify.**

```bash
node -c models/User.js
```

- [ ] **Step 5: Commit.**

```bash
git add models/User.js
git commit -m "$(cat <<'EOF'
feat(vip): atomic consumeQuota + getQuotasSnapshot helpers

User.consumeQuota does atomic check-and-increment via
findOneAndUpdate + $expr filter + pipeline update. Returns both
the per-feature result AND the full 5-chip snapshot from the
same round trip so callers don't refetch.

VIP users short-circuit with allowed=true and a pre-computed
all-unlimited snapshot. Non-VIP unlimited-feature tier
(theoretical) passthroughs with a fresh snapshot.

User.getQuotasSnapshot is a pure-read instance method that
computes UTC-daily-reset-aware used / remaining / resetAt for
all 5 chips. Used by getMyMemory directly off req.user.

NOTE: established a new race-safe pattern. Existing helpers
like incrementMessageCount still use the older sync pattern —
not refactored in this wave.
EOF
)"
```

---

## Task B3: limitations.js caps + AI_QUOTA_ENABLED + checkTutorQuota middleware

**Files:**
- Modify: `config/limitations.js`
- Create: `middleware/checkTutorQuota.js`

- [ ] **Step 1: Add `tutorDailyQuotas` per tier.**

Inside each tier (`visitor`, `regular`, `vip`) in `config/limitations.js`:

```javascript
  tutorDailyQuotas: {
    chat:          /* tier-specific */,
    roleplay:      /* tier-specific */,
    story:         /* tier-specific */,
    photo:         /* tier-specific */,
    pronunciation: /* tier-specific */,
  },
```

Values (locked):

| Chip | visitor | regular | vip |
|---|---|---|---|
| chat | 3 | 10 | -1 |
| roleplay | 0 | 1 | -1 |
| story | 0 | 1 | -1 |
| photo | 0 | 2 | -1 |
| pronunciation | 0 | 1 | -1 |

`-1` = unlimited (existing sentinel).

- [ ] **Step 2: Export the feature flag.**

```javascript
// Emergency kill switch. When 'false' (or unset), the new tutor-quota
// middleware short-circuits to next() with no DB write and no check.
exports.AI_QUOTA_ENABLED = String(process.env.AI_QUOTA_ENABLED || 'true').toLowerCase() === 'true';
```

- [ ] **Step 3: Create the middleware.**

`middleware/checkTutorQuota.js`:

```javascript
const asyncHandler = require('./async');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/User');
const AITutorSession = require('../models/AITutorSession');
const { AI_QUOTA_ENABLED } = require('../config/limitations');

/**
 * Build the standard 429 quota_exceeded response.
 */
function buildQuotaExceededResponse(featureKey, resetAt) {
  return {
    success: false,
    error: 'quota_exceeded',
    feature: featureKey,
    resetAt: resetAt?.toISOString() || null,
    message: "You've used today's free quota for this feature. Upgrade to keep going.",
    upgradeAvailable: true,
  };
}

/**
 * Generic factory — used by 4 of the 5 chip routes (roleplay-start,
 * story-generate, image-vocab-describe, pronunciation-summary).
 *
 * The chat-message route uses checkChatQuotaSessionAware below
 * because it needs to bypass the chat quota for messages within
 * an active roleplay session.
 *
 * Fails CLOSED on internal errors (503), not open. Brief outage
 * beats free unlimited usage.
 */
exports.checkTutorQuota = (featureKey) => asyncHandler(async (req, res, next) => {
  if (!AI_QUOTA_ENABLED) return next();
  if (req.user?.role === 'admin') return next();
  if (!req.user?.id) return next();

  let result;
  try {
    result = await User.consumeQuota(req.user.id, featureKey);
  } catch (err) {
    console.error(`[checkTutorQuota:${featureKey}] consumeQuota failed:`, err);
    return res.status(503).json({
      success: false,
      error: 'quota_check_failed',
      message: 'Try again in a moment.',
      retryAfter: 5,
    });
  }

  if (!result.allowed) {
    return res.status(429).json(buildQuotaExceededResponse(featureKey, result.resetAt));
  }

  // Both per-feature result AND full snapshot stashed for controllers.
  req.tutorQuotaResult = { ...result, feature: featureKey };
  next();
});

/**
 * Specialized middleware for POST /tutor/sessions/:id/message.
 *
 * If the underlying session.mode === 'roleplay', the chat quota
 * is bypassed entirely — the roleplay quota was already consumed at
 * session-start, all messages within the session are free. This
 * implements locked decision #1 (don't cut a user off mid-roleplay
 * if VIP grace expires).
 *
 * If session.mode is anything else (chat / default), applies the
 * standard chat quota check.
 */
exports.checkChatQuotaSessionAware = asyncHandler(async (req, res, next) => {
  if (!AI_QUOTA_ENABLED) return next();
  if (req.user?.role === 'admin') return next();
  if (!req.user?.id) return next();

  const sessionId = req.params.id;
  if (!sessionId) return next(new ErrorResponse('Missing session id', 400));

  let session;
  try {
    session = await AITutorSession.findById(sessionId).select('user mode').lean();
  } catch (err) {
    console.error('[checkChatQuotaSessionAware] session lookup failed:', err);
    return res.status(503).json({
      success: false,
      error: 'quota_check_failed',
      message: 'Try again in a moment.',
      retryAfter: 5,
    });
  }

  if (!session) return next(new ErrorResponse('Session not found', 404));
  if (session.user.toString() !== req.user.id.toString()) {
    return next(new ErrorResponse('Not authorized', 403));
  }

  if (session.mode === 'roleplay') {
    // Roleplay session — quota was consumed at session-start. Free pass.
    return next();
  }

  let result;
  try {
    result = await User.consumeQuota(req.user.id, 'chat');
  } catch (err) {
    console.error('[checkChatQuotaSessionAware] consumeQuota failed:', err);
    return res.status(503).json({
      success: false,
      error: 'quota_check_failed',
      message: 'Try again in a moment.',
      retryAfter: 5,
    });
  }

  if (!result.allowed) {
    return res.status(429).json(buildQuotaExceededResponse('chat', result.resetAt));
  }

  req.tutorQuotaResult = { ...result, feature: 'chat' };
  next();
});
```

- [ ] **Step 4: Add `AI_QUOTA_ENABLED` to `.env.example` if it exists.**

```bash
ls .env.example 2>/dev/null && echo "exists" || echo "absent — note in commit msg"
```

If present, append:
```
# Step 13A: gate the 5 AI tutor chips with per-user daily quotas.
# Set to 'false' to disable enforcement.
AI_QUOTA_ENABLED=true
```

- [ ] **Step 5: Verify.**

```bash
node -c config/limitations.js && node -c middleware/checkTutorQuota.js
```

- [ ] **Step 6: Commit.**

```bash
git add config/limitations.js middleware/checkTutorQuota.js .env.example 2>/dev/null
git commit -m "$(cat <<'EOF'
feat(vip): tier-specific tutor daily caps + checkTutorQuota middleware

config/limitations.js gets a tutorDailyQuotas block per tier:
  visitor   {chat:3, roleplay:0, story:0, photo:0, pronunciation:0}
  regular   {chat:10, roleplay:1, story:1, photo:2, pronunciation:1}
  vip       all -1 (unlimited sentinel)

New middleware/checkTutorQuota.js exports two factories:

- checkTutorQuota(featureKey) — generic, used by the 4 simple chip
  routes (roleplay-start, story-generate, image-vocab-describe,
  pronunciation-summary).
- checkChatQuotaSessionAware — used by /sessions/:id/message. Reads
  session.mode; if 'roleplay', bypasses the chat quota entirely
  (roleplay was already consumed at session-start). Otherwise
  applies the standard chat quota check.

Returns the documented 429 quota_exceeded shape on cap-hit.

Fails CLOSED on consumeQuota / session-lookup errors — returns 503
with a retry hint, NOT next(). Brief outage beats free unlimited.

AI_QUOTA_ENABLED env var (default true) short-circuits both
middlewares to next() when set to 'false'. Admin users always
bypass.
EOF
)"
```

---

## Task B4: Wire middleware to 5 routes + handlers use stashed snapshot

**Files:**
- Modify: `routes/tutor.js`
- Modify: `controllers/tutor.js`

No user-doc refetch anywhere in this task. <!-- Issue 6 -->

- [ ] **Step 1: Attach middleware to the 5 trigger routes in `routes/tutor.js`.**

Add to the destructured controller import block:

```javascript
const { checkTutorQuota, checkChatQuotaSessionAware } = require('../middleware/checkTutorQuota');
```

Then on each trigger route:

```javascript
// Chat: session-aware (bypasses for roleplay messages)
router.post('/sessions/:id/message', checkChatQuotaSessionAware, tutorMessageLimiter, sendMessage);

// Roleplay: count at session-start
router.post('/sessions/roleplay', checkTutorQuota('roleplay'), startRoleplaySession);

// Story: count at generation
router.post('/stories/generate', checkTutorQuota('story'), generateStory);

// Photo: count at describe (NOT grade — same session)
router.post('/image-vocab/describe', checkTutorQuota('photo'), imageUpload.single('image'), imageVocabDescribe);

// Pronounce: count at summary-save
router.post('/pronunciation/summary', checkTutorQuota('pronunciation'), submitPronunciationSummary);
```

- [ ] **Step 2: Update `getMyMemory` to use `req.user.getQuotasSnapshot()` directly.** <!-- Issue 6 -->

In `controllers/tutor.js`, replace the existing `getMyMemory` body:

```javascript
exports.getMyMemory = asyncHandler(async (req, res) => {
  const mem = await ensureMemory(req.user._id);
  // req.user is the full Mongoose User doc populated by protect middleware.
  // Instance method works directly — no refetch.
  const quotas = req.user.getQuotasSnapshot
    ? req.user.getQuotasSnapshot()
    : null;
  res.status(200).json({
    success: true,
    data: mem,
    quotas,
  });
});
```

**Verification step (must confirm before relying on this):** open `middleware/auth.js` (or wherever `protect` is defined) and confirm `req.user` is a full Mongoose document (not `.lean()`). If `protect` uses `.lean()`, this code path returns `null` for quotas because instance methods don't exist on lean objects. In that case, **STOP** and surface to the user — either change `protect` to drop `.lean()`, OR add a single `User.findById(req.user._id)` here. (Existing code calls `user.isVIP()` elsewhere, which is an instance method — strong signal `protect` does NOT use `.lean()`. Confirm anyway.)

- [ ] **Step 3: Update the 5 trigger handlers to attach `req.tutorQuotaResult.snapshot` to their success response.** <!-- Issue 6 -->

For each of `sendMessage`, `startRoleplaySession`, `generateStory`, `imageVocabDescribe`, `submitPronunciationSummary`, find the final `res.status(...).json({ success: true, data: ... })` call and add:

```javascript
res.status(200).json({
  success: true,
  data: <existing-data>,
  quotas: req.tutorQuotaResult?.snapshot || null,
});
```

The `quotas` field is `null` when:
- AI_QUOTA_ENABLED was off (middleware bypassed; `req.tutorQuotaResult` unset)
- The route is for a roleplay message (session-aware middleware bypassed without setting `tutorQuotaResult`)

Both cases are correct: the client should show the indicator only when there's data to show.

- [ ] **Step 4: Verify.**

```bash
node -c routes/tutor.js && node -c controllers/tutor.js
```

- [ ] **Step 5: Curl smoke (with backend running and `AI_QUOTA_ENABLED=true`).**

```bash
TOKEN="<regular-tier user token, 0 today usage>"

# First call — succeeds, quotas in response
curl -s -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '{success, used: .quotas.pronunciation.used, cap: .quotas.pronunciation.cap}'
# Expected: success=true, used=1, cap=1

# Second call — 429 quota_exceeded
curl -s -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '{success, error, feature, message}'
# Expected: success=false, error='quota_exceeded', feature='pronunciation'

# Start a roleplay (consumes roleplay quota)
curl -s -X POST http://localhost:5000/api/v1/tutor/sessions/roleplay \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"scenarioId":"<valid id>"}' | jq '.quotas.roleplay'
# Expected: { "used": 1, "cap": 1, ... }

# Send a message in that roleplay session — should NOT consume chat quota
SESSION_ID="<id from previous response>"
curl -s -X POST http://localhost:5000/api/v1/tutor/sessions/$SESSION_ID/message \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"content":"Hello"}' | jq '{success, chatUsed: .quotas.chat.used}'
# Expected: success=true, quotas: null  (because session-aware middleware bypassed,
#           so no tutorQuotaResult was set)
```

- [ ] **Step 6: Commit.**

```bash
git add routes/tutor.js controllers/tutor.js
git commit -m "$(cat <<'EOF'
feat(vip): gate 5 tutor chip endpoints + roleplay session bypass

Trigger points per locked product decision:
  Chat (non-roleplay) → POST /sessions/:id/message
  Roleplay            → POST /sessions/roleplay  (session-start only)
  Story               → POST /stories/generate
  Photo               → POST /image-vocab/describe (NOT /grade)
  Pronounce           → POST /pronunciation/summary

The /sessions/:id/message route uses checkChatQuotaSessionAware
which reads the underlying session.mode. If 'roleplay', the chat
quota is bypassed — the roleplay quota was already consumed at
session-start, so messages within the session are free even if
VIP grace expires mid-conversation. This implements locked
decision #1 (don't cut users off mid-roleplay).

Controllers use req.tutorQuotaResult.snapshot directly for the
quotas response field — no extra DB refetch. getMyMemory uses
req.user.getQuotasSnapshot() (req.user is the full Mongoose doc
from protect; verified during implementation).

quotas field is null when AI_QUOTA_ENABLED is off OR when the
route was bypassed (roleplay messages) — both are correct
"nothing to show" signals to the client.
EOF
)"
```

---

## Task B5: AudioCache orphan-blob purge job

**Files:**
- Create: `jobs/audioCacheOrphanPurgeJob.js`
- Modify: `jobs/scheduler.js`

- [ ] **Step 1: Create the purge job.**

`jobs/audioCacheOrphanPurgeJob.js`:

```javascript
/**
 * AudioCache Orphan-Blob Purge Job
 *
 * Mirror of jobs/pronunciationAudioPurgeJob.js scoped to AudioCache
 * (TTS audio caching).
 *
 * AudioCache has a 90-day Mongo TTL on lastAccessedAt — Mongo auto-drops
 * the metadata. This job runs ~3 days before the TTL fires and deletes
 * the underlying Spaces blob so audio is gone BEFORE the URL disappears.
 *
 * Idempotent: once audioUrl is null, subsequent runs skip the record.
 */

const AudioCache = require('../models/AudioCache');
const { deleteFromSpaces } = require('../services/storageService');

const CUTOFF_DAYS = 87;
const BATCH_LIMIT = 1000;

const purgeAudioCacheOrphans = async () => {
  const cutoff = new Date(Date.now() - CUTOFF_DAYS * 24 * 60 * 60 * 1000);
  const counts = { processed: 0, blobsDeleted: 0, errors: 0, skipped: 0 };

  console.log(`[audio-cache-purge] starting — cutoff=${cutoff.toISOString()} batchLimit=${BATCH_LIMIT}`);

  const docs = await AudioCache
    .find({
      lastAccessedAt: { $lt: cutoff },
      audioUrl: { $ne: null, $exists: true },
    })
    .select('_id audioUrl')
    .limit(BATCH_LIMIT)
    .lean(false);

  for (const doc of docs) {
    counts.processed++;
    const url = doc.audioUrl;
    if (!url || typeof url !== 'string' || url.length === 0) {
      counts.skipped++;
      continue;
    }
    try {
      await deleteFromSpaces(url);
      doc.audioUrl = null;
      await doc.save();
      counts.blobsDeleted++;
    } catch (e) {
      counts.errors++;
      console.error(`[audio-cache-purge] failed for cache ${doc._id}: ${e.message}`);
    }
  }

  console.log(
    `[audio-cache-purge] done — processed=${counts.processed} ` +
    `deleted=${counts.blobsDeleted} skipped=${counts.skipped} errors=${counts.errors}`
  );
  return counts;
};

module.exports = { purgeAudioCacheOrphans };
```

- [ ] **Step 2: Wire into `jobs/scheduler.js`.**

Find the existing `schedulePronunciationAudioPurge` block. Add the require at the top:

```javascript
const { purgeAudioCacheOrphans } = require('./audioCacheOrphanPurgeJob');
```

Add the scheduler function:

```javascript
const scheduleAudioCacheOrphanPurge = () => {
  const runJob = async () => {
    console.log('\n⏰ Running scheduled AudioCache orphan purge...');
    try {
      await purgeAudioCacheOrphans();
    } catch (error) {
      console.error('Scheduled AudioCache orphan purge failed:', error);
    }
    setTimeout(runJob, 24 * 60 * 60 * 1000);
  };

  // 2:15 AM KST — staggered 15min after the pronunciation purge.
  const msUntilNextRun = getMillisecondsUntil(2, 15);
  console.log(`📅 AudioCache orphan purge scheduled in ${Math.round(msUntilNextRun / 1000 / 60 / 60)} hours`);
  setTimeout(runJob, msUntilNextRun);
};
```

Inside `startScheduler()`, right after the pronunciation purge call:

```javascript
  schedulePronunciationAudioPurge();
  scheduleAudioCacheOrphanPurge();   // ← NEW
```

- [ ] **Step 3: Verify.**

```bash
node -c jobs/audioCacheOrphanPurgeJob.js && node -c jobs/scheduler.js && npm test 2>&1 | tail -3
```

- [ ] **Step 4: Commit.**

```bash
git add jobs/audioCacheOrphanPurgeJob.js jobs/scheduler.js
git commit -m "$(cat <<'EOF'
feat(privacy): AudioCache orphan-blob purge job

Mirrors jobs/pronunciationAudioPurgeJob.js. AudioCache has a 90-day
Mongo TTL on lastAccessedAt; without a Spaces cleanup job the
underlying mp3 blobs persist indefinitely. New job runs nightly at
2:15 AM KST, finds records older than 87 days with audioUrl still
set, deletes the Spaces blob and nulls the URL.

Idempotent, batch-capped at 1000/run, slot-staggered 15 minutes
after the pronunciation purge to avoid simultaneous bursts.

Closes the queued-engineering item in docs/manual-todos.md
(cleanup landed in the Flutter doc commit).
EOF
)"
```

---

## Task F1: ApiClient `quotas` extraction + `quota_exceeded` detection

**Files:**
- Modify: `lib/services/api_client.dart`

Working dir: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

<!-- Issue 2: quotas at body level needs its own field on ApiResponse, separate from body['data'] -->

- [ ] **Step 1: Add `QuotaError` data class.**

Near the bottom of `api_client.dart` (with the other helper classes):

```dart
class QuotaError {
  final String feature;
  final DateTime? resetAt;
  final String message;
  final bool upgradeAvailable;

  const QuotaError({
    required this.feature,
    required this.resetAt,
    required this.message,
    required this.upgradeAvailable,
  });

  factory QuotaError.fromJson(Map<String, dynamic> j) => QuotaError(
    feature: j['feature']?.toString() ?? 'unknown',
    resetAt: j['resetAt'] != null ? DateTime.tryParse(j['resetAt'].toString()) : null,
    message: j['message']?.toString() ?? "You've hit your daily limit.",
    upgradeAvailable: j['upgradeAvailable'] == true,
  );
}
```

- [ ] **Step 2: Extend `ApiResponse`.**

Add two new fields:

```dart
class ApiResponse {
  // ... existing fields ...

  /// Top-level `quotas` block from the response body, present on /tutor/me
  /// and the 5 gated trigger endpoints. Distinct from `data` because the
  /// server returns it at body root, not inside body.data.
  final Map<String, dynamic>? quotas;

  /// Populated on 429 quota_exceeded responses. Null for everything else.
  final QuotaError? quotaError;

  bool get isQuotaExceeded => statusCode == 429 && quotaError != null;

  ApiResponse({
    // existing params,
    this.quotas,
    this.quotaError,
  });
}
```

- [ ] **Step 3: Add `onQuotaExceeded` callback to ApiClient.**

Find the existing callback fields (search for `onRateLimitError`). Add a parallel field:

```dart
/// Called when the server returns 429 with body.error == 'quota_exceeded'.
/// Distinct from onRateLimitError — quota exhaustion routes to the
/// paywall, generic rate limit shows a toast.
final void Function(QuotaError quotaError)? onQuotaExceeded;
```

Wire through the constructor's parameter list.

- [ ] **Step 4: Extract `body['quotas']` in `_handleResponse`.**

In `_handleResponse` (around line 225+), after parsing `body`, add (before any return statement):

```dart
final Map<String, dynamic>? bodyQuotas =
    body['quotas'] is Map ? Map<String, dynamic>.from(body['quotas']) : null;
```

Then **every** `return ApiResponse(...)` in this method passes `quotas: bodyQuotas`. Easiest: a small helper:

```dart
ApiResponse _build({
  required bool success,
  dynamic data,
  String? error,
  required int statusCode,
  RateLimitInfo? rateLimitInfo,
  QuotaError? quotaError,
}) => ApiResponse(
  success: success,
  data: data,
  error: error,
  statusCode: statusCode,
  rateLimitInfo: rateLimitInfo,
  quotaError: quotaError,
  quotas: bodyQuotas,
);
```

Use `_build(...)` everywhere a new `ApiResponse(...)` is currently constructed in `_handleResponse`. (Yes, it's mechanical; do them all.)

- [ ] **Step 5: Update the 429 branch to detect `quota_exceeded`.**

Replace:

```dart
case 429:
  // Rate limit exceeded
  final errorMessage = body['error'] ?? 'Too many requests. Please slow down.';
  onRateLimitError?.call(_getReadableRateLimitError(errorMessage));
  return ApiResponse(
    success: false,
    error: _getReadableRateLimitError(errorMessage),
    statusCode: 429,
    rateLimitInfo: _rateLimits[endpoint],
  );
```

With:

```dart
case 429:
  // Two flavors: standard rate limit vs. daily quota exhaustion.
  if (body['error'] == 'quota_exceeded') {
    final qe = QuotaError.fromJson(Map<String, dynamic>.from(body));
    onQuotaExceeded?.call(qe);
    return _build(
      success: false,
      error: qe.message,
      statusCode: 429,
      quotaError: qe,
    );
  }
  final errorMessage = body['error'] ?? 'Too many requests. Please slow down.';
  onRateLimitError?.call(_getReadableRateLimitError(errorMessage));
  return _build(
    success: false,
    error: _getReadableRateLimitError(errorMessage),
    statusCode: 429,
    rateLimitInfo: _rateLimits[endpoint],
  );
```

- [ ] **Step 6: Verify.**

```bash
flutter analyze lib/services/api_client.dart 2>&1 | tail -3
```

Expected: no errors specific to this file.

- [ ] **Step 7: Commit.**

```bash
git add lib/services/api_client.dart
git commit -m "$(cat <<'EOF'
feat(vip): ApiClient extracts quotas + detects quota_exceeded

ApiResponse gains two new fields:
- quotas (Map?) — top-level body.quotas block, populated by every
  response that includes it (/tutor/me + 5 gated trigger
  endpoints). Distinct from .data because the server returns
  quotas at body root, not inside body.data.
- quotaError (QuotaError?) — populated only on 429 quota_exceeded.

_handleResponse extracts body['quotas'] once at the top and routes
it through every ApiResponse construction via a small _build()
helper to keep wiring uniform.

The 429 branch now distinguishes:
  body.error == 'quota_exceeded' → onQuotaExceeded callback (paywall)
  anything else                  → onRateLimitError (toast, unchanged)

Global wiring of onQuotaExceeded lands in F4 alongside the persona
paywall sheet.
EOF
)"
```

---

## Task F2: Firebase Analytics + AnalyticsService wrapper (8 events)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `lib/services/analytics_service.dart`

<!-- Issue 3: prereq check before install -->
<!-- Issue 12: 8th event added -->
<!-- Issue 13: pub get moved to verification step -->

- [ ] **Step 0: PREREQUISITE — verify Firebase Console has Analytics enabled and config files include Analytics tokens.**

This is a manual gate. Before touching code:

```bash
# 1. iOS: check that GoogleService-Info.plist has the Analytics keys.
#    The file should contain GOOGLE_APP_ID + ANDROID_CLIENT_ID + others;
#    if you grep for "IS_ANALYTICS_ENABLED" the value should be present.
grep -E "IS_ANALYTICS_ENABLED|GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist

# 2. Android: check that google-services.json includes an "analytics_service" block.
grep -E "analytics_service|analytics_property" android/app/google-services.json
```

**Expected:**
- iOS file has `GOOGLE_APP_ID` (always) AND `IS_ANALYTICS_ENABLED` set to `true` (or absent — Firebase default is enabled).
- Android file mentions `analytics_service` or `analytics_property`.

**If either is missing:**
1. STOP. Open https://console.firebase.google.com → bananatalk project → Project Settings.
2. Confirm Analytics is enabled at the project level (not just SDK level).
3. Re-download `GoogleService-Info.plist` and `google-services.json` from the Firebase Console.
4. Replace the bundled files.
5. Re-run the grep checks before proceeding.

Surface to the user if Firebase Console access is needed — agent cannot complete this step autonomously.

- [ ] **Step 1: Add `firebase_analytics` to `pubspec.yaml`.**

In the `# Firebase & Notifications` section, right after `firebase_messaging`:

```yaml
  firebase_analytics: ^11.0.0
```

(Don't run `pub get` yet — it's the verification step below.)

- [ ] **Step 2: Initialize in `lib/main.dart`.**

Add the import at the top:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
```

In the existing Firebase init block (lines ~37-46), after `await Firebase.initializeApp();`:

```dart
    // Step 13A: Analytics. Initialized after Firebase.initializeApp().
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
```

- [ ] **Step 3: Create `lib/services/analytics_service.dart`.**

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin Firebase Analytics wrapper for Step 13A VIP-gating events.
/// Methods are typed so call sites can't misspell event names or
/// forget required params.
///
/// All methods are async-fire-and-forget; we never await analytics
/// from the UI thread. On SDK error, debug-print and move on —
/// never block the user.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  Future<void> _log(String name, Map<String, Object?> params) async {
    try {
      final clean = <String, Object>{};
      params.forEach((k, v) {
        if (v != null) clean[k] = v;
      });
      await _fa.logEvent(name: name, parameters: clean);
    } catch (e) {
      if (kDebugMode) debugPrint('[analytics] $name failed: $e');
    }
  }

  // ─── Step 13A events ──────────────────────────────────────────

  Future<void> tutorChipUsed({required String chipName, required String userTier}) =>
      _log('tutor_chip_used', {'chip_name': chipName, 'user_tier': userTier});

  /// Fired at the meaningful end-of-flow action for each chip:
  ///   Chat        → session end (user navigates away or explicit end)
  ///   Roleplay    → end-of-session score request
  ///   Story       → reaching the final comprehension question / score screen
  ///   Photo       → after the describe response is rendered + user dismisses
  ///   Pronounce   → Save & Close on the summary sheet
  Future<void> tutorChipCompleted({required String chipName, required String userTier}) =>
      _log('tutor_chip_completed', {'chip_name': chipName, 'user_tier': userTier});

  Future<void> quotaRemainingShown({required String chipName, required int remainingCount}) =>
      _log('quota_remaining_shown', {'chip_name': chipName, 'remaining_count': remainingCount});

  Future<void> quotaHit({required String chipName, required String tier}) =>
      _log('quota_hit', {'chip_name': chipName, 'tier': tier});

  Future<void> paywallShown({required String triggerChip, required String reason}) =>
      _log('paywall_shown', {'trigger_chip': triggerChip, 'reason': reason});

  Future<void> paywallCtaTapped({required String chipName}) =>
      _log('paywall_cta_tapped', {'chip_name': chipName});

  Future<void> subscriptionPurchased({required String plan, required String platform}) =>
      _log('subscription_purchased', {'plan': plan, 'platform': platform});

  Future<void> subscriptionPurchaseFailed({
    required String plan,
    required String platform,
    required String errorCode,
  }) =>
      _log('subscription_purchase_failed', {
        'plan': plan,
        'platform': platform,
        'error_code': errorCode,
      });
}
```

- [ ] **Step 4: Verify (install + analyze).** <!-- Issue 13 -->

```bash
flutter pub get
flutter analyze lib/services/analytics_service.dart lib/main.dart 2>&1 | tail -3
```

Expected: `flutter pub get` resolves cleanly; analyze shows no errors specific to these files.

- [ ] **Step 5: Commit.**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/services/analytics_service.dart
git commit -m "$(cat <<'EOF'
feat(analytics): Firebase Analytics + typed AnalyticsService wrapper

Adds firebase_analytics ^11.0.0 (companion to existing firebase_core
+ firebase_messaging). Initialized once in main.dart's Firebase
block; collection enabled by default.

lib/services/analytics_service.dart wraps FirebaseAnalytics in a
singleton with 8 typed methods, one per Step 13A event:
  tutor_chip_used / tutor_chip_completed /
  quota_remaining_shown / quota_hit /
  paywall_shown / paywall_cta_tapped /
  subscription_purchased / subscription_purchase_failed

tutor_chip_completed fires at the meaningful end-of-flow action per
chip (Chat session end, Roleplay end-of-session score, Story score
screen, Photo describe-then-dismiss, Pronounce Save & Close) so we
can compute entry → completion funnel rates.

All methods are async-fire-and-forget — analytics never blocks UI.
SDK errors are debug-printed and swallowed.

Event firing in F3 (quota_remaining_shown) + F4 (everything else).
EOF
)"
```

---

## Task F3: Tutor quota state + counter UI widget

<!-- Issue 1: F3 rewritten linearly, final design only -->
<!-- Issue 5: _shownToday renamed to _shownThisSession -->

**Files:**
- Modify: `lib/providers/tutor_provider.dart`
- Create: `lib/providers/tutor_quota_provider.dart`
- Create: `lib/widgets/tutor/tutor_quota_indicator.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: the 5 chip screens (`tutor_chat_screen`, `pronunciation_session_screen`, `scenario_picker_screen`, `story_setup_screen`, `image_vocab_screen`)

**Final design:**
- `TutorService.getMemory()` returns a Dart record `({TutorMemory memory, Map<String, dynamic>? quotas})`.
- Private `_tutorMemoryAndQuotasProvider` (FutureProvider.autoDispose) holds the record.
- Public `tutorMemoryProvider` reads from the private one, exposing just the memory (backward-compat for existing call sites).
- Public `tutorQuotaProvider` (plain Provider) reads from the private one, exposing a typed `TutorQuotaState`.
- After each successful gated action, the corresponding controller calls `ref.invalidate(_tutorMemoryAndQuotasProvider)` to trigger a re-fetch.
- `TutorQuotaIndicator` reads `tutorQuotaProvider` and renders the compact pill once usage ≥ 50% for the given chip.

- [ ] **Step 1: Modify `TutorService.getMemory()` to return a record.**

In `lib/providers/tutor_provider.dart`, change the existing `getMemory` to:

```dart
Future<({TutorMemory memory, Map<String, dynamic>? quotas})> getMemory() async {
  final res = await _api.get('tutor/me');
  if (!res.success || res.data == null) {
    throw StateError(res.error ?? 'Failed to load tutor memory');
  }
  return (
    memory: TutorMemory.fromJson(_dataObj(res.data)),
    quotas: res.quotas,   // <— from F1
  );
}
```

- [ ] **Step 2: Refactor `tutorMemoryProvider` + create `tutorQuotaProvider`.**

Create `lib/providers/tutor_quota_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

class TutorQuotaInfo {
  final int used;
  final int? cap;        // null when unlimited (VIP)
  final int? remaining;  // null when unlimited
  final DateTime? resetAt;
  final bool unlimited;

  const TutorQuotaInfo({
    required this.used,
    required this.cap,
    required this.remaining,
    required this.resetAt,
    required this.unlimited,
  });

  factory TutorQuotaInfo.fromJson(Map<String, dynamic> j) => TutorQuotaInfo(
    used: (j['used'] as num?)?.toInt() ?? 0,
    cap: (j['cap'] as num?)?.toInt(),
    remaining: (j['remaining'] as num?)?.toInt(),
    resetAt: j['resetAt'] != null ? DateTime.tryParse(j['resetAt'].toString()) : null,
    unlimited: j['unlimited'] == true,
  );

  /// True once usage ≥ 50% of cap. Hides for unlimited.
  bool get shouldShowIndicator {
    if (unlimited || cap == null || cap == 0) return false;
    return used * 2 >= cap!;
  }
}

class TutorQuotaState {
  final TutorQuotaInfo? chat;
  final TutorQuotaInfo? roleplay;
  final TutorQuotaInfo? story;
  final TutorQuotaInfo? photo;
  final TutorQuotaInfo? pronunciation;

  const TutorQuotaState({this.chat, this.roleplay, this.story, this.photo, this.pronunciation});

  static const empty = TutorQuotaState();

  TutorQuotaInfo? get(String key) {
    switch (key) {
      case 'chat':          return chat;
      case 'roleplay':      return roleplay;
      case 'story':         return story;
      case 'photo':         return photo;
      case 'pronunciation': return pronunciation;
      default: return null;
    }
  }

  factory TutorQuotaState.fromMap(Map<String, dynamic>? quotasJson) {
    if (quotasJson == null) return empty;
    TutorQuotaInfo? parse(String k) {
      final v = quotasJson[k];
      return v is Map<String, dynamic> ? TutorQuotaInfo.fromJson(v) : null;
    }
    return TutorQuotaState(
      chat:          parse('chat'),
      roleplay:      parse('roleplay'),
      story:         parse('story'),
      photo:         parse('photo'),
      pronunciation: parse('pronunciation'),
    );
  }
}

/// Per-app-session dedup set for the quota_remaining_shown event.
/// Resets when the app process restarts — we intentionally do NOT
/// persist this across restarts. v1 acceptable.
final _shownThisSession = <String>{};

void _maybeFireRemainingShown(TutorQuotaState state) {
  for (final key in ['chat', 'roleplay', 'story', 'photo', 'pronunciation']) {
    final info = state.get(key);
    if (info != null && info.shouldShowIndicator && !_shownThisSession.contains(key)) {
      _shownThisSession.add(key);
      AnalyticsService.instance.quotaRemainingShown(
        chipName: key,
        remainingCount: info.remaining ?? 0,
      );
    }
  }
}

/// Public provider — reads from the private memory+quotas provider.
/// Fires quota_remaining_shown analytics on first sight of ≥ 50% per chip.
final tutorQuotaProvider = Provider<TutorQuotaState>((ref) {
  final asyncResult = ref.watch(tutorMemoryAndQuotasProvider);
  return asyncResult.maybeWhen(
    data: (r) {
      final state = TutorQuotaState.fromMap(r.quotas);
      _maybeFireRemainingShown(state);
      return state;
    },
    orElse: () => TutorQuotaState.empty,
  );
});
```

- [ ] **Step 3: Add the private provider + refactor existing `tutorMemoryProvider`.**

In `lib/providers/tutor_provider.dart`, find the existing `tutorMemoryProvider` definition (around line 140-150):

```dart
final tutorMemoryProvider = FutureProvider<TutorMemory>((ref) {
  return ref.read(tutorServiceProvider).getMemory();
});
```

Replace with:

```dart
/// Internal — holds the raw response (memory + quotas) so we can
/// fan it out to two public providers without making two HTTP calls.
final tutorMemoryAndQuotasProvider = FutureProvider.autoDispose<
    ({TutorMemory memory, Map<String, dynamic>? quotas})>((ref) {
  return ref.read(tutorServiceProvider).getMemory();
});

/// Public — backward-compatible memory-only view.
final tutorMemoryProvider = FutureProvider<TutorMemory>((ref) async {
  final r = await ref.watch(tutorMemoryAndQuotasProvider.future);
  return r.memory;
});
```

(Naming note: I dropped the leading underscore on `tutorMemoryAndQuotasProvider` because Dart treats `_` as library-private — and the consumer in `tutor_quota_provider.dart` is a different file. Effectively still "internal" but accessible across files within the same package.)

- [ ] **Step 4: Invalidate the private provider in each of the 5 gated controllers after a successful action.**

Controllers needing the invalidation:
- `TutorChatController.send` (sendMessage success) — `tutor_provider.dart`
- `TutorChatController.startRoleplay` (roleplay session-start success) — `tutor_provider.dart`
- `StoryController.generate` (story generate success) — wherever that lives
- `ImageVocabController.describe` (describe success) — wherever that lives
- `PronunciationController.finish` (summary save success) — `pronunciation_provider.dart`

Each controller already has access to a `Ref` (passed in its constructor — confirm before adding; if not, add it). After the `_safeSet` of the success state, add:

```dart
ref.invalidate(tutorMemoryAndQuotasProvider);
```

(Import the provider from `tutor_provider.dart` if needed.)

- [ ] **Step 5: Create the indicator widget.**

`lib/widgets/tutor/tutor_quota_indicator.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

/// Compact "N left today" pill. Renders nothing for VIP / below 50% used.
class TutorQuotaIndicator extends ConsumerWidget {
  final String featureKey;
  final IconData icon;

  const TutorQuotaIndicator({
    super.key,
    required this.featureKey,
    this.icon = Icons.flash_on_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(tutorQuotaProvider).get(featureKey);
    if (info == null || !info.shouldShowIndicator) {
      return const SizedBox.shrink();
    }
    final remaining = info.remaining ?? 0;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(
            l10n.aiTutorQuotaRemaining(remaining),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Add the l10n key.**

In `lib/l10n/app_en.arb`:

```json
"aiTutorQuotaRemaining": "{count, plural, =1{1 left today} other{{count} left today}}",
"@aiTutorQuotaRemaining": {
  "description": "Daily quota counter pill on tutor chip screens",
  "placeholders": { "count": {"type": "int"} }
}
```

- [ ] **Step 7: Wire the indicator into the 5 chip screens.**

For each screen, add `TutorQuotaIndicator(featureKey: '<key>')` to its `AppBar.actions` (or wherever fits):

| File | featureKey |
|---|---|
| `tutor_chat_screen.dart` | `'chat'` |
| `scenario_picker_screen.dart` | `'roleplay'` |
| `story_setup_screen.dart` | `'story'` |
| `image_vocab_screen.dart` | `'photo'` |
| `pronunciation_session_screen.dart` | `'pronunciation'` |

Insert before any existing AppBar actions where it makes visual sense.

- [ ] **Step 8: Verify.**

```bash
flutter gen-l10n && flutter analyze lib/providers/tutor_quota_provider.dart lib/widgets/tutor/tutor_quota_indicator.dart lib/providers/tutor_provider.dart 2>&1 | tail -5
```

Expected: no errors in these files. (Pre-existing info-level lints elsewhere are fine.)

- [ ] **Step 9: Commit.**

```bash
git add lib/providers/tutor_quota_provider.dart lib/widgets/tutor/tutor_quota_indicator.dart lib/providers/tutor_provider.dart lib/pages/ai/tutor/ lib/l10n/
git commit -m "$(cat <<'EOF'
feat(vip): tutor quota state + "N left today" indicator on 5 chips

Architecture:
- TutorService.getMemory() returns Dart record (memory, quotas).
- New tutorMemoryAndQuotasProvider (FutureProvider) holds the
  raw record so two public providers can fan out without
  making two HTTP calls.
- Existing tutorMemoryProvider refactored to read from the new
  private provider — no breaking change for downstream callers.
- New tutorQuotaProvider (Provider) exposes typed TutorQuotaState.
- After each successful gated controller action, the controller
  invalidates tutorMemoryAndQuotasProvider so the indicator
  reflects the post-increment count.

TutorQuotaIndicator: compact pill, shown only when usage ≥ 50%
for that chip. Hides for VIP (unlimited). Crossing the 50%
threshold once per app session fires quota_remaining_shown
(dedup via _shownThisSession set; intentionally not persisted
across app restarts — v1 acceptable).
EOF
)"
```

---

## Task F4: Persona paywall + global wiring + webhook race + analytics

<!-- Issue 7: uses existing callOverlayNavigatorKey -->
<!-- Issue 12: tutor_chip_completed firing wired here -->

**Files:**
- Create: `lib/widgets/tutor/persona_upgrade_sheet.dart`
- Modify: `lib/main.dart` (wire `ApiClient.onQuotaExceeded` using existing `callOverlayNavigatorKey`)
- Modify: `lib/pages/vip/vip_payment_screen.dart` (retry-with-backoff + fire purchase events)
- Modify: the 5 chip screens (fire `tutor_chip_used` on entry + `tutor_chip_completed` at end-of-flow)
- Modify: `docs/manual-todos.md` (drop the AudioCache item)

- [ ] **Step 1: Create the persona-aware paywall sheet.**

`lib/widgets/tutor/persona_upgrade_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// Persona-aware variant of VipUpgradeSheet. Copy matches the user's
/// selected persona — falls back to generic if persona is unset.
/// Fires paywall_shown on first build, paywall_cta_tapped on Upgrade.
class PersonaUpgradeSheet extends ConsumerWidget {
  final String triggerChip;
  final String reason; // 'quota_exceeded' | 'locked_feature'

  const PersonaUpgradeSheet({
    super.key,
    required this.triggerChip,
    this.reason = 'quota_exceeded',
  });

  String _copyForPersona(String? persona) {
    switch (persona) {
      case 'nana':
        return "Want to keep chatting with Nana? 🐻\nUpgrade for unlimited.";
      case 'sensei':
        return "Continue your training with Sensei. 🤖\nUpgrade for unrestricted practice.";
      case 'riko':
        return "Riko's just getting warmed up! 🐙\nUpgrade and let's keep going.";
      default:
        return "Want to keep going?\nUpgrade for unlimited AI Study.";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memAsync = ref.watch(tutorMemoryProvider);
    final persona = memAsync.valueOrNull?.persona;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.paywallShown(triggerChip: triggerChip, reason: reason);
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 28, 24, MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _copyForPersona(persona),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                AnalyticsService.instance.paywallCtaTapped(chipName: triggerChip);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VipPlansScreen()),
                );
              },
              child: const Text(
                'Upgrade to VIP',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire `ApiClient.onQuotaExceeded` globally using `callOverlayNavigatorKey`.** <!-- Issue 7 -->

In `lib/main.dart`, import the overlay key:

```dart
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;
import 'package:bananatalk_app/widgets/tutor/persona_upgrade_sheet.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
```

Then wherever `ApiClient()` is constructed/configured (find it via `grep -n "ApiClient(" lib/`), add the callback:

```dart
ApiClient(
  // existing params...
  onQuotaExceeded: (qe) {
    final overlayCtx = callOverlayNavigatorKey.currentContext;
    if (overlayCtx == null) return;
    showModalBottomSheet(
      context: overlayCtx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PersonaUpgradeSheet(triggerChip: qe.feature),
    );
    AnalyticsService.instance.quotaHit(chipName: qe.feature, tier: 'free');
  },
);
```

(`tier: 'free'` is hardcoded because by definition only non-VIP users hit `quota_exceeded`. Refine to actually read `userMode` from `userProvider` if you want visitor/regular precision — minor.)

- [ ] **Step 3: Webhook-race retry-with-backoff in `vip_payment_screen.dart`.**

Find the success path (lines ~202-214). Replace with:

```dart
if (verifyResult['success'] == true) {
  // Webhook race fix: Apple/Google webhook may not have processed by
  // the time we re-fetch /vip/status. Retry up to 3 times over ~6 sec.
  bool confirmedVip = false;
  for (int attempt = 1; attempt <= 3; attempt++) {
    ref.invalidate(userProvider);
    ref.invalidate(vipStatusProvider(widget.userId));
    ref.invalidate(userLimitsProvider(widget.userId));
    try {
      final status = await ref.read(vipStatusProvider(widget.userId).future);
      if (status['isVIP'] == true) {
        confirmedVip = true;
        break;
      }
    } catch (_) {
      // Soft-fail; retry until budget exhausted.
    }
    if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
  }
  if (!mounted) return;
  if (confirmedVip) {
    ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
    AnalyticsService.instance.subscriptionPurchased(
      plan: widget.plan,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    _showSuccessDialog();
  } else {
    ref.read(purchaseStateProvider.notifier).state = PurchaseState.pending;
    _showPendingDialog();
  }
} else {
  AnalyticsService.instance.subscriptionPurchaseFailed(
    plan: widget.plan,
    platform: Platform.isIOS ? 'ios' : 'android',
    errorCode: verifyResult['error']?.toString() ?? 'unknown',
  );
  // ... existing error handling
}
```

Add `_showPendingDialog`:

```dart
void _showPendingDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Almost there'),
      content: const Text(
        "Your subscription is processing — please try refreshing in a minute.",
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

If `PurchaseState.pending` doesn't exist, add it to the enum.

- [ ] **Step 4: Fire `tutor_chip_used` on entry to each chip screen.**

In each chip screen's `initState` (or first build hook):

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final isVip = ref.read(isVipProvider(widget.userId));
  AnalyticsService.instance.tutorChipUsed(
    chipName: '<chip>',  // chat / roleplay / story / photo / pronunciation
    userTier: isVip ? 'vip' : 'free',
  );
});
```

- [ ] **Step 5: Fire `tutor_chip_completed` at end-of-flow.** <!-- Issue 12 -->

| Chip | Where to fire | Trigger |
|---|---|---|
| Chat | `tutor_chat_screen.dart` — `dispose()` | Screen torn down |
| Roleplay | wherever end-of-session score is requested | After `gradeScenario` returns |
| Story | `story_reader_screen.dart` — when score screen renders | First build of the score view |
| Photo | `image_vocab_screen.dart` — when user dismisses describe screen | dispose() of describe view |
| Pronounce | `pronunciation_session_screen.dart` — `PronunciationSummarySheet._save()` success | After `finish()` resolves |

Pattern per call site:

```dart
AnalyticsService.instance.tutorChipCompleted(
  chipName: '<chip>',
  userTier: <derived as in step 4>,
);
```

For dispose-based call sites, read the user tier in `initState` and cache it on the State object — `ref.read` from `dispose` is allowed but reading providers feels awkward; caching is cleaner.

- [ ] **Step 6: Remove the AudioCache item from manual-todos.md.**

In `docs/manual-todos.md`, find the bullet under Queued engineering → Architecture prep beginning `**(30 min) AudioCache orphan blob purge.**` — delete the entire bullet.

- [ ] **Step 7: Verify.**

```bash
flutter analyze 2>&1 | grep -E "(persona_upgrade_sheet|vip_payment_screen|tutor_quota|api_client)" | head -10
# Expected: no errors specific to these files
```

- [ ] **Step 8: Commit.**

```bash
git add lib/widgets/tutor/persona_upgrade_sheet.dart lib/main.dart lib/pages/vip/vip_payment_screen.dart lib/pages/ai/tutor/ docs/manual-todos.md
git commit -m "$(cat <<'EOF'
feat(vip): persona paywall + global wiring + webhook race + events

PersonaUpgradeSheet — new bottom-sheet variant with Nana/Sensei/Riko
copy lines. Falls back to generic copy when persona is unset.
Fires paywall_shown on first build and paywall_cta_tapped on
Upgrade button.

Global ApiClient.onQuotaExceeded uses the existing
callOverlayNavigatorKey (lib/router/app_router.dart:118) which
sits above GoRouter in the widget tree — paywall sheets appear
on top of any route. Also fires quota_hit analytics.

Webhook race fix in VipPaymentScreen: replace single
invalidate-and-flip-success with a 3-attempt retry loop
(2s between attempts, 6s total worst case). Only show success
when backend confirms userMode === 'vip'; on timeout show a
"subscription is processing" dialog instead of misleading
success-then-revert.

Each chip screen fires tutor_chip_used on entry and
tutor_chip_completed at its meaningful end-of-flow action
(see analytics_service.dart docstring for per-chip trigger
points). VipPaymentScreen fires subscription_purchased on
confirmed success and subscription_purchase_failed on
verification failure.

Closes the AudioCache orphan-blob item in manual-todos.md
(implementation landed in backend B5).
EOF
)"
```

---

## Task G1: Glue — manual smoke test + merge

<!-- Issue 10: physical devices only -->

**Files:** none (this is the merge gate)

- [ ] **Step 1: Backend smoke (`npm run dev`, `AI_QUOTA_ENABLED=true`).**

```bash
TOKEN_REGULAR="<regular-tier token, 0 today usage>"
TOKEN_VIP="<active-VIP token>"

# A. Regular Pronounce — first succeeds, second 429.
# (see B4 step 5 for the curl chain)

# B. VIP unlimited.
curl -s -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN_VIP" \
  -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '.quotas.pronunciation.unlimited'
# Expected: true

# C. Roleplay session-aware bypass — see B4 step 5.

# D. Feature flag off.
AI_QUOTA_ENABLED=false npm run dev &
# Two pronounce-summary POSTs as regular → both should succeed, no 429.

# E. Backend error fail-closed.
# Manually break consumeQuota temporarily (e.g., throw) → request returns 503.
```

- [ ] **Step 2: Flutter smoke on TWO real devices: iOS physical + Android physical.** <!-- Issue 10 -->

Sandbox purchases on simulator/emulator are flaky and don't exercise the actual webhook race. Use real hardware.

For each device:

1. AI Study tab → Pronounce chip → start drill → finish 1 session → Save & Close
2. Try to start a second drill same day → expect persona-aware paywall sheet
3. Confirm sheet copy matches selected persona, NOT "Quota exceeded"
4. Tap "Upgrade to VIP" → arrives at VipPlansScreen → confirm `paywall_cta_tapped` fires (Firebase DebugView)
5. Tap a real plan + complete purchase (sandbox iOS or test Google Play account):
   - Success dialog only appears after backend confirms `isVIP: true`
   - If 3rd retry fails, "processing" dialog appears instead
6. After purchase, re-enter Pronounce chip → no quota indicator, no paywall, full access
7. Flip `AI_QUOTA_ENABLED=false` on the backend, restart, retry as free user → no 429

- [ ] **Step 3: Analytics verification (Firebase Console → Analytics → DebugView).**

During the smoke flow, confirm these events appear:
- `tutor_chip_used` (chip entry)
- `tutor_chip_completed` (end-of-flow)
- `quota_remaining_shown` (when crossing 50% — only fires for chips with cap ≥ 2, mainly chat)
- `quota_hit` (first 429)
- `paywall_shown` (persona sheet appears)
- `paywall_cta_tapped` (Upgrade tap)
- `subscription_purchased` (confirmed VIP)
- `subscription_purchase_failed` (if you simulate a failure)

- [ ] **Step 4: Final analyze + push both branches.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git push -u origin feat/step13a-vip-gating

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "error •" && echo "ERRORS — fix before merge" || echo "no errors"
git push -u origin feat/step13a-vip-gating
```

- [ ] **Step 5: Open PRs.**

```bash
gh pr create --title "feat: Step 13A VIP gating + analytics + webhook race fix" \
  --body "Step 13A. See docs/superpowers/plans/2026-05-13-step13a-vip-gating-plan.md."
```

Same on backend.

---

## Cadence guidance

- **B1 → B5 land first** on backend, in order. After B4 the backend is functionally complete; B5 is independent but bundled here for atomicity.
- **F1 lands first on Flutter** — downstream tasks need the new `ApiResponse.quotas` field shape.
- **F2 and F3 can be authored in parallel** but commit F2 first so F3's `quota_remaining_shown` event has somewhere to fire.
- **F4 is the final Flutter task** — depends on F1-F3 + B1-B5 all being on `main` (or at least pushed) so the smoke test can hit a real backend.
- **G1 smoke test is the merge gate.** Do not merge either branch until both physical-device smokes pass.

## Risk + rollback

- **Highest-risk change: B2 `consumeQuota`.** New atomic pattern, no automated test framework on backend beyond `node:test`. Rollback: revert B2 + B3 + B4 (sequential cherry-pick revert). The 3 commits should land together or roll back together.
- **Mid-risk: F4 webhook race fix.** If the 3-attempt loop hangs or `vipStatusProvider` future never resolves, user is stuck on a spinner. Each attempt has explicit 2s `Future.delayed`; the soft-fail catch ensures loop completes. Rollback: revert F4 — leaves the old single-invalidate behavior.
- **Mid-risk: F1 `_build()` refactor.** Every `ApiResponse(...)` construction in `_handleResponse` is mechanically rewritten. Risk: a missed call site. Mitigation: `flutter analyze` will catch any obvious miss; manual scan during PR review is the fallback. Rollback: revert F1.
- **Low-risk: B5 AudioCache purge.** Isolated job; failures log and continue. Rollback: delete the file + revert scheduler wiring.
- **Emergency kill switch.** Set `AI_QUOTA_ENABLED=false` in backend `.env` and restart. All quota checks bypass without a code rollback.
- **Pre-deploy DB note.** The TTL/index additions in B1 + the schema fields are Mongoose-managed and populated by defaults on first read. No migration script. No backfill needed.

---

## Appendix A — Why "count at describe-success" for Photo

Photo flow: user uploads image → `/image-vocab/describe` returns AI description → optionally `/image-vocab/grade` for self-test → end. The "1 photo" unit is one successful describe; grading is a free follow-up on the same image.

## Appendix B — Why "count at summary-save" for Pronounce

A Pronounce session is 5 sentences. Counting at the first sentence-fetch would tick even if the user immediately backs out. Counting at `/pronunciation/score` would over-count (5 per session). Counting at `/pronunciation/summary` matches "one completed drill = one quota tick" cleanly.
