# Moments Instagram-Style Redesign

**Date:** 2026-04-19
**Status:** Approved
**Scope:** Backend (language_exchange_backend_application) + Flutter (bananatalk_app)
**Approach:** Parallel backend + frontend development

---

## Overview

Redesign the Moments feature to feel like Instagram/Facebook posts. Remove the `title` field entirely, keep `description` as the sole text field (labeled "caption" in UI), add gradient backgrounds for text-only posts, redesign feed cards with two layouts (media full-width + gradient text-only), add double-tap to like, fix translation bugs, fix `isDeleted` filter bug in feed endpoints, sync mood/category enums, localize all hardcoded strings, and clean up dead code.

---

## 1. Backend Changes

### 1.1 Schema (Moment.js)

**Remove `title` field entirely:**
- Delete the `title` field definition from `MomentSchema`
- `description` remains required (max 2000 chars) — this is the "caption"

**Add `backgroundColor` field:**
```js
backgroundColor: {
  type: String,
  enum: [
    '', 'gradient_sunset', 'gradient_ocean', 'gradient_forest',
    'gradient_purple', 'gradient_fire', 'gradient_midnight',
    'gradient_candy', 'gradient_sky'
  ],
  default: ''
}
```

**Remove dead slug code:**
- The `slugify` import and `slug` field exist but no pre-save hook generates slugs — this is dead code
- Remove the `slugify` import and `slug` field entirely from the schema

### 1.2 Validator (momentValidator.js)

**createMomentValidation:**
- Remove `title` validation entirely
- Add `backgroundColor` validation: `optional({ nullable: true }).isIn(['', ...preset list])` — accept `null` (Mongoose defaults to `''`)

**updateMomentValidation:**
- Remove `title` validation entirely
- Add `backgroundColor` validation: same as create

### 1.3 Controller (moments.js)

- Remove any `title` references in `createMoment` and `updateMoment`
- **Fix `createMoment` notification call:** change `description || title || ''` to `description || ''` (line ~363)
- **Fix `translateMoment` source text:** change `moment.description || moment.title || ''` to `moment.description || ''` (line ~1162)
- Verify `updateMoment` handles partial updates correctly
- Verify `deleteMoment` cascading works (media from Spaces, comments, translations)
- Verify all feed endpoints don't assume `title` exists

**Critical fix — add `isDeleted` filter to missing endpoints:**
- `getMoments` (main feed, line ~42): add `isDeleted: { $ne: true }` to query
- `getUserMoments` (line ~184): add `isDeleted: { $ne: true }` to query
- `getMoment` (single moment, line ~127): add `isDeleted: { $ne: true }` to query
- These three endpoints currently return soft-deleted moments — this is a bug

### 1.4 Category Enum Sync

**Add missing categories to backend enum:**

Current backend: `general`, `language-learning`, `culture`, `food`, `travel`, `music`, `books`, `hobbies`

Add: `daily-life`, `technology`, `entertainment`, `sports`, `movies`, `study`, `work`, `question`

Updated enum:
```
['general', 'language-learning', 'culture', 'food', 'travel', 'music', 'books', 'hobbies',
 'daily-life', 'technology', 'entertainment', 'sports', 'movies', 'study', 'work', 'question']
```

Update in both `Moment.js` schema and `momentValidator.js`.

### 1.5 Mood Enum Sync

**Three-way mismatch exists — resolve to a single canonical list:**

- Backend model: `['happy', 'excited', 'grateful', 'motivated', 'relaxed', 'curious', '']`
- Backend validator: same as model
- Flutter create form: `['happy', 'excited', 'sad', 'love', 'funny', 'thoughtful', 'cool', 'tired', 'motivated', 'grateful']`
- Flutter `MomentMood` class in model: yet another subset

**Canonical mood list (union of all, removing duplicates):**
```
['happy', 'excited', 'grateful', 'motivated', 'relaxed', 'curious',
 'sad', 'love', 'funny', 'thoughtful', 'cool', 'tired', '']
```

