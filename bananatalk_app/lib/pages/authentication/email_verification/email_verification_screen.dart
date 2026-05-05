import 'package:bananatalk_app/pages/authentication/register/register_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class EmailVerification extends ConsumerStatefulWidget {
  final String email;

  const EmailVerification({super.key, required this.email});

  @override
  ConsumerState<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends ConsumerState<EmailVerification> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final String code = _controllers.map((c) => c.text).join();
    final l10n = AppLocalizations.of(context)!;

    if (code.length != 6) {
      showAuthSnackBar(
        context,
        message: l10n.pleaseEnterAll6Digits,
        type: AuthSnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authServiceProvider).verifyEmailCode(
          email: widget.email,
          code: code,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showAuthSnackBar(
        context,
        message: l10n.emailVerifiedSuccessfully,
        type: AuthSnackBarType.success,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => Register(userEmail: widget.email),
        ),
      );
    } else {
      showAuthSnackBar(
        context,
        message: result['message'] ?? 'Verification failed',
        type: AuthSnackBarType.error,
      );
    }
  }

  Future<void> _resendCode() async {
    if (_resendTimer > 0) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isResending = true);

    final result =
        await ref.read(authServiceProvider).sendVerificationCode(widget.email);

    setState(() => _isResending = false);

    if (!mounted) return;

    if (result['success']) {
      showAuthSnackBar(
        context,
        message: l10n.verificationCodeResent,
        type: AuthSnackBarType.success,
      );
      _startResendTimer();
    } else {
      showAuthSnackBar(
        context,
        message: result['message'] ?? 'Failed to resend code',
        type: AuthSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScreenScaffold(
      title: l10n.verifyEmail,
      showBackButton: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.email_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.verifyYourEmail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.weSentCodeTo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: context.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          // 6-digit code input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 45,
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: context.containerColor,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    // Auto-submit when all 6 digits are entered
                    if (index == 5 && value.isNotEmpty) {
                      _verifyCode();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          AuthGradientButton(
            label: l10n.verify,
            onPressed: _isLoading ? null : _verifyCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.didntReceiveCode,
                style: TextStyle(color: context.textSecondary),
              ),
              TextButton(
                onPressed:
                    _isResending || _resendTimer > 0 ? null : _resendCode,
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _resendTimer > 0
                            ? l10n.resendWithTimer(_resendTimer.toString())
                            : l10n.resend,
                        style: TextStyle(
                          color: _resendTimer > 0
                              ? context.textMuted
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
