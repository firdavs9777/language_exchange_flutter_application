/// Hashtag text helpers. The server normalises tags itself (it also folds
/// accents); the app only cleans what the user typed, for display and for
/// building URLs.
library;

/// Longest tag the server keeps, in code points.
const int kHashtagMaxLength = 30;

final RegExp _baseChar = RegExp(r'[\p{L}\p{N}_]', unicode: true);

// Combining marks (Thai vowels and tone marks, Hangul/Indic signs, ...), but
// not the emoji variation selectors, which are marks too: `❤️` must not
// leave a stray U+FE0F behind. Enclosing marks (keycap) are left out too.
final RegExp _joiningMark = RegExp(r'[\p{Mn}\p{Mc}]', unicode: true);

bool _isVariationSelector(int rune) =>
    (rune >= 0xFE00 && rune <= 0xFE0F) || (rune >= 0xE0100 && rune <= 0xE01EF);

/// What the user typed as a tag: no leading `#`, lower case, no whitespace,
/// only letters, digits, combining marks and `_`, at most 30 code points;
/// `null` when nothing is left. A combining mark is kept only when it
/// attaches to a kept character.
String? normalizeHashtag(String raw) {
  final out = StringBuffer();
  var count = 0;
  var lastKept = false;
  for (final rune in raw.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final keep =
        _baseChar.hasMatch(ch) ||
        (lastKept && !_isVariationSelector(rune) && _joiningMark.hasMatch(ch));
    lastKept = keep;
    if (!keep) continue;
    if (count == kHashtagMaxLength) break;
    out.write(ch);
    count += 1;
  }
  return count == 0 ? null : out.toString();
}

/// A piece of a text: plain, or a hashtag (`text` includes the `#`, `tag` is
/// the word after it, as written).
class HashtagSpan {
  const HashtagSpan.plain(this.text) : tag = null;
  const HashtagSpan.hashtag(this.text, String this.tag);

  final String text;
  final String? tag;

  bool get isHashtag => tag != null;

  @override
  String toString() =>
      isHashtag ? 'HashtagSpan.hashtag($text)' : 'HashtagSpan.plain($text)';
}

// `#` + a letter/digit/underscore, then more of those and combining marks;
// not right after a letter, digit, mark, `_` or `/` (so `a#b` and URL
// fragments are not tags).
final RegExp _hashtagPattern = RegExp(
  r'(?<![\p{L}\p{N}\p{M}_/])#([\p{L}\p{N}_](?:[\p{L}\p{N}_]|(?![︀-️])[\p{Mn}\p{Mc}])*)',
  unicode: true,
);

/// [text] cut into plain and hashtag spans, in order; joining the spans'
/// `text` gives [text] back.
List<HashtagSpan> splitHashtags(String text) {
  final spans = <HashtagSpan>[];
  var cursor = 0;
  for (final m in _hashtagPattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(HashtagSpan.plain(text.substring(cursor, m.start)));
    }
    spans.add(HashtagSpan.hashtag(m.group(0)!, m.group(1)!));
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(HashtagSpan.plain(text.substring(cursor)));
  }
  return spans;
}
