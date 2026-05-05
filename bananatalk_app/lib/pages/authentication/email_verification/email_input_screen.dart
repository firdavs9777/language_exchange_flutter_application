import 'package:bananatalk_app/pages/authentication/email_verification/email_verification_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/login_screen.dart';
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

class EmailInput extends ConsumerStatefulWidget {
  const EmailInput({super.key});

  @override
  ConsumerState<EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends ConsumerState<EmailInput> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
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

    setState(() => _isLoading = true);

    final result =
        await ref.read(authServiceProvider).sendVerificationCode(email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      showAuthSnackBar(
        context,
        message: l10n.verificationCodeSent,
        type: AuthSnackBarType.success,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EmailVerification(email: email),
        ),
      );
    } else {
      // Handle error — check if it's a registration validation error (wrong endpoint)
      String errorMessage =
          result['message'] ?? 'Failed to send verification code';

      if (errorMessage.contains('language to learn') ||
          errorMessage.contains('native language') ||
          errorMessage.contains('birth day') ||
          errorMessage.contains('password')) {
        errorMessage = 'Server configuration error. Please contact support.';
      }

      showAuthSnackBar(
        context,
        message: errorMessage,
        type: AuthSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScreenScaffold(
      title: l10n.signUp,
      showBackButton: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Bananatalk',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.createAccount,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.enterEmailToGetStarted,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: context.textSecondary),
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
            label: l10n.continueText,
            onPressed: _isLoading ? null : _sendVerificationCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.alreadyHaveAnAccount,
                style: TextStyle(color: context.textSecondary),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => Login()),
                  );
                },
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
    );
  }
}
