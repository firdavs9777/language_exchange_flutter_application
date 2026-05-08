# Step 2 — Settings Polish & Wave-1 Followups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish `lib/pages/settings/` (cleanup sweep + light split + add notification preferences screen + surface theme/language in drawer) and ship 3 wave-1 followups (waves daily summary cron, community topics filter section, voice-room languages from API).

**Architecture:** No folder restructure (settings is small). Server-backed notification preferences via new `User.notificationPreferences` subdoc + `shouldNotify(user, type)` helper gating every push at the source. Theme + language switcher surfaced as top-level `profile_drawer.dart` rows.

**Tech Stack:** Flutter + Riverpod, Node.js/Express + MongoDB (backend), Socket.IO, FCM, SharedPreferences

**Spec:** `docs/superpowers/specs/2026-05-08-step2-settings-and-followups-design.md`

**Branch:** `refactor/step2-settings-followups` (off `main`)

**Project pattern (carried from wave 1):** No new Flutter widget tests — verification is `flutter analyze` clean + manual smoke. Backend additions get unit tests where indicated.

---

## Branch setup

- [ ] **Step 1: Create branch off main**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull
git checkout -b refactor/step2-settings-followups
```

- [ ] **Step 2: Verify clean tree (excluding platform-generated files)**

```bash
git status -s | grep -v -E "(Podfile.lock|generated_plugin_registrant|GeneratedPluginRegistrant)"
flutter analyze lib/pages/settings/ 2>&1 | tail -10
```

Expected: zero new analyzer errors above the wave-1 baseline.

---

## Task C0 — chore: branch + deps audit

**Files:**
- Modify (maybe): `pubspec.yaml`

- [ ] **Step 1: Confirm no new deps needed**

Step 2 introduces no new packages. The features rely on `flutter_riverpod` (already), `shared_preferences` (already), `http` (already), `socket_io_client` (already), `cached_network_image` (already). Verify:

```bash
grep -E "^  (flutter_riverpod|shared_preferences|http|socket_io_client):" pubspec.yaml
```

If anything is missing, add via `flutter pub add <name>`. Otherwise skip.

- [ ] **Step 2: Skip the commit if pubspec untouched**

If `pubspec.yaml` was untouched, no commit is needed for C0 — proceed to C1.

---

## Task C1 — refactor(settings): add ~17 English ARB keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_localizations.dart` (regenerated)
- Modify: `lib/l10n/app_localizations_en.dart` (regenerated)

- [ ] **Step 1: Add the keys to `app_en.arb`**

Insert at the end of the file (before the closing `}`), or sort alphabetically into existing groups. Some keys may already exist (e.g., `notificationPreferences` does); if so, **skip them**.

```json
"notificationPreferencesTitle": "Notifications",
"notificationPreferencesSubtitle": "Choose which alerts you receive",
"notifPrefChat": "New messages",
"notifPrefWave": "Waves",
"notifPrefVoiceRoomStart": "Voice room invites",
"notifPrefScheduledRoomReminder": "Scheduled room reminders",
"notifPrefFollowerMoment": "New moments from people you follow",
"notifPrefVisitorAlert": "Profile visitors",
"notifPrefMatchAlert": "Mutual waves",
"notifResetToDefaults": "Reset to defaults",
"themeMode": "Theme",
"themeLight": "Light",
"themeDark": "Dark",
"themeSystem": "System",
"languageSettingsRow": "Language",
"waveDailySummaryTitle": "New waves waiting",
"waveDailySummaryBody": "{count, plural, =1{1 person waved at you} other{{count} people waved at you}}",
"@waveDailySummaryBody": {"placeholders": {"count": {"type": "int"}}},
"filterTopicsTitle": "Topics",
"filterTopicsEmpty": "No topics selected"
```

- [ ] **Step 2: Skip any key that already exists**

```bash
grep -n "notificationPreferences\b" lib/l10n/app_en.arb
```

If `"notificationPreferences": "..."` already appears, leave it alone; the new keys above don't duplicate it (they all have `Title`/`Subtitle`/specific suffixes).

- [ ] **Step 3: Regenerate localization bindings**

```bash
flutter gen-l10n
```

Expected: regenerates `app_localizations.dart` + `app_localizations_en.dart` with new getters. Other locales report "untranslated message" warnings — that's expected, fixed in C2 follow-up.

- [ ] **Step 4: Verify analyzer**

```bash
flutter analyze lib/l10n/ 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
git commit -m "refactor(settings): C1 — add ~18 English ARB keys for Step 2"
```

---

## Task C2 — refactor(settings): translate ARB keys to 17 locales

**Files:**
- Modify: `lib/l10n/app_<locale>.arb` for: ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW

- [ ] **Step 1: For each locale, add the same keys with translated values**

Critical rules:
- Preserve ICU placeholders verbatim (`{count}`)
- Preserve plural ICU syntax in `waveDailySummaryBody` — use locale's plural categories (Korean/Japanese/Chinese can use only `=1`/`other`)
- Skip keys that already exist
- Preserve `@key` placeholder metadata blocks unchanged

Example (Korean, `lib/l10n/app_ko.arb`):

```json
"notificationPreferencesTitle": "알림",
"notificationPreferencesSubtitle": "받을 알림을 선택하세요",
"notifPrefChat": "새 메시지",
"notifPrefWave": "인사",
"notifPrefVoiceRoomStart": "음성 방 초대",
"notifPrefScheduledRoomReminder": "예정된 방 알림",
"notifPrefFollowerMoment": "팔로우한 사람의 새 모먼트",
"notifPrefVisitorAlert": "프로필 방문자",
"notifPrefMatchAlert": "상호 인사",
"notifResetToDefaults": "기본값으로 재설정",
"themeMode": "테마",
"themeLight": "라이트",
"themeDark": "다크",
"themeSystem": "시스템",
"languageSettingsRow": "언어",
"waveDailySummaryTitle": "새 인사가 기다리고 있어요",
"waveDailySummaryBody": "{count, plural, =1{1명이 인사했어요} other{{count}명이 인사했어요}}",
"@waveDailySummaryBody": {"placeholders": {"count": {"type": "int"}}},
"filterTopicsTitle": "주제",
"filterTopicsEmpty": "선택된 주제 없음"
```

