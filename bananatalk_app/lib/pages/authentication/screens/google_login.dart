import 'dart:io';
import 'package:bananatalk_app/pages/authentication/screens/register_second.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLogin extends ConsumerStatefulWidget {
  const GoogleLogin({super.key});

  @override
  ConsumerState<GoogleLogin> createState() => _GoogleLoginState();
}

class _GoogleLoginState extends ConsumerState<GoogleLogin> {
  bool _isLoading = false;
  String? _errorMessage;
  static const String _iosClientId =
      '810869785173-6jl1i1b32lghpsdq6lp92a7b1vuedoh4.apps.googleusercontent.com';

  // Android uses WEB client ID (NOT the Android client ID!)
  static const String _webClientId =
      '810869785173-aktt02a6oberoemnuce1i58jtj803sq5.apps.googleusercontent.com';

  // This is ONLY for backend validation (optional)
  static const String _androidClientId =
      '810869785173-7r5qlkcuje3fmcg0b92cnkmgglsulank.apps.googleusercontent.com';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use native Google Sign-In for iOS & Android, web flow for others
      if (Platform.isIOS || Platform.isAndroid) {
        await _signInWithGoogleNative();
      } else {
        // For Android/Web, use WebView approach
        await _signInWithGoogleWebView();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogleNative() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        // Use the Web client ID for Android
        clientId: Platform.isIOS ? _iosClientId : _webClientId,
      );
      print(googleSignIn.clientId);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() {
          _errorMessage = 'Failed to get ID token from Google';
          _isLoading = false;
        });
        return;
      }

      final result =
          await ref.read(authServiceProvider).signInWithGoogleNative(idToken);

      if (result['success'] == true) {
        // Get user data from response - use 'user' not 'userData'
        final user = result['user'] as Map<String, dynamic>?;

        // Check profileCompleted flag from backend (not isRegistrationComplete)
        final bool profileCompleted = user?['profileCompleted'] ?? true;

        // Secondary check: Look for default values
        final bool hasDefaultValues = user?['native_language'] == 'English' &&
            user?['language_to_learn'] == 'Korean' &&
            user?['gender'] == 'other' &&
            user?['birth_year'] == '2000';

        // User needs to complete profile if flag is false OR has default values
        final bool needsProfileCompletion =
            !profileCompleted || hasDefaultValues;

        print(
            '🔍 Profile check: profileCompleted=$profileCompleted, hasDefaultValues=$hasDefaultValues, needsCompletion=$needsProfileCompletion');

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
                  bio: user?['bio'] ?? 'Hello! I joined using Google. 👋',
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
            // Profile completed - go to main app
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
        _errorMessage = 'Google sign-in error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogleWebView() async {
    setState(() {
      _errorMessage = 'WebView login not yet implemented for this platform';
      _isLoading = false;
    });
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

                    // Google Logo with gradient background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4285F4),
                            Color(0xFF34A853),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4285F4).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    BananaText(
                      'Sign in with Google',
                      BanaStyles: BananaTextStyles.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    BananaText(
                      Platform.isIOS || Platform.isAndroid
                          ? 'Continue with your Google account\nfor a seamless experience'
                          : 'You will be redirected to Google\nfor secure authentication',
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
                                  Color(0xFF4285F4),
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
                      // Google Sign In Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4285F4).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: BananaButton(
                          BananaText: BananaText(
                            'Continue with Google',
                            BanaStyles: BananaTextStyles.buttonText,
                          ),
                          onPressed: _signInWithGoogle,
                          color: const Color(0xFF4285F4),
                          textColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          icon: const Icon(
                            Icons.g_mobiledata_rounded,
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
                                  _signInWithGoogle();
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
                                'Secured by Google',
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
                            'Your data is protected with industry-standard encryption',
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
