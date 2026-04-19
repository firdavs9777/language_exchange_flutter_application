# Moments Instagram-Style Redesign — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Moments feature to feel like Instagram/Facebook posts — remove title, add gradient text posts, two card layouts, double-tap to like, fix translation bugs, fix isDeleted bug, sync enums, and localize all hardcoded strings.

**Architecture:** Parallel backend + frontend. Backend changes are small and self-contained (schema, validator, controller fixes). Frontend changes are larger (model, creation flow, card layouts, translation, localization). Both can proceed independently since the API contract is simple: remove `title`, add `backgroundColor`.

**Tech Stack:** Node.js/Express + MongoDB (backend), Flutter + Riverpod (frontend), LibreTranslate (translation), DigitalOcean Spaces (media)

**Spec:** `docs/superpowers/specs/2026-04-19-moments-instagram-redesign.md`

---

## Task 1: Backend — Schema, Validator, and Dead Code Cleanup

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/models/Moment.js`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/validators/momentValidator.js`

- [ ] **Step 1: Update Moment.js schema — remove title, slug, slugify; add backgroundColor**

In `models/Moment.js`:
- Remove line 2: `const slugify = require('slugify');`
- Remove lines 5-11 (the `title` field definition)
- Remove line 76: `slug: String,`
- Add `backgroundColor` field after the `privacy` field (after line 114):

```js
backgroundColor: {
  type: String,
  enum: ['', 'gradient_sunset', 'gradient_ocean', 'gradient_forest',
         'gradient_purple', 'gradient_fire', 'gradient_midnight',
         'gradient_candy', 'gradient_sky'],
  default: ''
},
```

- [ ] **Step 2: Update Moment.js — sync category enum**

Replace the `category` enum (line 97) with the full list:

```js
enum: ['general', 'language-learning', 'culture', 'food', 'travel', 'music', 'books', 'hobbies',
       'daily-life', 'technology', 'entertainment', 'sports', 'movies', 'study', 'work', 'question'],
```

- [ ] **Step 3: Update Moment.js — sync mood enum**

Replace the `mood` enum (line 86) with the canonical list:

```js
enum: ['happy', 'excited', 'grateful', 'motivated', 'relaxed', 'curious',
       'sad', 'love', 'funny', 'thoughtful', 'cool', 'tired', ''],
```

- [ ] **Step 4: Update momentValidator.js — remove title, add backgroundColor, sync enums**

In `validators/momentValidator.js`:

Remove the `body('title')` block (lines 7-10) from `createMomentValidation`.

Add after the `description` validation:

```js
body('backgroundColor')
  .optional({ nullable: true })
  .isIn(['', 'gradient_sunset', 'gradient_ocean', 'gradient_forest',
         'gradient_purple', 'gradient_fire', 'gradient_midnight',
         'gradient_candy', 'gradient_sky']).withMessage('Invalid background color'),
```

Update the `body('mood')` `.isIn()` to match the canonical list:

```js
.isIn(['happy', 'excited', 'grateful', 'motivated', 'relaxed', 'curious',
       'sad', 'love', 'funny', 'thoughtful', 'cool', 'tired', '']).withMessage('Invalid mood'),
```

Update the `body('category')` `.isIn()` to match the full list:

```js
.isIn(['general', 'language-learning', 'culture', 'food', 'travel', 'music', 'books', 'hobbies',
       'daily-life', 'technology', 'entertainment', 'sports', 'movies', 'study', 'work', 'question']).withMessage('Invalid category'),
```

Do the same in `updateMomentValidation`:
- Remove `body('title')` block (lines 76-79)
- Add `backgroundColor` validation
- Update `mood` and `category` `.isIn()` lists

- [ ] **Step 5: Commit backend schema + validator changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add models/Moment.js validators/momentValidator.js
git commit -m "feat(moments): remove title field, add backgroundColor, sync mood/category enums"
```

---

## Task 2: Backend — Controller Fixes (isDeleted, title refs, notifications)

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_backend_application/controllers/moments.js`

- [ ] **Step 1: Fix getMoments — add isDeleted filter**

In `getMoments` (line 55), change:
```js
let query = { privacy: 'public' };
```
to:
```js
let query = { privacy: 'public', isDeleted: { $ne: true } };
```