For agentic execution: dispatch one subagent per locale OR a single agent across all 17 with strict ICU placeholder preservation rules (matches wave-1 C6 pattern).

- [ ] **Step 2: Regenerate**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -10
```

Expected: no errors; "untranslated message" warnings should be cleared for the 18 added keys.

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "refactor(settings): C2 — translate ~18 Step 2 keys to 17 locales"
```

---

## Task C3 — fix(settings): withOpacity → withValues + Colors.grey + data_storage hardcoded white

**Files:**
- Modify various under `lib/pages/settings/`

- [ ] **Step 1: Locate withOpacity sites**

```bash
grep -rn "\.withOpacity(" lib/pages/settings/
```

Expected: ~7 hits across `data_storage_screen.dart`, `email_preferences_screen.dart`, possibly others.

- [ ] **Step 2: Mass-replace withOpacity → withValues(alpha:)**

```bash
grep -rl "\.withOpacity(" lib/pages/settings/ | xargs sed -i '' 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g'
```

Re-grep to confirm zero matches:

```bash
grep -rn "\.withOpacity(" lib/pages/settings/
```

- [ ] **Step 3: Locate hardcoded grey/white sites**

```bash
grep -rn "Colors\.grey\[\|Colors\.white\b" lib/pages/settings/
```

Expected: 4 `Colors.grey[*]` + ~2 `Colors.white` instances. Apply per-site judgment using the wave-1 mapping:

| From | To |
|---|---|
| `Colors.white` (background of card / sheet) | `context.surfaceColor` |
| `Colors.grey[100]` (filled bg) | `context.containerColor` |
| `Colors.grey[200]` / `[300]` (borders) | `context.dividerColor` |
| `Colors.grey[400]` / `[500]` (muted icons) | `context.textMuted` |
| `Colors.grey[600]` / `[700]` (secondary text) | `context.textSecondary` |

**Exception:** `foregroundColor: Colors.white` paired with a colored `backgroundColor` (button on primary) — keep. That's the universal codebase pattern.

- [ ] **Step 4: Specifically fix `data_storage_screen.dart:196,258`**

These are known dark-mode regressions where `foregroundColor: Colors.white` is paired with a non-colored background, rendering invisible in dark mode. Read the surrounding context:

```bash
sed -n '190,205p;250,265p' lib/pages/settings/data_storage_screen.dart
```

Identify whether the button has a colored `backgroundColor`. If yes, leave `Colors.white` (it's the universal pattern). If the button has no `backgroundColor` (uses default), pair with `AppColors.primary` background or change foreground to `context.textPrimary`.

- [ ] **Step 5: Add theme_extensions import where needed**

If any file you migrated to `context.foo` getters lacks the import, add:

```dart
import 'package:bananatalk_app/utils/theme_extensions.dart';
```

- [ ] **Step 6: Verify analyzer + smoke test in dark mode**

```bash
flutter analyze lib/pages/settings/ 2>&1 | tail -10
```

Expected: no errors; `withOpacity` deprecation warnings gone.

Manual smoke: launch app → toggle dark mode → walk every settings screen → confirm no white-on-white surfaces.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/settings/
git commit -m "fix(settings): C3 — withOpacity → withValues + Colors.grey theme migration + data_storage dark-mode fixes"
```

---

## Task C4 — refactor(settings): add settings_snackbar helper + migrate ~11 inline calls

**Files:**
- Create: `lib/pages/settings/widgets/settings_snackbar.dart`
- Modify: every settings file containing `ScaffoldMessenger.of(context).showSnackBar`

- [ ] **Step 1: Create the helper**

Create `lib/pages/settings/widgets/settings_snackbar.dart` mirroring `lib/pages/community/widgets/community_snackbar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum SettingsSnackBarType { info, success, error }

void showSettingsSnackBar(
  BuildContext context, {
  required String message,
  SettingsSnackBarType type = SettingsSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    SettingsSnackBarType.success => AppColors.primary,
    SettingsSnackBarType.error => AppColors.error,
    SettingsSnackBarType.info => Theme.of(context).colorScheme.surface,
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
      duration: duration,
    ),
  );
}
```

- [ ] **Step 2: Locate inline snackbar sites**

```bash
grep -rn "ScaffoldMessenger\.of(context)\.showSnackBar" lib/pages/settings/
```

Expected: ~11 hits.

- [ ] **Step 3: Replace each with showSettingsSnackBar**

Pattern:

```dart
// BEFORE
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.someMessage),
    backgroundColor: const Color(0xFF00BFA5),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
  ),
);

// AFTER
showSettingsSnackBar(
  context,
  message: l10n.someMessage,
  type: SettingsSnackBarType.success,
);
```

Color → type mapping:
- `AppColors.primary` / `0xFF00BFA5` → `success`
- `Colors.red` / `AppColors.error` → `error`
- otherwise → `info`

Add the import to each modified file:

```dart
import 'package:bananatalk_app/pages/settings/widgets/settings_snackbar.dart';
```

**Skip** snackbars whose `content:` is a custom `Row` (icon + text). Those need a richer helper; out of scope. Leave them as-is.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/pages/settings/ 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/settings/
git commit -m "refactor(settings): C4 — settings_snackbar helper + migrate ~11 inline calls"
```

---

## Task C5 — refactor(settings): light split of data_storage_screen

