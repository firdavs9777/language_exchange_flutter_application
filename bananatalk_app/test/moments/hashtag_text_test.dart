import 'package:bananatalk_app/utils/hashtag_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeHashtag', () {
    final table = <String, String?>{
      '#Food': 'food',
      'food': 'food',
      '##Food': 'food',
      '#한국어': '한국어',
      '#日本語': '日本語',
      '#food🍜': 'food',
      '#food🍜️': 'food',
      '🍜': null,
      '❤️': null,
      '': null,
      '#': null,
      '#café': 'café',
      '# my tag': 'mytag',
      '#snake_case': 'snake_case',
      '#ไทย': 'ไทย',
      '#ที่': 'ที่',
      '#العربية': 'العربية',
      '#a-b!c': 'abc',
    };
    table.forEach((raw, expected) {
      test('"$raw" -> $expected', () {
        expect(normalizeHashtag(raw), expected);
      });
    });

    test('Thai combining marks survive', () {
      expect(normalizeHashtag('#กรุงเทพ้'), 'กรุงเทพ้');
    });

    test('40 chars are cut to 30', () {
      expect(normalizeHashtag('#${'a' * 40}'), 'a' * 30);
    });

    test('cut is by code point, not UTF-16 unit', () {
      final raw = '#${'𠮷' * 40}';
      expect(normalizeHashtag(raw)!.runes.length, 30);
    });
  });

  group('splitHashtags', () {
    test('finds only real hashtags', () {
      final spans = splitHashtags(
        'I love #한국어 and #Seoul2026, see site.com/#x',
      );
      final tags = spans.where((s) => s.isHashtag).map((s) => s.tag).toList();
      expect(tags, ['한국어', 'Seoul2026']);
    });

    test('spans reassemble the original text', () {
      const text = 'a #b c #d_e. #f';
      expect(splitHashtags(text).map((s) => s.text).join(), text);
    });

    test('hashtag span text keeps the leading #', () {
      final s = splitHashtags('x #ab').last;
      expect(s.isHashtag, isTrue);
      expect(s.text, '#ab');
      expect(s.tag, 'ab');
    });

    test('not preceded by letter, digit or underscore', () {
      expect(splitHashtags('a#b 1#c _#d').any((s) => s.isHashtag), isFalse);
    });

    test('lone # and empty text', () {
      expect(splitHashtags('# alone').any((s) => s.isHashtag), isFalse);
      expect(splitHashtags(''), isEmpty);
    });

    test('hashtag at start and after newline', () {
      final tags = splitHashtags(
        '#one\n#two',
      ).where((s) => s.isHashtag).map((s) => s.tag).toList();
      expect(tags, ['one', 'two']);
    });
  });
}