Also in the authenticated user branch (line 60-61), add `isDeleted: { $ne: true }` to both sub-queries:
```js
const publicQuery = { privacy: 'public', isDeleted: { $ne: true } };
const ownPostsQuery = { user: req.user._id, isDeleted: { $ne: true } };
```

- [ ] **Step 2: Fix getMoment — add isDeleted filter**

In `getMoment` (line 128), change:
```js
const moment = await Moment.findById(req.params.id)
```
to:
```js
const moment = await Moment.findOne({ _id: req.params.id, isDeleted: { $ne: true } })
```

- [ ] **Step 3: Fix getUserMoments — add isDeleted filter**

In `getUserMoments` (line 216), change:
```js
let query = { user: targetUserId };
```
to:
```js
let query = { user: targetUserId, isDeleted: { $ne: true } };
```

- [ ] **Step 4: Fix createMoment — remove title references**

In `createMoment` (lines 268-279), remove `title` from the destructured `req.body`:
```js
const {
  description,
  mood,
  tags,
  category,
  language,
  privacy,
  location,
  scheduledFor,
  backgroundColor
} = req.body;
```

In `momentData` (lines 320-330), remove `title` and add `backgroundColor`:
```js
const momentData = {
  description,
  user: userId,
  mood: mood || '',
  tags: tags || [],
  category: category || 'general',
  language: language || 'en',
  privacy: privacy || 'public',
  scheduledFor: scheduledFor || null,
  backgroundColor: backgroundColor || ''
};
```

Fix notification call (line 362):
```js
description || ''
```
(remove `|| title`)

- [ ] **Step 5: Fix translateMoment — remove title fallback**

In `translateMoment` (line 1162), change:
```js
const sourceText = moment.description || moment.title || '';
```
to:
```js
const sourceText = moment.description || '';
```

- [ ] **Step 6: Commit controller fixes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add controllers/moments.js
git commit -m "fix(moments): add isDeleted filter to feed endpoints, remove title references"
```

---

## Task 3: Flutter — Model Changes (moments_model.dart)

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/providers/provider_models/moments_model.dart`

- [ ] **Step 1: Update Moments class — remove title, add backgroundColor**

In `Moments` constructor (lines 58-90):
- Remove `required this.title,` (line 60)
- Add `this.backgroundColor = '',` after `this.mediaType`

Remove the `title` field declaration (line 93):
```dart
final String title;
```

Add after `mediaType` field:
```dart
final String backgroundColor;
```

- [ ] **Step 2: Update fromJson — remove title, add backgroundColor**

In `fromJson` (line 153-234):
- Remove: `title: json['title']?.toString() ?? '',` (line 155)
- Add after `mediaType`: `backgroundColor: safeString(json['backgroundColor'], ''),`

- [ ] **Step 3: Update toJson — remove title, add backgroundColor**

In `toJson` (lines 238-264):
- Remove: `'title': title,` (line 241)
- Add: `'backgroundColor': backgroundColor,`

- [ ] **Step 4: Update copyWith — remove title, add backgroundColor**

In `copyWith` (lines 267-323):
- Remove `String? title,` from parameters (line 269)
- Remove `title: title ?? this.title,` from constructor call (line 297)
- Add `String? backgroundColor,` to parameters
- Add `backgroundColor: backgroundColor ?? this.backgroundColor,` to constructor call

- [ ] **Step 5: Add gradient presets constant**

Add after the `Moments` class closing brace (before `Comment` class at line 326):

```dart
/// Gradient presets for text-only moments
class MomentGradients {
  static const Map<String, List<int>> presets = {
    'gradient_sunset': [0xFFFF512F, 0xFFDD2476],
    'gradient_ocean': [0xFF2193B0, 0xFF6DD5ED],
    'gradient_forest': [0xFF11998E, 0xFF38EF7D],
    'gradient_purple': [0xFF8E2DE2, 0xFF4A00E0],
    'gradient_fire': [0xFFFF416C, 0xFFFF4B2B],
    'gradient_midnight': [0xFF0F2027, 0xFF2C5364],
    'gradient_candy': [0xFFD585FF, 0xFF00FFEE],
    'gradient_sky': [0xFF56CCF2, 0xFF2F80ED],
  };

  static const String defaultGradient = 'gradient_purple';

  static List<int> getColors(String key) {
    return presets[key] ?? presets[defaultGradient]!;
  }
}
```

