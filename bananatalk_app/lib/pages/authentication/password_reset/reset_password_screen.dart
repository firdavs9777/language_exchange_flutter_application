import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/widgets/animated_auth_background.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_error_state.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_field.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_strength_meter.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPassword extends ConsumerStatefulWidget {
  final String email;
  final String code;

  const ResetPassword({super.key, required this.email, required this.code});

  @override
  ConsumerState<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPassword> {
  bool _isLoading = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _password = '';
  String? _confirmError;

  // Non-null when the last attempt failed with a network/lockout/rate-limit
  // error — renders AuthErrorState in-body instead of the raw form.
  // NOTE: the backend `reset-password` endpoint does not return a typed
  // error `code` (unlike verify-reset-code), so this stays message-based —
  // we only ever detect the network case here, keyed off the message text
  // AuthService.resetPassword synthesizes for thrown exceptions.
  AuthErrorKind? _errorKind;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() => _password = _passwordController.text);
    _validateConfirmMatch();
  }

  void _onConfirmChanged() => _validateConfirmMatch();

  void _validateConfirmMatch() {
    final l10n = AppLocalizations.of(context)!;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _confirmError = confirm.isNotEmpty && confirm != _passwordController.text
          ? l10n.passwordsDoNotMatch
          : null;
    });
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
        message:
            passwordValidation['message'] ??
            'Password does not meet requirements',
        type: AuthSnackBarType.error,
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() => _confirmError = l10n.passwordsDoNotMatch);
      showAuthSnackBar(
        context,
        message: l10n.passwordsDoNotMatch,
        type: AuthSnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorKind = null;
    });

    Map<String, dynamic> result;
    try {
      result = await ref
          .read(authServiceProvider)
          .resetPassword(
            email: widget.email,
            code: widget.code,
            newPassword: password,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorKind = AuthErrorKind.network;
      });
      return;
    }

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
      // Message-based fallback: resetPassword's backend endpoint never
      // returns a typed `code`, so a "Network error: ..." message is the
      // only reliable signal we have for the illustrated network state.
      final message = result['message']?.toString() ?? '';
      if (message.startsWith('Network error')) {
        setState(() => _errorKind = AuthErrorKind.network);
      } else {
        showAuthSnackBar(
          context,
          message: result['message'] ?? 'Failed to reset password',
          type: AuthSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScreenScaffold(
      title: l10n.resetPasswordTitle,
      showBackButton: false,
      // AnimatedAuthBackground is a Stack(fit: StackFit.expand) so it needs a
      // bounded height — give it at least the viewport height, then let the
      // outer SingleChildScrollView (from AuthScreenScaffold) handle any
      // overflow instead of the Stack itself. See login_screen.dart for the
      // same pattern.
      body: Builder(
        builder: (context) {
          final viewportHeight = MediaQuery.sizeOf(context).height;
          return SizedBox(
            height: viewportHeight,
            width: double.infinity,
            child: AnimatedAuthBackground(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    if (_errorKind != null) ...[
                      AuthErrorState(
                        kind: _errorKind!,
                        onRetry: _isLoading ? null : _resetPassword,
                      ),
                    ] else ...[
                      Icon(Icons.lock_open, size: 60, color: AppColors.success),
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
                        showStrengthMeter: false,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      PasswordStrengthMeter(password: _password),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmPasswordController,
                        label: l10n.confirmPasswordLabel,
                        textInputAction: TextInputAction.done,
                        validator: (_) => _confirmError,
                      ),
                      if (_confirmError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _confirmError!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      AuthGradientButton(
                        label: l10n.resetPasswordTitle,
                        onPressed: _isLoading ? null : _resetPassword,
                        isLoading: _isLoading,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
