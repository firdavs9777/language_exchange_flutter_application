import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/services/offers/offers_provider.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';
import 'package:bananatalk_app/widgets/navigation/tab_reselect_scroll_to_top.dart';

const _flow = PaywallFlow(
  placement: 'vip_entry',
  flowId: 'flow-1',
  offerId: 'offer-1',
  detail: 'moments_chip',
);

void main() {
  late List<String> shown;

  setUp(() {
    resetOfferProcessStateForTest();
    shown = [];
    paywallLogSpy = (flow, action, detail) {
      if (action == PaywallAction.shown) shown.add(flow.offerId ?? '');
    };
  });
  tearDown(() => paywallLogSpy = null);

  testWidgets(
    'a reporter in a tab that is not selected logs nothing until the tab is selected, then once',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TabReselectScrollToTop(
              tab: kMomentsTabIndex,
              child: OfferShownReporter(flow: _flow, child: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(container.read(selectedTabProvider), isNot(kMomentsTabIndex));
      expect(shown, isEmpty, reason: 'mounted in a hidden tab');

      container.read(selectedTabProvider.notifier).state = kMomentsTabIndex;
      await tester.pump();
      await tester.pump();
      expect(shown, ['offer-1']);

      container.read(selectedTabProvider.notifier).state = 0;
      await tester.pump();
      container.read(selectedTabProvider.notifier).state = kMomentsTabIndex;
      await tester.pump();
      await tester.pump();
      expect(shown, ['offer-1'], reason: 'once per offer id per process');
    },
  );

  testWidgets(
    'a reporter under a pushed route logs nothing until its route is current again',
    (tester) async {
      final show = ValueNotifier<bool>(false);
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorKey: navKey,
            home: ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (_, on, __) => on
                  ? const OfferShownReporter(flow: _flow, child: SizedBox())
                  : const SizedBox(),
            ),
          ),
        ),
      );
      navKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();

      show.value = true; // the surface appears under the pushed route
      await tester.pump();
      await tester.pump();
      expect(shown, isEmpty, reason: 'its route is covered');

      navKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(shown, ['offer-1']);
    },
  );

  testWidgets('a reporter with no owning tab on the current route logs once',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OfferShownReporter(flow: _flow, child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(shown, ['offer-1']);
  });
}
