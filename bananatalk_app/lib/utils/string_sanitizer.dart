/// Strips lone UTF-16 surrogates (U+D800–U+DFFF) that crash Flutter's
/// text engine. Call on any user-supplied string before passing to Text().
String sanitize(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString();
  if (s.isEmpty) return fallback;
  final units = s.codeUnits;
  // Fast path: skip processing if no surrogates present
  bool hasSurrogate = false;
  for (final u in units) {
    if (u >= 0xD800 && u <= 0xDFFF) {
      hasSurrogate = true;
      break;
    }
  }
  if (!hasSurrogate) return s;
  // Remove lone surrogates; preserve valid surrogate pairs (emoji etc.)
  final clean = <int>[];
  for (int i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      // High surrogate — keep only if followed by a low surrogate
      if (i + 1 < units.length && units[i + 1] >= 0xDC00 && units[i + 1] <= 0xDFFF) {
        clean.add(u);
        clean.add(units[i + 1]);
        i++;
      }
      // else: lone high surrogate — drop it
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      // Lone low surrogate — drop it
    } else {
      clean.add(u);
    }
  }
  return String.fromCharCodes(clean);
}
