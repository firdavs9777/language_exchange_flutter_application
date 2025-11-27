import 'package:bananatalk_app/pages/authentication/screens/email_input.dart';
import 'package:bananatalk_app/pages/authentication/screens/facebook_login.dart';
import 'package:bananatalk_app/pages/authentication/screens/forget_password_email.dart';
import 'package:bananatalk_app/pages/authentication/screens/google_login.dart';
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
  bool _isLoading = false;

  void submit() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Please enter both email and password',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate email format
    if (!AuthService.validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Please enter a valid email address',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ref.read(authServiceProvider).login(
            email: email,
            password: password,
          );

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
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
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle different error types
        String errorMessage =
            response['message'] ?? 'Login failed. Please try again.';

        // Show appropriate error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BananaText(
              errorMessage,
              BanaStyles: BananaTextStyles.error,
            ),
            duration: Duration(seconds: response['isLocked'] == true ? 5 : 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Network error: ${error.toString()}',
            BanaStyles: BananaTextStyles.error,
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
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
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF31A062)),
                                ),
                              )
                            : BananaButton(
                                onPressed: submit,
                                color: Color(0xFF31A062),
                                BananaText: BananaText(
                                  'Login',
                                  BanaStyles: BananaTextStyles.buttonText,
                                ),
                                textColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 12.0),
                                borderRadius: BorderRadius.circular(8.0),
                              )),
                    SizedBox(height: 24.0),
                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey[400],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: BananaText(
                            'OR',
                            BanaStyles: BananaTextStyles.body,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey[400],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.0),
                    // Social Login Buttons
                    SizedBox(
                      width: 250.0,
                      child: Column(
                        children: [
                          // Facebook Login Button
                          // Container(
                          //   width: double.infinity,
                          //   height: 50,
                          //   margin: const EdgeInsets.only(bottom: 12.0),
                          //   decoration: BoxDecoration(
                          //     borderRadius: BorderRadius.circular(20),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: const Color(0xFF1877F2).withOpacity(0.3),
                          //         blurRadius: 8,
                          //         offset: const Offset(0, 4),
                          //       ),
                          //     ],
                          //   ),
                          //   child: ElevatedButton.icon(
                          //     onPressed: () {
                          //       Navigator.of(context).push(
                          //         MaterialPageRoute(
                          //           builder: (ctx) => const FacebookLogin(),
                          //         ),
                          //       );
                          //     },
                          //     icon: const Icon(
                          //       Icons.facebook,
                          //       color: Colors.white,
                          //       size: 24,
                          //     ),
                          //     label: BananaText(
                          //       'Continue with Facebook',
                          //       BanaStyles: BananaTextStyles.buttonText,
                          //     ),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: const Color(0xFF1877F2),
                          //       foregroundColor: Colors.white,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(20),
                          //       ),
                          //       elevation: 0,
                          //     ),
                          //   ),
                          // ),
                          // Google Login Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4285F4).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => const GoogleLogin(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.g_mobiledata_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              label: BananaText(
                                'Continue with Google',
                                BanaStyles: BananaTextStyles.buttonText,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => const ForgotPasswordEmail()));
                          },
                          child: BananaText(
                            'Forgot password?',
                            BanaStyles: BananaTextStyles.link,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => const EmailInput()));
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
