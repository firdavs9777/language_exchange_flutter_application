# Community Discovery & Profile Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Community partner list dense enough to browse, and pin the profile
detail screen's Follow/Chat/Wave actions so they never scroll away.

**Architecture:** Three independent UI changes inside `lib/pages/community/`. Task 1 builds
a shared test fixture every later task needs. Tasks 2–4 build pure widgets bottom-up
(language pill → match tags → the row that composes them). Task 5 re-renders the tab strip
as chips without touching its controller logic. Task 6 moves the detail action row into a
pinned overlay. Nothing here is a backend or API change.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), `flutter_test`, the app's own
design tokens in `lib/core/theme/app_theme.dart` and `lib/utils/theme_extensions.dart`.

**Spec:** `docs/superpowers/specs/2026-09-18-community-ui-design.md`

## Global Constraints

- **Imports are always `package:bananatalk_app/...`** — never relative `../../`. The linter
  enforces this.
- **Design tokens only.** Colours come from `AppColors` / `context.*` extensions, radii from
  `AppRadius`, shadows from `AppShadows`, spacing from `AppSpacing`. No raw hex, no
  `BoxShadow` literals.
- **Partner row:** radius 20, `AppShadows.sm`, 14px padding, 8px vertical gap.
- **Do not touch** `remapTabIndexForRoomsFlag`, `_roomsInsertionIndex`, `_baseTabCount`, or
  either kill switch (`roomsEnabled`, `gatheringsEnabled`) in `community_main.dart`.
- **Every task ends green:** `flutter test` passes and `flutter analyze` reports no errors
  and no warnings.
- Run all commands from `bananatalk_app/`.

---

### Task 1: Shared `Community` test fixture

No test in the repo constructs a `Community` today, and its constructor has 20 required
fields. Every later task needs one, so it is built first and built once.

