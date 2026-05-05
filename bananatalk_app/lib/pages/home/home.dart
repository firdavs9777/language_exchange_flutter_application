import 'package:bananatalk_app/pages/authentication/login/apple_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/google_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/login_screen.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Center(
        child: Padding(
          padding: Spacing.paddingSM,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Bananatalk',
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
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              BananaText(
                'Connect, learn, and grow with our Language Exchange app',
                textAlign: TextAlign.center,
                BanaStyles: BananaTextStyles.titleLarge,
              ),
              const SizedBox(height: 35),
              BananaText(
                'Make global friends on Bananatalk.',
                textAlign: TextAlign.center,
                BanaStyles: BananaTextStyles.cardTitle,
              ),
              Padding(
                padding: Spacing.paddingLG,
                child: SizedBox(
                  height: 45.0,
                  width: 0.8 * MediaQuery.of(context).size.width,
                  child: BananaButton(
                    BananaText: BananaText('Sign In with Google'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const GoogleLogin(),
                        ),
                      );
                    },
                    color: const Color(0xFF4285F4), // Google blue color
                    textColor: AppColors.white,
                    borderRadius: AppRadius.borderSM,
                    icon: Icon(
                      Icons.g_mobiledata_rounded,
                      color: AppColors.white,
                      size: 26.0,
                    ),
                  ),
                ),
              ),

              if (Platform.isIOS) // ONLY SHOW ON iOS
                Padding(
                  padding: Spacing.paddingLG,
                  child: SizedBox(
                    height: 45.0,
                    width: 0.8 * MediaQuery.of(context).size.width,
                    child: BananaButton(
                      BananaText: BananaText('Sign In with Apple'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const AppleLogin(),
                          ),
                        );
                      },
                      color: AppColors.black, // Apple black color
                      textColor: AppColors.white,
                      borderRadius: AppRadius.borderSM,
                      icon: Icon(
                        Icons.apple,
                        color: AppColors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: Spacing.paddingSM,
                child: SizedBox(
                  height: 45.0,
                  width: 0.8 * MediaQuery.of(context).size.width,
                  child: BananaButton(
                    BananaText: BananaText('Sign in with Email'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => Login()),
                      );
                    },
                    color: context.isDarkMode ? AppColors.gray800 : AppColors.gray900,
                    textColor: AppColors.white,
                    borderRadius: AppRadius.borderSM,
                    icon: Icon(Icons.email, color: AppColors.white, size: 24.0),
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
