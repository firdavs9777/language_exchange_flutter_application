import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/authentication/screens/register_second.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  final String userName;
  final String userEmail; // This is now pre-verified
  final String userPassword;
  final String userBio;
  final String? userGender;
  final String? userNativeLang;
  final String? userLearnLang;
  final String userBirthDate;

  const Register({
    super.key,
    this.userName = '',
    required this.userEmail, // Make this required since email is verified
    this.userPassword = '',
    this.userBio = '',
    this.userGender = '',
    this.userNativeLang = '',
    this.userLearnLang = '',
    this.userBirthDate = '',
  });

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscureText = true;
  bool _obscureText_two = true;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _passwordConfirmController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _passwordController = TextEditingController(text: widget.userPassword);
    _emailController = TextEditingController(text: widget.userEmail);
    _passwordConfirmController =
        TextEditingController(text: widget.userPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void submit() {
    // Validate name and passwords only (email is already verified)
    if (_nameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Please fill in all fields.',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Password validation using AuthService helper
    final passwordValidation =
        AuthService.validatePassword(_passwordController.text);
    if (!passwordValidation['valid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            passwordValidation['message'] ??
                'Password does not meet requirements.',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Password match validation
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Passwords do not match.',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Navigate to next step with verified email
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RegisterTwo(
          name: _nameController.text,
          email: widget.userEmail, // Use verified email from widget
          password: _passwordController.text,
          bio: widget.userBio,
          gender: widget.userGender ?? 'Male',
          nativeLanguage: widget.userNativeLang ?? 'English',
          languageToLearn: widget.userLearnLang ?? 'Korean',
          birthDate: widget.userBirthDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BananaText(
          'Register',
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                child: Column(
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(top: 10, left: 20, right: 20),
                      width: 200,
                      child: Image.asset(
                        'assets/images/logo_no_background.png',
                        height: 120,
                        width: 180,
                      ),
                    ),
                    Center(
                      child: BananaText(
                        'Complete Your Profile',
                        BanaStyles: BananaTextStyles.heading,
                      ),
                    ),
                    SizedBox(height: 10.0),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        hintText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Email field (READ-ONLY - already verified)
                    TextFormField(
                      controller: _emailController,
                      enabled: false, // Make it read-only
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[300], // Show it's disabled
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        suffixIcon: Icon(
                          Icons.verified,
                          color: Colors.green,
                        ), // Show verified icon
                      ),
                    ),
                    SizedBox(height: 10),

                    // Password field
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
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Confirm password field
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: _obscureText_two,
                      decoration: InputDecoration(
                        filled: true,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureText_two = !_obscureText_two;
                            });
                          },
                          child: Icon(
                            _obscureText_two
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: _obscureText_two ? Colors.grey : Colors.blue,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.password_outlined),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    SizedBox(
                      width: 200.0,
                      child: ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                        child: Text(
                          'Next',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => Login()),
                      );
                    },
                    child: Text('Already have an account?'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => Login()),
                      );
                    },
                    child: Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
