import 'package:connectivity_plus/connectivity_plus.dart';

/// Most reels we will ever fetch ahead of the one being watched.
const int kReelMaxPrefetchDepth = 3;

/// Whether [status] describes a connection whose bytes are effectively free
/// to spend — i.e. **unmetered**.
///
/// This is the one place the word "unmetered" is defined: Wi-Fi or Ethernet.
/// Everything else — cellular, an unrecognised transport, no connection at
/// all — is treated as metered, because under-fetching is the cheaper
/// mistake than spending a user's data allowance on reels they may never
/// watch.
///
/// connectivity_plus v7 reports a *list* of active transports, so a device on
/// both Wi-Fi and cellular resolves to the unmetered path.
///
/// Callers that want "may I download video the user didn't ask for?" should
/// ask this rather than re-deriving it from [reelPrefetchDepth]'s numeric
/// result (`> 1` was previously open-coded at two call sites, with the
/// meaning of the comparison living nowhere).
bool reelConnectionUnmetered(List<ConnectivityResult> status) {
  return status.any((r) =>
      r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
}

/// How many upcoming reels to download ahead of the current one.
///
/// Unmetered connections buy latency hiding cheaply; on mobile data the same
/// aggressiveness would spend a user's allowance on reels they may never
/// watch. An unrecognised transport is treated as metered — under-fetching is
/// the cheaper mistake.
int reelPrefetchDepth(List<ConnectivityResult> status) {
  if (status.isEmpty || status.every((r) => r == ConnectivityResult.none)) {
    return 0;
  }
  return reelConnectionUnmetered(status) ? kReelMaxPrefetchDepth : 1;
}
