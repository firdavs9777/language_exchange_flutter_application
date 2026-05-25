import 'package:bananatalk_app/router/app_router.dart'
    show goRouter, callOverlayNavigatorKey;
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/language_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/widgets/tutor/persona_upgrade_sheet.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/pages/authentication/account_suspended_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent system UI; per-screen AnnotatedRegion overrides will
  // handle icon brightness based on theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Load environment variables (fail fast if .env is missing).
  await dotenv.load(fileName: '.env');

  // Initialize Firebase + Ads
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Step 13A: Analytics. Initialized after Firebase.initializeApp().
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    await AdService().initialize();
  } catch (e, stack) {
    debugPrint('❌ Firebase/Ads initialization failed: $e');
    if (kDebugMode) debugPrintStack(stackTrace: stack);
  }

  // Initialize socket + notifications if user is logged in.
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    final apiClient = ApiClient();
    final chatSocketService = ChatSocketService();
    apiClient.onTokenRefreshed = () {
      chatSocketService.refreshConnection();
    };

    // Step 13A: route 429 quota_exceeded responses to the persona paywall
    // sheet via the existing call-overlay navigator key (sits above
    // GoRouter so the sheet appears on top of any route).
    apiClient.onQuotaExceeded = (qe) {
      final overlayCtx = callOverlayNavigatorKey.currentContext;
      if (overlayCtx == null) return;
      showModalBottomSheet(
        context: overlayCtx,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => PersonaUpgradeSheet(triggerChip: qe.feature),
      );
      AnalyticsService.instance.quotaHit(chipName: qe.feature, tier: 'free');
    };

    // Step 14 (safety wave): banned-account 403 → clear token + push the
    // AccountSuspendedScreen via the global overlay navigator (sits above
    // GoRouter — same key used by the quota paywall above).
    apiClient.onAccountSuspended = (reason) async {
      // Best-effort logout — clears token + cached auth state. Even if it
      // fails, the navigation below still terminates the user's session UX.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('userId');
      } catch (e) {
        debugPrint('[suspended] token cleanup failed: $e');
      }
      final overlayNav = callOverlayNavigatorKey.currentState;
      if (overlayNav == null) return;
      // Pop overlay/stack the user can't navigate back from. pushAndRemoveUntil
      // with (_) => false clears the entire overlay route stack; the persistent
      // GoRouter app underneath is unreachable until the suspended screen is
      // dismissed (which only happens on app restart, by design).
      overlayNav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AccountSuspendedScreen(reason: reason),
        ),
        (_) => false,
      );
    };

    if (token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty) {
      await chatSocketService.connect();

      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.registerToken(userId);
    }
  } catch (e, stack) {
    debugPrint('❌ Socket/notification setup failed: $e');
    if (kDebugMode) debugPrintStack(stackTrace: stack);
  }

  runApp(const ProviderScope(child: MyApp()));
}

// Theme provider with persistence
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('app_theme') ?? 'system';
    state = _stringToThemeMode(themeString);
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', _themeModeToString(mode));
    state = mode;
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  // Use device language synchronously as initial state to avoid English flash
  LanguageNotifier()
    : super(LanguageService.getLocale(LanguageService.getDeviceLanguage())) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final languageCode = await LanguageService.getAppLanguage();
    state = LanguageService.getLocale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    await LanguageService.setAppLanguage(languageCode);
    state = LanguageService.getLocale(languageCode);
  }

  /// Reset to use system language (clears saved preference)
  Future<void> useSystemLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_language');
    final deviceLanguage = LanguageService.getDeviceLanguage();
    state = LanguageService.getLocale(deviceLanguage);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _callManagerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize call manager once after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCallManager();
    });
  }

  void _initializeCallManager() {
    if (_callManagerInitialized) return;
    try {
      final chatSocketService = ChatSocketService();
      final callNotifier = ref.read(callProvider.notifier);
      callNotifier.callManager.initialize(chatSocketService);

      callNotifier.setCallConnectedCallback((call) {
        debugPrint('📞 Call connected - UI notified');
      });

      callNotifier.setIncomingCallCallback((call) {
        final navState = callOverlayNavigatorKey.currentState;
        if (navState != null) {
          debugPrint('📞 Incoming call from ${call.userName} - showing screen');
          navState.push(
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(call: call),
              fullscreenDialog: true,
            ),
          );
        } else {
          debugPrint('❌ Cannot show incoming call - no navigator');
        }
      });

      _callManagerInitialized = true;
    } catch (e, stack) {
      debugPrint('❌ Call manager init error: $e');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);

    // Keep global chat listener active so badge counts update everywhere.
    ref.watch(globalChatListenerProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      locale: locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ko', 'KR'),
        Locale('zh', 'CN'),
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('it', 'IT'),
        Locale('pt', 'BR'),
        Locale('ru', 'RU'),
        Locale('ar', 'SA'),
        Locale('hi', 'IN'),
        Locale('ja', 'JP'),
        Locale('id', 'ID'),
        Locale('th', 'TH'),
        Locale('tl', 'PH'),
        Locale('tr', 'TR'),
        Locale('vi', 'VN'),
        Locale('tg', 'TJ'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Use locale-aware themes (NanumSquare Neo for Korean, system font for others)
      theme: AppTheme.lightWithLocale(locale),
      darkTheme: AppTheme.darkWithLocale(locale),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply theme-aware system UI overlay style globally + clamp text scale.
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
              ),
            ),
            // Overlay navigator for full-screen overlays (incoming calls, etc.)
            // Sits above GoRouter so pop() doesn't affect GoRouter's route stack.
            child: Navigator(
              key: callOverlayNavigatorKey,
              onPopPage: (route, result) => route.didPop(result),
              pages: [MaterialPage(child: child ?? const SizedBox())],
            ),
          ),
        );
      },
    );
  }
}
