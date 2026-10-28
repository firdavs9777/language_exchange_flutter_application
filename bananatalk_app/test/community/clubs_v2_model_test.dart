import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/community/gathering_model.dart';

/// Clubs v2 fields are additive: a club payload from before v2 (or for a
/// viewer without access) has none of them and must parse to the defaults.
void main() {
  test('an old payload parses to the defaults', () {
    final club = Club.fromJson({
      '_id': 'c1',
      'name': 'Seoul Coffee Chat',
      'language': 'ko',
      'members': [
        {'_id': 'u1', 'name': 'A', 'role': 'owner'},
      ],
    });
    expect(club.secondLanguage, isNull);
    expect(club.secondLanguageLabel, '');
    expect(club.rules, isEmpty);
    expect(club.viewerWarningCount, 0);
    expect(club.members.single.warningCount, 0);
  });

  test('a v2 payload parses every new field', () {
    final club = Club.fromJson({
      '_id': 'c1',
      'name': 'Hangang Running',
      'language': 'en',
      'languageLabel': 'English',
      'secondLanguage': 'ko',
      'secondLanguageLabel': 'Korean',
      'rules': ['Be respectful.', 'No selling.'],
      'viewerWarningCount': 2,
      'members': [
        {'_id': 'u1', 'name': 'A', 'role': 'member', 'warningCount': 3},
      ],
    });
    expect(club.secondLanguage, 'ko');
    expect(club.secondLanguageLabel, 'Korean');
    expect(club.rules, ['Be respectful.', 'No selling.']);
    expect(club.viewerWarningCount, 2);
    expect(club.members.single.warningCount, 3);
  });

  test('copyWith keeps the v2 fields', () {
    final club = Club.fromJson({
      '_id': 'c1',
      'name': 'X',
      'secondLanguage': 'ko',
      'rules': ['r'],
      'viewerWarningCount': 1,
    }).copyWith(memberCount: 5);
    expect(club.secondLanguage, 'ko');
    expect(club.rules, ['r']);
    expect(club.viewerWarningCount, 1);
  });
}
