// import 'package:bananatalk/features/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/authentication/screens/register.dart';
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
                  child: ElevatedButton(
                    onPressed: () => {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (ctx) => Register()))
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFF31A062)),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Set your custom border radius
                        ),
                      ), // Set your custom background color
                    ),
                    child: Text(
                      'Create an Account',
                      style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
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
                  child: TextButton(
                    onPressed: () => {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const Login()))
                    },
                    style: ButtonStyle(

                        // Set your custom background color
                        ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                          color: Color(0xFF31A062),
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
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
