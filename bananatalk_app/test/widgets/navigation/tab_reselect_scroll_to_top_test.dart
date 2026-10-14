import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';
import 'package:bananatalk_app/widgets/navigation/tab_reselect_scroll_to_top.dart';

/// A sub-tab page that stays alive while another sub-tab is shown, like
/// Community's partner lists.
class _Page extends StatefulWidget {
  const _Page(this.name);
  final String name;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      key: ValueKey('list-${widget.name}'),
      children: [
        SizedBox(
          height: 100,
          child: ListView(
            key: ValueKey('carousel-${widget.name}'),
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(width: 80, child: Text('${widget.name} h$i')),
            ],
          ),
        ),
        for (var i = 0; i < 100; i++)
          SizedBox(height: 60, child: Text('${widget.name} row $i')),
      ],
    );
  }
}

void main() {
  late ProviderContainer container;
  late TabController tabs;

  Future<void> pump(WidgetTester t) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TabReselectScrollToTop(
              tab: 1,
              child: DefaultTabController(
                length: 2,
                child: Builder(
                  builder: (context) {
                    tabs = DefaultTabController.of(context);
                    return const TabBarView(children: [_Page('a'), _Page('b')]);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ScrollPosition pos(WidgetTester t, String key) => t
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(ValueKey(key), skipOffstage: false),
              matching: find.byType(Scrollable, skipOffstage: false),
            )
            .first,
      )
      .position;

  void reselect(int tab) {
    final n = container.read(tabReselectProvider.notifier);
    n.state = (tab: tab, seq: n.state.seq + 1);
  }

  testWidgets('re-tapping this tab scrolls the visible list to the top', (
    t,
  ) async {
    await pump(t);
    // Small enough that the carousel stays built (inside the cache extent).
    pos(t, 'list-a').jumpTo(200);
    pos(t, 'carousel-a').jumpTo(200);
    await t.pump();

    reselect(1);
    await t.pumpAndSettle();
    expect(pos(t, 'list-a').pixels, 0);
    expect(
      pos(t, 'carousel-a').pixels,
      200,
      reason: 'horizontal carousels keep their place',
    );
  });

  testWidgets('another tab being re-tapped is ignored', (t) async {
    await pump(t);
    pos(t, 'list-a').jumpTo(500);
    await t.pump();

    reselect(2);
    await t.pumpAndSettle();
    expect(pos(t, 'list-a').pixels, 500);
  });

  testWidgets('a sub-tab kept alive off screen keeps its place', (t) async {
    await pump(t);
    pos(t, 'list-a').jumpTo(500);
    tabs.animateTo(1);
    await t.pumpAndSettle();
    pos(t, 'list-b').jumpTo(300);
    await t.pump();

    reselect(1);
    await t.pumpAndSettle();
    expect(pos(t, 'list-b').pixels, 0);
    expect(pos(t, 'list-a').pixels, 500);
  });
}
