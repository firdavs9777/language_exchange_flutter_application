import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/community/gathering_model.dart';

/// The club detail page showed a name, a member COUNT and a list of gathering
/// cards — which is why it read as a gathering page with a different title.
///
/// `city` and `place` had existed on the server model since it was written and
/// were never sent. `members` never left the server, so every club looked
/// leaderless: you were asked to join something with no visible human behind
/// it. `role` was in the schema and nothing read it.
void main() {
  Map<String, dynamic> payload({Object? members, Object? place}) => {
        '_id': 'c1',
        'name': 'Seoul Coffee Chat',
        'description': 'we meet on saturdays',
        'language': 'ko',
        'languageLabel': 'Korean',
        'interest': 'coffee',
        'owner': {'_id': 'u1', 'name': 'Dana', 'images': <String>[]},
        'memberCount': 3,
        'city': 'Seoul',
        'place': place ?? {'name': 'Anthracite', 'address': 'Hapjeong'},
        'createdAt': '2026-03-04T10:00:00.000Z',
        'roleCounts': {'owner': 1, 'organizer': 1, 'member': 1},
        'pastCount': 11,
        'viewerCanManage': true,
        'members': members ??
            [
              {'_id': 'u1', 'name': 'Dana', 'role': 'owner', 'images': ['a.jpg']},
              {'_id': 'u2', 'name': 'Sam', 'role': 'organizer', 'images': <String>[]},
              {'_id': 'u3', 'name': 'Rio', 'role': 'member', 'images': <String>[]},
            ],
      };

  test('the fields the page never had all parse', () {
    final club = Club.fromJson(payload());
    expect(club.city, 'Seoul');
    expect(club.place?.name, 'Anthracite');
    expect(club.pastCount, 11);
    expect(club.organizerCount, 1);
    expect(club.createdAt?.year, 2026);
    expect(club.viewerCanManage, isTrue);
  });

  test('leaders are the owner and organizers, not every member', () {
    // The row that answers "who is behind this?" — the question the page could
    // not answer at all.
    final club = Club.fromJson(payload());
    expect(club.leaders.map((m) => m.name), ['Dana', 'Sam']);
    expect(club.members.length, 3);
  });

  test('a member with no role is an ordinary member, not dropped', () {
    final club = Club.fromJson(payload(members: [
      {'_id': 'u9', 'name': 'Kim', 'images': <String>[]},
    ]));
    expect(club.members.single.role, 'member');
    expect(club.members.single.leads, isFalse);
  });

  test('an empty place is null, so the UI skips the block', () {
    // Rendering "meets at" with nothing after it is worse than omitting it.
    for (final p in [
      <String, dynamic>{'name': '', 'address': ''},
      <String, dynamic>{},
    ]) {
      expect(Club.fromJson(payload(place: p)).place, isNull);
    }
  });

  test('a club with none of the new fields still parses', () {
    // Older payloads, and list responses which send a thinner shape.
    final club = Club.fromJson({
      '_id': 'c2',
      'name': 'Bare',
      'owner': {'_id': 'u1'},
    });
    expect(club.city, isNull);
    expect(club.place, isNull);
    expect(club.members, isEmpty);
    expect(club.pastCount, 0);
    expect(club.viewerCanManage, isFalse);
    expect(club.leaders, isEmpty);
  });

  test('avatar is the first image, or null', () {
    final club = Club.fromJson(payload());
    expect(club.members.first.avatar, 'a.jpg');
    expect(club.members[1].avatar, isNull);
  });

  test('viewerCanManage is independent of viewerIsOwner', () {
    // An organizer may edit and remove members; only the owner may delete the
    // club or change who else is an organizer.
    final organizer = Club.fromJson({
      ...payload(),
      'viewerIsOwner': false,
      'viewerCanManage': true,
    });
    expect(organizer.viewerIsOwner, isFalse);
    expect(organizer.viewerCanManage, isTrue);
  });
}
