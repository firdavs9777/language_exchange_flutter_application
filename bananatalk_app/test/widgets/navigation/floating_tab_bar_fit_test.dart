import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';

import '../../helpers/real_fonts.dart';

const _labels = ['AI Study', 'Community', 'Chats', 'Moments', 'Profile'];

Widget _bar(int selected) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Stack(children: [
          FloatingTabBar(
            selected: selected,
            visible: true,
            onSelect: (_) {},
            items: [
              for (final l in _labels)
                FloatingTabItem(
                  icon: Icons.circle_outlined,
                  activeIcon: Icons.circle,
                  label: l,
                  color: const Color(0xFF8B5CF6),
                ),
            ],
          ),
        ]),
      ),
    );

/// Spec §8.1: on a common 360-wide phone at default text size the active
/// tab's English name fits whole (measured with real Roboto, not the
/// square test font).
void main() {
  late bool fonts;
  setUpAll(() async => fonts = await loadRoboto());

  for (var i = 0; i < _labels.length; i++) {
    testWidgets('360 wide, scale 1.0: "${_labels[i]}" is not ellipsized', (t) async {
      if (!fonts) {
        markTestSkipped('Flutter SDK Roboto not found');
        return;
      }
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_bar(i));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final label = find.text(_labels[i]);
      expect(label, findsOneWidget, reason: 'the name was dropped');
      final p = t.renderObject<RenderParagraph>(label);
      expect(p.didExceedMaxLines, isFalse, reason: '"${_labels[i]}" was cut');
    });
  }
}
