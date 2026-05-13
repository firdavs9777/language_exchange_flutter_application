# Step 13A — VIP Gating for AI Study Tutor Chips

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-user daily quotas to the 5 tutor chips (Chat, Roleplay, Story, Photo, Pronounce) on top of the existing tier-aware rate limit. Free/regular users get small daily caps; VIP gets unlimited. Quota exhaustion routes the user into a persona-aware paywall. Install Firebase Analytics. Fix the post-purchase webhook race. Bundle the AudioCache orphan-blob purge job.

**Architecture:**
- **Backend:** Extend the existing `regularUserLimitations` / `visitorLimitations` daily-counter pattern with 5 new field pairs per tier. New `User.consumeQuota(userId, featureKey)` static does **atomic check-and-increment** via a `findOneAndUpdate` pipeline-update with `$expr` filter — race-safe across concurrent devices. A new `middleware/checkTutorQuota.js` factory wraps this, gates the 5 chip trigger endpoints, and returns `429 {error: 'quota_exceeded', ...}` on cap. Env-var `AI_QUOTA_ENABLED` is the emergency kill switch.
- **Flutter:** Extend `ApiClient._handleResponse` 429 branch to detect `error: 'quota_exceeded'` and route to a new `onQuotaExceeded` callback (separate from the existing `onRateLimitError` for normal rate limits). New `TutorQuotaState` notifier holds the 5 chip counters, populated from a new `quota` block in `/tutor/me` and from per-request response bodies. New `TutorQuotaIndicator` widget (compact view modeled on `VisitorUsageIndicator`) shows "N left today" in the chip UI once the user crosses 50% used. Persona-aware paywall sheet (new variant of `VipUpgradeSheet`) opens on quota_exceeded. Webhook race fixed via retry-with-backoff in `VipPaymentScreen`. Firebase Analytics installed + thin `AnalyticsService` wrapper fires 7 events.

**Tech Stack:** Node.js / Express / Mongoose / MongoDB (backend); Flutter / Riverpod / flutter_riverpod / Firebase Analytics (mobile). No new vendor relationships — RevenueCat is NOT used; existing Apple App Store Server Notifications + Google Play RTDN webhooks stay as-is.

**Spec reference:** This plan is the spec. (No prior brainstorming spec — locked decisions were handed down directly from the product owner in the session that produced this plan.)

**Branches:** `feat/step13a-vip-gating` on both repos (`/Users/davis/Desktop/Personal/language_exchange_backend_application` and `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`).

**Estimated commits:** 10 (B1-B5 backend, F1-F4 Flutter, G1 glue).

**Pacing:** Drive uninterrupted through tasks per the user's recorded preference (`feedback_pacing.md`). Surface only at G1 or on a genuine blocker.

---

## File Structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Create:**
- `middleware/checkTutorQuota.js` — quota gate factory + the AI_QUOTA_ENABLED short-circuit
- `jobs/audioCacheOrphanPurgeJob.js` — mirror of `pronunciationAudioPurgeJob.js`, scoped to `AudioCache`

