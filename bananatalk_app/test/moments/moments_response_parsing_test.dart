import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

void main() {
  test('trending/explore: the list under `moments` is read', () {
    final r = MomentsResponse.fromJson({
      'success': true,
      'moments': <dynamic>[],
      'pagination': {'totalMoments': 9},
    });
    expect(r.success, isTrue);
    expect(r.totalMoments, 9);
  });

  test('saved: the total comes from pagination, not the page count', () {
    final r = MomentsResponse.fromJson({
      'success': true,
      'count': 10,
      'data': <dynamic>[],
      'pagination': {'totalMoments': 23},
    });
    expect(r.totalMoments, 23);
  });

  test('user moments: top-level totalMoments still wins', () {
    final r = MomentsResponse.fromJson({
      'success': true,
      'count': 1,
      'totalMoments': 1,
      'data': <dynamic>[],
    });
    expect(r.totalMoments, 1);
  });
}
