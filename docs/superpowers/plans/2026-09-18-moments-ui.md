# Moments Feed & Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the duplicated engagement counts, replace a fake proficiency indicator
with a real one, stop truncation from splitting emoji, make the card look like a card, add
Follow to the feed, and bring the detail screen to parity with it.

**Architecture:** Five independent changes inside `lib/pages/moments/`. Task 1 swaps the
moment header's hand-rolled language display for the shared `LanguageExchangePill`. Tasks
2–4 fix the card (counts, truncation, chrome + Follow). Task 5 brings detail to parity.
App-only; no backend, no API, no model change.

**Tech Stack:** Flutter, Riverpod, `flutter_test`, the app's tokens in
`lib/core/theme/app_theme.dart`.

**Spec:** `docs/superpowers/specs/2026-09-18-moments-ui-design.md`

## Global Constraints

- **DEPENDENCY:** Task 1 requires `LanguageExchangePill` and `dotsForLevel` from
  `docs/superpowers/plans/2026-09-18-community-ui.md` **Task 2**. Do not start this plan
  until that task is merged. Every other task here is independent of the community plan.
- **Imports are always `package:bananatalk_app/...`** — never relative.
- **Design tokens only** — `AppColors`, `AppRadius`, `AppShadows`, `AppSpacing`, or the
  `context.*` extensions. No raw hex.
- **Moment card:** radius 20 (`AppRadius.xl`), `AppShadows.sm`, 12px side margin, 10px gap
  — deliberately identical to the community partner row.
- **Do not touch** the media carousel, the double-tap heart, story rings, reels, the
  composer, the filter bar/sheet, comments, corrections, or the ad placements.
- **The inline Translate chip stays inline** under the caption on the card. It was moved
  out of the action row on purpose (see the comment at `moment_card.dart:648-652`).
- **Every task ends green:** `flutter test` passes, `flutter analyze` is clean.
- Run all commands from `bananatalk_app/`.

---

### Task 1: Real proficiency dots in the moment header

**Files:**
- Modify: `lib/pages/moments/card/moment_card_header.dart:141-196` (delete the native
  underline, the arrow, and the five hardcoded dots)
- Test: `test/moments/moment_card_header_test.dart`

**Interfaces:**
- Consumes: `LanguageExchangePill` from `lib/widgets/language/language_exchange_pill.dart`
  (community plan, Task 2).
- Produces: nothing new. `MomentCardHeader`'s constructor is unchanged.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child, {double width = 320}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );

void main() {
  testWidgets('the header renders the shared language pill', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageExchangePill), findsOneWidget);
  });

  // The bug: five dots built with `index < 3`, a constant, so a beginner and a
  // C2 speaker rendered identically on every card in the feed.
  testWidgets('a header with no level shows no proficiency dots', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(languageLevel: null),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    final pill = tester.widget<LanguageExchangePill>(
      find.byType(LanguageExchangePill),
    );
    expect(dotsForLevel(pill.languageLevel), isNull);
  });

  testWidgets('a maximal header does not overflow a 320pt phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(
        userName: 'Bartholomew Fotheringay-Smythe',
        nativeLanguage: 'Chinese (Traditional)',
        languageLevel: 'C2',
      ),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Create the moment fixture the test imports**

`Moments.user` is a `Community`, so this fixture delegates to `buildCommunity` from the
community plan's Task 1 rather than duplicating twenty defaults.

Create `test/support/moment_fixture.dart`:

```dart
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

import 'community_fixture.dart';

Moments buildMoment({
  String id = 'm1',
  String userName = 'YGK',
  String nativeLanguage = 'Korean',
  String languageToLearn = 'English',
  String? languageLevel,
  String description = 'Hello there',
  String language = 'ko',
  int likeCount = 0,
  int commentCount = 0,
  List<String> images = const [],
  DateTime? createdAt,
}) {
  return Moments(
    id: id,
    user: buildCommunity(
      id: 'author-$id',
      name: userName,
      nativeLanguage: nativeLanguage,
      languageToLearn: languageToLearn,
      languageLevel: languageLevel,
    ),
    description: description,
    images: images,
    imageUrls: images,
    likeCount: likeCount,
    commentCount: commentCount,
    language: language,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 16)),
  );
}
```

- [ ] **Step 3: Run the test and watch it fail**

Run: `flutter test test/moments/moment_card_header_test.dart`
Expected: FAIL — "Expected: exactly one matching node ... Actual: no matching nodes" for
`LanguageExchangePill`. The header still renders its own underline-and-dots row.

- [ ] **Step 4: Replace the hand-rolled language row**

