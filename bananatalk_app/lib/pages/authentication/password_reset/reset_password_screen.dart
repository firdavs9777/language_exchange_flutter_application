import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_field.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPassword extends ConsumerStatefulWidget {
  final String email;
  final String code;

  const ResetPassword({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  ConsumerState<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPassword> {
  bool _isLoading = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      showAuthSnackBar(
        context,
        message: l10n.pleaseFillAllFields,
        type: AuthSnackBarType.error,
      );
      return;
    }

    final passwordValidation = AuthService.validatePassword(password);
    if (!passwordValidation['valid']) {
      showAuthSnackBar(
        context,
        message: passwordValidation['message'] ??
            'Password does not meet requirements',
        type: AuthSnackBarType.error,
      );
      return;
    }

    if (password != confirmPassword) {
      showAuthSnackBar(
        context,
        message: l10n.passwordsDoNotMatch,
        type: AuthSnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authServiceProvider).resetPassword(
          email: widget.email,
          code: widget.code,
          newPassword: password,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showAuthSnackBar(
        context,
        message: l10n.passwordResetSuccessful,
        type: AuthSnackBarType.success,
      );
      context.go('/login');
    } else {
      showAuthSnackBar(
        context,
        message: result['message'] ?? 'Failed to reset password',
        type: AuthSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScreenScaffold(
      title: l10n.resetPasswordTitle,
      showBackButton: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.lock_open,
            size: 60,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.createNewPassword,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.enterNewPasswordBelow,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          PasswordField(
            controller: _passwordController,
            label: l10n.newPassword,
            showStrengthMeter: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmPasswordController,
            label: l10n.confirmPasswordLabel,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),
          AuthGradientButton(
            label: l10n.resetPasswordTitle,
            onPressed: _isLoading ? null : _resetPassword,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
