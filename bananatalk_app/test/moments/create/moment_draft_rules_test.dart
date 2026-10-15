import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/create/moment_draft_rules.dart';

void main() {
  group('validateMomentDraft', () {
    final now = DateTime(2026, 9, 17, 12);

    String? validate({
      String description = 'hello',
      List<String> tags = const [],
      DateTime? scheduledDate,
      bool hasMedia = false,
      bool isReel = false,
      bool hasVideo = false,
    }) =>
        validateMomentDraft(
          description: description,
          tags: tags,
          scheduledDate: scheduledDate,
          now: now,
          hasMedia: hasMedia,
          isReel: isReel,
          hasVideo: hasVideo,
        );

    test('a normal draft is valid', () {
      expect(validate(), isNull);
    });

    test('an empty caption with no media is rejected', () {
      expect(validate(description: ''), isNotNull);
    });

    test('caption only is valid', () {
      expect(validate(description: 'hello', hasMedia: false), isNull);
    });

    test('BUG: media only (no caption) is valid -- "A photo or one line"', () {
      // The guide promised a photo alone was a moment and the Next button let
      // you through, but the Post step then refused with "Caption is required".
      expect(validate(description: '', hasMedia: true), isNull);
      expect(validate(description: '   ', hasMedia: true), isNull);
    });

    test('neither caption nor media is rejected', () {
      expect(validate(description: '  ', hasMedia: false), isNotNull);
    });

    test('media does not excuse the other rules', () {
      expect(
        validate(description: 'a' * (kMaxDescriptionLength + 1), hasMedia: true),
        isNotNull,
      );
      expect(
        validate(
          description: '',
          hasMedia: true,
          tags: List.generate(kMaxTags + 1, (i) => 't$i'),
        ),
        isNotNull,
      );
      expect(
        validate(
          description: '',
          hasMedia: true,
          scheduledDate: now.subtract(const Duration(minutes: 1)),
        ),
        isNotNull,
      );
    });

    test('a reel without a video is rejected, even with a caption', () {
      expect(validate(description: 'hello', isReel: true), isNotNull);
      expect(
        validate(description: 'hello', isReel: true, hasVideo: false),
        contains('video'),
      );
    });

    test('a reel with a video and no caption is valid', () {
      expect(
        validate(description: '', isReel: true, hasVideo: true, hasMedia: true),
        isNull,
      );
    });

    test('a whitespace-only caption is rejected', () {
      // The widget trims before checking; a caption of spaces is empty.
      expect(validate(description: '   \n  '), isNotNull);
    });

    test('exactly the limit is accepted, one over is not', () {
      expect(validate(description: 'a' * kMaxDescriptionLength), isNull);
      expect(validate(description: 'a' * (kMaxDescriptionLength + 1)), isNotNull);
    });

    test('the character limit counts the TRIMMED caption', () {
      // Trailing spaces should not push an otherwise-valid caption over.
      final atLimit = '${'a' * kMaxDescriptionLength}    ';
      expect(validate(description: atLimit), isNull);
    });

    test('five tags are fine, six are not', () {
      expect(validate(tags: List.generate(kMaxTags, (i) => 't$i')), isNull);
      expect(validate(tags: List.generate(kMaxTags + 1, (i) => 't$i')), isNotNull);
    });

    test('no schedule is fine', () {
      expect(validate(scheduledDate: null), isNull);
    });

    test('a future schedule is fine', () {
      expect(validate(scheduledDate: now.add(const Duration(hours: 1))), isNull);
    });

    test('a past schedule is rejected', () {
      expect(validate(scheduledDate: now.subtract(const Duration(minutes: 1))), isNotNull);
    });

    test('the caption is checked before the tags', () {
      // Order matters for which message the poster sees first; an empty
      // caption is the more basic problem.
      final message = validate(description: '', tags: List.generate(9, (i) => 't$i'));
      expect(message, contains('Caption'));
    });
  });

  group('draftHasContent', () {
    test('caption or media is content; neither is not', () {
      expect(draftHasContent(description: 'hi', hasMedia: false), isTrue);
      expect(draftHasContent(description: '', hasMedia: true), isTrue);
      expect(draftHasContent(description: ' \n ', hasMedia: false), isFalse);
    });
  });

  group('imagesAddable', () {
    test('an empty selection can take the full allowance', () {
      expect(imagesAddable(current: 0, adding: 4), 4);
    });

    test('adding more than fits is clamped to the free slots', () {
      expect(imagesAddable(current: 8, adding: 5), kMaxImages - 8);
    });

    test('a full selection can take none', () {
      expect(imagesAddable(current: kMaxImages, adding: 3), 0);
    });

    test('never returns a negative, even if current somehow exceeds the max', () {
      // Defensive: a clamp that can go negative would turn `take(n)` into a
      // RangeError rather than a no-op.
      expect(imagesAddable(current: kMaxImages + 4, adding: 2), 0);
    });

    test('adding nothing adds nothing', () {
      expect(imagesAddable(current: 2, adding: 0), 0);
    });
  });

  group('languageNameForCode', () {
    const languages = {'English': 'en', 'Korean': 'ko', 'Japanese': 'ja'};

    test('a known code resolves to its display name', () {
      expect(languageNameForCode('ko', languages), 'Korean');
    });

    test('an unknown code falls back to English', () {
      // This fallback is deliberate, not an accident: a moment must always
      // carry a language, and English is the safe default for this audience.
      expect(languageNameForCode('xx', languages), 'English');
    });

    test('an empty or null code falls back to English', () {
      expect(languageNameForCode('', languages), 'English');
      expect(languageNameForCode(null, languages), 'English');
    });

    test('an empty language map still yields English', () {
      expect(languageNameForCode('ko', const {}), 'English');
    });
  });
}
