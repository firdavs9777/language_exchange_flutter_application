import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/language_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    rethrow; // Fail fast if .env is missing
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  } catch (e) {
  }

  // Initialize socket and notification services if user is logged in
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    // Setup API client token refresh callback to reconnect socket
    final apiClient = ApiClient();
    final chatSocketService = ChatSocketService();
    apiClient.onTokenRefreshed = () {
      chatSocketService.refreshConnection();
    };

    if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
      await chatSocketService.connect();

      // Initialize notification service for logged-in users
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.registerToken(userId);
    } else {
    }
  } catch (e) {
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
  LanguageNotifier() : super(LanguageService.getLocale(LanguageService.getDeviceLanguage())) {
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);

    // Initialize global chat listener to keep badge count updated
    // This ensures badge updates even when ChatMain isn't visible
    // Using ref.watch ensures it stays active and re-initializes if needed
    ref.watch(globalChatListenerProvider);

    // Initialize call manager with socket service and global incoming call handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final chatSocketService = ChatSocketService();
        final callNotifier = ref.read(callProvider.notifier);
        callNotifier.callManager.initialize(chatSocketService);

        // Notify UI when call connects (for timer, status updates)
        callNotifier.setCallConnectedCallback((call) {
          debugPrint('📞 Call connected - UI notified');
        });

        // Register global incoming call handler using overlay navigator
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
      } catch (e) {
        debugPrint('❌ Call manager init error: $e');
      }
    });

    return MaterialApp.router(
      routerConfig: goRouter,
      locale: locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ko', 'KR'),
        Locale('zh', 'CN'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
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
      ],
      localizationsDelegates: [
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
        // Apply global text scaling limits for accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          // Overlay navigator for full-screen overlays (incoming calls, etc.)
          // Sits above GoRouter so pop() doesn't affect GoRouter's route stack
          child: Navigator(
            key: callOverlayNavigatorKey,
            onPopPage: (route, result) => route.didPop(result),
            pages: [MaterialPage(child: child ?? const SizedBox())],
          ),
        );
      },
    );
  }
}
