import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Small circular badge overlaying the bottom-left corner of an avatar to
/// surface the user's native language at a glance — matches the chat-list
/// pattern and is reused across chat detail, community card / detail, and
/// moments feed / detail to keep visual identity consistent.
///
/// Drop into a [Stack] alongside the avatar:
/// ```dart
/// Stack(children: [
///   avatar,
///   LanguageFlagBadge(nativeLanguage: user.native_language),
/// ])
/// ```
class LanguageFlagBadge extends StatelessWidget {
  final String? nativeLanguage;

  /// Diameter of the badge circle. The flag glyph scales proportionally.
  final double size;

  /// Distance from the avatar's bottom-left corner. Tweak to clear VIP frames.
  final double offset;

  const LanguageFlagBadge({
    super.key,
    required this.nativeLanguage,
    this.size = 18,
    this.offset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final lang = nativeLanguage;
    if (lang == null || lang.isEmpty) return const SizedBox.shrink();
    final flag = LanguageFlags.getFlagByName(lang);
    if (flag.isEmpty) return const SizedBox.shrink();

    final surface = context.surfaceColor;
    return Positioned(
      bottom: offset,
      left: offset,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          flag,
          style: TextStyle(fontSize: size * 0.67, height: 1.0),
        ),
      ),
    );
  }
}
