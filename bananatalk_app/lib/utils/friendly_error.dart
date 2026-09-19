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
/// A caller holding a message the SERVER wrote ("this club is full", "you
/// already removed this word") should pass it as [fallback]. This function
/// cannot tell a server's sentence from an exception dump, so it treats
/// everything unrecognised as opaque — which would throw away exactly the
/// refusals worth reading. The caller knows which it has; this does not.
String friendlyErrorMessage(
  AppLocalizations l10n,
  Object? error, {
  String? fallback,
}) {
  return switch (classifyError(error)) {
    ErrorKind.offline => l10n.noInternetConnection,
    ErrorKind.unknown => fallback ?? l10n.somethingWentWrong,
  };
}
