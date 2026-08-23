import 'package:connectivity_plus/connectivity_plus.dart';

/// Most reels we will ever fetch ahead of the one being watched.
const int kReelMaxPrefetchDepth = 3;

/// How many upcoming reels to download ahead of the current one.
///
/// Unmetered connections buy latency hiding cheaply; on mobile data the same
/// aggressiveness would spend a user's allowance on reels they may never
/// watch. An unrecognised transport is treated as metered — under-fetching is
/// the cheaper mistake.
///
/// connectivity_plus v7 reports a *list* of active transports, so a device on
/// both Wi-Fi and cellular resolves to the unmetered path.
int reelPrefetchDepth(List<ConnectivityResult> status) {
  if (status.isEmpty || status.every((r) => r == ConnectivityResult.none)) {
    return 0;
  }
  final unmetered = status.any((r) =>
      r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
  return unmetered ? kReelMaxPrefetchDepth : 1;
}
