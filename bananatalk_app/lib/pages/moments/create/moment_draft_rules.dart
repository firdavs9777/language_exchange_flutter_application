/// The rules that decide whether a moment can be posted.
///
/// Pure and Flutter-free, so they can be checked without a camera, a gallery
/// or a network. They lived inline in `create_moment.dart` — 2,634 lines, 58
/// state fields, no tests — which meant the rule governing whether anyone can
/// post at all was unverifiable.
///
/// Nothing here changes behaviour. Each function reproduces exactly what the
/// widget already did; the point is that it can now be pinned down.
library;

/// Images per moment. Also the number quoted to the poster when they exceed it.
const int kMaxImages = 10;

/// Characters in a caption, counted after trimming.
const int kMaxDescriptionLength = 2000;

/// Tags per moment. This was a bare `5` inside a validation branch.
const int kMaxTags = 5;

/// Returns the reason a draft cannot be posted, or null when it can.
///
/// Order is deliberate and preserved from the original: caption problems are
/// reported before tag or schedule problems, because an empty caption is the
/// more basic failure and reporting the subtler one first would be confusing.
///
/// [now] is a parameter rather than `DateTime.now()` so the schedule rule can
/// be tested without waiting for a clock.
String? validateMomentDraft({
  required String description,
  required List<String> tags,
  DateTime? scheduledDate,
  required DateTime now,
}) {
  final trimmed = description.trim();

  if (trimmed.isEmpty) {
    return 'Caption is required';
  }
  if (trimmed.length > kMaxDescriptionLength) {
    return 'Caption must be $kMaxDescriptionLength characters or less';
  }
  if (tags.length > kMaxTags) {
    return 'Maximum $kMaxTags tags allowed';
  }
  if (scheduledDate != null && scheduledDate.isBefore(now)) {
    return 'Scheduled date must be in the future';
  }
  return null;
}

/// How many of [adding] images will actually fit.
///
/// The widget computed this inline in two places as
/// `maxImages - _selectedImages.length` and fed it to `take(...)`. Clamped at
/// zero because a negative would turn that `take` into a RangeError instead of
/// a no-op — reachable if `current` ever exceeded the cap.
int imagesAddable({
  required int current,
  required int adding,
  int max = kMaxImages,
}) {
  final free = max - current;
  if (free <= 0) return 0;
  return adding < free ? adding : free;
}

/// The display name for a language code, falling back to English.
///
/// The fallback is deliberate rather than incidental: a moment must always
/// carry a language, and English is the safe default for this audience. It was
/// previously an `orElse` buried in a `firstWhere`, where it read as an
/// afterthought.
String languageNameForCode(String? code, Map<String, String> languages) {
  if (code == null || code.isEmpty) return 'English';
  for (final entry in languages.entries) {
    if (entry.value == code) return entry.key;
  }
  return 'English';
}
