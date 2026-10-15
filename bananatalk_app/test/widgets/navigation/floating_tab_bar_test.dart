import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

const _tabColors = [
  Color(0xFF8B5CF6),
  Color(0xFF00BFA5),
  Color(0xFF667EEA),
  Color(0xFFFF6B6B),
  Color(0xFFF59E0B),
];

void main() {
  group('BarScrollState', () {
    test('hides after 24 px down, not before', () {
      final s = BarScrollState();
      s.onScroll(delta: 20, atTop: false, atEnd: false);
      expect(s.visible, isTrue);
      s.onScroll(delta: 5, atTop: false, atEnd: false);
      expect(s.visible, isFalse);
    });
    test('any upward scroll shows', () {
      final s = BarScrollState()
        ..onScroll(delta: 40, atTop: false, atEnd: false);
      s.onScroll(delta: -1, atTop: false, atEnd: false);
      expect(s.visible, isTrue);
    });
    test('top or end shows', () {
      final s = BarScrollState()
        ..onScroll(delta: 40, atTop: false, atEnd: false);
      s.onScroll(delta: 3, atTop: false, atEnd: true);
      expect(s.visible, isTrue);
      s.onScroll(delta: 40, atTop: false, atEnd: false);
      s.onScroll(delta: 0, atTop: true, atEnd: false);
      expect(s.visible, isTrue);
    });
    test('upward scroll resets the accumulator', () {
      final s = BarScrollState()
        ..onScroll(delta: 20, atTop: false, atEnd: false)
        ..onScroll(delta: -2, atTop: false, atEnd: false)
        ..onScroll(delta: 20, atTop: false, atEnd: false);
      expect(s.visible, isTrue);
    });
    test('reset shows', () {
      final s = BarScrollState()
        ..onScroll(delta: 40, atTop: false, atEnd: false);
      s.reset();
      expect(s.visible, isTrue);
    });
  });

  group('tabLabelColor (spec §8.1: label >= 4.5:1 on its capsule)', () {
    for (final dark in [false, true]) {
      for (final c in _tabColors) {
        test('${dark ? 'dark' : 'light'} $c', () {
          final pill = dark ? const Color(0xFF1C1C2E) : Colors.white;
          final fill = Color.alphaBlend(
            c.withValues(alpha: tabCapsuleAlpha(dark: dark)),
            pill,
          );
          expect(
            _contrast(tabLabelColor(c, dark: dark), fill),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  });

  Widget bar({
    int selected = 0,
    bool visible = true,
    ValueChanged<int>? onSelect,
    String firstLabel = 'AI Study',
    int badgeCount = 0,
    int otherBadges = 0,
  }) => MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          FloatingTabBar(
            selected: selected,
            visible: visible,
            onSelect: onSelect ?? (_) {},
            items: [
              FloatingTabItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: firstLabel,
                color: const Color(0xFF8B5CF6),
                badgeCount: otherBadges,
              ),
              FloatingTabItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Community',
                color: const Color(0xFF00BFA5),
                badgeCount: badgeCount,
              ),
              FloatingTabItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chats',
                color: const Color(0xFF667EEA),
                badgeCount: otherBadges,
              ),
              FloatingTabItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'Moments',
                color: const Color(0xFFFF6B6B),
                badgeCount: otherBadges,
              ),
              FloatingTabItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                color: const Color(0xFFF59E0B),
                badgeCount: otherBadges,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  testWidgets('screen readers hear the unread count', (t) async {
    await t.pumpWidget(bar(badgeCount: 7));
    expect(find.bySemanticsLabel('Community, 7'), findsOneWidget);
    expect(find.bySemanticsLabel('AI Study'), findsOneWidget);
  });

  testWidgets('a slid-away bar leaves no screen-reader stops', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(bar(visible: false));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('Community'), findsNothing);
    expect(find.bySemanticsLabel('AI Study'), findsNothing);
    handle.dispose();
  });

  testWidgets('active tab draws its name, inactive does not', (t) async {
    await t.pumpWidget(bar());
    expect(find.text('AI Study'), findsOneWidget);
    expect(find.text('Community'), findsNothing);
    expect(find.bySemanticsLabel('Community'), findsOneWidget);
  });

  testWidgets('every item exposes its selected state to semantics', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(bar());
    expect(
      t.getSemantics(find.bySemanticsLabel('AI Study')),
      matchesSemantics(
        label: 'AI Study',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      t.getSemantics(find.bySemanticsLabel('Profile')),
      matchesSemantics(
        label: 'Profile',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('tapping an item reports its index', (t) async {
    int? tapped;
    await t.pumpWidget(bar(onSelect: (i) => tapped = i));
    await t.tap(find.byIcon(Icons.auto_awesome_outlined));
    expect(tapped, 3);
  });

  testWidgets('badge sits on the icon when inactive, after the name when '
      'active', (t) async {
    await t.pumpWidget(bar(badgeCount: 120));
    expect(find.text('99+'), findsOneWidget);
    final inactive = t.getRect(find.text('99+'));
    final icon = t.getRect(find.byIcon(Icons.explore_outlined));
    expect(inactive.overlaps(icon), isTrue);

    await t.pumpWidget(bar(badgeCount: 3, selected: 1));
    await t.pumpAndSettle();
    final label = t.getRect(find.text('Community'));
    expect(t.getRect(find.text('3')).left, greaterThanOrEqualTo(label.right));
    // Badge text is never below 12 px.
    expect(
      t.widget<Text>(find.text('3')).style!.fontSize,
      greaterThanOrEqualTo(12),
    );
  });

  testWidgets('hidden bar slides off screen', (t) async {
    await t.pumpWidget(bar(visible: false));
    await t.pumpAndSettle();
    final rect = t.getRect(find.byType(FloatingTabBar));
    expect(
      rect.top,
      greaterThanOrEqualTo(
        t.view.physicalSize.height / t.view.devicePixelRatio,
      ),
    );
  });

  testWidgets('hidden bar ignores taps', (t) async {
    var taps = 0;
    await t.pumpWidget(bar(visible: false, onSelect: (_) => taps++));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.explore_outlined).hitTestable(), findsNothing);
    expect(taps, 0);
  });

  testWidgets('keyboard open hides the bar', (t) async {
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.resetViewInsets);
    await t.pumpWidget(bar());
    await t.pumpAndSettle();
    expect(find.text('AI Study').hitTestable(), findsNothing);
  });

  testWidgets('keyboard closing brings the bar back', (t) async {
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.resetViewInsets);
    await t.pumpWidget(bar());
    await t.pumpAndSettle();
    t.view.resetViewInsets();
    await t.pumpAndSettle();
    expect(find.text('AI Study').hitTestable(), findsOneWidget);
  });

  testWidgets('no overflow at 320 wide, text scale 1.3, long label', (t) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);

    await t.pumpWidget(
      bar(
        firstLabel: 'Sprachlernen mit künstlicher Intelligenz',
        badgeCount: 0,
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final pill = t.getRect(find.byKey(FloatingTabBar.pillKey));
    expect(pill.left, greaterThanOrEqualTo(0));
    expect(pill.right, lessThanOrEqualTo(320));
  });

  for (var tab = 0; tab < 5; tab++) {
    testWidgets('no overflow at 320 wide, text scale 1.3, tab $tab active '
        'with a 99+ badge on every tab', (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);

      await t.pumpWidget(bar(selected: tab, badgeCount: 120, otherBadges: 120));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      // The count is never lost: every tab still shows it somewhere.
      expect(find.text('99+'), findsNWidgets(5));
      final pill = t.getRect(find.byKey(FloatingTabBar.pillKey));
      // 8 px side margin.
      expect(pill.left, greaterThanOrEqualTo(8));
      expect(pill.right, lessThanOrEqualTo(312));
      // Items touch, so each keeps its 48 px hit target.
      final items = find.descendant(
        of: find.byKey(FloatingTabBar.pillKey),
        matching: find.byType(GestureDetector),
      );
      expect(items, findsNWidgets(5));
      for (final e in items.evaluate()) {
        expect(t.getSize(find.byWidget(e.widget)).width, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('no overflow at 360 wide, text scale 1.3, Community active '
      'with a badge, and the name still shows', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);

    await t.pumpWidget(bar(selected: 1, badgeCount: 120, otherBadges: 120));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Community'), findsOneWidget);
  });

  testWidgets('the pill hugs its tabs on a wide screen', (t) async {
    await t.pumpWidget(bar());
    await t.pumpAndSettle();
    final pill = t.getRect(find.byKey(FloatingTabBar.pillKey));
    final screen = t.view.physicalSize.width / t.view.devicePixelRatio;
    expect(pill.width, lessThan(screen / 2));
  });

  testWidgets('keyboard closing reports onKeyboardClosed once', (t) async {
    var closed = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingTabBar(
                selected: 0,
                visible: false,
                onSelect: (_) {},
                onKeyboardClosed: () => closed++,
                items: const [
                  FloatingTabItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: 'AI Study',
                    color: Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.resetViewInsets);
    await t.pump();
    expect(closed, 0);
    t.view.viewInsets = const FakeViewPadding(bottom: 120);
    await t.pump();
    expect(closed, 0);
    t.view.resetViewInsets();
    await t.pump();
    expect(closed, 1);
  });

  group('BarScrollState.onNotification with a real list', () {
    Widget harness({ValueNotifier<int>? rows}) {
      final state = BarScrollState();
      final rowCount = rows ?? ValueNotifier(100);
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: NotificationListener<Notification>(
              onNotification: (n) {
                if (state.onNotification(n)) setState(() {});
                return false;
              },
              child: Stack(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: rowCount,
                    builder: (context, count, _) => ListView(
                      children: [
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < 30; i++)
                                SizedBox(width: 80, child: Text('h$i')),
                            ],
                          ),
                        ),
                        for (var i = 0; i < count; i++)
                          SizedBox(height: 60, child: Text('row $i')),
                      ],
                    ),
                  ),
                  FloatingTabBar(
                    selected: 0,
                    visible: state.visible,
                    onSelect: (_) {},
                    onKeyboardClosed: () => setState(state.reset),
                    items: const [
                      FloatingTabItem(
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book_rounded,
                        label: 'AI Study',
                        color: Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scrolling down hides, scrolling up shows', (t) async {
      await t.pumpWidget(harness());
      await t.drag(find.text('row 3'), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(find.text('AI Study').hitTestable(), findsNothing);

      await t.drag(find.text('row 8'), const Offset(0, 40));
      await t.pumpAndSettle();
      expect(find.text('AI Study').hitTestable(), findsOneWidget);
    });

    testWidgets('horizontal scrolling never hides the bar', (t) async {
      await t.pumpWidget(harness());
      await t.drag(find.text('h1'), const Offset(-400, 0));
      await t.pumpAndSettle();
      expect(find.text('AI Study').hitTestable(), findsOneWidget);
    });

    Future<void> hideByScrolling(WidgetTester t) async {
      await t.drag(find.text('row 3'), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(find.text('AI Study').hitTestable(), findsNothing);
    }

    testWidgets('keyboard closing restores a bar hidden by scrolling', (
      t,
    ) async {
      await t.pumpWidget(harness());
      await hideByScrolling(t);

      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(t.view.resetViewInsets);
      await t.pumpAndSettle();
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      expect(find.text('AI Study').hitTestable(), findsOneWidget);
    });

    testWidgets('content shrinking to fit the viewport restores the bar', (
      t,
    ) async {
      final rows = ValueNotifier(100);
      await t.pumpWidget(harness(rows: rows));
      await hideByScrolling(t);

      rows.value = 2; // e.g. short search results
      await t.pumpAndSettle();
      expect(find.text('AI Study').hitTestable(), findsOneWidget);
    });
  });

  for (final inset in [0.0, 34.0, 48.0]) {
    testWidgets('fabLift puts a Scaffold FAB on clearance (inset $inset)', (
      t,
    ) async {
      late double clearance;
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              padding: EdgeInsets.only(bottom: inset),
              viewPadding: EdgeInsets.only(bottom: inset),
            ),
            child: Builder(
              builder: (context) {
                clearance = FloatingTabBar.clearance(context);
                return Scaffold(
                  floatingActionButton: Padding(
                    padding: EdgeInsets.only(
                      bottom: FloatingTabBar.fabLift(context),
                    ),
                    child: FloatingActionButton(
                      onPressed: () {},
                      child: const Icon(Icons.add),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      final screenBottom = t.getBottomLeft(find.byType(Scaffold)).dy;
      final fabBottom = t.getBottomLeft(find.byType(FloatingActionButton)).dy;
      expect(screenBottom - fabBottom, moreOrLessEquals(clearance));
    });
  }
}
