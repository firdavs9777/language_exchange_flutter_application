import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// Profiles carry followersCount / followingCount / isFollowing (backend
/// followSummary); the app prefers them over the id lists, which are on their
/// way out of other users' profiles. Older servers send only the lists.
void main() {
  test('server counts and isFollowing win', () {
    final c = Community.fromJson({
      '_id': 'u2',
      'name': 'Bo',
      'followers': ['a', 'b'],
      'following': ['c'],
      'followersCount': 120,
      'followingCount': 7,
      'isFollowing': false,
    });
    expect(c.followerTotal, 120);
    expect(c.followingTotal, 7);
    expect(c.followedBy('a'), isFalse, reason: 'the server answer, not the list');
  });

  test('without them, the lists still work', () {
    final c = Community.fromJson({
      '_id': 'u2',
      'name': 'Bo',
      'followers': ['a', 'b'],
      'following': ['c'],
    });
    expect(c.followerTotal, 2);
    expect(c.followingTotal, 1);
    expect(c.followedBy('a'), isTrue);
    expect(c.followedBy('z'), isFalse);
  });
}
