import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

/// Captures incoming deep links (universal links `https://banatalk.com/...`
/// and the custom scheme `bananatalk://...`) and routes them through the
/// app's existing [GoRouter], both for the link that launched the app
/// (cold start) and any links received while the app is already running.
class DeepLinkService {
  final GoRouter router;
  final AppLinks _appLinks = AppLinks();

  DeepLinkService(this.router);

  Future<void> start() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
    _appLinks.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    final path = routePathFromUri(uri);
    if (path != null) router.go(path);
  }
}
