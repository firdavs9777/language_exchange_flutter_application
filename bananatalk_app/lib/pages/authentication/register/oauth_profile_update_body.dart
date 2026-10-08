/// The `PUT /auth/updatedetails` body an OAuth (Google/Apple) signup sends to
/// finish its profile.
///
/// Pure so the payload can be pinned by a test. It used to carry
/// `'images': []`, and the server writes every defined field, so finishing the
/// wizard replaced the photo Google/Apple had attached at sign-in with nothing
/// -- on exactly the accounts where the wizard had skipped the photo step
/// *because* that photo existed. Images are never part of this body: a photo
/// picked in the wizard goes through `uploadUserPhoto` (POST /users/:id/photos)
/// after this request succeeds.
library;

Map<String, dynamic> buildOAuthProfileUpdateBody({
  required String name,
  required String gender,
  required String birthYear,
  required String birthMonth,
  required String birthDay,
  required String nativeLanguage,
  required String learningLanguage,
  required Map<String, dynamic> clientInfo,
  String? languageLevel,
  String? city,
  String? country,
  double? latitude,
  double? longitude,
}) {
  return {
    'name': name,
    'gender': gender,
    'birth_year': birthYear,
    'birth_month': birthMonth,
    'birth_day': birthDay,
    'native_language': nativeLanguage,
    'language_to_learn': learningLanguage,
    'profileCompleted': true,
    'clientInfo': clientInfo,
    // `languageLevel` is CEFR for the language being LEARNED (it feeds the
    // partner filter and matchScoring, where B1+ scores differently).
    if (languageLevel != null) 'languageLevel': languageLevel,
    if (city != null && country != null)
      'location': {
        'type': 'Point',
        'coordinates': [longitude ?? 0.0, latitude ?? 0.0],
        'formattedAddress': '$city, $country',
        'city': city,
        'country': country,
      },
  };
}
