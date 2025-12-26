import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 60, color: Colors.red.shade700),
                      const SizedBox(height: 16),
                      BananaText(
                        'Warning: This action is permanent!',
                        BanaStyles: BananaTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Deleting your account will permanently remove:\n\n'
                        '• Your profile and all personal data\n'
                        '• All your messages and conversations\n'
                        '• All your moments and stories\n'
                        '• Your VIP subscription (no refund)\n'
                        '• All your connections and followers\n\n'
                        'This action cannot be undone.',
                        textAlign: TextAlign.left,
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (!widget.isOAuthUser) ...[
                  BananaText('Enter your password',
                      BanaStyles: BananaTextStyles.title),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.yourPassword,
                      helperText: 'Required for email accounts only',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                  const SizedBox(height: 24),
                ],
                BananaText('Type DELETE to confirm',
                    BanaStyles: BananaTextStyles.title),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeDELETEInCapitalLetters,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.delete_forever),
                  ),
                  validator: (value) => value != 'DELETE'
                      ? 'You must type DELETE to confirm'
                      : null,
                ),
                const SizedBox(height: 32),
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
                    color: Colors.red,
                    textColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
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