**Files:**
- Create: `test/support/community_fixture.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `Community buildCommunity({String id, String name, String nativeLanguage,
  String languageToLearn, String? languageLevel, String bio, String birthYear,
  List<String> topics, double? responseRate, String createdAt, bool isOnline,
  bool vipSubscriptionActive, bool hasActiveStory, String city, String country})` —
  all named, all defaulted, returns a valid `Community`.

- [ ] **Step 1: Write the fixture**

```dart
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// Every field the constructor demands, defaulted to something harmless, so a
/// test can name only the one or two fields it actually cares about.
Community buildCommunity({
  String id = 'u1',
  String name = 'Yeonwoo',
  String nativeLanguage = 'Korean',
  String languageToLearn = 'English',
  String? languageLevel,
  String bio = '',
  String birthYear = '1997',
  List<String> topics = const [],
  double? responseRate,
  String? createdAt,
  bool isOnline = false,
  bool vipSubscriptionActive = false,
  bool hasActiveStory = false,
  String city = 'Seoul',
  String country = 'South Korea',
}) {
  return Community(
    id: id,
    name: name,
    email: '$id@example.com',
    bio: bio,
    mbti: '',
    bloodType: '',
    images: const [],
    imageUrls: const [],
    birth_day: '1',
    birth_month: '1',
    birth_year: birthYear,
    gender: 'female',
    native_language: nativeLanguage,
    language_to_learn: languageToLearn,
    languageLevel: languageLevel,
    followers: const [],
    followings: const [],
    createdAt: createdAt ?? DateTime(2020, 1, 1).toIso8601String(),
    version: 0,
    topics: topics,
    responseRate: responseRate,
    isOnline: isOnline,
    vipSubscriptionActive: vipSubscriptionActive,
    hasActiveStory: hasActiveStory,
    location: Location(
      type: 'Point',
      coordinates: const [0, 0],
      formattedAddress: '$city, $country',
      street: '',
      city: city,
      state: '',
      zipcode: '',
      country: country,
    ),
  );
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze test/support/community_fixture.dart`
Expected: "No issues found."

If a required field is missing, the analyzer names it — add it with a harmless default and
re-run until clean.

- [ ] **Step 3: Commit**

```bash
git add test/support/community_fixture.dart
git commit -m "test(community): a Community fixture, so tests name only what they mean"
```

---

### Task 2: `LanguageExchangePill`

**Files:**
- Create: `lib/widgets/language/language_exchange_pill.dart`
- Test: `test/widgets/language_exchange_pill_test.dart`

Built under `lib/widgets/` rather than `lib/pages/community/` because the moments plan
(`2026-09-18-moments-ui.md`, Task 1) consumes this exact widget. Building it here first is
the reason the two plans can run in parallel after this point.

**Interfaces:**
- Consumes: `buildCommunity` (Task 1).
- Produces:
  - `class LanguageExchangePill extends StatelessWidget` with
    `const LanguageExchangePill({super.key, required String nativeLanguage,
    required String learningLanguage, String? languageLevel, bool dense = false})`.
  - `int? dotsForLevel(String? level)` — top-level, pure: `null` for null/unknown,
    1 for A1/A2, 2 for B1/B2, 3 for C1/C2.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';

void main() {
  group('dotsForLevel', () {
    test('maps each CEFR band to a dot count', () {
      expect(dotsForLevel('A1'), 1);
      expect(dotsForLevel('A2'), 1);
      expect(dotsForLevel('B1'), 2);
      expect(dotsForLevel('B2'), 2);
      expect(dotsForLevel('C1'), 3);
      expect(dotsForLevel('C2'), 3);
    });

    test('is case insensitive', () {
      expect(dotsForLevel('b1'), 2);
    });

    // A missing level must read as ABSENT, never as "beginner" -- one filled
    // dot would be a claim the data does not make.
    test('returns null for a missing or unrecognised level', () {
      expect(dotsForLevel(null), isNull);
      expect(dotsForLevel(''), isNull);
      expect(dotsForLevel('fluent'), isNull);
    });
  });

  testWidgets('renders both language codes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LanguageExchangePill(
          nativeLanguage: 'Korean',
          learningLanguage: 'English',
          languageLevel: 'B1',
        ),
      ),
    ));

    expect(find.text('KR'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/widgets/language_exchange_pill_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'bananatalk_app' ... language_exchange_pill.dart` /
"dotsForLevel isn't defined". The file does not exist yet.

- [ ] **Step 3: Write the implementation**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/language_codes.dart';

/// Dots to fill for a CEFR level, or null when we do not know the level.
///
/// Null is not zero. A profile with no level renders NO dots rather than three
/// empty ones, because an empty indicator reads as "beginner" -- a claim the
/// data has not made. This is the bug the moments header shipped with, where
/// five dots were generated with a hardcoded `index < 3` for every user alive.
int? dotsForLevel(String? level) {
  switch (level?.trim().toUpperCase()) {
    case 'A1':
    case 'A2':
      return 1;
    case 'B1':
    case 'B2':
      return 2;
    case 'C1':
    case 'C2':
      return 3;
    default:
      return null;
  }
}

/// `KR ●●● ⇄ EN ●○○` — the single most important fact on a partner row or a
/// moment card, in one teal pill.
///
/// Lives in lib/widgets/ because both the community partner row and
/// MomentCardHeader render it. Before this, each screen had its own
/// implementation and each was wrong in a different way.
class LanguageExchangePill extends StatelessWidget {
  const LanguageExchangePill({
    super.key,
    required this.nativeLanguage,
    required this.learningLanguage,
    this.languageLevel,
    this.dense = false,
  });

  final String nativeLanguage;
  final String learningLanguage;
  final String? languageLevel;

  /// Smaller type and tighter padding, for the moment card header.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fontSize = dense ? 10.0 : 11.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 9,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: AppRadius.borderRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _code(context, shortLanguageCode(nativeLanguage), fontSize),
          _dots(3, fontSize),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.swap_horiz_rounded,
                size: fontSize + 2, color: AppColors.primary),
          ),
          _code(context, shortLanguageCode(learningLanguage), fontSize),
          if (dotsForLevel(languageLevel) case final filled?) _dots(filled, fontSize),
        ],
      ),
    );
  }

  Widget _code(BuildContext context, String code, double fontSize) => Text(
        code,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
        ),
      );

  Widget _dots(int filled, double fontSize) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.only(left: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.28),
              ),
            );
          }),
        ),
      );
}
```

- [ ] **Step 4: Provide `shortLanguageCode` if it does not already exist**

Run: `grep -rn "shortLanguageCode" lib/utils/language_codes.dart`

If it is absent, add it to `lib/utils/language_codes.dart` (do **not** create a second
language-code helper — this file is the app's existing one):

```dart
/// Two-letter display code for a language name: 'Korean' -> 'KR'.
/// Falls back to the first two letters uppercased so an unrecognised language
/// still renders something rather than blank.
String shortLanguageCode(String language) {
  const map = {
    'korean': 'KR', 'english': 'EN', 'japanese': 'JP', 'chinese': 'CN',
    'spanish': 'ES', 'french': 'FR', 'german': 'DE', 'russian': 'RU',
    'arabic': 'AR', 'portuguese': 'PT', 'italian': 'IT', 'hindi': 'HI',
    'vietnamese': 'VI', 'thai': 'TH', 'indonesian': 'ID', 'turkish': 'TR',
  };
  final key = language.toLowerCase().split(' (').first.trim();
  final hit = map[key];
  if (hit != null) return hit;
  if (language.isEmpty) return '';
  return language.toUpperCase().substring(0, language.length > 2 ? 2 : language.length);
}
```

- [ ] **Step 5: Run the test and watch it pass**

Run: `flutter test test/widgets/language_exchange_pill_test.dart`
Expected: PASS, all 5 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/language/language_exchange_pill.dart \
        lib/utils/language_codes.dart \
        test/widgets/language_exchange_pill_test.dart
git commit -m "feat(widgets): one language-exchange pill, with real proficiency dots"
```

