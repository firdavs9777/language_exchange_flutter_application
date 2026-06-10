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

/// In-app password change for users who signed up with email/password.
///
/// Backend: `PUT /auth/updatepassword` (`controllers/auth.js#updatePassword`)
/// requires `{currentPassword, newPassword}`, verifies the current password
/// matches, and enforces the strong-password regex
/// `^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$` — we mirror that
/// regex client-side so the user gets instant feedback rather than a 400 on
/// submit. The backend also rotates the JWT on success; [AuthService]
/// handles writing the new token to SharedPreferences.
///
/// This screen is only reachable from Settings when the user has no OAuth
/// IDs linked (see the gating Consumer in `settings.dart`) — OAuth-only
/// accounts have no password to verify against.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  // Mirrors backend strongPasswordRegex (auth.js:1342). Keep in sync.
  static final RegExp _strongPassword =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentController.addListener(_rebuild);
    _newController.addListener(_rebuild);
    _confirmController.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _currentController
      ..removeListener(_rebuild)
      ..dispose();
    _newController
      ..removeListener(_rebuild)
      ..dispose();
    _confirmController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  bool get _newPasswordIsStrong =>
      _strongPassword.hasMatch(_newController.text);

  bool get _confirmMatches =>
      _newController.text.isNotEmpty &&
      _newController.text == _confirmController.text;

  bool get _canSave =>
      !_isSaving &&
      _currentController.text.isNotEmpty &&
      _newPasswordIsStrong &&
      _confirmMatches &&
      _newController.text != _currentController.text;

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.passwordChangedSuccess,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      showProfileSnackBar(
        context,
        message: '${l10n.failedToUpdate}: $msg',
        type: ProfileSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EditScreenScaffold(
      title: l10n.changePassword,
      canSave: _canSave,
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
            SectionLabel(
              icon: Icons.lock_outline_rounded,
              text: l10n.currentPassword,
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _currentController,
              hint: l10n.currentPasswordHint,
              obscure: !_showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 24),
            SectionLabel(
              icon: Icons.key_rounded,
              text: l10n.newPasswordLabel,
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _newController,
              hint: l10n.newPasswordHint,
              obscure: !_showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            _buildStrengthHints(),

            const SizedBox(height: 24),
            SectionLabel(
              icon: Icons.check_rounded,
              text: l10n.confirmNewPassword,
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _confirmController,
              hint: l10n.confirmPasswordHint,
              obscure: !_showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canSave ? _save() : null,
            ),
            if (_confirmController.text.isNotEmpty && !_confirmMatches) ...[
              const SizedBox(height: 8),
              _buildInlineMessage(
                l10n.passwordsDontMatch,
                color: AppColors.error,
                icon: Icons.error_outline_rounded,
              ),
            ],
            if (_newController.text.isNotEmpty &&
                _newController.text == _currentController.text) ...[
              const SizedBox(height: 8),
              _buildInlineMessage(
                l10n.newPasswordSameAsCurrent,
                color: AppColors.error,
                icon: Icons.error_outline_rounded,
              ),
            ],

            const SizedBox(height: 28),
            GradientSaveButton(
              canSave: _canSave,
              isSaving: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Field helpers ──────────────────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required TextInputAction textInputAction,
    void Function(String)? onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : context.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enableSuggestions: false,
        autocorrect: false,
        enabled: !_isSaving,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: context.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.bodyMedium.copyWith(color: context.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.lock_outline_rounded,
              color: context.textMuted,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
              color: context.textMuted,
            ),
            onPressed: _isSaving ? null : onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthHints() {
    final l10n = AppLocalizations.of(context)!;
    final pwd = _newController.text;
    final hasMinLen = pwd.length >= 8;
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasDigit = RegExp(r'\d').hasMatch(pwd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _strengthRow(l10n.passwordRule8Chars, hasMinLen),
        _strengthRow(l10n.passwordRuleLowercase, hasLower),
        _strengthRow(l10n.passwordRuleUppercase, hasUpper),
        _strengthRow(l10n.passwordRuleNumber, hasDigit),
      ],
    );
  }

  Widget _strengthRow(String text, bool met) {
    final color = met ? AppColors.success : context.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: context.captionSmall.copyWith(
              color: color,
              fontWeight: met ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMessage(
    String text, {
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.captionSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
