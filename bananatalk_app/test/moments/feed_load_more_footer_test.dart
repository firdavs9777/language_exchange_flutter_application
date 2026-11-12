import 'dart:async';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_feed_widget.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart'
    show MomentsFeedTab;
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/moment_fixture.dart';

Widget _feed({
  required bool hasMore,
  bool loadMoreFailed = false,
  VoidCallback? onRetry,
}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MomentsFeedWidget(
          momentsAsync: AsyncValue<List<Moments>>.data(
            [buildMoment(id: 'a', description: '')],
          ),
          isSearching: false,
          onRefresh: () {},
          activeTab: MomentsFeedTab.forYou,
          hasMore: hasMore,
          loadMoreFailed: loadMoreFailed,
          onRetryLoadMore: onRetry,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hasMore shows the spinner', (tester) async {
    await tester.pumpWidget(_feed(hasMore: true));
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('feed-load-more')),
      300,
    );
    expect(find.byKey(const ValueKey('feed-load-more')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-load-more-failed')), findsNothing);
  });

  testWidgets('a failed page shows the Retry row; tapping retries',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _feed(hasMore: true, loadMoreFailed: true, onRetry: () => retries++),
    );
    await tester.pump(const Duration(seconds: 1));
    final row = find.byKey(const ValueKey('feed-load-more-failed'));
    await tester.scrollUntilVisible(row, 300);
    expect(find.byKey(const ValueKey('feed-load-more')), findsNothing);
    final l10n = AppLocalizations.of(tester.element(row))!;
    expect(find.text(l10n.feedCouldNotLoadMore), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, l10n.retry));
    expect(retries, 1);
  });

  testWidgets('no footer at the end of the feed', (tester) async {
    await tester.pumpWidget(_feed(hasMore: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('feed-load-more')), findsNothing);
    expect(find.byKey(const ValueKey('feed-load-more-failed')), findsNothing);
  });

  testWidgets('Retry shows a spinner in place of the button while it runs',
      (tester) async {
    final done = Completer<void>();
    await tester.pumpWidget(
      _feed(hasMore: true, loadMoreFailed: true, onRetry: () => done.future),
    );
    await tester.pump(const Duration(seconds: 1));
    final row = find.byKey(const ValueKey('feed-load-more-failed'));
    await tester.scrollUntilVisible(row, 300);
    final l10n = AppLocalizations.of(tester.element(row))!;
    await tester.tap(find.widgetWithText(TextButton, l10n.retry));
    await tester.pump();
    expect(find.widgetWithText(TextButton, l10n.retry), findsNothing);
    expect(
      find.descendant(of: row, matching: find.byType(CircularProgressIndicator)),
      findsOneWidget,
    );
    // A second tap cannot start a second retry (no button).
    done.complete();
    await tester.pump();
    expect(find.widgetWithText(TextButton, l10n.retry), findsOneWidget);
  });
}
