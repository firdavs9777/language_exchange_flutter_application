# Profile Folder Restructure & Code Cleanup

**Date:** 2026-05-05
**Branch:** `refactor/profile-restructure` (off `main`)
**Scope:** `lib/pages/profile/` only (plus 2 out-of-tree compile-error fixes)

## Goal

Bring the 23-file, 19,000-line `profile/` tree under control:

1. Re-organize folders so names match contents
2. Drop redundant `profile_` filename prefix wherever the folder path already says it
3. Extract shared building blocks (`widgets/`) — eliminate ~1,200 lines of copy-pasted helpers
4. Split the 4 files over 1,000 lines into focused units (each <600 lines)
5. Fix two pre-existing compile errors that block release builds

Behavior is unchanged. No API contracts, theme constants, l10n keys, or providers move. Strictly internal restructure.

## Current state — why this is needed

| File | Lines | Problem |
|---|---|---|
| `profile_main.dart` | 1,822 | Header + tabs + gallery + state all in one |
| `profile_left_drawer.dart` | 1,370 | Drawer + About dialog + logout + menu helpers |
| `profile_picture_edit.dart` | 1,346 | Upload + cropping + grid + handlers in one |
| `profile_edit_main.dart` | 1,009 | Master edit + completion logic + section tiles |

Misplaced files:
- `about/profile_single_moment.dart` is a moment card — has nothing to do with profile-about
- `about/profile_info_set.dart` is a name+gender editor — belongs in `personal_info/`
- `main/` contains drawer, settings, theme, moments, highlights, visitors — most aren't "main"
- `sub/` contains a single file (`profile_header.dart`) with a confusing name

Duplication: ~120 instances of `_showSuccessSnackBar` / `_showErrorSnackBar` / `_buildSaveButton` / `_buildSectionLabel` patterns copy-pasted across files.

## Target folder layout

```
lib/pages/profile/
├── profile_main.dart                          ~400 (was 1822)
├── profile_wrapper.dart                       (untouched)
├── widgets/                                   NEW — shared building blocks
│   ├── edit_screen_scaffold.dart
│   ├── gradient_save_button.dart
│   ├── profile_snackbar.dart
│   └── section_label.dart
├── header/                                    was sub/
│   └── profile_header.dart
├── edit/                                      was personal_info/
│   ├── name_gender_edit.dart                  MOVED from about/profile_info_set.dart
│   ├── bio_edit.dart
│   ├── blood_type_edit.dart
│   ├── hometown_edit.dart
│   ├── language_edit.dart
│   ├── mbti_edit.dart
│   ├── privacy_edit.dart
│   ├── topics_edit.dart
│   ├── picture_edit.dart                      ~500 (was 1346)
│   └── picture_edit/
│       ├── photo_picker_sheet.dart
│       ├── photo_upload_handler.dart
│       └── photo_grid_tile.dart
├── drawer/                                    was main/profile_left_drawer.dart
│   ├── profile_drawer.dart                    ~600 (was 1370)
│   ├── about_dialog.dart
│   ├── drawer_section.dart
│   └── logout_dialog.dart
├── moments/                                   was scattered
│   ├── moments_list.dart
│   ├── moment_edit.dart
│   └── moment_card.dart                       MOVED from about/profile_single_moment.dart
├── edit_main/                                 was main/profile_edit_main.dart
│   ├── edit_main.dart                         ~400 (was 1009)
│   ├── completion_calculator.dart
│   └── sections/
│       ├── basic_info_tile.dart
│       ├── language_section.dart
│       └── personal_section.dart
├── profile_main/                              NEW — extracted sections
│   └── sections/
│       ├── profile_stats_row.dart
│       ├── profile_action_buttons.dart
│       ├── profile_tab_bar.dart
│       ├── profile_about_tab.dart
│       ├── profile_moments_tab.dart
│       └── profile_highlights_tab.dart
└── (kept flat at root):
    ├── followers.dart
    ├── followings.dart
    ├── highlights.dart
    ├── settings.dart
    ├── theme.dart
    └── visitors_screen.dart
```

The `about/`, `sub/`, and `main/` folders are removed. Their contents redistribute by what they actually do.

## Shared widgets/ contents

### `widgets/profile_snackbar.dart`

Replaces 3 helper methods (`_showSuccessSnackBar`, `_showErrorSnackBar`, `_showWarningSnackBar`) duplicated across ~12 files.

```dart
enum ProfileSnackBarType { success, error, warning }

void showProfileSnackBar(
  BuildContext context, {
  required String message,
  ProfileSnackBarType type = ProfileSnackBarType.success,
});
```

Internally: hides current snackbar, fires haptic appropriate to type, shows the row+icon style with type-coloured background, floating behavior, 14-radius shape, durations matching current convention (2s success, 3s error, 2s warning).

### `widgets/gradient_save_button.dart`

```dart
class GradientSaveButton extends StatelessWidget {
  final bool canSave;
  final bool isSaving;
  final String? label;          // null → l10n.saveChanges
  final VoidCallback? onPressed;
}
```

Renders the canonical `[#00BFA5 → #00897B]` gradient + check icon + spinner + disabled state.

### `widgets/edit_screen_scaffold.dart`

```dart
class EditScreenScaffold extends StatelessWidget {
  final String title;
  final bool canSave;
  final bool isSaving;
  final VoidCallback? onSave;
  final Widget body;
  final bool showBottomSaveButton;  // default true
  final EdgeInsetsGeometry? bodyPadding;
}
```

