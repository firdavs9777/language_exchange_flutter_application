import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  Color get textPrimary => Theme.of(this).colorScheme.onBackground;
  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get textMuted => Theme.of(this).colorScheme.onSurface.withOpacity(0.7);
  Color get surfaceBackground => Theme.of(this).colorScheme.surface;
  Color get cardBackground => Theme.of(this).colorScheme.surfaceVariant;
  Color get dividerColor => Theme.of(this).colorScheme.outlineVariant;
}

