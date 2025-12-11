import 'package:bananatalk_app/pages/authentication/screens/apple_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/facebook_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/google_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
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
      backgroundColor: Colors.white,
      body: Container(
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
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
              SizedBox(
                height: 35,
              ),
              BananaText('Make global friends on BananaTalk.',
                  textAlign: TextAlign.center,
                  BanaStyles: BananaTextStyles.cardTitle),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 45.0,
                  width: 0.8 *
                      MediaQuery.of(context).size.width, // 90% of screen width
                  child: BananaButton(
                    BananaText: BananaText('Sign In with Google'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (ctx) => const GoogleLogin()),
                      );
                    },
                    color: Color(0xFF4285F4), // Google blue color
                    textColor: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    icon: Icon(
                      Icons.g_mobiledata_rounded, // Google icon
                      color: Colors.white,
                      size: 26.0,
                    ),
                  ),
                ),
              ),

              if (Platform.isIOS) // ONLY SHOW ON iOS
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 45.0,
                    width: 0.8 * MediaQuery.of(context).size.width,
                    child: BananaButton(
                      BananaText: BananaText('Sign In with Apple'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (ctx) => const AppleLogin()),
                        );
                      },
                      color: Colors.black, // Apple black color
                      textColor: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      icon: Icon(
                        Icons.apple, // Apple icon
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),

              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Container(
              //     height: 45.0,
              //     width: 0.8 *
              //         MediaQuery.of(context).size.width, // 90% of screen width
              //     child: BananaButton(
              //       BananaText: BananaText('Sign In with Facebook'),
              //       onPressed: () {
              //         Navigator.of(context).push(
              //           MaterialPageRoute(builder: (ctx) => FacebookLogin()),
              //         );
              //       },
              //       color: Color(0xFF1877F2), // Facebook blue color
              //       textColor: Color(0xFFFFFFFF),
              //       borderRadius: BorderRadius.circular(8),
              //       icon: Icon(
              //         Icons.facebook,
              //         color: Colors.white,
              //         size: 24.0,
              //       ),
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 45.0,
                  width: 0.8 *
                      MediaQuery.of(context).size.width, // 90% of screen width
                  child: BananaButton(
                    BananaText: BananaText('Sign in with Email'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => Login()),
                      );
                    },
                    color: Colors.black87,
                    textColor: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    icon: Icon(
                      Icons.email,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