**Files:**
- Modify: `lib/pages/settings/data_storage_screen.dart` (681 → ~400 lines)
- Create: `lib/pages/settings/widgets/cache_stats_card.dart`
- Create: `lib/pages/settings/widgets/clear_cache_actions.dart`

- [ ] **Step 1: Read the current file**

```bash
wc -l lib/pages/settings/data_storage_screen.dart
sed -n '1,50p' lib/pages/settings/data_storage_screen.dart
```

Identify the structure: typically a `StatefulWidget` with sections for storage usage breakdown, cache clearing actions, and maybe download settings.

- [ ] **Step 2: Extract the cache-stats card**

Identify the widget rendering the storage breakdown (per-category usage with bars). Extract into `widgets/cache_stats_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CacheStatsCard extends StatelessWidget {
  final Map<String, int> sizeByCategory;  // bytes per category
  final int totalBytes;

  const CacheStatsCard({
    super.key,
    required this.sizeByCategory,
    required this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    // ... migrated body of the storage-breakdown section
    // Adjust the prop shape to match what the existing screen passes
  }
}
```

**The prop shape must match the existing screen's data.** Read the screen, identify the variables the section consumes (e.g., `_imageCacheSize`, `_videoCacheSize`, `_totalSize`), and design the prop shape accordingly. If the screen uses individual ints, accept individual ints; if it uses a map, accept a map.

- [ ] **Step 3: Extract the clear-cache actions**

Identify the widget rendering per-section delete buttons + clear-all flow. Extract into `widgets/clear_cache_actions.dart`:

```dart
import 'package:flutter/material.dart';

class ClearCacheActions extends StatelessWidget {
  final VoidCallback onClearImages;
  final VoidCallback onClearVideos;
  final VoidCallback onClearAll;
  final bool isClearing;

  const ClearCacheActions({
    super.key,
    required this.onClearImages,
    required this.onClearVideos,
    required this.onClearAll,
    required this.isClearing,
  });

  @override
  Widget build(BuildContext context) {
    // ... migrated body of the action-buttons section
  }
}
```

- [ ] **Step 4: Update `data_storage_screen.dart` to compose**

```dart
import 'widgets/cache_stats_card.dart';
import 'widgets/clear_cache_actions.dart';
```

Replace the inline section blocks with the new widgets, passing state + callbacks.

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/pages/settings/data_storage_screen.dart lib/pages/settings/widgets/ 2>&1 | tail -10
```

Manual smoke: open Settings → Data & Storage → confirm storage breakdown still renders, clear-cache buttons still work.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/settings/
git commit -m "refactor(settings): C5 — light split of data_storage_screen (681 → ~400)"
```

---

## Task C6 — feat(settings) + backend: User.notificationPreferences + endpoints

**Files (backend):**
- Modify: `models/User.js`
- Modify or create: `controllers/users.js` (add `getNotificationPreferences`, `updateNotificationPreferences`)
- Modify: `routes/users.js`

- [ ] **Step 1: Add `notificationPreferences` subdocument to User model**

In `/Users/davis/Desktop/Personal/language_exchange_backend_application/models/User.js`, add the field:

```js
notificationPreferences: {
  chat:                  { type: Boolean, default: true },
  wave:                  { type: Boolean, default: true },
  voiceRoomStart:        { type: Boolean, default: true },
  scheduledRoomReminder: { type: Boolean, default: true },
  followerMoment:        { type: Boolean, default: true },
  visitorAlert:          { type: Boolean, default: true },
  matchAlert:            { type: Boolean, default: true },
}
```

Place near other user-preference fields. No migration needed (defaults are true; missing field on existing rows reads as undefined and is treated as true by `shouldNotify` helper added in C7).

- [ ] **Step 2: Add controller methods**

In `controllers/users.js` (or wherever user CRUD lives — verify by reading the file):

```js
exports.getNotificationPreferences = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('notificationPreferences');
    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.status(200).json({
      success: true,
      data: { prefs: user.notificationPreferences || {} },
    });
  } catch (e) { next(e); }
};

exports.updateNotificationPreferences = async (req, res, next) => {
  try {
    const { prefs } = req.body;
    if (!prefs || typeof prefs !== 'object') {
      return res.status(400).json({ error: 'prefs body required' });
    }
    // Allow only known keys; ignore others
    const allowed = ['chat', 'wave', 'voiceRoomStart', 'scheduledRoomReminder',
                     'followerMoment', 'visitorAlert', 'matchAlert'];
    const update = {};
    for (const key of allowed) {
      if (key in prefs) {
        update[`notificationPreferences.${key}`] = !!prefs[key];
      }
    }
    if (Object.keys(update).length === 0) {
      return res.status(400).json({ error: 'no valid prefs in body' });
    }
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: update },
      { new: true, select: 'notificationPreferences' }
    );
    return res.status(200).json({
      success: true,
      data: { prefs: user.notificationPreferences || {} },
    });
  } catch (e) { next(e); }
};
```

Adapt to the project's actual error-handling pattern (`asyncHandler` + `ErrorResponse` if used).

- [ ] **Step 3: Wire routes**

In `routes/users.js`:

```js
router.get('/me/notification-preferences', protect, getNotificationPreferences);
router.put('/me/notification-preferences', protect, updateNotificationPreferences);
```

Use the actual auth middleware name (`protect`, `authMiddleware`, etc.). Verify the route is mounted under `/auth/users` to match Flutter's `Endpoints.usersURL = 'auth/users'`.

- [ ] **Step 4: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node --check models/User.js
node --check controllers/users.js
node --check routes/users.js
```

- [ ] **Step 5: Commit (backend)**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add models/User.js controllers/users.js routes/users.js
git commit -m "feat(settings): C6 — User.notificationPreferences + GET/PUT endpoints"
```

---

## Task C7 — feat(settings) + backend: shouldNotify helper + gate every push site

**Files (backend):**
- Modify: `services/notificationService.js` (or wherever existing push helpers live)

- [ ] **Step 1: Add the helper**