**Modify:**
- `models/User.js` — add 5 counter+reset field pairs to both `regularUserLimitations` and `visitorLimitations`; add `User.consumeQuota` static; add `User.getQuotasSnapshot` instance method
- `config/limitations.js` — add per-tier `tutorDailyQuotas` block; add `AI_QUOTA_ENABLED` env-var read
- `routes/tutor.js` — attach `checkTutorQuota(featureKey)` to the 5 chip trigger endpoints
- `controllers/tutor.js` — extend `getMyMemory` response to include `quotas` block; extend the 5 trigger handlers to attach `quotas` block to success response
- `jobs/scheduler.js` — register `scheduleAudioCacheOrphanPurge()` (2:15 AM KST so it doesn't collide with the 2:00 AM pronunciation purge)

**Reuse (no change):**
- `routes/purchases.js` + `controllers/iosPurchase.js` + `controllers/androidPurchase.js` — webhook pipeline stays as-is
- `jobs/subscriptionExpiryJob.js` — handles VIP expiry + grace period (no change)
- `services/storageService.js#deleteFromSpaces` — used by both purge jobs
- `models/AudioCache.js` — has the 90-day TTL already

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Create:**
- `lib/services/analytics_service.dart` — thin Firebase Analytics wrapper with 7 typed event methods
- `lib/providers/tutor_quota_provider.dart` — `StateNotifierProvider` holding the 5 chip counters
- `lib/widgets/tutor/tutor_quota_indicator.dart` — compact "N left today" pill widget; mirrors `VisitorUsageIndicator` compact view
- `lib/widgets/tutor/persona_upgrade_sheet.dart` — persona-aware variant of `VipUpgradeSheet` with Nana/Sensei/Riko copy

**Modify:**
- `pubspec.yaml` — add `firebase_analytics: ^11.0.0`
- `lib/main.dart` — initialize `FirebaseAnalytics.instance` in the existing Firebase init block
- `lib/services/api_client.dart` — extend `_handleResponse` 429 branch to detect `quota_exceeded` and call new `onQuotaExceeded` callback; add `isQuotaExceeded` getter + `quotaError` payload to `ApiResponse`
- `lib/pages/ai/tutor/tutor_chat_screen.dart` — show `TutorQuotaIndicator` once usage ≥ 50%
- `lib/pages/ai/tutor/pronunciation_session_screen.dart` — same
- `lib/pages/ai/tutor/scenario_picker_screen.dart` + `story_setup_screen.dart` + `image_vocab_screen.dart` — same (just the indicator; trigger is once per chip)
- `lib/pages/vip/vip_payment_screen.dart` — replace the success-path single invalidate with retry-with-backoff (3 attempts × ~2s)
- `lib/widgets/vip_locked_feature.dart` — keep existing `VipUpgradeSheet`; new persona sheet is a sibling
- `lib/main.dart` (or wherever ApiClient is initialized) — wire global `onQuotaExceeded` handler that opens `PersonaUpgradeSheet`

**Reuse (no change):**
- `lib/providers/provider_root/vip_provider.dart` — `vipStatusProvider` + `isVipProvider` stay
- `lib/services/api_client.dart` ApiResponse class structure
- `lib/widgets/visitor_usage_indicator.dart` — the compact view pattern; copied, not extended (so the visitor flow stays untouched)

---

## Critical decisions made in this plan

1. **Atomic check-and-increment via pipeline update.** Existing `User.incrementMessageCount` uses synchronous `this.field += 1; this.save()` — race-prone if two devices hit at the same moment. For the new quotas we **establish a new atomic pattern** via `findOneAndUpdate({_id, $expr}, [pipeline])` so concurrent requests can't double-increment past the cap. Documented in B2; existing helpers are NOT refactored in this wave.

2. **Pre-increment in middleware, not post-success in controller.** The atomic op combines check + increment in one DB round trip — there's no clean way to "check now, increment later" while preserving atomicity. So the count goes up the moment the request enters the controller. **If the downstream AI call fails, we do NOT decrement.** Rationale: decrementing on failure re-opens abuse (spam-fail loops), and well-behaved users with rare AI failures will see at most ~1 lost slot/day.

3. **UTC daily reset, not user-local midnight.** Matches existing `messagesSentToday` pattern. The `User.quietHours.timezone` field stays unused for this wave. Flagged as a v2 enhancement in `docs/manual-todos.md` if users complain.

4. **`AI_QUOTA_ENABLED=false` is a full bypass, not a "fail-open."** When the env var is unset OR `'false'`, `checkTutorQuota` calls `next()` without touching the DB. No counter increment, no cap check. Treats the entire quota system as feature-flagged.

5. **Server is single source of truth for daily reset.** Client never decides "is it a new day." `User.consumeQuota` computes UTC midnight server-side. Client receives `quotas: {chat: {used, cap, resetAt}, ...}` in responses.

6. **VIP path = early return.** `User.consumeQuota` short-circuits when `userMode === 'vip' && isVipActive`: returns `{allowed: true, used: 0, cap: Infinity, resetAt: null}` without touching counters. VIP users get zero DB write cost on AI calls.

7. **AudioCache orphan purge bundled here.** Was queued in `manual-todos.md`. Mirroring `pronunciationAudioPurgeJob.js` is trivial enough to fold in. Removes the item from the queued-engineering list in the same commit.

---

## Task 0: Branch setup

**Files:** none

- [ ] **Step 1: Create branches on both repos.**

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

Identical fields, identical names. (Existing visitor counters use slightly different naming like `messagesSent` without `Today` — but for the tutor counters keep the `Today` suffix in both blocks for consistency with the new pattern.)

- [ ] **Step 3: Verify syntax.**

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

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task B2: Atomic `User.consumeQuota` static + getQuotasSnapshot instance method

**Files:**
- Modify: `models/User.js`

- [ ] **Step 1: Add the field-key map at the top of the file (after the existing requires).**

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
```

- [ ] **Step 2: Add the `consumeQuota` static method.**

At the bottom of `User.js`, before `module.exports`, add:

```javascript
/**
 * Atomic check-and-increment for a tutor-chip quota.
 *
 * VIP users with an active subscription short-circuit with allowed=true
 * and no DB write. Regular and visitor users hit an atomic
 * findOneAndUpdate with a pipeline update that:
 *   - resets the counter to 1 if lastReset is before today's UTC midnight
 *   - else increments the counter if it's below the cap
 *   - else fails the filter and returns null (quota exhausted)
 *
 * @param {String} userId
 * @param {String} featureKey  one of 'chat'|'roleplay'|'story'|'photo'|'pronunciation'
 * @returns {Promise<{allowed: boolean, used: number, cap: number, resetAt: Date|null}>}
 */
UserSchema.statics.consumeQuota = async function(userId, featureKey) {
  const LIMITS = require('../config/limitations');
  const fields = TUTOR_QUOTA_FIELDS[featureKey];
  if (!fields) throw new Error(`Unknown featureKey: ${featureKey}`);

  // Compute today's UTC midnight + tomorrow's UTC midnight for resetAt.
  const now = new Date();
  const startOfTodayUTC = new Date(Date.UTC(
    now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()
  ));
  const startOfTomorrowUTC = new Date(startOfTodayUTC.getTime() + 24 * 60 * 60 * 1000);

  // First, a cheap read to determine tier + check VIP active. We need the
  // tier before we know which cap applies. Read just the fields we need.
  const user = await this.findById(userId)
    .select('userMode vipSubscription.isActive vipSubscription.endDate')
    .lean();
  if (!user) {
    return { allowed: false, used: 0, cap: 0, resetAt: startOfTomorrowUTC };
  }

  // VIP fast path — no DB write, no counter touch.
  if (user.userMode === 'vip'
      && user.vipSubscription?.isActive
      && user.vipSubscription?.endDate
      && new Date(user.vipSubscription.endDate) > now) {
    return { allowed: true, used: 0, cap: Infinity, resetAt: null };
  }

  // Determine tier + cap. visitor and regular both consume the same
  // schema sub-doc shape; just different field names + caps.
  const tier = user.userMode === 'visitor' ? 'visitor' : 'regular';
  const tierLimits = LIMITS[tier]?.tutorDailyQuotas || {};
  const cap = tierLimits[featureKey];
  if (cap === undefined || cap === null) {
    // No cap configured for this tier+feature — fail closed.
    return { allowed: false, used: 0, cap: 0, resetAt: startOfTomorrowUTC };
  }
  if (cap === -1 || cap === Infinity) {
    // Sentinel for unlimited — allow without touching counter.
    return { allowed: true, used: 0, cap: Infinity, resetAt: null };
  }

  const limitationsPath = tier === 'visitor' ? 'visitorLimitations' : 'regularUserLimitations';
  const counterPath = `${limitationsPath}.${fields.counter}`;
  const resetPath = `${limitationsPath}.${fields.reset}`;

  // Atomic check-and-increment.
  const updated = await this.findOneAndUpdate(
    {
      _id: userId,
      $expr: {
        $or: [
          { $lt: [`$${resetPath}`, startOfTodayUTC] }, // stale → will reset to 1
          { $lt: [{ $ifNull: [`$${counterPath}`, 0] }, cap] }, // under cap → increment
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
    { new: true, projection: { [counterPath]: 1, [resetPath]: 1 } }
  );

  if (!updated) {
    // Filter didn't match → cap is hit and we're not in a new day.
    return { allowed: false, used: cap, cap, resetAt: startOfTomorrowUTC };
  }

  const used = updated.get(counterPath);
  return { allowed: true, used, cap, resetAt: startOfTomorrowUTC };
};
```

- [ ] **Step 3: Add the `getQuotasSnapshot` instance method.**

Returns the current state of all 5 quotas in one shot — used by `/tutor/me` and by controllers to attach `quotas` to response bodies.

```javascript
/**
 * Snapshot of all 5 tutor chip quotas for this user.
 * Does NOT mutate counters; pure read. Computes resetAt and remaining
 * fresh from the stored counters.
 */
UserSchema.methods.getQuotasSnapshot = function() {
  const LIMITS = require('../config/limitations');

  const now = new Date();
  const startOfTodayUTC = new Date(Date.UTC(
    now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()
  ));
  const startOfTomorrowUTC = new Date(startOfTodayUTC.getTime() + 24 * 60 * 60 * 1000);

  // VIP → all unlimited, no counters relevant.
  const isVipActive = this.userMode === 'vip'
    && this.vipSubscription?.isActive
    && this.vipSubscription?.endDate
    && new Date(this.vipSubscription.endDate) > now;
  if (isVipActive) {
    return Object.fromEntries(
      Object.keys(TUTOR_QUOTA_FIELDS).map(k => [k, {
        used: 0, cap: null, remaining: null, resetAt: null, unlimited: true,
      }])
    );
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

- [ ] **Step 4: Verify syntax.**

```bash
node -c models/User.js
```

- [ ] **Step 5: Commit.**

```bash
git add models/User.js
git commit -m "$(cat <<'EOF'
feat(vip): atomic consumeQuota static + getQuotasSnapshot helper

User.consumeQuota does atomic check-and-increment in one round
trip via findOneAndUpdate + $expr filter + pipeline update. If
two devices hit concurrently, the second one's filter fails
(counter already at cap from the first) and gets allowed=false
without double-incrementing.

VIP active users short-circuit with allowed=true and zero DB
writes. Visitor and regular tiers share the same schema sub-doc
shape, just different field names + caps.

User.getQuotasSnapshot returns a pure read of all 5 quota states
for use by /tutor/me and controller response augmentation. Honors
the same UTC-daily-reset semantics without mutating counters.

NOTE: established a new race-safe pattern. Existing helpers like
incrementMessageCount still use the older sync pattern — not
refactored in this wave.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task B3: limitations.js caps + AI_QUOTA_ENABLED env + middleware

**Files:**
- Modify: `config/limitations.js`
- Create: `middleware/checkTutorQuota.js`

- [ ] **Step 1: Add `tutorDailyQuotas` block to each tier in `config/limitations.js`.**

Inside each tier object (`visitor`, `regular`, `vip`), add:

```javascript
  tutorDailyQuotas: {
    chat:          /* tier-specific value, see below */,
    roleplay:      /* tier-specific value */,
    story:         /* tier-specific value */,
    photo:         /* tier-specific value */,
    pronunciation: /* tier-specific value */,
  },
```

**Values per tier (locked):**

| Chip | visitor | regular | vip |
|---|---|---|---|
| chat | 3 | 10 | -1 (unlimited) |
| roleplay | 0 | 1 | -1 |
| story | 0 | 1 | -1 |
| photo | 0 | 2 | -1 |
| pronunciation | 0 | 1 | -1 |

`-1` is the existing sentinel for "unlimited" — `User.consumeQuota` already treats it that way.

- [ ] **Step 2: Add the feature flag read.**

Anywhere near the top of `config/limitations.js`, export:

```javascript
// Emergency kill switch. When false (or unset), the new tutor-quota
// middleware short-circuits to next() with no DB write and no check.
// Use to disable quota enforcement during incidents without a deploy.
exports.AI_QUOTA_ENABLED = String(process.env.AI_QUOTA_ENABLED || 'true').toLowerCase() === 'true';
```

Note the default `'true'`: once this lands, the gate is ON by default. Set `AI_QUOTA_ENABLED=false` in `.env` to disable.

- [ ] **Step 3: Create the middleware.**

`middleware/checkTutorQuota.js`:

```javascript
const asyncHandler = require('./async');
const User = require('../models/User');
const { AI_QUOTA_ENABLED } = require('../config/limitations');

/**
 * Express middleware factory. Returns a middleware that atomically
 * checks-and-increments the per-user daily quota for the given tutor
 * feature. On cap-hit returns:
 *
 *   429 {
 *     success: false,
 *     error: 'quota_exceeded',
 *     feature: <featureKey>,
 *     resetAt: <UTC ISO timestamp>,
 *     message: <user-facing copy>,
 *     upgradeAvailable: true,
 *   }
 *
 * Flutter's ApiClient detects this shape and routes to the persona
 * paywall instead of the generic rate-limit dialog.
 *
 * Bypasses entirely when AI_QUOTA_ENABLED is false (emergency kill).
 * Admin users always bypass.
 *
 * @param {String} featureKey  'chat'|'roleplay'|'story'|'photo'|'pronunciation'
 */
const checkTutorQuota = (featureKey) => asyncHandler(async (req, res, next) => {
  if (!AI_QUOTA_ENABLED) return next();
  if (req.user?.role === 'admin') return next();
  if (!req.user?.id) return next(); // protect should have caught this, but fail safe

  const result = await User.consumeQuota(req.user.id, featureKey);

  if (!result.allowed) {
    return res.status(429).json({
      success: false,
      error: 'quota_exceeded',
      feature: featureKey,
      resetAt: result.resetAt?.toISOString() || null,
      message: "You've used today's free quota for this feature. Upgrade to keep going.",
      upgradeAvailable: true,
    });
  }

  // Stash for controllers that want to attach updated quotas to their
  // 200 response without re-querying.
  req.tutorQuotaResult = { ...result, feature: featureKey };
  next();
});

module.exports = { checkTutorQuota };
```

- [ ] **Step 4: Add `AI_QUOTA_ENABLED` to `.env.example` (if it exists).**

```bash
ls .env.example 2>/dev/null && echo "exists" || echo "absent — skip"
```

If present, append:
```
# Step 13A: gate the 5 AI tutor chips with per-user daily quotas.
# Set to 'false' to disable enforcement (counters still increment).
AI_QUOTA_ENABLED=true
```

If absent, just document in commit message that operators must set this in their `.env`.

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

New middleware/checkTutorQuota.js factory wraps User.consumeQuota
in an Express middleware. Returns the documented 429 quota_exceeded
shape on cap-hit so the Flutter client can route to the persona
paywall.

AI_QUOTA_ENABLED env var (default true) short-circuits the middleware
to next() when set to 'false'. Emergency kill switch — no deploy
needed to disable enforcement.

Admin users always bypass.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task B4: Wire middleware to 5 routes + augment responses with `quotas`

**Files:**
- Modify: `routes/tutor.js`
- Modify: `controllers/tutor.js`

- [ ] **Step 1: Attach `checkTutorQuota(featureKey)` to the 5 chip trigger routes in `routes/tutor.js`.**

Add to the destructured imports at top:

```javascript
const { checkTutorQuota } = require('../middleware/checkTutorQuota');
```

Then on each of the 5 trigger routes, insert `checkTutorQuota(...)` between `protect` (already applied via `router.use`) and the existing middleware/handler. **Trigger points per locked decision:**

```javascript
// Chat: count at message-send
router.post('/sessions/:id/message', checkTutorQuota('chat'), tutorMessageLimiter, sendMessage);

// Roleplay: count at session-start
router.post('/sessions/roleplay', checkTutorQuota('roleplay'), startRoleplaySession);

// Story: count at generation
router.post('/stories/generate', checkTutorQuota('story'), generateStory);

// Photo: count at describe (the entry point; grade reuses the same upload)
router.post('/image-vocab/describe', checkTutorQuota('photo'), imageUpload.single('image'), imageVocabDescribe);

// Pronounce: count at summary-save (the end-of-session action; matches "1 drill = 1 quota tick")
router.post('/pronunciation/summary', checkTutorQuota('pronunciation'), submitPronunciationSummary);
```

**Note: `/image-vocab/grade` is NOT gated.** Per the brief, photo counts at describe-success. Grade is the follow-up action on the same uploaded image — counting it again would double-count one photo session.

- [ ] **Step 2: Augment `getMyMemory` to include quotas snapshot.**

In `controllers/tutor.js`, find `exports.getMyMemory` (lines ~47-50). Replace with:

```javascript
exports.getMyMemory = asyncHandler(async (req, res) => {
  const mem = await ensureMemory(req.user._id);
  const user = await User.findById(req.user._id).select(
    'userMode regularUserLimitations visitorLimitations vipSubscription.isActive vipSubscription.endDate'
  );
  const quotas = user ? user.getQuotasSnapshot() : null;
  res.status(200).json({
    success: true,
    data: mem,
    quotas,
  });
});
```

(`User` must already be required at top of `controllers/tutor.js` — confirm before editing. If not, add `const User = require('../models/User');`.)

- [ ] **Step 3: Augment the 5 trigger handlers to include updated `quotas` in their 200/201 responses.**

For each of the 5 trigger handlers (`sendMessage`, `startRoleplaySession`, `generateStory`, `imageVocabDescribe`, `submitPronunciationSummary`), find the success `res.status(...).json({ success: true, data: ... })` line and add a `quotas` field. Pattern:

```javascript
// At the end of the successful handler, just before res.json:
let quotas = null;
if (req.tutorQuotaResult) {
  // Cheap: re-snapshot the user since consumeQuota already wrote.
  const fresh = await User.findById(req.user._id).select(
    'userMode regularUserLimitations visitorLimitations vipSubscription.isActive vipSubscription.endDate'
  );
  quotas = fresh ? fresh.getQuotasSnapshot() : null;
}
res.status(200).json({ success: true, data: <existing-data>, quotas });
```

The `quotas` field is `null` when the route wasn't gated (e.g., legacy routes) or when AI_QUOTA_ENABLED was off.

This adds one extra DB round-trip per AI call. Acceptable: the call already takes 2-5s for the OpenAI hop, +20ms for a projected user-find is invisible.

- [ ] **Step 4: Verify.**

```bash
node -c routes/tutor.js && node -c controllers/tutor.js
```

- [ ] **Step 5: Smoke test via curl.**

```bash
TOKEN="<paste a regular-tier user token>"
# First call — should succeed and include quotas in response
curl -s -X POST https://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '.quotas.pronunciation'
# Expected: { "used": 1, "cap": 1, "remaining": 0, "resetAt": "...", "unlimited": false }

# Second call — should 429 with quota_exceeded
curl -s -X POST https://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq
# Expected: { "success": false, "error": "quota_exceeded", "feature": "pronunciation", ... }
```

- [ ] **Step 6: Commit.**

```bash
git add routes/tutor.js controllers/tutor.js
git commit -m "$(cat <<'EOF'
feat(vip): gate 5 tutor chip endpoints + return quotas in responses

Trigger points per locked product decision:
  Chat          → POST /sessions/:id/message
  Roleplay      → POST /sessions/roleplay
  Story         → POST /stories/generate
  Photo         → POST /image-vocab/describe (NOT /grade — same session)
  Pronounce     → POST /pronunciation/summary

Each route gets checkTutorQuota('<key>') ahead of its handler. On
cap-hit the middleware responds 429 quota_exceeded; on allowed
the controller adds the fresh quotas snapshot to its 200 response
so the client can update the counter UI without a separate fetch.

GET /tutor/me also returns the quotas block so the AI Study tab
shows accurate counters on first load.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task B5: AudioCache orphan-blob purge job

**Files:**
- Create: `jobs/audioCacheOrphanPurgeJob.js`
- Modify: `jobs/scheduler.js`
- Modify (cross-repo): `bananatalk_app/docs/manual-todos.md` (separate commit on Flutter — done in F4 or G1; backend commit just creates the job)

- [ ] **Step 1: Create the purge job.**

`jobs/audioCacheOrphanPurgeJob.js`:

```javascript
/**
 * AudioCache Orphan-Blob Purge Job
 *
 * Mirror of jobs/pronunciationAudioPurgeJob.js but scoped to the
 * AudioCache collection (TTS audio caching).
 *
 * AudioCache has a 90-day Mongo TTL on lastAccessedAt — Mongo
 * auto-drops the metadata record. This job runs ~3 days before the
 * TTL fires and deletes the underlying Spaces blob so the audio is
 * gone BEFORE the URL disappears (no orphaned blobs).
 *
 * Idempotency: once audioUrl is set to null, subsequent runs skip
 * the record. Safe to retry.
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

Find the existing `schedulePronunciationAudioPurge` block (around line 343-368). Add a parallel scheduler function:

```javascript
const { purgeAudioCacheOrphans } = require('./audioCacheOrphanPurgeJob');

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

  // 2:15 AM KST so it doesn't collide with the 2:00 AM pronunciation purge
  const msUntilNextRun = getMillisecondsUntil(2, 15);
  console.log(`📅 AudioCache orphan purge scheduled in ${Math.round(msUntilNextRun / 1000 / 60 / 60)} hours`);
  setTimeout(runJob, msUntilNextRun);
};
```

Then inside `startScheduler()` (around line 418, right after `schedulePronunciationAudioPurge()`):

```javascript
  schedulePronunciationAudioPurge();
  scheduleAudioCacheOrphanPurge();   // <-- NEW
```

- [ ] **Step 3: Verify.**

```bash
node -c jobs/audioCacheOrphanPurgeJob.js && node -c jobs/scheduler.js && npm test 2>&1 | tail -3
```

Existing 15 pronunciation-scoring tests should still pass.

- [ ] **Step 4: Commit.**

```bash
git add jobs/audioCacheOrphanPurgeJob.js jobs/scheduler.js
git commit -m "$(cat <<'EOF'
feat(privacy): AudioCache orphan-blob purge job

Mirrors jobs/pronunciationAudioPurgeJob.js. AudioCache has a 90-day
Mongo TTL on lastAccessedAt; without a Spaces cleanup job the
underlying mp3 blobs persist indefinitely. New
jobs/audioCacheOrphanPurgeJob.js runs nightly at 2:15 AM KST,
finds records older than 87 days with audioUrl still set,
deletes the Spaces blob and nulls the URL.

Idempotent, batch-capped, slot-staggered 15 minutes after the
pronunciation purge to avoid simultaneous bursts.

Closes the queued-engineering item from docs/manual-todos.md
(cleanup landed in the Flutter doc commit).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task F1: ApiClient `quota_exceeded` detection + `onQuotaExceeded` callback

**Files:**
- Modify: `lib/services/api_client.dart`

Working dir: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

- [ ] **Step 1: Extend the `ApiClient` constructor + class fields to accept `onQuotaExceeded`.**

Find the existing callback fields (search for `onRateLimitError`). Add a parallel:

```dart
/// Called when the server returns 429 with body.error == 'quota_exceeded'.
/// Distinct from onRateLimitError — quota exhaustion routes to the
/// paywall, generic rate limit shows a toast.
final void Function(QuotaError quotaError)? onQuotaExceeded;
```

Add to the constructor's param list + initialization.

- [ ] **Step 2: Add the `QuotaError` data class.**

Near the bottom of the file (with the other ApiResponse helper classes):

```dart
class QuotaError {
  final String feature;       // 'chat'|'roleplay'|'story'|'photo'|'pronunciation'
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

- [ ] **Step 3: Extend `ApiResponse`.**

Add a `quotaError` field + `isQuotaExceeded` getter:

```dart
class ApiResponse {
  // ... existing fields ...
  final QuotaError? quotaError;

  // ... existing getters ...
  bool get isQuotaExceeded => statusCode == 429 && quotaError != null;

  ApiResponse({
    // existing params
    this.quotaError,
  });
}
```

- [ ] **Step 4: Modify the 429 branch in `_handleResponse` (around line 263-272).**

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
  // Two flavors of 429: standard rate limit (per-minute throttle) vs.
  // daily quota exhaustion (specific to the AI tutor chips).
  if (body['error'] == 'quota_exceeded') {
    final qe = QuotaError.fromJson(Map<String, dynamic>.from(body));
    onQuotaExceeded?.call(qe);
    return ApiResponse(
      success: false,
      error: qe.message,
      statusCode: 429,
      quotaError: qe,
    );
  }
  final errorMessage = body['error'] ?? 'Too many requests. Please slow down.';
  onRateLimitError?.call(_getReadableRateLimitError(errorMessage));
  return ApiResponse(
    success: false,
    error: _getReadableRateLimitError(errorMessage),
    statusCode: 429,
    rateLimitInfo: _rateLimits[endpoint],
  );
```

- [ ] **Step 5: Analyze.**

```bash
flutter analyze lib/services/api_client.dart 2>&1 | tail -3
```

Expected: `No issues found!`

- [ ] **Step 6: Commit.**

```bash
git add lib/services/api_client.dart
git commit -m "$(cat <<'EOF'
feat(vip): ApiClient detects 429 quota_exceeded and routes to paywall

Two 429 flavors now distinguished by body.error:
  'quota_exceeded' → onQuotaExceeded callback (paywall)
  anything else    → onRateLimitError callback (toast, unchanged)

New QuotaError data class carries feature, resetAt, message,
upgradeAvailable. ApiResponse gains an isQuotaExceeded getter
+ quotaError field for call sites that want to handle the
case locally rather than through the global callback.

Global wiring of onQuotaExceeded lands in F4 alongside the
persona-aware paywall sheet.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task F2: Firebase Analytics + AnalyticsService wrapper

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `lib/services/analytics_service.dart`

- [ ] **Step 1: Add `firebase_analytics` to dependencies.**

In `pubspec.yaml`, in the `# Firebase & Notifications` section right after `firebase_messaging`:

```yaml
  firebase_analytics: ^11.0.0
```

Run:

```bash
flutter pub get
```

Expected: no errors. (If version pinning is fragile, drop the caret and pin exactly to whatever firebase_core ^3.0.0 resolves to.)

- [ ] **Step 2: Initialize in `lib/main.dart`.**

In the existing Firebase init block (lines ~37-46), after `await Firebase.initializeApp();`, add:

```dart
    // Step 13A: Analytics. Initialized after Firebase.initializeApp().
    // No collection until the user gives consent? — App is already
    // collecting tokens for messaging, so analytics fits the same
    // posture. Privacy policy update in docs/manual-todos.md covers this.
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
```

Add the import at the top of `main.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
```

- [ ] **Step 3: Create the AnalyticsService wrapper.**

`lib/services/analytics_service.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin Firebase Analytics wrapper for Step 13A VIP-gating events.
/// Methods are typed and intent-named so call sites can't misspell
/// event names or forget required params.
///
/// All methods are async-fire-and-forget; we never await analytics
/// from the UI thread. If a call fails (analytics SDK error, no
/// network), debug-print and move on — never block the user.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  Future<void> _log(String name, Map<String, Object?> params) async {
    try {
      // Firebase Analytics rejects null param values; drop them.
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

- [ ] **Step 4: Verify.**

```bash
flutter pub get && flutter analyze lib/services/analytics_service.dart lib/main.dart 2>&1 | tail -3
```

- [ ] **Step 5: Commit.**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/services/analytics_service.dart
git commit -m "$(cat <<'EOF'
feat(analytics): Firebase Analytics + typed AnalyticsService wrapper

Adds firebase_analytics ^11.0.0 (companion to existing firebase_core
+ firebase_messaging). Initialized once in main.dart's Firebase
block; collection enabled by default.

lib/services/analytics_service.dart wraps FirebaseAnalytics in a
singleton with 7 typed methods, one per Step 13A event:
  tutor_chip_used / quota_remaining_shown / quota_hit /
  paywall_shown / paywall_cta_tapped /
  subscription_purchased / subscription_purchase_failed

All methods are async-fire-and-forget — analytics never blocks UI.
SDK errors are debug-printed and swallowed.

Event firing in subsequent commits (F3 + F4).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task F3: Tutor quota state + counter UI widget + wire into chip screens

**Files:**
- Create: `lib/providers/tutor_quota_provider.dart`
- Create: `lib/widgets/tutor/tutor_quota_indicator.dart`
- Modify: `lib/pages/ai/tutor/tutor_chat_screen.dart`
- Modify: `lib/pages/ai/tutor/pronunciation_session_screen.dart`
- Modify: `lib/pages/ai/tutor/scenario_picker_screen.dart`
- Modify: `lib/pages/ai/tutor/story_setup_screen.dart`
- Modify: `lib/pages/ai/tutor/image_vocab_screen.dart`

- [ ] **Step 1: Create the quota provider.**

`lib/providers/tutor_quota_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// Per-chip daily quota state. Updated from API response bodies
/// (the backend includes a `quotas` block on /tutor/me and on the
/// 5 trigger endpoints' success responses).
class TutorQuotaInfo {
  final int used;
  final int? cap;          // null when unlimited (VIP)
  final int? remaining;    // null when unlimited
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

  /// True once the user has hit 50% of their cap (used for triggering
  /// the counter UI). Always false for unlimited.
  bool get shouldShowIndicator {
    if (unlimited || cap == null || cap == 0) return false;
    return used * 2 >= cap!; // used >= cap/2, integer-safe
  }
}

class TutorQuotaState {
  final TutorQuotaInfo? chat;
  final TutorQuotaInfo? roleplay;
  final TutorQuotaInfo? story;
  final TutorQuotaInfo? photo;
  final TutorQuotaInfo? pronunciation;

  const TutorQuotaState({this.chat, this.roleplay, this.story, this.photo, this.pronunciation});

  TutorQuotaInfo? get(String key) {
    switch (key) {
      case 'chat': return chat;
      case 'roleplay': return roleplay;
      case 'story': return story;
      case 'photo': return photo;
      case 'pronunciation': return pronunciation;
      default: return null;
    }
  }

  TutorQuotaState copyWithFromMap(Map<String, dynamic>? quotasJson) {
    if (quotasJson == null) return this;
    TutorQuotaInfo? parse(String k) {
      final v = quotasJson[k];
      return v is Map<String, dynamic> ? TutorQuotaInfo.fromJson(v) : null;
    }
    return TutorQuotaState(
      chat:          parse('chat')          ?? chat,
      roleplay:      parse('roleplay')      ?? roleplay,
      story:         parse('story')         ?? story,
      photo:         parse('photo')         ?? photo,
      pronunciation: parse('pronunciation') ?? pronunciation,
    );
  }
}

class TutorQuotaController extends StateNotifier<TutorQuotaState> {
  TutorQuotaController() : super(const TutorQuotaState());

  // Track which chips have already fired the quota_remaining_shown
  // analytics event today so we don't double-fire on every screen
  // build past the 50% threshold.
  final Set<String> _shownToday = {};

  /// Merge in a `quotas` payload from any API response.
  void updateFrom(Map<String, dynamic>? quotasJson) {
    if (quotasJson == null) return;
    final next = state.copyWithFromMap(quotasJson);
    state = next;

    // Fire quota_remaining_shown once per chip per session when
    // crossing the 50% threshold.
    for (final key in ['chat', 'roleplay', 'story', 'photo', 'pronunciation']) {
      final info = next.get(key);
      if (info != null && info.shouldShowIndicator && !_shownToday.contains(key)) {
        _shownToday.add(key);
        AnalyticsService.instance.quotaRemainingShown(
          chipName: key,
          remainingCount: info.remaining ?? 0,
        );
      }
    }
  }
}

final tutorQuotaProvider =
    StateNotifierProvider<TutorQuotaController, TutorQuotaState>(
  (_) => TutorQuotaController(),
);
```

- [ ] **Step 2: Hook ApiClient responses to update the provider.**

The cleanest place is wherever responses are first received. Two options: extend ApiClient with a hook, or extract `quotas` at each call site. **Decision:** add a single global hook in `lib/main.dart` (or wherever ApiClient is constructed) that the tutor service methods can call. Simpler change: extract at the call site in `lib/providers/tutor_provider.dart`'s `TutorService` methods.

Find each of these methods in `TutorService` (in `lib/providers/tutor_provider.dart`) and after the existing `_dataObj(res.data)` extraction, also call:

```dart
// In each tutor service method that gates a chip (sendMessage,
// startRoleplay, generateStory, image-vocab describe, submitSummary,
// getMemory):
final rawBody = res.data is Map ? res.data as Map<String, dynamic> : null;
final quotasJson = rawBody?['quotas'];
// Push to provider via a callback the caller has wired. Easiest:
// the controller that called the service does the dispatch:
//   ref.read(tutorQuotaProvider.notifier).updateFrom(quotasJson);
```

Because `TutorService` is a plain class (not a ConsumerWidget), it can't access Riverpod directly. The **clean pattern**: have each method return a `(result, quotas)` tuple — or extend `ApiResponse` with a `quotas` getter. Since we already control `ApiResponse`, that's simpler. Actually simplest of all: **the controllers that call these services** are already Riverpod-aware, so they can read `res.data['quotas']` once they have the raw response.

For this plan: add a generic `quotas` extractor on `ApiResponse`:

```dart
// In api_client.dart, ApiResponse class:
Map<String, dynamic>? get quotas {
  if (data is Map) {
    final m = data as Map;
    if (m['quotas'] is Map) return Map<String, dynamic>.from(m['quotas']);
  }
  return null;
}
```

(Wait — `_handleResponse` extracts `data` from `body['data']` already. So `quotas` lives at the body level, not inside data. Need to verify in B4 that the backend response shape is `{success, data: {...}, quotas: {...}}` not nested. ✅ confirmed in B4 step 2.)

The provider call site lives in each controller. Add this snippet to `TutorChatController.send` (in `lib/providers/tutor_provider.dart`) and the parallel methods in `PronunciationController` and any other controllers that hit the gated endpoints:

```dart
// Just before _safeSet on success path:
ref.read(tutorQuotaProvider.notifier).updateFrom(res.quotas);
```

(`ref` here is the controller's stored `Ref` — for StateNotifier-based controllers, store a `Ref` in the constructor.)

**Note:** retrofitting `Ref` into existing controllers might be invasive. Simpler retrofit: have the `TutorService` static methods return the raw `ApiResponse` (or expose `lastQuotas` as a stream), and the screen `ConsumerStatefulWidget` that called the controller reads quotas separately by watching `/tutor/me`.

For this plan, choose the cleanest: **The controllers stay unchanged. The screens that show the chip UI directly fetch `/tutor/me` via a provider when needed**, OR after a successful action they invalidate a `tutorMemoryProvider` to re-fetch including the fresh quotas block. This is a tiny extra HTTP round-trip (~50ms) but keeps the change contained.

Specifically: extend `tutorMemoryProvider` (FutureProvider) in `tutor_provider.dart` so its response includes the quotas, and the new `tutorQuotaProvider` reads from `tutorMemoryProvider` instead of being a StateNotifier. Simpler. Replace the StateNotifier above with:

```dart
final tutorQuotaProvider = Provider<TutorQuotaState>((ref) {
  final memAsync = ref.watch(tutorMemoryProvider);
  return memAsync.when(
    data: (mem) {
      // tutorMemoryProvider needs to be extended to return both memory
      // and quotas; OR a sibling tutorQuotasResponseProvider could carry
      // just the quotas. The simplest: extend the existing service
      // method getMemory() to also call a new getQuotas() endpoint OR
      // return a tuple.
      // For this plan: revisit the data model. See note below.
      return const TutorQuotaState();
    },
    loading: () => const TutorQuotaState(),
    error: (_, __) => const TutorQuotaState(),
  );
});
```

**OK, the cleanest data path:**

1. Backend `/tutor/me` returns `{success, data: <memory>, quotas: <snapshot>}` — already designed in B4.
2. Modify `TutorService.getMemory` to return a record/tuple `(TutorMemory, Map<String, dynamic>? quotas)` OR a wrapper class. The cleanest in Dart 3 is a record:

```dart
// In TutorService:
Future<({TutorMemory memory, Map<String, dynamic>? quotas})> getMemory() async {
  final res = await _api.get('tutor/me');
  if (!res.success || res.data == null) {
    throw StateError(res.error ?? 'Failed to load tutor memory');
  }
  return (
    memory: TutorMemory.fromJson(_dataObj(res.data)),
    quotas: res.quotas,
  );
}
```

3. Modify `tutorMemoryProvider` to use this and feed both into separate providers:

```dart
final _tutorMemoryAndQuotasProvider = FutureProvider.autoDispose<
    ({TutorMemory memory, Map<String, dynamic>? quotas})>((ref) {
  return ref.read(tutorServiceProvider).getMemory();
});

final tutorMemoryProvider = FutureProvider<TutorMemory>((ref) async {
  final result = await ref.watch(_tutorMemoryAndQuotasProvider.future);
  return result.memory;
});

final tutorQuotaProvider = Provider<TutorQuotaState>((ref) {
  final asyncResult = ref.watch(_tutorMemoryAndQuotasProvider);
  return asyncResult.maybeWhen(
    data: (r) => const TutorQuotaState().copyWithFromMap(r.quotas),
    orElse: () => const TutorQuotaState(),
  );
});
```

And to refresh after a successful action, the controller invalidates the private `_tutorMemoryAndQuotasProvider`:

```dart
ref.invalidate(_tutorMemoryAndQuotasProvider);
```

This is the cleanest path for this plan. Use this approach.

- [ ] **Step 3: Wire invalidation in each of the 5 controllers after successful gated actions.**

For each successful response on a gated endpoint (Chat send, Roleplay start, Story generate, Photo describe, Pronounce summary), add right after the success state update:

```dart
ref.invalidate(_tutorMemoryAndQuotasProvider);
```

(Add a `Ref` to the controller's constructor if it doesn't have one. Existing controllers like `TutorChatController` already take a `Ref` indirectly via the provider builder — check before adding.)

- [ ] **Step 4: Create the indicator widget.**

`lib/widgets/tutor/tutor_quota_indicator.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Compact pill widget showing "N left today" for one tutor chip's quota.
/// Renders nothing when the user is VIP (unlimited) or below the 50%
/// threshold. Mirrors the style of VisitorUsageIndicator.compact.
class TutorQuotaIndicator extends ConsumerWidget {
  /// 'chat'|'roleplay'|'story'|'photo'|'pronunciation'
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

Add the l10n key to `lib/l10n/app_en.arb`:

```json
"aiTutorQuotaRemaining": "{count, plural, =1{1 left today} other{{count} left today}}",
"@aiTutorQuotaRemaining": {
  "description": "Daily quota counter pill on tutor chip screens",
  "placeholders": { "count": {"type": "int"} }
}
```

- [ ] **Step 5: Wire the indicator into the 5 chip screens.**

For each of `tutor_chat_screen.dart`, `pronunciation_session_screen.dart`, `scenario_picker_screen.dart`, `story_setup_screen.dart`, `image_vocab_screen.dart`: add `TutorQuotaIndicator(featureKey: '<key>')` to the AppBar's `actions:` list (or wherever fits the screen's layout — for Pronounce it's already a busy AppBar; insert before the existing volume icon).

- [ ] **Step 6: Verify.**

```bash
flutter gen-l10n && flutter analyze lib/providers/tutor_quota_provider.dart lib/widgets/tutor/tutor_quota_indicator.dart 2>&1 | tail -3
```

- [ ] **Step 7: Commit.**

```bash
git add lib/providers/tutor_quota_provider.dart lib/widgets/tutor/tutor_quota_indicator.dart lib/providers/tutor_provider.dart lib/pages/ai/tutor/ lib/l10n/
git commit -m "$(cat <<'EOF'
feat(vip): tutor quota state + "N left today" indicator on 5 chips

TutorService.getMemory now returns a record (memory, quotas).
A private _tutorMemoryAndQuotasProvider feeds the existing
tutorMemoryProvider and a new tutorQuotaProvider in parallel —
so re-fetching the memory also refreshes the quotas without
adding an extra HTTP round-trip.

After each successful gated action (Chat send / Roleplay start /
Story generate / Photo describe / Pronounce summary), the
controller invalidates the private provider so the AppBar
indicator updates to the post-increment value.

TutorQuotaIndicator (compact pill) renders only once a chip
crosses 50% used. Hides entirely for VIP. Mirrors the existing
VisitorUsageIndicator.compact style. Crossing 50% also fires
the quota_remaining_shown analytics event once per chip per
session (deduped in TutorQuotaController).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task F4: Persona-aware paywall + global wiring + webhook race fix + analytics events

**Files:**
- Create: `lib/widgets/tutor/persona_upgrade_sheet.dart`
- Modify: `lib/main.dart` (or wherever ApiClient is constructed; wire `onQuotaExceeded`)
- Modify: `lib/pages/vip/vip_payment_screen.dart` (retry-with-backoff)
- Modify: `lib/pages/ai/tutor/*` chip screens to fire `tutor_chip_used` + `quota_hit` analytics
- Modify: `lib/widgets/vip_locked_feature.dart` (fire `paywall_shown` + `paywall_cta_tapped`)
- Modify: `bananatalk_app/docs/manual-todos.md` (drop the AudioCache item)

- [ ] **Step 1: Create the persona-aware paywall sheet.**

`lib/widgets/tutor/persona_upgrade_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Persona-aware variant of VipUpgradeSheet. Shown when a free user
/// hits a tutor quota cap. Copy matches the user's selected persona
/// (Nana/Sensei/Riko) — falls back to generic if no persona set.
class PersonaUpgradeSheet extends ConsumerWidget {
  final String triggerChip; // 'chat'|'roleplay'|'story'|'photo'|'pronunciation'
  final String reason;      // 'quota_exceeded'|'locked_feature'

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

    // Fire paywall_shown once when this sheet first builds.
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

- [ ] **Step 2: Wire `ApiClient.onQuotaExceeded` globally.**

Wherever `ApiClient()` is constructed (it's a singleton — find the construction site, likely in a `main.dart`-adjacent service). Add:

```dart
ApiClient(
  // existing params...
  onQuotaExceeded: (qe) {
    final ctx = _appNavigatorKey.currentContext; // existing global nav key
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PersonaUpgradeSheet(triggerChip: qe.feature),
    );
    AnalyticsService.instance.quotaHit(chipName: qe.feature, tier: 'free');
  },
);
```

(If a global navigator key doesn't already exist, use the existing GoRouter root context.)

- [ ] **Step 3: Webhook-race retry-with-backoff in `vip_payment_screen.dart`.**

Find lines 202-214 (success path). Replace with:

```dart
if (verifyResult['success'] == true) {
  // Webhook race fix: the Apple/Google webhook may not have landed
  // by the time we re-fetch /vip/status. Retry up to 3 times over
  // ~6 seconds, each time waiting 2 seconds and re-invalidating.
  // Only flip to success when the backend confirms userMode === 'vip'.
  bool confirmedVip = false;
  for (int attempt = 1; attempt <= 3; attempt++) {
    ref.invalidate(userProvider);
    ref.invalidate(vipStatusProvider(widget.userId));
    ref.invalidate(userLimitsProvider(widget.userId));
    final status = await ref.read(vipStatusProvider(widget.userId).future);
    if (status['isVIP'] == true) {
      confirmedVip = true;
      break;
    }
    if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
  }
  if (!mounted) return;
  if (confirmedVip) {
    ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
    AnalyticsService.instance.subscriptionPurchased(
      plan: widget.plan, platform: Platform.isIOS ? 'ios' : 'android',
    );
    _showSuccessDialog();
  } else {
    // Verification succeeded but backend hasn't reflected VIP yet.
    // Show a softer dialog instead of misleading "Welcome to VIP."
    ref.read(purchaseStateProvider.notifier).state = PurchaseState.pending;
    _showPendingDialog();
  }
} else {
  AnalyticsService.instance.subscriptionPurchaseFailed(
    plan: widget.plan,
    platform: Platform.isIOS ? 'ios' : 'android',
    errorCode: verifyResult['error']?.toString() ?? 'unknown',
  );
  // ...existing error handling
}
```

`_showPendingDialog` is a new method on the State class:

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

- [ ] **Step 4: Fire `tutor_chip_used` from each chip screen on entry.**

In each of the 5 chip screens' `initState` (or equivalent first-build hook), add:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final isVip = ref.read(isVipProvider(widget.userId));
  AnalyticsService.instance.tutorChipUsed(
    chipName: '<chip>',  // 'chat'|'roleplay'|'story'|'photo'|'pronunciation'
    userTier: isVip ? 'vip' : 'free', // 'regular' if you have that distinction
  );
});
```

Note: `userTier` is derived from `isVipProvider` since the frontend doesn't differentiate visitor/regular in this provider — adjust to read `userProvider.userMode` if you want the full visitor/regular/vip split.

- [ ] **Step 5: Remove the AudioCache item from manual-todos.md.**

In `docs/manual-todos.md`, find the bullet under Queued engineering → Architecture prep:

```markdown
- [ ] **(30 min) AudioCache orphan blob purge.** ...
```

Delete the entire bullet.

- [ ] **Step 6: Verify.**

```bash
flutter analyze 2>&1 | grep -E "(persona_upgrade_sheet|vip_payment_screen|tutor_quota_indicator)" | head -10
# Expected: no errors specific to these files
```

- [ ] **Step 7: Commit.**

```bash
git add lib/widgets/tutor/persona_upgrade_sheet.dart lib/main.dart lib/pages/vip/vip_payment_screen.dart lib/pages/ai/tutor/ lib/widgets/vip_locked_feature.dart docs/manual-todos.md
git commit -m "$(cat <<'EOF'
feat(vip): persona paywall + global wiring + webhook race fix + events

PersonaUpgradeSheet — new bottom-sheet variant with Nana/Sensei/Riko
copy lines based on the user's selected persona. Falls back to
generic copy when persona is unset. Fires paywall_shown on first
build and paywall_cta_tapped on Upgrade button.

Global ApiClient.onQuotaExceeded hookup opens the persona sheet
when any tutor service call returns 429 quota_exceeded. Also
fires quota_hit analytics event with the chip name + tier.

Webhook race fix in VipPaymentScreen: replace single
invalidate-and-flip-success with a 3-attempt retry loop
(2s between attempts, 6s total worst case). Only show success
when backend confirms userMode === 'vip'; on timeout show a
"subscription is processing" dialog instead of misleading
success-then-revert.

Each chip screen fires tutor_chip_used on entry with the chip
name + user tier. VipPaymentScreen fires subscription_purchased
on confirmed success and subscription_purchase_failed on
verification failure.

Closes the AudioCache orphan-blob item in manual-todos.md
(implementation landed in backend B5).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task G1: Glue — manual smoke test checklist + merge

**Files:** none (this is a meta-task)

This isn't a code commit — it's the verification gate before merging.

- [ ] **Step 1: Backend smoke (run `npm run dev` locally with `AI_QUOTA_ENABLED=true`).**

```bash
TOKEN_REGULAR="<token of a regular-tier user with 0 today usage>"
TOKEN_VIP="<token of an active-VIP user>"

# A. Regular user — Pronounce drill quota is 1/day. First call succeeds.
curl -s -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN_REGULAR" \
  -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '{success, used: .quotas.pronunciation.used, cap: .quotas.pronunciation.cap}'
# Expected: success=true, used=1, cap=1

# B. Same user, same day. Second call → 429 quota_exceeded.
curl -s -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN_REGULAR" \
  -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '{success, error, feature}'
# Expected: success=false, error='quota_exceeded', feature='pronunciation'

# C. VIP user, same call. Bypasses cap; quotas.unlimited=true.
curl -s -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN_VIP" \
  -H "Content-Type: application/json" \
  -d '{"weakWords":["test"]}' | jq '.quotas.pronunciation.unlimited'
# Expected: true

# D. Feature flag off. Restart server with AI_QUOTA_ENABLED=false. Regular
#    user hits the same endpoint twice — both succeed, no 429.
AI_QUOTA_ENABLED=false npm run dev &
# (run two POSTs as in A) → both should return success=true.
```

- [ ] **Step 2: Flutter smoke (on a real device or sim).**

Walk:
1. AI Study tab → Pronounce chip → start drill → finish 1 session (Save & Close)
2. Try to start a second drill same day → expect persona-aware paywall sheet (with whatever persona the test user has selected)
3. Confirm the sheet copy matches the persona, NOT "Quota exceeded"
4. Tap "Upgrade to VIP" → arrives at VipPlansScreen → confirm `paywall_cta_tapped` fires (check `adb logcat | grep firebase` or Firebase DebugView)
5. Tap a real plan + complete purchase (sandbox iOS or test Google Play). Confirm:
   - Success dialog only appears after backend confirms `isVIP: true`
   - On the 3rd retry if not VIP, the "processing" dialog appears instead
6. After purchase, re-enter Pronounce chip. Expect: no quota indicator, no paywall, full access.
7. Manually flip `AI_QUOTA_ENABLED=false` on the backend, restart, and confirm a free user can hit the endpoint repeatedly with no 429.

- [ ] **Step 3: Analytics verification.**

Open Firebase Console → Analytics → DebugView. Confirm these events appear during the smoke flow:
- `tutor_chip_used` (on chip entry)
- `quota_remaining_shown` (when crossing 50% — only fires for chips with cap ≥ 2, so basically just `chat`)
- `quota_hit` (on first 429)
- `paywall_shown` (when persona sheet appears)
- `paywall_cta_tapped` (on Upgrade tap)
- `subscription_purchased` (on confirmed VIP)

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
  --body "Step 13A wave. See docs/superpowers/plans/2026-05-13-step13a-vip-gating-plan.md for full details."
```

For the backend PR, separate command in that repo.

---

## Cadence guidance

- **B1 → B5 land first on the backend branch**, in order. After B4 the backend is functionally complete (quotas + middleware + gated routes). B5 is independent — could ship in its own PR but bundling here keeps the wave atomic.
- **F1 lands first on the Flutter branch** — gives downstream tasks a stable `ApiClient` shape to wire against.
- **F2 + F3 can be authored in parallel** but commit F2 first (analytics) so F3's `quota_remaining_shown` event has somewhere to fire.
- **F4 is the final Flutter task** — depends on F1-F3 + B1-B5 all being on `main` (or at least pushed) so the smoke test can hit a real backend.
- **G1 smoke test is the merge gate.** Do not merge either branch until both smokes pass.

## Risk + rollback

- **Highest-risk change: B2 atomic consumeQuota.** New pattern, no existing test framework on backend other than `node:test`. Rollback: revert B2 + B3 + B4 (sequential cherry-pick revert). Reverting B2 alone leaves the middleware broken (`User.consumeQuota` undefined). The 3 commits should land together or roll back together.
- **Mid-risk: F4 webhook race fix.** If the 3-attempt loop ever blocks the UI thread or the `vipStatusProvider` future never resolves, the user is stuck on a spinner. Mitigation: each attempt has an explicit 2s timeout via `Future.delayed`; if `ref.read(future)` itself hangs, the loop completes anyway after ~6s. Rollback: revert F4 — leaves the old single-invalidate-then-success behavior with its known race.
- **Low-risk: B5 AudioCache purge.** Isolated job; failures log and continue. Worst case: orphan blobs continue accumulating (current state). Rollback: delete `jobs/audioCacheOrphanPurgeJob.js` + revert the scheduler.js wiring.
- **Emergency kill switch.** If quota enforcement breaks in production after deploy: set `AI_QUOTA_ENABLED=false` in the backend `.env` and restart. All quota checks immediately bypass without a code rollback.
- **Pre-deploy DB note.** The TTL/index additions in B1 are Mongoose-managed and auto-build on first connection. No migration script. Existing users get `default: 0` / `default: Date.now()` on first read of the new fields. **No backfill needed.**

---

## Appendix A — Why "count at describe-success" for Photo

Photo flow: user uploads image → `/image-vocab/describe` returns AI description → optionally `/image-vocab/grade` for self-test → end. The "1 photo" unit is one successful describe; grading the same photo is a free follow-up that doesn't justify another quota tick. Counting at `/grade` would penalize users for self-checking their work.

## Appendix B — Why "count at summary-save" for Pronounce

A Pronounce session is 5 sentences. The user is committed once they tap Save & Close on the summary sheet. Counting at `/pronunciation/sentence` (first sentence fetch) would tick the quota even if the user immediately backs out. Counting at `/pronunciation/score` would over-count (5 per session). Counting at `/pronunciation/summary` matches "one completed drill = one quota tick" cleanly.

## Appendix C — VIP grace-period mid-session

User's VIP grace ends mid-roleplay session. Each new `/sessions/:id/message` rechecks `userMode + vipSubscription.isActive + endDate` via `User.consumeQuota`. The instant grace expires, the next message hits the regular-tier cap. If they're already at the cap, they get 429 quota_exceeded mid-roleplay. **This is the documented edge case from the brief — Decision #1.** The plan does NOT add a "complete the current message free" exception. Rationale: complexity not worth the kindness. If the user complains, we can add a 1-message-grace as a hotfix.
