# Re-engagement Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Send a weekly FCM push notification to users inactive for 7+ days, and show a "Welcome back" modal when they open the app.

**Architecture:** The backend already has `sendReengagementNotifications` in `notificationJobs.js` scheduled weekly (Monday 10 AM KST), but it queries the wrong field (`lastActivityAt`) and uses a broken service call. Fix it to match the proven `waveDailySummaryJob.js` pattern using `fcmService.sendToUser()` and the correct `lastSeenAt` field. On the Flutter side, track the last app-open timestamp in SharedPreferences and show a one-time "Welcome back" modal on the splash screen when the user returns after 7+ days away.

**Tech Stack:** Node.js + Mongoose (backend), Flutter + Riverpod + SharedPreferences (app)

---

## File Map

**Backend (fix only — no new files):**
- Modify: `backend/jobs/notificationJobs.js` — fix `sendReengagementNotifications` to query `lastSeenAt`, use `fcmService.sendToUser()`, and respect `notificationPreferences` via `shouldNotify()`

**Flutter (new files):**
- Create: `lib/services/welcome_back_service.dart` — checks SharedPreferences for `lastAppOpenMs`, returns whether to show modal, saves current timestamp
- Create: `lib/widgets/welcome_back_modal.dart` — the modal UI
- Modify: `lib/pages/home/splash_screen.dart:98` — call `WelcomeBackService.checkAndShow(context)` after version check

---

## Task 1: Fix the backend re-engagement job

**Files:**
- Modify: `backend/jobs/notificationJobs.js:110-157`

The existing `sendReengagementNotifications` has three bugs:
1. Queries `lastActivityAt` — the User schema has `lastSeenAt` (updated by socket) and `lastActive` (updated by auth middleware). Use `lastSeenAt` as it's the most accurate.
2. Uses `notificationSettings.marketing` — the User schema uses `notificationPreferences` (the same object checked by `shouldNotify()`).
3. Calls `notificationService.send()` with a `'system'` type — that method doesn't exist in this shape. Use `fcmService.sendToUser()` directly, same as `waveDailySummaryJob.js`.

- [ ] **Step 1: Open `backend/jobs/notificationJobs.js` and find the imports at the top**

Check what's imported. The file currently imports `notificationService` and `templates`. We need `fcmService` and `shouldNotify` from `notificationService`.

- [ ] **Step 2: Replace `sendReengagementNotifications` with the fixed version**

Replace lines 107–157 with:

```javascript
/**
 * Send re-engagement push notifications to users inactive for 7+ days.
 * Runs weekly (Monday 10 AM KST via scheduler.js).
 * Matches the pattern of waveDailySummaryJob.js.
 */
const sendReengagementNotifications = async () => {
  try {
    console.log('\n💌 Sending re-engagement notifications...');

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    // lastSeenAt is updated on every socket connection — most reliable activity signal.
    // Fall back to lastActive (set by auth middleware) for users who never connected via socket.
    const inactiveUsers = await User.find({
      $or: [
        { lastSeenAt: { $lt: sevenDaysAgo } },
        { lastSeenAt: null, lastActive: { $lt: sevenDaysAgo } },
      ],
      'fcmTokens.0': { $exists: true },
    })
      .select('_id name language_to_learn notificationPreferences fcmTokens lastReengagementAt')
      .limit(500);

    let sent = 0;
    let skipped = 0;
    let failed = 0;

    for (const user of inactiveUsers) {
      try {
        // Respect per-user notification preferences
        if (!shouldNotify(user, 'reengagement')) {
          skipped++;
          continue;
        }

        // Don't re-notify within 6 days (job fires weekly, this prevents double-send)
        const sixDaysAgo = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000);
        if (user.lastReengagementAt && user.lastReengagementAt > sixDaysAgo) {
          skipped++;
          continue;
        }

        const hasActiveToken = user.fcmTokens.some(t => t.active !== false);
        if (!hasActiveToken) { skipped++; continue; }

        const notification = templates.getReengagementTemplate(user);

        await fcmService.sendToUser(
          user._id,
          { title: notification.title, body: notification.body },
          { type: 'reengagement', route: '/home' }
        );

        await User.updateOne(
          { _id: user._id },
          { lastReengagementAt: new Date() }
        );

        sent++;
      } catch (err) {
        console.error('[reengagement] per-user error:', user._id, err.message);
        failed++;
      }
    }

    console.log(`✅ Re-engagement complete: ${sent} sent, ${skipped} skipped, ${failed} failed`);
    return { success: true, sent, skipped, failed };
  } catch (error) {
    console.error('❌ Re-engagement notifications failed:', error);
    return { success: false, error: error.message };
  }
};
```

