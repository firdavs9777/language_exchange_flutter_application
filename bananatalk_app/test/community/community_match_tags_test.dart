import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/card/community_match_tags.dart';

import '../support/community_fixture.dart';

void main() {
  final viewer = buildCommunity(
    id: 'me',
    birthYear: '1997',
    topics: ['Philosophy', 'Matcha'],
  );

  test('a brand-new profile is tagged New', () {
    final candidate = buildCommunity(
      id: 'them',
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    );
    expect(communityMatchTags(candidate, viewer).first.kind, MatchTagKind.isNew);
  });

  test('ages within three years are a similar age', () {
    final candidate = buildCommunity(id: 'them', birthYear: '1999');
    expect(
      communityMatchTags(candidate, viewer).map((t) => t.kind),
      contains(MatchTagKind.similarAge),
    );
  });

  test('a four-year age gap is not', () {
    final candidate = buildCommunity(id: 'them', birthYear: '1992');
    expect(
      communityMatchTags(candidate, viewer).map((t) => t.kind),
      isNot(contains(MatchTagKind.similarAge)),
    );
  });

  test('the first shared topic is named', () {
    final candidate = buildCommunity(id: 'them', topics: ['Hiking', 'Philosophy']);
    final tag = communityMatchTags(candidate, viewer)
        .firstWhere((t) => t.kind == MatchTagKind.sharedTopic);
    expect(tag.value, 'Philosophy');
  });

  test('a fast replier is tagged', () {
    final candidate = buildCommunity(id: 'them', responseRate: 91, birthYear: '1970');
    expect(
      communityMatchTags(candidate, viewer).map((t) => t.kind),
      contains(MatchTagKind.repliesFast),
    );
  });

  test('at most two tags, in priority order', () {
    final candidate = buildCommunity(
      id: 'them',
      birthYear: '1997',
      topics: ['Philosophy'],
      responseRate: 95,
      createdAt: DateTime.now().toIso8601String(),
    );
    final tags = communityMatchTags(candidate, viewer);
    expect(tags, hasLength(2));
    expect(tags[0].kind, MatchTagKind.isNew);
    expect(tags[1].kind, MatchTagKind.similarAge);
  });

  // An empty strip is correct output, not something to pad with filler.
  test('nothing applies, nothing is returned', () {
    final candidate = buildCommunity(id: 'them', birthYear: '1960');
    expect(communityMatchTags(candidate, viewer), isEmpty);
  });

  test('a null viewer yields only viewer-independent tags', () {
    final candidate = buildCommunity(
      id: 'them',
      topics: ['Philosophy'],
      createdAt: DateTime.now().toIso8601String(),
    );
    final tags = communityMatchTags(candidate, null);
    expect(tags.map((t) => t.kind), [MatchTagKind.isNew]);
  });
}
