import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  final bool isOAuthUser; // Google, Facebook, or Apple user
  final bool isGoogleUser;
  final bool isAppleUser;

  const DeleteAccountScreen({
    super.key,
    required this.isOAuthUser,
    this.isGoogleUser = false,
    this.isAppleUser = false,
  });

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Final confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.finalWarning),
        content: Text(
          '${AppLocalizations.of(context)!.thisActionCannotBeUndone} All your data will be permanently deleted.\n\nAre you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.deleteForever),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Disconnect Google account before deletion (revokes access)
      if (widget.isGoogleUser) {
        try {
          final googleSignIn = GoogleSignIn();
          await googleSignIn.disconnect(); // Revokes Google access + sign out
        } catch (_) {
          // Don't block deletion if Google disconnect fails
        }
      }

      // Apple token revocation is handled server-side (requires client secret)

      final result = await ref.read(authServiceProvider).deleteAccount(
            password: widget.isOAuthUser ? null : _passwordController.text,
            confirmText: _confirmController.text,
          );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Account deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );

          context.go('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete account'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.deleteAccount, style: context.titleLarge.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXXL,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: AppSpacing.paddingXL,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.errorLight,
                    borderRadius: AppRadius.borderMD,
                    border: Border.all(
                      color: context.isDarkMode
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 60, color: AppColors.error),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        AppLocalizations.of(context)!.warningPermanent,
                        style: context.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        AppLocalizations.of(context)!.deleteAccountWarning,
                        textAlign: TextAlign.left,
                        style: context.bodyMedium.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                if (!widget.isOAuthUser) ...[
                  Text(AppLocalizations.of(context)!.enterYourPassword,
                      style: context.titleMedium),
                  SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.yourPassword,
                      helperText: AppLocalizations.of(context)!.requiredForEmailOnly,
                      helperStyle: context.caption,
                      border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? AppLocalizations.of(context)!.pleaseEnterPassword
                        : null,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                ],
                Text(AppLocalizations.of(context)!.typeDELETE,
                    style: context.titleMedium),
                SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeDELETEInCapitalLetters,
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMD),
                    prefixIcon: const Icon(Icons.delete_forever),
                  ),
                  validator: (value) => value != 'DELETE'
                      ? AppLocalizations.of(context)!.mustTypeDELETE
                      : null,
                ),
                SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: BananaButton(
                    BananaText: BananaText(
                      _isLoading
                          ? AppLocalizations.of(context)!.deletingAccount
                          : AppLocalizations.of(context)!.deleteMyAccountPermanently,
                      BanaStyles: BananaTextStyles.buttonText,
                    ),
                    onPressed: _isLoading ? null : _deleteAccount,
                    color: AppColors.error,
                    textColor: AppColors.white,
                    borderRadius: AppRadius.borderMD,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.white),
                            ),
                          )
                        : Icon(Icons.delete_forever, color: AppColors.white),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMD),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancel, style: context.titleMedium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