- [ ] **Step 6: Sync MomentCategory class**

Replace the `MomentCategory` class (lines 484-503) with:

```dart
class MomentCategory {
  static const String general = 'general';
  static const String languageLearning = 'language-learning';
  static const String culture = 'culture';
  static const String food = 'food';
  static const String travel = 'travel';
  static const String music = 'music';
  static const String books = 'books';
  static const String hobbies = 'hobbies';
  static const String dailyLife = 'daily-life';
  static const String technology = 'technology';
  static const String entertainment = 'entertainment';
  static const String sports = 'sports';
  static const String movies = 'movies';
  static const String study = 'study';
  static const String work = 'work';
  static const String question = 'question';

  static List<Map<String, String>> get all => [
        {'value': general, 'label': 'General', 'icon': '🌐'},
        {'value': languageLearning, 'label': 'Language Learning', 'icon': '📚'},
        {'value': culture, 'label': 'Culture', 'icon': '🎭'},
        {'value': food, 'label': 'Food', 'icon': '🍜'},
        {'value': travel, 'label': 'Travel', 'icon': '✈️'},
        {'value': music, 'label': 'Music', 'icon': '🎵'},
        {'value': books, 'label': 'Books', 'icon': '📖'},
        {'value': hobbies, 'label': 'Hobbies', 'icon': '🎨'},
        {'value': dailyLife, 'label': 'Daily Life', 'icon': '☀️'},
        {'value': technology, 'label': 'Technology', 'icon': '💻'},
        {'value': entertainment, 'label': 'Entertainment', 'icon': '🎬'},
        {'value': sports, 'label': 'Sports', 'icon': '⚽'},
        {'value': movies, 'label': 'Movies', 'icon': '🎥'},
        {'value': study, 'label': 'Study', 'icon': '📝'},
        {'value': work, 'label': 'Work', 'icon': '💼'},
        {'value': question, 'label': 'Question', 'icon': '❓'},
      ];
}
```

- [ ] **Step 7: Sync MomentMood class**

Replace the `MomentMood` class (lines 507-523) with:

```dart
class MomentMood {
  static const String happy = 'happy';
  static const String excited = 'excited';
  static const String grateful = 'grateful';
  static const String motivated = 'motivated';
  static const String relaxed = 'relaxed';
  static const String curious = 'curious';
  static const String sad = 'sad';
  static const String love = 'love';
  static const String funny = 'funny';
  static const String thoughtful = 'thoughtful';
  static const String cool = 'cool';
  static const String tired = 'tired';

  static List<Map<String, String>> get all => [
        {'value': happy, 'label': 'Happy', 'emoji': '😊'},
        {'value': excited, 'label': 'Excited', 'emoji': '🤩'},
        {'value': grateful, 'label': 'Grateful', 'emoji': '🙏'},
        {'value': motivated, 'label': 'Motivated', 'emoji': '💪'},
        {'value': relaxed, 'label': 'Relaxed', 'emoji': '😌'},
        {'value': curious, 'label': 'Curious', 'emoji': '🤔'},
        {'value': sad, 'label': 'Sad', 'emoji': '😢'},
        {'value': love, 'label': 'Love', 'emoji': '😍'},
        {'value': funny, 'label': 'Funny', 'emoji': '😂'},
        {'value': thoughtful, 'label': 'Thoughtful', 'emoji': '💭'},
        {'value': cool, 'label': 'Cool', 'emoji': '😎'},
        {'value': tired, 'label': 'Tired', 'emoji': '😴'},
      ];
}
```

- [ ] **Step 8: Commit model changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/providers/provider_models/moments_model.dart
git commit -m "feat(moments): remove title, add backgroundColor and gradient presets, sync mood/category enums"
```

---

## Task 4: Flutter — Service Layer (remove title from API calls)

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/providers/provider_root/moments_providers.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/services/upload_queue_service.dart`

- [ ] **Step 1: Update MomentsService.createMoments — remove title, add backgroundColor**

