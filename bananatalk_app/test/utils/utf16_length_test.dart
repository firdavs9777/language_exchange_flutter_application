import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/utf16_length.dart';

void main() {
  group('truncateUtf16', () {
    test('short text is unchanged', () {
      expect(truncateUtf16('hello', 200), 'hello');
    });

    test('counts UTF-16 code units like JS .length (emoji = 2, flag = 4)', () {
      final text = '${'a' * 197}😀😀';
      expect(text.length, 201);
      expect(truncateUtf16(text, 200), '${'a' * 197}😀');
    });

    test('never splits a flag or a surrogate pair', () {
      expect(truncateUtf16('ab🇺🇿', 5), 'ab');
      expect(truncateUtf16('ab😀', 3), 'ab');
      expect(truncateUtf16('ab🇺🇿', 6), 'ab🇺🇿');
    });
  });

  group('Utf16LengthLimitingTextInputFormatter', () {
    const f = Utf16LengthLimitingTextInputFormatter(4);

    TextEditingValue v(String t) => TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));

    test('allows text within the limit', () {
      expect(f.formatEditUpdate(v('ab'), v('abc')).text, 'abc');
    });

    test('truncates on a grapheme boundary within the unit limit', () {
      final out = f.formatEditUpdate(v('abc'), v('abc😀'));
      expect(out.text, 'abc');
      expect(out.selection.baseOffset, 3);
    });

    test('accepts an emoji that fits exactly', () {
      expect(f.formatEditUpdate(v('ab'), v('ab😀')).text, 'ab😀');
    });

    test('an edit in the middle keeps the cursor where it was, not at the end', () {
      const before = TextEditingValue(text: 'abcd', selection: TextSelection.collapsed(offset: 1));
      const after = TextEditingValue(text: 'aXbcd', selection: TextSelection.collapsed(offset: 2));
      final out = f.formatEditUpdate(before, after);
      expect(out.text, 'aXbc');
      expect(out.selection, const TextSelection.collapsed(offset: 2));
    });

    test('a selection past the new end is clamped to it', () {
      const after = TextEditingValue(text: 'abcde', selection: TextSelection(baseOffset: 3, extentOffset: 5));
      final out = f.formatEditUpdate(v('abcd'), after);
      expect(out.text, 'abcd');
      expect(out.selection, const TextSelection(baseOffset: 3, extentOffset: 4));
    });

    test('never truncates while the IME is composing (Korean/Japanese input)', () {
      const composing = TextEditingValue(
        text: 'abc한글',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 3, end: 5),
      );
      expect(f.formatEditUpdate(v('abc'), composing), composing);
    });

    test('truncates once the composition is committed', () {
      const committed = TextEditingValue(text: 'abc한글', selection: TextSelection.collapsed(offset: 5));
      final out = f.formatEditUpdate(v('abc'), committed);
      expect(out.text, 'abc한');
      expect(out.selection, const TextSelection.collapsed(offset: 4));
      expect(out.composing, TextRange.empty);
    });
  });
}
