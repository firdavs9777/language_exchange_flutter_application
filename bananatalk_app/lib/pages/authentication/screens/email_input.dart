import 'package:bananatalk_app/pages/authentication/screens/email_verification.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
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
            AppLocalizations.of(context)!.pleaseEnterEmailAddress,
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
            AppLocalizations.of(context)!.pleaseEnterValidEmail,
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
            AppLocalizations.of(context)!.verificationCodeSent,
            BanaStyles: BananaTextStyles.success,
          ),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BananaText(
          AppLocalizations.of(context)!.signUp,
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              alignment: Alignment.center,
              child: Text(
                'BananaTalk',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            BananaText(
              AppLocalizations.of(context)!.createAccount,
              BanaStyles: BananaTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            Spacing.gapMD,
            Text(
              AppLocalizations.of(context)!.enterEmailToGetStarted,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: context.textSecondary),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.containerColor,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: context.dividerColor),
                  borderRadius: AppRadius.borderMD,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                  borderRadius: AppRadius.borderMD,
                ),
                hintText: AppLocalizations.of(context)!.emailAddress,
                prefixIcon: Icon(Icons.email),
              ),
            ),
            Spacing.gapXXL,
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendVerificationCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context)!.continueText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            Spacing.gapXXL,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.alreadyHaveAnAccount,
                  style: TextStyle(color: context.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => Login()),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.login,
                    style: TextStyle(
                      color: AppColors.primary,
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
