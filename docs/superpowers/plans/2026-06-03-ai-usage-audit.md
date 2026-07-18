# AI Usage Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist a lightweight audit record every time a user invokes any AI feature so admins can query who used what and when.

**Architecture:** Create an `AIUsageLog` Mongoose model, implement the existing `trackUsage()` stub in `aiProviderService.js` to write to it (fire-and-forget), and add a `GET /api/v1/admin/ai-usage` endpoint that returns counts grouped by feature and day.

**Tech Stack:** Node.js, Express, Mongoose/MongoDB

---

## File Map

| Action | File |
|--------|------|
| Create | `backend/models/AIUsageLog.js` |
| Modify | `backend/services/aiProviderService.js` (lines 649–660) |
| Modify | `backend/controllers/admin.js` (add `getAIUsage` export) |
| Modify | `backend/routes/admin.js` (add route + import) |

---

### Task 1: Create the `AIUsageLog` model

**Files:**
- Create: `backend/models/AIUsageLog.js`

- [ ] **Step 1: Create the model file**

```js
// backend/models/AIUsageLog.js
const mongoose = require('mongoose');

const AIUsageLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  feature: {
    type: String,
    required: true,
    index: true,
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

AIUsageLogSchema.index({ feature: 1, timestamp: -1 });
AIUsageLogSchema.index({ userId: 1, timestamp: -1 });

module.exports = mongoose.model('AIUsageLog', AIUsageLogSchema);
```

- [ ] **Step 2: Verify the file exists**

Run: `ls backend/models/AIUsageLog.js`
Expected: file path printed, no error

- [ ] **Step 3: Commit**

```bash
git add backend/models/AIUsageLog.js
git commit -m "feat(audit): add AIUsageLog model"
```

---

### Task 2: Implement `trackUsage()` in `aiProviderService.js`

**Files:**
- Modify: `backend/services/aiProviderService.js` (lines 649–660)

- [ ] **Step 1: Add the AIUsageLog require at the top of the file**

Find the top of `backend/services/aiProviderService.js` (after the existing `require` statements, around line 7). Add:

```js
const AIUsageLog = require('../models/AIUsageLog');
```

- [ ] **Step 2: Replace the `trackUsage` stub**

Find this block (lines 649–660):

```js
const trackUsage = async (options) => {
  const {
    userId,
    feature,
    tokensUsed,
    provider = 'openai'
  } = options;

  // This would typically save to a database
  // For now, just log
  console.log(`AI Usage: User ${userId}, Feature: ${feature}, Tokens: ${JSON.stringify(tokensUsed)}`);
};
```

Replace with:

```js
const trackUsage = async (options) => {
  const { userId, feature } = options;
  if (!userId || !feature) return;
  AIUsageLog.create({ userId, feature }).catch((err) =>
    console.error('[AIUsageLog] write failed:', err.message)
  );
};
```

- [ ] **Step 3: Start the backend server and confirm no startup error**

Run: `node -e "require('./backend/services/aiProviderService')" 2>&1`
Expected: no output (no crash)

- [ ] **Step 4: Commit**

```bash
git add backend/services/aiProviderService.js
git commit -m "feat(audit): implement trackUsage() — write to AIUsageLog"
```

---

### Task 3: Add `getAIUsage` controller function

**Files:**
- Modify: `backend/controllers/admin.js`

- [ ] **Step 1: Add AIUsageLog import at top of `backend/controllers/admin.js`**

Find the existing requires at the top:

```js
const asyncHandler = require('../middleware/async');
const User = require('../models/User');
const AdminAuditLog = require('../models/AdminAuditLog');
const ErrorResponse = require('../utils/errorResponse');
const banService = require('../services/banService');
```

Add `AIUsageLog` after `AdminAuditLog`:

```js
const asyncHandler = require('../middleware/async');
const User = require('../models/User');
const AdminAuditLog = require('../models/AdminAuditLog');
const AIUsageLog = require('../models/AIUsageLog');
const ErrorResponse = require('../utils/errorResponse');
const banService = require('../services/banService');
```

