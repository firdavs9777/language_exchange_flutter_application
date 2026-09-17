import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Explains WHY a reel would not play, from inside the app.
///
/// The pool logged only the PlatformException, which for AVFoundation is a
/// bare OSStatus — `-12746` tells you a decoder refused the file and nothing
/// about the file. Diagnosing that from outside meant guessing: simulator
/// limits, codec, bitrate, moov position, all plausible and all wrong at
/// various points.
///
/// What actually decides whether iOS will play a URL is mostly in the response
/// headers, so this asks the server directly and prints them next to the
/// failure. A Content-Type of `application/octet-stream` is the single most
/// common cause — AVPlayer picks its decoder from that header, and
/// "arbitrary binary" makes it refuse a perfectly good H.264 file. That is
/// also invisible from a stack trace, which is why this exists.
///
/// Debug builds only: it costs an extra request per failure, which is free
/// while developing and pointless in release.
class ReelFailureDiagnostics {
  ReelFailureDiagnostics._();

  /// Types iOS will actually attempt. Anything else is the likely culprit.
  static const Set<String> playableTypes = {
    'video/mp4',
    'video/quicktime',
    'video/x-m4v',
    'video/3gpp',
    'application/vnd.apple.mpegurl',
    'application/x-mpegurl',
  };

  /// Formats one line per fact. Pure, so the verdict logic is testable
  /// without a network.
  static String describe({
    required String url,
    required bool usingCache,
    int? status,
    String? contentType,
    String? contentLength,
    String? cdnCacheStatus,
    String? cachedPath,
    int? cachedBytes,
  }) {
    final lines = <String>[
      '── reel playback failure ──────────────────',
      '  url            : $url',
      '  source         : ${usingCache ? 'cached file' : 'network'}',
    ];

    if (cachedPath != null) {
      lines.add('  cached path    : $cachedPath');
      lines.add('  cached bytes   : ${cachedBytes ?? 'unknown'}');
      final dot = cachedPath.lastIndexOf('.');
      final ext = dot == -1 ? '(none)' : cachedPath.substring(dot);
      lines.add('  cached ext     : $ext');
      if (ext == '(none)' || ext == '.bin') {
        // A previous bug stored cached reels as .bin and iOS refused them.
        lines.add('  ⚠ the cached file has no usable video extension');
      }
    }

    if (status != null) lines.add('  http status    : $status');
    if (contentLength != null) lines.add('  content-length : $contentLength');
    if (cdnCacheStatus != null) lines.add('  cdn cache      : $cdnCacheStatus');

    if (contentType != null) {
      lines.add('  content-type   : $contentType');
      final base = contentType.split(';').first.trim().toLowerCase();
      if (!playableTypes.contains(base)) {
        lines.add('  ⚠ iOS picks its decoder from Content-Type, and');
        lines.add('    "$base" is not a type it will play.');
        lines.add('    This alone causes OSStatus -12746.');
      } else {
        lines.add('  ✓ content-type is playable — look elsewhere');
      }
    }

    lines.add('───────────────────────────────────────────');
    return lines.join('\n');
  }

  /// Probes [url] and prints the report. Never throws and never blocks
  /// playback recovery — a diagnostic that breaks the thing it is diagnosing
  /// is worse than none.
  static Future<void> report({
    required String url,
    required bool usingCache,
    File? cachedFile,
  }) async {
    if (!kDebugMode) return;

    int? status;
    String? contentType;
    String? contentLength;
    String? cdnCache;
    String? cachedPath;
    int? cachedBytes;

    try {
      if (cachedFile != null) {
        cachedPath = cachedFile.path;
        if (await cachedFile.exists()) {
          cachedBytes = await cachedFile.length();
        } else {
          cachedBytes = -1; // probe said hit, file is gone
        }
      }
    } catch (_) {
      // Filesystem detail is a nicety; never let it break the report.
    }

    try {
      // A ranged GET rather than HEAD: some CDNs answer HEAD from a different
      // path and report headers the player will never actually see.
      final response = await http
          .get(Uri.parse(url), headers: {'Range': 'bytes=0-1'})
          .timeout(const Duration(seconds: 10));
      status = response.statusCode;
      contentType = response.headers['content-type'];
      contentLength = response.headers['content-range'] ??
          response.headers['content-length'];
      cdnCache = response.headers['cf-cache-status'] ??
          response.headers['x-cache'];
    } catch (e) {
      status = -1;
      contentType = null;
      debugPrint('  (diagnostic probe failed: $e)');
    }

    debugPrint(describe(
      url: url,
      usingCache: usingCache,
      status: status,
      contentType: contentType,
      contentLength: contentLength,
      cdnCacheStatus: cdnCache,
      cachedPath: cachedPath,
      cachedBytes: cachedBytes,
    ));
  }
}
