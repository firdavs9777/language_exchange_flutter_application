import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/app_provider_container.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/deep_link_gate.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

/// Captures incoming deep links (universal links `https://banatalk.com/...`
/// and the custom scheme `bananatalk://...`), both the link that launched
/// the app (cold start) and links received while it runs.
///
/// Links go through [DeepLinkGate]: a cold-start link waits for the normal
/// start (splash -> Terms/profile gates -> tab shell, or login and then the
/// shell) and is then pushed over the shell; a link received while signed in
/// is pushed at once.
class DeepLinkService {
  final GoRouter router;
  final AppLinks _appLinks = AppLinks();
  late final DeepLinkGate _gate = DeepLinkGate(
    currentPath: _currentPath,
    isSignedIn: () {
      final auth = appProviderContainer.read(authServiceProvider);
      return auth.isLoggedIn && auth.token.isNotEmpty;
    },
    // Deferred: never navigate from inside the router's own notification.
    push: (path) => Future(() => router.push(path)),
    go: router.go,
  );

  DeepLinkService(this.router);

  Future<void> start() async {
    router.routerDelegate.addListener(_gate.onRouteChanged);
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
    _appLinks.uriLinkStream.listen(_handle);
  }

  String? _currentPath() {
    try {
      final config = router.routerDelegate.currentConfiguration;
      return config.matches.isEmpty ? null : config.uri.path;
    } catch (_) {
      return null;
    }
  }

  void _handle(Uri uri) {
    final path = routePathFromUri(uri);
    if (path != null) _gate.onLink(path);
  }
}
