import 'package:bananatalk_app/pages/authentication/screens/register_second.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookLogin extends ConsumerStatefulWidget {
  const FacebookLogin({super.key});

  @override
  ConsumerState<FacebookLogin> createState() => _FacebookLoginState();
}

class _FacebookLoginState extends ConsumerState<FacebookLogin> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // try {
    // Trigger Facebook login
    // final LoginResult result = await FacebookAuth.instance.login(
    //   permissions: ['email', 'public_profile'],
    // );
    //
    // if (result.status == LoginStatus.success) {
    //   // Get the access token
    //   final AccessToken accessToken = result.accessToken!;
    //
    //   print(
    //       '✅ Facebook login successful - token: ${accessToken.tokenString}');
    //
    //   // Send access token to backend
    //   final backendResult = await ref
    //       .read(authServiceProvider)
    //       .signInWithFacebookNative(accessToken.tokenString);

    // if (backendResult['success'] == true) {
    //   // Get user data from response
    //   final user = backendResult['user'] as Map<String, dynamic>?;
    //
    //   // Check profileCompleted flag from backend
    //   final bool profileCompleted = user?['profileCompleted'] ?? true;
    //
    //   // Secondary check: Look for default values
    //   final bool hasDefaultValues = user?['native_language'] == 'English' &&
    //       user?['language_to_learn'] == 'Korean' &&
    //       user?['gender'] == 'other' &&
    //       user?['birth_year'] == '2000';
    //
    //   // User needs to complete profile if flag is false OR has default values
    //   final bool needsProfileCompletion =
    //       !profileCompleted || hasDefaultValues;

    // print(
    //     '🔍 Profile check: profileCompleted=$profileCompleted, hasDefaultValues=$hasDefaultValues, needsCompletion=$needsProfileCompletion');

    setState(() {
      _isLoading = false;
    });

    // if (mounted) {
    //   if (needsProfileCompletion) {
    //     // Profile not completed - redirect to RegisterTwo
    //     Navigator.of(context).pushReplacement(
    //       MaterialPageRoute(
    //         builder: (ctx) => RegisterTwo(
    //           name: user?['name'] ?? '',
    //           email: user?['email'] ?? '',
    //           password: '', // OAuth users don't have password
    //           bio: user?['bio'] ?? 'Hello! I joined using Facebook. 👋',
    //           gender: user?['gender'] ?? 'other',
    //           nativeLanguage: '', // Force empty so user must select
    //           languageToLearn: '', // Force empty so user must select
    //           birthDate:
    //               '${user?['birth_year'] ?? '2000'}.${user?['birth_month'] ?? '01'}.${user?['birth_day'] ?? '01'}',
    //         ),
    //       ),
    //     );
    //
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: BananaText(
    //           'Welcome! Please complete your profile',
    //           BanaStyles: BananaTextStyles.body,
    //         ),
    //         duration: const Duration(seconds: 3),
    //         backgroundColor: Colors.orange,
    //         behavior: SnackBarBehavior.floating,
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(10),
    //         ),
    //       ),
    //     );
    //   } else {
    //     // Profile completed - go to main app
    //     Navigator.of(context).pushReplacement(
    //       MaterialPageRoute(builder: (ctx) => const TabsScreen()),
    //     );
    //
    //           ScaffoldMessenger.of(context).showSnackBar(
    //             SnackBar(
    //               content: BananaText(
    //                 'Welcome back, ${user?['name'] ?? 'User'}! 👋',
    //                 BanaStyles: BananaTextStyles.success,
    //               ),
    //               duration: const Duration(seconds: 2),
    //               backgroundColor: Colors.green,
    //               behavior: SnackBarBehavior.floating,
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(10),
    //               ),
    //             ),
    //           );
    //         }
    //       }
    //     } else {
    //       setState(() {
    //         _errorMessage = backendResult['message'] ??
    //             'Failed to authenticate with backend';
    //         _isLoading = false;
    //       });
    //     }
    //   } else if (result.status == LoginStatus.cancelled) {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //     print('❌ Facebook login cancelled by user');
    //   } else {
    //     setState(() {
    //       _errorMessage = 'Facebook login failed: ${result.message}';
    //       _isLoading = false;
    //     });
    //     print('❌ Facebook login failed: ${result.message}');
    //   }
    // } catch (e) {
    //   setState(() {
    //     _errorMessage = 'Facebook sign-in error: ${e.toString()}';
    //     _isLoading = false;
    //   });
    //   print('❌ Facebook sign-in exception: $e');
    // }
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

                    // Facebook Logo with gradient background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1877F2),
                            Color(0xFF0C63D4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1877F2).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.facebook,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    BananaText(
                      'Sign in with Facebook',
                      BanaStyles: BananaTextStyles.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    BananaText(
                      'Continue with your Facebook account\nfor a seamless experience',
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
                                  Color(0xFF1877F2),
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
                      // Facebook Sign In Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: BananaButton(
                          BananaText: BananaText(
                            'Continue with Facebook',
                            BanaStyles: BananaTextStyles.buttonText,
                          ),
                          onPressed: _signInWithFacebook,
                          color: const Color(0xFF1877F2),
                          textColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          icon: const Icon(
                            Icons.facebook,
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
                                  _signInWithFacebook();
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
                                'Secured by Facebook',
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