In `moments_providers.dart`, `createMoments` method (line 91):
- Remove `required String title,` from parameters
- Add `String? backgroundColor,` parameter
- Remove `'title': title.trim(),` from body (line 113)
- Add after language: `if (backgroundColor != null && backgroundColor.isNotEmpty) body['backgroundColor'] = backgroundColor;`

- [ ] **Step 2: Update MomentsService.updateMoment — remove title, add backgroundColor**

In `moments_providers.dart`, `updateMoment` method (line 181):
- Remove `required String title,` from parameters
- Add `String? backgroundColor,` parameter
- Remove `'title': title.trim(),` from body (line 201)
- Add: `if (backgroundColor != null) body['backgroundColor'] = backgroundColor;`

- [ ] **Step 3: Update upload_queue_service.dart — remove title**

In `upload_queue_service.dart`:
- Remove `required String title,` from method signature (line 75)
- Remove `'title': title,` from metadata map (line 91)
- Remove `title: metadata['title'] ?? '',` from createMoments calls (lines 259, 292) — these must match the new signature without title

- [ ] **Step 4: Commit service layer changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/providers/provider_root/moments_providers.dart lib/services/upload_queue_service.dart
git commit -m "feat(moments): remove title from API service methods, add backgroundColor support"
```

---

## Task 5: Flutter — Creation Flow Redesign (create_moment.dart)

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/create_moment.dart`

- [ ] **Step 1: Remove titleController and title-related code**

- Remove `final titleController = TextEditingController();` (line 35)
- Remove `titleController.addListener(_updateButtonState);` (line 145)
- Remove `titleController.text = moment.title;` (line 151)
- Remove `titleController.removeListener(_updateButtonState);` (line 173)
- Remove `titleController.dispose();` (line 175)
- Remove `static const int maxTitleLength = 100;` (line 64)

- [ ] **Step 2: Add backgroundColor state variable**

Add after `DateTime? _scheduledDate;` (line 61):
```dart
String _selectedBackgroundColor = '';
```

- [ ] **Step 3: Update _updateButtonState — remove title check**

Change `_updateButtonState` (line 182-184) to:
```dart
void _updateButtonState() {
  isButtonEnabled.value = descriptionController.text.isNotEmpty;
}
```

- [ ] **Step 4: Update _validateInputs — remove title validation, localize strings**

Replace `_validateInputs` (lines 956-978) with:
```dart
String? _validateInputs() {
  final description = descriptionController.text.trim();

  if (description.isEmpty) {
    return AppLocalizations.of(context)!.captionRequired;
  }
  if (description.length > maxDescriptionLength) {
    return AppLocalizations.of(context)!.captionTooLong;
  }
  if (_tags.length > 5) {
    return AppLocalizations.of(context)!.maximumTagsAllowed;
  }
  if (_scheduledDate != null && _scheduledDate!.isBefore(DateTime.now())) {
    return AppLocalizations.of(context)!.scheduledDateMustBeFuture;
  }
  return null;
}
```

- [ ] **Step 5: Update _createMoment — remove title from API calls, add backgroundColor**

In the edit mode branch (line 1133-1140), change to:
```dart
await ref.read(momentsServiceProvider).updateMoment(
  id: widget.momentToEdit!.id,
  description: descriptionController.text.trim(),
  category: _categoryToBackend[_selectedCategory] ?? 'general',
  mood: _selectedMood != null ? _moods[_selectedMood] : null,
  tags: _tags.isNotEmpty ? _tags : null,
  backgroundColor: _selectedBackgroundColor.isNotEmpty ? _selectedBackgroundColor : null,
);
```

In the create mode branch (line 1170-1180), change to:
```dart
final moment = await ref.read(momentsServiceProvider).createMoments(
  description: descriptionController.text.trim(),
  privacy: _selectedPrivacy.toLowerCase(),
  category: _categoryToBackend[_selectedCategory] ?? 'general',
  language: _languages[_selectedLanguage] ?? 'en',
  mood: _selectedMood != null ? _moods[_selectedMood] : null,
  tags: _tags.isNotEmpty ? _tags : null,
  scheduledFor: _scheduledDate?.toIso8601String(),
  location: locationData,
  backgroundColor: _selectedBackgroundColor.isNotEmpty ? _selectedBackgroundColor : null,
);
```

