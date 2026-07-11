import 'package:bananatalk_app/pages/authentication/auth_error_codes.dart';
import 'package:bananatalk_app/pages/authentication/register/register_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/otp_code_field.dart';
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

class _EmailVerificationState extends ConsumerState<EmailVerification>
    with TickerProviderStateMixin {
  final GlobalKey<OtpCodeFieldState> _otpKey = GlobalKey<OtpCodeFieldState>();

  bool _isLoading = false;
  bool _isResending = false;
  bool _isSuccess = false;
  int _resendTimer = 60;
  Timer? _timer;

  late final AnimationController _successController;
  late final Animation<double> _successScale;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutBack,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _pulseResendButton() {
    if (MediaQuery.of(context).disableAnimations) return;
    _pulseController.forward(from: 0).then((_) {
      if (!mounted) return;
      _pulseController.reverse();
    });
  }

  Future<void> _verifyCode([String? completedCode]) async {
    if (_isLoading) return;

    final String code = completedCode ?? '';
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

    final result = await ref
        .read(authServiceProvider)
        .verifyEmailCode(email: widget.email, code: code);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      setState(() => _isSuccess = true);
      await _successController.forward(from: 0);

      if (!mounted) return;

      showAuthSnackBar(
        context,
        message: l10n.emailVerifiedSuccessfully,
        type: AuthSnackBarType.success,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => Register(userEmail: widget.email)),
      );
    } else {
      final AuthErrorCode errorCode = parseAuthErrorCode(
        result['code']?.toString(),
      );

      switch (errorCode) {
        case AuthErrorCode.codeExpired:
          showAuthSnackBar(
            context,
            message:
                result['message'] ??
                'This code has expired. Please '
                    'request a new one.',
            type: AuthSnackBarType.error,
          );
          // Surface the resend affordance immediately instead of making the
          // user wait out the countdown for a code we already know is dead,
          // and draw the eye to it with a brief pulse.
          setState(() => _resendTimer = 0);
          _timer?.cancel();
          _pulseResendButton();
          break;
        case AuthErrorCode.codeInvalid:
          _otpKey.currentState?.shakeAndClear();
          showAuthSnackBar(
            context,
            message: result['message'] ?? 'Incorrect code. Please try again.',
            type: AuthSnackBarType.error,
          );
          break;
        default:
          showAuthSnackBar(
            context,
            message: result['message'] ?? 'Verification failed',
            type: AuthSnackBarType.error,
          );
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendTimer > 0) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isResending = true);

    final result = await ref
        .read(authServiceProvider)
        .sendVerificationCode(widget.email);

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
          if (_isSuccess)
            ScaleTransition(
              scale: _successScale,
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: AppColors.success,
              ),
            )
          else
            Icon(Icons.email_outlined, size: 80, color: AppColors.primary),
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
          // 6-digit OTP input
          Center(
            child: OtpCodeField(
              key: _otpKey,
              length: 6,
              onCompleted: _verifyCode,
            ),
          ),
          const SizedBox(height: 40),
          AuthGradientButton(
            label: l10n.verify,
            onPressed: _isLoading
                ? null
                : () => _verifyCode(_otpKey.currentState?.value),
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
              ScaleTransition(
                scale: _pulseScale,
                child: TextButton(
                  onPressed: _isResending || _resendTimer > 0
                      ? null
                      : _resendCode,
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
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