In `moment_card_header.dart`, delete the second `Row` in the name column (the one holding
the underlined native code, the `Icons.arrow_forward`, the learning code and the
`List.generate(5, ...)` dots — lines 141–196) and replace it with:

```dart
                const SizedBox(height: 3),
                LanguageExchangePill(
                  nativeLanguage: moment.user.native_language,
                  learningLanguage: moment.user.language_to_learn,
                  languageLevel: moment.user.languageLevel,
                  dense: true,
                ),
```

Add `import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';` and
delete the now-unused `_getLanguageCode` helper.

`moment.user` is a `Community`, so `languageLevel` is already there — no model change is
needed. Where it is null the pill renders no dots, which is the correct answer and still
strictly better than three fake ones.

- [ ] **Step 5: Run the test and watch it pass**

Run: `flutter test test/moments/moment_card_header_test.dart`
Expected: PASS, all 3 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/moments/card/moment_card_header.dart \
        test/support/moment_fixture.dart \
        test/moments/moment_card_header_test.dart
git commit -m "fix(moments): proficiency dots were hardcoded 3-of-5 for every user"
```

---

### Task 2: One set of engagement counts

**Files:**
- Modify: `lib/pages/moments/card/moment_card.dart:872-903` (delete the engagement-counts
  block)
- Test: `test/moments/moment_card_counts_test.dart`

**Interfaces:**
- Consumes: `buildMoment` (Task 1).
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('a liked, commented moment shows each count once', (tester) async {
    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(likeCount: 189, commentCount: 21),
    )));
    await tester.pumpAndSettle();

    // The action row carries the numbers. The block that repeated them
    // underneath ("189 likes" / "21 comments") is gone.
    expect(find.text('189'), findsOneWidget);
    expect(find.textContaining('189 likes'), findsNothing);
    expect(find.textContaining('21 comments'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/moments/moment_card_counts_test.dart`
Expected: FAIL — `findsNothing` fails because "189 likes" is still rendered by the
engagement-counts block.

- [ ] **Step 3: Delete the duplicate block**

In `moment_card.dart`, delete the whole `if (likeCount > 0 || widget.moments.commentCount > 0)`
block (the one commented `── Engagement counts ───`, starting at line 873) together with
its `Padding`, `Column` and the two `Text`s inside it.

Leave the reaction-chips block that follows it — those are a different thing, not a second
copy of the same numbers.

- [ ] **Step 4: Run the test and watch it pass**

Run: `flutter test test/moments/moment_card_counts_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/moments/card/moment_card.dart test/moments/moment_card_counts_test.dart
git commit -m "fix(moments): stop printing every engagement count twice"
```

---

### Task 3: Truncation that cannot split a glyph

**Files:**
- Modify: `lib/pages/moments/card/moment_card.dart:596-600` and the caption `Text` at
  `:654-680`
- Test: `test/moments/moment_caption_truncation_test.dart`