- [ ] **Step 3: Make sure `fcmService` is imported at the top of `notificationJobs.js`**

Add if not present:
```javascript
const fcmService = require('./fcmService');  // adjust path if needed — check waveDailySummaryJob.js
const { shouldNotify } = require('../services/notificationService');
const templates = require('../utils/notificationTemplates');
```

Check the actual relative path by looking at how `waveDailySummaryJob.js` imports `fcmService`:
```
const fcmService = require('../services/fcmService');
```

- [ ] **Step 4: Add `lastReengagementAt` to `shouldNotify` in `notificationService.js`**

Open `backend/services/notificationService.js` and find `function shouldNotify(user, type)`. Add a case for `'reengagement'`:

```javascript
case 'reengagement':
  return prefs?.marketing !== false;
```

If `prefs.marketing` doesn't exist in the schema, default is `true` (opt-in by default).

- [ ] **Step 5: Add `lastReengagementAt` field to the User schema**

Open `backend/models/User.js`. Find the `lastActive` field (around line 601) and add after it:

```javascript
lastReengagementAt: {
  type: Date,
  default: null,
},
```

- [ ] **Step 6: Test manually**

```bash
cd /path/to/backend
node -e "
require('dotenv').config();
require('mongoose').connect(process.env.MONGO_URI).then(async () => {
  const { sendReengagementNotifications } = require('./jobs/notificationJobs');
  const result = await sendReengagementNotifications();
  console.log(result);
  process.exit(0);
}).catch(e => { console.error(e); process.exit(1); });
"
```

Expected output:
```
💌 Sending re-engagement notifications...
✅ Re-engagement complete: X sent, Y skipped, Z failed
{ success: true, sent: X, skipped: Y, failed: Z }
```

- [ ] **Step 7: Commit**

```bash
cd backend
git add jobs/notificationJobs.js models/User.js services/notificationService.js
git commit -m "fix(jobs): repair weekly re-engagement notification job

- Query lastSeenAt/lastActive instead of missing lastActivityAt field
- Use fcmService.sendToUser() (proven pattern from waveDailySummaryJob)
- Add lastReengagementAt guard to prevent double-send within 6 days
- Add reengagement case to shouldNotify()"
```

---

## Task 2: Flutter — `WelcomeBackService`

**Files:**
- Create: `lib/services/welcome_back_service.dart`

This service tracks the last time the app was opened. If it was 7+ days ago, it returns `true` (show modal) and saves the current timestamp.

- [ ] **Step 1: Create `lib/services/welcome_back_service.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeBackService {
  static const _key = 'last_app_open_ms';
  static const _threshold = Duration(days: 7);

  /// Returns true if the user has been away for 7+ days.
  /// Always updates the stored timestamp to now.
  static Future<bool> checkAndMark() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = prefs.getInt(_key);

    await prefs.setInt(_key, now);

    if (last == null) return false; // first ever launch
    final away = Duration(milliseconds: now - last);
    return away >= _threshold;
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd bananatalk_app
git add lib/services/welcome_back_service.dart
git commit -m "feat(services): add WelcomeBackService — tracks last app open for re-engagement modal"
```

---

## Task 3: Flutter — `WelcomeBackModal` widget

**Files:**
- Create: `lib/widgets/welcome_back_modal.dart`

