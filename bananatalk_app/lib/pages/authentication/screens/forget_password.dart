import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/authentication/screens/reset_password.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgetPassword extends ConsumerStatefulWidget {
  const ForgetPassword({super.key});

  @override
  _ForgetPasswordState createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends ConsumerState<ForgetPassword> {
  int step = 3;
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _codeController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void handleNext() {
    setState(() {
      step++;
    });
  }

  void handlePrevious() {
    if (step > 1) {
      setState(() {
        step--;
      });
    }
  }

  Future<void> sendVerificationCode() async {
    if (_emailController.text.isNotEmpty) {
      try {
        final response = await ref
            .read(authServiceProvider)
            .sendEmailCode(email: _emailController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent!')),
        );
        handleNext();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      // TODO: Implement API call
    }
  }

  Future<void> verifyVerificationCode() async {
    if (_codeController.text.isNotEmpty) {
      try {
        final response = await ref.read(authServiceProvider).verifyEmailCode(
            email: _emailController.text, code: _codeController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code successfully verified!')),
        );
        handleNext();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      // TODO: Implement API call
    }
  }

  Future<void> handleResetPassword() async {
    final email = _emailController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword == confirmPassword) {
      try {
        final response = await ref
            .read(authServiceProvider)
            .resetPassword(email: email, newPassword: newPassword);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password successfully reset!')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const Login()),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password',
            style: TextStyle(color: colorScheme.onPrimaryContainer)),
        backgroundColor: colorScheme.onPrimary,
      ),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Form(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset('assets/images/logo_no_background.png',
                      height: 100, width: 180),
                  const SizedBox(height: 16),
                  Text(
                    'Reset your password',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(height: 24),
                  if (step == 1) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: sendVerificationCode,
                      child: const Text('Send Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                  if (step == 2) ...[
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Enter verification code',
                        prefixIcon: const Icon(Icons.verified),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: handlePrevious,
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: verifyVerificationCode,
                            child: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (step == 3) ...[
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: handlePrevious,
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: handleResetPassword,
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
