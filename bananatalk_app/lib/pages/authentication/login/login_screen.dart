import 'dart:io';

import 'package:bananatalk_app/pages/authentication/login/apple_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/email_verification/email_input_screen.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/forgot_password_email_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/google_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two_screen.dart';
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
import 'package:bananatalk_app/pages/authentication/widgets/animated_banana_title.dart';
import 'package:bananatalk_app/pages/authentication/widgets/animated_auth_background.dart';
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

  // Inline email validation — shown as errorText under the field on
  // focus-loss (not a snackbar). Password keeps just the show/hide toggle
  // (no strength meter on login; that's registration-only).
  final _emailFieldKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();

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
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) return;
    // Validate on focus-loss only; leave the field alone while still typing.
    _emailFieldKey.currentState?.validate();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!AuthService.validateEmail(email)) {
      return AppLocalizations.of(context)!.pleaseEnterValidEmail;
    }
    return null;
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
    final ok = await _biometric.authenticate(
      reason: l10n.biometricSignInPrompt,
    );
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
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
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
        message: AppLocalizations.of(context)!.pleaseEnterBothEmailAndPassword,
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

          // Profile-completion gate: rescues accounts stuck at
          // profileCompleted=false (abandoned wizard, or backend refused an
          // earlier completion attempt because languages matched).
          // `profileCompleted` now lives on Community (populated from
          // /auth/me), so both the initial gate and the post-wizard recheck
          // read the same field for symmetry.
          final bool hasCoreFields =
              user.gender.isNotEmpty &&
              user.birth_year.isNotEmpty &&
              user.native_language.isNotEmpty &&
              user.language_to_learn.isNotEmpty;

          if (!user.profileCompleted || !hasCoreFields) {
            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterTwo(completionMode: true),
              ),
            );

            if (!mounted) return;
            final recheck = await ref
                .read(authServiceProvider)
                .getLoggedInUser();
            final bool recheckHasCoreFields =
                recheck.gender.isNotEmpty &&
                recheck.birth_year.isNotEmpty &&
                recheck.native_language.isNotEmpty &&
                recheck.language_to_learn.isNotEmpty;
            if (!recheck.profileCompleted || !recheckHasCoreFields) {
              // Still incomplete — stay on login screen.
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
        // `accountLocked` / `rateLimited` keep their existing countdown
        // flows — auth_providers.dart already folds lockUntil/retryAfter
        // into `message`, so the snackbar path here just surfaces it as-is.
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
      resizeToAvoidBottomInset: true,
      bodyPadding: EdgeInsets.zero,
      // Full-bleed animated backdrop behind the form. AnimatedAuthBackground
      // is a Stack(fit: StackFit.expand) so it needs a bounded height — give
      // it at least the viewport height, then let an inner scroll view
      // handle any overflow (small screens / keyboard open) instead of the
      // Stack itself.
      body: Builder(
        builder: (context) {
          final viewportHeight = MediaQuery.sizeOf(context).height;
          return SizedBox(
            height: viewportHeight,
            width: double.infinity,
            child: AnimatedAuthBackground(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    const AnimatedBananaTitle(fontSize: 46),
                    const SizedBox(height: 10),
                    Text(
                      l10n.login,
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Note: biometric sign-in (when available) is offered as
                    // an inline icon chip alongside the social providers
                    // below, not as a separate bolt-on block up here.
                    Form(
                      key: _emailFieldKey,
                      child: AuthTextField(
                        controller: _emailController,
                        label: l10n.email,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        focusNode: _emailFocusNode,
                        validator: _validateEmail,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      label: l10n.password,
                      showStrengthMeter: false,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 12),
                    // Remember Me + Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? true),
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(l10n.rememberMe, style: context.bodyMedium),
                            ],
                          ),
                        ),
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    AuthGradientButton(
                      label: l10n.login,
                      onPressed: _isLoading ? null : submit,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    // "or continue with" divider
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
                          child: Text(l10n.or, style: context.bodyMedium),
                        ),
                        Expanded(
                          child: Divider(
                            color: context.dividerColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Social providers (Apple + Google side-by-side per
                    // platform guidelines) with the biometric option as an
                    // inline icon chip when available.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (Platform.isIOS) ...[
                          SocialLoginButton(
                            compact: true,
                            provider: SocialProvider.apple,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => const AppleLogin(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                        ],
                        SocialLoginButton(
                          compact: true,
                          provider: SocialProvider.google,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => const GoogleLogin(),
                              ),
                            );
                          },
                        ),
                        if (_biometricVisible) ...[
                          const SizedBox(width: 16),
                          BiometricLoginButton(
                            compact: true,
                            userName: _biometricUserName ?? '',
                            isAuthenticating: _biometricAuthing,
                            onPressed: _biometricLogin,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Register link footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
              ),
            ),
          );
        },
      ),
    );
  }
}
