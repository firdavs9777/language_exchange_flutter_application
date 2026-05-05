import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Password field with two optional UX wins:
/// - Always: eye-icon suffix to toggle obscureText (B feature).
/// - When [showStrengthMeter] is true: 4-segment strength bar below the
///   field that updates as the user types (C feature).
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final bool showStrengthMeter;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.showStrengthMeter = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;
  String _value = '';

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
    _value = widget.controller.text;
    if (widget.showStrengthMeter) {
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    if (widget.showStrengthMeter) {
      widget.controller.removeListener(_onTextChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    if (mounted) setState(() => _value = widget.controller.text);
  }

  void _toggleObscure() {
    HapticFeedback.selectionClick();
    setState(() => _obscure = !_obscure);
  }

  /// Strength score 0..4 — one point each for: length ≥8, has digit,
  /// has uppercase, has special char.
  int _strength(String pw) {
    if (pw.isEmpty) return 0;
    var score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'\d'))) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return score;
  }

  (Color, String) _strengthLabel(int score, AppLocalizations l10n) {
    return switch (score) {
      0 || 1 => (AppColors.error, l10n.passwordWeak),
      2 => (const Color(0xFFFF9800), l10n.passwordFair),
      3 => (AppColors.success, l10n.passwordStrong),
      _ => (AppColors.success, l10n.passwordVeryStrong),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderColor = _focused
        ? AppColors.primary
        : context.dividerColor.withValues(alpha: 0.5);
    final iconColor = _focused ? AppColors.primary : context.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          style: context.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            labelStyle: TextStyle(
              color: _focused ? AppColors.primary : context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: context.bodyMedium.copyWith(color: context.textHint),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: iconColor),
            suffixIcon: IconButton(
              tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: context.textMuted,
              ),
              onPressed: _toggleObscure,
            ),
            filled: true,
            fillColor: context.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
        if (widget.showStrengthMeter && _value.isNotEmpty) ...[
          const SizedBox(height: 8),
          _StrengthMeter(
            score: _strength(_value),
            label: _strengthLabel(_strength(_value), l10n),
          ),
        ],
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final int score; // 0..4
  final (Color, String) label;

  const _StrengthMeter({required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final (color, text) = label;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              final filled = i < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: filled
                        ? color
                        : context.dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: context.captionSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
