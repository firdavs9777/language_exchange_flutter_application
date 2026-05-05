import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/version_check_coordinator.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Store initial notification to handle after auth completes
  RemoteMessage? _pendingNotification;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notification service
    try {
      await NotificationService().initialize(context: context);

      // Clear app badge when app opens
      await NotificationService().clearBadge();

      // Check if app was opened from a notification (cold start)
      // Store it — we'll handle navigation AFTER auth completes
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _pendingNotification = initialMessage;
      }
    } catch (e) {}

    // Wait for auth initialization to complete
    final authService = ref.read(authServiceProvider);
    final isAuthenticated = await authService.initializeAuth();

    // Add minimum splash screen duration for better UX
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Version-update gate. For force-update this never returns (dialog is
    // non-dismissible and pins the user on splash). For soft prompts it
    // returns once the user dismisses, then navigation continues.
    await VersionCheckCoordinator().check(context);

    if (!mounted) return;

    // Check if user has accepted terms of service
    // Note: For new users, terms are shown during registration.
    // This check is for existing users who haven't accepted yet.
    if (isAuthenticated) {
      final prefs = await SharedPreferences.getInstance();
      final termsAcceptedLocally =
          prefs.getBool('termsAcceptedLocally') ?? false;

      // If terms already accepted locally, skip the network check entirely
      // This prevents logging users out when they're offline
      if (!termsAcceptedLocally) {
        try {
          final user = await authService.getLoggedInUser();
          final termsAccepted = user.termsAccepted;

          if (termsAccepted) {
            // Save locally so we don't need network next time
            await prefs.setBool('termsAcceptedLocally', true);
          } else {
            // Show terms screen - user cannot proceed without accepting
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen(),
              ),
            );

            if (!mounted) return;

            // Re-check local flag after terms screen
            final updatedLocalFlag =
                prefs.getBool('termsAcceptedLocally') ?? false;
            if (!updatedLocalFlag) {
              final updatedUser = await authService.getLoggedInUser();
              if (!updatedUser.termsAccepted) {
                return;
              }
            }
          }
        } catch (e) {
          // Network error - don't log the user out, just skip terms check
          // Terms will be checked again on next online launch
        }
      }
    }

    // Navigate based on authentication status
    if (isAuthenticated) {
      context.go('/home');

      // If app was opened from a notification, navigate to the target screen
      // after a short delay to let /home settle first
      if (_pendingNotification != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _handlePendingNotification(_pendingNotification!.data);
        }
      }
    } else {
      // Navigate to login page if not authenticated
      context.go('/login');
    }
  }

  /// Handle notification navigation without calling go('/home') again
  /// since we're already on /home — just push the target screen
  void _handlePendingNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';

    try {
      switch (type) {
        case 'chat_message':
          final senderId = data['senderId']?.toString();
          if (senderId != null) {
            goRouter.push('/chat/$senderId');
          }
          break;
        case 'moment_like':
        case 'moment_comment':
        case 'follower_moment':
          final momentId = data['momentId']?.toString();
          if (momentId != null) {
            goRouter.push('/moment/$momentId');
          }
          break;
        case 'friend_request':
        case 'profile_visit':
          final userId = data['userId']?.toString();
          if (userId != null) {
            goRouter.push('/profile/$userId');
          }
          break;
        case 'incoming_call':
          // Socket listener handles showing the call screen
          break;
        case 'missed_call':
          final callerId = data['callerId']?.toString();
          if (callerId != null) {
            goRouter.push('/chat/$callerId');
          }
          break;
        default:
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'BananaTalk',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MEET · CHAT · CONNECT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      letterSpacing: 2.0,
                    ),
                  ),
                  Spacing.gapXL,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