- [ ] **Step 6: Sync mood map with canonical list**

Replace `_moods` map (lines 126-137) with:
```dart
final Map<String, String> _moods = {
  '😊': 'happy',
  '🤩': 'excited',
  '🙏': 'grateful',
  '💪': 'motivated',
  '😌': 'relaxed',
  '🤔': 'curious',
  '😢': 'sad',
  '😍': 'love',
  '😂': 'funny',
  '💭': 'thoughtful',
  '😎': 'cool',
  '😴': 'tired',
};
```

- [ ] **Step 7: Fix mounted check bugs in _buildTagDialog and async callbacks**

In `_buildTagDialog` (around lines 2150-2190), wrap all `setState`, `Navigator.pop`, and `showDialog` calls with `if (!mounted) return;`:

For the `onDeleted` callback in chip (lines 2153-2161):
```dart
onDeleted: () {
  if (!mounted) return;
  setState(() {
    _tags.remove(tag);
  });
  if (!mounted) return;
  Navigator.pop(context);
  if (!mounted) return;
  showDialog(
    context: context,
    builder: (context) => _buildTagDialog(),
  );
},
```

For the ElevatedButton onPressed (lines 2173-2181):
```dart
onPressed: () {
  if (!mounted) return;
  _addTag();
  Navigator.pop(context);
  if (!mounted) return;
  showDialog(
    context: context,
    builder: (context) => _buildTagDialog(),
  );
},
```

Also audit ALL other `setState()` calls in async callbacks throughout the file and add `if (!mounted) return;` guards where missing (especially in location permission handlers, video processing callbacks, and image picker results).

- [ ] **Step 8: Remove title TextField from the build method**

Find and remove the title `TextField` / `TextFormField` widget in the `build()` method. This is the text field that uses `titleController`. Remove the entire widget and its surrounding padding/decoration.

- [ ] **Step 9: Add background color picker UI**

Add a background color picker widget that appears only when no media is selected (`_selectedImages.isEmpty && _selectedVideo == null`). Place it after the caption field:

```dart
if (_selectedImages.isEmpty && _selectedVideo == null) ...[
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.chooseBackground,
          style: context.titleSmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // "None" option
              GestureDetector(
                onTap: () => setState(() => _selectedBackgroundColor = ''),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(
                      color: _selectedBackgroundColor.isEmpty
                          ? const Color(0xFF00BFA5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.block, size: 20, color: Colors.grey),
                ),
              ),
              ...MomentGradients.presets.entries.map((entry) {
                final colors = entry.value;
                final isSelected = _selectedBackgroundColor == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBackgroundColor = entry.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: colors.map((c) => Color(c)).toList(),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00BFA5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    ),
  ),
],
```

- [ ] **Step 10: Commit creation flow changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/moments/create_moment.dart
git commit -m "feat(moments): redesign creation flow - remove title, add gradient picker, fix mounted bugs"
```

---

## Task 6: Flutter — Feed Card Layouts (moment_card.dart)

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/moment_card.dart`

- [ ] **Step 1: Add double-tap animation state**

Add to `_MomentCardState` class (after existing state variables, around line 38):
```dart
bool _showHeartAnimation = false;
```

- [ ] **Step 2: Add gradient text card builder method**

Add a method to build the gradient card for text-only posts:
```dart
Widget _buildGradientTextCard(Moments moment) {
  final colors = MomentGradients.getColors(
    moment.backgroundColor.isNotEmpty
        ? moment.backgroundColor
        : MomentGradients.defaultGradient,
  );
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 200),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.map((c) => Color(c)).toList(),
      ),
    ),
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        moment.description,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
```

- [ ] **Step 3: Add double-tap to like with heart animation**

Wrap the media/gradient area with a `GestureDetector` and `Stack` for the heart overlay:

