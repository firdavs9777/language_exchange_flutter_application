/// Pure profile-completion logic — no UI, no Flutter widgets.
///
/// Call [calculateProfileCompletion] with the current field values
/// (already resolved from widget state) to get a [ProfileCompletion]
/// that the hero-header progress bar and percent label can consume.
library;

class ProfileCompletion {
  final int completedFields;
  final int totalFields;

  const ProfileCompletion({
    required this.completedFields,
    required this.totalFields,
  });

  /// 0.0 – 1.0 fraction suitable for [LinearProgressIndicator.value].
  double get fraction =>
      totalFields == 0 ? 0 : completedFields / totalFields;

  /// 0 – 100 integer percentage.
  int get percent => (fraction * 100).round();
}

/// Returns the completion state for the profile edit screen.
///
/// Every parameter corresponds to a value the caller resolved from
/// widget / state — pass the display string or the sentinel "Not Set"
/// exactly as the screen stores it.
ProfileCompletion calculateProfileCompletion({
  required String name,
  required String gender,
  required String bio,
  required String nativeLanguage,
  required String languageToLearn,
  required String? languageLevel,
  required String mbti,
  required String address,
  required List<String> topics,
}) {
  const notSet = 'Not Set';
  const total = 9;
  int filled = 0;

  if (name != notSet) filled++;
  if (gender != notSet) filled++;
  if (bio != notSet) filled++;
  if (nativeLanguage != notSet) filled++;
  if (languageToLearn != notSet) filled++;
  if (languageLevel != null) filled++;
  if (mbti != notSet) filled++;
  if (address != notSet) filled++;
  if (topics.isNotEmpty) filled++;

  return ProfileCompletion(completedFields: filled, totalFields: total);
}
