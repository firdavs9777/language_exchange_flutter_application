import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Filters applied on a tab they do not change land on Partners (2026-10-18).
void main() {
  test('Matches-first layout: Matches / Gatherings / Rooms / Waves go to Partners', () {
    int? at(int i) => partnersTabIndexIfFilterless(currentIndex: i, matchesLayout: true, roomsTab: true);
    // matches, partners, gatherings, rooms, nearby, topics, waves
    expect(at(0), 1, reason: 'Matches');
    expect(at(1), isNull, reason: 'Partners already filters');
    expect(at(2), 1, reason: 'Gatherings');
    expect(at(3), 1, reason: 'Rooms');
    expect(at(4), isNull, reason: 'Nearby filters');
    expect(at(5), isNull, reason: 'Topics filters');
    expect(at(6), 1, reason: 'Waves');
  });

  test('legacy layout: Partners is 0, Gender filters', () {
    int? at(int i) => partnersTabIndexIfFilterless(currentIndex: i, matchesLayout: false, roomsTab: false);
    // partners, genders, gatherings, nearby, city, topics, waves
    expect(at(1), isNull);
    expect(at(2), 0);
    expect(at(6), 0);
  });
}
