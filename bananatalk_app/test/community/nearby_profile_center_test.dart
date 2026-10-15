import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/tabs/nearby_tab.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

Location _loc(List<double> coords) => Location(
      type: 'Point',
      coordinates: coords,
      formattedAddress: '',
      street: '',
      city: 'Seoul',
      state: '',
      zipcode: '',
      country: 'South Korea',
    );

void main() {
  test('profile GeoJSON [lng, lat] becomes the search centre', () {
    final c = profileSearchCenter(_loc([126.97, 37.56]));
    expect(c, isNotNull);
    expect(c!.latitude, 37.56);
    expect(c.longitude, 126.97);
  });

  test('missing, [0, 0] or out-of-range profile coordinates give no centre',
      () {
    expect(profileSearchCenter(null), isNull);
    expect(profileSearchCenter(_loc([])), isNull);
    expect(profileSearchCenter(_loc([0, 0])), isNull);
    expect(profileSearchCenter(_loc([200, 37])), isNull);
    expect(profileSearchCenter(_loc([126, 95])), isNull);
  });
}
