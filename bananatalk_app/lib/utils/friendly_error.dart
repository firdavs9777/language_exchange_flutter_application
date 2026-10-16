import 'dart:async';
import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// What went wrong, in the only two categories a user can act on.
///
/// `offline` means "the request never left, or never arrived" — the user can
/// fix that by reconnecting. Everything else is `unknown`: the user's only
/// move is to try again, so drawing finer distinctions would give them
/// nothing extra to do.
enum ErrorKind { offline, unknown }

/// Classify a thrown object.
///
/// String matching is deliberate alongside the type checks: failures reach
/// the UI having been round-tripped through `e.toString()` by service layers
/// that catch and re-wrap, so by the time a screen sees one the original
/// [SocketException] is often just text inside an [Exception] message.
ErrorKind classifyError(Object? error) {
  if (error is SocketException) return ErrorKind.offline;
  if (error is HttpException) return ErrorKind.offline;
  if (error is TimeoutException) return ErrorKind.offline;

  final text = error?.toString().toLowerCase() ?? '';
  const offlineMarkers = [
    'socketexception',
    'failed host lookup',
    'no address associated',
    'network is unreachable',
    'connection refused',
    'connection closed',
    'connection reset',
    'connection timed out',
    'timeoutexception',
    'handshakeexception',
    'clientexception',
  ];
  for (final marker in offlineMarkers) {
    if (text.contains(marker)) return ErrorKind.offline;
  }
  return ErrorKind.unknown;
}

/// A sentence to show a user, for any thrown object.
///
/// The alternative — which this replaces at a dozen call sites — was
/// `Text('Error: $e')`, which put
/// `Exception: Failed to load community: SocketException: Failed host lookup:
/// 'api.banatalk.com' (OS Error: nodename nor servname provided)` in front of
/// someone whose wifi had dropped. It is not only unreadable; it reads as a
/// crash, which is a worse thing to believe about an app than "I am offline".
///
/// [fallback] is for when the caller has something more specific worth saying
/// than "something went wrong" — a failed follow, say. It is used only for
/// non-network failures; a dropped connection always reports as one.
///
/// Without a [fallback], a non-network failure that reads like a sentence our
/// backend wrote ("this club is full", "you already removed this word") is
/// shown as-is — see [serverMessageOf]. Anything else becomes the generic
/// localized "something went wrong".
///
/// [prefix] is for screens that used to show `'$failedToUpdate: $e'`: a
/// server sentence keeps the prefix in front of it ("Failed to update: Name
/// is too long"), and an opaque failure shows the prefix alone.
String friendlyErrorMessage(
  AppLocalizations l10n,
  Object? error, {
  String? fallback,
  String? prefix,
}) {
  if (classifyError(error) == ErrorKind.offline) {
    return l10n.noInternetConnection;
  }
  if (fallback != null) return fallback;
  final server = serverMessageOf(error);
  if (prefix != null) return server == null ? prefix : '$prefix: $server';
  return server ?? l10n.somethingWentWrong;
}

/// The human-readable sentence inside [error], or null when there is none.
///
/// Services mostly `throw Exception(body['message'] ?? 'Failed to ...')`, so
/// a refusal from the server reaches the UI as `Exception: This club is
/// full` — worth showing once the prefix is gone. What must NOT reach a user
/// is everything else that travels the same road: re-wrapped chains
/// (`Failed to update: Exception: ...`), JSON bodies, HTML error pages, Dart
/// type errors. This is a conservative guess: when in doubt it says null and
/// the caller shows its generic message.
String? serverMessageOf(Object? error) {
  if (error == null) return null;
  String text;
  if (error is Map) {
    final value = error['message'] ?? error['error'];
    if (value is! String) return null;
    text = value;
  } else if (error is Error || error is FormatException) {
    // Programming errors (type casts, null checks, bad state) and parse
    // failures never carry a sentence meant for a user.
    return null;
  } else {
    text = error.toString();
  }

  text = text.trim();
  while (text.startsWith('Exception:')) {
    text = text.substring('Exception:'.length).trim();
  }
  if (text.isEmpty || text.length > 200) return null;
  if (!RegExp(r'[A-Za-zÀ-￿]').hasMatch(text)) return null;

  final lower = text.toLowerCase();
  const opaqueMarkers = [
    '{', '}', '[', '<', '\n', ': ', '#0', //
    'exception', 'error:', 'subtype', 'null check', 'nosuchmethod',
    'instance of', 'dart:', 'package:', 'http://', 'https://',
    'statuscode', 'status code', 'bad state', 'stack',
  ];
  for (final marker in opaqueMarkers) {
    if (lower.contains(marker)) return null;
  }
  return text;
}
