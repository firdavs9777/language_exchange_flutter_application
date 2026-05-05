# Personal Info & About — Translations + UI Modernization

**Date:** 2026-05-05
**Branch baseline:** `feat/notif-v2-c1`
**Scope:** `lib/pages/profile/personal_info/` (7 files) + `lib/pages/profile/about/` (2 files)

## Goal

Bring two profile-edit folders to a consistent, fully-localized state:

1. Eliminate hardcoded English strings from user-facing UI
2. Unify two competing visual idioms (modern gradient vs. legacy `ElevatedButton`) onto the modern style already used in `bio_edit`, `blood_type`, `hometown`, and `info_set`

Backend, models, providers, and routing are out of scope.

## File inventory

| File | Current UI | Hardcoded strings | Phase |
|---|---|---|---|
| `personal_info/profile_bio_edit.dart` | Modern | 8 | 1 (l10n) |
| `personal_info/profile_blood_type.dart` | Modern | 8 | 1 (l10n) |
| `personal_info/profile_hometown.dart` | Modern | 5 | 1 (l10n) |
| `about/profile_info_set.dart` | Modern | 3 | 1 (l10n) |
| `personal_info/profile_mbti.dart` | Legacy | minor | 1 + 2 |
| `personal_info/profile_language_edit.dart` | Legacy | minor | 1 + 2 |
| `personal_info/profile_privacy.dart` | Legacy | none | 2 (UI only) |
| `personal_info/profile_topics_edit.dart` | Legacy | none | 2 (UI only) |
| `about/profile_single_moment.dart` | Mixed | none | 2 (cleanup) |

`profile_picture_edit.dart` is excluded — already modern, already localized.

## Phase 1 — l10n sweep

### New ARB keys (English source)

Added to `app_en.arb` and propagated to 17 locales (ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW).

| Key | English value | Used in |
|---|---|---|
| `bioHintCard` | "A great bio helps others connect with you. Share your interests, languages, or what you're looking for." | bio_edit |
| `bioCounterStartWriting` | "Start writing..." | bio_edit |
| `bioCounterABitMore` | "A bit more would be great" | bio_edit |
| `bioCounterAlmostAtLimit` | "Almost at the limit" | bio_edit |
| `bioCounterTooLong` | "Too long" | bio_edit |
| `bioQuickStarters` | "Quick starters" | bio_edit |
| `rhPositive` | "Rh Positive" | blood_type |
| `rhNegative` | "Rh Negative" | blood_type |
| `rhPositiveDesc` | "Most common" | blood_type |
| `rhNegativeDesc` | "Universal donors / rare" | blood_type |
| `yourBloodType` | "Your blood type" | blood_type |
| `noBloodTypeSelected` | "No blood type selected" | blood_type |
| `tapTypeBelow` | "Tap a type below" | blood_type |
| `tapButtonToDetectLocation` | "Tap the button below to detect your current location" | hometown |
| `currentAddressLabel` | "Current: {address}" (placeholder) | hometown |
| `onlyCityCountryShown` | "Only your city and country are shown to others. Exact coordinates remain private." | hometown |
| `updateLocationCta` | "Update Location" | hometown |
| `enterYourName` | "Enter your name" | info_set |
| `unsavedChanges` | "You have unsaved changes" | info_set |

`save` (bare "Save") already exists — reused.

### Bio suggestion content — KEPT IN ENGLISH

The 5 starter-text suggestions in `profile_bio_edit.dart` (`'Hi, I'm '`, `'I love traveling…'`, etc.) remain English-only. They are user-edited template content, not UI chrome. Only the **section title** ("Quick starters") and emoji-prefixed labels become translated; the inserted text stays English.

### Hardcoded `'Save'` button labels

4 screens (`bio_edit`, `blood_type`, `hometown`, `info_set`) hardcode `'Save'` in their AppBar action button. Replace each with `l10n.save` (existing key).

### Code generation

After ARB edits, run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations*.dart`. Verify no compile errors.

## Phase 2 — UI modernization

Goal: 4 legacy-style screens adopt the patterns established in `bio_edit`/`blood_type`.

### Standard pattern (target)

1. **AppBar Save button** — pill-shaped `TextButton` with `AppColors.primary` background, white text, 20-radius (replaces plain text button)
2. **Bottom Save button** — gradient `Material/InkWell/Ink` with `[Color(0xFF00BFA5), Color(0xFF00897B)]` gradient, primary-color shadow, check icon + `l10n.saveChanges` (replaces `ElevatedButton` + `AppColors.secondary`)
3. **Snackbar helpers** — extract `_showSuccessSnackBar` / `_showErrorSnackBar` private methods using the shared row+icon style (matches `bio_edit` pattern)
4. **Haptics** — `HapticFeedback.lightImpact()` on save start and success snackbar; `HapticFeedback.selectionClick()` on selection changes; `HapticFeedback.mediumImpact()` on errors

### Per-file changes

- **`profile_mbti.dart`** — Apply standard pattern. Replace `GestureDetector` with `InkWell` in grid cells. Add haptics on selection. Extract snackbar helpers.
- **`profile_language_edit.dart`** — Apply standard pattern. Extract snackbar helpers.
- **`profile_privacy.dart`** — Replace bottom `ElevatedButton` with gradient save button. AppBar save: keep simple `TextButton` (matches multi-section settings convention) — *no pill pattern here* because the save is non-destructive and live. Visual hierarchy stays cleaner without the pill.
- **`profile_topics_edit.dart`** — Apply standard pattern. Replace `GestureDetector` with `InkWell` in `_TopicCard`. Haptic on toggle.
- **`profile_single_moment.dart`** — Cleanup only: replace `withOpacity()` (lines 399, 756) with `withValues(alpha:)`. No structural changes.

### What is NOT changing

- No new shared widget abstraction. Each screen keeps its own `_buildSaveButton`, `_buildSectionLabel`, etc. Extraction is deferred — current duplication is tolerable; premature consolidation risks breaking other consumers.
- No backend / API contract changes
- No router/navigation changes
- No theme constant changes (gradient colors stay inline as in existing modern files)

## Testing & verification

1. `flutter gen-l10n` succeeds with no errors
2. `flutter analyze` clean for the 9 modified files
3. Manual smoke test in dev build: open each of the 9 screens in **English** and **Korean** locales, confirm no English text leaks where a translated key should appear
4. Tap each Save button (AppBar + bottom) on the 4 modernized screens — confirm consistent behavior, haptics, and snackbar styling
5. Dark mode pass on all 9 screens

## Rollout

Single PR, but two commits:
- **Commit 1:** Phase 1 (l10n sweep — ARB + generated Dart + Dart consumer updates). Ships value alone.
- **Commit 2:** Phase 2 (UI modernization). Cosmetic-only on top of Phase 1.

This keeps blame-history clear and enables clean revert of either phase if regressions are found.

## Out of scope (not in this work)

- Translating bio suggestion *content* (deliberate — see above)
- Refactoring `profile_single_moment.dart`'s mood-emoji map (likely duplicates one in moments folder; separate cleanup)
- New shared `PersonalInfoScaffold` / `EditableProfileSection` abstraction
- `profile_picture_edit.dart` (already modern + localized)
- Other profile subfolders (`main/`, `sub/`)
