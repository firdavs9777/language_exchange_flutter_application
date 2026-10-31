import 'package:bananatalk_app/pages/community/partners/nearby_partners_view.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nearby (2026-10-18): a free account picking 200 km was silently searched
/// at 50 km; wider chips now show a lock that opens VIP.
void main() {
  test('chips above the account limit are locked; before the server answers, 50 km', () {
    expect(nearbyRadiusLocked(50, null), isFalse);
    expect(nearbyRadiusLocked(100, null), isTrue);
    expect(nearbyRadiusLocked(200, 500), isFalse, reason: 'VIP limit is 500 km');
    expect(nearbyRadiusLocked(100, 50), isTrue);
  });

  test('the response carries the searched radius and the account limit', () {
    final r = NearbyUsersResponse.fromJson({
      'data': [],
      'pagination': {'total': 0, 'limit': 20, 'offset': 0, 'hasMore': false},
      'search': {'radiusKm': 50, 'maxRadiusKm': 50},
    });
    expect(r.searchedRadiusKm, 50);
    expect(r.maxRadiusKm, 50);
    expect(NearbyUsersResponse.fromJson({'data': []}).maxRadiusKm, isNull);
  });
}
