# Community Restructure & Wave 1 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `lib/pages/community/` (~12,366 lines, 13 files) into 7 focused subfolders with shared widgets and a dark-mode/withOpacity sweep, then ship five wave-1 features (filter UX rebuild, waves send-side + mutual UI, voice rooms overhaul, mutual interests on profile, online-now presence). Mesh→SFU migration is deferred to wave 2.

**Architecture:** Parallel backend + frontend. Backend changes are additive and default-safe (new fields, new socket events, new endpoint validation, indexes). Flutter side does folder restructure first (C0–C12), then features (C13–C19), then voice rooms overhaul (C20–C26), polish (C27). Each commit is independently revertable; no feature flags.

**Tech Stack:** Flutter + Riverpod, Node.js/Express + MongoDB (backend), Socket.IO (presence + voice rooms), flutter_webrtc (mesh audio), FCM (push notifications)

**Spec:** `docs/superpowers/specs/2026-05-06-community-restructure-and-wave-1-design.md`

**Branch:** `refactor/community-wave-1` (off `main`)

**Backend repo:** Lives in a separate Node.js/Express + MongoDB repo (typically `language_exchange_backend_application` adjacent to this repo). Confirm the actual path with the team before C15; commits prefixed `feat(community): C15…` (etc.) land in that repo. The Flutter repo's commits for backend-touching tasks include either a backend stub note or an empty marker commit.

**Project pattern (locked-in via spec):** No new Flutter widget tests — verification is `flutter analyze` clean + manual smoke per the chat phase 1 cadence. Backend additions get unit tests where indicated.

---

## Branch setup

- [ ] **Step 1: Create branch off main**

```bash
git checkout main && git pull
git checkout -b refactor/community-wave-1
```

- [ ] **Step 2: Verify clean tree**

```bash
git status
flutter analyze lib/pages/community/ 2>&1 | tail -20
```

Expected: clean working tree; analyzer baseline noted (will be the bar to keep).

---

## C0 — chore(community): branch setup & deps audit

**Files:**
- Modify (maybe): `pubspec.yaml`

- [ ] **Step 1: Audit deps**

Wave 1 introduces no new packages — `flutter_webrtc`, `socket_io_client`, `image_cropper`, `geolocator`, `shared_preferences`, `flutter_riverpod`, `flutter_animate`, `timeago`, `cached_network_image` are all already present. Confirm:

```bash
grep -E "^  (flutter_webrtc|socket_io_client|flutter_riverpod):" pubspec.yaml
```

If anything is missing, add via `flutter pub add <name>`. Otherwise proceed.

- [ ] **Step 2: Commit (empty if no deps changed)**

If `pubspec.yaml` was untouched, skip the commit. Otherwise:

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(community): C0 — deps audit for wave 1"
```

---

## C1 — refactor(community): widgets/ scaffolding (5 shared widgets, no callers yet)

**Files (Create):**
- `lib/pages/community/widgets/community_snackbar.dart`
- `lib/pages/community/widgets/community_dialog_scaffold.dart`
- `lib/pages/community/widgets/community_empty_state.dart`
- `lib/pages/community/widgets/community_filter_chip.dart`
- `lib/pages/community/widgets/community_error_state.dart`

- [ ] **Step 1: Create `community_snackbar.dart`**

Mirror the chat module's `showChatSnackBar` shape (read `lib/pages/chat/widgets/chat_snackbar.dart` for the exact API surface and copy the pattern). Three types: `info`, `success`, `error`. Each maps to a colored floating SnackBar with rounded corners.

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum CommunitySnackBarType { info, success, error }

void showCommunitySnackBar(
  BuildContext context, {
  required String message,
  CommunitySnackBarType type = CommunitySnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    CommunitySnackBarType.success => AppColors.primary,
    CommunitySnackBarType.error => AppColors.error,
    CommunitySnackBarType.info => Theme.of(context).colorScheme.surface,
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

- [ ] **Step 2: Create `community_dialog_scaffold.dart`**

A reusable rounded card used by confirm dialogs and bottom sheets across community.

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CommunityDialogScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CommunityDialogScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: padding,
      child: SafeArea(child: child),
    );
  }
}
```

- [ ] **Step 3: Create `community_empty_state.dart`**

Generic empty-state (icon + title + subtitle + optional CTA). Used by tabs when filters return zero, when waves list is empty, etc.

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CommunityEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const CommunityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: context.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `community_filter_chip.dart`**

Theme-aware filter chip extracted from `voice_rooms_tab.dart:514`. Replaces hardcoded `Colors.grey[*]` colors with `context.*` getters.

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CommunityFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const CommunityFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : context.containerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: isSelected ? AppColors.primary : context.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create `community_error_state.dart`**

Generic error state with retry button.

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CommunityErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const CommunityErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                style: context.titleMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? 'Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Verify analyzer**

```bash
flutter analyze lib/pages/community/widgets/ 2>&1 | tail -10
```

Expected: no errors (warnings/info from existing code OK).

- [ ] **Step 7: Commit**

```bash
git add lib/pages/community/widgets/
git commit -m "refactor(community): C1 — add widgets/ scaffolding (5 shared widgets, no callers)"
```

---

## C2 — refactor(community): migrate inline snackbars to showCommunitySnackBar

**Files:**
- Modify all `lib/pages/community/**/*.dart` files containing `ScaffoldMessenger.of(context).showSnackBar`

- [ ] **Step 1: Locate inline snackbar calls**

```bash
grep -rn "ScaffoldMessenger.of(context).showSnackBar\|ScaffoldMessenger.of(\w*).showSnackBar" lib/pages/community/
```

Expected: ~30 hits across `voice_rooms_tab.dart`, `voice_room_screen.dart`, `single_community.dart`, `community_main.dart`, `community_filter.dart`, etc.

- [ ] **Step 2: Replace each with `showCommunitySnackBar`**

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
showCommunitySnackBar(
  context,
  message: l10n.someMessage,
  type: CommunitySnackBarType.success, // or .error / .info
);
```

Add the import to each file:

```dart
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
```

Map color → type:
- `AppColors.primary` / `0xFF00BFA5` → `success`
- `Colors.red` / `AppColors.error` → `error`
- everything else → `info`

- [ ] **Step 3: Verify analyzer + smoke test snackbars**

```bash
flutter analyze lib/pages/community/ 2>&1 | tail -10
```

Run app → walk to community → trigger a room create / wave / filter apply / voice room mute → confirm snackbars still appear with same color/shape.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/community/
git commit -m "refactor(community): C2 — migrate inline snackbars to showCommunitySnackBar"
```

---

