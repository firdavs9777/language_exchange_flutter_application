import 'package:bananatalk_app/pages/authentication/screens/email_verification.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class EmailInput extends ConsumerStatefulWidget {
  const EmailInput({super.key});

  @override
  ConsumerState<EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends ConsumerState<EmailInput> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Please enter your email address',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final emailPattern = r'^[^@]+@[^@]+\.[^@]+';
    final emailRegex = RegExp(emailPattern);

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Please enter a valid email address',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Use your authServiceProvider
    final result =
        await ref.read(authServiceProvider).sendVerificationCode(email);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Verification code sent to your email!',
            BanaStyles: BananaTextStyles.success,
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to verification screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EmailVerification(email: email),
        ),
      );
    } else {
      // Handle error - check if it's a registration validation error (wrong endpoint)
      String errorMessage = result['message'] ?? 'Failed to send verification code';
      
      // If the error contains registration validation messages, it means wrong endpoint
      if (errorMessage.contains('language to learn') || 
          errorMessage.contains('native language') ||
          errorMessage.contains('birth day') ||
          errorMessage.contains('password')) {
        errorMessage = 'Server configuration error. Please contact support.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            errorMessage,
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BananaText(
          'Sign Up',
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              child: Image.asset(
                'assets/images/logo_no_background.png',
                height: 120,
              ),
            ),
            BananaText(
              'Create Account',
              BanaStyles: BananaTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Enter your email to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 40),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: AppLocalizations.of(context)!.emailAddress,
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendVerificationCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => Login()),
                    );
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