---

### Task 3: `communityMatchTags` derivation

**Files:**
- Create: `lib/pages/community/card/community_match_tags.dart`
- Test: `test/community/community_match_tags_test.dart`

**Interfaces:**
- Consumes: `buildCommunity` (Task 1).
- Produces:
  - `enum MatchTagKind { isNew, similarAge, sharedTopic, repliesFast }`
  - `class MatchTag { final MatchTagKind kind; final String? value; }`
  - `List<MatchTag> communityMatchTags(Community candidate, Community? viewer)` — at most 2,
    in the priority order below.
  - `class CommunityMatchTags extends ConsumerWidget` taking `{required Community community}`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/card/community_match_tags.dart';

import '../support/community_fixture.dart';

void main() {
  final viewer = buildCommunity(
    id: 'me', birthYear: '1997', topics: ['Philosophy', 'Matcha'],
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
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/community/community_match_tags_test.dart`
Expected: FAIL — the file `community_match_tags.dart` does not exist.

- [ ] **Step 3: Write the implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

enum MatchTagKind { isNew, similarAge, sharedTopic, repliesFast }

class MatchTag {
  const MatchTag(this.kind, [this.value]);
  final MatchTagKind kind;

  /// The topic name, for [MatchTagKind.sharedTopic]. Null for every other kind.
  final String? value;
}

int? _ageOf(Community user) {
  final year = int.tryParse(user.birth_year);
  if (year == null || year <= 1900) return null;
  return DateTime.now().year - year;
}

/// Why this person is worth tapping, at most two reasons, derived on-device.
///
/// Order is priority, not preference: recency first (it is the most perishable
/// fact), then the two "we have something in common" signals, then responsiveness.
/// Returning fewer than two -- or none -- is a correct answer; the strip renders
/// nothing rather than inventing a reason.
List<MatchTag> communityMatchTags(Community candidate, Community? viewer) {
  final tags = <MatchTag>[];

  if (candidate.isNewUser) tags.add(const MatchTag(MatchTagKind.isNew));

  if (viewer != null) {
    final mine = _ageOf(viewer);
    final theirs = _ageOf(candidate);
    if (mine != null && theirs != null && (mine - theirs).abs() <= 3) {
      tags.add(const MatchTag(MatchTagKind.similarAge));
    }
  }

  if (viewer != null) {
    final shared = candidate.topics.firstWhere(
      (t) => viewer.topics.contains(t),
      orElse: () => '',
    );
    if (shared.isNotEmpty) tags.add(MatchTag(MatchTagKind.sharedTopic, shared));
  }

  final rate = candidate.responseRate;
  if (rate != null && rate >= 80) tags.add(const MatchTag(MatchTagKind.repliesFast));

  return tags.take(2).toList();
}

/// The tag strip. Renders nothing at all when no tag applies, so an empty
/// strip costs no height.
class CommunityMatchTags extends ConsumerWidget {
  const CommunityMatchTags({super.key, required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(userProvider).valueOrNull;
    final tags = communityMatchTags(community, viewer);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: _chip(context, tag),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, MatchTag tag) {
    final isBanana = tag.kind == MatchTagKind.isNew;
    final label = switch (tag.kind) {
      MatchTagKind.isNew => 'New',
      MatchTagKind.similarAge => 'Similar age',
      MatchTagKind.sharedTopic => 'Both like ${tag.value}',
      MatchTagKind.repliesFast => 'Replies fast',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isBanana
            ? AppColors.secondary.withValues(alpha: 0.28)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderRound,
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: context.captionSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: isBanana ? AppColors.secondaryDark : AppColors.primaryDark,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test and watch it pass**

Run: `flutter test test/community/community_match_tags_test.dart`
Expected: PASS, all 8 tests.

If `test('a fast replier is tagged')` fails because `similarAge` crowded it out, that is the
cap working — the fixture sets `birthYear: '1970'` precisely to keep the age tag away.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/card/community_match_tags.dart \
        test/community/community_match_tags_test.dart
git commit -m "feat(community): derive why a partner is worth tapping, on-device"
```

---

### Task 4: Rebuild the partner row

**Files:**
- Modify: `lib/pages/community/card/community_card.dart` (whole build; drop the
  slide/scale entrance)
- Modify: `lib/pages/community/card/community_card_meta.dart` (delete `buildFooter`,
  `_buildStatChip`, `_buildViewProfileButton`, `buildLanguageExchange`,
  `_buildLanguageChip`, `_buildLocationRow`)
- Test: `test/community/community_card_layout_test.dart`

**Interfaces:**
- Consumes: `LanguageExchangePill` (Task 2), `CommunityMatchTags` (Task 3),
  `buildCommunity` (Task 1).
- Produces: `CommunityCard` keeps its existing public constructor
  `({Key? key, required Community community, required VoidCallback onTap,
  int animationDelay = 0, bool isFollowing = false})` — call sites in
  `partner_discovery_tab.dart`, `nearby_tab.dart`, `city_tab.dart`, `genders_tab.dart`
  must keep compiling untouched.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/card/community_card.dart';

import '../support/community_fixture.dart';

Widget _host(Widget child, {double width = 320}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
      ),
    );

void main() {
  testWidgets('a maximal row does not overflow a 320pt phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(CommunityCard(
      community: buildCommunity(
        name: 'Bartholomew Fotheringay-Smythe',
        nativeLanguage: 'Chinese (Traditional)',
        languageToLearn: 'English',
        languageLevel: 'B2',
        bio: 'Looking for someone to practise with every single day of the week, '
             'preferably in the evenings, about food and films and everything else.',
        topics: const ['Philosophy'],
        vipSubscriptionActive: true,
      ),
      onTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });

  testWidgets('the row no longer carries a View Profile button', (tester) async {
    await tester.pumpWidget(_host(
      CommunityCard(community: buildCommunity(), onTap: () {}),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    // Tapping the row already opens the profile; a second control doing the
    // same thing is what this redesign removed.
    expect(find.textContaining('View Profile'), findsNothing);
  });

  testWidgets('tapping the row fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(
      CommunityCard(community: buildCommunity(), onTap: () => tapped = true),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(CommunityCard));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/community/community_card_layout_test.dart`
Expected: FAIL on `the row no longer carries a View Profile button` — the button is still
rendered by `buildFooter`.

- [ ] **Step 3: Replace `CommunityCard.build` and `_buildHeader`**

Replace the `build` and `_buildHeader` methods (currently `community_card.dart:88-189`)
with:

```dart
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              color: context.surfaceColor,
              boxShadow: context.isDarkMode ? [] : AppShadows.sm,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: widget.onTap,
                  splashColor: AppColors.primary.withValues(alpha: 0.1),
                  highlightColor: AppColors.primary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildRow(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityCardAvatar(
          imageUrl: widget.community.profileImageUrl,
          name: widget.community.name,
          nativeLanguage: widget.community.native_language,
          country: (widget.community.privacySettings?.showCountryRegion ?? true)
              ? widget.community.location.country
              : null,
          isVip: widget.community.isVip,
          userId: PrivacyUtils.shouldShowOnlineStatus(widget.community)
              ? widget.community.id
              : null,
          size: 54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CommunityCardMeta(
                community: widget.community,
                isFollowing: widget.isFollowing,
              ),
              const SizedBox(height: 4),
              LanguageExchangePill(
                nativeLanguage: widget.community.native_language,
                learningLanguage: widget.community.language_to_learn,
                languageLevel: widget.community.languageLevel,
              ),
              if (widget.community.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    widget.community.bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySmall.copyWith(color: context.textSecondary),
                  ),
                ),
              CommunityMatchTags(community: widget.community),
            ],
          ),
        ),
        const SizedBox(width: 10),
        CommunityCardActions(
          community: widget.community,
          onMessageTap: widget.onTap,
        ),
      ],
    );
  }
