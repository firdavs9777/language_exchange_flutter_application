import 'package:bananatalk_app/pages/authentication/screens/forgot_password_verification.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ForgotPasswordEmail extends ConsumerStatefulWidget {
  const ForgotPasswordEmail({super.key});

  @override
  ConsumerState<ForgotPasswordEmail> createState() =>
      _ForgotPasswordEmailState();
}

class _ForgotPasswordEmailState extends ConsumerState<ForgotPasswordEmail> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
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

    final result = await ref.read(authServiceProvider).sendPasswordResetCode(
          email: email,
        );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            AppLocalizations.of(context)!.resetCodeSent,
            BanaStyles: BananaTextStyles.success,
          ),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to verification screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ForgotPasswordVerification(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            result['message'] ?? 'Failed to send reset code',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: Duration(seconds: 3),
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
          AppLocalizations.of(context)!.forgotPasswordTitle,
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
            Icon(
              Icons.lock_reset,
              size: 80,
              color: AppColors.error,
            ),
            Spacing.gapXXL,
            BananaText(
              AppLocalizations.of(context)!.resetPasswordTitle,
              BanaStyles: BananaTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            Spacing.gapMD,
            Text(
              AppLocalizations.of(context)!.enterEmailForResetCode,
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
                  borderSide: BorderSide(color: AppColors.error, width: 2),
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
                onPressed: _isLoading ? null : _sendResetCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context)!.sendResetCode,
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
                  AppLocalizations.of(context)!.rememberYourPassword,
                  style: TextStyle(color: context.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.login,
                    style: TextStyle(
                      color: AppColors.error,
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
