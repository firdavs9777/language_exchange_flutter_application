import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Grid tile for a text/prompt moment (no image). Renders the moment's text
/// on its chosen background colour so it reads as a real post instead of a
/// blank placeholder.
///
/// Shared by the own-profile moments preview grid
/// ([lib/pages/profile/profile_main/sections/profile_moments_tab.dart]),
/// the full profile moments grid
/// ([lib/pages/profile/moments/moments_list.dart]), and the community
/// detail moments grid — previously duplicated privately in each.
class TextMomentTile extends StatelessWidget {
  final String text;
  final String backgroundColor;

  const TextMomentTile({
    super.key,
    required this.text,
    required this.backgroundColor,
  });

  /// Parses a "#RRGGBB" / "RRGGBB" hex string; null if not a valid colour.
  Color? _parseHex(String raw) {
    var hex = raw.replaceAll('#', '').trim();
    if (hex.isEmpty) return null;
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseHex(backgroundColor);
    final hasBg = bg != null;
    final trimmed = text.trim();

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasBg ? bg : context.containerColor,
        gradient: hasBg
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFFE7A3), Color(0xFFFFD54F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: trimmed.isEmpty
          ? Icon(Icons.notes_rounded, color: context.textSecondary)
          : Text(
              trimmed,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: hasBg ? Colors.white : const Color(0xFF5B4A00),
              ),
            ),
    );
  }
}