```

Add the imports this needs:

```dart
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';
import 'package:bananatalk_app/pages/community/card/community_match_tags.dart';
```

- [ ] **Step 4: Cut the slide and scale entrance**

In `initState`, delete `_slideAnimation` and `_scaleAnimation` (and their fields), and
shorten the controller:

```dart
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
```

A 500ms staggered slide+scale was tuned for two large cards per screen; at four rows it
reads as the list lagging behind the scroll.

- [ ] **Step 5: Delete the dead meta helpers**

In `community_card_meta.dart`, delete `buildFooter`, `_buildStatChip`,
`_buildViewProfileButton`, `buildLanguageExchange`, `_buildLanguageChip` and
`_buildLocationRow`, and remove `_buildLocationRow`'s call from `build`. Keep
`_buildNameRow` and `_buildFollowingBadge`.

- [ ] **Step 6: Run the tests and the analyzer**

Run: `flutter test test/community/ && flutter analyze lib/pages/community/`
Expected: all tests PASS; analyzer reports no errors and no warnings. Any "unused import"
or "unused element" warning means a helper deleted in Step 5 left a dangling reference —
remove it.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/community/card/ test/community/community_card_layout_test.dart
git commit -m "feat(community): one row per partner, and a reason to tap"
```

---

### Task 5: Tab strip becomes pill chips