Update in:
- `Moment.js` schema enum
- `momentValidator.js` create/update validation
- `create_moment.dart` mood list
- `MomentMood` class in `moments_model.dart`

### 1.6 Translation Endpoint Audit

- Verify `translateMoment` works end-to-end with LibreTranslate
- Verify `getMomentTranslations` returns correct data
- Confirm Translation model TTL (30-day cache) is working
- No structural changes needed — just audit and fix if broken

---

## 2. Flutter — Model Changes

### 2.1 Moments Model (moments_model.dart)

- Remove `title` field entirely from `Moments` class
- Remove `title` from `fromJson()`, `toJson()`, `copyWith()`
- Add `backgroundColor` field (String, default empty)
- Add `backgroundColor` to `fromJson()`, `toJson()`, `copyWith()`

### 2.2 Gradient Presets (new constants)

Define shared gradient map in a constants file or within the model:

```dart
static const Map<String, List<Color>> gradientPresets = {
  'gradient_sunset': [Color(0xFFFF512F), Color(0xFFDD2476)],
  'gradient_ocean': [Color(0xFF2193B0), Color(0xFF6DD5ED)],
  'gradient_forest': [Color(0xFF11998E), Color(0xFF38EF7D)],
  'gradient_purple': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  'gradient_fire': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
  'gradient_midnight': [Color(0xFF0F2027), Color(0xFF2C5364)],
  'gradient_candy': [Color(0xFFD585FF), Color(0xFF00FFEE)],
  'gradient_sky': [Color(0xFF56CCF2), Color(0xFF2F80ED)],
};
```

---

## 3. Flutter — Creation Flow Redesign (create_moment.dart)

### 3.1 Layout Changes

Remove `titleController` and title text field entirely. Single `descriptionController` serves as "caption."

**New layout (top to bottom):**
1. **Media area** — prominent image/video picker at top, grid preview for multiple images
2. **Caption field** — multi-line text input, placeholder uses localized "What's on your mind?"
3. **Background color picker** — only visible when `mediaType == 'text'` (no media selected). Horizontal row of gradient circle swatches.
4. **Options section** — reorganized:
   - Mood: emoji chips in horizontal scroll
   - Category: dropdown
   - Language: dropdown
   - Privacy: segmented control (Public / Friends / Private)
   - Tags: chip input
   - Location: tap to add
   - Schedule: tap to set date

### 3.2 Bug Fixes

**Mounted check issues (the exception from the error trace):**
- Add `if (!mounted) return;` guards before every `setState()` call in async callbacks
- Add `if (!mounted) return;` before every `Navigator.pop(context)` / `showDialog(context)` in `_buildTagDialog` and all other dialogs
- Ensure all `TextEditingController` instances are properly disposed and not used after dispose
- Fix the tag dialog specifically: the recursive `Navigator.pop` → `showDialog` pattern that triggers unmounted state errors

**Validation updates:**
- Remove title validation (`_validateForm` no longer checks title)
- Update `_updateButtonState` (line ~183): remove `titleController.text.isNotEmpty` check, only check `descriptionController`
- `description` validation remains (required, max 2000 chars)

**Category list sync:**
- Update `_categories` list and `_categoryToBackend` map to match the full backend enum (add any missing, remove any that don't exist in backend)

### 3.3 Form Submission

- `toJson()` sends: `description`, `mood`, `tags`, `category`, `language`, `privacy`, `location`, `scheduledFor`, `backgroundColor`
- No `title` field sent
- `backgroundColor` only sent when `mediaType == 'text'` and user selected one

---

## 4. Flutter — Feed Card Layouts (moment_card.dart)

### 4.1 Two Card Layouts

**A) Media post (image/video) — Full-width:**
- Top row: user avatar + name + time ago + language badge
- Full-width image/video (edge-to-edge)
- Multiple images: horizontal PageView with dot indicators
- Action bar: like, comment, share, save, translate
- Caption text below (truncated with "more" to expand)
- Comment count → taps to single_moment detail

