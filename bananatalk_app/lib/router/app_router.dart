import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/chat/chat_screen_wrapper.dart';
import 'package:bananatalk_app/pages/coins/boost_screen.dart';
import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/home/splash_screen.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/moments/moment_detail_wrapper.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen_wrapper.dart';
import 'package:bananatalk_app/pages/matching/smart_matching_screen.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_picker_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_dashboard_screen.dart';
import 'package:bananatalk_app/pages/learning/main/learning_main_screen.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/screens/call_history_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/referral_service.dart'
    show pendingReferralPrefsKey, shouldStorePendingReferral;

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

/// Landing for `community/matches|waves` deep links: requests the Community
/// sub-tab, then shows the tab shell on Community.
class _CommunitySubTabLanding extends ConsumerStatefulWidget {
  const _CommunitySubTabLanding({required this.subTab});
  final int subTab;

  @override
  ConsumerState<_CommunitySubTabLanding> createState() =>
      _CommunitySubTabLandingState();
}

class _CommunitySubTabLandingState
    extends ConsumerState<_CommunitySubTabLanding> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(communityPendingSubTabProvider.notifier).state =
            widget.subTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) => const TabsScreen(initialIndex: 1);
}

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

    // Invite deep link: remember the code, then let the splash screen make
    // its usual auth decision (-> /home when logged in, /login otherwise).
    GoRoute(
      path: '/invite/:code',
      redirect: (context, state) async {
        final code = state.pathParameters['code'];
        if (code != null && code.isNotEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            if (shouldStorePendingReferral(
              code: code,
              sessionToken: prefs.getString('token'),
            )) {
              await prefs.setString(
                pendingReferralPrefsKey,
                code.toUpperCase(),
              );
            }
          } catch (_) {}
        }
        return '/splash';
      },
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
        final prefill = state.uri.queryParameters['prefill'];
        return _buildSlideTransition(
          state: state,
          child: ChatScreenWrapper(userId: userId, prefillMessage: prefill),
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

    // 모임 — deep-link-only, same shape and the same reason as `/room/:roomId`
    // below. The detail screen fetches by id itself, so unlike
    // `RoomScreenWrapper` no wrapper is needed: the id IS the whole argument.
    //
    // Without this route a gathering reminder push taps through to the
    // home screen. That matters more here than for most types: the 24h
    // reminder is the notification spec §5 calls load-bearing, and a reminder
    // that does not open the thing it is reminding you about is most of the
    // way to not being a reminder.
    GoRoute(
      path: '/gathering/:gatheringId',
      pageBuilder: (context, state) {
        final gatheringId = state.pathParameters['gatheringId']!;
        return _buildSlideTransition(
          state: state,
          child: GatheringDetailScreen(gatheringId: gatheringId),
        );
      },
    ),
    // Slide from right + fade — standard navigation push feel.
    // Rooms are otherwise only reached via `Navigator.push` from within the
    // Community tab (there's no directory-by-id GoRoute), so this is
    // deep-link-only — Task 16 (client layer C) added it so
    // `NotificationRouter` can push straight into a topic-room/hub instead
    // of only as far as the Community tab.
    GoRoute(
      path: '/room/:roomId',
      pageBuilder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return _buildSlideTransition(
          state: state,
          child: RoomScreenWrapper(roomId: roomId),
        );
      },
    ),

    // Slide from right + fade — standard navigation push feel.
    // `SingleCommunity` (rendered via `ProfileWrapper`) is the same detail
    // screen used for `/profile/:userId` — a community member IS a
    // `Community` record, loaded by id, so we reuse the existing
    // fetch-by-id wrapper rather than introducing a near-duplicate one.
    // Must precede `/community/:communityId` so these literals win.
    GoRoute(
      path: '/community/matches',
      pageBuilder: (context, state) => _buildFadeTransition(
        state: state,
        child: const _CommunitySubTabLanding(subTab: communityMatchesSubTab),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    ),
    GoRoute(
      path: '/community/waves',
      pageBuilder: (context, state) => _buildFadeTransition(
        state: state,
        child: const _CommunitySubTabLanding(subTab: communityWavesSubTab),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    ),
    GoRoute(
      path: '/community/:communityId',
      pageBuilder: (context, state) {
        final communityId = state.pathParameters['communityId']!;
        return _buildSlideTransition(
          state: state,
          child: ProfileWrapper(userId: communityId),
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
    // `daily_drop` push notifications deep-link here. There is no route for
    // `DailyDropScreen` itself — it requires a `DailyItem` (plus submit
    // callbacks) that a bare notification payload cannot supply — so this
    // opens the Study Hub instead, the closest real surface, same as the
    // `srs_review`/`streak_reminder` "closest available surface" fallback.
    GoRoute(
      path: '/learning/daily',
      pageBuilder: (context, state) =>
          _buildSlideTransition(state: state, child: const LearningMain()),
    ),

    // `boost_receipt` push notifications deep-link here (behind boostsEnabled
    // server-side; the push is only sent when boosts are live).
    GoRoute(
      path: '/boost',
      pageBuilder: (context, state) =>
          _buildSlideTransition(state: state, child: const BoostScreen()),
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

    // Exam Study — picker (pushed from the AI Study tab when a language
    // card is tapped). The selected ExamLanguage is passed via `extra`
    // so the screen has the full object without re-fetching by id.
    GoRoute(
      path: '/exam-study/language/:languageId',
      pageBuilder: (context, state) {
        final language = state.extra as ExamLanguage?;
        if (language == null) {
          // No extra passed — fall back to a benign empty screen rather
          // than crash. Should only happen on a hand-typed deep link.
          return _buildSlideTransition(
            state: state,
            child: const Scaffold(
              body: Center(child: Text('Language not provided')),
            ),
          );
        }
        return _buildSlideTransition(
          state: state,
          child: ExamPickerScreen(language: language),
        );
      },
    ),

    // Exam Study — dashboard for a specific exam. Receives the full
    // ExamType via `extra` so we render meta/description without an
    // extra round-trip.
    GoRoute(
      path: '/exam-study/exam/:examId',
      pageBuilder: (context, state) {
        final exam = state.extra as ExamType?;
        if (exam == null) {
          return _buildSlideTransition(
            state: state,
            child: const Scaffold(
              body: Center(child: Text('Exam not provided')),
            ),
          );
        }
        return _buildSlideTransition(
          state: state,
          child: ExamDashboardScreen(exam: exam),
        );
      },
    ),
  ],
);
