import 'dart:io';
import 'package:bananatalk_app/pages/authentication/screens/register_second.dart';
import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/notification_service.dart';
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
      '28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo.apps.googleusercontent.com';

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
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🚀 STEP 1: Initializing GoogleSignIn');
      debugPrint('   Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');

      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        // iOS uses clientId, Android uses serverClientId
        clientId: Platform.isIOS ? _iosClientId : null,
        serverClientId: Platform.isAndroid ? _webClientId : null,
      );

      debugPrint('🔑 STEP 2: Client IDs configured');
      debugPrint('   iOS Client ID: $_iosClientId');
      debugPrint('   Web Client ID (for Android): $_webClientId');
      debugPrint('   Android Client ID (for backend): $_androidClientId');
      debugPrint('   Using: ${Platform.isIOS ? _iosClientId : _webClientId}');

      // Sign out any previously signed-in account to force account picker
      // This ensures the account selection popup appears when user has multiple accounts
      debugPrint('🔄 STEP 3: Signing out previous session...');
      await googleSignIn.signOut();
      debugPrint('✅ Previous session signed out');

      // Small delay to ensure sign out completes
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('📱 STEP 4: Launching Google Sign-In UI...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ STEP 4 FAILED: User cancelled Google sign-in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('✅ STEP 4 SUCCESS: Google user signed in');
      debugPrint('   Email: ${googleUser.email}');
      debugPrint('   Display Name: ${googleUser.displayName}');
      debugPrint('   ID: ${googleUser.id}');
      debugPrint('   Photo URL: ${googleUser.photoUrl}');

      debugPrint('🎫 STEP 5: Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('✅ STEP 5 SUCCESS: Got authentication object');
      debugPrint('   Access Token: ${googleAuth.accessToken != null ? '${googleAuth.accessToken!.substring(0, 20)}...' : 'NULL'}');

      final String? idToken = googleAuth.idToken;
      debugPrint('   ID Token: ${idToken != null ? '${idToken.substring(0, 50)}...' : 'NULL'}');

      if (idToken == null) {
        debugPrint('❌ STEP 5 FAILED: ID Token is NULL!');
        debugPrint('   This usually means:');
        debugPrint('   - Wrong Client ID configured');
        debugPrint('   - SHA-1 fingerprint mismatch (Android)');
        debugPrint('   - Bundle ID mismatch (iOS)');
        setState(() {
          _errorMessage = 'Failed to get ID token from Google. Please check configuration.';
          _isLoading = false;
        });
        return;
      }

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🌐 STEP 6: Sending ID token to backend...');
      debugPrint('   Endpoint: ${Endpoints.baseURL}auth/google/mobile');
      debugPrint('   ID Token length: ${idToken.length} chars');

      final result = await ref
          .read(authServiceProvider)
          .signInWithGoogleNative(idToken);

      debugPrint('📡 STEP 6 RESPONSE:');
      debugPrint('   Success: ${result['success']}');
      debugPrint('   Message: ${result['message']}');
      debugPrint('   Has Token: ${result['token'] != null}');
      debugPrint('   Has User: ${result['user'] != null}');
      if (result['user'] != null) {
        debugPrint('   User ID: ${result['user']['_id']}');
        debugPrint('   User Email: ${result['user']['email']}');
      }
      if (result['success'] == true) {
        // Get user data from response
        final user = result['user'] as Map<String, dynamic>?;

        // Debug: Log the full user object to see what backend returns
        debugPrint('🔍 Google login - Full user data from backend: $user');
        debugPrint('🔍 Google login - profileCompleted raw value: ${user?['profileCompleted']}');
        debugPrint('🔍 Google login - profileCompleted type: ${user?['profileCompleted']?.runtimeType}');

        // Check profileCompleted flag from backend
        // IMPORTANT: Default to FALSE for safety - new users must complete profile
        final bool profileCompleted = user?['profileCompleted'] == true;

        // Also check if essential fields are filled (extra safety check)
        final gender = user?['gender']?.toString() ?? '';
        final bio = user?['bio']?.toString() ?? '';
        final birthYear = user?['birth_year']?.toString() ?? '';
        final images = user?['images'] as List? ?? [];

        final bool hasEssentialFields =
            gender.isNotEmpty &&
            bio.isNotEmpty &&
            birthYear.isNotEmpty &&
            images.length >= 2;

        // User needs to complete profile if either flag is false OR essential fields missing
        final bool needsProfileCompletion = !profileCompleted || !hasEssentialFields;

        debugPrint('═══════════════════════════════════════');
        debugPrint('🔍 PROFILE COMPLETION CHECK:');
        debugPrint('   profileCompleted flag: $profileCompleted');
        debugPrint('   hasEssentialFields: $hasEssentialFields');
        debugPrint('   needsCompletion: $needsProfileCompletion');
        debugPrint('───────────────────────────────────────');
        debugPrint('📝 User Profile Data:');
        debugPrint('   name: ${user?['name']}');
        debugPrint('   email: ${user?['email']}');
        debugPrint('   gender: ${user?['gender']}');
        debugPrint('   bio: ${user?['bio']}');
        debugPrint('   birth_year: ${user?['birth_year']}');
        debugPrint('   images count: ${(user?['images'] as List?)?.length ?? 0}');
        debugPrint('   native_language: ${user?['native_language']}');
        debugPrint('   language_to_learn: ${user?['language_to_learn']}');
        debugPrint('═══════════════════════════════════════');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (needsProfileCompletion) {
            // Profile NOT completed - redirect to RegisterTwo
            debugPrint('❌ Profile incomplete - redirecting to RegisterTwo');

            // Get values from backend - use empty strings to force user input
            final birthYear = user?['birth_year']?.toString() ?? '';
            final birthMonth = user?['birth_month']?.toString() ?? '';
            final birthDay = user?['birth_day']?.toString() ?? '';

            // Only use birthdate if all parts are present and valid
            String birthDate = '';
            if (birthYear.isNotEmpty && birthMonth.isNotEmpty && birthDay.isNotEmpty) {
              birthDate = '$birthYear.${birthMonth.padLeft(2, '0')}.${birthDay.padLeft(2, '0')}';
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => RegisterTwo(
                  name: user?['name'] ?? '',
                  email: user?['email'] ?? '',
                  password: '', // OAuth users don't have password
                  bio: user?['bio'] ?? '', // Empty - user must write bio
                  gender: user?['gender'] ?? '', // Empty - user must select
                  nativeLanguage: '', // Force empty so user must select
                  languageToLearn: '', // Force empty so user must select
                  birthDate: birthDate, // Empty if not set - user must select
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
            // Profile IS completed - check terms before going to main app
            debugPrint('✅ Profile complete - checking terms acceptance');

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
              debugPrint('Error checking terms after Google login: $e');
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

            // NOW connect socket - profile is complete and terms accepted
            try {
              debugPrint('🔌 Connecting socket (profile complete)...');
              final chatSocketService = ChatSocketService();
              chatSocketService.enableReconnection();
              await chatSocketService.connect();
              debugPrint('✅ Chat socket connected after Google login');
            } catch (e) {
              debugPrint('⚠️ Error connecting chat socket: $e');
            }

            // Register FCM token for push notifications
            try {
              final notificationService = NotificationService();
              final userId = ref.read(authServiceProvider).userId;
              if (userId.isNotEmpty) {
                await notificationService.registerToken(userId);
                debugPrint('✅ FCM token registered after Google login');
              }
            } catch (e) {
              debugPrint(
                '⚠️ Error registering FCM token after Google login: $e',
              );
            }

            // Invalidate userProvider to force fresh fetch
            ref.invalidate(userProvider);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const TabsScreen()),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: BananaText(
                  'Welcome back, ${user?['name']}! 👋',

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
        debugPrint('❌ Backend authentication failed: ${result['message']}');
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to authenticate with backend';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('❌ GOOGLE SIGN-IN ERROR:');
      debugPrint('   Error: $e');
      debugPrint('   Type: ${e.runtimeType}');
      debugPrint('   Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('═══════════════════════════════════════════════════════════');

      String userFriendlyMessage = 'Google sign-in error';

      // Parse common errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network')) {
        userFriendlyMessage = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('canceled') || errorString.contains('cancelled')) {
        userFriendlyMessage = 'Sign-in was cancelled.';
      } else if (errorString.contains('configuration') || errorString.contains('client')) {
        userFriendlyMessage = 'Configuration error. Please contact support.';
      } else if (errorString.contains('10:')) {
        userFriendlyMessage = 'Developer error (10). SHA-1 fingerprint may be incorrect.';
      } else if (errorString.contains('12500')) {
        userFriendlyMessage = 'Google Play services error. Please update Google Play services.';
      } else if (errorString.contains('12501')) {
        userFriendlyMessage = 'Sign-in was cancelled.';
      } else if (errorString.contains('7:')) {
        userFriendlyMessage = 'Network error (7). Please check your connection.';
      }

      setState(() {
        _errorMessage = '$userFriendlyMessage\n\nDetails: ${e.toString()}';
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
                          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
