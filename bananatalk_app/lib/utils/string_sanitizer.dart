/// Strips lone UTF-16 surrogates (U+D800–U+DFFF) that crash Flutter's
/// text engine. Call on any user-supplied string before passing to Text().
String sanitize(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString();
  if (s.isEmpty) return fallback;
  return s.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '');
}
