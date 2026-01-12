import 'dart:io';
import 'package:bananatalk_app/pages/authentication/screens/register_second.dart';
import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
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
      final result = await ref.read(authServiceProvider).signInWithAppleNative(
            identityToken,
            appleUser,
          );

      if (result['success'] == true) {
        // Get user data from response
        final user = result['user'] as Map<String, dynamic>?;

        // Debug: Log the full user object to see what backend returns
        print('🔍 Apple login - Full user data from backend: $user');
        print('🔍 Apple login - profileCompleted raw value: ${user?['profileCompleted']}');
        print('🔍 Apple login - profileCompleted type: ${user?['profileCompleted']?.runtimeType}');

        // Check profileCompleted flag from backend
        // Only redirect to profile completion if explicitly set to false
        final bool profileCompleted = user?['profileCompleted'] ?? true;

        // User needs to complete profile only if backend says so
        final bool needsProfileCompletion = !profileCompleted;

        print(
            '🔍 Profile check: profileCompleted=$profileCompleted, needsCompletion=$needsProfileCompletion');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (needsProfileCompletion) {
            // Profile not completed - redirect to RegisterTwo
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => RegisterTwo(
                  name: user?['name'] ?? '',
                  email: user?['email'] ?? '',
                  password: '', // OAuth users don't have password
                  bio: user?['bio'] ?? 'Hello! I joined using Apple. 🍎',
                  gender: user?['gender'] ?? 'other',
                  nativeLanguage: '', // Force empty so user must select
                  languageToLearn: '', // Force empty so user must select
                  birthDate:
                      '${user?['birth_year'] ?? '2000'}.${user?['birth_month'] ?? '01'}.${user?['birth_day'] ?? '01'}',
                ),
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: BananaText(
                  'Welcome! Please complete your profile',
                  BanaStyles: BananaTextStyles.body,
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else {
            // Profile completed - check terms before going to main app
            // Check if user has accepted terms of service
            try {
              final loggedInUser = await ref.read(authServiceProvider).getLoggedInUser();
              if (!loggedInUser.termsAccepted) {
                // Show terms screen before entering app
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                );
                
                if (!mounted) return;
                
                // Re-check after terms acceptance
                final updatedUser = await ref.read(authServiceProvider).getLoggedInUser();
                if (!updatedUser.termsAccepted) {
                  // User didn't accept terms, stay on login screen
                  return;
                }
              }
            } catch (e) {
              // If we can't fetch user data, log out and redirect to home
              debugPrint('Error checking terms after Apple login: $e');
              await ref.read(authServiceProvider).logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const HomePage()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: BananaText(
                    'Session expired. Please login again.',
                    BanaStyles: BananaTextStyles.warning,
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            if (!mounted) return;

            // Register FCM token for push notifications
            try {
              final notificationService = NotificationService();
              final userId = ref.read(authServiceProvider).userId;
              if (userId.isNotEmpty) {
                await notificationService.registerToken(userId);
                debugPrint('✅ FCM token registered after Apple login');
              }
            } catch (e) {
              debugPrint('⚠️ Error registering FCM token after Apple login: $e');
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const TabsScreen()),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: BananaText(
                  'Welcome back, ${user?['name'] ?? 'User'}! 👋',
                  BanaStyles: BananaTextStyles.success,
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple sign-in error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
                          colors: [
                            Color(0xFF000000),
                            Color(0xFF434343),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                      'Sign in with Apple',
                      BanaStyles: BananaTextStyles.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    BananaText(
                      'Continue with your Apple ID\nfor a secure experience',
                      textAlign: TextAlign.center,
                      BanaStyles: BananaTextStyles.body,
                    ),

                    const SizedBox(height: 48),

                    // Loading or Button
                    if (_isLoading) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            BananaText(
                              'Signing you in...',
                              BanaStyles: BananaTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Apple Sign In Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: BananaButton(
                          BananaText: BananaText(
                            'Continue with Apple',
                            BanaStyles: BananaTextStyles.buttonText,
                          ),
                          onPressed: _signInWithApple,
                          color: Colors.black,
                          textColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          icon: const Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
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
                                child: const Text(
                                  'Try Again',
                                  style: TextStyle(
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
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                      ),
                      label: const Text(
                        'Back to sign-in methods',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
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
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Secured by Apple',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your privacy is protected with Apple Sign-In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
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
