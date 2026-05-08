# Step 2 — Settings Polish & Wave-1 Followups — Design

**Date:** 2026-05-08
**Branch:** `refactor/step2-settings-followups` (off `main`)
**Scope:** `lib/pages/settings/` polish + 3 wave-1 followups (waves daily summary, community topics filter section, voice-room languages API wiring) + theme/language drawer surfacing
**Shape:** Polish wave — no folder restructure, sweep cleanup, ship bounded features

## Goal

Polish the settings module by:
1. Adding a server-backed notification preferences screen (gates every push at the source).
2. Surfacing theme toggle (light/dark/system) and language switcher as top-level drawer rows.
3. Sweeping cleanup debt across the settings folder (`withOpacity`, hardcoded `Colors.grey[*]`, inline snackbars).
4. Lightly splitting the largest file (`data_storage_screen.dart`).

And shipping three follow-ups deferred during community wave 1:
- Daily summary cron for waves (the >3-unread coalesce was added in C15; the actual digest push wasn't).
- Topics filter section in the community filter sheet (`FilterState.topics` exists but has no UI).
- Voice-room languages from the existing API instead of the hardcoded `kVoiceRoomLanguages` const.

## Non-goals (explicit)

- **No folder restructure** of `lib/pages/settings/` — 6 files, 2,202 lines, well-scoped already.
- **No backend account-deletion logic changes** — it's a sensitive flow; UI polish only.
- **No per-locale daily-summary scheduling** — fires once at 9am UTC. Timezone-aware deferred to a future polish round if user feedback demands it.
- **No new minor features** beyond the listed set. Things like push-notification scheduling, "do not disturb" hours, mute-this-conversation — out of scope, deferred.
- **No moments/stories/learning work** — those are Steps 3, 4, 5 (separate specs).

## Current state diagnostics

**Settings folder (6 files, 2,202 lines):**

| File | Lines | Smell |
|---|---|---|
| `data_storage_screen.dart` | 681 | Hardcoded `Colors.white` on dark-mode-incompatible buttons (lines 196, 258); 4 `Colors.grey[*]` instances; mixes cache-stats card + per-section delete buttons + clear-all flow |
| `email_preferences_screen.dart` | 412 | Clean; serves as the pattern reference for new notification preferences screen |
| `language_settings_screen.dart` | 326 | Buried in drawer; surface as top-level row |
| `blocked_users_screen.dart` | 305 | OK |
| `account_deletion.dart` | 268 | OK (audit only — no logic changes) |
| `legal_screen.dart` | 210 | OK |

**Cleanup debt:**
- 7 `.withOpacity(` calls (deprecated)
- 4 `Colors.grey[*]` instances (not theme-aware)
- 11 inline `ScaffoldMessenger.of(context).showSnackBar(...)` calls

**Drawer state:** `lib/pages/profile/drawer/profile_drawer.dart` is the entry point for all settings screens. Currently lists rows for each settings screen; theme + language are not surfaced (or are buried). Notification preferences row is missing entirely.

**Backend surface today:**
- No `notificationPreferences` field on User; pushes fire unconditionally aside from the C15 wave coalesce logic.
- No daily summary digest job — wave_daily summary references in the wave-1 plan were intentionally deferred.
- `shouldNotify(user, type)` helper does not exist; each push site decides on its own.
- `User.email` exists; email preferences storage TBD (verify during implementation — `email_preferences_screen.dart:412` already has working CRUD against some backend endpoint, so the pattern exists).

**Wave-1 leftovers being addressed here:**

| Leftover | Source | Resolution |
|---|---|---|
| Daily summary cron for waves | C15 backend (suppression added, digest deferred) | E1 — new `waveDailySummaryJob.js` cron (9am UTC) |
| Topics filter section UI | C9 spec listed `filter_topics_section.dart` but C9 was structural-only — original sheet had no topics UI | E2 — new section file, wired into rebuilt filter sheet from C19 |
| Voice-room languages hardcoded | C12 added `kVoiceRoomLanguages` top-level const with `// TODO(wave-2)` | E3 — replace with FutureProvider over existing languages API |
| Local-user speaking indicator | C22 deferred remote-only | **NOT in Step 2** — folded into Step 4 (community wave 2 voice-room polish) |

---

## Architecture

### A. Notification preferences (server-backed)

**Why server-side:** A client-side toggle that can't actually stop the server from pushing is a lie. The backend must consult prefs before sending pushes — that's the load-bearing requirement. Server storage also survives reinstalls and device changes.

**Schema** — add to `User` model:

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

Default-true: existing users keep getting pushes; new users get the same default. No migration needed for existing rows.

**Endpoints**

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/auth/users/me/notification-preferences` | — | `{success, data: {prefs}}` |
| PUT | `/auth/users/me/notification-preferences` | `{prefs}` (partial OK; only sets the keys present) | `{success, data: {prefs}}` |

**Backend integration** — single `shouldNotify(user, type)` helper:

```js
function shouldNotify(user, type) {
  if (!user) return false;
  const prefs = user.notificationPreferences;
  if (!prefs) return true;  // missing prefs = use defaults (all true)
  return prefs[type] !== false;
}
```

Every existing push send-site (in `services/notificationService.js`) calls this guard before the FCM send. Add a `// notification preferences gate` comment at each gated site so future authors don't bypass.

The wave-1 push types map to these keys:
- `wave_received` → `wave`
- `chat_message` (or whatever existing key) → `chat`
- `voiceroom_started` (placeholder for Step 4 scheduled rooms) → `voiceRoomStart` / `scheduledRoomReminder`
- `follower_moment_posted` → `followerMoment`
- `profile_visited` → `visitorAlert`
- `mutual_wave` → `matchAlert`

**Flutter — `lib/pages/settings/notification_preferences_screen.dart`**

Mirrors `email_preferences_screen.dart` shape:
- `ConsumerStatefulWidget`
- Loading state on first build → CircularProgressIndicator
- List of `_PreferenceToggleTile` (one per pref key) with title + subtitle + Switch
- Save-on-change with optimistic UI: flip toggle locally → fire `PUT` → on error, revert + snackbar
- "Reset to defaults" link at bottom

Tile labels (l10n keys, added in this Step):
- `notifPrefChat` — "New messages"
- `notifPrefWave` — "Waves"
- `notifPrefVoiceRoomStart` — "Voice room invites"
- `notifPrefScheduledRoomReminder` — "Scheduled room reminders"
- `notifPrefFollowerMoment` — "New moments from people you follow"
- `notifPrefVisitorAlert` — "Profile visitors"
- `notifPrefMatchAlert` — "Mutual waves"

### B. Theme toggle (light/dark/system)

**Investigation step:** verify whether `themeModeProvider` exists in `lib/providers/`. The existing app supports dark mode (community wave 1 had a dark-mode pass) so a setting must exist. If buried, surface it. If absent, add `Riverpod` provider:

```dart
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theme_mode');
    state = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}
```

`MaterialApp.themeMode` reads `ref.watch(themeModeProvider)`.

**Drawer row:** `SegmentedButton<ThemeMode>` with 3 options (Light / Dark / System) inline in `profile_drawer.dart`, no separate screen.

### C. Language switcher in drawer

Existing `LanguageSettingsScreen` (326 lines) already implements full locale picking with persistence. Don't duplicate — keep it as the actual picker UI but **add a top-level drawer row** showing `🇺🇸 English` (current flag + name) that opens it. Also add a "current locale" label inline, so users see which language is active without navigating in.

### D. Cleanup sweep

Mirrors wave-1 cadence:

1. **Migrate inline snackbars** (~11 calls) to a new `lib/pages/settings/widgets/settings_snackbar.dart` helper:

```dart
enum SettingsSnackBarType { info, success, error }

void showSettingsSnackBar(
  BuildContext context, {
  required String message,
  SettingsSnackBarType type = SettingsSnackBarType.info,
}) { ... }
```

Same shape as `community_snackbar.dart` (added in wave-1 C1).

2. **Sweep `withOpacity` → `withValues(alpha:)`** (~7 sites).

3. **Replace hardcoded `Colors.grey[*]`** (4 sites) with theme getters per the wave-1 mapping (`context.containerColor`, `context.dividerColor`, `context.textMuted`, `context.textSecondary`).

4. **Fix `data_storage_screen.dart:196,258`** specifically — known regression where `foregroundColor: Colors.white` paired with a non-colored background renders white-on-white in dark mode. Pair with an `AppColors.primary` background or use `context.textPrimary`.

5. **Light split** of `data_storage_screen.dart` (681 → ~400 + extracted card widgets):
   - `widgets/cache_stats_card.dart` — the storage-by-category breakdown
   - `widgets/clear_cache_actions.dart` — the per-section + clear-all buttons
   - Top-level screen composes them

### E1. Daily summary cron for waves

**Backend job:** `jobs/waveDailySummaryJob.js`. Runs once an hour (cron `0 * * * *`); sends summary push at 9am UTC for users with > 0 unread waves received in last 24h whose individual pushes were suppressed by the existing 6h-coalesce logic from C15.

**Logic:**

```js
const SUMMARY_HOUR_UTC = 9;

cron.schedule('0 * * * *', async () => {
  const now = new Date();
  if (now.getUTCHours() !== SUMMARY_HOUR_UTC) return;

  const since = new Date(Date.now() - 24 * 3600 * 1000);

  // Find users with unread waves in last 24h
  const candidates = await Wave.aggregate([
    { $match: { isRead: false, createdAt: { $gte: since } } },
    { $group: { _id: '$to', count: { $sum: 1 } } },
    { $match: { count: { $gte: 1 } } },
  ]);

  for (const { _id: userId, count } of candidates) {
    const user = await User.findById(userId).select('fcmToken notificationPreferences');
    if (!user?.fcmToken) continue;
    if (!shouldNotify(user, 'wave')) continue;

    await sendPush({
      token: user.fcmToken,
      title: 'New waves waiting',
      body: count === 1
        ? '1 person waved at you'
        : `${count} people waved at you`,
      data: {
        type: 'wave_daily_summary',
        route: '/community?tab=waves',
      },
    });
  }
});
```

Idempotency: track `lastDailySummaryAt` on User. Don't re-fire within 23h.

### E2. Topics filter section

**File:** `lib/pages/community/filter/filter_topics_section.dart`

**Shape:** matches the other filter section widgets (StatefulWidget receiving the parent's slice of state + `onChanged` callback). Multi-select chip grid sourced from `Topic.defaultTopics` (see `lib/models/community/topic_model.dart`).

```dart
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: Topic.defaultTopics.map((topic) {
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

**Wire into `community_filter_sheet.dart`** between Country and Level, in its own `ExpansionTile` (collapsed by default). The sheet's `_buildDraftFiltersMap()` already includes `'topics': _selectedTopics` (verify; if not, add).

**Backend** — verify whether `getUsers` already supports `?topics=a,b,c` filtering (the `getTopicUsers` endpoint exists per wave-1 docs; the bulk user-list endpoint may or may not). If not, add `topics` to `buildUsersQuery` as a `$in` match against `User.topics`. Also extend the count endpoint correspondingly.

### E3. Voice-room languages from API

**File:** `lib/providers/voice_room_languages_provider.dart` (new)

```dart
final voiceRoomLanguagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final languages = await ref.read(languageServiceProvider).getAll();
    return languages.map((l) => l.name).toList();
  } catch (e) {
    // Fallback to the const list to keep the UI functional
    return kVoiceRoomLanguages;
  }
});
```

`languageServiceProvider` and `Language` model already exist (used in registration `_fetchLanguages`).

**Update `voice_rooms_tab.dart`:**

```dart
Consumer(builder: (context, ref, _) {
  final asyncLangs = ref.watch(voiceRoomLanguagesProvider);
  return asyncLangs.when(
    data: (languages) => _buildLanguageFilterChips(languages),
    loading: () => const SizedBox(height: 44, child: SkeletonRow()),
    error: (_, __) => _buildLanguageFilterChips(kVoiceRoomLanguages),
  );
}),
```

Keep `kVoiceRoomLanguages` const as the fallback (don't delete; rename comment from `// TODO(wave-2)` → `// Fallback for offline / API failure`).

