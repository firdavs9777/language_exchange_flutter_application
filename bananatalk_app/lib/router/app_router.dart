import 'package:bananatalk_app/pages/chat/chat_screen_wrapper.dart';
import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/home/splash_screen.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/moments/moment_detail_wrapper.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const HomePage()),
    GoRoute(path: '/home', builder: (context, state) => const TabsScreen()),
    GoRoute(
      path: '/tabs/:index',
      builder: (context, state) {
        final index = int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
        return TabsScreen(initialIndex: index);
      },
    ),
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ChatScreenWrapper(userId: userId);
      },
    ),
    GoRoute(
      path: '/moment/:momentId',
      builder: (context, state) {
        final momentId = state.pathParameters['momentId']!;
        return MomentDetailWrapper(momentId: momentId);
      },
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileWrapper(userId: userId);
      },
    ),
  ],
);