Wires the pill-shaped AppBar Save TextButton + scaffold + scrollable body slot + `GradientSaveButton` at bottom. Most edit screens become 5-line scaffolds.

### `widgets/section_label.dart`

```dart
class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
}
```

Replaces ~8 instances of the inline `Row(children: [Icon..., Text...])` pattern.

## File splits

### `profile_main.dart` (1,822 → ~400)

Extract section widgets to `profile_main/sections/`. The state class keeps tab control + scaffold; sections become stateless widgets receiving the user model and callbacks via constructor.

### `profile_left_drawer.dart` (1,370 → ~600)

`drawer/profile_drawer.dart` keeps the `Drawer` shell + section list. Extracts:
- `drawer/about_dialog.dart` — `_showAboutDialog` body (the gradient card + tagline + copyright)
- `drawer/drawer_section.dart` — `_buildSectionTitle`, `_buildSectionContainer`, `_buildMenuItem`, `_buildDivider`
- `drawer/logout_dialog.dart` — `_handleLogout`'s confirmation dialog

### `profile_picture_edit.dart` (1,346 → ~500)

- `edit/picture_edit.dart` — screen state + grid layout + reorder logic
- `edit/picture_edit/photo_picker_sheet.dart` — camera/gallery bottom sheet
- `edit/picture_edit/photo_upload_handler.dart` — auth-bearing http multipart upload
- `edit/picture_edit/photo_grid_tile.dart` — per-photo tile with delete + drag handle

### `profile_edit_main.dart` (1,009 → ~400)

- `edit_main/edit_main.dart` — screen + tile list
- `edit_main/completion_calculator.dart` — `_calculateCompletion` + missing-fields detection
- `edit_main/sections/*.dart` — basic info / language / personal section builders

## Class rename map

Widgets keep the `Profile` prefix even when files drop it — global Dart symbol uniqueness still matters when grep'ing the codebase.

| Old class | New class |
|---|---|
| `LeftDrawer` | `ProfileDrawer` |
| `PersonBloodType` | `BloodTypeEdit` |
| `ProfileSingleMoment` | `MomentCard` |
| `ProfileInfoSet` | `NameGenderEdit` |

`MBTIEdit`, `ProfileBioEdit`, etc. stay as-is.

## Bug fixes folded into this work

1. **`Moments.title` compile errors** at `lib/pages/explore/explore_main.dart:283` and `lib/pages/moments/saved_moments_screen.dart:325, 327`. Block release builds. Fix: inspect intent (was the model field renamed/dropped?) and either add `title` back to the model or remove the references.
2. **Stale style imports** — `Spacing.gapSM` / `Spacing.paddingLG` mixed with inline `const SizedBox` / `EdgeInsets`. Normalize to the modern (inline) style during the file moves.

Out of scope: behavior changes, network/API changes, theme constants, l10n keys, providers, anything outside `profile/` (except the two compile-error files).

## Migration plan — 9 commits, single PR

| # | Commit | Why this order | Verification |
|---|---|---|---|
| C1 | Add `widgets/` (4 new files, no callers yet) | Bottom-up: shared bits land first | `flutter analyze` clean |
| C2 | Migrate 4 modern edit screens to new widgets (bio, blood_type, hometown, name_gender) | Validate the widget API on the easiest cases | Open each, save flow works |
| C3 | Migrate 4 legacy edit screens (mbti, language, privacy, topics) | Same pattern, more variety | Same |
| C4 | File moves + renames using `git mv` (no logic changes) | History preserved | `flutter analyze` clean — every import updated |
| C5 | Split `profile_main.dart` | The biggest, riskiest split | App boots, profile loads, tabs switch |
| C6 | Split `profile_left_drawer.dart` → `drawer/` | Drawer opens, all menu items navigate |
| C7 | Split `profile_picture_edit.dart` → `edit/picture_edit/` | Upload flow + reorder works |
| C8 | Split `profile_edit_main.dart` → `edit_main/` | Edit screen, completion bar accurate |
| C9 | Fix `Moments.title` compile errors | Out-of-tree but blocks release | `flutter build` succeeds |

Each commit gates on `flutter analyze` clean + a manual smoke test of the affected screen. If a commit breaks something, only that commit gets reverted.

## Risk register

- **Import sprawl** — moving 22 files breaks every import. Mitigated by `git mv` (preserves history) + `dart fix --apply` + `flutter analyze` after each commit.
- **Hidden coupling in `_ProfileMainState`** — extracted sections may need state currently held in private fields. They'll receive it via constructor params; no global state added.
- **Behavior regressions** — each commit gates on `flutter analyze` and a manual smoke test of the touched screen. Rollback is per-commit.
- **In-flight work on a parallel branch** — collaborator branches that touch profile files will conflict. Coordinate timing or merge restructure last.

## Out of scope (deferred)

- Riverpod-ifying screens that use `setState` for local UI state (orthogonal cleanup)
- Fully extracting a `BaseEditController` for save/load lifecycle (Option C territory — comes later if needed)
- Type-safety improvements on the `Moments` / `Community` / `User` models
- Test coverage for any profile screen (separate effort)
- Dark mode pass on the 4 split-result files (inherits dark-mode from current files; verify still works)
