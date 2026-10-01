import 'dart:io';

/// Where the paired backend repo lives, for cross-repo drift tests (the ones
/// that read a server enum straight from its source so two hand-maintained
/// lists can never diverge silently).
///
/// `../backend` was the original assumption, but on the primary dev machine
/// that path is an empty directory left over from January — so both drift
/// tests have failed there forever, teaching everyone to ignore them. Resolve
/// from candidates instead, and let callers SKIP (loudly) when no backend is
/// present rather than fail on machines that only check out the app.
String? backendFile(String relativePath) {
  final env = Platform.environment['BANANATALK_BACKEND'];
  final candidates = [
    if (env != null && env.isNotEmpty) env,
    '../backend',
    '../../language_exchange_backend_application',
  ];
  for (final root in candidates) {
    final f = File('$root/$relativePath');
    if (f.existsSync()) return f.path;
  }
  return null;
}
