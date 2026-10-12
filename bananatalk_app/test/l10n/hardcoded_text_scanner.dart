import 'dart:io';

/// Scope: English string literals anywhere in the FIRST argument of a
/// `Text(` / `SelectableText(` call (plain, ternary, `??`, parenthesised).
/// Index keys such as `m['error']` are ignored.
/// Out of scope: `TextSpan(text:)`, `hintText`, `labelText`, `tooltip`,
/// `title:` and other named-parameter strings.
///
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

/// Extent of the first argument starting at [i]: up to the first top-level
/// `,` or the closing `)` of the call. Returns the end index (exclusive).
int _firstArgEnd(String s, int i) {
  var depth = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      final lit = _literal(s, i);
      if (lit == null) return s.length;
      i = lit.$2;
      continue;
    }
    if (c == 'r' && i + 1 < s.length && (s[i + 1] == "'" || s[i + 1] == '"') &&
        (i == 0 || !RegExp(r'\w').hasMatch(s[i - 1]))) {
      final lit = _literal(s, i);
      if (lit != null) {
        i = lit.$2;
        continue;
      }
    }
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return i;
      depth--;
    } else if (c == ',' && depth == 0) {
      return i;
    }
    i++;
  }
  return s.length;
}

/// True when the literal spanning [start]..[end] is a lookup key, `m['k']`.
bool _isIndexKey(String s, int start, int end) {
  var b = start - 1;
  while (b >= 0 && ' \t\r\n'.contains(s[b])) {
    b--;
  }
  var a = end;
  while (a < s.length && ' \t\r\n'.contains(s[a])) {
    a++;
  }
  return b >= 0 && a < s.length && s[b] == '[' && s[a] == ']';
}

/// English-bearing Text literals in [source]; adjacent literals are joined.
List<HardcodedText> scanSource(String path, String source) {
  final src = _stripLineComments(source);
  final hits = <HardcodedText>[];
  for (final m in _call.allMatches(src)) {
    final end = _firstArgEnd(src, m.end);
    final arg = src.substring(m.end, end);
    // Collect every string literal in the argument (nested calls included).
    final parts = <String>[];
    var i = 0;
    while (i < arg.length) {
      final c = arg[i];
      final rawStart = c == 'r' &&
          i + 1 < arg.length &&
          (arg[i + 1] == "'" || arg[i + 1] == '"') &&
          (i == 0 || !RegExp(r'\w').hasMatch(arg[i - 1]));
      if (c == "'" || c == '"' || rawStart) {
        final lit = _literal(arg, i);
        if (lit == null) break;
        if (!_isIndexKey(arg, i, lit.$2)) parts.add(lit.$1);
        i = lit.$2;
      } else {
        i++;
      }
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
