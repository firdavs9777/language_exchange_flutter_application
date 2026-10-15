/// Decides when an incoming deep link may open.
///
/// A link that launches the app must not skip the splash: the splash runs the
/// Terms and profile gates, re-registers push, and decides between the tab
/// shell and login. So a link that arrives before the user is signed in and
/// past the splash is held, and opened on top of the shell (`push`, so back
/// returns to the tabs) the first time the router lands on `/home` or
/// `/tabs/..` -- after the splash, or after signing in from login.
///
/// Pure: the router and auth are passed in, so this is unit tested.
class DeepLinkGate {
  DeepLinkGate({
    required this.currentPath,
    required this.isSignedIn,
    required this.push,
    required this.go,
  });

  /// The router's current path, or null before it has one.
  final String? Function() currentPath;
  final bool Function() isSignedIn;
  final void Function(String path) push;
  final void Function(String path) go;

  String? _pending;

  /// The held link, if any.
  String? get pending => _pending;

  void onLink(String path) {
    // The invite route stores the code and redirects to the splash itself.
    if (path.startsWith('/invite/')) {
      go(path);
      return;
    }
    if (_canOpenNow()) {
      _pending = null;
      push(path);
    } else {
      _pending = path;
    }
  }

  /// Call whenever the router's location changes.
  void onRouteChanged() {
    final path = _pending;
    if (path == null || !isSignedIn() || !_isShell(currentPath())) return;
    _pending = null;
    push(path);
  }

  bool _canOpenNow() {
    final here = currentPath();
    return isSignedIn() && here != null && here != '/splash' && here != '/login';
  }

  static bool _isShell(String? path) =>
      path == '/home' || (path?.startsWith('/tabs/') ?? false);
}
