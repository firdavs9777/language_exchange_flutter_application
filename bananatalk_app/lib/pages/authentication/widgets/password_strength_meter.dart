import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, strong }

PasswordStrength scorePassword(String password) {
  if (password.isEmpty) return PasswordStrength.empty;
  final hasUpper = password.contains(RegExp(r'[A-Z]'));
  final hasLower = password.contains(RegExp(r'[a-z]'));
  final hasDigit = password.contains(RegExp(r'\d'));
  final hasSymbol = password.contains(RegExp(r'[@$!%*?&]'));
  final meetsMinimum = password.length >= 8 && hasUpper && hasLower && hasDigit;
  if (!meetsMinimum) return PasswordStrength.weak;
  if (password.length >= 12 && hasSymbol) return PasswordStrength.strong;
  return PasswordStrength.fair;
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = scorePassword(password);
    final (fill, color, label) = switch (strength) {
      PasswordStrength.empty => (0.0, Colors.transparent, ''),
      PasswordStrength.weak => (0.33, Colors.redAccent, 'Weak'),
      PasswordStrength.fair => (0.66, const Color(0xFFFFB300), 'Good'),
      PasswordStrength.strong => (1.0, const Color(0xFF00BFA5), 'Strong'),
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: strength == PasswordStrength.empty ? 0 : 1,
      child: Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill, minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]),
    );
  }
}