```dart
Widget _buildDoubleTapLikeArea(Widget child) {
  return GestureDetector(
    onDoubleTap: () {
      if (!isLiked) {
        _handleLike();
      }
      setState(() => _showHeartAnimation = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showHeartAnimation = false);
      });
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (_showHeartAnimation)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value < 0.5 ? value * 2 : (1 - value) * 2,
                child: Transform.scale(
                  scale: 0.5 + value * 0.5,
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 80,
                    shadows: [
                      Shadow(blurRadius: 20, color: Colors.black38),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Update card build method — use two layouts based on mediaType**

In the main `build` method, update the card body to use the layout selection logic:
- If `moment.mediaType == 'text'` and `moment.images.isEmpty` and `!moment.hasVideo` → use `_buildDoubleTapLikeArea(_buildGradientTextCard(moment))`
- Otherwise → use `_buildDoubleTapLikeArea(existingMediaWidget)` wrapping the existing image/video display

Remove any references to `moment.title` in the card (title display, share text, etc.).

- [ ] **Step 5: Fix translate button — wire up onPressed**

Find the translate icon button (around line 729) with the empty `onPressed`, and connect it:
```dart
IconButton(
  icon: const Icon(Icons.translate, size: 20),
  onPressed: () {
    // Show language selector from TranslatedMomentWidget
    _showTranslationLanguageSelector(widget.moments);
  },
),
```

Add the `_showTranslationLanguageSelector` method that shows a bottom sheet with language options and calls the translation service.

- [ ] **Step 6: Update share text — use description instead of title**

Find where `moment.title` is used in share/report text and replace with a description snippet:
```dart
final shareText = widget.moments.description.length > 100
    ? '${widget.moments.description.substring(0, 100)}...'
    : widget.moments.description;
```

- [ ] **Step 7: Commit card layout changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/moments/moment_card.dart
git commit -m "feat(moments): add gradient text cards, double-tap to like, fix translate button"
```

---

## Task 7: Flutter — Single Moment View + Profile Pages

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/single_moment.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/profile/main/profile_moments.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/profile/main/profile_moment_edit.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/profile/about/profile_single_moment.dart`

- [ ] **Step 1: Update single_moment.dart — remove title, add gradient, fix translate**

- Remove all `moment.title` references (title display widgets)
- For text-only moments, show the gradient card at top instead of empty media area (same `_buildGradientTextCard` pattern as moment_card.dart)
- Fix the translate button `onPressed` (around line 601) — same pattern as moment_card.dart

- [ ] **Step 2: Update profile_moment_edit.dart — remove title completely**

- Remove `late TextEditingController titleController;` (line 19)
- Remove `titleController = TextEditingController(text: widget.moment.title);` (line 32)
- Remove `titleController.dispose();` (line 47)
- Remove title validation (lines 116-119)
- Remove `title: titleController.text.trim(),` from updateMoment call (line 147)
- Remove the title TextField widget (around line 265)
- Add `backgroundColor` parameter to the updateMoment call if needed

- [ ] **Step 3: Update profile_moments.dart — remove title display**

- Remove any `moment.title` display in the moments list/grid

- [ ] **Step 4: Update profile_single_moment.dart — remove title, fix share text**

- Remove title display
- Fix hardcoded share string (line ~134):
```dart
final shareText = moment.description.length > 100
    ? '${moment.description.substring(0, 100)}...'
    : moment.description;
```

- [ ] **Step 5: Commit profile and single moment changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/moments/single_moment.dart lib/pages/profile/main/profile_moments.dart lib/pages/profile/main/profile_moment_edit.dart lib/pages/profile/about/profile_single_moment.dart
git commit -m "feat(moments): remove title from single moment view and profile pages"
```

---