## C3 — refactor(community): extract `_FilterChip` from voice_rooms_tab.dart

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_rooms_tab.dart`

- [ ] **Step 1: Update voice_rooms_tab.dart**

Remove the local `_FilterChip` class (lines ~514–578). Replace the 4 in-file usages (lines 196, 205, 223, 232) with `CommunityFilterChip`.

Add import:

```dart
import 'package:bananatalk_app/pages/community/widgets/community_filter_chip.dart';
```

Replace `_FilterChip(` → `CommunityFilterChip(` at each call site (4 occurrences).

- [ ] **Step 2: Verify analyzer**

```bash
flutter analyze lib/pages/community/voice_rooms/voice_rooms_tab.dart 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Manual smoke**

Run app → community → Voice Rooms tab → confirm language filter chips and topic filter chips render and toggle correctly.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/community/voice_rooms/voice_rooms_tab.dart
git commit -m "refactor(community): C3 — extract _FilterChip to widgets/community_filter_chip.dart"
```

---

## C4 — fix(community): withOpacity → withValues + dark-mode pass

**Files:**
- Modify any community-page file using `withOpacity` or hardcoded `Colors.grey[*]` / `Colors.white`

- [ ] **Step 1: Locate withOpacity calls**

```bash
grep -rn "withOpacity\|Colors.grey\[\|Colors.white\b" lib/pages/community/ | wc -l
```

Document the count for the commit message.

- [ ] **Step 2: Mass-replace withOpacity → withValues(alpha:)**

```bash
# Sed-style replace; review each match before committing
grep -rl "\.withOpacity(" lib/pages/community/ | xargs sed -i '' 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g'
```

- [ ] **Step 3: Replace hardcoded colors with theme getters**

Per the chat phase 1 pattern in `2026-05-05-chat-restructure-phase-1-design.md`:

| From | To |
|---|---|
| `Colors.white` | `context.surfaceColor` |
| `Colors.grey[50/100]` | `context.containerColor` |
| `Colors.grey[200/300]` | `context.dividerColor` |
| `Colors.grey[400/500]` | `context.textMuted` |
| `Colors.grey[600/700]` | `context.textSecondary` |
| `Colors.black87` | `context.textPrimary` |

Walk each file flagged by the grep and apply contextually. Do not touch values inside `voice_room_screen.dart` that are deliberately white-on-dark (the room UI is intentionally a fixed dark theme — leave `Color(0xFF1A1A2E)` and white text alone; they're not theme-bound by design).

- [ ] **Step 4: Verify analyzer + dark mode smoke**

```bash
flutter analyze lib/pages/community/ 2>&1 | tail -10
```

Run app in light mode → walk every community tab + filter sheet + single profile + voice room create sheet → switch to dark mode → walk again → confirm nothing is illegible or has white-on-white surfaces.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/
git commit -m "fix(community): C4 — withOpacity → withValues + dark-mode color sweep"
```

---

## C5 — refactor(community): add ~53 new English ARB keys for wave 1

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_localizations.dart` (regenerated)

- [ ] **Step 1: Add wave-1 keys to `app_en.arb`**

Insert alphabetized into existing groups. Reference the spec's "l10n plan" for the full ~53 keys. Categories:

**Waves (~12):**
```json
"sendWave": "Send a wave",
"sendWaveTo": "Send a wave to {name}",
"@sendWaveTo": {"placeholders": {"name": {"type": "String"}}},
"waveSent": "Wave sent to {name}",
"@waveSent": {"placeholders": {"name": {"type": "String"}}},
"waveCooldown": "You can wave {name} again in {time}",
"@waveCooldown": {"placeholders": {"name": {"type": "String"}, "time": {"type": "String"}}},
"waveCouldntSend": "Couldn't send wave",
"itsAMatch": "It's a match!",
"itsAMatchSubtitle": "You and {name} both waved",
"@itsAMatchSubtitle": {"placeholders": {"name": {"type": "String"}}},
"sendAMessage": "Send a message",
"waveQuickReplyHi": "Hi!",
"waveQuickReplyCool": "You seem cool",
"waveQuickReplyHey": "Hey there",
"waveQuickReplyChat": "Let's chat",
"waveQuickReplyHello": "Hello",
"waveQuickReplyFromCountry": "Hi from {country}",
"@waveQuickReplyFromCountry": {"placeholders": {"country": {"type": "String"}}},
"waveCustomMessage": "Or write your own…",
```

**Voice room chat (~5):**
```json
"voiceRoomChat": "Chat",
"voiceRoomChatPlaceholder": "Send a message…",
"voiceRoomChatEmpty": "No messages yet — say hi",
"voiceRoomChatSend": "Send",
"voiceRoomChatNewBadge": "{n}",
"@voiceRoomChatNewBadge": {"placeholders": {"n": {"type": "int"}}},
```

**Voice room host (~10):**
```json
"voiceRoomEnd": "End room",
"voiceRoomEndConfirm": "End this room?",
"voiceRoomEndConfirmBody": "Everyone will be disconnected.",
"voiceRoomKick": "Remove from room",
"voiceRoomKickConfirm": "Remove {name}?",
"@voiceRoomKickConfirm": {"placeholders": {"name": {"type": "String"}}},
"voiceRoomKicked": "Removed",
"voiceRoomYouAreHostNow": "You're now the host",
"voiceRoomHostChanged": "{name} is now the host",
"@voiceRoomHostChanged": {"placeholders": {"name": {"type": "String"}}},
"voiceRoomHostMenuTitle": "Room actions",
"voiceRoomViewProfile": "View profile",
```

**Voice room reconnect (~4):**
```json
"voiceRoomReconnecting": "Reconnecting…",
"voiceRoomReconnected": "Reconnected",
"voiceRoomEnded": "Room ended",
"voiceRoomReconnectRetry": "Retry",
```

**Mutual interests (~5):**
```json
"mutualInterests": "Mutual interests",
"interestsInCommon": "{count, plural, =0{No interests in common yet} =1{1 interest in common} other{{count} interests in common}}",
"@interestsInCommon": {"placeholders": {"count": {"type": "int"}}},
"interestsInCommonSeeAll": "See all",
"interestsInCommonAddCta": "Add topics",
"interestsInCommonAddSubtitle": "Add topics to your profile to find common ground",
```

**Presence (~3):**
```json
"onlineNow": "Online now",
"activeAgo": "Active {time} ago",
"@activeAgo": {"placeholders": {"time": {"type": "String"}}},
"filterOnlineNow": "Online now",
```

**Tab title (~1):**
```json
"wavesTab": "Waves",
```

**Filter rebuild (~14):**
```json
"filterAge": "Age",
"filterGender": "Gender",
"filterLanguages": "Languages",
"filterCountry": "Country",
"filterTopics": "Topics",
"filterLevel": "Language level",
"filterToggles": "Other",
"filterMatchCount": "{count, plural, =0{No partners match} =1{1 partner matches} other{{count} partners match}}",
"@filterMatchCount": {"placeholders": {"count": {"type": "int"}}},
"filterClearAll": "Clear all",
"filterReset": "Reset",
"filterApply": "Apply",
"filterNewUsers": "New users only",
"filterPrioritizeNearby": "Prioritize nearby",
"filterSheetTitle": "Filters",
```

- [ ] **Step 2: Regenerate localization files**

```bash
flutter gen-l10n
```

Expected: regenerates `lib/l10n/app_localizations.dart` and `app_localizations_en.dart` with the new getters. No errors.

- [ ] **Step 3: Verify analyzer**

```bash
flutter analyze lib/l10n/ 2>&1 | tail -10
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
git commit -m "refactor(community): C5 — add ~53 English ARB keys for wave 1"
```

---

## C6 — refactor(community): translate ARB keys to 17 locales

**Files:**
- Modify: `lib/l10n/app_<locale>.arb` for the 17 non-English locales (ko, ja, zh, es, fr, de, it, pt, ru, ar, hi, vi, th, tl, id, tr, plus zh-Hant if present)

- [ ] **Step 1: Identify the locale files**

```bash
ls lib/l10n/app_*.arb | grep -v app_en.arb
```

- [ ] **Step 2: Translate each key per locale**

For each locale ARB file, add the same ~53 keys with locale-appropriate translations. Use the existing translation cadence (refer to past commits like `61c87af refactor(auth): C2 — 13 new ARB keys for Phase 2 across 18 locales` for tone/quality bar).

For agentic execution: dispatch one subagent per language with the English keys and ask for native translations preserving ICU placeholders. Do not auto-translate critical UX strings (e.g., the "It's a match!" celebration) without a native speaker review pass.

- [ ] **Step 3: Regenerate**

```bash
flutter gen-l10n
flutter analyze lib/l10n/ 2>&1 | tail -10
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "refactor(community): C6 — translate ~53 wave-1 keys to 17 locales"
```

---

## C7 — refactor(community): split community_main into main/

**Files:**
- Create dir: `lib/pages/community/main/`
- `git mv` + split: `community_main.dart` → `main/community_main.dart` (~300) + `main/community_app_bar.dart` + `main/community_tab_bar.dart` + `main/community_search_bar.dart`

- [ ] **Step 1: Create main/ directory and move root file**

```bash
mkdir -p lib/pages/community/main
git mv lib/pages/community/community_main.dart lib/pages/community/main/community_main.dart
```

- [ ] **Step 2: Extract `_buildAppBar` (or equivalent search/filter row) to `community_app_bar.dart`**

Read `community_main.dart` to identify the AppBar / top action row. Extract into a `CommunityAppBar` widget that accepts callbacks: `onFilterTap`, `onSearchChanged`, `searchController`, `isSearching`.

- [ ] **Step 3: Extract `TabBar` widget to `community_tab_bar.dart`**

Pull the `TabBar` builder into `CommunityTabBar({required tabController, required tabs})`. Tabs grow from 6 → 7 in C13 — for now keep the existing 6.

- [ ] **Step 4: Extract search-bar overlay to `community_search_bar.dart`**

If `community_main.dart` has a separate search overlay (revealed when search icon tapped), pull it out. If search is inline in the AppBar, skip this file.

- [ ] **Step 5: Update imports across the app**

```bash
grep -rln "pages/community/community_main.dart" lib/
```

Update each importer to `pages/community/main/community_main.dart`.

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -20
```

Run app → walk to community tab → confirm nothing is broken visually.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/community/ lib/
git commit -m "refactor(community): C7 — split community_main into main/ subfolder"
```

---

## C8 — refactor(community): split community_card into card/

**Files:**
- Create dir: `lib/pages/community/card/`
- `git mv` + split: `community_card.dart` → `card/community_card.dart` (~300) + `card/community_card_avatar.dart` + `card/community_card_meta.dart` + `card/community_card_actions.dart`

- [ ] **Step 1: Move + create dir**

```bash
mkdir -p lib/pages/community/card
git mv lib/pages/community/community_card.dart lib/pages/community/card/community_card.dart
```

- [ ] **Step 2: Extract avatar widget**

`CommunityCardAvatar({required imageUrl, required name, this.isVip = false, this.isOnline = false})` — handles VIP frame + presence-dot placeholder (the dot itself wires up in C18). Place the `.withValues(alpha:)` corrections from C4 here.

- [ ] **Step 3: Extract meta widget**

`CommunityCardMeta({required community})` — name, age, native↔learning languages, language level badges. No actions.

- [ ] **Step 4: Extract actions widget**

`CommunityCardActions({required community, required onMessageTap, this.onWaveTap})` — message button + wave-button placeholder (filled in C14). For now the wave button can be a stub `IconButton(icon: Icons.waving_hand_rounded, onPressed: null)`.

- [ ] **Step 5: Update community_card.dart**

Composes the three child widgets. Should drop to ~300 lines.

- [ ] **Step 6: Update imports across the app**

```bash
grep -rln "pages/community/community_card.dart" lib/
```

Update each.

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -20
```

Manual smoke: every tab that uses community_card renders correctly.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/community/ lib/
git commit -m "refactor(community): C8 — split community_card into card/ subfolder"
```

---

## C9 — refactor(community): split community_filter into filter/ + FilterState

**Files:**
- Create dir: `lib/pages/community/filter/`
- New: `filter/filter_state.dart`
- `git mv`: `community_filter.dart` → `filter/community_filter_sheet.dart` then split into 8 section files

> **Note:** The redesigned UX (sticky bars, match count, ExpansionTile collapse) lands in **C19**. C9 is structural-only: typed `FilterState`, sections live in their own files but **all share the parent sheet's state via the existing data flow** — do NOT change the props/contract per section yet. The `(filterState, onChanged) → FilterState` widget contract is C19's job. C9 should leave the sheet's overall data flow identical.

- [ ] **Step 1: Create filter/ + move root**

```bash
mkdir -p lib/pages/community/filter
git mv lib/pages/community/community_filter.dart lib/pages/community/filter/community_filter_sheet.dart
```

- [ ] **Step 2: Create `filter_state.dart`**

```dart
class FilterState {
  final int minAge;
  final int maxAge;
  final String? gender;
  final String? nativeLanguage;
  final String? learningLanguage;
  final String? country;
  final List<String> topics;
  final String? languageLevel;
  final bool onlineOnly;
  final bool newUsersOnly;
  final bool prioritizeNearby;

  const FilterState({
    this.minAge = 18,
    this.maxAge = 100,
    this.gender,
    this.nativeLanguage,
    this.learningLanguage,
    this.country,
    this.topics = const [],
    this.languageLevel,
    this.onlineOnly = false,
    this.newUsersOnly = false,
    this.prioritizeNearby = false,
  });

  FilterState copyWith({
    int? minAge,
    int? maxAge,
    String? gender,
    String? nativeLanguage,
    String? learningLanguage,
    String? country,
    List<String>? topics,
    String? languageLevel,
    bool? onlineOnly,
    bool? newUsersOnly,
    bool? prioritizeNearby,
  }) =>
      FilterState(
        minAge: minAge ?? this.minAge,
        maxAge: maxAge ?? this.maxAge,
        gender: gender ?? this.gender,
        nativeLanguage: nativeLanguage ?? this.nativeLanguage,
        learningLanguage: learningLanguage ?? this.learningLanguage,
        country: country ?? this.country,
        topics: topics ?? this.topics,
        languageLevel: languageLevel ?? this.languageLevel,
        onlineOnly: onlineOnly ?? this.onlineOnly,
        newUsersOnly: newUsersOnly ?? this.newUsersOnly,
        prioritizeNearby: prioritizeNearby ?? this.prioritizeNearby,
      );

  Map<String, dynamic> toJson() => {
        'minAge': minAge,
        'maxAge': maxAge,
        'gender': gender,
        'nativeLanguage': nativeLanguage,
        'learningLanguage': learningLanguage,
        'country': country,
        'topics': topics,
        'languageLevel': languageLevel,
        'onlineOnly': onlineOnly,
        'newUsersOnly': newUsersOnly,
        'prioritizeNearby': prioritizeNearby,
      };

  /// Backwards-compat reader for the old `Map<String, dynamic>` shape stored
  /// under SharedPreferences key `community_filters`.
  factory FilterState.fromJson(Map<String, dynamic> json) => FilterState(
        minAge: json['minAge'] as int? ?? 18,
        maxAge: json['maxAge'] as int? ?? 100,
        gender: json['gender'] as String?,
        nativeLanguage: json['nativeLanguage'] as String?,
        learningLanguage: json['learningLanguage'] as String?,
        country: json['country'] as String?,
        topics: List<String>.from(json['topics'] ?? const []),
        languageLevel: json['languageLevel'] as String?,
        onlineOnly: json['onlineOnly'] as bool? ?? false,
        newUsersOnly: json['newUsersOnly'] as bool? ?? false,
        prioritizeNearby: json['prioritizeNearby'] as bool? ?? false,
      );

  static const FilterState defaults = FilterState();
}
```

- [ ] **Step 3: Update CommunityMain to use FilterState**

In `lib/pages/community/main/community_main.dart`, replace `Map<String, dynamic> _filters` with `FilterState _filters`. Update `_loadSavedFilters` and `_saveFilters` to use `FilterState.fromJson` / `toJson`. The Map-shape is preserved on disk so old saved filters still load.

- [ ] **Step 4: Split filter sheet into 7 section files (structural only)**

Read the current `community_filter_sheet.dart` to identify each visual section (Age range, Gender, Languages, Country, Topics, Language level, Other toggles — note the "Online-now" toggle is part of "Other toggles" in C9, then promoted/labeled in C18). Extract each into its own file as a private widget that **continues to receive whatever props/state the existing sheet passes down** (don't redesign data flow):

- `filter/filter_age_section.dart`
- `filter/filter_gender_section.dart`
- `filter/filter_languages_section.dart`
- `filter/filter_country_section.dart`
- `filter/filter_topics_section.dart`
- `filter/filter_level_section.dart`
- `filter/filter_toggles_section.dart`

Each is a `StatefulWidget` or `StatelessWidget` matching whatever the original section was. Keep all existing callbacks/keys/state shapes the same. The shell file (`community_filter_sheet.dart`) imports them and composes them in the same order/UX as before. **Goal of C9: same UX, same behavior, just smaller files.** C19 then rewrites the data-flow contract + adds match count + ExpansionTile.

- [ ] **Step 5: Update imports**

```bash
grep -rln "community_filter.dart" lib/
```

Each importer → `pages/community/filter/community_filter_sheet.dart`.

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -20
```

Manual smoke: open filter sheet, change every section, apply, reopen — confirm persistence.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/community/ lib/
git commit -m "refactor(community): C9 — split community_filter into filter/ + FilterState"
```

---

## C10 — refactor(community): split single_community into single/

**Files:**
- Create dir: `lib/pages/community/single/`
- `git mv` + split: `single_community.dart` (2,532 lines) → `single/single_community_screen.dart` (~600) + 7 section files

- [ ] **Step 1: Move + dir**

```bash
mkdir -p lib/pages/community/single
git mv lib/pages/community/single_community.dart lib/pages/community/single/single_community_screen.dart
```

- [ ] **Step 2: Extract sections into focused files**

Read `single_community_screen.dart` to identify the visual sections of the profile detail. Extract each:

- `single/single_community_header.dart` — avatar, name, location, follow CTA
- `single/single_community_languages.dart` — wraps `LanguageMatchCard` (no functional change)
- `single/single_community_engagement.dart` — wraps `EngagementStatsBar`
- `single/single_community_starters.dart` — wraps `ConversationStartersCard`
- `single/single_community_actions.dart` — wave/message/more (block/report) row
- `single/single_community_tabs.dart` — About/Moments/Photos tab strip

Each section receives the `Community` model + relevant callbacks. State (block, follow, refresh, tab controller) stays in the screen-level `_SingleCommunityState`.

> **Note:** `single/single_community_topics.dart` for mutual interests is created in **C16**, not here.

- [ ] **Step 3: Update imports across the app**

```bash
grep -rln "pages/community/single_community.dart" lib/
```

Update each (chat, profile_visitor, search results, push notification handlers may all import this).

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -20
```

Manual smoke: tap a profile → walk every section → tap follow → tap message → tap block → tap report → tap About/Moments/Photos. All should behave identically to pre-refactor.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/ lib/
git commit -m "refactor(community): C10 — split single_community (2,532) into single/"
```

---

## C11 — refactor(community): flatten tabs/ + extract big-tab helpers

**Files:**
- Create dir: `lib/pages/community/tabs/`
- `git mv` 6 tab files → `tabs/`
- Extract embedded helpers from each big tab to either `widgets/` (if reusable) or stay inline as `_PrivateName` (if not)

- [ ] **Step 1: Move tab files**

```bash
mkdir -p lib/pages/community/tabs
git mv lib/pages/community/partner_discovery_tab.dart lib/pages/community/tabs/
git mv lib/pages/community/nearby_tab.dart lib/pages/community/tabs/
git mv lib/pages/community/city_tab.dart lib/pages/community/tabs/
git mv lib/pages/community/genders_tab.dart lib/pages/community/tabs/
git mv lib/pages/community/topics_tab.dart lib/pages/community/tabs/
git mv lib/pages/community/waves_tab.dart lib/pages/community/tabs/
```

(Voice rooms tab stays in `voice_rooms/voice_rooms_tab.dart` — that folder gets its own deeper split in C12.)

- [ ] **Step 2: Slim each big tab**

For each of `partner_discovery_tab.dart` (1,274), `nearby_tab.dart` (1,188), `city_tab.dart` (1,054), `genders_tab.dart` (931): extract embedded list-item widgets, embedded filter rows, embedded skeleton loaders into private classes within the same file (or pull truly reusable widgets up to `widgets/`). Target ~600 lines for partner_discovery and nearby, ~500 for city and genders.

> **Pragmatic note:** Don't force decomposition where the existing structure is already clear. If a tab has one giant `build` method with inline column children, just split that into a few `_buildSection()` private methods. The goal is comprehensibility, not file count.

- [ ] **Step 3: Replace inline `Colors.grey/white` calls (carryover from C4 if any missed)**

```bash
grep -rn "Colors.grey\|Colors.white\b" lib/pages/community/tabs/
```

Sweep any leftovers.

- [ ] **Step 4: Update imports**

```bash
grep -rln "pages/community/partner_discovery_tab\|pages/community/nearby_tab\|pages/community/city_tab\|pages/community/genders_tab\|pages/community/topics_tab\|pages/community/waves_tab" lib/
```

Update each importer to `pages/community/tabs/<file>.dart`.

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -20
```

Manual smoke: walk all 7 tabs (well, 6 still — Waves is wired into TabController in C13). Check pull-to-refresh, infinite scroll, filter application.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/community/ lib/
git commit -m "refactor(community): C11 — flatten tabs into tabs/, extract helpers from big tabs"
```

---

## C12 — refactor(community): split voice_rooms/ into focused units

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_rooms_tab.dart` (578 → ~300)
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` (556 → ~300)
- Create: `lib/pages/community/voice_rooms/voice_room_header.dart`
- Create: `lib/pages/community/voice_rooms/voice_room_info_bar.dart`
- Create: `lib/pages/community/voice_rooms/voice_room_participants_grid.dart`
- Create: `lib/pages/community/voice_rooms/voice_room_participant_tile.dart`
- Create: `lib/pages/community/voice_rooms/voice_room_controls.dart`

> **Note:** `voice_room_chat_panel.dart`, `voice_room_host_menu.dart`, `voice_room_reconnect_banner.dart` are created in C20, C23, C25 respectively.

- [ ] **Step 1: Drop hardcoded language list in voice_rooms_tab**

The `_languages` const list at lines 31-45 should consume the `languages` API endpoint instead. Replace with a `FutureBuilder` that calls `LanguageService.getAll()` (verify the actual provider/service used in registration flow). For now if rewiring is invasive, leave the const list with a `// TODO: source from languages API (C13+)` and split is fine.

- [ ] **Step 2: Extract `_buildHeader` from voice_rooms_tab to a method/widget**

Either keep as `_buildHeader()` private method or pull to `widgets/voice_rooms_header.dart` if reused. Most likely keep private.

- [ ] **Step 3: Extract `_ParticipantTile` (in voice_room_screen.dart) to its own file**

The `_ParticipantTile` class (lines 365-502 of `voice_room_screen.dart`) becomes `voice_room_participant_tile.dart`. Make it public: `class VoiceRoomParticipantTile extends StatelessWidget`. Add fields for hand-raise (`isHandRaised: bool`, default false — wired in C21).

- [ ] **Step 4: Extract `_ControlButton` to voice_room_controls.dart**

The `_ControlButton` (lines 504-557) becomes `class _ControlButton` private inside `voice_room_controls.dart`. The new `VoiceRoomControls` widget composes mute / hand-raise / leave (or end-room when host — leave the conditional empty for now, fill in C23).

- [ ] **Step 5: Extract participants grid + room info bar + header**

- `voice_room_header.dart`: app bar + duration badge (extracted from the AppBar `actions` in voice_room_screen.dart)
- `voice_room_info_bar.dart`: language + participant count chip row (lines ~198-263)
- `voice_room_participants_grid.dart`: the `GridView.builder` block (lines ~284-311) — takes participants list + onTap callback

- [ ] **Step 6: Compose voice_room_screen.dart**

Reduces to ~300 lines: app bar (using `VoiceRoomHeader`), body = Column of [`VoiceRoomInfoBar`, Expanded(`VoiceRoomParticipantsGrid`), `VoiceRoomControls`].

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/ 2>&1 | tail -10
```

Manual smoke: open voice rooms tab → create room → join → leave. Confirm everything renders the same as before split.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/community/voice_rooms/
git commit -m "refactor(community): C12 — split voice_rooms/ into focused units"
```

---

## C13 — feat(community): wire WavesTab into CommunityMain (7th tab + unread badge)

**Files:**
- Modify: `lib/pages/community/main/community_main.dart`
- Modify: `lib/pages/community/main/community_tab_bar.dart`
- New: in `lib/providers/provider_root/community_provider.dart` — `wavesUnreadProvider`

- [ ] **Step 1: Add `wavesUnreadProvider`**

In `community_provider.dart`, add at the bottom:

```dart
/// Returns the count of unread waves for the current user. Refresh on
/// app resume and after `markWavesAsRead`.
final wavesUnreadProvider = FutureProvider<int>((ref) async {
  final service = ref.read(communityServiceProvider);
  try {
    final waves = await service.getWavesReceived(unreadOnly: true, limit: 100);
    return waves.length;
  } catch (e) {
    return 0;
  }
});
```

- [ ] **Step 2: Update CommunityMain TabController length 6 → 7**

In `community_main.dart`, change `_tabController = TabController(length: 6, ...)` → `length: 7`.

- [ ] **Step 3: Add WavesTab to the children of TabBarView**

```dart
const WavesTab(),
```

Place it after `VoiceRoomsTab` (or wherever in the order makes sense — recommend **last** so it's a destination from the unread badge).

- [ ] **Step 4: Add Tab entry to CommunityTabBar**

Match the styling of existing tabs (read `community_main.dart`'s current `Tab(text: ...)` or `Tab(icon:..., text:...)` shape and mirror it). Wrap the localized title in a Stack that overlays an unread dot.

```dart
Tab(
  child: Consumer(builder: (_, ref, __) {
    final l10n = AppLocalizations.of(context)!;
    final unread = ref.watch(wavesUnreadProvider).maybeWhen(
          data: (n) => n,
          orElse: () => 0,
        );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Match the text style used by the other Tab(text:) entries.
        Text(l10n.wavesTab),
        if (unread > 0)
          Positioned(
            right: -10,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }),
),
```

**Note:** the C5 ARB list adds `wavesTab` for this string. If the existing tabs use the `Tab(text:)` shape with implicit styling, you may need to wrap the entire `Tab` (not just its child) in `DefaultTextStyle.merge` to keep visual parity — verify on-device after C13.

- [ ] **Step 5: Invalidate the provider after `markWavesAsRead`**

In `WavesTab._loadWaves`, after calling `service.markWavesAsRead()`:

```dart
ref.invalidate(wavesUnreadProvider);
```

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Manual smoke: tab strip shows 7 tabs (scrollable on small phones); tapping Waves shows the existing list; if there are unread waves, the dot appears and clears after the list loads.

- [ ] **Step 7: Commit**

```bash
git add lib/
git commit -m "feat(community): C13 — wire WavesTab into CommunityMain (7th tab + unread badge)"
```

---

## C14 — feat(community): wave button + quick-reply sheet + mutual-wave dialog

**Files:**
- New: `lib/pages/community/widgets/wave_button.dart`
- New: `lib/pages/community/widgets/send_wave_sheet.dart`
- New: `lib/pages/community/widgets/mutual_wave_dialog.dart`
- Modify: `lib/pages/community/card/community_card_actions.dart`
- Modify: `lib/pages/community/single/single_community_actions.dart`

- [ ] **Step 1: Create `wave_button.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class WaveButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserCountry;
  final bool greyedOut; // true when in cooldown
  final String? cooldownText;
  final VoidCallback? onSent;

  const WaveButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserCountry,
    this.greyedOut = false,
    this.cooldownText,
    this.onSent,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: greyedOut ? (cooldownText ?? '') : '',
      child: IconButton(
        icon: Icon(
          Icons.waving_hand_rounded,
          color: greyedOut ? context.textMuted : AppColors.primary,
        ),
        onPressed: greyedOut
            ? null
            : () => showSendWaveSheet(
                  context,
                  targetUserId: targetUserId,
                  targetUserName: targetUserName,
                  targetUserCountry: targetUserCountry,
                  onSent: onSent,
                ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `send_wave_sheet.dart`**

Bottom sheet with 6 quick-reply chips + free-text option. On send, call `communityService.sendWave(targetUserId: ..., message: ...)`. Handle response: if `isMutual`, show `MutualWaveDialog`; else success snackbar. Cache `lastSentAt` in SharedPreferences.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/community_dialog_scaffold.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/widgets/mutual_wave_dialog.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

const _waveCooldownPrefsPrefix = 'wave_cooldown_';

Future<void> showSendWaveSheet(
  BuildContext context, {
  required String targetUserId,
  required String targetUserName,
  String? targetUserCountry,
  VoidCallback? onSent,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _SendWaveSheet(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserCountry: targetUserCountry,
      onSent: onSent,
    ),
  );
}

class _SendWaveSheet extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserCountry;
  final VoidCallback? onSent;

  const _SendWaveSheet({
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserCountry,
    this.onSent,
  });

  @override
  ConsumerState<_SendWaveSheet> createState() => _SendWaveSheetState();
}

class _SendWaveSheetState extends ConsumerState<_SendWaveSheet> {
  final TextEditingController _customController = TextEditingController();
  String? _selectedQuickReply;
  bool _isSending = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  List<String> _quickReplies(AppLocalizations l10n) => [
        '👋 ${l10n.waveQuickReplyHi}',
        '❤️ ${l10n.waveQuickReplyCool}',
        '😊 ${l10n.waveQuickReplyHey}',
        '🎉 ${l10n.waveQuickReplyChat}',
        '✋ ${l10n.waveQuickReplyHello}',
        if (widget.targetUserCountry != null)
          '🌟 ${l10n.waveQuickReplyFromCountry(widget.targetUserCountry!)}',
      ];

  Future<void> _send() async {
    if (_isSending) return;
    final l10n = AppLocalizations.of(context)!;
    final message = _customController.text.trim().isNotEmpty
        ? _customController.text.trim()
        : (_selectedQuickReply ?? '👋');
    setState(() => _isSending = true);
    try {
      final response = await ref.read(communityServiceProvider).sendWave(
            targetUserId: widget.targetUserId,
            message: message,
          );
      // Cache cooldown
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$_waveCooldownPrefsPrefix${widget.targetUserId}',
        DateTime.now().millisecondsSinceEpoch,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSent?.call();
      if (response.isMutual) {
        showMutualWaveDialog(context, name: widget.targetUserName,
            targetUserId: widget.targetUserId);
      } else {
        showCommunitySnackBar(
          context,
          message: l10n.waveSent(widget.targetUserName),
          type: CommunitySnackBarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      final isRateLimited = e.toString().contains('Too many waves');
      showCommunitySnackBar(
        context,
        message: isRateLimited
            ? l10n.waveCooldown(widget.targetUserName, '24h')
            : l10n.waveCouldntSend,
        type: CommunitySnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CommunityDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.sendWaveTo(widget.targetUserName),
              style: context.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReplies(l10n)
                .map((reply) => ChoiceChip(
                      label: Text(reply),
                      selected: _selectedQuickReply == reply,
                      onSelected: (selected) => setState(() {
                        _selectedQuickReply = selected ? reply : null;
                        _customController.clear();
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            onChanged: (_) => setState(() => _selectedQuickReply = null),
            decoration: InputDecoration(
              hintText: l10n.waveCustomMessage,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_selectedQuickReply == null &&
                    _customController.text.trim().isEmpty) ||
                    _isSending
                ? null
                : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_isSending ? '…' : l10n.sendWave),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `mutual_wave_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

void showMutualWaveDialog(
  BuildContext context, {
  required String name,
  required String targetUserId,
}) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(l10n.itsAMatch,
              style: context.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l10n.itsAMatchSubtitle(name),
              textAlign: TextAlign.center, style: context.bodyMedium),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Later'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(dialogContext);
            // Open chat with the matched user; reuse existing chat route.
            context.push('/chat/$targetUserId');
          },
          child: Text(l10n.sendAMessage),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Wire wave button into community_card_actions.dart**

Replace the stub `IconButton` from C8 with the real `WaveButton`. Pass `targetUserId`, `targetUserName`, `targetUserCountry` from the community model. Read the cooldown timestamp from SharedPreferences to set `greyedOut` + `cooldownText`:

```dart
// Inside the stateful widget's build or via a small helper provider
Future<bool> _isInCooldown(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final lastMs = prefs.getInt('${_waveCooldownPrefsPrefix}$userId');
  if (lastMs == null) return false;
  return DateTime.now().millisecondsSinceEpoch - lastMs < 24 * 3600 * 1000;
}
```

(Or use a `FutureProvider.family` to keep the check reactive across rebuilds.)

- [ ] **Step 5: Wire wave button into single_community_actions.dart**

Same pattern, but as a full-width button alongside the message CTA.

- [ ] **Step 6: Hide wave button on own profile**

Both `community_card_actions.dart` and `single_community_actions.dart` should not render the wave button when `community.id == authService.userId`. Mirror existing follow-button logic.

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Manual smoke (assume backend C15 is also wired or stubbed): open a profile → tap wave → pick quick reply → send → see toast. Trigger mutual response (manually have another account wave back first) → see celebration dialog. Reopen the same profile → button should be greyed out.

- [ ] **Step 8: Commit**

```bash
git add lib/
git commit -m "feat(community): C14 — wave button, quick-reply sheet, mutual-wave dialog"
```

---

## C15 — feat(community) + backend: confirm/implement POST community/wave + rate limit + push

**Files (backend):**
- Verify or create: `routes/community.js` (or wherever `community/*` routes live) — `POST /wave`
- Verify or create: `controllers/communityController.js` — `sendWave` handler
- Verify or create: `models/Wave.js` — schema with required indexes
- Verify or create: `services/notifications.js` — `sendWaveNotification(targetUserId, fromUserId, message)`

> **Backend project root** — wave 1 spec assumes a separate Node.js/Express + MongoDB backend. Adjust paths to match the actual backend repo layout.

- [ ] **Step 1: Verify backend endpoint exists**

From the Flutter project, hit the endpoint manually:

```bash
curl -X POST "$API_BASE/community/wave" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"targetUserId": "<test-user-id>", "message": "👋 Hi"}'
```

If 404, the endpoint doesn't exist yet — implement per below. If 200 with `{waveId, isMutual, message}`, skip to Step 5.

- [ ] **Step 2: Define `Wave.js` schema**

```js
const mongoose = require('mongoose');

const waveSchema = new mongoose.Schema({
  fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  targetUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  message: { type: String, default: '👋' },
  isRead: { type: Boolean, default: false },
}, { timestamps: true });

waveSchema.index({ fromUserId: 1, targetUserId: 1, createdAt: -1 });
waveSchema.index({ targetUserId: 1, isRead: 1, createdAt: -1 });

module.exports = mongoose.model('Wave', waveSchema);
```

- [ ] **Step 3: Implement `sendWave` controller**

```js
exports.sendWave = async (req, res, next) => {
  try {
    const fromUserId = req.user.id;
    const { targetUserId, message } = req.body;

    if (!targetUserId) return res.status(400).json({ error: 'targetUserId required' });
    if (String(targetUserId) === String(fromUserId)) {
      return res.status(400).json({ error: 'Cannot wave yourself' });
    }

    // Block check
    const target = await User.findById(targetUserId).select('blockedUsers');
    if (!target) return res.status(404).json({ error: 'User not found' });
    if (target.blockedUsers?.some(id => String(id) === String(fromUserId))) {
      return res.status(403).json({ error: 'Cannot send wave' });
    }

    // Rate limit
    const cooldownHours = parseInt(process.env.WAVE_COOLDOWN_HOURS || '24', 10);
    const cooldownMs = cooldownHours * 3600 * 1000;
    const recent = await Wave.findOne({
      fromUserId,
      targetUserId,
      createdAt: { $gte: new Date(Date.now() - cooldownMs) },
    });
    if (recent) {
      return res.status(429).json({
        error: 'Too many waves',
        retryAfter: Math.ceil((recent.createdAt.getTime() + cooldownMs - Date.now()) / 1000),
      });
    }

    // Create wave
    const wave = await Wave.create({ fromUserId, targetUserId, message: message || '👋' });

    // Mutual check: did targetUser previously wave fromUser?
    const reverseWave = await Wave.findOne({
      fromUserId: targetUserId,
      targetUserId: fromUserId,
    });
    const isMutual = !!reverseWave;

    // Push notification (fire-and-forget)
    sendWaveNotification(targetUserId, fromUserId, message).catch(() => {});

    return res.json({ waveId: wave._id, isMutual, message: 'Wave sent!' });
  } catch (e) {
    next(e);
  }
};
```

- [ ] **Step 4: Wire into router**

```js
// routes/community.js
router.post('/wave', authMiddleware, communityController.sendWave);
```

- [ ] **Step 5: Implement `sendWaveNotification`**

In the existing notifications service, add:

```js
exports.sendWaveNotification = async (targetUserId, fromUserId, message) => {
  const fromUser = await User.findById(fromUserId).select('name images');
  const targetUser = await User.findById(targetUserId).select('fcmToken');
  if (!targetUser?.fcmToken) return;

  // Coalesce: count unread waves received in last 6h. If > 3, suppress per-wave push.
  const recentUnreadCount = await Wave.countDocuments({
    targetUserId,
    isRead: false,
    createdAt: { $gte: new Date(Date.now() - 6 * 3600 * 1000) },
  });
  if (recentUnreadCount > 3) {
    // Daily summary cron handles this case; return.
    return;
  }

  await admin.messaging().send({
    token: targetUser.fcmToken,
    notification: {
      title: `${fromUser.name} waved at you`,
      body: message || '👋',
    },
    data: {
      type: 'wave_received',
      fromUserId: String(fromUserId),
      route: '/community?tab=waves',
    },
  });
};
```

- [ ] **Step 6: Add unit tests**

In the backend repo's test suite, add tests for:
- 400 when `targetUserId` missing or self
- 403 when blocked
- 429 when within cooldown window
- 200 with `{waveId, isMutual: false, message}` on first wave
- 200 with `{waveId, isMutual: true, ...}` when target previously waved sender

- [ ] **Step 7: Verify Flutter end-to-end**

Run app on physical device → tap wave on a real partner → confirm:
- Real `WaveResponse.waveId` appears in console logs
- Recipient device gets a push notification
- Tapping the notification opens the app on the Waves tab

- [ ] **Step 8: Commit**

In the backend repo:

```bash
git add models/Wave.js controllers/communityController.js routes/community.js services/notifications.js __tests__/
git commit -m "feat(community): C15 — POST /community/wave with rate limit, mutual detection, push"
```

In the Flutter repo (no Flutter changes for C15 if everything else was wired in C14):

```bash
git commit --allow-empty -m "feat(community): C15 — wire backend POST community/wave (backend repo)"
```

---

## C16 — feat(community): mutual interests on single_community (D)

**Files:**
- New: `lib/pages/community/single/single_community_topics.dart`
- Modify: `lib/pages/community/single/single_community_screen.dart`

- [ ] **Step 1: Create the section widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class SingleCommunityTopics extends ConsumerWidget {
  final Community community;
  const SingleCommunityTopics({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myTopics = ref.watch(userProvider).maybeWhen(
          data: (u) => u?.topics ?? const <String>[],
          orElse: () => const <String>[],
        );
    final theirTopics = community.topics ?? const <String>[];
    final shared = theirTopics.where((t) => myTopics.contains(t)).toList();
    final notShared = theirTopics.where((t) => !myTopics.contains(t)).toList();

    if (theirTopics.isEmpty || myTopics.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    final visible = [...shared, ...notShared].take(6).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mutualInterests, style: context.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.interestsInCommon(shared.length),
              style: context.bodySmall.copyWith(color: context.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visible.map((topicId) {
              final isShared = shared.contains(topicId);
              return Chip(
                label: Text(topicId),
                avatar: isShared
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
                backgroundColor: isShared
                    ? AppColors.primary
                    : context.containerColor,
                labelStyle: TextStyle(
                  color: isShared ? Colors.white : context.textSecondary,
                ),
                side: BorderSide(
                  color: isShared ? AppColors.primary : context.dividerColor,
                ),
              );
            }).toList(),
          ),
          if (theirTopics.length > 6)
            TextButton(
              onPressed: () => _showAllTopics(context, theirTopics, shared),
              child: Text(l10n.interestsInCommonSeeAll),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Text(l10n.interestsInCommon(0), style: context.bodyMedium),
          const SizedBox(height: 8),
          Text(l10n.interestsInCommonAddSubtitle,
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(color: context.textMuted)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile/topics'),
            child: Text(l10n.interestsInCommonAddCta),
          ),
        ],
      ),
    );
  }

  void _showAllTopics(BuildContext context, List<String> all, List<String> shared) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.mutualInterests),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: all.map((t) {
              final isShared = shared.contains(t);
              return Chip(
                label: Text(t),
                avatar: isShared
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
                backgroundColor: isShared ? AppColors.primary : null,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Insert into single_community_screen.dart**

Place between `SingleCommunityLanguages` and `SingleCommunityEngagement` in the scroll body:

```dart
SingleCommunityLanguages(community: _community),
SingleCommunityTopics(community: _community),
SingleCommunityEngagement(community: _community),
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/pages/community/single/ 2>&1 | tail -10
```

Manual smoke: open 3 different profiles — one with all-shared topics, one with mixed, one with empty topics. Confirm correct rendering. Tap "See all" if > 6 topics.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/community/single/single_community_topics.dart lib/pages/community/single/single_community_screen.dart
git commit -m "feat(community): C16 — mutual interests section on single_community"
```

---

## C17 — feat(community) + backend: presence socket events + presence_provider

**Files (backend):**
- Modify: socket server (likely `socket/index.js` or similar) — add `presence:online` / `presence:offline` / `presence:bulk` emit
- Modify: `models/User.js` — add `lastSeenAt: Date` field

**Files (Flutter):**
- New: `lib/providers/presence_provider.dart`
- Modify: `lib/services/chat_socket_service.dart` — add `onPresenceChanged` stream

- [ ] **Step 1: Backend — add `lastSeenAt` to User model**

```js
// models/User.js — add field
lastSeenAt: { type: Date, default: null },
```

Add an index:
```js
userSchema.index({ lastSeenAt: -1 });
```

- [ ] **Step 2: Backend — presence broadcast**

In the socket server module, on `connection`:

```js
io.on('connection', (socket) => {
  const userId = socket.userId; // assumes auth middleware attaches this
  if (!userId) return;

  presenceStore.set(userId, { socketId: socket.id, lastSeenAt: new Date() });

  // Broadcast online to followers + active conversation partners
  const interestedIds = await getInterestedSubscribers(userId); // followers + conv partners
  interestedIds.forEach(id => {
    const subSocketId = presenceStore.get(id)?.socketId;
    if (subSocketId) io.to(subSocketId).emit('presence:online', { userId });
  });

  // Initial bulk push to this user (cap 200)
  const onlineSubset = [...presenceStore.keys()]
    .filter(id => interestedIds.includes(id))
    .slice(0, 200);
  socket.emit('presence:bulk', { onlineUserIds: onlineSubset });

  socket.on('disconnect', async () => {
    const lastSeenAt = new Date();
    presenceStore.delete(userId);
    await User.updateOne({ _id: userId }, { lastSeenAt });
    interestedIds.forEach(id => {
      const subSocketId = presenceStore.get(id)?.socketId;
      if (subSocketId) {
        io.to(subSocketId).emit('presence:offline', {
          userId, lastSeenAt: lastSeenAt.toISOString()
        });
      }
    });
  });
});
```

`getInterestedSubscribers(userId)` returns the union of (a) users who follow `userId`, (b) users with whom `userId` has an active chat thread. Cap union at 200.

- [ ] **Step 3: Flutter — extend chat_socket_service**

Add three streams + emit handlers in `lib/services/chat_socket_service.dart`:

```dart
final _presenceOnlineController = StreamController<Map<String, dynamic>>.broadcast();
final _presenceOfflineController = StreamController<Map<String, dynamic>>.broadcast();
final _presenceBulkController = StreamController<List<String>>.broadcast();

Stream<Map<String, dynamic>> get onPresenceOnline => _presenceOnlineController.stream;
Stream<Map<String, dynamic>> get onPresenceOffline => _presenceOfflineController.stream;
Stream<List<String>> get onPresenceBulk => _presenceBulkController.stream;

// Inside the socket setup (where other listeners are wired):
_socket?.on('presence:online', (data) => _presenceOnlineController.add(Map<String, dynamic>.from(data)));
_socket?.on('presence:offline', (data) => _presenceOfflineController.add(Map<String, dynamic>.from(data)));
_socket?.on('presence:bulk', (data) {
  final ids = (data['onlineUserIds'] as List).cast<String>();
  _presenceBulkController.add(ids);
});
```

Don't forget `dispose` to close the controllers.

- [ ] **Step 4: Flutter — create presence_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

class PresenceState {
  final Set<String> onlineUserIds;
  final Map<String, DateTime> lastSeen;

  const PresenceState({
    this.onlineUserIds = const {},
    this.lastSeen = const {},
  });

  bool isOnline(String userId) => onlineUserIds.contains(userId);

  PresenceState withOnline(String userId) =>
      PresenceState(onlineUserIds: {...onlineUserIds, userId}, lastSeen: lastSeen);

  PresenceState withOffline(String userId, DateTime at) => PresenceState(
        onlineUserIds: onlineUserIds.where((id) => id != userId).toSet(),
        lastSeen: {...lastSeen, userId: at},
      );

  PresenceState withBulk(List<String> ids) =>
      PresenceState(onlineUserIds: ids.toSet(), lastSeen: lastSeen);
}

class PresenceNotifier extends StateNotifier<PresenceState> {
  PresenceNotifier(this._socket) : super(const PresenceState()) {
    _subOnline = _socket.onPresenceOnline.listen((data) {
      final id = data['userId'] as String;
      state = state.withOnline(id);
    });
    _subOffline = _socket.onPresenceOffline.listen((data) {
      final id = data['userId'] as String;
      final at = DateTime.tryParse(data['lastSeenAt'] as String? ?? '') ?? DateTime.now();
      state = state.withOffline(id, at);
    });
    _subBulk = _socket.onPresenceBulk.listen((ids) {
      state = state.withBulk(ids);
    });
  }

  final ChatSocketService _socket;
  late final StreamSubscription _subOnline;
  late final StreamSubscription _subOffline;
  late final StreamSubscription _subBulk;

  @override
  void dispose() {
    _subOnline.cancel();
    _subOffline.cancel();
    _subBulk.cancel();
    super.dispose();
  }
}

final presenceProvider = StateNotifierProvider<PresenceNotifier, PresenceState>((ref) {
  return PresenceNotifier(ChatSocketService());
});
```

- [ ] **Step 5: Verify (no UI yet — that's C18)**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Manual smoke: open the app on two devices with mutual followers, attach to console logs of one. When the other connects, expect `presence:online` log. When the other disconnects, expect `presence:offline`.

- [ ] **Step 6: Commit (Flutter + backend)**

Backend:
```bash
git add models/User.js socket/ __tests__/
git commit -m "feat(community): C17 — presence:online/offline/bulk socket events + lastSeenAt"
```

Flutter:
```bash
git add lib/services/chat_socket_service.dart lib/providers/presence_provider.dart
git commit -m "feat(community): C17 — presence socket integration + presenceProvider"
```

---

## C18 — feat(community): online-now dot + filter toggle (E frontend complete)

**Files:**
- Modify: `lib/pages/community/card/community_card_avatar.dart`
- Modify: `lib/pages/community/single/single_community_header.dart`
- Modify: `lib/pages/community/filter/filter_toggles_section.dart`
- Modify: tab fetch logic (likely in `tabs/partner_discovery_tab.dart`, etc.) to pass `?online=true`

- [ ] **Step 1: Add green dot to community_card_avatar.dart**

Wrap the avatar Stack with an additional `Positioned` indicator:

```dart
Consumer(builder: (context, ref, _) {
  final isOnline = ref.watch(presenceProvider.select((p) => p.isOnline(userId)));
  if (!isOnline) return const SizedBox.shrink();
  return Positioned(
    bottom: 2,
    right: 2,
    child: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    ),
  );
}),
```

- [ ] **Step 2: Add presence pill to single_community_header.dart**

```dart
Consumer(builder: (context, ref, _) {
  final state = ref.watch(presenceProvider);
  final isOnline = state.isOnline(community.id);
  if (isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(l10n.onlineNow, style: const TextStyle(fontSize: 11, color: Colors.green)),
        ],
      ),
    );
  } else if (state.lastSeen[community.id] != null) {
    return Text(
      l10n.activeAgo(timeago.format(state.lastSeen[community.id]!)),
      style: context.bodySmall.copyWith(color: context.textMuted),
    );
  }
  return const SizedBox.shrink();
}),
```

- [ ] **Step 3: Add online-now toggle to filter_toggles_section.dart**

```dart
SwitchListTile(
  title: Text(l10n.filterOnlineNow),
  value: filterState.onlineOnly,
  onChanged: (v) => onChanged(filterState.copyWith(onlineOnly: v)),
),
```

- [ ] **Step 4: Wire `online=true` query param in tab fetch logic**

In each tab that calls the user-list service, append `online=true` if `filterState.onlineOnly`:

```dart
queryParams['online'] = 'true';
```

Backend's user-list endpoints filter by joining against the in-memory presence store. (Backend change in C17 already exposes presence; just need to plumb the query param through the controller.) Backend tweak:

```js
// in user-list controller
if (req.query.online === 'true') {
  const onlineIds = [...presenceStore.keys()];
  filter._id = { $in: onlineIds };
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Manual smoke (2 devices): connect device B → device A's community list shows green dot on B's card; toggle "Online now" filter on A → only B (and other online users) appear.

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "feat(community): C18 — online-now dot on cards + presence pill + filter toggle"
```

---

## C19 — feat(community): filter rebuild — match-count, sticky bars, sectioned (A)

**Files:**
- Modify: `lib/pages/community/filter/community_filter_sheet.dart`
- New: `lib/service/endpoints.dart` — `communityUsersCountURL` (`community/users/count`)
- Modify: `lib/providers/provider_root/community_provider.dart` — add `Future<int> getUsersCount(FilterState)` + `filterMatchCountProvider`
- Backend: new endpoint `GET community/users/count?<filters>` returning `{count}`

- [ ] **Step 1: Backend — implement count endpoint**

```js
// routes/community.js
router.get('/users/count', authMiddleware, communityController.getUsersCount);

// controllers/communityController.js
exports.getUsersCount = async (req, res, next) => {
  try {
    const filter = buildUserFilter(req.query); // existing helper
    const count = await User.countDocuments(filter);
    res.json({ count });
  } catch (e) { next(e); }
};
```

`buildUserFilter` should be the same helper used by the user-list endpoint so count and list always agree.

- [ ] **Step 2: Flutter — `getUsersCount`**

```dart
Future<int> getUsersCount(FilterState filters) async {
  final params = filters.toJson()..removeWhere((_, v) => v == null);
  final response = await _apiClient.get(
    Endpoints.communityUsersCountURL,
    queryParams: params.map((k, v) => MapEntry(k, v.toString())),
  );
  if (response.success && response.data?['count'] is int) {
    return response.data['count'] as int;
  }
  return 0;
}
```

Plus a `filterMatchCountProvider`:

```dart
final filterMatchCountProvider =
    FutureProvider.family<int, FilterState>((ref, filters) {
  return ref.read(communityServiceProvider).getUsersCount(filters);
});
```

- [ ] **Step 3: Rebuild `community_filter_sheet.dart` UX**

The sheet now has:
- Sticky top: filter title + live "{N} partners match" via the provider above (debounce changes by 300ms before invalidating)
- Scrollable body: each section in an `ExpansionTile` (Age + Gender expanded by default)
- Sticky bottom: "Clear all" (resets to `FilterState.defaults`) + "Apply" (returns FilterState)

Pseudocode:

```dart
class CommunityFilterSheet extends ConsumerStatefulWidget { ... }

class _CommunityFilterSheetState extends ConsumerState<CommunityFilterSheet> {
  late FilterState _draft;
  Timer? _debounce;

  void _onChanged(FilterState next) {
    setState(() => _draft = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.invalidate(filterMatchCountProvider(_draft));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final countAsync = ref.watch(filterMatchCountProvider(_draft));
    return Column(
      children: [
        // Sticky top
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(l10n.filterSheetTitle, style: context.titleLarge),
              const Spacer(),
              countAsync.maybeWhen(
                data: (n) => Text(l10n.filterMatchCount(n)),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Scrollable body
        Expanded(
          child: ListView(
            children: [
              FilterAgeSection(filterState: _draft, onChanged: _onChanged),
              FilterGenderSection(filterState: _draft, onChanged: _onChanged),
              FilterLanguagesSection(filterState: _draft, onChanged: _onChanged),
              FilterCountrySection(filterState: _draft, onChanged: _onChanged),
              FilterTopicsSection(filterState: _draft, onChanged: _onChanged),
              FilterLevelSection(filterState: _draft, onChanged: _onChanged),
              FilterTogglesSection(filterState: _draft, onChanged: _onChanged),
            ],
          ),
        ),
        // Sticky bottom
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => _onChanged(FilterState.defaults),
                child: Text(l10n.filterClearAll),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _draft),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.filterApply),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Wrap each section in `ExpansionTile`**

In each `filter_<section>.dart`, wrap the existing widget in `ExpansionTile` with the section title. Pass `initiallyExpanded: true` for Age + Gender; false for the rest.

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/ 2>&1 | tail -10
```

Manual smoke: open filter sheet → expand each section → tweak age/gender → match count updates after ~300ms (only one in-flight request observed via DevTools) → tap Apply → user list re-fetches; tap Reset → all filters clear.

- [ ] **Step 6: Verify backwards-compat**

Use a device that had filters saved under the pre-C9 `Map<String, dynamic>` shape (or simulate by writing a manual JSON to SharedPreferences). Confirm app loads without crashing and the typed `FilterState` reflects the saved values.

- [ ] **Step 7: Commit**

```bash
git add lib/
git commit -m "feat(community): C19 — filter rebuild with sticky bars, match count, sectioned (A)"
```

---

## C20 — feat(voice-rooms): in-room chat panel (C-i)

**Files:**
- New: `lib/pages/community/voice_rooms/voice_room_chat_panel.dart`
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` — host the panel as a `DraggableScrollableSheet`
- Modify: `lib/pages/community/voice_rooms/voice_room_controls.dart` — chat icon w/ unread badge

- [ ] **Step 1: Create `voice_room_chat_panel.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/services/voice_room_manager.dart';

class VoiceRoomChatPanel extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const VoiceRoomChatPanel({super.key, required this.scrollController});

  @override
  ConsumerState<VoiceRoomChatPanel> createState() => _VoiceRoomChatPanelState();
}

class _VoiceRoomChatPanelState extends ConsumerState<VoiceRoomChatPanel> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    ref.read(voiceRoomProvider).sendChat(text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = ref.watch(voiceRoomProvider).chatMessages;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF22223A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(l10n.voiceRoomChat,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              )),
          const SizedBox(height: 8),
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(l10n.voiceRoomChatEmpty,
                        style: const TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    reverse: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _ChatLine(messages[i]),
                  ),
          ),
          // Input
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l10n.voiceRoomChatPlaceholder,
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  final VoiceRoomChatMessage message;
  const _ChatLine(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${message.userName}: ',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: message.message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add chat icon to voice_room_controls.dart**

To the left of the mute button, add:

```dart
Consumer(builder: (context, ref, _) {
  final unread = ref.watch(voiceRoomProvider.select((p) =>
      p.chatMessages.length - widget.lastSeenChatCount));
  return Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        onPressed: widget.onChatToggle,
      ),
      if (unread > 0)
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
    ],
  );
}),
```

`onChatToggle` and `lastSeenChatCount` flow up from `voice_room_screen.dart`.

- [ ] **Step 3: Mount the panel in voice_room_screen.dart**

Wrap the room body in a Stack with a `DraggableScrollableSheet` overlay that's only visible when `_chatVisible == true`:

```dart
Stack(
  children: [
    Column(children: [_header, _info, Expanded(child: _grid), _controls]),
    if (_chatVisible)
      DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.0,
        maxChildSize: 0.85,
        builder: (_, scrollController) =>
            VoiceRoomChatPanel(scrollController: scrollController),
      ),
  ],
)
```

Toggle `_chatVisible` from the chat icon's `onChatToggle`. Reset `_lastSeenChatCount = chatMessages.length` whenever panel becomes visible.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/pages/community/voice_rooms/ 2>&1 | tail -10
```

Manual smoke (2-device): both join the same room → device A taps chat icon → types message → device B sees the chat panel slide up automatically? No — design is each device opens manually. So: confirm device B's chat icon shows badge "1" when A sends, and tapping opens the panel showing A's message.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/voice_rooms/
git commit -m "feat(voice-rooms): C20 — in-room chat panel with unread badge (C-i)"
```

---

## C21 — fix(voice-rooms): hand-raise visible on tile (C-ii)

**Files:**
- Modify: `lib/models/community/voice_room_model.dart` — add `isHandRaised` to `RoomParticipant`
- Modify: `lib/services/voice_room_manager.dart` — propagate hand-raise to participant
- Modify: `lib/pages/community/voice_rooms/voice_room_participant_tile.dart` — render badge

- [ ] **Step 1: Add field to model**

In `RoomParticipant`:

```dart
final bool isHandRaised;

const RoomParticipant({
  ...
  this.isHandRaised = false,
});

factory RoomParticipant.fromJson(Map<String, dynamic> json) {
  // ... existing parse
  return RoomParticipant(
    ...
    isHandRaised: json['isHandRaised'] == true,
  );
}

Map<String, dynamic> toJson() => {
  ...
  'isHandRaised': isHandRaised,
};
```

**Add `copyWith` to `RoomParticipant`** — currently doesn't exist. C22 (`isSpeaking` flips) and C26 (`isHost` flips) both depend on this helper. Add it now in C21:

```dart
RoomParticipant copyWith({
  bool? isMuted,
  bool? isSpeaking,
  bool? isHost,
  bool? isHandRaised,
}) =>
    RoomParticipant(
      id: id,
      name: name,
      avatar: avatar,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt,
      isHandRaised: isHandRaised ?? this.isHandRaised,
    );
```

- [ ] **Step 2: Update VoiceRoomManager hand-raise listener**

Replace the stub at line 181-187 with:

```dart
_handRaisedSub = _chatSocketService!.onVoiceRoomHandRaised.listen((data) {
  final participantId = data['userId']?.toString() ?? '';
  final isRaised = data['isRaised'] == true;
  final i = _participants.indexWhere((p) => p.id == participantId);
  if (i != -1) {
    _participants[i] = _participants[i].copyWith(isHandRaised: isRaised);
    onStateChanged?.call();
  }
});
```

- [ ] **Step 3: Render badge in tile**

In `voice_room_participant_tile.dart`, add a positioned hand emoji on the avatar Stack:

```dart
if (participant.isHandRaised)
  Positioned(
    top: -4,
    left: -4,
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Color(0xFFFFB74D),
        shape: BoxShape.circle,
      ),
      child: const Text('✋', style: TextStyle(fontSize: 12)),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.1, duration: 600.ms),
  ),
```

(`flutter_animate` is already a dep per existing code.)

- [ ] **Step 4: Verify**

Manual smoke (2-device): both join room → A taps "raise hand" → B should see hand badge appear with pulse on A's tile.

- [ ] **Step 5: Commit**

```bash
git add lib/models/community/voice_room_model.dart lib/services/voice_room_manager.dart lib/pages/community/voice_rooms/voice_room_participant_tile.dart
git commit -m "fix(voice-rooms): C21 — hand-raise visible on participant tile (C-ii)"
```

---

## C22 — feat(voice-rooms): speaking indicator via WebRTC stats (C-iii)

**Files:**
- Modify: `lib/services/webrtc_service.dart` — add `Stream<Map<String, double>> peerAudioLevels`
- Modify: `lib/services/voice_room_manager.dart` — consume the stream, update participant `isSpeaking`

- [ ] **Step 1: Audio-level polling in WebRTCService**

Add a periodic stats poll. The existing `WebRTCService` has multi-peer connections (`onMultiPeerOfferCreated` etc.), so iterate them:

```dart
final _audioLevelsController = StreamController<Map<String, double>>.broadcast();
Stream<Map<String, double>> get peerAudioLevels => _audioLevelsController.stream;

Timer? _audioLevelTimer;

void startAudioLevelPolling() {
  _audioLevelTimer?.cancel();
  _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
    final levels = <String, double>{};
    for (final entry in _peerConnections.entries) {
      final peerId = entry.key;
      final pc = entry.value;
      try {
        final stats = await pc.getStats();
        for (final report in stats) {
          if (report.type == 'inbound-rtp' && report.values['kind'] == 'audio') {
            final level = (report.values['audioLevel'] as num?)?.toDouble() ?? 0;
            levels[peerId] = level;
          }
        }
      } catch (_) {}
    }
    // Local user
    final localStream = _localStream;
    if (localStream != null) {
      // Local audio level via getStats() requires a sender; for simplicity, derive from track enabled state
      // (more accurate would be Web Audio analyzer on the track — defer to a follow-up if needed)
    }
    _audioLevelsController.add(levels);
  });
}

void stopAudioLevelPolling() {
  _audioLevelTimer?.cancel();
  _audioLevelTimer = null;
}
```

Call `startAudioLevelPolling()` from `VoiceRoomManager.joinRoom` and `stopAudioLevelPolling()` from `_cleanup`.

- [ ] **Step 2: Consume stream in VoiceRoomManager**

```dart
StreamSubscription? _audioLevelSub;

// In _setupWebRTCCallbacks or initialize:
_audioLevelSub = _webrtcService.peerAudioLevels.listen((levels) {
  bool changed = false;
  for (var i = 0; i < _participants.length; i++) {
    final p = _participants[i];
    final level = levels[p.id] ?? 0;
    final shouldSpeak = level > 0.05 && !p.isMuted;
    if (p.isSpeaking != shouldSpeak) {
      _participants[i] = p.copyWith(isSpeaking: shouldSpeak);
      changed = true;
    }
  }
  if (changed) onStateChanged?.call();
});
```

Don't forget to cancel `_audioLevelSub` in `dispose()`.

- [ ] **Step 3: Add perf guard**

In `WebRTCService.startAudioLevelPolling`, only poll while app is foregrounded. Add a `WidgetsBindingObserver` somewhere reasonable (e.g., `voice_room_screen.dart`) and toggle `startAudioLevelPolling()` / `stopAudioLevelPolling()` based on `AppLifecycleState`.

- [ ] **Step 4: Verify**

Manual smoke (2-device): both join room → A unmutes and talks → B should see green ring light up on A's tile while A is speaking → B mutes A from "Mute self" — wait, that's a host control, deferred. Just confirm: muted participants never get the green ring even if their audioLevel > 0.

CPU profile on a Pixel 4a (or simulate Performance Overlay): polling at 500ms with 4 peers should stay under 5% steady-state.

- [ ] **Step 5: Commit**

```bash
git add lib/services/webrtc_service.dart lib/services/voice_room_manager.dart lib/pages/community/voice_rooms/
git commit -m "feat(voice-rooms): C22 — speaking indicator via WebRTC audio-level stats (C-iii)"
```

---

## C23 — feat(voice-rooms): host controls — kick + end-room (C-iv)

**Files:**
- New: `lib/pages/community/voice_rooms/voice_room_host_menu.dart`
- New: `lib/pages/community/voice_rooms/voice_room_participant_actions.dart`
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` — show host UI conditionally
- Modify: `lib/pages/community/voice_rooms/voice_room_controls.dart` — "End room" button when host

- [ ] **Step 1: Create end-room confirm dialog (`voice_room_host_menu.dart`)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';

Future<void> showEndRoomConfirm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.voiceRoomEndConfirm),
      content: Text(l10n.voiceRoomEndConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.stay),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            ref.read(voiceRoomProvider).endRoom();
            Navigator.pop(dialogContext);
            Navigator.pop(context); // exit room screen
          },
          child: Text(l10n.voiceRoomEnd),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Create participant-actions sheet (`voice_room_participant_actions.dart`)**

Long-press on a non-host participant tile opens this sheet. Two actions: "View profile" + "Remove from room" (with confirm).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/widgets/community_dialog_scaffold.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';

Future<void> showParticipantActions(
  BuildContext context,
  WidgetRef ref,
  RoomParticipant participant,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => CommunityDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.voiceRoomViewProfile),
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/profile/${participant.id}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_rounded, color: Colors.red),
            title: Text(l10n.voiceRoomKick, style: const TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(sheetContext);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text(l10n.voiceRoomKickConfirm(participant.name)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(d, true),
                      child: Text(l10n.voiceRoomKick),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(voiceRoomProvider).kickParticipant(participant.id);
                if (context.mounted) {
                  showCommunitySnackBar(
                    context,
                    message: l10n.voiceRoomKicked,
                    type: CommunitySnackBarType.success,
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Conditionally swap "Leave" → "End room" in voice_room_controls.dart**

```dart
Consumer(builder: (context, ref, _) {
  final room = ref.watch(voiceRoomProvider).currentRoom;
  final myId = ref.read(authServiceProvider).userId;
  final isHost = room?.hostId == myId;
  return _ControlButton(
    icon: isHost ? Icons.cancel_rounded : Icons.call_end_rounded,
    label: isHost ? l10n.voiceRoomEnd : l10n.leave,
    color: Colors.red,
    backgroundColor: Colors.red.withValues(alpha: 0.2),
    onTap: () {
      if (isHost) {
        showEndRoomConfirm(context, ref);
      } else {
        widget.onLeave();
      }
    },
  );
}),
```

- [ ] **Step 4: Wire long-press on non-host participant tiles**

In `voice_room_participants_grid.dart`, wrap each `VoiceRoomParticipantTile` with a `GestureDetector`:

```dart
Consumer(builder: (context, ref, _) {
  final myId = ref.read(authServiceProvider).userId;
  final isHost = room.hostId == myId;
  return GestureDetector(
    onTap: () => context.push('/profile/${participant.id}'),
    onLongPress: isHost && !participant.isHost
        ? () => showParticipantActions(context, ref, participant)
        : null,
    child: VoiceRoomParticipantTile(participant: participant, isHost: participant.isHost),
  );
});
```

- [ ] **Step 5: Verify**

Manual smoke (2-device): A creates room (host), B joins. A long-presses B's tile → sheet opens → tap "Remove" → confirm → B is kicked (B's app navigates back). A taps "End room" → confirm → both A and B exit.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/community/voice_rooms/
git commit -m "feat(voice-rooms): C23 — host controls (kick + end-room with confirms) (C-iv)"
```

---

## C24 — feat(voice-rooms) + backend: heartbeat + stale-room cleanup (C-v)

**Files (backend):**
- Modify: `models/VoiceRoom.js` — add `lastHeartbeatAt: Date` field + index
- Modify: socket layer — handle `voiceroom:heartbeat`
- New cron: `jobs/voiceRoomCleanup.js`
- Modify: list endpoint — filter stale rooms

**Files (Flutter):**
- Modify: `lib/services/voice_room_manager.dart` — emit `voiceroom:heartbeat` every 20s

- [ ] **Step 1: Backend — schema field + index**

```js
// models/VoiceRoom.js
lastHeartbeatAt: { type: Date, default: () => new Date() },

// indexes
voiceRoomSchema.index({ isLive: 1, lastHeartbeatAt: -1 });
```

- [ ] **Step 2: Backend — heartbeat handler**

```js
socket.on('voiceroom:heartbeat', async ({ roomId }) => {
  if (!roomId) return;
  await VoiceRoom.updateOne({ _id: roomId }, { lastHeartbeatAt: new Date() });
});
```

- [ ] **Step 3: Backend — cleanup cron**

```js
// jobs/voiceRoomCleanup.js
const cron = require('node-cron');
const VoiceRoom = require('../models/VoiceRoom');

cron.schedule('* * * * *', async () => {
  const cutoff = new Date(Date.now() - 90 * 1000);
  const result = await VoiceRoom.updateMany(
    { isLive: true, lastHeartbeatAt: { $lt: cutoff } },
    { $set: { isLive: false } }
  );
  if (result.modifiedCount > 0) {
    console.log(`[voiceRoomCleanup] Marked ${result.modifiedCount} stale rooms inactive`);
  }
});
```

Wire `require('./jobs/voiceRoomCleanup')` into the server entry point.

- [ ] **Step 4: Backend — list endpoint filters stale rooms**

```js
// controllers/voiceRoomController.js — listRooms
const cutoff = new Date(Date.now() - 60 * 1000);
const rooms = await VoiceRoom.find({
  isLive: true,
  lastHeartbeatAt: { $gte: cutoff },
  ...filter,
}).populate('host');
```

- [ ] **Step 5: Flutter — emit heartbeat from VoiceRoomManager**

```dart
Timer? _heartbeatTimer;

Future<void> joinRoom(VoiceRoom room) async {
  // ... existing join logic ...
  _heartbeatTimer?.cancel();
  _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
    if (_currentRoom != null) {
      _socket?.emit('voiceroom:heartbeat', {'roomId': _currentRoom!.id});
    }
  });
}

void _cleanup() {
  // ... existing cleanup ...
  _heartbeatTimer?.cancel();
  _heartbeatTimer = null;
}
```

- [ ] **Step 6: Verify**

Manual smoke: create room with device A → confirm `lastHeartbeatAt` updates in DB every ~20s. Force-quit device A → wait 90s → run `GET voicerooms` from device B → confirm room no longer in list.

- [ ] **Step 7: Commit (backend + Flutter)**

Backend:
```bash
git add models/VoiceRoom.js socket/ jobs/ controllers/voiceRoomController.js
git commit -m "feat(voice-rooms): C24 — heartbeat + stale-room cleanup cron (C-v)"
```

Flutter:
```bash
git add lib/services/voice_room_manager.dart
git commit -m "feat(voice-rooms): C24 — Flutter emits voiceroom:heartbeat every 20s (C-v)"
```

---

## C25 — feat(voice-rooms) + backend: reconnect banner + rejoin protocol (C-vi)

**Files (backend):**
- Modify: socket layer — handle `voiceroom:rejoin`

**Files (Flutter):**
- New: `lib/pages/community/voice_rooms/voice_room_reconnect_banner.dart`
- Modify: `lib/services/voice_room_manager.dart` — listen to socket connection state, emit rejoin
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` — render banner

- [ ] **Step 1: Backend — rejoin handler**

```js
socket.on('voiceroom:rejoin', async ({ roomId }, ack) => {
  const room = await VoiceRoom.findById(roomId).populate('host');
  if (!room || !room.isLive) {
    if (ack) ack({ ok: false, ended: true });
    socket.emit('voiceroom:ended', { roomId });
    return;
  }

  const userId = socket.userId;
  // Re-add to participants if missing
  const exists = room.participants.some(p => String(p.user) === String(userId));
  if (!exists) {
    room.participants.push({ user: userId, joinedAt: new Date(), isMuted: true });
    await room.save();
    socket.to(`room:${roomId}`).emit('voiceroom:participant-joined', {
      userId, joinedAt: new Date(),
    });
  }
  socket.join(`room:${roomId}`);

  // Determine youArePromoted (if you used to be host but were promoted away during grace)
  const youArePromoted = String(room.host._id) === String(userId);
  const currentHostId = String(room.host._id);

  if (ack) {
    ack({
      ok: true,
      ended: false,
      currentHostId,
      youArePromoted, // true if rejoining user is the current host; false if they were demoted during grace
      participants: room.participants,
    });
  }
});
```

> **Semantics check:** `youArePromoted: true` means the rejoining user is still the current host (came back within grace window or was never the host before). `youArePromoted: false` means they were the host but got demoted during their absence (grace expired before rejoin) — Flutter uses this to swap from host UI to guest UI. Add a unit test in C26 covering: ex-host rejoins post-grace → ACK has `youArePromoted: false, currentHostId: <newHost>`.

- [ ] **Step 2: Flutter — create reconnect banner**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class VoiceRoomReconnectBanner extends StatelessWidget {
  final bool isReconnecting;
  const VoiceRoomReconnectBanner({super.key, required this.isReconnecting});

  @override
  Widget build(BuildContext context) {
    if (!isReconnecting) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber,
      child: Row(
        children: [
          const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
          const SizedBox(width: 12),
          Text(l10n.voiceRoomReconnecting,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Flutter — VoiceRoomManager rejoin logic**

In `VoiceRoomManager`, add a connection-state listener and a rejoin emitter:

```dart
StreamSubscription? _connectionSub;
bool _isReconnecting = false;
bool get isReconnecting => _isReconnecting;
Function()? onConnectionChanged;

void _setupConnectionListener() {
  _connectionSub = _chatSocketService!.connectionState.listen((connected) async {
    if (_currentRoom == null) return;
    if (!connected) {
      _isReconnecting = true;
      onConnectionChanged?.call();
      return;
    }
    // Reconnected — try rejoin
    _socket?.emitWithAck('voiceroom:rejoin', {'roomId': _currentRoom!.id}, ack: (ackData) {
      _isReconnecting = false;
      if (ackData['ended'] == true) {
        onRoomEnded?.call();
        _cleanup();
      } else {
        if (ackData['youArePromoted'] == false &&
            _currentRoom?.hostId == _chatSocketService?.currentUserId) {
          // We were demoted during grace; refresh state
          _currentRoom = _currentRoom!.copyWith(hostId: ackData['currentHostId']);
        }
      }
      onConnectionChanged?.call();
    });
  });
}
```

(Adjust to match the actual `ChatSocketService` connection-state API.)

- [ ] **Step 4: Render banner in voice_room_screen.dart**

Wrap the body Column's first child in a Column that renders the banner above:

```dart
Column(
  children: [
    Consumer(builder: (_, ref, __) {
      final isRecon = ref.watch(voiceRoomProvider).isReconnecting;
      return VoiceRoomReconnectBanner(isReconnecting: isRecon);
    }),
    _buildRoomInfo(l10n),
    Expanded(child: _buildParticipants(l10n)),
    _buildControls(l10n),
  ],
);
```

Expose `isReconnecting` from `VoiceRoomNotifier` via `state` or a getter; also disable the controls while reconnecting (`AbsorbPointer` or `IgnorePointer`).

- [ ] **Step 5: Verify**

Manual smoke (1-device, airplane mode):
- A creates room. Toggle airplane mode → "Reconnecting…" banner appears, controls disabled. Toggle airplane back → banner clears within ~5s, participants list intact.
- B in same room kills A → A's banner shows briefly during reconnect; on rejoin, A sees the room (still live with B as host? — see C26 for transfer semantics).

- [ ] **Step 6: Commit**

Backend:
```bash
git add socket/
git commit -m "feat(voice-rooms): C25 — voiceroom:rejoin handler (C-vi)"
```

Flutter:
```bash
git add lib/pages/community/voice_rooms/voice_room_reconnect_banner.dart lib/pages/community/voice_rooms/voice_room_screen.dart lib/services/voice_room_manager.dart lib/providers/voice_room_provider.dart
git commit -m "feat(voice-rooms): C25 — reconnect banner + rejoin protocol (C-vi)"
```

---

## C26 — feat(voice-rooms) + backend: host transfer protocol (C-vii)

**Files (backend):**
- Modify: socket layer — implement host-disconnect state machine
- New: timer storage `Map<{roomId,hostUserId}, NodeJS.Timeout>` (in-memory)

**Files (Flutter):**
- Modify: `lib/services/chat_socket_service.dart` — add `onVoiceRoomHostChanged` stream
- Modify: `lib/services/voice_room_manager.dart` — listen to host-changed
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` — react to host swap

- [ ] **Step 1: Backend — state machine implementation**

```js
const hostGraceTimers = new Map(); // key: `${roomId}:${userId}` → timeout id
const HOST_GRACE_MS = 30 * 1000;

function scheduleHostTransfer(roomId, hostUserId) {
  const key = `${roomId}:${hostUserId}`;
  if (hostGraceTimers.has(key)) return;
  const timer = setTimeout(async () => {
    hostGraceTimers.delete(key);
    const room = await VoiceRoom.findById(roomId).populate('host');
    if (!room || !room.isLive) return;
    if (String(room.host._id) !== String(hostUserId)) return; // host already swapped

    if (room.participants.length === 0) {
      room.isLive = false;
      await room.save();
      return;
    }

    // Promote next-oldest joinedAt
    const sorted = [...room.participants].sort(
      (a, b) => new Date(a.joinedAt) - new Date(b.joinedAt)
    );
    const newHost = sorted[0];
    room.host = newHost.user;
    await room.save();
    io.to(`room:${roomId}`).emit('voiceroom:host-changed', {
      newHostId: String(newHost.user),
      previousHostId: String(hostUserId),
    });
  }, HOST_GRACE_MS);
  hostGraceTimers.set(key, timer);
}

function cancelHostTransfer(roomId, hostUserId) {
  const key = `${roomId}:${hostUserId}`;
  const timer = hostGraceTimers.get(key);
  if (timer) {
    clearTimeout(timer);
    hostGraceTimers.delete(key);
  }
}
```

- [ ] **Step 2: Backend — wire triggers**

```js
// On host disconnect
socket.on('disconnect', async () => {
  // ... existing presence cleanup ...
  // For each room user is hosting and still joined to, schedule grace
  const hostedRooms = await VoiceRoom.find({ host: socket.userId, isLive: true });
  hostedRooms.forEach(r => scheduleHostTransfer(r._id, socket.userId));
});

// On heartbeat (cancel grace if user back)
socket.on('voiceroom:heartbeat', async ({ roomId }) => {
  await VoiceRoom.updateOne({ _id: roomId }, { lastHeartbeatAt: new Date() });
  cancelHostTransfer(roomId, socket.userId);
});

// On rejoin (also cancels grace and ACK reflects youArePromoted)
socket.on('voiceroom:rejoin', async ({ roomId }, ack) => {
  // ... existing rejoin logic ...
  cancelHostTransfer(roomId, socket.userId);
  // ... rest unchanged ...
});

// On explicit leave (host)
socket.on('voiceroom:leave', async ({ roomId }) => {
  const room = await VoiceRoom.findById(roomId);
  if (room && String(room.host) === String(socket.userId)) {
    if (room.participants.length > 1) {
      // Trigger immediate transfer (no grace for explicit leaves)
      scheduleHostTransfer(roomId, socket.userId);
      // Or: synchronous promote here, depending on desired UX. Spec says "immediately on explicit leave."
    } else {
      // Empty room → mark inactive
      await VoiceRoom.updateOne({ _id: roomId }, { isLive: false });
    }
  }
  // ... existing leave logic (remove from participants) ...
});
```

- [ ] **Step 3: Flutter — listen for host-changed**

Add stream in `chat_socket_service.dart`:

```dart
final _voiceRoomHostChangedController = StreamController<dynamic>.broadcast();
Stream<dynamic> get onVoiceRoomHostChanged => _voiceRoomHostChangedController.stream;

// In socket setup:
_socket?.on('voiceroom:host-changed', (data) =>
    _voiceRoomHostChangedController.add(data));
```

Subscribe in `VoiceRoomManager`:

```dart
StreamSubscription? _hostChangedSub;

_hostChangedSub = _chatSocketService!.onVoiceRoomHostChanged.listen((data) {
  final newHostId = data['newHostId']?.toString() ?? '';
  if (newHostId.isEmpty || _currentRoom == null) return;

  // Update room
  _currentRoom = _currentRoom!.copyWith(hostId: newHostId);

  // Update participants (the previous host's role; new host's role)
  for (var i = 0; i < _participants.length; i++) {
    final p = _participants[i];
    if (p.id == newHostId) {
      _participants[i] = p.copyWith(isHost: true);
    } else if (p.isHost) {
      _participants[i] = p.copyWith(isHost: false);
    }
  }

  onHostChanged?.call(newHostId);
  onStateChanged?.call();
});

Function(String newHostId)? onHostChanged;
```

- [ ] **Step 4: Show host-change snackbar**

In `voice_room_screen.dart`, listen for `onHostChanged` from the manager:

```dart
@override
void initState() {
  super.initState();
  // ... existing init ...
  ref.read(voiceRoomProvider).manager.onHostChanged = (newHostId) {
    final l10n = AppLocalizations.of(context)!;
    final isMe = newHostId == ref.read(authServiceProvider).userId;
    if (isMe) {
      showCommunitySnackBar(context,
          message: l10n.voiceRoomYouAreHostNow,
          type: CommunitySnackBarType.success);
    } else {
      final newHost = ref.read(voiceRoomProvider).participants
          .firstWhere((p) => p.id == newHostId,
              orElse: () => RoomParticipant(id: '', name: '', joinedAt: DateTime.now()));
      showCommunitySnackBar(context,
          message: l10n.voiceRoomHostChanged(newHost.name),
          type: CommunitySnackBarType.info);
    }
  };
}
```

- [ ] **Step 5: Verify**

Multi-device E2E:
- 3 users (A=host, B, C). Force-quit A. Expected: 30s later → "B is now the host" snackbar on B+C; B's controls show "End room"; A relaunches → A sees room with B as host, A is a guest now.
- Rejoin within grace: kill A → 10s later relaunch → A still host on rejoin.
- Empty grace: 1 user (A=host) → quit → after grace → room flipped `isLive: false`; doesn't appear in list.

- [ ] **Step 6: Commit**

Backend:
```bash
git add socket/
git commit -m "feat(voice-rooms): C26 — host transfer state machine (C-vii)"
```

Flutter:
```bash
git add lib/services/chat_socket_service.dart lib/services/voice_room_manager.dart lib/pages/community/voice_rooms/voice_room_screen.dart
git commit -m "feat(voice-rooms): C26 — react to voiceroom:host-changed with snackbar (C-vii)"
```

---

## C27 — chore(community): final polish + smoke pass

**Files:**
- Various

- [ ] **Step 1: Final analyzer sweep**

```bash
flutter analyze lib/ 2>&1 | tail -30
```

Triage any remaining warnings/info notes:
- Unused imports → remove
- Dangling `// TODO` comments tied to wave 1 → resolve or convert to GitHub issues for wave 2
- Verify `lib/pages/community/community_main.dart`, `community_card.dart`, `community_filter.dart`, `single_community.dart`, `partner_discovery_tab.dart`, `nearby_tab.dart`, `city_tab.dart`, `genders_tab.dart` are all gone (replaced by their split versions)

- [ ] **Step 2: Cross-file walk-through**

Walk every entry point one more time:
- iOS + Android, light + dark mode
- All 7 community tabs render
- Filter sheet open/close/apply/reset
- Community card → tap to open profile → walk every section
- Wave button → send → mutual dialog (if applicable) → cooldown
- Voice rooms: create / join / chat / hand-raise / mute / kick / end / reconnect (airplane toggle) / host-transfer (force-quit host)

- [ ] **Step 3: Verify l10n parity**

```bash
flutter gen-l10n
```

Spot-check 3 locales (e.g., ko, ja, es) for missing-key warnings or untranslated entries.

- [ ] **Step 4: Final commit**

```bash
git commit --allow-empty -m "chore(community): C27 — final analyzer cleanup + manual smoke pass"
```

- [ ] **Step 5: Push + PR**

```bash
git push -u origin refactor/community-wave-1
gh pr create --title "Community: restructure + wave 1 features" --body "$(cat <<'EOF'
## Summary

Restructures `lib/pages/community/` (12,366 lines, 13 files → ~50 files in 7 subfolders) and ships five wave-1 features:

- A. Filter UX rebuild (sticky bars, match count, sectioned)
- B. Waves send-side + mutual-wave dialog + unread badge
- C. Voice rooms overhaul: chat panel, hand-raise visibility, speaking indicator, host controls, heartbeat cleanup, reconnect, host transfer
- D. Mutual interests on `single_community`
- E. Online-now presence (green dot + filter)

Mesh→SFU migration deferred to wave 2.

## Test plan

- [ ] All 7 community tabs render in iOS + Android, light + dark
- [ ] Filter sheet: sectioned UI, match count, apply/reset
- [ ] Wave: send / cooldown / mutual celebration / unread badge
- [ ] Voice rooms: chat / hand-raise / speaking ring / host kick / end / reconnect / host transfer
- [ ] Mutual interests: 3 profiles (all-shared, mixed, empty)
- [ ] Online-now dot + filter toggle

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Plan complete

**Spec:** `docs/superpowers/specs/2026-05-06-community-restructure-and-wave-1-design.md`
**Plan:** this file
**Branch:** `refactor/community-wave-1`
**Total: 28 commits (C0–C27), ~6-8 weeks**

**Backend changes are split across two repositories.** Flutter commits land in this repo; backend commits (C15, C17, C18 partial, C19, C24, C25, C26) land in the backend repo. Coordinate via the project tracker.
