import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';

/// Standard scaffold used by every profile edit screen:
/// - Pill-shaped AppBar Save button on the right
/// - Scrollable body slot
/// - Optional gradient bottom Save button beneath the body
///
/// The two save buttons share the same [canSave] / [isSaving] / [onSave]
/// state — pressing either invokes [onSave].
class EditScreenScaffold extends StatelessWidget {
  final String title;
  final bool canSave;
  final bool isSaving;
  final VoidCallback? onSave;
  final Widget body;
  final bool showBottomSaveButton;
  final EdgeInsetsGeometry bodyPadding;

  const EditScreenScaffold({
    super.key,
    required this.title,
    required this.canSave,
    required this.isSaving,
    required this.onSave,
    required this.body,
    this.showBottomSaveButton = true,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 16, 20, 32),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canTap = canSave && !isSaving && onSave != null;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canTap ? onSave : null,
              style: TextButton.styleFrom(
                backgroundColor: canTap
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: bodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,
            if (showBottomSaveButton) ...[
              const SizedBox(height: 28),
              GradientSaveButton(
                canSave: canSave,
                isSaving: isSaving,
                onPressed: onSave,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