## Task 8: Flutter — Translation Feature Fixes

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/widgets/translated_moment_widget.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/services/translation_service.dart`

- [ ] **Step 1: Expand TranslatedMomentWidget language list from 20 to 44**

In `translated_moment_widget.dart`, find the language list used in the language selector bottom sheet and update it to match the backend's 44 supported languages. Sort alphabetically by language name.

- [ ] **Step 2: Sync translation_service.dart supportedLanguages**

In `translation_service.dart` (around lines 118-139), update `supportedLanguages` to include all 44 languages matching the backend:
```dart
static const List<Map<String, String>> supportedLanguages = [
  {'code': 'ar', 'name': 'Arabic'},
  {'code': 'az', 'name': 'Azerbaijani'},
  {'code': 'bg', 'name': 'Bulgarian'},
  {'code': 'cs', 'name': 'Czech'},
  {'code': 'cy', 'name': 'Welsh'},
  {'code': 'da', 'name': 'Danish'},
  {'code': 'de', 'name': 'German'},
  {'code': 'el', 'name': 'Greek'},
  {'code': 'en', 'name': 'English'},
  {'code': 'es', 'name': 'Spanish'},
  {'code': 'et', 'name': 'Estonian'},
  {'code': 'fi', 'name': 'Finnish'},
  {'code': 'fr', 'name': 'French'},
  {'code': 'ga', 'name': 'Irish'},
  {'code': 'he', 'name': 'Hebrew'},
  {'code': 'hi', 'name': 'Hindi'},
  {'code': 'hr', 'name': 'Croatian'},
  {'code': 'hu', 'name': 'Hungarian'},
  {'code': 'id', 'name': 'Indonesian'},
  {'code': 'it', 'name': 'Italian'},
  {'code': 'ja', 'name': 'Japanese'},
  {'code': 'kk', 'name': 'Kazakh'},
  {'code': 'ko', 'name': 'Korean'},
  {'code': 'ky', 'name': 'Kyrgyz'},
  {'code': 'lt', 'name': 'Lithuanian'},
  {'code': 'lv', 'name': 'Latvian'},
  {'code': 'mt', 'name': 'Maltese'},
  {'code': 'nl', 'name': 'Dutch'},
  {'code': 'no', 'name': 'Norwegian'},
  {'code': 'pl', 'name': 'Polish'},
  {'code': 'pt', 'name': 'Portuguese'},
  {'code': 'ro', 'name': 'Romanian'},
  {'code': 'ru', 'name': 'Russian'},
  {'code': 'sk', 'name': 'Slovak'},
  {'code': 'sl', 'name': 'Slovenian'},
  {'code': 'sv', 'name': 'Swedish'},
  {'code': 'tg', 'name': 'Tajik'},
  {'code': 'th', 'name': 'Thai'},
  {'code': 'tk', 'name': 'Turkmen'},
  {'code': 'tr', 'name': 'Turkish'},
  {'code': 'uk', 'name': 'Ukrainian'},
  {'code': 'uz', 'name': 'Uzbek'},
  {'code': 'vi', 'name': 'Vietnamese'},
  {'code': 'zh', 'name': 'Chinese'},
];
```

- [ ] **Step 3: Commit translation fixes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/widgets/translated_moment_widget.dart lib/services/translation_service.dart
git commit -m "feat(moments): expand translation language support from 20 to 44 languages"
```

---

