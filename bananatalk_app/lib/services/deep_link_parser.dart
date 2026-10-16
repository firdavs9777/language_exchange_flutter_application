/// Pure parsing logic for incoming deep links. Deliberately has no
/// dependency on `app_links` or any Flutter binding so it can be unit
/// tested without plugins.
///
/// Supports:
///   - Universal links: https://banatalk.com/<type>/<id>
///   - Custom scheme:   bananatalk://<type>/<id>
///   - Old profile QR codes: bananatalk://user/<id>
///
/// Returns the app route path (e.g. `/moment/123`) or `null` if the URI
/// doesn't match a supported deep link shape. The path is rebuilt from the
/// type and id only: query strings never reach the router (so a link can't
/// add `/chat/<id>?call=video`).
const _allowed = {'moment', 'profile', 'community', 'story', 'chat'};

/// Types added in 2.7.0 whose id must be a Mongo ObjectId: a malformed id
/// would otherwise open a screen that fetches it and fails.
const _objectIdTypes = {'story', 'chat'};

final _objectId = RegExp(r'^[0-9a-fA-F]{24}$');

final _inviteCode = RegExp(r'^[A-Z2-7]{4,16}$');

bool isObjectId(String id) => _objectId.hasMatch(id);

/// An invite code as the backend issues it (8 chars of A-Z2-7, see the
/// backend's lib/referralCode.js), or null.
String? normalizeInviteCode(String? raw) {
  if (raw == null) return null;
  final code = raw.trim().toUpperCase();
  return _inviteCode.hasMatch(code) ? code : null;
}

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
  if (type == 'community' && (id == 'matches' || id == 'waves')) {
    return '/community/$id';
  }
  if (type == null || id == null || id.isEmpty) return null;
  if (type == 'i') {
    final code = normalizeInviteCode(id);
    return code == null ? null : '/invite/$code';
  }
  // Profile QR codes made before 2.7.0 encode bananatalk://user/<id>; the
  // system camera hands them to the app like any other link.
  if (isScheme && type == 'user') {
    return isObjectId(id) ? '/profile/$id' : null;
  }
  if (!_allowed.contains(type)) return null;
  if (_objectIdTypes.contains(type) && !isObjectId(id)) return null;
  return '/$type/$id';
}

/// The user id in a scanned profile QR code: the https profile link (2.7.0+)
/// or the old `bananatalk://user/<id>`, or null for anything else.
String? userIdFromQrPayload(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  final path = routePathFromUri(uri);
  if (path == null || !path.startsWith('/profile/')) return null;
  final id = path.substring('/profile/'.length);
  return isObjectId(id) ? id : null;
}
