/// The one profile-completion calculator, shared by the profile tab's
/// completion card and the edit screen's progress bar so both show the same
/// percentage and the same missing fields.
///
/// This is not the activation rule ("profile done = photo + bio"); that lives
/// with activation and is deliberately narrower.
library;

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// The fields that count. Keyed by this stable id, never by the localized
/// label: two labels that translate to the same word in some locale would
/// collapse into one map entry and skew the percentage. Declaration order is
/// the order missing fields are suggested in.
enum ProfileCompletionField {
  picture,
  name,
  gender,
  bio,
  nativeLanguage,
  learningLanguage,
  languageLevel,
  location,
  topics,
  mbti,
  birthYear,
  // Why they are here — learn, meet or date. Counted because the completion
  // card is the one surface that reaches users who signed up before the field
  // existed, and a soft ranking signal nobody fills in changes nothing.
  intents;

  String label(AppLocalizations l10n) => switch (this) {
        picture => l10n.profilePicture,
        name => l10n.nameLabel,
        gender => l10n.gender,
        bio => l10n.bio,
        nativeLanguage => l10n.nativeLanguage,
        learningLanguage => l10n.learningLanguageLabel,
        languageLevel => l10n.languageLevel,
        location => l10n.location,
        topics => l10n.topics,
        mbti => l10n.mbti,
        birthYear => l10n.profileBirthYear,
        intents => l10n.intentSectionTitle,
      };
}

class ProfileCompletion {
  final int completedFields;
  final int totalFields;

  /// Every unfilled field, in [ProfileCompletionField] order.
  final List<ProfileCompletionField> missing;

  const ProfileCompletion({
    required this.completedFields,
    required this.totalFields,
    required this.missing,
  });

  /// 0.0 – 1.0 fraction suitable for a progress indicator's value.
  double get fraction => totalFields == 0 ? 0 : completedFields / totalFields;

  /// 0 – 100 integer percentage.
  int get percent => (fraction * 100).round();
}

/// Completion over [filled], which must say for every field whether it is
/// set. Build it with [profileCompletionFieldsOf] and override what a screen
/// holds unsaved.
ProfileCompletion calculateProfileCompletion(
    Map<ProfileCompletionField, bool> filled) {
  final missing = [
    for (final f in ProfileCompletionField.values)
      if (filled[f] != true) f,
  ];
  final total = ProfileCompletionField.values.length;
  return ProfileCompletion(
    completedFields: total - missing.length,
    totalFields: total,
    missing: missing,
  );
}

/// Which fields [user] has filled.
Map<ProfileCompletionField, bool> profileCompletionFieldsOf(Community user) => {
      ProfileCompletionField.picture: user.imageUrls.isNotEmpty,
      ProfileCompletionField.name: user.name.isNotEmpty,
      ProfileCompletionField.gender: user.gender.isNotEmpty,
      ProfileCompletionField.bio: user.bio.isNotEmpty,
      ProfileCompletionField.nativeLanguage: user.native_language.isNotEmpty,
      ProfileCompletionField.learningLanguage:
          user.language_to_learn.isNotEmpty,
      ProfileCompletionField.languageLevel:
          user.languageLevel?.isNotEmpty == true,
      ProfileCompletionField.location: user.location.country.isNotEmpty ||
          user.location.city.isNotEmpty ||
          user.location.formattedAddress.isNotEmpty,
      ProfileCompletionField.topics: user.topics.isNotEmpty,
      ProfileCompletionField.mbti: user.mbti.isNotEmpty,
      ProfileCompletionField.birthYear: user.birth_year.isNotEmpty,
      ProfileCompletionField.intents: user.intents.isNotEmpty,
    };