- [ ] **Step 2: Add the `getAIUsage` export at the bottom of `backend/controllers/admin.js`**

Append before the end of the file:

```js
/**
 * @desc    AI feature usage counts grouped by feature and day
 * @route   GET /api/v1/admin/ai-usage
 * @access  Admin
 * @query   feature (string, optional) — filter to one feature
 *          from (ISO date, optional) — start of range, default 30 days ago
 *          to   (ISO date, optional) — end of range, default now
 */
exports.getAIUsage = asyncHandler(async (req, res) => {
  const to = req.query.to ? new Date(req.query.to) : new Date();
  const from = req.query.from
    ? new Date(req.query.from)
    : new Date(to.getTime() - 30 * 24 * 60 * 60 * 1000);

  const match = { timestamp: { $gte: from, $lte: to } };
  if (req.query.feature) match.feature = req.query.feature;

  const [byFeature, byDay, total] = await Promise.all([
    AIUsageLog.aggregate([
      { $match: match },
      { $group: { _id: '$feature', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $project: { _id: 0, feature: '$_id', count: 1 } },
    ]),
    AIUsageLog.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$timestamp' },
          },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
      { $project: { _id: 0, date: '$_id', count: 1 } },
    ]),
    AIUsageLog.countDocuments(match),
  ]);

  res.status(200).json({ success: true, data: { total, byFeature, byDay } });
});
```

- [ ] **Step 3: Verify the file parses**

Run: `node -e "require('./backend/controllers/admin')" 2>&1`
Expected: no output (no crash)

- [ ] **Step 4: Commit**

```bash
git add backend/controllers/admin.js
git commit -m "feat(audit): add getAIUsage admin controller"
```

---

### Task 4: Wire the route

**Files:**
- Modify: `backend/routes/admin.js`

- [ ] **Step 1: Add `getAIUsage` to the destructured import in `backend/routes/admin.js`**

Find:

```js
const {
  searchUsers,
  getUserDetail,
  banUser,
  unbanUser,
  changeRole,
  getAuditLog,
  getStats,
} = require('../controllers/admin');
```

Replace with:

```js
const {
  searchUsers,
  getUserDetail,
  banUser,
  unbanUser,
  changeRole,
  getAuditLog,
  getStats,
  getAIUsage,
} = require('../controllers/admin');
```

- [ ] **Step 2: Add the route before `module.exports`**

Find:

```js
router.get('/audit-log', getAuditLog);
router.get('/stats', getStats);

module.exports = router;
```

Replace with:

```js
router.get('/audit-log', getAuditLog);
router.get('/stats', getStats);
router.get('/ai-usage', getAIUsage);

module.exports = router;
```

- [ ] **Step 3: Verify the router parses**

Run: `node -e "require('./backend/routes/admin')" 2>&1`
Expected: no output (no crash)

- [ ] **Step 4: Commit**

```bash
git add backend/routes/admin.js
git commit -m "feat(audit): expose GET /api/v1/admin/ai-usage route"
```

---

### Task 5: Manual smoke test

- [ ] **Step 1: Start the backend**

Run: `cd backend && node server.js` (or however the backend is started in this project — check `package.json` scripts)

- [ ] **Step 2: Trigger an AI feature call**

Make one authenticated API call to any AI endpoint (e.g. `POST /api/v1/grammar/` with a user token) so `trackUsage()` fires.

- [ ] **Step 3: Query the audit endpoint**

```bash
curl -H "Authorization: Bearer <admin_token>" \
  http://localhost:5000/api/v1/admin/ai-usage
```

Expected response shape:
```json
{
  "success": true,
  "data": {
    "total": 1,
    "byFeature": [{ "feature": "grammar_feedback", "count": 1 }],
    "byDay": [{ "date": "2026-06-03", "count": 1 }]
  }
}
```
