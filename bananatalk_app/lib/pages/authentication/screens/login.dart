import 'dart:io';

import 'package:bananatalk_app/pages/authentication/screens/apple_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/email_input.dart';
import 'package:bananatalk_app/pages/authentication/screens/forget_password_email.dart';
import 'package:bananatalk_app/pages/authentication/screens/google_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class Login extends ConsumerStatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _obscureText = true;
  bool _isLoading = false;

  void submit() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            AppLocalizations.of(context)!.pleaseEnterBothEmailAndPassword,
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate email format
    if (!AuthService.validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            AppLocalizations.of(context)!.pleaseEnterValidEmail,
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: BananaText(
                AppLocalizations.of(context)!.sessionExpired,
                BanaStyles: BananaTextStyles.warning,
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        if (!mounted) return;

        context.go('/home');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BananaText(
              AppLocalizations.of(context)!.loginSuccessful,
              BanaStyles: BananaTextStyles.success,
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // Handle different error types
        String errorMessage =
            response['message'] ?? 'Login failed. Please try again.';

        // Show appropriate error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BananaText(
              errorMessage,
              BanaStyles: BananaTextStyles.error,
            ),
            duration: Duration(seconds: response['isLocked'] == true ? 5 : 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Network error: ${error.toString()}',
            BanaStyles: BananaTextStyles.error,
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: BananaText(
          AppLocalizations.of(context)!.login,
          BanaStyles: BananaTextStyles.title,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                  child: Text(
                    'Bananatalk',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Center(
                  child: BananaText(
                    AppLocalizations.of(context)!.login,
                    BanaStyles: BananaTextStyles.title,
                  ),
                ),
                Spacing.gapLG,
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        textCapitalization: TextCapitalization.none,
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_sharp),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: context.dividerColor),
                            borderRadius: AppRadius.borderXL,
                          ),
                          label: BananaText(
                            AppLocalizations.of(context)!.email,
                            BanaStyles: BananaTextStyles.inputText,
                          ),
                        ),
                      ),
                      Spacing.gapLG,
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          filled: true,
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            child: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _obscureText
                                  ? context.iconColor
                                  : AppColors.info,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.password_outlined),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: context.dividerColor),
                            borderRadius: AppRadius.borderXL,
                          ),
                          label: BananaText(
                            AppLocalizations.of(context)!.password,
                            BanaStyles: BananaTextStyles.inputText,
                          ),
                        ),
                      ),
                      Spacing.gapXXL,
                      SizedBox(
                        width: 250.0,
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              )
                            : BananaButton(
                                onPressed: submit,
                                color: AppColors.primary,
                                BananaText: BananaText(
                                  AppLocalizations.of(context)!.login,
                                  BanaStyles: BananaTextStyles.buttonText,
                                ),
                                textColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 12.0,
                                ),
                                borderRadius: AppRadius.borderSM,
                              ),
                      ),
                      Spacing.gapXXL,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: BananaText(
                              AppLocalizations.of(context)!.or,
                              BanaStyles: BananaTextStyles.body,
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
                      Spacing.gapXXL,
                      // Social Login Buttons
                      SizedBox(
                        width: 250.0,
                        child: Column(
                          children: [
                            // Facebook Login Button
                            // Container(
                            //   width: double.infinity,
                            //   height: 50,
                            //   margin: const EdgeInsets.only(bottom: 12.0),
                            //   decoration: BoxDecoration(
                            //     borderRadius: AppRadius.borderXL,
                            //     boxShadow: [
                            //       BoxShadow(
                            //         color: const Color(0xFF1877F2).withOpacity(0.3),
                            //         blurRadius: 8,
                            //         offset: const Offset(0, 4),
                            //       ),
                            //     ],
                            //   ),
                            //   child: ElevatedButton.icon(
                            //     onPressed: () {
                            //       Navigator.of(context).push(
                            //         MaterialPageRoute(
                            //           builder: (ctx) => const FacebookLogin(),
                            //         ),
                            //       );
                            //     },
                            //     icon: const Icon(
                            //       Icons.facebook,
                            //       color: Colors.white,
                            //       size: 24,
                            //     ),
                            //     label: BananaText(
                            //       'Continue with Facebook',
                            //       BanaStyles: BananaTextStyles.buttonText,
                            //     ),
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: const Color(0xFF1877F2),
                            //       foregroundColor: Colors.white,
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: AppRadius.borderXL,
                            //       ),
                            //       elevation: 0,
                            //     ),
                            //   ),
                            // ),
                            // Google Login Button
                            if (Platform.isIOS) // ONLY SHOW ON iOS
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  height: 45.0,
                                  width: double.infinity,
                                  child: BananaButton(
                                    BananaText: BananaText(
                                      AppLocalizations.of(
                                        context,
                                      )!.signInWithApple,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (ctx) => const AppleLogin(),
                                        ),
                                      );
                                    },
                                    color: Colors.black, // Apple black color
                                    textColor: Color(0xFFFFFFFF),
                                    borderRadius: AppRadius.borderSM,
                                    icon: Icon(
                                      Icons.apple, // Apple icon
                                      color: Colors.white,
                                      size: 24.0,
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.borderXL,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4285F4,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => const GoogleLogin(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                label: BananaText(
                                  AppLocalizations.of(
                                    context,
                                  )!.continueWithGoogle,
                                  BanaStyles: BananaTextStyles.buttonText,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4285F4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderXL,
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacing.gapSM,
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
                            child: BananaText(
                              AppLocalizations.of(context)!.forgotPassword,
                              BanaStyles: BananaTextStyles.link,
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
                            child: BananaText(
                              AppLocalizations.of(context)!.registerLink,
                              BanaStyles: BananaTextStyles.link,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