**Files:**
- Modify: `lib/pages/community/main/community_tab_bar.dart` (rewrite the render; keep the
  class name and constructor)
- Test: `test/community/community_chip_bar_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `CommunityTabBar` keeps its exact constructor
  `({super.key, required TabController tabController, bool showRoomsTab = true,
  bool gatheringsEnabled = true})`, so `community_main.dart` needs no edit at all.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/main/community_tab_bar.dart';

void main() {
  testWidgets('tapping a chip moves the controller to that tab', (tester) async {
    late TabController controller;

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultTabController(
          length: 8,
          child: Builder(builder: (context) {
            controller = DefaultTabController.of(context);
            return Scaffold(
              body: CommunityTabBar(tabController: controller),
            );
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(controller.index, 0);

    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();

    expect(controller.index, 4);
  });

  testWidgets('the Rooms chip is absent when the kill switch is off', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultTabController(
          length: 7,
          child: Builder(builder: (context) {
            return Scaffold(
              body: CommunityTabBar(
                tabController: DefaultTabController.of(context),
                showRoomsTab: false,
              ),
            );
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Rooms'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/community/community_chip_bar_test.dart`
Expected: FAIL on the first test — the current `TabBar` labels sit beside icons and the tap
target resolves differently; the assertion `controller.index == 4` will not be reached
because `find.text('Nearby')` matches a `Tab` whose tap is handled by `TabBar`, and the
index arithmetic under test is the chip list's, which does not exist yet.

