import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
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
          const SnackBar(
              content: BananaText(
            'Verification code sent!',
            BanaStyles: BananaTextStyles.success,
          )),
        );
        handleNext();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: BananaText(
            '$error',
            BanaStyles: BananaTextStyles.error,
          )),
        );
      }
    }
  }

  Future<void> verifyVerificationCode() async {
    if (_codeController.text.isNotEmpty) {
      try {
        final response = await ref.read(authServiceProvider).verifyEmailCode(
            email: _emailController.text, code: _codeController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: BananaText(
            'Code successfully verified!',
            BanaStyles: BananaTextStyles.success,
          )),
        );
        handleNext();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: BananaText(
            '$error',
            BanaStyles: BananaTextStyles.error,
          )),
        );
      }
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
          const SnackBar(
              content: BananaText(
            'Password successfully reset!',
            BanaStyles: BananaTextStyles.success,
          )),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const Login()),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: BananaText(
            '$error',
            BanaStyles: BananaTextStyles.error,
          )),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: BananaText(
          'Passwords do not match.',
          BanaStyles: BananaTextStyles.error,
        )),
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
                  const BananaText("Reset your password",
                      BanaStyles: BananaTextStyles.heading),
                  const SizedBox(height: 24),
                  if (step == 1) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        label: BananaText('Enter your email',
                            BanaStyles: BananaTextStyles.labelText),
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: sendVerificationCode,
                        child: BananaText(
                          "Send Code",
                          BanaStyles: BananaTextStyles.buttonText,
                        ),
                      ),
                    ),
                  ],
                  if (step == 2) ...[
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        label: BananaText('Enter verification Code',
                            BanaStyles: BananaTextStyles.labelText),
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
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.black87,
                            ),
                            onPressed: handlePrevious,
                            child: BananaText(
                              'Back',
                              BanaStyles: BananaTextStyles.buttonText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.black87,
                            ),
                            onPressed: verifyVerificationCode,
                            child: BananaText(
                              'Next',
                              BanaStyles: BananaTextStyles.buttonText,
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
                        label: BananaText('New Password',
                            BanaStyles: BananaTextStyles.labelText),
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
                        label: BananaText('Confirm Password',
                            BanaStyles: BananaTextStyles.labelText),
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
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.black87),
                            onPressed: handlePrevious,
                            child: BananaText(
                              'Back',
                              BanaStyles: BananaTextStyles.buttonText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: handleResetPassword,
                            child: BananaText(
                              'Next',
                              BanaStyles: BananaTextStyles.buttonText,
                            ),
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
