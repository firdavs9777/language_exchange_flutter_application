import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/chat/chat_screen_wrapper.dart';
import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/home/splash_screen.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/moments/moment_detail_wrapper.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/pages/matching/smart_matching_screen.dart';
import 'package:bananatalk_app/pages/learning/leaderboard_screen.dart';
import 'package:bananatalk_app/screens/call_history_screen.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Transition helpers
// Each returns a CustomTransitionPage so route definitions stay concise.
// ---------------------------------------------------------------------------

/// Slide from the right edge + fade in. Standard push feel.
CustomTransitionPage<void> _buildSlideTransition({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeOutCubic,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: curve);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Pure fade in. Good for shell-level replacements (home, tabs).
CustomTransitionPage<void> _buildFadeTransition({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeOut,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: curve),
        child: child,
      );
    },
  );
}

/// Fade + slight scale-up from 0.95. Content-detail feel (moments).
CustomTransitionPage<void> _buildScaleTransition({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeOutCubic,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: curve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Slide up from the bottom + fade in. Modal-style feel (matching).
CustomTransitionPage<void> _buildSlideUpTransition({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 350),
  Curve curve = Curves.easeOutCubic,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: curve);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

// ---------------------------------------------------------------------------

/// Global navigator key for overlay screens (incoming calls, etc.)
/// This is NOT GoRouter's navigator — it sits above it in the widget tree.
final callOverlayNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // No animation — instant display for the splash screen.
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    ),

    // Fade in — first screen the user sees after splash.
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildFadeTransition(
        state: state,
        child: const HomePage(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    ),

    // Fade in — replacing the whole app shell.
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildFadeTransition(
        state: state,
        child: const TabsScreen(),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    ),
    GoRoute(
      path: '/tabs/:index',
      pageBuilder: (context, state) {
        final index = int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
        return _buildFadeTransition(
          state: state,
          child: TabsScreen(initialIndex: index),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    ),

    // Slide from right + fade — standard navigation push feel.
    GoRoute(
      path: '/chat/:userId',
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return _buildSlideTransition(
          state: state,
          child: ChatScreenWrapper(userId: userId),
        );
      },
    ),

    // Fade + scale up — content detail feel.
    GoRoute(
      path: '/moment/:momentId',
      pageBuilder: (context, state) {
        final momentId = state.pathParameters['momentId']!;
        return _buildSlideUpTransition(
          state: state,
          child: MomentDetailWrapper(momentId: momentId),
        );
      },
    ),

    // Slide from right + fade — standard navigation push feel.
    GoRoute(
      path: '/profile/:userId',
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return _buildSlideTransition(
          state: state,
          child: ProfileWrapper(userId: userId),
        );
      },
    ),

    // Slide up from bottom + fade — modal feel.
    GoRoute(
      path: '/matching',
      pageBuilder: (context, state) => _buildSlideUpTransition(
        state: state,
        child: const SmartMatchingScreen(),
      ),
    ),

    // Slide from right + fade — standard navigation push feel.
    GoRoute(
      path: '/leaderboard',
      pageBuilder: (context, state) =>
          _buildSlideTransition(state: state, child: const LeaderboardScreen()),
    ),

    // Slide from right + fade — standard navigation push feel.
    GoRoute(
      path: '/call-history',
      pageBuilder: (context, state) =>
          _buildSlideTransition(state: state, child: const CallHistoryScreen()),
    ),
  ],
);
