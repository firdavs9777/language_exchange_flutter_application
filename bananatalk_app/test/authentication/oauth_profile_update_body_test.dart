import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/authentication/register/oauth_profile_update_body.dart';

Map<String, dynamic> _body({
  String? languageLevel,
  String? city,
  String? country,
}) =>
    buildOAuthProfileUpdateBody(
      name: 'Ann',
      gender: 'female',
      birthYear: '1995',
      birthMonth: '07',
      birthDay: '04',
      nativeLanguage: 'Korean',
      learningLanguage: 'English',
      clientInfo: const {'platform': 'ios'},
      languageLevel: languageLevel,
      city: city,
      country: country,
      latitude: 37.5,
      longitude: 127.0,
    );

void main() {
  test('never sends images, so the Google/Apple photo survives signup', () {
    // THE BUG: the body carried `'images': []` and updatedetails writes every
    // defined field, wiping the provider photo on profile completion.
    expect(_body().containsKey('images'), isFalse);
    expect(
      _body(languageLevel: 'B1', city: 'Seoul', country: 'KR')
          .containsKey('images'),
      isFalse,
    );
  });

  test('carries the core fields and profileCompleted', () {
    final b = _body();
    expect(b['birth_year'], '1995');
    expect(b['native_language'], 'Korean');
    expect(b['language_to_learn'], 'English');
    expect(b['profileCompleted'], isTrue);
    expect(b.containsKey('languageLevel'), isFalse);
    expect(b.containsKey('location'), isFalse);
  });

  test('location is GeoJSON [lng, lat] when a city was picked', () {
    final loc = _body(city: 'Seoul', country: 'KR')['location'] as Map;
    expect(loc['coordinates'], [127.0, 37.5]);
    expect(loc['formattedAddress'], 'Seoul, KR');
  });
}
