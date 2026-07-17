/// Pure parsing logic for incoming deep links. Deliberately has no
/// dependency on `app_links` or any Flutter binding so it can be unit
/// tested without plugins.
///
/// Supports:
///   - Universal links: https://banatalk.com/<type>/<id>
///   - Custom scheme:   bananatalk://<type>/<id>
///
/// Returns the app route path (e.g. `/moment/123`) or `null` if the URI
/// doesn't match a supported deep link shape.
const _allowed = {'moment', 'profile', 'community'};

String? routePathFromUri(Uri uri) {
  final isHttps = uri.scheme == 'https' && uri.host == 'banatalk.com';
  final isScheme = uri.scheme == 'bananatalk';
  if (!isHttps && !isScheme) return null;

  // https://banatalk.com/<type>/<id>  → segments [type, id]
  // bananatalk://<type>/<id>          → host=type, segments=[id]
  String? type;
  String? id;
  if (isScheme) {
    type = uri.host;
    id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else {
    if (uri.pathSegments.length >= 2) {
      type = uri.pathSegments[0];
      id = uri.pathSegments[1];
    }
  }
  if (type == null || id == null || id.isEmpty) return null;
  if (!_allowed.contains(type)) return null;
  return '/$type/$id';
}