**B) Text-only post — Gradient card:**
- Top row: user avatar + name + time ago
- Gradient background card (from `backgroundColor` field) with centered, large white text
- If no `backgroundColor` set, use a default gradient
- Action bar below (same actions)
- No separate caption — the description IS the card content

**Card type selection logic:**
- If `mediaType == 'text'` and no images/video → use layout B (gradient)
- Otherwise (has images or video, regardless of caption) → use layout A (full-width media with caption)

### 4.2 Double-Tap to Like

- Wrap media area / gradient card in `GestureDetector` with `onDoubleTap`
- On double-tap: call like API (if not already liked) + show animated heart overlay
- Heart animation: white heart icon, centered on card, scale up + fade out (~800ms)
- Use `AnimationController` with `OverlayEntry` or `Stack` approach

### 4.3 Action Bar

- Keep existing actions: like, comment, share, save, translate
- Fix translate button `onPressed` (currently empty) — see Section 6

---

## 5. Flutter — Single Moment View (single_moment.dart)

- Remove title display
- Show caption (description) as main text
- For text-only moments: show gradient card at top instead of empty media area
- Fix translate button `onPressed` (currently empty) — see Section 6
- Ensure edit and delete actions work correctly and refresh parent feed

---

## 6. Flutter — Translation Feature Fixes

### 6.1 Wire Up Dead Translate Buttons

**moment_card.dart (~line 729):**
- Connect `onPressed` to trigger `TranslatedMomentWidget`'s language selector bottom sheet
- Use the existing `TranslationService.translateMoment()` method

**single_moment.dart (~line 601):**
- Same fix — connect to language selector and translation service

### 6.2 Sync Language Lists

- Update `TranslatedMomentWidget`'s language selector from 20 to 44 languages to match backend's supported list
- Group/sort alphabetically for easier browsing

---

## 7. Flutter — Localization (i18n)

### 7.1 New Strings to Add

Add to all 18 ARB files (`app_en.arb` as template, then translate for ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW):

**Permission dialogs:**
- `maximumImagesReached` — "Maximum Images Reached"
- `maximumImagesReachedDescription` — "You can only upload up to {maxImages} images per moment."
- `locationAccessRestricted` — "Location Access Restricted"
- `locationServicesDisabled` — "Location Services Disabled"
- `locationPermissionNeeded` — "Location Permission Needed"
- `locationPermissionRequired` — "Location Permission Required"
- (+ body text for each dialog)

**Buttons:**
- `ok` — "OK"
- `notNow` — "Not Now"
- `allow` — "Allow"
- `openSettings` — "Open Settings"

**Validation:**
- `captionRequired` — "Caption is required"
- `captionTooLong` — "Caption must be {maxLength} characters or less"
- `maximumTagsAllowed` — "Maximum 5 tags allowed"
- `scheduledDateMustBeFuture` — "Scheduled date must be in the future"

**Form labels:**
- `addToYourMoment` — "Add to your moment"
- `categoryLabel` — "Category"
- `languageLabel` — "Language"
- `scheduleOptional` — "Schedule (optional)"
- `scheduleForLater` — "Schedule for later"
- `whatsOnYourMind` — "What's on your mind?"
- `addMore` — "Add More"

**Mood:**
- `howAreYouFeeling` — "How are you feeling?"

**Video processing:**
- `processingVideo` — "Processing video..."
- `preparingVideo` — "Preparing video..."
- `videoCompressed` — "Video compressed"
- `pleaseWaitOptimizingVideo` — "Please wait while we optimize your video"
- `unsupportedVideoFormat` — "Unsupported format. Use: {formats}"
- `failedToProcessVideo` — "Failed to process video"
- `errorProcessingVideo` — "Error processing video"

**Other:**
- `locationAdded` — "Location added"
- `pleaseRemoveImagesFirst` — "Please remove images first to record a video"
- `failedToQueueUpload` — "Failed to queue upload"
- `chooseBackground` — "Choose a background"
- `maximumImagesAddedPartial` — "Maximum {maxImages} images allowed. Only {added} images added."

### 7.2 Remove Stale Strings

- Remove or update `checkOutMoment` (currently uses `{title}` parameter) — update to use description snippet for share text

