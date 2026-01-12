import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/language_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment variables loaded successfully');
  } catch (e) {
    debugPrint('❌ Error: Could not load .env file: $e');
    debugPrint('   Please ensure .env file exists in the project root with Firebase configuration.');
    debugPrint('   Copy .env.example to .env and fill in your values.');
    rethrow; // Fail fast if .env is missing
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
  }

  // Initialize socket service if user is logged in
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
      debugPrint('🔌 Initializing socket at app startup for user: $userId');
      await ChatSocketService().connect();
    } else {
      debugPrint('ℹ️ No token found - socket will connect after login');
    }
  } catch (e) {
    debugPrint('❌ Error initializing socket at startup: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

var kColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 96, 59, 181),
);
var kLightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 96, 59, 181),
);
var kDarkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 5, 99, 125),
);

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

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

    // Initialize call manager with socket service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final chatSocketService = ChatSocketService();
        final callNotifier = ref.read(callProvider.notifier);
        callNotifier.callManager.initialize(chatSocketService);
        debugPrint('✅ CallManager initialized');
      } catch (e) {
        debugPrint('❌ Error initializing CallManager: $e');
      }
    });

    return MaterialApp.router(
      routerConfig: goRouter,
      locale: locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
        Locale('ko', 'KR'),
        Locale('ru', 'RU'),
        Locale('es', 'ES'),
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: kLightColorScheme,
        scaffoldBackgroundColor: kLightColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: kLightColorScheme.surface,
          foregroundColor: kLightColorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: kLightColorScheme.surface,
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kLightColorScheme.primary,
            foregroundColor: kLightColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: ThemeData().textTheme.apply(
          bodyColor: kLightColorScheme.onSurface,
          displayColor: kLightColorScheme.onSurface,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: kDarkColorScheme,
        scaffoldBackgroundColor: kDarkColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: kDarkColorScheme.surface,
          foregroundColor: kDarkColorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: kDarkColorScheme.surface,
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkColorScheme.primary,
            foregroundColor: kDarkColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: kDarkColorScheme.onSurface,
          displayColor: kDarkColorScheme.onSurface,
        ),
      ),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
