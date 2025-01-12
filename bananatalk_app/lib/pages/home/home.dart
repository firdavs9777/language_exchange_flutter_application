import 'package:bananatalk_app/pages/authentication/screens/login.dart';
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 45.0,
                  width: 0.8 *
                      MediaQuery.of(context).size.width, // 90% of screen width
                  child: BananaButton(
                    text: 'Sign In with Facebook',
                    onPressed: () {
                      // Implement your Facebook login logic here
                    },
                    color: Color(0xFF1877F2), // Facebook blue color
                    textColor: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    icon: Icon(
                      Icons
                          .facebook, // You can also use a custom image if needed
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 45.0,
                  width: 0.8 *
                      MediaQuery.of(context).size.width, // 90% of screen width
                  child: BananaButton(
                    text: 'Sign in with Email',
                    onPressed: () {
                      // Implement your Facebook login logic here
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (ctx) =>
                                Login()), // Make sure you have the Register screen imported
                      );
                    },
                    color: Colors.black87, // Facebook blue color
                    textColor: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    icon: Icon(
                      Icons.email, // You can also use a custom image if needed
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
