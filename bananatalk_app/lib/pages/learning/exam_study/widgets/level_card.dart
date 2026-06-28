import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// CEFR level tile used by the Vocabulary level picker. Shows the CEFR
/// label primarily and, when [secondaryLabel] is non-null, a smaller
/// label underneath (used for the Korean TOPIK dual-label).
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.cefr,
    required this.onTap,
    this.secondaryLabel,
    this.disabled = false,
  });

  final String cefr;
  final String? secondaryLabel;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? context.textMuted : context.primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: disabled
                  ? context.dividerColor
                  : context.primaryColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cefr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.4,
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  secondaryLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