At the top of `services/notificationService.js`:

```js
/**
 * Returns true if the user has not opted out of `type` notifications.
 * Missing notificationPreferences = use defaults (all true).
 *
 * @param {Object} user - User document with notificationPreferences populated
 * @param {string} type - One of: 'chat', 'wave', 'voiceRoomStart',
 *                        'scheduledRoomReminder', 'followerMoment',
 *                        'visitorAlert', 'matchAlert'
 */
function shouldNotify(user, type) {
  if (!user) return false;
  const prefs = user.notificationPreferences;
  if (!prefs) return true;  // missing field = use defaults (all true)
  return prefs[type] !== false;
}
```

Export it:

```js
module.exports = {
  // ... existing exports
  shouldNotify,
};
```

- [ ] **Step 2: Identify every push send-site**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
grep -rn "fcmService.sendToUser\|admin\.messaging\|sendPush\|messaging()\.send" --include='*.js' . | head -30
```

Expected hits: each push type has a function in `notificationService.js` (e.g., `sendChat`, `sendWave`, `sendFollowerMomentNotification`, `sendProfileVisitNotification`, etc.).

- [ ] **Step 3: Gate each send with `shouldNotify`**

For each push function, add the gate after fetching the target user (and ensure the fetch includes `notificationPreferences`):

```js
exports.sendWave = async (targetUserId, fromUserId, message) => {
  const target = await User.findById(targetUserId)
    .select('fcmToken notificationPreferences');
  if (!target?.fcmToken) return;

  // notification preferences gate
  if (!shouldNotify(target, 'wave')) return;

  // ... existing send logic
};
```

Map push types:
- `sendChat` / message-related → `'chat'`
- `sendWave` → `'wave'`
- `sendVoiceRoomInvite` (placeholder for Step 4) → `'voiceRoomStart'`
- `sendScheduledRoomReminder` (placeholder for Step 4) → `'scheduledRoomReminder'`
- `sendFollowerMomentNotification` → `'followerMoment'`
- `sendProfileVisitNotification` → `'visitorAlert'`
- mutual-wave path (inside `sendWave` after `isMutual: true`) → `'matchAlert'` (separate gate; mutuals can be enabled even if waves are off, or vice versa)

- [ ] **Step 4: Verify syntax**

```bash
node --check services/notificationService.js
```

- [ ] **Step 5: Commit (backend)**

```bash
git add services/notificationService.js
git commit -m "feat(settings): C7 — shouldNotify helper + gate every push site"
```

---

## Task C8 — feat(settings): NotificationPreferencesScreen + drawer row

**Files:**
- Create: `lib/pages/settings/notification_preferences_screen.dart`
- Modify: `lib/pages/profile/drawer/profile_drawer.dart`
- Modify: `lib/providers/provider_root/community_provider.dart` (or wherever — add the prefs service method)

- [ ] **Step 1: Add service method to fetch + update prefs**

Add to whichever service handles user CRUD (likely in `lib/services/user_service.dart` or `lib/providers/provider_root/community_provider.dart`'s service class). Add:

```dart
Future<Map<String, bool>> getNotificationPreferences() async {
  final response = await _apiClient.get(
    '${Endpoints.usersURL}/me/notification-preferences',
  );
  if (response.success && response.data is Map) {
    final prefs = response.data['prefs'] as Map?;
    return prefs?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {};
  }
  throw Exception(response.error ?? 'Failed to load preferences');
}

