import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/story_upload_payload.dart';

/// A queued story is persisted as JSON and may be restored after an app
/// restart: what reaches the server from the restored payload must be what
/// the composer handed over, field for field.
void main() {
  StoryUploadPayload full() => StoryUploadPayload(
        mediaPath: '/docs/story_uploads/abc.mp4',
        isVideo: true,
        text: '  caption with spaces  ',
        backgroundColor: '#112233',
        textColor: '#FFEEDD',
        fontStyle: 'bold',
        privacy: StoryPrivacy.closeFriends,
        overlays: [
          {'type': 'text', 'content': 'hi', 'x': 0.2, 'y': 0.3},
        ],
        poll: StoryPoll(
          question: 'Tea or coffee?',
          options: const [
            StoryPollOption(index: 0, text: 'Tea'),
            StoryPollOption(index: 1, text: 'Coffee'),
          ],
          isAnonymous: true,
          expiresAt: DateTime.utc(2026, 11, 14, 9),
        ),
        questionBox: const StoryQuestionBox(prompt: 'Ask me'),
        correctionSticker: const StoryCorrectionSticker(
            sentence: ' I goed home ', language: 'en', x: 0.25, y: 0.75),
        quizSticker: const StoryQuizSticker(
          question: 'Which is right?',
          options: [
            StoryQuizOption(index: 0, text: 'A'),
            StoryQuizOption(index: 1, text: 'B'),
            StoryQuizOption(index: 2, text: 'C'),
          ],
          correctIndex: 2,
        ),
        wordSticker: const StoryWordSticker(
            word: '사과',
            meaning: 'apple',
            example: '사과를 먹어요',
            language: 'ko',
            x: 0.1,
            y: 0.9),
        hashtags: const ['korean', 'study'],
        location: const StoryLocation(
            name: 'Seoul',
            address: 'Jung-gu',
            latitude: 37.5,
            longitude: 127.0,
            placeId: 'p1'),
        link: const StoryLink(
            url: 'https://example.com', title: 'Ex', displayText: 'Open'),
        mentions: const [
          StoryMention(userId: 'u9', username: 'kim', x: 30, y: 40),
        ],
        allowReplies: false,
        allowSharing: false,
        ownerUserId: 'u1',
      );

  /// Through a real JSON string, as SharedPreferences stores it.
  StoryUploadPayload roundTrip(StoryUploadPayload p) =>
      StoryUploadPayload.fromJson(
          jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);

  test('every field survives a JSON round trip with the same wire form', () {
    final a = full();
    final b = roundTrip(a);

    expect(b.mediaPath, a.mediaPath);
    expect(b.isVideo, isTrue);
    expect(b.isTextStory, isFalse);
    expect(b.text, a.text, reason: 'text is never trimmed by the queue');
    expect(b.backgroundColor, a.backgroundColor);
    expect(b.textColor, a.textColor);
    expect(b.fontStyle, a.fontStyle);
    expect(b.privacy, StoryPrivacy.closeFriends);
    expect(b.overlays, a.overlays);
    expect(b.poll!.toJson(), a.poll!.toJson());
    expect(b.questionBox!.toJson(), a.questionBox!.toJson());
    expect(b.correctionSticker!.toCreateJson(),
        a.correctionSticker!.toCreateJson());
    expect(b.quizSticker!.toCreateJson(), a.quizSticker!.toCreateJson());
    expect(b.quizSticker!.toCreateJson()['correctIndex'], isA<int>());
    expect(b.wordSticker!.toCreateJson(), a.wordSticker!.toCreateJson());
    expect(b.hashtags, a.hashtags);
    expect(b.location!.toJson(), a.location!.toJson());
    expect(b.link!.toJson(), a.link!.toJson());
    expect(b.mentions!.single.toJson(), a.mentions!.single.toJson());
    expect(b.allowReplies, isFalse);
    expect(b.allowSharing, isFalse);
    expect(b.ownerUserId, 'u1');
    // And the whole thing is stable.
    expect(jsonEncode(b.toJson()), jsonEncode(a.toJson()));
  });

  test('a text-only story has no media path and round-trips', () {
    const a = StoryUploadPayload(
      text: 'hello',
      backgroundColor: 'sunset',
      fontStyle: 'normal',
      overlays: [
        {'type': 'text', 'content': 'hello'},
      ],
      wordSticker: StoryWordSticker(word: 'w', meaning: 'm'),
      ownerUserId: 'u1',
    );
    final b = roundTrip(a);
    expect(b.mediaPath, isNull);
    expect(b.isTextStory, isTrue);
    expect(b.isVideo, isFalse);
    expect(b.text, 'hello');
    expect(b.wordSticker!.toCreateJson(), {
      'word': 'w',
      'meaning': 'm',
      'x': 0.5,
      'y': 0.5,
    });
    expect(b.poll, isNull);
    expect(b.allowReplies, isTrue);
    expect(b.allowSharing, isTrue);
  });

  test("today's five-field story metadata restores with defaults", () {
    final b = StoryUploadPayload.fromJson({
      'mediaPath': '/tmp/x.jpg',
      'isVideo': false,
      'text': 'cap',
      'backgroundColor': '#000000',
      'privacy': 'friends',
    });
    expect(b.mediaPath, '/tmp/x.jpg');
    expect(b.text, 'cap');
    expect(b.backgroundColor, '#000000');
    expect(b.privacy, StoryPrivacy.friends);
    expect(b.allowReplies, isTrue);
    expect(b.allowSharing, isTrue);
    expect(b.ownerUserId, isNull);
    expect(b.overlays, isNull);
    expect(b.textColor, isNull);
  });

  test('missing, unknown and malformed fields never throw', () {
    expect(() => StoryUploadPayload.fromJson(const {}), returnsNormally);
    final b = StoryUploadPayload.fromJson({
      'mediaPath': 42,
      'isVideo': 'yes',
      'privacy': 'galaxy',
      'overlays': 'nope',
      'poll': 'x',
      'questionBox': [1],
      'correctionSticker': {'sentence': 5},
      'quizSticker': {'question': 'q', 'options': 'a,b'},
      'wordSticker': {'word': 'w'},
      'hashtags': [1, 'ok'],
      'location': {'name': 3, 'latitude': 'n'},
      'link': 7,
      'mentions': [
        'bad',
        {'userId': 'u2', 'username': 'lee', 'x': 1, 'y': 2},
      ],
      'allowReplies': 'false',
      'someFutureField': {'a': 1},
    });
    expect(b.mediaPath, isNull);
    expect(b.isVideo, isFalse);
    expect(b.privacy, StoryPrivacy.everyone);
    expect(b.overlays, isNull);
    expect(b.poll, isNull);
    expect(b.questionBox, isNull);
    expect(b.correctionSticker, isNull);
    expect(b.quizSticker, isNull);
    expect(b.wordSticker, isNull);
    expect(b.hashtags, ['ok']);
    expect(b.link, isNull);
    expect(b.mentions!.single.userId, 'u2');
    expect(b.allowReplies, isTrue);
  });

  test('a story task exposes its failure code; other tasks have none', () {
    final story = UploadTask(
      type: UploadType.story,
      localFilePath: '',
      metadata: {kStoryFailureKey: 'limitReached'},
    );
    expect(story.isStory, isTrue);
    expect(story.storyFailure, StoryUploadFailure.limitReached);

    final unknown = UploadTask(
      type: UploadType.storyVideo,
      localFilePath: '',
      metadata: {kStoryFailureKey: 'somethingNew'},
    );
    expect(unknown.storyFailure, StoryUploadFailure.failed);

    final moment =
        UploadTask(type: UploadType.moment, localFilePath: '', metadata: {});
    expect(moment.isStory, isFalse);
    expect(moment.storyFailure, isNull);
  });
}
