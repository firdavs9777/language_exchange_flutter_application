import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  final bool isOAuthUser; // Google, Facebook, or Apple user

  const DeleteAccountScreen({
    super.key,
    required this.isOAuthUser,
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

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const HomePage()),
            (route) => false,
          );
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
        title: Text('Delete Account', style: context.titleLarge.copyWith(color: AppColors.white)),
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
                      BananaText(
                        'Warning: This action is permanent!',
                        BanaStyles: BananaTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Deleting your account will permanently remove:\n\n'
                        '• Your profile and all personal data\n'
                        '• All your messages and conversations\n'
                        '• All your moments and stories\n'
                        '• Your VIP subscription (no refund)\n'
                        '• All your connections and followers\n\n'
                        'This action cannot be undone.',
                        textAlign: TextAlign.left,
                        style: context.bodyMedium.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                if (!widget.isOAuthUser) ...[
                  BananaText('Enter your password',
                      BanaStyles: BananaTextStyles.title),
                  SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.yourPassword,
                      helperText: 'Required for email accounts only',
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
                        ? 'Please enter your password'
                        : null,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                ],
                BananaText('Type DELETE to confirm',
                    BanaStyles: BananaTextStyles.title),
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
                      ? 'You must type DELETE to confirm'
                      : null,
                ),
                SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: BananaButton(
                    BananaText: BananaText(
                      _isLoading
                          ? 'Deleting Account...'
                          : 'Delete My Account Permanently',
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
                    child: Text('Cancel', style: context.titleMedium),
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