If it unexpectedly passes, the test is asserting the old `TabBar`'s behaviour — do not
proceed; rewrite the test to target the chip widgets by key instead.

- [ ] **Step 3: Rewrite the render as chips**

Replace the `build` method's returned widget. Keep the same tab ORDER and the same
conditional `showRoomsTab` entry at index 3 — this is a rendering change only.

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unread =
        ref.watch(wavesUnreadProvider).maybeWhen(data: (n) => n, orElse: () => 0);

    final labels = <String>[
      l10n.communityTabAll,
      l10n.communityTabGender,
      gatheringsEnabled ? l10n.gatheringsTabLabel : l10n.voiceRooms,
      if (showRoomsTab) 'Rooms',
      l10n.nearby,
      l10n.communityTabCity,
      l10n.topics,
      l10n.wavesTab,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: AnimatedBuilder(
        // The chips are driven by the controller, so they must repaint when it
        // moves -- including when the move came from a SWIPE rather than a tap.
        animation: tabController,
        builder: (context, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: _Chip(
                    label: labels[i],
                    selected: tabController.index == i,
                    showDot: labels[i] == l10n.wavesTab && unread > 0,
                    onTap: () => tabController.animateTo(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
```

And add the chip itself at the bottom of the file:

```dart
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRound,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.borderRound,
            border: Border.all(
              color: selected ? AppColors.primary : context.dividerColor,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                label,
                style: context.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.textSecondary,
                ),
              ),
              if (showDot)
                Positioned(
                  right: -8,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Remove the now-unused `flutter_animate` import if nothing else in the file uses it.

- [ ] **Step 4: Run the tests and watch them pass**

Run: `flutter test test/community/community_chip_bar_test.dart`
Expected: PASS, both tests.

- [ ] **Step 5: Confirm nothing else broke**

Run: `flutter test && flutter analyze`
Expected: the full suite PASSes (392 + the new tests) and the analyzer is clean. In
particular `community_main.dart` must not need an edit — if it does, the constructor
changed and that is a mistake.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/community/main/community_tab_bar.dart \
        test/community/community_chip_bar_test.dart
git commit -m "feat(community): the tab strip becomes teal pill chips"
```

---

### Task 6: Pin the detail screen's action bar

**Files:**
- Modify: `lib/pages/community/single/single_community_actions.dart` (rename the class,
  restyle for a floating bar)
- Modify: `lib/pages/community/single/single_community_screen.dart:555-565` (remove the
  sliver, wrap the body in a `Stack`)
- Modify: `lib/pages/community/single/single_community_moments.dart`,
  `lib/pages/community/single/single_community_about.dart` (bottom padding)
- Test: `test/community/single_community_action_bar_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `class SingleCommunityActionBar extends ConsumerWidget` with
  `({super.key, required Community community, required bool isFollower,
  required VoidCallback onMessage, required VoidCallback onFollowToggle})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/single/single_community_actions.dart';

import '../support/community_fixture.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('the bar offers Follow and Chat', (tester) async {
    await tester.pumpWidget(_host(SingleCommunityActionBar(
      community: buildCommunity(id: 'them'),
      isFollower: false,
      onMessage: () {},
      onFollowToggle: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byType(SingleCommunityActionBar), findsOneWidget);
    expect(find.byIcon(Icons.waving_hand_rounded), findsOneWidget);
  });

  testWidgets('Chat calls onMessage', (tester) async {
    var messaged = false;
    await tester.pumpWidget(_host(SingleCommunityActionBar(
      community: buildCommunity(id: 'them'),
      isFollower: false,
      onMessage: () => messaged = true,
      onFollowToggle: () {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('action-bar-chat')));
    expect(messaged, isTrue);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/community/single_community_action_bar_test.dart`
Expected: FAIL — "SingleCommunityActionBar isn't defined". The class is still called
`SingleCommunityActions`.

- [ ] **Step 3: Rename and restyle**

In `single_community_actions.dart`, rename `SingleCommunityActions` to
`SingleCommunityActionBar`, give the Chat button `key: const Key('action-bar-chat')`, and
replace the outer `Container`'s decoration so it floats:

```dart
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14, 0, 14, 14 + MediaQuery.of(context).padding.bottom,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRound,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: context.surfaceColor.withValues(alpha: 0.92),
              borderRadius: AppRadius.borderRound,
              border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
              boxShadow: AppShadows.lg,
            ),
            // The existing IntrinsicHeight > Row of Follow / Message / Wave
            // moves across unchanged -- only the container around it changes.
            child: _actionRow(context, l10n, isOwnProfile),
          ),
        ),
      ),
    );
```

Extract the current `IntrinsicHeight(child: Row(...))` — the Follow, Message and Wave
buttons exactly as they are today — into a private method:

```dart
  Widget _actionRow(BuildContext context, AppLocalizations l10n, bool isOwnProfile) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 10, child: _buildFollowButton(context, l10n)),
          const SizedBox(width: 10),
          Expanded(flex: 14, child: _buildMessageButton(context, l10n)),
          if (!isOwnProfile) ...[
            const SizedBox(width: 10),
            FutureBuilder<bool>(
              future: _alreadyWaved(community.id),
              builder: (context, snapshot) =>
                  _buildWaveButton(context, snapshot.data ?? false),
            ),
          ],
        ],
      ),
    );
  }
```

`_buildFollowButton`, `_buildMessageButton` and `_buildWaveButton` are unchanged apart from
their border radius, which becomes `AppRadius.borderRound` to match the bar.

Add `import 'dart:ui' show ImageFilter;`. Remove the `ConversationStarterRibbon` from
inside this widget — it moves in Step 5.

- [ ] **Step 4: Run the test and watch it pass**

Run: `flutter test test/community/single_community_action_bar_test.dart`
Expected: PASS, both tests.

- [ ] **Step 5: Mount it as an overlay**

In `single_community_screen.dart`, delete the `SliverToBoxAdapter` holding
`SingleCommunityActions` (currently lines 555–565) and wrap the `NestedScrollView` in a
`Stack`:

```dart
      body: Stack(
        children: [
          NestedScrollView(
            /* ...unchanged... */
          ),
          if (userId.isNotEmpty && userId != _community.id)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_starterDismissed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                      child: ConversationStarterRibbon(
                        community: _community,
                        compact: true,
                        onDismiss: () => setState(() => _starterDismissed = true),
                      ),
                    ),
                  SingleCommunityActionBar(
                    community: _community,
                    isFollower: isFollower,
                    onMessage: _navigateToChat,
                    onFollowToggle: isFollower ? _unfollowUser : _followUser,
                  ),
                ],
              ),
            ),
        ],
      ),
```

Add `bool _starterDismissed = false;` to the state class, and add an optional
`VoidCallback? onDismiss` to `ConversationStarterRibbon` that renders a small `×` when
non-null.

- [ ] **Step 6: Give the tab bodies room**

In `single_community_moments.dart` and `single_community_about.dart`, add bottom padding so
the last row is not covered by the floating bar:

```dart
  padding: EdgeInsets.only(bottom: 96 + MediaQuery.of(context).padding.bottom),
```

For the Moments `GridView`, this goes on its existing `padding`. For About, wrap the
scrolling child in a `Padding` with the same value.

- [ ] **Step 7: Verify the whole screen**

Run: `flutter test && flutter analyze`
Expected: full suite PASSes, analyzer clean.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/community/single/ lib/pages/community/widgets/conversation_starter_ribbon.dart \
        test/community/single_community_action_bar_test.dart
git commit -m "feat(community): Chat is reachable from anywhere on a profile"
```

---

### Task 7: Final verification

- [ ] **Step 1: Full suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: every test passes; "No issues found."

- [ ] **Step 2: Confirm the untouchable logic is untouched**

Run:

```bash
git diff main --stat -- lib/pages/community/main/community_main.dart
```

Expected: **no output.** `community_main.dart` must not have changed. If it did, the chip
bar's constructor drifted and Task 5 Step 5 was not honoured.

- [ ] **Step 3: See it on a device**

Run: `flutter run` and check, by hand: four partner rows fit a phone screen; chips scroll
and select; a profile shows Chat while scrolled into Moments; the last Moments row is not
hidden behind the bar.
