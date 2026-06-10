import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/pages/profile/widgets/section_label.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Free-text school / education edit. Capped at 80 chars (backend
/// `User.school` `maxlength: 80`). Identical shape to [OccupationEdit] —
/// kept as separate files for evolution (e.g. when school later grows
/// autocomplete from the Hipolabs universities API, only this file changes).
class SchoolEdit extends ConsumerStatefulWidget {
  const SchoolEdit({super.key, required this.currentSchool});

  final String currentSchool;

  @override
  ConsumerState<SchoolEdit> createState() => _SchoolEditState();
}

class _SchoolEditState extends ConsumerState<SchoolEdit> {
  static const int _maxLength = 80;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSaving = false;
  bool _isFocused = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentSchool);
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    final hasChanges = _controller.text.trim() != widget.currentSchool.trim();
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authServiceProvider)
          .updateSchool(school: _controller.text.trim());
      ref.invalidate(userProvider);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.profileUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context, _controller.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showProfileSnackBar(
        context,
        message:
            '${l10n.failedToUpdate}: ${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _hasChanges && !_isSaving;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return EditScreenScaffold(
      title: 'School',
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(
              icon: Icons.school_rounded,
              text: 'School',
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFocused
                      ? AppColors.primary
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : context.dividerColor.withValues(alpha: 0.5)),
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: _maxLength,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => canSave ? _save() : null,
                style:
                    context.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'e.g. Seoul National University, Lincoln High',
                  hintStyle: context.bodyMedium.copyWith(color: context.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.school_rounded,
                      color: _isFocused
                          ? AppColors.primary
                          : context.textMuted,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.length} / $_maxLength',
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 28),
            GradientSaveButton(
              canSave: canSave,
              isSaving: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
