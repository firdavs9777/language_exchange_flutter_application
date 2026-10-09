import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/widgets/guides/guide_card.dart';
import 'package:bananatalk_app/widgets/guides/page_guide.dart';

Community _user({required int daysOld}) => Community(
      id: 'me',
      appleId: '',
      googleId: '',
      name: 'Me',
      email: '',
      mbti: '',
      bloodType: '',
      bio: '',
      images: const [],
      birth_day: '',
      birth_month: '',
      gender: '',
      birth_year: '',
      native_language: 'English',
      language_to_learn: 'Korean',
      imageUrls: const [],
      createdAt:
          DateTime.now().subtract(Duration(days: daysOld)).toIso8601String(),
      version: 0,
      followers: const [],
      followings: const [],
      location: Location.defaultLocation(),
    );

const _surface = GuideSurface.moments;
const _fresh = GuideState(acted: false, timesShown: 0);

/// Inside the guide window vs. an account old enough to be past it.
const _insideWindow = 1;
const _pastWindow = kGuideWindowDays + 1;

Widget _wrap({
  required int daysOld,
  GuideState state = _fresh,
  bool acted = false,
  bool stateFails = false,
  VoidCallback? onCta,
}) =>
    ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) async => _user(daysOld: daysOld)),
        guideStateProvider(_surface).overrideWith((ref) async {
          if (stateFails) throw Exception('prefs unreadable');
          return state;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PageGuide(
            surface: _surface,
            icon: Icons.add_a_photo_rounded,
            accent: const Color(0xFF7C4DFF),
            title: 'Post something',
            body: 'A photo or one line.',
            ctaLabel: 'Post a moment',
            acted: acted,
            onCta: onCta ?? () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('someone inside the window sees the guide', (tester) async {
    await tester.pumpWidget(_wrap(daysOld: _insideWindow));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsOneWidget);
  });

  testWidgets('an account past the window does not', (tester) async {
    await tester.pumpWidget(_wrap(daysOld: _pastWindow));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
  });

  testWidgets('someone who already acted does not', (tester) async {
    await tester.pumpWidget(_wrap(
      daysOld: _insideWindow,
      state: const GuideState(acted: true, timesShown: 0),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
  });

  testWidgets('a page-derived acted signal hides it too', (tester) async {
    // The Chats guide passes conversations.isNotEmpty and Profile passes
    // "photo and bio": telling someone to do a thing their own screen is
    // showing them having done reads as a bug.
    await tester.pumpWidget(_wrap(daysOld: _insideWindow, acted: true));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
  });

  testWidgets('a high view count does not retire it inside the window',
      (tester) async {
    // The window ends the guide now, not a count. Someone who opens the app
    // ten times on day one still gets the card on the eleventh.
    await tester.pumpWidget(_wrap(
      daysOld: _insideWindow,
      state: const GuideState(acted: false, timesShown: 10),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsOneWidget);
  });

  testWidgets('the last day of the window still renders', (tester) async {
    await tester.pumpWidget(_wrap(
      daysOld: kGuideWindowDays - 1,
      state: _fresh,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsOneWidget);
  });

  testWidgets('the day after the window does not', (tester) async {
    await tester.pumpWidget(_wrap(daysOld: kGuideWindowDays, state: _fresh));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
  });

  testWidgets('unreadable storage shows nothing rather than throwing',
      (tester) async {
    await tester.pumpWidget(_wrap(daysOld: _insideWindow, stateFails: true));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it occupies no space when ineligible', (tester) async {
    // Pages mount this unconditionally at the top of their body, so an
    // ineligible guide that still took a few logical pixels would push every
    // page down for the ~99% of users who never see one.
    await tester.pumpWidget(_wrap(daysOld: _pastWindow));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(PageGuide));
    expect(size.height, 0);
  });

  testWidgets('the CTA fires the page callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(daysOld: _insideWindow, onCta: () => taps++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post a moment'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('the guide does not vanish from under the user mid-view',
      (tester) async {
    // If the state provider were invalidated after recordShown, the card
    // would be removed milliseconds after appearing and the page would jump
    // by its height -- exactly as the user reaches for the button. The cap
    // that made this acute is gone; the invalidation hazard is not.
    await tester.pumpWidget(_wrap(
      daysOld: _insideWindow,
      state: const GuideState(acted: false, timesShown: 1),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(GuideCard), findsOneWidget,
        reason: 'the last view must stay put for the whole visit');
  });
}
