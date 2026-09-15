/// Which steps the profile wizard actually needs to show.
///
/// Extracted from RegisterTwo so the step order, the labels and the page
/// indexes are derived once and can be tested without driving the widget.
/// They had been computed in three places that each had to be kept in lockstep
/// by hand.
///
/// The server's requirements are the floor: gender, birth year, and two
/// distinct languages (controllers/auth.js derives `profileCompleted` from
/// exactly those, noting "Bio, images, location are optional — don't block
/// login for them"). The wizard must not demand more than that, because this
/// is where Apple/Google signups are lost — 282 of 298 such accounts never
/// returned after day one.
class RegistrationSteps {
  final bool needsPersonalInfo;
  final bool needsPhoto;
  final bool needsLanguages;

  const RegistrationSteps({
    required this.needsPersonalInfo,
    required this.needsPhoto,
    required this.needsLanguages,
  });

  int get totalSteps =>
      (needsPersonalInfo ? 1 : 0) +
      (needsPhoto ? 1 : 0) +
      (needsLanguages ? 2 : 0) +
      1; // Finish is always shown

  /// Page order: [PersonalInfo?] -> [Photo?] -> [Native, Learning]? -> Finish
  List<String> get labels => [
        if (needsPersonalInfo) 'About you',
        if (needsPhoto) 'Photo',
        if (needsLanguages) ...['Native language', 'Learning language'],
        'Finish',
      ];

  int? get personalInfoStepIndex => needsPersonalInfo ? 0 : null;

  int? get photoStepIndex =>
      needsPhoto ? (needsPersonalInfo ? 1 : 0) : null;

  int? get languageStepIndex => needsLanguages
      ? (needsPersonalInfo ? 1 : 0) + (needsPhoto ? 1 : 0)
      : null;
}

/// Build the plan from what is already known about the account.
///
/// [hasPhoto] is the one that shortens the funnel most: Apple and Google hand
/// over a profile picture at sign-in, and 163 of 165 incomplete Google
/// accounts already carry one — yet the photo step used to be unconditional.
RegistrationSteps planRegistrationSteps({
  required String gender,
  required String birthDate,
  required String nativeLanguage,
  required String learningLanguage,
  required bool hasPhoto,
}) {
  // Mirrors the server's check: both set AND different. Asking again is
  // better than a completion the server will refuse with PROFILE_INCOMPLETE.
  final languagesKnown = nativeLanguage.isNotEmpty &&
      learningLanguage.isNotEmpty &&
      nativeLanguage != learningLanguage;

  return RegistrationSteps(
    needsPersonalInfo: gender.isEmpty || birthDate.isEmpty,
    needsPhoto: !hasPhoto,
    needsLanguages: !languagesKnown,
  );
}
