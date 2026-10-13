import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter/services.dart';

/// [text] cut to at most [maxUnits] UTF-16 code units (what JS `.length`
/// and Dart `String.length` count), never inside a grapheme cluster, so an
/// emoji or a flag is kept whole or dropped whole.
String truncateUtf16(String text, int maxUnits) {
  if (text.length <= maxUnits) return text;
  final out = StringBuffer();
  var units = 0;
  for (final g in text.characters) {
    if (units + g.length > maxUnits) break;
    out.write(g);
    units += g.length;
  }
  return out.toString();
}

/// Like [LengthLimitingTextInputFormatter], but counts UTF-16 code units
/// instead of grapheme clusters, matching a server that checks JS `.length`.
class Utf16LengthLimitingTextInputFormatter extends TextInputFormatter {
  const Utf16LengthLimitingTextInputFormatter(this.maxUnits);

  final int maxUnits;

  /// While an IME is composing (Korean, Japanese, Chinese input) the text is
  /// left alone: cutting into a composition breaks it. The limit applies as
  /// soon as the composition is committed (the send path clamps too).
  /// Otherwise the text is cut on a grapheme boundary and the selection
  /// stays where it was, clamped to the new length.
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length <= maxUnits) return newValue;
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) return newValue;
    final text = truncateUtf16(newValue.text, maxUnits);
    int clamp(int offset) => offset < 0 ? offset : (offset > text.length ? text.length : offset);
    final sel = newValue.selection;
    return TextEditingValue(
      text: text,
      selection: sel.isValid
          ? sel.copyWith(baseOffset: clamp(sel.baseOffset), extentOffset: clamp(sel.extentOffset))
          : TextSelection.collapsed(offset: text.length),
    );
  }
}
