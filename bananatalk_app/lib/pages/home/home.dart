import 'package:bananatalk_app/pages/authentication/screens/apple_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/google_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
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
              Image.asset(
                'assets/images/logo_no_background.png',
                height: 300,
                width: 300,
              ),
              BananaText(
                'Connect, learn, and grow with our Language Exchange app',
                textAlign: TextAlign.center,
                BanaStyles: BananaTextStyles.titleLarge,
              ),
              const SizedBox(height: 35),
              BananaText(
                'Make global friends on BananaTalk.',
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
