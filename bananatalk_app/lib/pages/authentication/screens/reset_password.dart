import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPassword extends ConsumerStatefulWidget {
  final String email;
  final String code;

  const ResetPassword({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  ConsumerState<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPassword> {
  bool _obscureText = true;
  bool _obscureText_two = true;
  bool _isLoading = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Please fill in all fields',
            BanaStyles: BananaTextStyles.warning,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use AuthService password validation
    final passwordValidation = AuthService.validatePassword(password);
    if (!passwordValidation['valid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            passwordValidation['message'] ??
                'Password does not meet requirements',
            BanaStyles: BananaTextStyles.warning,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Passwords do not match',
            BanaStyles: BananaTextStyles.warning,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authServiceProvider).resetPassword(
          email: widget.email,
          code: widget.code,
          newPassword: password,
        );

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            'Password reset successful! Please login with your new password',
            BanaStyles: BananaTextStyles.success,
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => Login()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            result['message'] ?? 'Failed to reset password',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: Duration(seconds: 3),
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
          'Reset Password',
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                width: 200,
                child: Image.asset(
                  'assets/images/logo_no_background.png',
                  height: 120,
                  width: 180,
                ),
              ),
              Icon(
                Icons.lock_open,
                size: 60,
                color: Colors.green,
              ),
              SizedBox(height: 16),
              BananaText(
                'Create New Password',
                BanaStyles: BananaTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Enter your new password below',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 40),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    child: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: _obscureText ? Colors.grey : Colors.blue,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.password_outlined),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'New Password',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureText_two,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Confirm Password',
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Reset Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