Future<Map<String, bool>> updateNotificationPreferences(
    Map<String, bool> prefs) async {
  final response = await _apiClient.put(
    '${Endpoints.usersURL}/me/notification-preferences',
    body: {'prefs': prefs},
  );
  if (response.success && response.data is Map) {
    final returned = response.data['prefs'] as Map?;
    return returned?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {};
  }
  throw Exception(response.error ?? 'Failed to update preferences');
}
```

Place `Endpoints.usersURL` reference confirms the path is `auth/users/me/notification-preferences`.

- [ ] **Step 2: Create `notification_preferences_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/settings/widgets/settings_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, bool>? _prefs;
  bool _isLoading = true;
  String? _error;

  static const _keys = [
    'chat', 'wave', 'voiceRoomStart', 'scheduledRoomReminder',
    'followerMoment', 'visitorAlert', 'matchAlert',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await ref
          .read(communityServiceProvider)
          .getNotificationPreferences();
      // Fill in defaults (true) for missing keys
      final filled = <String, bool>{};
      for (final key in _keys) {
        filled[key] = prefs[key] ?? true;
      }
      if (!mounted) return;
      setState(() {
        _prefs = filled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    if (_prefs == null) return;
    final old = Map<String, bool>.from(_prefs!);
    setState(() => _prefs![key] = value);
    try {
      await ref.read(communityServiceProvider).updateNotificationPreferences({key: value});
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs!.addAll(old));
      showSettingsSnackBar(
        context,
        message: AppLocalizations.of(context)!.waveCouldntSend, // generic error string
        type: SettingsSnackBarType.error,
      );
    }
  }

  Future<void> _resetDefaults() async {
    final defaults = {for (final k in _keys) k: true};
    setState(() => _prefs = defaults);
    try {
      await ref.read(communityServiceProvider).updateNotificationPreferences(defaults);
    } catch (e) {
      _load(); // re-fetch on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.notificationPreferencesTitle),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.notificationPreferencesSubtitle,
                        style: context.bodyMedium
                            .copyWith(color: context.textSecondary),
                      ),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefChat,
                      value: _prefs!['chat']!,
                      onChanged: (v) => _toggle('chat', v),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefWave,
                      value: _prefs!['wave']!,
                      onChanged: (v) => _toggle('wave', v),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefVoiceRoomStart,
                      value: _prefs!['voiceRoomStart']!,
                      onChanged: (v) => _toggle('voiceRoomStart', v),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefScheduledRoomReminder,
                      value: _prefs!['scheduledRoomReminder']!,
                      onChanged: (v) => _toggle('scheduledRoomReminder', v),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefFollowerMoment,
                      value: _prefs!['followerMoment']!,
                      onChanged: (v) => _toggle('followerMoment', v),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefVisitorAlert,
                      value: _prefs!['visitorAlert']!,
                      onChanged: (v) => _toggle('visitorAlert', v),
                    ),
                    _PreferenceTile(
                      title: l10n.notifPrefMatchAlert,
                      value: _prefs!['matchAlert']!,
                      onChanged: (v) => _toggle('matchAlert', v),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: _resetDefaults,
                        child: Text(l10n.notifResetToDefaults),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: context.bodyMedium),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
```

- [ ] **Step 3: Add drawer row to `profile_drawer.dart`**

Read the file:

```bash
grep -n "ListTile\|EmailPreferences\|languageSettings" lib/pages/profile/drawer/profile_drawer.dart | head -20
```

Find the section listing settings-related rows. Add a new ListTile (alongside `EmailPreferencesScreen` row) that pushes `NotificationPreferencesScreen`:

```dart
ListTile(
  leading: const Icon(Icons.notifications_outlined),
  title: Text(AppLocalizations.of(context)!.notificationPreferencesTitle),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPreferencesScreen(),
      ),
    );
  },
),
```

Add the import:

```dart
import 'package:bananatalk_app/pages/settings/notification_preferences_screen.dart';
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/pages/settings/notification_preferences_screen.dart lib/pages/profile/drawer/profile_drawer.dart 2>&1 | tail -10
```

Manual smoke: open drawer → tap Notifications → screen opens, loads prefs, toggle one off → close + reopen screen → confirm toggle persisted.

- [ ] **Step 5: Commit**

```bash
git add lib/
git commit -m "feat(settings): C8 — NotificationPreferencesScreen + drawer row"
```

---

## Task C9 — feat(settings): theme toggle (provider + drawer SegmentedButton)

**Files:**
- Create or verify: `lib/providers/theme_mode_provider.dart`
- Modify: `lib/main.dart` (or wherever `MaterialApp.themeMode` is wired)
- Modify: `lib/pages/profile/drawer/profile_drawer.dart`

- [ ] **Step 1: Check if a theme provider already exists**

```bash
grep -rn "ThemeMode\b\|themeMode\b" lib/providers/ lib/main.dart 2>/dev/null | head -10
```

If a provider exists, **skip Step 2** and proceed to Step 3 (just surface the toggle). If not, create the provider.

- [ ] **Step 2: Create the provider (if needed)**

Create `lib/providers/theme_mode_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    state = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
```

- [ ] **Step 3: Wire `themeMode` into `MaterialApp`**

In `lib/main.dart` (or wherever the `MaterialApp` is built), make the app a `ConsumerWidget` (or wrap the existing root in a `Consumer`) and pass:

```dart
themeMode: ref.watch(themeModeProvider),
```

If the `MaterialApp` already had `themeMode` set to a hardcoded value (e.g., `ThemeMode.system`), replace that.

- [ ] **Step 4: Add theme toggle to drawer**

In `profile_drawer.dart`, add a `SegmentedButton` row near the Notifications row:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Text(
          AppLocalizations.of(context)!.themeMode,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          final l10n = AppLocalizations.of(context)!;
          return SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight), icon: const Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark), icon: const Icon(Icons.dark_mode_outlined)),
              ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem), icon: const Icon(Icons.settings_outlined)),
            ],
            selected: {mode},
            onSelectionChanged: (s) {
              ref.read(themeModeProvider.notifier).set(s.first);
            },
          );
        },
      ),
    ],
  ),
),
```

Imports to add to `profile_drawer.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/theme_mode_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/main.dart lib/providers/theme_mode_provider.dart lib/pages/profile/drawer/profile_drawer.dart 2>&1 | tail -10
```

Manual smoke: open drawer → tap each theme option → app theme changes immediately. Restart app → setting persists.

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "feat(settings): C9 — theme toggle (provider + drawer SegmentedButton)"
```

---

## Task C10 — feat(settings): language switcher drawer row

**Files:**
- Modify: `lib/pages/profile/drawer/profile_drawer.dart`

- [ ] **Step 1: Identify the current locale source**

```bash
grep -rn "currentLocale\|Localizations\.of\|locale:" lib/main.dart lib/services/language_service.dart 2>/dev/null | head -10
```

Read `LanguageService` (`lib/services/language_service.dart`) to find:
- How current locale is read (likely `LanguageService.currentLanguageCode` or similar)
- How it's persisted (SharedPreferences key `app_language`)
- The full list of supported languages with native names

- [ ] **Step 2: Add a drawer row**

In `profile_drawer.dart`, add a row that surfaces the current language and opens `LanguageSettingsScreen`:

```dart
ListTile(
  leading: const Icon(Icons.language),
  title: Text(AppLocalizations.of(context)!.languageSettingsRow),
  trailing: Text(
    LanguageService.nativeNameFor(currentCode), // or the equivalent helper
    style: TextStyle(color: context.textSecondary),
  ),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LanguageSettingsScreen(),
      ),
    );
  },
),
```

Adapt to whatever helper or method `LanguageService` actually exposes. If no helper exists, inline a simple lookup table or call `Localizations.localeOf(context).languageCode`.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/pages/profile/drawer/profile_drawer.dart 2>&1 | tail -10
```