---

## Cross-cutting

### l10n plan

**New ARB keys (~15-20):**

| Group | Keys |
|---|---|
| Notification prefs (drawer + screen) | `notificationPreferencesTitle`, `notificationPreferencesSubtitle`, `notifPrefChat`, `notifPrefWave`, `notifPrefVoiceRoomStart`, `notifPrefScheduledRoomReminder`, `notifPrefFollowerMoment`, `notifPrefVisitorAlert`, `notifPrefMatchAlert`, `notifResetToDefaults` |
| Theme | `themeMode`, `themeLight`, `themeDark`, `themeSystem` |
| Language drawer row | `languageSettingsRow` (using the existing localized language name) |
| Daily summary push | `waveDailySummaryTitle`, `waveDailySummaryBody(count)` (plural) |
| Topics filter section | `filterTopicsTitle`, `filterTopicsEmpty` |

`notificationPreferences` already exists in 18 locales — reuse it.

Cadence: en-keys commit → 17-locale translation commit (matches wave-1 C5/C6).

### Testing

- `flutter analyze` clean per commit.
- Manual smoke: each notification preferences toggle round-trips via PUT and gates the corresponding backend push.
- Daily summary cron: deploy to staging, manually trigger by setting `SUMMARY_HOUR_UTC=current_hour` env, observe one summary push fires; revert env.
- Theme toggle: walk every screen in light/dark/system; confirm transitions don't strand text invisible.
- Topics filter: verify match-count from C19 still updates correctly when topics added/removed.

