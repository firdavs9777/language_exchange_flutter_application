import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'package:bananatalk_app/utils/image_utils.dart';

/// Preloads story images. Injectable so widget tests record the URLs instead
/// of touching the network.
typedef StoryPrecacher = Future<void> Function(
  BuildContext context,
  List<String> urls,
);

/// Loads each URL through the same provider and cache manager
/// `CachedImageWidget` uses (and its URL normalisation), so the bytes are on
/// disk when the ring or the viewer asks for them. Failures are ignored.
Future<void> precacheStoryImages(BuildContext context, List<String> urls) async {
  for (final url in urls) {
    if (!context.mounted) return;
    try {
      await precacheImage(
        CachedNetworkImageProvider(
          ImageUtils.normalizeImageUrl(url),
          cacheManager: AppImageCacheManager.instance,
        ),
        context,
        onError: (_, __) {},
      );
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