Manual smoke: open drawer → see "Language: English" row → tap → existing `LanguageSettingsScreen` opens.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/profile/drawer/profile_drawer.dart
git commit -m "feat(settings): C10 — language switcher drawer row"
```

---

## Task C11 — feat(community) + backend: waveDailySummaryJob cron

**Files (backend):**
- Create: `jobs/waveDailySummaryJob.js`
- Modify: `jobs/scheduler.js` (wire the new job)
- Modify: `models/User.js` (add `lastDailySummaryAt`)

- [ ] **Step 1: Add `lastDailySummaryAt` to User model**

In `/Users/davis/Desktop/Personal/language_exchange_backend_application/models/User.js`:

```js
lastDailySummaryAt: { type: Date, default: null },
```

No index — only updated by the cron, never queried.

- [ ] **Step 2: Create the job**

Create `/Users/davis/Desktop/Personal/language_exchange_backend_application/jobs/waveDailySummaryJob.js`:

```js
const Wave = require('../models/Wave');
const User = require('../models/User');
const { shouldNotify } = require('../services/notificationService');
const fcmService = require('../services/fcmService');  // adapt path

const SUMMARY_HOUR_UTC = 9;
const SKIP_WINDOW_MS = 23 * 3600 * 1000;
const LOOKBACK_MS = 24 * 3600 * 1000;

let _started = false;

async function _runOnce() {
  const now = new Date();
  if (now.getUTCHours() !== SUMMARY_HOUR_UTC) return;

  const since = new Date(Date.now() - LOOKBACK_MS);
  const skipBefore = new Date(Date.now() - SKIP_WINDOW_MS);

  // Aggregate unread waves per recipient in last 24h
  const candidates = await Wave.aggregate([
    { $match: { isRead: false, createdAt: { $gte: since } } },
    { $group: { _id: '$to', count: { $sum: 1 } } },
    { $match: { count: { $gte: 1 } } },
  ]);

  let sent = 0;
  for (const { _id: userId, count } of candidates) {
    const user = await User.findById(userId).select(
      'fcmToken notificationPreferences lastDailySummaryAt'
    );
    if (!user?.fcmToken) continue;
    if (!shouldNotify(user, 'wave')) continue;
    if (user.lastDailySummaryAt && user.lastDailySummaryAt > skipBefore) continue;

    try {
      await fcmService.sendToUser({
        userId: user._id,
        token: user.fcmToken,
        notification: {
          title: 'New waves waiting',
          body: count === 1
            ? '1 person waved at you'
            : `${count} people waved at you`,
        },
        data: {
          type: 'wave_daily_summary',
          route: '/community?tab=waves',
        },
      });
      await User.updateOne({ _id: userId }, { lastDailySummaryAt: new Date() });
      sent++;
    } catch (err) {
      console.error('[waveDailySummary] send failed:', userId, err.message);
    }
  }

  if (sent > 0) {
    console.log(`[waveDailySummary] sent ${sent} summaries`);
  }
}

function start() {
  if (_started) return;
  _started = true;
  // Run every hour at minute 0, gate by UTC hour
  setInterval(_runOnce, 60 * 60 * 1000);
  console.log('[waveDailySummary] started (fires at UTC hour ' + SUMMARY_HOUR_UTC + ')');
}

module.exports = { start, _runOnce };
```

Adapt `fcmService.sendToUser` to whatever the actual existing FCM helper is (the C15 wave path uses one; verify).

- [ ] **Step 3: Wire into scheduler**

In `jobs/scheduler.js` (which C24 wave-1 work created or extended), add:

```js
const waveDailySummaryJob = require('./waveDailySummaryJob');

function startScheduler() {
  // ... existing job starts
  waveDailySummaryJob.start();
}

module.exports = { startScheduler };
```

- [ ] **Step 4: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node --check jobs/waveDailySummaryJob.js
node --check jobs/scheduler.js
node --check models/User.js
```

- [ ] **Step 5: Add a manual trigger (for staging testing)**

Append a small CLI test hook at the bottom of `waveDailySummaryJob.js`:

```js
// CLI test trigger: `node jobs/waveDailySummaryJob.js --run-once`
if (require.main === module && process.argv.includes('--run-once')) {
  require('mongoose').connect(process.env.MONGO_URI).then(() => {
    return _runOnce();
  }).then(() => {
    console.log('done');
    process.exit(0);
  });
}
```

Test in staging: temporarily change `SUMMARY_HOUR_UTC` to current UTC hour, run `node jobs/waveDailySummaryJob.js --run-once`, observe one summary fires, revert the constant.

