import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Chip labels rendered invisibly: AppTypography.labelMedium carries no colour
/// of its own, and the dark theme had no chipTheme at all, so the label took
/// whatever tone surrounded it — which on a chip is the chip's own background.
void main() {
  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    final name = entry.key;
    final theme = entry.value;

    group('$name chip theme', () {
      test('exists at all', () {
        // The dark theme simply did not define one.
        expect(theme.chipTheme.backgroundColor, isNotNull,
            reason: '$name has no chip background');
      });

      test('GLOBAL CONSTRAINT: the label has an explicit colour', () {
        expect(theme.chipTheme.labelStyle?.color, isNotNull,
            reason: 'an uncoloured label inherits, and inherits wrong');
      });

      test('the selected label has an explicit colour too', () {
        expect(theme.chipTheme.secondaryLabelStyle?.color, isNotNull);
      });

      test('the label is not the same colour as the chip behind it', () {
        // The actual failure: same tone on same tone reads as missing.
        expect(
          theme.chipTheme.labelStyle!.color,
          isNot(equals(theme.chipTheme.backgroundColor)),
          reason: '$name renders an invisible chip label',
        );
      });

      test('the selected label differs from the selected background', () {
        expect(
          theme.chipTheme.secondaryLabelStyle!.color,
          isNot(equals(theme.chipTheme.selectedColor)),
          reason: '$name renders an invisible SELECTED chip label',
        );
      });
    });
  }

  testWidgets('a real chip paints a visible label in both themes',
      (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(child: Chip(label: Text('Conversation'))),
        ),
      ));
      await tester.pump();

      final label = tester.widget<Text>(find.text('Conversation'));
      final resolved = label.style?.color ??
          theme.chipTheme.labelStyle?.color ??
          theme.textTheme.labelMedium?.color;
      expect(resolved, isNotNull, reason: 'the label resolved to no colour');
      expect(resolved, isNot(equals(theme.chipTheme.backgroundColor)));
    }
  });
}
