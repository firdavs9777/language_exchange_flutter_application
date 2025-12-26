import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notification service
    try {
      await NotificationService().initialize(context: context);
      
      // Clear app badge when app opens
      await NotificationService().clearBadge();
      debugPrint('🔔 App badge cleared');
      
      // Handle notification tap (if app opened from notification)
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null && mounted) {
          // Delay navigation to let the app fully initialize
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              NotificationRouter.handleNotification(context, message.data);
            }
          });
        }
      });
      
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing notification service: $e');
    }
    
    // Wait for auth initialization to complete
    final authService = ref.read(authServiceProvider);
    final isAuthenticated = await authService.initializeAuth();
    
    // Add minimum splash screen duration for better UX
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user has accepted terms of service from backend
    // Note: For new users, terms are shown during registration.
    // This check is for existing users who haven't accepted yet.
    if (isAuthenticated) {
      try {
        final user = await authService.getLoggedInUser();
        final termsAccepted = user.termsAccepted;
        
        if (!termsAccepted) {
          // Show terms screen - user cannot proceed without accepting
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TermsOfServiceScreen(),
            ),
          );
          
          if (!mounted) return;
          
          // Re-check if terms were accepted after returning from terms screen
          final updatedUser = await authService.getLoggedInUser();
          if (!updatedUser.termsAccepted) {
            // If still not accepted, user may have closed the app
            // On next app launch, they'll see terms again (correct behavior)
            return;
          }
        }
      } catch (e) {
        // If we can't fetch user data, redirect to login screen
        // This handles cases where token is invalid or network issues
        debugPrint('Error checking terms acceptance: $e');
        if (!mounted) return;
        context.go('/login');
        return;
      }
    }
    
    // Navigate based on authentication status
    if (isAuthenticated) {
      context.go('/home');
    } else {
      // Navigate to login page if not authenticated
      context.go('/login');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simulate a loading delay

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo_no_background.png',
              width: 350,
              height: 321,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
