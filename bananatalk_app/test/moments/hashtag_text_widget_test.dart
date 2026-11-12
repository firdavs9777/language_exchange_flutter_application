import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/widgets/hashtag_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/moment_fixture.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _app(Widget child, {GoRouter? router}) {
  if (router != null) return MaterialApp.router(routerConfig: router);
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('links off: one plain Text, same style, lines and overflow', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 17);
    await tester.pumpWidget(
      _app(
        const HashtagText(
          text: 'learn #korean today',
          style: style,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          linksEnabled: false,
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'learn #korean today');
    expect(text.textSpan, isNull);
    expect(text.style, style);
    expect(text.maxLines, 4);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('links on: hashtag spans are tappable, plain spans are not', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HashtagText(text: 'a #korean b', linksEnabled: true)),
    );
    final root = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    final spans = root.children!.cast<TextSpan>();
    expect(spans.map((s) => s.text), ['a ', '#korean', ' b']);
    expect(spans[0].recognizer, isNull);
    expect(spans[1].recognizer, isA<TapGestureRecognizer>());
    expect(spans[2].recognizer, isNull);
    expect(
      spans[1].style?.color,
      Theme.of(tester.element(find.byType(Text))).colorScheme.primary,
    );
  });

  testWidgets('a tap on #한국어 pushes the encoded hashtag route', (tester) async {
    String? pushed;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: HashtagText(text: '#한국어', linksEnabled: true),
          ),
        ),
        GoRoute(
          path: '/hashtag/:tag',
          builder: (_, state) {
            pushed = state.uri.path;
            return const Scaffold(body: Text('page'));
          },
        ),
      ],
    );
    await tester.pumpWidget(_app(const SizedBox(), router: router));
    await tester.pumpAndSettle();
    final root = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    final tap =
        (root.children!.single as TextSpan).recognizer! as TapGestureRecognizer;
    tap.onTap!();
    await tester.pumpAndSettle();
    expect(pushed, '/hashtag/%ED%95%9C%EA%B5%AD%EC%96%B4');
  });

  testWidgets('links on with no hashtag in the text: still one Text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HashtagText(text: 'no tags here', linksEnabled: true)),
    );
    expect(find.text('no tags here'), findsOneWidget);
  });

  Widget cardHost({required bool flag, required String caption}) =>
      ProviderScope(
        overrides: [hashtagsEnabledProvider.overrideWithValue(flag)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MomentCard(moments: buildMoment(description: caption)),
            ),
          ),
        ),
      );

  testWidgets('feed card caption: plain with the flag off', (tester) async {
    await tester.pumpWidget(cardHost(flag: false, caption: 'hi #korean'));
    await tester.pump(const Duration(milliseconds: 300));
    final caption = tester.widget<Text>(find.text('hi #korean'));
    expect(caption.textSpan, isNull);
    expect(caption.maxLines, 4);
  });

  testWidgets('feed card caption: tappable hashtags with the flag on', (
    tester,
  ) async {
    await tester.pumpWidget(cardHost(flag: true, caption: 'hi #korean'));
    await tester.pump(const Duration(milliseconds: 300));
    final rich = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.textSpan?.toPlainText() == 'hi #korean')
        .single;
    expect(rich.maxLines, 4);
    final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.last.recognizer, isA<TapGestureRecognizer>());
  });

  /// Pumps a card captioned "hi #korean" (links on) and taps the middle of
  /// characters [from]..[to] of the caption with a real pointer. Returns the
  /// hashtag routes opened; [detailFetches] counts the card's detail opens.
  Future<List<String>> tapCaption(
    WidgetTester tester, {
    required int from,
    required int to,
    required List<String> detailFetches,
  }) async {
    final opened = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: SingleChildScrollView(
              child: MomentCard(
                moments: buildMoment(description: 'hi #korean'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/hashtag/:tag',
          builder: (_, state) {
            opened.add(state.uri.path);
            return const Scaffold(body: Text('hashtag page'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hashtagsEnabledProvider.overrideWithValue(true),
          momentsServiceProvider.overrideWithValue(
            _CountingMomentsService(detailFetches),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final caption = find.byWidgetPredicate(
      (w) => w is Text && w.textSpan?.toPlainText() == 'hi #korean',
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: caption, matching: find.byType(RichText)).first,
    );
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: from, extentOffset: to),
    );
    await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('tapping a hashtag in a card opens the hashtag, not the detail', (
    tester,
  ) async {
    final fetches = <String>[];
    // "#korean" is characters 3..10 of "hi #korean".
    final opened = await tapCaption(
      tester,
      from: 3,
      to: 10,
      detailFetches: fetches,
    );
    expect(opened, ['/hashtag/korean']);
    expect(find.text('hashtag page'), findsOneWidget);
    expect(fetches, isEmpty);
  });

  testWidgets('a tap on the caption outside a hashtag opens the detail', (
    tester,
  ) async {
    final fetches = <String>[];
    // "hi" is characters 0..2.
    final opened = await tapCaption(
      tester,
      from: 0,
      to: 2,
      detailFetches: fetches,
    );
    expect(opened, isEmpty);
    expect(fetches, ['m1']);
  });
}

class _CountingMomentsService extends MomentsService {
  _CountingMomentsService(this.fetches);

  final List<String> fetches;

  @override
  Future<Moments> getSingleMoment({required String id}) async {
    fetches.add(id);
    throw Exception('offline');
  }
}
