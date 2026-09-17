/// Which media a moment may hold at once, and why.
///
/// Extracted from create_moment.dart — 2,629 lines with no test over its media
/// pipeline. These rules were six separate `if` guards scattered across the
/// picking methods, each with its own message, and nothing checked they agreed
/// with one another. A rewrite would break them silently: the failure is a
/// combination that should have been refused being quietly accepted, which
/// only surfaces when the server rejects the post.
library;

/// The kinds of media a moment can carry. Mutually exclusive by design.
enum MomentMediaKind { none, images, video, audio }

/// What the draft currently holds.
///
/// Derived rather than stored, so it can never disagree with the actual
/// selection — the bug a separate `_mediaType` field invites.
MomentMediaKind currentMediaKind({
  required int imageCount,
  required bool hasVideo,
  required bool hasAudio,
}) {
  if (hasVideo) return MomentMediaKind.video;
  if (hasAudio) return MomentMediaKind.audio;
  if (imageCount > 0) return MomentMediaKind.images;
  return MomentMediaKind.none;
}

/// Why [wanted] cannot be added right now, or null when it can.
///
/// One function rather than a guard per picker. The three pickers previously
/// each decided for themselves, which is how `_pickImages` came to check for
/// audio while `_takePhoto` did not — the same action allowed from the camera
/// and refused from the gallery.
MomentMediaBlock? blockerFor({
  required MomentMediaKind wanted,
  required int imageCount,
  required bool hasVideo,
  required bool hasAudio,
}) {
  final current = currentMediaKind(
    imageCount: imageCount,
    hasVideo: hasVideo,
    hasAudio: hasAudio,
  );

  if (current == MomentMediaKind.none || current == wanted) {
    // Adding more of what you already have is always fine; the per-kind
    // limits (image count, video duration) are enforced elsewhere.
    return null;
  }

  return MomentMediaBlock(present: current, wanted: wanted);
}

/// A refused combination, carrying both halves so the caller can say which
/// thing is in the way rather than a generic "not allowed".
class MomentMediaBlock {
  const MomentMediaBlock({required this.present, required this.wanted});

  final MomentMediaKind present;
  final MomentMediaKind wanted;

  @override
  bool operator ==(Object other) =>
      other is MomentMediaBlock &&
      other.present == present &&
      other.wanted == wanted;

  @override
  int get hashCode => Object.hash(present, wanted);

  @override
  String toString() => 'MomentMediaBlock($present blocks $wanted)';
}

/// The longest video allowed, in seconds.
///
/// Reels cap at three minutes; a plain video moment keeps the older ten-minute
/// cap. The trimmer will not let a longer window be selected, so this is the
/// single place the number is decided.
int maxVideoSeconds({required bool isReel}) => isReel ? 180 : 600;