A bottom-sheet style modal shown when user returns after 7+ days. Non-blocking (user can dismiss). Shows a warm greeting, 3 feature highlights, and a "Let's go" button.

- [ ] **Step 1: Create `lib/widgets/welcome_back_modal.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Shows a "Welcome back" bottom sheet.
/// Returns when the user dismisses it.
Future<void> showWelcomeBackModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _WelcomeBackSheet(),
  );
}

class _WelcomeBackSheet extends StatelessWidget {
  const _WelcomeBackSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Welcome back! 👋',
            style: context.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We missed you. Here's what's new:",
            style: context.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Feature highlights
          _FeatureRow(
            icon: Icons.psychology_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'AI Tutor',
            subtitle: 'Practice conversations, pronunciation & quizzes',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.explore_rounded,
            color: const Color(0xFF00BFA5),
            title: 'Community',
            subtitle: 'Find language partners near you',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFFFF6B6B),
            title: 'Moments',
            subtitle: 'Share your language learning journey',
          ),
          const SizedBox(height: 28),
          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Let's go! 🚀",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color)),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/welcome_back_modal.dart
git commit -m "feat(widgets): add WelcomeBackModal bottom sheet"
```

---

## Task 4: Wire into splash screen

**Files:**
- Modify: `lib/pages/home/splash_screen.dart:98`

The splash screen already calls `VersionCheckCoordinator().check(context)` at line 98. Add the welcome-back check right after it.

- [ ] **Step 1: Add imports to `splash_screen.dart`**

Find the existing imports and add:
```dart
import 'package:bananatalk_app/services/welcome_back_service.dart';
import 'package:bananatalk_app/widgets/welcome_back_modal.dart';
```

- [ ] **Step 2: Add the check after the version check (line 98)**

Find this block:
```dart
if (!mounted) return;
await VersionCheckCoordinator().check(context);
if (!mounted) return;
```

Replace with:
```dart
if (!mounted) return;
await VersionCheckCoordinator().check(context);
if (!mounted) return;

// Show welcome-back modal for users returning after 7+ days
final shouldShowWelcomeBack = await WelcomeBackService.checkAndMark();
if (shouldShowWelcomeBack && mounted && isAuthenticated) {
  await showWelcomeBackModal(context);
  if (!mounted) return;
}
```

Note: only shown when `isAuthenticated` — no point showing it to logged-out users.

- [ ] **Step 3: Verify it compiles**

```bash
cd bananatalk_app
flutter analyze lib/pages/home/splash_screen.dart lib/services/welcome_back_service.dart lib/widgets/welcome_back_modal.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/home/splash_screen.dart lib/services/welcome_back_service.dart lib/widgets/welcome_back_modal.dart
git commit -m "feat: show welcome-back modal on app launch after 7+ days away"
```

---

## Task 5: Push backend + deploy

- [ ] **Step 1: Push backend changes**

```bash
cd backend
git push origin main
```

- [ ] **Step 2: Pull and restart on server**

```bash
# On the server
git pull
pm2 restart all
```

- [ ] **Step 3: Verify re-engagement job is scheduled**

```bash
pm2 logs language-app --lines 50 | grep "Re-engagement"
```

Expected:
```
📅 Re-engagement scheduled in X hours
```

---

## Self-Review

**Spec coverage:**
- ✅ Weekly FCM push to inactive users (7+ days) — Task 1
- ✅ Only sent if not active — `lastSeenAt`/`lastActive` filter
- ✅ Once per week guard — `lastReengagementAt` 6-day check
- ✅ Welcome-back modal on app open — Tasks 2, 3, 4
- ✅ Modal only shown to authenticated users returning after 7+ days

**No placeholders:** All code blocks are complete and self-contained.

**Type consistency:** `WelcomeBackService.checkAndMark()` returns `Future<bool>` — used correctly in splash_screen as `final shouldShowWelcomeBack = await WelcomeBackService.checkAndMark()`.
