import 'package:bananatalk_app/pages/authentication/auth_error_codes.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_verification_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/animated_auth_background.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_error_state.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_text_field.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ForgotPasswordEmail extends ConsumerStatefulWidget {
  const ForgotPasswordEmail({super.key});

  @override
  ConsumerState<ForgotPasswordEmail> createState() =>
      _ForgotPasswordEmailState();
}

class _ForgotPasswordEmailState extends ConsumerState<ForgotPasswordEmail> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // Non-null when the last attempt failed with a network/lockout/rate-limit
  // error — renders AuthErrorState in-body instead of (or in addition to) a
  // transient snackbar.
  AuthErrorKind? _errorKind;
  Duration? _errorRetryAfter;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty) {
      showAuthSnackBar(
        context,
        message: l10n.pleaseEnterEmailAddress,
        type: AuthSnackBarType.error,
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      showAuthSnackBar(
        context,
        message: l10n.pleaseEnterValidEmail,
        type: AuthSnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorKind = null;
      _errorRetryAfter = null;
    });

    Map<String, dynamic> result;
    try {
      result = await ref
          .read(authServiceProvider)
          .sendPasswordResetCode(email: email);
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
        message: l10n.resetCodeSent,
        type: AuthSnackBarType.success,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ForgotPasswordVerification(email: email),
        ),
      );
    } else {
      final errorCode = parseAuthErrorCode(result['code']?.toString());
      switch (errorCode) {
        case AuthErrorCode.accountLocked:
          setState(() {
            _errorKind = AuthErrorKind.locked;
            _errorRetryAfter = parseAuthErrorRetryAfter(result);
          });
          break;
        case AuthErrorCode.rateLimited:
          setState(() {
            _errorKind = AuthErrorKind.rateLimited;
            _errorRetryAfter = parseAuthErrorRetryAfter(result);
          });
          break;
        default:
          showAuthSnackBar(
            context,
            message: result['message'] ?? 'Failed to send reset code',
            type: AuthSnackBarType.error,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScreenScaffold(
      title: l10n.forgotPasswordTitle,
      showBackButton: true,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    if (_errorKind != null) ...[
                      AuthErrorState(
                        kind: _errorKind!,
                        retryAfter: _errorRetryAfter,
                        onRetry: _isLoading ? null : _sendResetCode,
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Icon(Icons.lock_reset, size: 80, color: AppColors.error),
                      const SizedBox(height: 24),
                      Text(
                        l10n.resetPasswordTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.enterEmailForResetCode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      AuthTextField(
                        controller: _emailController,
                        label: l10n.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 32),
                      AuthGradientButton(
                        label: l10n.sendResetCode,
                        onPressed: _isLoading ? null : _sendResetCode,
                        isLoading: _isLoading,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.rememberYourPassword,
                          style: TextStyle(color: context.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.login,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
