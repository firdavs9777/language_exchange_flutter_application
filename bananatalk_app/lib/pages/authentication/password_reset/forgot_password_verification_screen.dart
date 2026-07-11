import 'package:bananatalk_app/pages/authentication/auth_error_codes.dart';
import 'package:bananatalk_app/pages/authentication/password_reset/reset_password_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/animated_auth_background.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_error_state.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_screen_scaffold.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:bananatalk_app/pages/authentication/widgets/otp_code_field.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class ForgotPasswordVerification extends ConsumerStatefulWidget {
  final String email;

  const ForgotPasswordVerification({super.key, required this.email});

  @override
  ConsumerState<ForgotPasswordVerification> createState() =>
      _ForgotPasswordVerificationState();
}

class _ForgotPasswordVerificationState
    extends ConsumerState<ForgotPasswordVerification> {
  final GlobalKey<OtpCodeFieldState> _otpKey = GlobalKey<OtpCodeFieldState>();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  // Non-null when the last attempt failed with a network/lockout/rate-limit
  // error — renders AuthErrorState in-body instead of the raw OTP form.
  AuthErrorKind? _errorKind;
  Duration? _errorRetryAfter;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
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

  Future<void> _verifyCode(String completedCode) async {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorKind = null;
      _errorRetryAfter = null;
    });

    Map<String, dynamic> result;
    try {
      result = await ref
          .read(authServiceProvider)
          .verifyPasswordResetCode(email: widget.email, code: completedCode);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorKind = AuthErrorKind.network;
      });
      return;
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showAuthSnackBar(
        context,
        message: l10n.codeVerifiedCreatePassword,
        type: AuthSnackBarType.success,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) =>
              ResetPassword(email: widget.email, code: completedCode),
        ),
      );
    } else {
      final AuthErrorCode code = parseAuthErrorCode(result['code']?.toString());

      switch (code) {
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
          // user wait out the countdown for a code we already know is dead.
          setState(() => _resendTimer = 0);
          _timer?.cancel();
          break;
        case AuthErrorCode.codeInvalid:
          _otpKey.currentState?.shakeAndClear();
          showAuthSnackBar(
            context,
            message: result['message'] ?? 'Incorrect code. Please try again.',
            type: AuthSnackBarType.error,
          );
          break;
        case AuthErrorCode.accountLocked:
          setState(() {
            _errorKind = AuthErrorKind.locked;
            _errorRetryAfter = parseAuthErrorRetryAfter(result);
          });
          break;
        case AuthErrorCode.rateLimited:
          setState(() {
            _errorKind = AuthErrorKind.rateLimited;
            _errorRetryAfter = parseAuthErrorRetryAfter(result);
          });
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

    Map<String, dynamic> result;
    try {
      result = await ref
          .read(authServiceProvider)
          .sendPasswordResetCode(email: widget.email);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorKind = AuthErrorKind.network;
      });
      return;
    }

    setState(() => _isResending = false);

    if (!mounted) return;

    if (result['success']) {
      showAuthSnackBar(
        context,
        message: l10n.resetCodeResent,
        type: AuthSnackBarType.success,
      );
      _startResendTimer();
    } else {
      final errorCode = parseAuthErrorCode(result['code']?.toString());
      switch (errorCode) {
        case AuthErrorCode.accountLocked:
          setState(() {
            _errorKind = AuthErrorKind.locked;
            _errorRetryAfter = parseAuthErrorRetryAfter(result);
          });
          break;
        case AuthErrorCode.rateLimited:
          setState(() {
            _errorKind = AuthErrorKind.rateLimited;
            _errorRetryAfter = parseAuthErrorRetryAfter(result);
          });
          break;
        default:
          showAuthSnackBar(
            context,
            message: result['message'] ?? 'Failed to resend code',
            type: AuthSnackBarType.error,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScreenScaffold(
      title: l10n.verifyCode,
      showBackButton: true,
      // AnimatedAuthBackground is a Stack(fit: StackFit.expand) so it needs a
      // bounded height — give it at least the viewport height, then let the
      // outer SingleChildScrollView (from AuthScreenScaffold) handle any
      // overflow instead of the Stack itself. See login_screen.dart for the
      // same pattern.
      body: Builder(
        builder: (context) {
          final viewportHeight = MediaQuery.sizeOf(context).height;
          return SizedBox(
            height: viewportHeight,
            width: double.infinity,
            child: AnimatedAuthBackground(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    if (_errorKind != null) ...[
                      AuthErrorState(
                        kind: _errorKind!,
                        retryAfter: _errorRetryAfter,
                        onRetry: (_isLoading || _isResending)
                            ? null
                            : () {
                                setState(() => _errorKind = null);
                              },
                      ),
                    ] else ...[
                      Icon(Icons.password, size: 80, color: AppColors.error),
                      const SizedBox(height: 24),
                      Text(
                        l10n.enterResetCode,
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
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: OtpCodeField(
                          key: _otpKey,
                          length: 6,
                          onCompleted: _verifyCode,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.didntReceiveCode,
                            style: TextStyle(color: context.textSecondary),
                          ),
                          TextButton(
                            onPressed: _isResending || _resendTimer > 0
                                ? null
                                : _resendCode,
                            child: _isResending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _resendTimer > 0
                                        ? l10n.resendWithTimer(
                                            _resendTimer.toString(),
                                          )
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
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
