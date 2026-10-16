import 'dart:io';

import 'package:bananatalk_app/pages/moments/create/moment_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

/// The moment composer used to send `formattedAddress: "Location added"`
/// (English UI text) — or ", " — to the server as the moment's address when
/// reverse geocoding found nothing.
void main() {
  group('placemarkAddress', () {
    test('joins the non-empty parts', () {
      expect(
        placemarkAddress(const Placemark(
          street: 'Teheran-ro 1',
          locality: 'Seoul',
          administrativeArea: '',
          postalCode: null,
          country: 'South Korea',
        )),
        'Teheran-ro 1, Seoul, South Korea',
      );
    });

    test('is null for an empty placemark, not ", "', () {
      expect(placemarkAddress(const Placemark()), isNull);
      expect(placemarkAddress(const Placemark(locality: ' ', country: '')), isNull);
    });
  });

  group('momentLocationPayload', () {
    test('sends [lng, lat] and the address', () {
      expect(
        momentLocationPayload(latitude: 37.5, longitude: 127.0, formattedAddress: 'Seoul'),
        {
          'coordinates': [127.0, 37.5],
          'formattedAddress': 'Seoul',
        },
      );
    });

    test('leaves formattedAddress out when there is none', () {
      final payload = momentLocationPayload(latitude: 37.5, longitude: 127.0);
      expect(payload, {'coordinates': [127.0, 37.5]});
      expect(payload.containsKey('formattedAddress'), isFalse);
      expect(
        momentLocationPayload(latitude: 1, longitude: 2, formattedAddress: '  '),
        {'coordinates': [2.0, 1.0]},
      );
    });
  });

  test('the composer no longer writes UI text into the location data', () {
    final src = File('lib/pages/moments/create/create_moment.dart').readAsStringSync();
    expect(src, isNot(contains('"Location added"')));
    expect(src, isNot(contains("'formattedAddress': _formattedAddress ?? 'Location'")));
  });
}