**Interfaces:**
- Consumes: `buildMoment` (Task 1).
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  // substring(0, 150) counts UTF-16 code units, so an emoji straddling index
  // 150 was cut mid-surrogate-pair and rendered as a replacement glyph.
  testWidgets('an emoji at the cut point survives intact', (tester) async {
    final caption = '${'a' * 149}😊${'b' * 200}';

    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: caption),
    )));
    await tester.pumpAndSettle();

    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join();

    expect(rendered, isNot(contains('�')),
        reason: 'a replacement glyph means a surrogate pair was split');
  });

  testWidgets('a short caption gets no show-more toggle', (tester) async {
    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: 'Hello!'),
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('more'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/moments/moment_caption_truncation_test.dart`
Expected: FAIL on the first test — the rendered string contains `�` because
`substring(0, 150)` cut the emoji in half.

- [ ] **Step 3: Replace the manual truncation**

Delete lines 596–600:

```dart
    final fullText = widget.moments.description;
    final shouldShowMore = fullText.length > 150;
    final displayText = !isExpanded && shouldShowMore
        ? '${fullText.substring(0, 150)}...'
        : fullText;
```

with just:

```dart
    final fullText = widget.moments.description;
```

Then replace the caption `Text(displayText, ...)` and its `if (shouldShowMore)` toggle with
a `LayoutBuilder` that asks the text engine whether it actually overflowed:

```dart
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final style = Theme.of(context).textTheme.bodyMedium;
                        // Ask the engine, rather than guessing from a character
                        // count -- 150 code units is a different amount of text
                        // in Korean than in English, and a different number of
                        // LINES in both.
                        final painter = TextPainter(
                          text: TextSpan(text: fullText, style: style),
                          maxLines: 4,
                          textDirection: Directionality.of(context),
                        )..layout(maxWidth: constraints.maxWidth);
                        final overflows = painter.didExceedMaxLines;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullText,
                              style: style,
                              maxLines: isExpanded ? null : 4,
                              overflow: isExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                            if (overflows)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => isExpanded = !isExpanded),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    isExpanded
                                        ? AppLocalizations.of(context)!.showLess
                                        : AppLocalizations.of(context)!.showMore,
                                    style: context.labelMedium
                                        .copyWith(color: context.textSecondary),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
```

- [ ] **Step 4: Run the test and watch it pass**

Run: `flutter test test/moments/moment_caption_truncation_test.dart`
Expected: PASS, both tests.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/moments/card/moment_card.dart \
        test/moments/moment_caption_truncation_test.dart
git commit -m "fix(moments): caption truncation split emoji and Hangul mid-glyph"
```

---

### Task 4: The card becomes a card, and gains Follow

**Files:**
- Modify: `lib/pages/moments/card/moment_card.dart:610-616` (container decoration)
- Modify: `lib/pages/moments/card/moment_card_header.dart` (add the Follow pill, move the
  ⋯ beside the timestamp)
- Test: `test/moments/moment_card_follow_test.dart`

**Interfaces:**
- Consumes: `buildMoment` (Task 1).
- Produces: `MomentCardHeader` gains two optional named parameters —
  `bool isFollowing = false` and `VoidCallback? onFollowToggle` — so a card that does not
  pass them renders no Follow pill.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('Follow fires its callback', (tester) async {
    var toggled = false;

    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
      onFollowToggle: () => toggled = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('moment-follow')));
    expect(toggled, isTrue);
  });

  // Your own post is not something to follow.
  testWidgets('no Follow pill without a callback', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('moment-follow')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/moments/moment_card_follow_test.dart`
Expected: FAIL — "No named parameter with the name 'onFollowToggle'".

- [ ] **Step 3: Add the Follow pill to the header**

Add the two parameters to `MomentCardHeader`, and replace the trailing
time-over-menu `Column` with a single row so the ⋯ sits beside the timestamp rather than
above it:

```dart
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onFollowToggle != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    key: const Key('moment-follow'),
                    onTap: onFollowToggle,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderRound,
                        border: Border.all(
                          color: isFollowing
                              ? context.dividerColor
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isFollowing
                            ? AppLocalizations.of(context)!.following
                            : AppLocalizations.of(context)!.follow,
                        style: context.captionSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isFollowing
                              ? context.textSecondary
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                _getRelativeTime(context, moment.createdAt),
                style: context.captionSmall.copyWith(color: context.textMuted),
              ),
              IconButton(
                onPressed: onMenuTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.more_horiz, color: context.iconColor, size: 20),
              ),
            ],
          ),
```

- [ ] **Step 4: Run the test and watch it pass**

Run: `flutter test test/moments/moment_card_follow_test.dart`
Expected: PASS, both tests.

- [ ] **Step 5: Wire Follow to the real flow in `MomentCard`**

In `moment_card.dart`, pass `onFollowToggle` down only when the post is not the current
user's, and drive `isFollowing` from the provider rather than local state — the same author
can appear in several posts in one feed, and two cards by one author must not disagree:

```dart
            MomentCardHeader(
              moment: widget.moments,
              isFollowing: ref.watch(userProvider).valueOrNull
                      ?.followings.contains(widget.moments.user.id) ??
                  false,
              onFollowToggle: _isOwnPost ? null : _toggleFollow,
              onAvatarTap: /* unchanged */,
              onMenuTap: () => _showMoreOptions(context),
            ),
```

Implement `_toggleFollow` by calling the existing service and invalidating the providers —
the same calls `single_community_screen.dart` already makes:

```dart
  Future<void> _toggleFollow() async {
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isEmpty) return;
    final following = ref.read(userProvider).valueOrNull
            ?.followings.contains(widget.moments.user.id) ?? false;
    final service = ref.read(communityServiceProvider);
    if (following) {
      await service.unfollowUser(
          userId: userId, targetUserId: widget.moments.user.id);
    } else {
      await service.followUser(
          userId: userId, targetUserId: widget.moments.user.id);
    }
    ref.invalidate(userProvider);
    ref.invalidate(communityProvider);
  }
```

- [ ] **Step 6: Give the card its chrome**

Replace the card `Container`'s decoration (line ~611):

```dart
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: context.isDarkMode ? [] : AppShadows.sm,
        ),
