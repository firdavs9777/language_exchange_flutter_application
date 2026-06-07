import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/animated_banana_title.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/version_check_coordinator.dart';
import 'package:bananatalk_app/services/welcome_back_service.dart';
import 'package:bananatalk_app/widgets/welcome_back_modal.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  RemoteMessage? _pendingNotification;
  late final AnimationController _entranceController;
  late final AnimationController _dotsController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Logo: 0 - 600ms — fade + scale-from-small
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Tagline: 500 - 1100ms — fade
    _taglineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await NotificationService().initialize(context: context);
      await NotificationService().clearBadge();
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _pendingNotification = initialMessage;
      }
    } catch (e) {}

    final authService = ref.read(authServiceProvider);
    final isAuthenticated = await authService.initializeAuth();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    await VersionCheckCoordinator().check(context);
    if (!mounted) return;

    final shouldShowWelcomeBack = await WelcomeBackService.checkAndMark();
    if (shouldShowWelcomeBack && mounted && isAuthenticated) {
      await showWelcomeBackModal(context);
      if (!mounted) return;
    }

    if (isAuthenticated) {
      final prefs = await SharedPreferences.getInstance();
      final termsAcceptedLocally =
          prefs.getBool('termsAcceptedLocally') ?? false;
      if (!termsAcceptedLocally) {
        try {
          final user = await authService.getLoggedInUser();
          final termsAccepted = user.termsAccepted;
          if (termsAccepted) {
            await prefs.setBool('termsAcceptedLocally', true);
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen(),
              ),
            );
            if (!mounted) return;
            final updatedLocalFlag =
                prefs.getBool('termsAcceptedLocally') ?? false;
            if (!updatedLocalFlag) {
              final updatedUser = await authService.getLoggedInUser();
              if (!updatedUser.termsAccepted) {
                return;
              }
            }
          }
        } catch (e) {}
      }
    }

    if (isAuthenticated) {
      context.go('/home');
      if (_pendingNotification != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _handlePendingNotification(_pendingNotification!.data);
        }
      }
    } else {
      context.go('/login');
    }
  }

  void _handlePendingNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    try {
      switch (type) {
        case 'chat_message':
          final senderId = data['senderId']?.toString();
          if (senderId != null) goRouter.push('/chat/$senderId');
          break;
        case 'moment_like':
        case 'moment_comment':
        case 'follower_moment':
          final momentId = data['momentId']?.toString();
          if (momentId != null) goRouter.push('/moment/$momentId');
          break;
        case 'friend_request':
        case 'profile_visit':
          final userId = data['userId']?.toString();
          if (userId != null) goRouter.push('/profile/$userId');
          break;
        case 'incoming_call':
          break;
        case 'missed_call':
          final callerId = data['callerId']?.toString();
          if (callerId != null) goRouter.push('/chat/$callerId');
          break;
        default:
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _dotsController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Brand gradient — soft teal in both modes (darker in dark mode).
    final List<Color> bgGradient = isDark
        ? const [Color(0xFF0B1F1C), Color(0xFF0F2E2A), Color(0xFF154A43)]
        : const [Color(0xFFF6FFFD), Color(0xFFE6FBF5), Color(0xFFB8F0E0)];
    final Color taglineColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF00695C).withValues(alpha: 0.65);
    final Color dotColor = isDark ? Colors.white : const Color(0xFF00897B);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Centered title + tagline (logo removed — typography-only)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subtle decorative accent: short colored bar above title
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        alignment: Alignment.center,
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const AnimatedBananaTitle(fontSize: 54),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        l10n.splashTagline,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: taglineColor,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom loader
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: _LoadingDots(controller: _dotsController, color: dotColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-dot indeterminate loader with staggered fade animation.
class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  const _LoadingDots({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // Each dot animates between 0.25 and 1.0 opacity with a staggered offset.
        final start = i * 0.2;
        final end = start + 0.6;
        final anim = Tween<double>(begin: 0.25, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeInOut),
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: FadeTransition(
            opacity: anim,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