- [ ] **Step 6: Commit (backend)**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add models/User.js jobs/waveDailySummaryJob.js jobs/scheduler.js
git commit -m "feat(settings): C11 — waveDailySummaryJob cron (9am UTC)"
```

---

## Task C12 — feat(community) + backend: topics filter section + backend filter

**Files (Flutter):**
- Create: `lib/pages/community/filter/filter_topics_section.dart`
- Modify: `lib/pages/community/filter/community_filter_sheet.dart`

**Files (backend):**
- Modify: `controllers/users.js` — extend `buildUsersQuery` with `topics` filter

- [ ] **Step 1: Verify FilterState already includes topics**

```bash
grep -n "topics" lib/pages/community/filter/filter_state.dart
```

Expected: `final List<String> topics;` already there from wave-1 C9. Confirm.

- [ ] **Step 2: Create the section widget**

Create `lib/pages/community/filter/filter_topics_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/pages/community/widgets/community_filter_chip.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class FilterTopicsSection extends StatelessWidget {
  final List<String> selectedTopics;
  final ValueChanged<List<String>> onChanged;

  const FilterTopicsSection({
    super.key,
    required this.selectedTopics,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = Topic.defaultTopics;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topics.map((topic) {
          final isSelected = selectedTopics.contains(topic.id);
          return CommunityFilterChip(
            label: topic.name,
            emoji: topic.icon,
            isSelected: isSelected,
            onTap: () {
              final next = List<String>.from(selectedTopics);
              if (isSelected) {
                next.remove(topic.id);
              } else {
                next.add(topic.id);
              }
              onChanged(next);
            },
          );
        }).toList(),
      ),
    );
  }
}
```

If `Topic.defaultTopics` static doesn't exist, read the actual API:

```bash
grep -n "defaultTopics\|class Topic" lib/models/community/topic_model.dart
```

If absent, fetch via `topicsProvider` or similar. Verify by reading the file before committing.

- [ ] **Step 3: Wire into community_filter_sheet.dart**

Read the current file to find where C19's `ExpansionTile`s are wired:

```bash
grep -n "ExpansionTile\|FilterCountrySection\|FilterLevelSection" lib/pages/community/filter/community_filter_sheet.dart | head -10
```

Insert the new section between Country and Level (or wherever fits the existing ordering). Pattern (matching the other section wires):

```dart
ExpansionTile(
  initiallyExpanded: false,
  title: Text(AppLocalizations.of(context)!.filterTopicsTitle),
  children: [
    FilterTopicsSection(
      selectedTopics: _selectedTopics,
      onChanged: (next) {
        setState(() => _selectedTopics = next);
        _onAnyFilterChanged();
      },
    ),
  ],
),
```

Add to the file's state if `_selectedTopics: List<String>` doesn't already exist:

```dart
List<String> _selectedTopics = [];
```

Initialize from `widget.initialFilters['topics']` in `_initializeValues`:

```dart
_selectedTopics = (widget.initialFilters['topics'] as List?)?.cast<String>() ?? [];
```

Reset in `resetFilters`:

```dart
_selectedTopics = [];
```

Include in `_applyFilters` output map:

```dart
'topics': _selectedTopics,
```

Add the import:

```dart
import 'package:bananatalk_app/pages/community/filter/filter_topics_section.dart';
```

- [ ] **Step 4: Verify Flutter**

```bash
flutter analyze lib/pages/community/filter/ 2>&1 | tail -10
```

Manual smoke: open filter sheet → expand Topics section → select 2 topics → Apply → confirm match-count updates and tab list filters.

- [ ] **Step 5: Backend — verify or extend `buildUsersQuery` to honor `topics`**

In `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/users.js`:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
grep -n "topics\|buildUsersQuery" controllers/users.js | head -10
```

If `topics` is not yet in the query builder, add it (Flutter passes `topics` as a comma-separated string in the URL query):

```js
// Inside buildUsersQuery(req)
if (req.query.topics) {
  const topicIds = req.query.topics
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
  if (topicIds.length > 0) {
    filter.topics = { $in: topicIds };
  }
}
```

The `User.topics` field is an array of topic ID strings. `$in` matches users whose topics array contains any of the requested topics.

- [ ] **Step 6: Verify backend syntax + that count endpoint also picks up topics**

```bash
node --check controllers/users.js
```

Since `getUsersCount` shares `buildUsersQuery` (extracted in wave-1 C19's `ad5875e`), the count automatically respects topics. Confirm by reading `controllers/users.js` to ensure both `getUsers` and `getUsersCount` go through the same helper.

- [ ] **Step 7: Commit (Flutter + backend)**

Backend:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/users.js
git commit -m "feat(community): C12 — topics filter in buildUsersQuery (Flutter + backend in sync)"
```

Flutter:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/community/filter/
git commit -m "feat(community): C12 — topics filter section + wire into filter sheet"
```

---

## Task C13 — refactor(voice-rooms): voice-room languages from API

**Files:**
- Create: `lib/providers/voice_room_languages_provider.dart`
- Modify: `lib/pages/community/voice_rooms/voice_rooms_tab.dart`

- [ ] **Step 1: Create the provider**

Create `lib/providers/voice_room_languages_provider.dart`:

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';

const List<String> kVoiceRoomLanguagesFallback = [
  'English', 'Korean', 'Japanese', 'Chinese', 'Spanish', 'French',
  'German', 'Italian', 'Portuguese', 'Russian', 'Arabic', 'Hindi', 'Uzbek',
];

final voiceRoomLanguagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      return kVoiceRoomLanguagesFallback;
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? [];
    final names = data
        .map((e) => (e is Map ? e['name']?.toString() : null))
        .whereType<String>()
        .toList();
    return names.isEmpty ? kVoiceRoomLanguagesFallback : names;
  } catch (e) {
    return kVoiceRoomLanguagesFallback;
  }
});
```

(`Endpoints.languagesURL = 'languages'` already exists — verified.)

- [ ] **Step 2: Update `voice_rooms_tab.dart` to consume the provider**

Read the existing file to find where `kVoiceRoomLanguages` is used:

```bash
grep -n "kVoiceRoomLanguages" lib/pages/community/voice_rooms/voice_rooms_tab.dart
```

Add the import:

```dart
import 'package:bananatalk_app/providers/voice_room_languages_provider.dart';
```

Wrap the language-filter chip row in a `Consumer`:

```dart
Consumer(
  builder: (context, ref, _) {
    final asyncLangs = ref.watch(voiceRoomLanguagesProvider);
    return asyncLangs.when(
      data: (languages) => _buildLanguageChips(languages),
      loading: () => const SizedBox(height: 44),  // placeholder; chips appear when loaded
      error: (_, __) => _buildLanguageChips(kVoiceRoomLanguagesFallback),
    );
  },
),
```

Where `_buildLanguageChips(List<String> langs)` is the existing chip-builder logic, parameterized to take a list rather than reading the const.

Optionally, **delete the now-unused** `kVoiceRoomLanguages` const at the top of the file (the fallback in the provider replaces it). If the file references the const elsewhere, retain the same name or rename references to use the provider's fallback constant.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/voice_rooms_tab.dart lib/providers/voice_room_languages_provider.dart 2>&1 | tail -10
```

Manual smoke: open voice rooms tab → confirm language filter chips load (you may see a brief loading state on cold start) → toggle a language → list filters correctly.

- [ ] **Step 4: Commit**

```bash
git add lib/
git commit -m "refactor(voice-rooms): C13 — voice-room languages from /languages API"
```

