// import 'package:bananatalk/features/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/authentication/screens/register.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // decoration: const BoxDecoration(
        //   gradient: LinearGradient(
        //       colors: [Colors.deepPurple, Colors.pinkAccent],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight),
        // ),
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
              Text(
                'Connect, learn, and grow with our Language Exchange app',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 35,
              ),
              Text(
                'Make global friends on BananaTalk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              SizedBox(
                height: 45,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 45.0,
                  width: 0.9 *
                      MediaQuery.of(context)
                          .size
                          .width, // 90% of the screen width
                  child: BananaButton(
                    text: 'Create an Account',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (ctx) =>
                                Register()), // Make sure you have the Register screen imported
                      );
                    },
                    color: Color(0xFF31A062),
                    textColor: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    height: 45.0,
                    width: 0.9 *
                        MediaQuery.of(context)
                            .size
                            .width, // 90% of the screen width
                    child: BananaButton(
                      text: 'Login',
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      textColor: Color(0xFF31A062),
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => const Login()));
                      },
                      color: Colors.transparent,
                    )),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
