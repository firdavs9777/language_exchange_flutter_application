import 'dart:io';

import 'package:bananatalk_app/pages/authentication/login/apple_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/email_verification/email_input_screen.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_email_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/google_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_text_field.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_field.dart';
import 'package:bananatalk_app/pages/authentication/widgets/social_login_button.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends ConsumerStatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getString('rememberedEmail');
    if (remembered != null && remembered.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = remembered;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void submit() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      showAuthSnackBar(
        context,
        message:
            AppLocalizations.of(context)!.pleaseEnterBothEmailAndPassword,
        type: AuthSnackBarType.error,
      );
      return;
    }

    // Validate email format
    if (!AuthService.validateEmail(email)) {
      showAuthSnackBar(
        context,
        message: AppLocalizations.of(context)!.pleaseEnterValidEmail,
        type: AuthSnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ref
          .read(authServiceProvider)
          .login(email: email, password: password);

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
        // Persist or clear remembered email
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('rememberedEmail', email);
        } else {
          await prefs.remove('rememberedEmail');
        }

        // Check if user has accepted terms of service
        try {
          final user = await ref.read(authServiceProvider).getLoggedInUser();
          if (!user.termsAccepted) {
            // Show terms screen before entering app
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen(),
              ),
            );

            if (!mounted) return;

            // Re-check after terms acceptance
            final updatedUser = await ref
                .read(authServiceProvider)
                .getLoggedInUser();
            if (!updatedUser.termsAccepted) {
              // User didn't accept terms, stay on login screen
              return;
            }
          }
        } catch (e) {
          // If we can't fetch user data, log out and redirect to home
          // This handles cases where token is invalid or network issues
          await ref.read(authServiceProvider).logout();
          if (!mounted) return;
          context.go('/login');
          showAuthSnackBar(
            context,
            message: AppLocalizations.of(context)!.sessionExpired,
            type: AuthSnackBarType.error,
          );
          return;
        }

        if (!mounted) return;

        context.go('/home');

        showAuthSnackBar(
          context,
          message: AppLocalizations.of(context)!.loginSuccessful,
          type: AuthSnackBarType.success,
        );
      } else {
        // Handle different error types
        final String errorMessage =
            response['message'] ?? 'Login failed. Please try again.';

        showAuthSnackBar(
          context,
          message: errorMessage,
          type: AuthSnackBarType.error,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      showAuthSnackBar(
        context,
        message: 'Network error: ${error.toString()}',
        type: AuthSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthScreenScaffold(
      showBackButton: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Bananatalk',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.login,
            style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            controller: _emailController,
            label: l10n.email,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            label: l10n.password,
            showStrengthMeter: false,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),
          // Remember Me
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Text(
                  l10n.rememberMe,
                  style: context.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuthGradientButton(
            label: l10n.login,
            onPressed: _isLoading ? null : submit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          // OR Divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: context.dividerColor,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  l10n.or,
                  style: context.bodyMedium,
                ),
              ),
              Expanded(
                child: Divider(
                  color: context.dividerColor,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Social Login Buttons
          if (Platform.isIOS)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SocialLoginButton(
                provider: SocialProvider.apple,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const AppleLogin(),
                    ),
                  );
                },
              ),
            ),
          SocialLoginButton(
            provider: SocialProvider.google,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const GoogleLogin(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const ForgotPasswordEmail(),
                    ),
                  );
                },
                child: Text(
                  l10n.forgotPassword,
                  style: context.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const EmailInput(),
                    ),
                  );
                },
                child: Text(
                  l10n.registerLink,
                  style: context.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
