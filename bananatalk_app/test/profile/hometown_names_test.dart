import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/hometown_names.dart';

Location _stored(String city, String country) => Location(
      type: 'Point',
      coordinates: const [126.9, 37.5],
      formattedAddress: '$city, $country',
      street: '',
      city: city,
      state: '',
      zipcode: '',
      country: country,
    );

void main() {
  test('geocoding failed: the stored city and country are kept', () {
    final names = resolveHometownNames(stored: _stored('Seoul', 'South Korea'));
    expect(names.city, 'Seoul');
    expect(names.country, 'South Korea');
  });

  test('no locality: only the city falls back', () {
    final names = resolveHometownNames(
      city: ' ',
      country: 'Japan',
      stored: _stored('Seoul', 'South Korea'),
    );
    expect(names.city, 'Seoul');
    expect(names.country, 'Japan');
  });

  test('resolved names replace the stored ones', () {
    final names = resolveHometownNames(
      city: 'Osaka',
      country: 'Japan',
      stored: _stored('Seoul', 'South Korea'),
    );
    expect(names.city, 'Osaka');
    expect(names.country, 'Japan');
  });

  test('nothing stored and nothing resolved: empty, as before', () {
    final names = resolveHometownNames();
    expect(names.city, '');
    expect(names.country, '');
  });
}
