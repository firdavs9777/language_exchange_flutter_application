import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// The canonical bottom save button used across edit screens:
/// gradient [#00BFA5 → #00897B] with primary-color shadow,
/// check icon + label (defaults to l10n.saveChanges),
/// spinner when isSaving, muted style when !canSave.
class GradientSaveButton extends StatelessWidget {
  final bool canSave;
  final bool isSaving;
  final String? label;
  final VoidCallback? onPressed;

  const GradientSaveButton({
    super.key,
    required this.canSave,
    required this.isSaving,
    this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveLabel = label ?? l10n.saveChanges;
    final enabled = canSave && !isSaving && onPressed != null;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    )
                  : null,
              color: enabled
                  ? null
                  : context.dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: enabled ? Colors.white : context.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          effectiveLabel,
                          style: context.titleSmall.copyWith(
                            color: enabled ? Colors.white : context.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
