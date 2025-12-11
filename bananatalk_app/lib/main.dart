import 'package:bananatalk_app/pages/home/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

var kColorScheme =
    ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 96, 59, 181));
var kLightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 96, 59, 181),
);
var kDarkColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromARGB(255, 5, 99, 125));

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: kLightColorScheme,
        scaffoldBackgroundColor: kLightColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: kLightColorScheme.surface,
          foregroundColor: kLightColorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardTheme(
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
        cardTheme: CardTheme(
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
      home: const SplashScreen(),
    );
  }
}
