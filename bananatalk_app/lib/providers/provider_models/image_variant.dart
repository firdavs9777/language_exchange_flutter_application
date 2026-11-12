/// A smaller rendition of one image, sent by the server next to `imageUrls`
/// when thumbnails are on. `url` equals an entry of the item's `imageUrls`.
///
/// Parsing is defensive: a missing or malformed list is empty, and an entry
/// without both `url` and `feedUrl` is skipped, so the feed draws the full
/// image exactly as it did before variants existed.
class ImageVariant {
  const ImageVariant({
    required this.url,
    required this.feedUrl,
    this.placeholder,
    this.width,
    this.height,
  });

  final String url;
  final String feedUrl;

  /// A tiny `data:image/jpeg;base64,…` blur-up image.
  final String? placeholder;
  final int? width;
  final int? height;

  /// `width / height` when both are positive, else `null`.
  double? get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  static ImageVariant? _tryParse(dynamic json) {
    if (json is! Map) return null;
    final url = json['url'];
    final feedUrl = json['feedUrl'];
    if (url is! String || url.isEmpty) return null;
    if (feedUrl is! String || feedUrl.isEmpty) return null;
    final placeholder = json['placeholder'];
    final width = json['width'];
    final height = json['height'];
    return ImageVariant(
      url: url,
      feedUrl: feedUrl,
      placeholder:
          placeholder is String && placeholder.isNotEmpty ? placeholder : null,
      width: width is num ? width.toInt() : null,
      height: height is num ? height.toInt() : null,
    );
  }

  /// `[]` for anything that is not a list; unusable entries are dropped.
  static List<ImageVariant> listFromJson(dynamic json) {
    if (json is! List) return const <ImageVariant>[];
    final out = <ImageVariant>[];
    for (final entry in json) {
      final v = _tryParse(entry);
      if (v != null) out.add(v);
    }
    return out;
  }

  /// The variant whose `url` is [imageUrl], or `null`.
  static ImageVariant? find(List<ImageVariant> variants, String imageUrl) {
    for (final v in variants) {
      if (v.url == imageUrl) return v;
    }
    return null;
  }
}
