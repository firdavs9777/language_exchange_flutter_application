import 'dart:io';

/// One English `Text('…')` / `SelectableText('…')` literal found in source.
class HardcodedText {
  HardcodedText(this.path, this.line, this.text);
  final String path;
  final int line;
  final String text;
  @override
  String toString() => '$path:$line  $text';
}

final _call = RegExp(r'(?<![\w.])(?:Text|SelectableText)\(\s*');
final _interp = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
final _escape = RegExp(r'\\.');
final _letters = RegExp(r'[A-Za-z]{2,}');

int _commentStart(String line) {
  var quote = '';
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (quote.isNotEmpty) {
      if (c == r'\') {
        i++;
      } else if (c == quote) {
        quote = '';
      }
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
    } else if (c == '/' && line[i + 1] == '/') {
      return i;
    }
  }
  return -1;
}

String _stripLineComments(String src) => src.split('\n').map((line) {
      final i = _commentStart(line);
      return i < 0 ? line : line.substring(0, i).padRight(line.length);
    }).join('\n');

/// A Dart string literal at [i] (optionally raw / triple-quoted), with
/// `${…}` (which may hold quotes of its own) kept verbatim.
(String, int)? _literal(String s, int i) {
  var raw = false;
  if (s[i] == 'r') {
    raw = true;
    i++;
  }
  if (i >= s.length) return null;
  final q = s[i];
  if (q != "'" && q != '"') return null;
  final triple = s.startsWith(q * 3, i);
  i += triple ? 3 : 1;
  final out = StringBuffer();
  while (i < s.length) {
    if (triple ? s.startsWith(q * 3, i) : s[i] == q) {
      return (out.toString(), i + (triple ? 3 : 1));
    }
    if (!triple && s[i] == '\n') return null;
    if (!raw && s[i] == r'\' && i + 1 < s.length) {
      out.write(s.substring(i, i + 2));
      i += 2;
      continue;
    }
    if (!raw && s.startsWith(r'${', i)) {
      var depth = 0;
      var j = i + 1;
      for (; j < s.length; j++) {
        final c = s[j];
        if (c == '{') {
          depth++;
        } else if (c == '}') {
          if (--depth == 0) break;
        } else if (c == "'" || c == '"') {
          final inner = _literal(s, j);
          if (inner == null) return null;
          j = inner.$2 - 1;
        }
      }
      out.write(s.substring(i, j + 1));
      i = j + 1;
      continue;
    }
    out.write(s[i]);
    i++;
  }
  return null;
}

/// English-bearing Text literals in [source]; adjacent literals are joined.
List<HardcodedText> scanSource(String path, String source) {
  final src = _stripLineComments(source);
  final hits = <HardcodedText>[];
  for (final m in _call.allMatches(src)) {
    var i = m.end;
    final parts = <String>[];
    while (true) {
      while (i < src.length && ' \t\r\n'.contains(src[i])) {
        i++;
      }
      if (i >= src.length) break;
      final lit = _literal(src, i);
      if (lit == null) break;
      parts.add(lit.$1);
      i = lit.$2;
    }
    if (parts.isEmpty) continue;
    final text = parts.join();
    final bare = text.replaceAll(_interp, '').replaceAll(_escape, '');
    if (_letters.hasMatch(bare)) {
      final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
      hits.add(HardcodedText(path, line, text));
    }
  }
  return hits;
}

List<HardcodedText> scanFiles(Iterable<String> paths) =>
    [for (final p in paths) ...scanSource(p, File(p).readAsStringSync())];