---

## Task C14 — chore(settings): final analyzer cleanup + smoke pass

- [ ] **Step 1: Run analyzer scoped to Step 2 areas**

```bash
flutter analyze lib/pages/settings/ lib/pages/profile/drawer/profile_drawer.dart lib/pages/community/filter/ lib/pages/community/voice_rooms/voice_rooms_tab.dart lib/providers/theme_mode_provider.dart lib/providers/voice_room_languages_provider.dart lib/main.dart 2>&1 | tail -50
```

Triage:
- **Errors:** must fix
- **Warnings:** undefined refs introduced by Step 2 commits — fix
- **Info-level lints:** skip unless trivial (unused imports added by Step 2 — remove)

- [ ] **Step 2: Fix unused imports in Step 2 files**

If any Step 2 file accumulated unused imports (common during iterative editing), remove them.

- [ ] **Step 3: Verify zero new errors**

```bash
flutter analyze lib/ 2>&1 | grep "error •" | head -10
```

Expected: zero. If any new error appears, fix or revert.

- [ ] **Step 4: Manual cross-screen smoke**

- iOS + Android, light + dark mode
- Drawer renders all 3 new rows (Notifications, Theme toggle, Language)
- Notifications screen toggles persist across app restart
- Theme toggle changes app appearance instantly
- Language switcher opens existing screen and works
- Settings → Data & Storage renders, no white-on-white in dark mode
- Community filter sheet shows new Topics section, applies correctly
- Voice rooms tab loads languages from API (or falls back gracefully if offline)

- [ ] **Step 5: Commit**

If anything was changed by the cleanup pass:

```bash
git add lib/
git commit -m "chore(settings): C14 — final analyzer cleanup + manual smoke pass"
```

If clean state, mark the boundary with an empty commit:

```bash
git commit --allow-empty -m "chore(settings): C14 — Step 2 complete (no further changes)"
```

- [ ] **Step 6: Push + PR**

```bash
git push -u origin refactor/step2-settings-followups

gh pr create --title "Settings polish + wave-1 followups (Step 2)" --body "$(cat <<'EOF'
## Summary

Step 2 of the post-wave-1 roadmap. Polishes `lib/pages/settings/` and ships 3 wave-1 followups. **No folder restructure** (settings is small enough already).

### Settings polish
- New `NotificationPreferencesScreen` (server-backed via new `User.notificationPreferences` + `shouldNotify` gate on every push)
- Theme toggle (light / dark / system) surfaced in drawer
- Language switcher row in drawer
- `data_storage_screen.dart` light split + dark-mode fixes
- `withOpacity` → `withValues(alpha:)` sweep, `Colors.grey[*]` → theme getters, inline snackbars → `showSettingsSnackBar`

### Wave-1 followups
- **Daily wave summary cron** (9am UTC) — fires for users with unread waves whose individual pushes were suppressed by C15's 6h coalesce
- **Topics filter section** in community filter sheet — `FilterState.topics` existed since C9 with no UI; now ships
- **Voice-room languages from `/languages` API** instead of the hardcoded `kVoiceRoomLanguages` const

### Backend changes
- `User.notificationPreferences` subdocument + GET/PUT endpoints
- `shouldNotify(user, type)` helper gating every push site
- `User.lastDailySummaryAt` field + `jobs/waveDailySummaryJob.js`
- `buildUsersQuery` extended with `?topics=a,b,c` filter (auto-flows to count endpoint)

## Test plan

- [ ] Drawer: 3 new rows visible; theme toggle changes app instantly
- [ ] Notifications: toggle a pref off → backend stops sending that push type
- [ ] Daily summary: staging trigger fires one summary push for a test user with unread waves
- [ ] Topics filter: select 2 topics → list narrows; match count updates
- [ ] Voice rooms: language filter loads from API on connection; falls back to const when offline
- [ ] Dark mode: walk every settings screen; no white-on-white surfaces

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Plan complete

**Spec:** `docs/superpowers/specs/2026-05-08-step2-settings-and-followups-design.md`
**Plan:** this file
**Branch:** `refactor/step2-settings-followups`
**Total: 14 commits (C0–C14), ~3 weeks**

Backend changes split across the paired backend repo (commits land on `main` directly, not on a feature branch — matches wave 1 cadence).

---

## Self-review notes (post-write)

**Spec coverage:**
- ✅ Notification preferences (C6 backend, C7 backend, C8 Flutter)
- ✅ Theme toggle (C9)
- ✅ Language switcher (C10)
- ✅ Cleanup sweep (C3, C4, C5)
- ✅ E1 daily summary (C11)
- ✅ E2 topics filter section (C12)
- ✅ E3 voice-room languages from API (C13)
- ✅ ARB keys + 17 locales (C1, C2)
- ✅ Final polish (C14)

**Type consistency:**
- `_PreferenceTile` in C8 — private widget, internal to the screen. ✓
- `FilterTopicsSection` props match the existing section pattern (`selectedTopics: List<String>`, `onChanged: ValueChanged<List<String>>`). ✓
- `voiceRoomLanguagesProvider` returns `Future<List<String>>` consistently across creation (C13) and consumption (`voice_rooms_tab.dart`). ✓
- `shouldNotify(user, type)` signature consistent across C7 (helper) and C11 (cron usage). ✓

**Placeholder scan:** no "TBD"/"TODO" placeholders. C13 references the actual `Endpoints.languagesURL = 'languages'` pattern verified before plan-writing.

**Cross-PR dependency:**
- C7 depends on C6 (User schema must exist before gating).
- C8 depends on C7 (gate must exist or the screen is observable but useless).
- C11 depends on C7 (cron uses `shouldNotify`).
- C12 (Flutter) depends on C12 (backend) only insofar as filtering will return all users until backend lands. Either order works.
- C9 / C10 / C13 are independent.
