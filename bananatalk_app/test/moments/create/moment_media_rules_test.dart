import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/create/moment_media_rules.dart';

void main() {
  group('currentMediaKind', () {
    test('nothing selected is none', () {
      expect(
        currentMediaKind(imageCount: 0, hasVideo: false, hasAudio: false),
        MomentMediaKind.none,
      );
    });

    test('images, video and audio each report themselves', () {
      expect(currentMediaKind(imageCount: 2, hasVideo: false, hasAudio: false),
          MomentMediaKind.images);
      expect(currentMediaKind(imageCount: 0, hasVideo: true, hasAudio: false),
          MomentMediaKind.video);
      expect(currentMediaKind(imageCount: 0, hasVideo: false, hasAudio: true),
          MomentMediaKind.audio);
    });

    test('video wins if state is somehow inconsistent', () {
      // Should be unreachable, but a derived value must still be total: a
      // draft holding both should report the heavier medium rather than throw.
      expect(currentMediaKind(imageCount: 3, hasVideo: true, hasAudio: true),
          MomentMediaKind.video);
    });
  });

  group('blockerFor', () {
    MomentMediaBlock? block({
      required MomentMediaKind wanted,
      int images = 0,
      bool video = false,
      bool audio = false,
    }) =>
        blockerFor(
          wanted: wanted,
          imageCount: images,
          hasVideo: video,
          hasAudio: audio,
        );

    test('an empty draft accepts anything', () {
      for (final kind in MomentMediaKind.values) {
        expect(block(wanted: kind), isNull, reason: '$kind should be allowed');
      }
    });

    test('more of the same kind is always allowed', () {
      expect(block(wanted: MomentMediaKind.images, images: 3), isNull);
    });

    test('images block video, in both directions', () {
      expect(block(wanted: MomentMediaKind.video, images: 1)?.present,
          MomentMediaKind.images);
      expect(block(wanted: MomentMediaKind.images, video: true)?.present,
          MomentMediaKind.video);
    });

    test('GLOBAL CONSTRAINT: audio blocks images from EVERY source', () {
      // The bug this pins: _pickImages checked for audio and _takePhoto did
      // not, so the same action was refused from the gallery and allowed from
      // the camera.
      expect(block(wanted: MomentMediaKind.images, audio: true), isNotNull);
    });

    test('images and video both block audio', () {
      expect(block(wanted: MomentMediaKind.audio, images: 1), isNotNull);
      expect(block(wanted: MomentMediaKind.audio, video: true), isNotNull);
    });

    test('audio blocks video', () {
      expect(block(wanted: MomentMediaKind.video, audio: true)?.present,
          MomentMediaKind.audio);
    });

    test('the block names both halves, so the message can be specific', () {
      final b = block(wanted: MomentMediaKind.images, audio: true)!;
      expect(b.present, MomentMediaKind.audio);
      expect(b.wanted, MomentMediaKind.images);
    });

    test('every pair of different kinds is refused', () {
      // Exhaustive rather than a sample: the whole point is that no
      // combination slips through because one picker forgot to check.
      final kinds = [
        MomentMediaKind.images,
        MomentMediaKind.video,
        MomentMediaKind.audio,
      ];
      for (final present in kinds) {
        for (final wanted in kinds) {
          final result = blockerFor(
            wanted: wanted,
            imageCount: present == MomentMediaKind.images ? 1 : 0,
            hasVideo: present == MomentMediaKind.video,
            hasAudio: present == MomentMediaKind.audio,
          );
          if (present == wanted) {
            expect(result, isNull, reason: '$present + $wanted');
          } else {
            expect(result, isNotNull, reason: '$present should block $wanted');
          }
        }
      }
    });
  });

  group('maxVideoSeconds', () {
    test('a reel caps at three minutes', () {
      expect(maxVideoSeconds(isReel: true), 180);
    });

    test('a video moment keeps the ten-minute cap', () {
      expect(maxVideoSeconds(isReel: false), 600);
    });
  });

  group('momentImageProblem', () {
    test('a normal jpeg/png/gif/webp under the limit is fine', () {
      for (final ext in ['jpg', 'jpeg', 'JPG', 'png', 'gif', 'webp']) {
        expect(momentImageProblem(path: '/x/a.$ext', sizeBytes: 1024), isNull,
            reason: ext);
      }
    });

    test('exactly the limit is fine, one byte over is not', () {
      expect(momentImageProblem(path: 'a.jpg', sizeBytes: kMaxMomentImageBytes),
          isNull);
      expect(
          momentImageProblem(
              path: 'a.jpg', sizeBytes: kMaxMomentImageBytes + 1),
          contains('10MB'));
    });

    test('HEIC (Android gallery) is refused before anything is created', () {
      expect(momentImageProblem(path: '/x/IMG_1.heic', sizeBytes: 10),
          isNotNull);
      expect(momentImageProblem(path: '/x/IMG_1.HEIF', sizeBytes: 10),
          isNotNull);
    });

    test('firstMomentImageProblem reports the first bad file, null if none',
        () {
      expect(
        firstMomentImageProblem(
            [('a.jpg', 10), ('b.png', 20)]),
        isNull,
      );
      expect(
        firstMomentImageProblem(
            [('a.jpg', 10), ('b.heic', 20), ('c.jpg', kMaxMomentImageBytes * 2)]),
        contains('heic'),
      );
    });
  });
}
