import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'package:bananatalk_app/utils/image_utils.dart';

/// Preloads story images. Injectable so widget tests record the URLs instead
/// of touching the network.
typedef StoryPrecacher = Future<void> Function(
  BuildContext context,
  List<String> urls,
);

/// Puts one URL's bytes in the disk cache. Injectable for tests.
typedef StoryImageWarmer = Future<void> Function(String url);

/// Downloads [url] into the cache manager `CachedImageWidget` uses, under
/// the same key the widget reads the original from (the URL itself). No
/// decode: the widget's 800 px disk copy (`resized_w800_h800_<url>`) is
/// derived from these bytes, without a network request, when the story is
/// first drawn.
Future<void> warmImageOnDisk(String url) async {
  await AppImageCacheManager.instance.getSingleFile(url);
}

/// Warms the disk cache for each URL (normalised the way `CachedImageWidget`
/// normalises it), one after another. Nothing is decoded into memory.
/// Failures are ignored.
Future<void> precacheStoryImages(
  BuildContext context,
  List<String> urls, {
  StoryImageWarmer warm = warmImageOnDisk,
}) async {
  for (final url in urls) {
    if (!context.mounted) return;
    final normalized = ImageUtils.normalizeImageUrl(url);
    if (normalized.isEmpty) continue;
    try {
      await warm(normalized);
    } catch (_) {}
  }
}

/// True on mobile data without Wi-Fi/Ethernet; false when unknown.
Future<bool> isOnMobileData() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return r.contains(ConnectivityResult.mobile) &&
        !r.contains(ConnectivityResult.wifi) &&
        !r.contains(ConnectivityResult.ethernet);
  } catch (_) {
    return false;
  }
}

/// True on Wi-Fi or Ethernet; false on mobile data, offline or unknown.
Future<bool> isOnUnmeteredNetwork() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
  } catch (_) {
    return false;
  }
}
