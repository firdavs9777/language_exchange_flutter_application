import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Remote-driven announcement popup.
///
/// Driven entirely by backend `.env` vars (see `appConfig.js`). Shows once per
/// unique announcement ID — bump `ANNOUNCEMENT_ID` to push a new popup to all
/// users, edit body/title freely, restart PM2.
class AnnouncementModal {
  static String _prefKey(String id) => 'dismissed_announcement_$id';

  static Future<void> showIfNeeded(
    BuildContext context,
    AppAnnouncement? announcement,
  ) async {
    if (announcement == null) return;
    if (!announcement.active) return;
    if (announcement.id.isEmpty) return;
    if (announcement.title.isEmpty && announcement.body.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey(announcement.id)) == true) return;
    if (!context.mounted) return;

    await prefs.setBool(_prefKey(announcement.id), true);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AnnouncementSheet(announcement: announcement),
    );
  }
}

class _AnnouncementSheet extends StatelessWidget {
  final AppAnnouncement announcement;
  const _AnnouncementSheet({required this.announcement});

  Future<void> _openButtonUrl(BuildContext context) async {
    final url = announcement.buttonUrl;
    if (url.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final hasButton =
        announcement.buttonLabel.isNotEmpty && announcement.buttonUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 28,
      ),
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

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                announcement.emoji,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (announcement.title.isNotEmpty) ...[
            Text(
              announcement.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          if (announcement.body.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5)
                    .withValues(alpha: isDark ? 0.10 : 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00BFA5)
                      .withValues(alpha: isDark ? 0.20 : 0.15),
                ),
              ),
              child: Text(
                announcement.body,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.65,
                ),
              ),
            ),
          const SizedBox(height: 24),

          if (hasButton) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openButtonUrl(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  announcement.buttonLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it 👍',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
