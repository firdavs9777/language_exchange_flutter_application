import 'package:bananatalk_app/pages/authentication/screens/forget_password.dart';
import 'package:bananatalk_app/pages/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Login extends ConsumerStatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _obscureText = true;
  void submit() async {
    try {
      await ref.read(authServiceProvider).login(
            email: _emailController.text,
            password: _passwordController.text,
          );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => TabsScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Login Successful!',
            BanaStyles: BananaTextStyles.success,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Invalid Credientals,please check it again',
            BanaStyles: BananaTextStyles.error,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: BananaText(
          'Login',
          BanaStyles: BananaTextStyles.title,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                width: 200,
                child: Image.asset(
                  'assets/images/logo_no_background.png',
                  height: 120,
                  width: 180,
                ),
              ),
              Center(
                child: BananaText(
                  'Login',
                  BanaStyles: BananaTextStyles.title,
                ),
              ),
              SizedBox(height: 16.0),
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      textCapitalization: TextCapitalization.none,
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_sharp),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        label: BananaText(
                          'Email',
                          BanaStyles: BananaTextStyles.inputText,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        filled: true,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          child: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: _obscureText ? Colors.grey : Colors.blue,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.password_outlined),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        label: BananaText(
                          'Password',
                          BanaStyles: BananaTextStyles.inputText,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.0),
                    SizedBox(
                        width: 250.0,
                        child: BananaButton(
                          onPressed: submit,
                          color: Color(0xFF31A062),
                          BananaText: BananaText(
                            'Login',
                            BanaStyles: BananaTextStyles.buttonText,
                          ),
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 12.0),
                          borderRadius: BorderRadius.circular(8.0),
                        )),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => const ForgetPassword()));
                          },
                          child: BananaText(
                            'Forgot password?',
                            BanaStyles: BananaTextStyles.link,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => const Register()));
                          },
                          child: BananaText(
                            'Register',
                            BanaStyles: BananaTextStyles.link,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
