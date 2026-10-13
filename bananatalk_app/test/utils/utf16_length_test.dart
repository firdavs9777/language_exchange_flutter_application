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
  });
}