```

and wrap its `Column` in `ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xl))` so
media does not paint over the rounded corners.

- [ ] **Step 7: Verify**

Run: `flutter test test/moments/ && flutter analyze lib/pages/moments/`
Expected: all PASS, analyzer clean.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/moments/card/ test/moments/moment_card_follow_test.dart
git commit -m "feat(moments): the card looks like a card, and you can follow from it"
```

---

### Task 5: Detail reaches parity with the card

**Files:**
- Modify: `lib/pages/moments/single/single_moment.dart:772-802` (action row)
- Test: `test/moments/single_moment_parity_test.dart`

**Interfaces:**
- Consumes: `buildMoment` (Task 1).
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/single/single_moment.dart';

import '../support/moment_fixture.dart';

void main() {
  testWidgets('detail offers save and translate, like the card does',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SingleMoment(moment: buildMoment(description: 'Hello there')),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('detail-save')), findsOneWidget);
    expect(find.byKey(const Key('detail-translate')), findsOneWidget);
  });
}
```

If `SingleMoment`'s constructor differs, run
`grep -n "class SingleMoment" -A 12 lib/pages/moments/single/single_moment.dart`
and match it exactly.

- [ ] **Step 2: Run the test and watch it fail**

Run: `flutter test test/moments/single_moment_parity_test.dart`
Expected: FAIL — neither key is found; detail has only like, comment and share.

- [ ] **Step 3: Add save to the action row**

In the action `Row` (currently after the `Spacer()` and before the share `IconButton`), add
a bookmark button mirroring the card's `_toggleSave` semantics:

```dart
                        IconButton(
                          key: const Key('detail-save'),
                          icon: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 20,
                            color: _isSaved ? AppColors.primary : context.iconColor,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: _toggleSave,
                        ),
```

Copy `_isSaved` and `_toggleSave` from `moment_card.dart` (`grep -n "_toggleSave" -A 25
lib/pages/moments/card/moment_card.dart`) rather than writing a new one — the save
semantics must not fork between the two screens.

- [ ] **Step 4: Add the translate chip under the full caption**

Directly below the caption `Text`, add the same chip-then-panel pair the card uses:

```dart
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: !_showTranslation
                        ? MomentTranslateChip(
                            key: const Key('detail-translate'),
                            onTap: () => setState(() => _showTranslation = true),
                          )
                        : TranslatedMomentWidget(
                            key: const Key('detail-translate'),
                            momentId: widget.moment.id,
                            originalText: widget.moment.description,
                            originalLanguage: widget.moment.language,
                            existingTranslations:
                                widget.moment.translations.isNotEmpty
                                    ? widget.moment.translations
                                    : null,
                            onDismiss: () =>
                                setState(() => _showTranslation = false),
                          ),
                  ),
```

Add `bool _showTranslation = false;` to the state class and the two imports.

- [ ] **Step 5: Add the liker avatar row**

Between the action row and the `Container(height: 8, ...)` divider:

```dart
                  if (likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(
                        children: [
                          // Up to five faces; the count is the real affordance.
                          for (final url in _likerAvatarUrls.take(5))
                            Align(
                              widthFactor: 0.72,
                              child: CachedCircleAvatar(
                                imageUrl: url,
                                radius: 10,
                                backgroundColor: context.containerColor,
                              ),
                            ),
                          const Spacer(),
                          Text(
                            '$likeCount ${AppLocalizations.of(context)!.likes}',
                            style: context.captionSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.textSecondary,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 16, color: context.textMuted),
                        ],
                      ),
                    ),
```

If the moment payload carries no liker avatars, render the count row without faces rather
than fetching per-liker profiles — an extra request per detail open is not worth five
thumbnails. Confirm with:
`grep -n "likes\|likedBy" lib/providers/provider_models/moments_model.dart`

- [ ] **Step 6: Run the test and watch it pass**

Run: `flutter test test/moments/single_moment_parity_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/moments/single/single_moment.dart \
        test/moments/single_moment_parity_test.dart
git commit -m "feat(moments): detail can do what the card that links to it can"
```

---

### Task 6: Final verification

- [ ] **Step 1: Full suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: every test passes; "No issues found."

- [ ] **Step 2: Confirm nothing shipped yesterday regressed**

Run: `flutter test test/moments/`
Expected: the carousel, story-link and sticker tests added in 2.4.0 still pass —
`story_link_test.dart`, `story_sticker_parsing_test.dart`, `moment_card_media_test.dart`.

- [ ] **Step 3: See it on a device**

Run: `flutter run`, open Moments, and check by hand: counts appear once; a long caption
with an emoji truncates cleanly and "show more" expands it; the Follow pill works and both
cards by one author agree after tapping it; detail offers save and translate.
