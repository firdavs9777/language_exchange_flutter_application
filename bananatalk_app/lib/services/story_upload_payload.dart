import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Task-metadata key holding a failed story task's [StoryUploadFailure] name.
const String kStoryFailureKey = 'storyFailure';

/// Why a story task is `failed`. A stable code the UI localises; the queue
/// has no BuildContext.
enum StoryUploadFailure {
  /// The daily story limit (429). No automatic retry.
  limitReached,

  /// The queue's private copy of the media is gone. No retry can help.
  fileMissing,

  /// Anything else, after the automatic retries ran out.
  failed,
}

/// Everything a story can be posted with, as the composer hands it over.
///
/// Stored flat in [UploadTask.metadata] (the queue persists that map as
/// JSON), with the same keys today's five-field story task used —
/// `mediaPath`, `isVideo`, `text`, `backgroundColor`, `privacy` — so a task
/// persisted by an older release restores as a payload. [fromJson] never
/// throws: a missing, unknown or malformed field restores as its default.
///
/// Stickers, poll, location, link and mentions are stored through their
/// constructors' fields, not their server-read parsers, so the restored
/// object sends exactly what the original would have. The question box is
/// the exception: it is restored with `StoryQuestionBox.fromJson` from its
/// own `toJson()` (prompt and responses), which round-trips what is sent.
class StoryUploadPayload {
  const StoryUploadPayload({
    this.mediaPath,
    this.isVideo = false,
    this.text,
    this.backgroundColor,
    this.textColor,
    this.fontStyle,
    this.privacy = StoryPrivacy.everyone,
    this.overlays,
    this.poll,
    this.questionBox,
    this.correctionSticker,
    this.quizSticker,
    this.wordSticker,
    this.hashtags,
    this.location,
    this.link,
    this.mentions,
    this.allowReplies = true,
    this.allowSharing = true,
    this.ownerUserId,
  });

  /// The media file; null (or empty) for a text-only story.
  final String? mediaPath;
  final bool isVideo;
  final String? text;
  final String? backgroundColor;
  final String? textColor;
  final String? fontStyle;
  final StoryPrivacy privacy;
  final List<Map<String, dynamic>>? overlays;
  final StoryPoll? poll;
  final StoryQuestionBox? questionBox;
  final StoryCorrectionSticker? correctionSticker;
  final StoryQuizSticker? quizSticker;
  final StoryWordSticker? wordSticker;
  final List<String>? hashtags;
  final StoryLocation? location;
  final StoryLink? link;
  final List<StoryMention>? mentions;
  final bool allowReplies;
  final bool allowSharing;

  /// The signed-in user who queued it; the queue never uploads it as anyone
  /// else. Null only on tasks persisted before this field existed.
  final String? ownerUserId;

  bool get isTextStory => mediaPath == null || mediaPath!.isEmpty;

  StoryUploadPayload copyWith({String? mediaPath, String? ownerUserId}) {
    return StoryUploadPayload(
      mediaPath: mediaPath ?? this.mediaPath,
      isVideo: isVideo,
      text: text,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontStyle: fontStyle,
      privacy: privacy,
      overlays: overlays,
      poll: poll,
      questionBox: questionBox,
      correctionSticker: correctionSticker,
      quizSticker: quizSticker,
      wordSticker: wordSticker,
      hashtags: hashtags,
      location: location,
      link: link,
      mentions: mentions,
      allowReplies: allowReplies,
      allowSharing: allowSharing,
      ownerUserId: ownerUserId ?? this.ownerUserId,
    );
  }

  Map<String, dynamic> toJson() => {
        'mediaPath': mediaPath,
        'isVideo': isVideo,
        'text': text,
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'fontStyle': fontStyle,
        'privacy': privacy.name,
        'overlays': overlays,
        'poll': poll?.toJson(),
        'questionBox': questionBox?.toJson(),
        'correctionSticker': correctionSticker == null
            ? null
            : {
                'sentence': correctionSticker!.sentence,
                'language': correctionSticker!.language,
                'x': correctionSticker!.x,
                'y': correctionSticker!.y,
              },
        'quizSticker': quizSticker == null
            ? null
            : {
                'question': quizSticker!.question,
                'options': quizSticker!.options.map((o) => o.text).toList(),
                'correctIndex': quizSticker!.correctIndex,
              },
        'wordSticker': wordSticker == null
            ? null
            : {
                'word': wordSticker!.word,
                'meaning': wordSticker!.meaning,
                'example': wordSticker!.example,
                'language': wordSticker!.language,
                'x': wordSticker!.x,
                'y': wordSticker!.y,
              },
        'hashtags': hashtags,
        'location': location == null
            ? null
            : {
                'name': location!.name,
                'address': location!.address,
                'latitude': location!.latitude,
                'longitude': location!.longitude,
                'placeId': location!.placeId,
              },
        'link': link == null
            ? null
            : {
                'url': link!.url,
                'title': link!.title,
                'displayText': link!.displayText,
              },
        'mentions': mentions
            ?.map((m) => {
                  'userId': m.userId,
                  'username': m.username,
                  'x': m.x,
                  'y': m.y,
                })
            .toList(),
        'allowReplies': allowReplies,
        'allowSharing': allowSharing,
        'ownerUserId': ownerUserId,
      };

