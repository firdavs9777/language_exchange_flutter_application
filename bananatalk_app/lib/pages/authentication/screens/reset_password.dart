import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            l10n.pleaseFillAllFields,
            BanaStyles: BananaTextStyles.warning,
          ),
          backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            l10n.passwordsDoNotMatch,
            BanaStyles: BananaTextStyles.warning,
          ),
          backgroundColor: AppColors.error,
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
            l10n.passwordResetSuccessful,
            BanaStyles: BananaTextStyles.success,
          ),
          duration: Duration(seconds: 3),
          backgroundColor: AppColors.info,
        ),
      );

      // Navigate to login screen
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            result['message'] ?? 'Failed to reset password',
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: BananaText(
          l10n.resetPasswordTitle,
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
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
              Icon(
                Icons.lock_open,
                size: 60,
                color: AppColors.success,
              ),
              Spacing.gapLG,
              BananaText(
                l10n.createNewPassword,
                BanaStyles: BananaTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              Spacing.gapMD,
              Text(
                l10n.enterNewPasswordBelow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.containerColor,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    child: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: _obscureText ? context.iconColor : AppColors.info,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.password_outlined),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.dividerColor),
                    borderRadius: AppRadius.borderMD,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: AppRadius.borderMD,
                  ),
                  labelText: l10n.newPassword,
                ),
              ),
              Spacing.gapLG,
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureText_two,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.containerColor,
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
                      color: _obscureText_two ? context.iconColor : AppColors.info,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.password_outlined),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.dividerColor),
                    borderRadius: AppRadius.borderMD,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: AppRadius.borderMD,
                  ),
                  labelText: l10n.confirmPasswordLabel,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.resetPasswordTitle,
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