### Risk register

| Risk | Mitigation |
|---|---|
| `shouldNotify` gate accidentally drops legitimate pushes (e.g., for users with `notificationPreferences` field missing) | Default-true logic in helper: `prefs?.[type] !== false`. Existing users without the field keep getting pushes |
| Daily summary fires duplicates if cron runs twice in the same hour | `lastDailySummaryAt` field + 23h skip check |
| Topics filter section breaks the C19 match-count flow | Match count consumes `_buildDraftFiltersMap()` which already includes topics; no integration risk if the field is wired correctly |
| `data_storage_screen` split breaks existing imports | Settings is reached only via the drawer; one importer to update |
| Theme toggle flickers on app start (system → user-pref hydrate) | Provider initializes from SharedPreferences synchronously where possible; otherwise default to `system` until hydrated |

---

## PR / commit breakdown

| # | Commit | Type |
|---|---|---|
| C0 | `chore(settings)`: branch + deps audit | chore |
| C1 | `refactor(settings)`: ARB keys (en) + 17 locales | refactor |
| C2 | `fix(settings)`: withOpacity → withValues + Colors.grey sweep + data_storage hardcoded white | fix |
| C3 | `refactor(settings)`: settings snackbar helper + migrate ~11 inline calls | refactor |
| C4 | `refactor(settings)`: light split of data_storage_screen | refactor |
| C5 | `feat(settings)` + backend: User.notificationPreferences + GET/PUT endpoints | feat + backend |
| C6 | `feat(settings)` + backend: shouldNotify helper + gate every push site | feat + backend |
| C7 | `feat(settings)`: NotificationPreferencesScreen + drawer row | feat |
| C8 | `feat(settings)`: theme toggle (provider + drawer SegmentedButton) | feat |
| C9 | `feat(settings)`: language switcher drawer row | feat |
| C10 | `feat(community)` + backend: waveDailySummaryJob cron | feat + backend |
| C11 | `feat(community)`: topics filter section + wire into filter sheet (+ verify-or-add `?topics=...` filter in `buildUsersQuery` + count endpoint) | feat + backend |
| C12 | `refactor(voice-rooms)`: voice-room languages from API | refactor |
| C13 | `chore(settings)`: final analyzer + smoke pass | chore |

**Total: 14 commits, ~3 weeks.**

---

## Future / deferred

- Per-locale daily summary scheduling (timezone-aware) — revisit if user feedback demands.
- "Do not disturb" hours — out of scope.
- Per-conversation mute (chat-side, not settings-wide) — out of scope.
- Notification sound / vibration customization — defer.
- Backup/restore of settings — defer.
