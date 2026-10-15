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

/// Largest photo the upload endpoint accepts, in bytes.
const int kMaxMomentImageBytes = 10 * 1024 * 1024;

/// Photo formats the upload step accepts, by extension, with their MIME type.
const Map<String, String> kMomentImageMimeTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
};

/// Why this photo would be refused by the upload step, or null if it is fine.
///
/// Checked BEFORE the moment is created. It used to be checked only inside
/// `uploadMomentPhotos`, i.e. after the moment already existed — so a 12MB
/// photo or an Android HEIC left a caption-only post behind, and tapping Post
/// again made a duplicate.
String? momentImageProblem({required String path, required int sizeBytes}) {
  final dot = path.lastIndexOf('.');
  final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  if (!kMomentImageMimeTypes.containsKey(ext)) {
    return 'Unsupported image format: $ext. Supported: JPEG, PNG, GIF, WEBP';
  }
  if (sizeBytes > kMaxMomentImageBytes) {
    return 'Image size exceeds 10MB limit';
  }
  return null;
}

/// The first problem among `(path, sizeBytes)` photos, or null if all are fine.
String? firstMomentImageProblem(Iterable<(String, int)> images) {
  for (final (path, size) in images) {
    final problem = momentImageProblem(path: path, sizeBytes: size);
    if (problem != null) return problem;
  }
  return null;
}