  factory StoryUploadPayload.fromJson(Map<String, dynamic> json) {
    final privacyName = json['privacy'];
    return StoryUploadPayload(
      mediaPath: _str(json['mediaPath']),
      isVideo: json['isVideo'] == true,
      text: _str(json['text']),
      backgroundColor: _str(json['backgroundColor']),
      textColor: _str(json['textColor']),
      fontStyle: _str(json['fontStyle']),
      privacy: StoryPrivacy.values.firstWhere(
        (p) => p.name == privacyName,
        orElse: () => StoryPrivacy.everyone,
      ),
      overlays: _guard(() => _overlays(json['overlays'])),
      poll: _guard(() => _poll(json['poll'])),
      questionBox: _guard(() => _questionBox(json['questionBox'])),
      correctionSticker: _guard(() => _correction(json['correctionSticker'])),
      quizSticker: _guard(() => _quiz(json['quizSticker'])),
      wordSticker: _guard(() => _word(json['wordSticker'])),
      hashtags: _guard(() => _strings(json['hashtags'])),
      location: _guard(() => _location(json['location'])),
      link: _guard(() => _link(json['link'])),
      mentions: _guard(() => _mentions(json['mentions'])),
      allowReplies: json['allowReplies'] != false,
      allowSharing: json['allowSharing'] != false,
      ownerUserId: _str(json['ownerUserId']),
    );
  }
}

/// Story-specific views of a queued [UploadTask].
extension StoryUploadTaskInfo on UploadTask {
  bool get isStory =>
      type == UploadType.story || type == UploadType.storyVideo;

  /// The payload this story task posts; meaningless for other tasks.
  StoryUploadPayload get storyPayload => StoryUploadPayload.fromJson(metadata);

  /// Why this story task failed; null while it is not failed (or not a
  /// story). An unknown stored code reads as [StoryUploadFailure.failed].
  StoryUploadFailure? get storyFailure {
    if (!isStory) return null;
    final code = metadata[kStoryFailureKey];
    if (code == null) return null;
    return StoryUploadFailure.values.firstWhere(
      (f) => f.name == code,
      orElse: () => StoryUploadFailure.failed,
    );
  }
}

T? _guard<T>(T? Function() read) {
  try {
    return read();
  } catch (_) {
    return null;
  }
}

String? _str(Object? v) => v is String ? v : null;

double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<String>? _strings(Object? v) =>
    v is List ? v.whereType<String>().toList() : null;

List<Map<String, dynamic>>? _overlays(Object? v) {
  if (v is! List) return null;
  return v.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

StoryPoll? _poll(Object? v) {
  final m = _map(v);
  final question = _str(m?['question']);
  final options = m?['options'];
  if (m == null || question == null || options is! List) return null;
  final parsed = <StoryPollOption>[];
  for (var i = 0; i < options.length; i++) {
    final o = _map(options[i]);
    final text = _str(o?['text']);
    if (o == null || text == null) continue;
    parsed.add(StoryPollOption(
      index: o['index'] is int ? o['index'] as int : i,
      text: text,
      voteCount: o['voteCount'] is int ? o['voteCount'] as int : 0,
    ));
  }
  final expires = _str(m['expiresAt']);
  return StoryPoll(
    question: question,
    options: parsed,
    isAnonymous: m['isAnonymous'] == true,
    expiresAt: expires == null ? null : DateTime.tryParse(expires),
  );
}

StoryQuestionBox? _questionBox(Object? v) {
  final m = _map(v);
  if (m == null || _str(m['prompt']) == null) return null;
  return StoryQuestionBox.fromJson(m);
}

StoryCorrectionSticker? _correction(Object? v) {
  final m = _map(v);
  final sentence = _str(m?['sentence']);
  if (m == null || sentence == null) return null;
  return StoryCorrectionSticker(
    sentence: sentence,
    language: _str(m['language']),
    x: _num(m['x']) ?? 0.5,
    y: _num(m['y']) ?? 0.5,
  );
}

StoryQuizSticker? _quiz(Object? v) {
  final m = _map(v);
  final question = _str(m?['question']);
  final options = m?['options'];
  if (m == null || question == null || options is! List) return null;
  final texts = options.whereType<String>().toList();
  if (texts.length != options.length) return null;
  final correct = m['correctIndex'];
  return StoryQuizSticker(
    question: question,
    options: [
      for (var i = 0; i < texts.length; i++)
        StoryQuizOption(index: i, text: texts[i]),
    ],
    correctIndex: correct is int ? correct : null,
  );
}

StoryWordSticker? _word(Object? v) {
  final m = _map(v);
  final word = _str(m?['word']);
  final meaning = _str(m?['meaning']);
  if (m == null || word == null || meaning == null) return null;
  return StoryWordSticker(
    word: word,
    meaning: meaning,
    example: _str(m['example']),
    language: _str(m['language']),
    x: _num(m['x']) ?? 0.5,
    y: _num(m['y']) ?? 0.5,
  );
}

StoryLocation? _location(Object? v) {
  final m = _map(v);
  final name = _str(m?['name']);
  if (m == null || name == null) return null;
  return StoryLocation(
    name: name,
    address: _str(m['address']),
    latitude: _num(m['latitude']),
    longitude: _num(m['longitude']),
    placeId: _str(m['placeId']),
  );
}

StoryLink? _link(Object? v) {
  final m = _map(v);
  final url = _str(m?['url']);
  if (m == null || url == null) return null;
  return StoryLink(
    url: url,
    title: _str(m['title']),
    displayText: _str(m['displayText']) ?? 'Learn More',
  );
}

List<StoryMention>? _mentions(Object? v) {
  if (v is! List) return null;
  final out = <StoryMention>[];
  for (final item in v) {
    final m = _map(item);
    final userId = _str(m?['userId']);
    if (m == null || userId == null) continue;
    out.add(StoryMention(
      userId: userId,
      username: _str(m['username']) ?? '',
      x: _num(m['x']) ?? 50,
      y: _num(m['y']) ?? 50,
    ));
  }
  return out;
}
