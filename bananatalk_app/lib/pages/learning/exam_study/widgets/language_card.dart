import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Card showing one language option on the Exam Study picker grid.
///
/// Each language gets its own accent color (deterministic from its code), a
/// gradient flag medallion, a softly-tinted background, and a code pill — so
/// the grid reads as distinct, colorful sections rather than identical tiles.
class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key, required this.language, required this.onTap});

  final ExamLanguage language;
  final VoidCallback onTap;

  /// Harmonious accent palettes; picked deterministically per language so a
  /// given language always keeps the same color across rebuilds.
  static const List<List<Color>> _palettes = [
    [Color(0xFF667EEA), Color(0xFF764BA2)], // indigo → violet
    [Color(0xFF11998E), Color(0xFF38EF7D)], // teal → green
    [Color(0xFFFF6A88), Color(0xFFFF99AC)], // pink
    [Color(0xFFFFB75E), Color(0xFFED8F03)], // amber
    [Color(0xFF4E9EFF), Color(0xFF1565C0)], // blue
    [Color(0xFFF857A6), Color(0xFFAA4B6B)], // magenta
    [Color(0xFF00B4DB), Color(0xFF0083B0)], // cyan
    [Color(0xFFFF8008), Color(0xFFFFC837)], // orange
  ];

  List<Color> get _palette {
    final seed =
        language.code.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return _palettes[seed % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final accent = palette.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            // Soft accent tint blended over the surface — works in light + dark.
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.07),
              context.surfaceColor,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient flag medallion.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    language.icon ?? '🏳️',
                    style: const TextStyle(fontSize: 30, height: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                language.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Code pill.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  language.code.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
