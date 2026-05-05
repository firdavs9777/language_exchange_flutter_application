import 'dart:io';

import 'package:bananatalk_app/pages/authentication/login/apple_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/email_verification/email_input_screen.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_email_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/google_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_service.dart';
import 'package:bananatalk_app/pages/authentication/biometric/enable_biometric_prompt.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_text_field.dart';
import 'package:bananatalk_app/pages/authentication/widgets/biometric_login_button.dart';
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

  // Biometric — only populated when device supports + user opted in.
  bool _biometricVisible = false;
  bool _biometricAuthing = false;
  String? _biometricUserName;
  final BiometricService _biometric = BiometricService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadRememberedEmail();
    _checkBiometricButton();
  }

  Future<void> _checkBiometricButton() async {
    final enabled = await _biometric.isEnabled();
    if (!enabled) return;
    final available = await _biometric.isAvailable();
    if (!available) return;
    final name = await _biometric.readUserNameDisplay();
    if (!mounted) return;
    setState(() {
      _biometricVisible = true;
      _biometricUserName = name;
    });
  }

  Future<void> _biometricLogin() async {
    if (_biometricAuthing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _biometricAuthing = true);

    final ok = await _biometric.authenticate(
      reason: l10n.biometricSignInPrompt,
    );
    if (!mounted) {
      return;
    }
    if (!ok) {
      setState(() => _biometricAuthing = false);
      return;
    }

    final state = await _biometric.readState();
    if (state == null || state.token.isEmpty) {
      // Stored snapshot is missing or unreadable — disable + drop to manual.
      await _biometric.disable();
      if (!mounted) return;
      setState(() {
        _biometricAuthing = false;
        _biometricVisible = false;
      });
      showAuthSnackBar(
        context,
        message: l10n.sessionExpired,
        type: AuthSnackBarType.error,
      );
      return;
    }

    // Restore auth state into prefs and run the existing init/validate flow.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', state.token);
    await prefs.setString('refreshToken', state.refreshToken);
    await prefs.setString('userId', state.userId);

    final auth = ref.read(authServiceProvider);
    final authed = await auth.initializeAuth();
    if (!mounted) return;

    if (!authed) {
      await _biometric.disable();
      setState(() {
        _biometricAuthing = false;
        _biometricVisible = false;
      });
      showAuthSnackBar(
        context,
        message: l10n.sessionExpired,
        type: AuthSnackBarType.error,
      );
      return;
    }

    setState(() => _biometricAuthing = false);
    context.go('/home');
  }

  /// Show the opt-in dialog after a fresh login if biometric is available
  /// and not already enabled. No-op otherwise.
  Future<void> _maybeOfferBiometric() async {
    final available = await _biometric.isAvailable();
    if (!available) return;
    final already = await _biometric.isEnabled();
    if (already) return;
    if (!mounted) return;

    final accepted = await showEnableBiometricPrompt(context);
    if (!accepted || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final ok = await _biometric.authenticate(reason: l10n.biometricSignInPrompt);
    if (!ok) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final refreshToken = prefs.getString('refreshToken') ?? '';
    final userId = prefs.getString('userId') ?? '';
    if (token.isEmpty || userId.isEmpty) return;

    String userName = '';
    try {
      final user = await ref.read(authServiceProvider).getLoggedInUser();
      userName = user.name;
    } catch (_) {
      // Fall back to the email's local-part if we can't load the user.
      userName = _emailController.text.trim().split('@').first;
    }

    await _biometric.enable(
      BiometricAuthState(
        token: token,
        refreshToken: refreshToken,
        userId: userId,
        userName: userName,
      ),
    );
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

        // Offer biometric login for next time. Only ask once — if already
        // enabled or unavailable on the device, skip silently.
        await _maybeOfferBiometric();
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
          if (_biometricVisible) ...[
            BiometricLoginButton(
              userName: _biometricUserName ?? '',
              isAuthenticating: _biometricAuthing,
              onPressed: _biometricLogin,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: context.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: context.captionSmall.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: context.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
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
