import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

enum AnnouncementLinkKind { inApp, external, none }

const String _appScheme = 'bananatalk://';

/// One rule for every announcement button: [Announcement.isOpenableButtonUrl]
/// (preflight ruling R1). Only http(s) opens outside the app; `bananatalk://`
/// and `/path` go through the app router (an empty app path is ignored, never
/// handed back to the OS); anything else is ignored.
AnnouncementLinkKind announcementLinkKind(String url) {
  final u = url.trim();
  if (!Announcement.isOpenableButtonUrl(u)) return AnnouncementLinkKind.none;
  if (announcementRoutePath(u) != null) return AnnouncementLinkKind.inApp;
  final scheme = Uri.tryParse(u)?.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https'
      ? AnnouncementLinkKind.external
      : AnnouncementLinkKind.none;
}

/// The go_router path for an in-app link: `/path` as is, and
/// `bananatalk://<path>` becomes `/<path>`. Null for anything else.
String? announcementRoutePath(String url) {
  final u = url.trim();
  if (!Announcement.isOpenableButtonUrl(u)) return null;
  if (u.startsWith('/')) return u;
  if (u.toLowerCase().startsWith(_appScheme)) {
    final rest = u.substring(_appScheme.length).replaceFirst(RegExp(r'^/+'), '');
    return rest.isEmpty ? null : '/$rest';
  }
  return null;
}

/// Whether the app router has a route for [path]. A mistyped admin link
/// (`bananatalk://moments-typo`) would otherwise land on go_router's built-in
/// "page not found" screen (the router has no errorBuilder).
bool isKnownAppRoute(String path) {
  try {
    return !goRouter.configuration.findMatch(Uri.parse(path)).isError;
  } catch (e) {
    debugPrint('isKnownAppRoute: $path failed to match: $e');
    return false;
  }
}

/// [push], [launch] and [isKnownRoute] default to the app router, the
/// external browser and [isKnownAppRoute]. An in-app link with no matching
/// route does nothing. Never throws: a failed launch or push is logged.
Future<void> openAnnouncementLink(
  String url, {
  void Function(String path)? push,
  Future<bool> Function(Uri uri)? launch,
  bool Function(String path)? isKnownRoute,
}) async {
  switch (announcementLinkKind(url)) {
    case AnnouncementLinkKind.inApp:
      final path = announcementRoutePath(url)!;
      if (!(isKnownRoute ?? isKnownAppRoute)(path)) {
        debugPrint('openAnnouncementLink: no route for $path, ignored');
        return;
      }
      try {
        if (push != null) {
          push(path);
        } else {
          goRouter.push(path);
        }
      } catch (e) {
        debugPrint('openAnnouncementLink: push failed: $e');
      }
    case AnnouncementLinkKind.external:
      final uri = Uri.parse(url.trim());
      try {
        if (launch != null) {
          await launch(uri);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        // Fire-and-forget from the sheet: never an uncaught async error.
        debugPrint('openAnnouncementLink: launch failed: $e');
      }
    case AnnouncementLinkKind.none:
      break;
  }
}

/// The in-app announcement sheet. Selection and the seen set live in
/// `AnnouncementCandidate`; this only renders.
class AnnouncementModal {
  /// Pushes the sheet synchronously (a push that fails throws before the
  /// returned future exists); the future completes when it is dismissed.
  static Future<void> show(BuildContext context, Announcement announcement) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AnnouncementSheet(announcement: announcement),
    );
  }
}

class _AnnouncementSheet extends StatelessWidget {
  const _AnnouncementSheet({required this.announcement});

  final Announcement announcement;

  static const _teal = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = announcement;
    final primaryButton = ElevatedButton.styleFrom(
      backgroundColor: _teal,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            if (a.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  a.imageUrl!,
                  cacheWidth: ImageUtils.getCacheDimension(ImageQuality.medium),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(a.emoji ?? '📢',
                      style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (a.title.isNotEmpty) ...[
              Text(
                a.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            if (a.body.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: isDark ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _teal.withValues(alpha: isDark ? 0.20 : 0.15)),
                ),
                child: Text(
                  a.body,
                  style: TextStyle(
                      fontSize: 14, color: context.textSecondary, height: 1.65),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: primaryButton,
                onPressed: () {
                  Navigator.pop(context);
                  if (a.hasButton) openAnnouncementLink(a.buttonUrl!);
                },
                child: Text(
                  a.hasButton ? a.buttonLabel! : l10n.ok,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (a.hasButton) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.close,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
