import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/widgets/story/story_gradient_ring.dart';

/// Built through fromJson rather than the constructor: Community requires a
/// dozen fields a ring test does not care about, and this exercises the real
/// parsing path the server payload takes.
Community _author({required bool hasStory}) => Community.fromJson({
      '_id': 'u1',
      'name': 'Ana',
      'email': 'a@e.com',
      'hasActiveStory': hasStory,
    });

Moments _moment({required bool hasStory}) => Moments(
      id: 'm1',
      user: _author(hasStory: hasStory),
      description: 'hello',
      images: const [],
      imageUrls: const [],
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
    );

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('an author with a story lights the ring', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: _moment(hasStory: true),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 50));

    final ring = tester.widget<StoryGradientRing>(find.byType(StoryGradientRing));
    expect(ring.hasStory, isTrue);
  });

  testWidgets('an author with no story does not', (tester) async {
    // StoryGradientRing always renders -- it draws a plain box when there is
    // no story -- so the meaningful assertion is the flag, not the widget.
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: _moment(hasStory: false),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 50));

    final ring = tester.widget<StoryGradientRing>(find.byType(StoryGradientRing));
    expect(ring.hasStory, isFalse);
  });

  testWidgets('tapping the avatar fires onAvatarTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: _moment(hasStory: true),
      onAvatarTap: () => tapped++,
      onMenuTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(StoryGradientRing));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tapped, 1);
  });
}