### 7.3 Verify Other Files

- Audit `moment_filter_sheet.dart` for hardcoded strings
- Audit `saved_moments_screen.dart` for hardcoded strings
- Fix any found

---

## 8. Data Migration & Backward Compatibility

**No migration needed:**
- Removing `title` from schema: existing moments keep their title data in MongoDB, it's just never read or displayed
- `backgroundColor` defaults to empty string — old text posts render with a default gradient
- API stays backward-compatible: `description` field unchanged, `title` simply no longer accepted

**Flutter model:**
- `fromJson()` ignores `title` if present in API response (old cached data)
- `backgroundColor` defaults to empty if missing from response

---

## 9. Files to Modify

### Backend (language_exchange_backend_application)
| File | Changes |
|------|---------|
| `models/Moment.js` | Remove `title`, add `backgroundColor`, update slug logic |
| `validators/momentValidator.js` | Remove `title` validation, add `backgroundColor`, sync category enum |
| `controllers/moments.js` | Remove `title` refs, audit CRUD, verify feed queries |
| `routes/moments.js` | No changes expected (audit only) |

### Flutter (bananatalk_app)
| File | Changes |
|------|---------|
| `lib/providers/provider_models/moments_model.dart` | Remove `title`, add `backgroundColor`, gradient presets, sync `MomentMood` and `MomentCategory` |
| `lib/providers/provider_root/moments_providers.dart` | Remove `title` param from `createMoments()` and `updateMoment()` method signatures |
| `lib/services/upload_queue_service.dart` | Remove `title` param from `createMoments` call (~line 258) |
| `lib/pages/moments/create_moment.dart` | Remove title field, add background picker, fix mounted bugs, localize strings, sync mood/category lists |
| `lib/pages/moments/moment_card.dart` | Two card layouts, double-tap to like, fix translate button |
| `lib/pages/moments/single_moment.dart` | Remove title display, gradient card for text posts, fix translate button |
| `lib/widgets/translated_moment_widget.dart` | Expand language list from 20 to 44 |
| `lib/l10n/app_en.arb` | Add ~25 new strings, update share text |
| `lib/l10n/app_*.arb` (17 files) | Add translated versions of new strings |
| `lib/pages/moments/moments_main.dart` | Minor: update search to not reference title |
| `lib/pages/profile/main/profile_moments.dart` | Remove title display |
| `lib/pages/profile/main/profile_moment_edit.dart` | Remove title field, title validation, title controller from edit form |
| `lib/pages/profile/about/profile_single_moment.dart` | Remove title display, fix hardcoded share string (~line 134) |
| `lib/pages/moments/saved_moments_screen.dart` | Audit for hardcoded strings |
| `lib/pages/moments/moment_filter_sheet.dart` | Audit for hardcoded strings |
| `lib/pages/moments/moment_filter_bar.dart` | Audit for hardcoded strings |

---

## 10. Summary of Key Decisions

1. **Title removed completely** — not optional, gone. `description` is the only text field.
2. **Two card layouts** — full-width media (for posts with images/video) and gradient text-only
3. **Gradient backgrounds** — 8 presets for text-only posts, picked during creation
4. **Double-tap to like** — heart animation overlay
5. **All existing fields kept** — mood, category, tags, language, privacy, location, schedule — reorganized as compact chips/dropdowns
6. **Translation buttons wired up** — fix dead onPressed callbacks
7. **Language list synced** — frontend matches backend's 44 supported languages
8. **30+ strings localized** — across all 18 supported languages
9. **Category enum synced** — backend gets the missing categories from Flutter
10. **Mood enum synced** — canonical list of 12 moods across backend and Flutter
11. **Mounted/dispose bugs fixed** — in create_moment.dart tag dialog and async callbacks
12. **isDeleted filter bug fixed** — main feed, user moments, and single moment endpoints now filter soft-deleted moments
13. **Dead slug code removed** — unused `slugify` import and `slug` field cleaned up
14. **title references cleaned up** — notification service, translation controller, providers, upload queue service
