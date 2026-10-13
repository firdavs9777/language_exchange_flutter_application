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

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length <= maxUnits) return newValue;
    final text = truncateUtf16(newValue.text, maxUnits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
