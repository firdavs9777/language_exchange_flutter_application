import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

/// One row of hashtag suggestions or trending.
class HashtagCount {
  const HashtagCount({required this.tag, required this.postCount});

  final String tag;
  final int postCount;

  /// `null` for an item without a usable tag.
  static HashtagCount? tryParse(Object? json) {
    if (json is! Map) return null;
    final tag = json['tag'];
    if (tag is! String || tag.isEmpty) return null;
    final count = json['postCount'];
    return HashtagCount(tag: tag, postCount: count is num ? count.toInt() : 0);
  }
}

/// One page of `GET hashtags/:tag/moments`. [tag] is the server's normalised
/// tag (what the page should display).
class HashtagPage {
  const HashtagPage({
    required this.tag,
    required this.postCount,
    this.relatedTopic,
    required this.moments,
    required this.hasNextPage,
  });

  /// What a 404 (server switch off) looks like.
  const HashtagPage.empty(this.tag)
    : postCount = 0,
      relatedTopic = null,
      moments = const <Moments>[],
      hasNextPage = false;

  final String tag;
  final int postCount;
  final String? relatedTopic;
  final List<Moments> moments;
  final bool hasNextPage;
}

/// The page-level fields of a hashtag page, kept next to the paged moments.
class HashtagPageMeta {
  const HashtagPageMeta({
    required this.tag,
    required this.postCount,
    this.relatedTopic,
  });

  final String tag;
  final int postCount;
  final String? relatedTopic;
}
