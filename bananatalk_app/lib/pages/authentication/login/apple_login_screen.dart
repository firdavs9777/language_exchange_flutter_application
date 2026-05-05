import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two_screen.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/social_login_button.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleLogin extends ConsumerStatefulWidget {
  const AppleLogin({super.key});

  @override
  ConsumerState<AppleLogin> createState() => _AppleLoginState();
}

class _AppleLoginState extends ConsumerState<AppleLogin> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request Apple Sign-In credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;

      if (identityToken == null) {
        setState(() {
          _errorMessage = 'Failed to get identity token from Apple';
          _isLoading = false;
        });
        return;
      }

      // Prepare user data (only available on first sign-in)
      final appleUser = {
        'fullName': {
          'givenName': credential.givenName,
          'familyName': credential.familyName,
        },
        'email': credential.email,
      };

      // Send to backend for verification
      final result = await ref
          .read(authServiceProvider)
          .signInWithAppleNative(identityToken, appleUser);

      if (result['success'] == true) {
        // Get user data from response
        final user = result['user'] as Map<String, dynamic>?;

        // Debug: Log the full user object to see what backend returns

        // Check profileCompleted flag from backend
        // IMPORTANT: Default to FALSE for safety - new users must complete profile
        final bool profileCompleted = user?['profileCompleted'] == true;

        // Check core required fields (language + gender + birth year)
        // Bio and images are optional — don't block login for them
        final gender = user?['gender']?.toString() ?? '';
        final birthYear = user?['birth_year']?.toString() ?? '';
        final nativeLang = user?['native_language']?.toString() ?? '';
        final learningLang = user?['language_to_learn']?.toString() ?? '';

        final bool hasCoreFields =
            gender.isNotEmpty &&
            birthYear.isNotEmpty &&
            nativeLang.isNotEmpty &&
            learningLang.isNotEmpty;

        // User needs to complete profile if backend flag is false OR core fields missing
        final bool needsProfileCompletion = !profileCompleted || !hasCoreFields;

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (needsProfileCompletion) {
            // Get values from backend - use empty strings to force user input
            final birthYear = user?['birth_year']?.toString() ?? '';
            final birthMonth = user?['birth_month']?.toString() ?? '';
            final birthDay = user?['birth_day']?.toString() ?? '';

            // Only use birthdate if all parts are present and valid
            String birthDate = '';
            if (birthYear.isNotEmpty &&
                birthMonth.isNotEmpty &&
                birthDay.isNotEmpty) {
              birthDate =
                  '$birthYear.${birthMonth.padLeft(2, '0')}.${birthDay.padLeft(2, '0')}';
            }

            // Profile not completed - redirect to RegisterTwo
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => RegisterTwo(
                  name: user?['name'] ?? '',
                  email: user?['email'] ?? '',
                  password: '', // OAuth users don't have password
                  gender: user?['gender'] ?? '',
                  birthDate: birthDate,
                  nativeLanguage: user?['native_language']?.toString() ?? '',
                  learningLanguage:
                      user?['language_to_learn']?.toString() ?? '',
                ),
              ),
            );

            showAuthSnackBar(
              context,
              message: AppLocalizations.of(context)!.welcomeCompleteProfile,
              type: AuthSnackBarType.info,
            );
          } else {
            // Profile completed - check terms before going to main app
            // Check if user has accepted terms of service
            try {
              final loggedInUser = await ref
                  .read(authServiceProvider)
                  .getLoggedInUser();
              if (!loggedInUser.termsAccepted) {
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

            // NOW connect socket - profile is complete and terms accepted
            try {
              await ChatSocketService().forceReconnect();
            } catch (e) {}

            // Register FCM token for push notifications
            try {
              final notificationService = NotificationService();
              final userId = ref.read(authServiceProvider).userId;
              if (userId.isNotEmpty) {
                await notificationService.registerToken(userId);
              }
            } catch (e) {}

            // Invalidate userProvider to force fresh fetch
            ref.invalidate(userProvider);

            context.go('/home');

            showAuthSnackBar(
              context,
              message: AppLocalizations.of(
                context,
              )!.welcomeBackName(user?['name'] ?? ''),
              type: AuthSnackBarType.success,
            );
          }
        }
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to authenticate with backend';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      String userFriendlyMessage = 'Apple sign-in error';

      // Parse common errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('canceled') ||
          errorString.contains('cancelled')) {
        userFriendlyMessage = 'Sign-in was cancelled.';
      } else if (errorString.contains('network')) {
        userFriendlyMessage =
            'Network error. Please check your internet connection.';
      } else if (errorString.contains('credential')) {
        userFriendlyMessage =
            'Failed to get Apple credentials. Please try again.';
      } else if (errorString.contains('authorization')) {
        userFriendlyMessage = 'Authorization failed. Please try again.';
      }

      setState(() {
        _errorMessage = '$userFriendlyMessage\n\nDetails: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: context.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // Main Content
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Apple Logo with gradient background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF000000), Color(0xFF434343)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.apple,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    BananaText(
                      AppLocalizations.of(context)!.signInWithApple,
                      BanaStyles: BananaTextStyles.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    BananaText(
                      AppLocalizations.of(context)!.continueWithAppleId,
                      textAlign: TextAlign.center,
                      BanaStyles: BananaTextStyles.body,
                    ),

                    const SizedBox(height: 48),

                    // Loading or Button
                    if (_isLoading) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            BananaText(
                              AppLocalizations.of(context)!.signingYouIn,
                              BanaStyles: BananaTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Apple Sign In Button
                      SocialLoginButton(
                        provider: SocialProvider.apple,
                        onPressed: _signInWithApple,
                        isLoading: false,
                      ),
                    ],

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BananaText(
                                    _errorMessage!,
                                    BanaStyles: BananaTextStyles.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                  _signInWithApple();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.tryAgain,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Back to Sign In Methods Link
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(
                        AppLocalizations.of(context)!.backToSignInMethods,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: context.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Privacy Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!.securedByApple,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.privacyProtectedApple,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