## Task 9: Flutter — Localization (i18n) — Add Missing Strings

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/l10n/app_en.arb`
- Modify: All 17 other `app_*.arb` files in the same directory

- [ ] **Step 1: Add new English strings to app_en.arb**

Add these entries to `app_en.arb`:

```json
"captionRequired": "Caption is required",
"captionTooLong": "Caption must be {maxLength} characters or less",
"@captionTooLong": { "placeholders": { "maxLength": { "type": "int" } } },
"maximumTagsAllowed": "Maximum 5 tags allowed",
"scheduledDateMustBeFuture": "Scheduled date must be in the future",
"maximumImagesReached": "Maximum Images Reached",
"maximumImagesReachedDescription": "You can only upload up to {maxImages} images per moment.",
"@maximumImagesReachedDescription": { "placeholders": { "maxImages": { "type": "int" } } },
"maximumImagesAddedPartial": "Maximum {maxImages} images allowed. Only {added} images added.",
"@maximumImagesAddedPartial": { "placeholders": { "maxImages": { "type": "int" }, "added": { "type": "int" } } },
"locationAccessRestricted": "Location Access Restricted",
"locationServicesDisabled": "Location Services Disabled",
"locationPermissionNeeded": "Location Permission Needed",
"locationPermissionRequired": "Location Permission Required",
"ok": "OK",
"notNow": "Not Now",
"allow": "Allow",
"openSettings": "Open Settings",
"addToYourMoment": "Add to your moment",
"categoryLabel": "Category",
"languageLabel": "Language",
"scheduleOptional": "Schedule (optional)",
"scheduleForLater": "Schedule for later",
"whatsOnYourMind": "What's on your mind?",
"addMore": "Add More",
"howAreYouFeeling": "How are you feeling?",
"processingVideo": "Processing video...",
"preparingVideo": "Preparing video...",
"videoCompressed": "Video compressed",
"pleaseWaitOptimizingVideo": "Please wait while we optimize your video",
"unsupportedVideoFormat": "Unsupported format. Use: {formats}",
"@unsupportedVideoFormat": { "placeholders": { "formats": { "type": "String" } } },
"failedToProcessVideo": "Failed to process video",
"errorProcessingVideo": "Error processing video",
"locationAdded": "Location added",
"pleaseRemoveImagesFirst": "Please remove images first to record a video",
"failedToQueueUpload": "Failed to queue upload",
"chooseBackground": "Choose a background"
```

- [ ] **Step 2: Update checkOutMoment — remove title parameter**

Find `checkOutMoment` in `app_en.arb` and update it to not use `{title}`:
```json
"checkOutMoment": "Check out this moment on BananaTalk!"
```

- [ ] **Step 3: Add translations to all 17 other ARB files**

For each of the 17 non-English ARB files (ar, de, es, fr, hi, id, it, ja, ko, pt, ru, th, tl, tr, vi, zh, zh_TW), add the same keys with appropriate translations. Use the existing translations in those files as reference for style and tone.

- [ ] **Step 4: Replace hardcoded strings in create_moment.dart**

Go through `create_moment.dart` and replace every hardcoded string identified in the spec with the corresponding `AppLocalizations.of(context)!.keyName` call. Key replacements:
- `"Title is required"` → `AppLocalizations.of(context)!.captionRequired`
- `"Description is required"` → `AppLocalizations.of(context)!.captionRequired`
- `"Maximum Images Reached"` → `AppLocalizations.of(context)!.maximumImagesReached`
- `"How are you feeling?"` → `AppLocalizations.of(context)!.howAreYouFeeling`
- `"Processing video..."` → `AppLocalizations.of(context)!.processingVideo`
- `"Add More"` → `AppLocalizations.of(context)!.addMore`
- `"Category"` → `AppLocalizations.of(context)!.categoryLabel`
- `"Language"` → `AppLocalizations.of(context)!.languageLabel`
- etc. for all ~30 hardcoded strings

- [ ] **Step 5: Run flutter gen-l10n to regenerate localization files**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter gen-l10n
```

- [ ] **Step 6: Commit localization changes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/l10n/
git commit -m "feat(moments): localize all hardcoded strings in moments feature across 18 languages"
```

---

## Task 10: Flutter — Audit Remaining Files for Hardcoded Strings and Title Refs

**Files:**
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/moments_main.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/saved_moments_screen.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/moment_filter_sheet.dart`
- Modify: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/lib/pages/moments/moment_filter_bar.dart`

- [ ] **Step 1: Update moments_main.dart — remove title from search**

Check search/filter logic that might reference `moment.title` and update to only search `moment.description`. Remove any title display.

- [ ] **Step 2: Audit saved_moments_screen.dart for hardcoded strings**

Read the file, find any hardcoded English strings, replace with `AppLocalizations.of(context)!.xxx`. Remove any `moment.title` references.

- [ ] **Step 3: Audit moment_filter_sheet.dart and moment_filter_bar.dart**

Read both files, find any hardcoded English strings, replace with localized equivalents.

- [ ] **Step 4: Commit remaining audit fixes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add lib/pages/moments/
git commit -m "fix(moments): remove title refs from search/filter, audit hardcoded strings"
```

---

## Task 11: Verify — Build and Test

- [ ] **Step 1: Run Flutter build to verify no compile errors**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter build apk --debug 2>&1 | tail -20
```

- [ ] **Step 2: Fix any compilation errors found**

Address any errors from the build (missing imports, type mismatches, removed title references that were missed, etc.)

- [ ] **Step 3: Run backend to verify it starts without errors**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node -e "const Moment = require('./models/Moment'); console.log('Schema loaded OK:', Object.keys(Moment.schema.paths).join(', '));"
```

- [ ] **Step 4: Final commit with all fixes**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git add -A
git commit -m "fix: resolve build errors from moments redesign"
```
