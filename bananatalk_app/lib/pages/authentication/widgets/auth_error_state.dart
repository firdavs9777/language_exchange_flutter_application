import 'package:flutter/material.dart';

/// Illustrated in-body error state for auth flows: account lockout, rate
/// limiting, and network failures. Rendered instead of a raw snackbar so the
/// user gets persistent context (icon, title, explanation) plus a retry
/// action, rather than a message that disappears after a few seconds.
enum AuthErrorKind { locked, rateLimited, network }

class AuthErrorState extends StatelessWidget {
  const AuthErrorState({
    super.key,
    required this.kind,
    this.retryAfter,
    this.onRetry,
  });

  final AuthErrorKind kind;
  final Duration? retryAfter;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (kind) {
      AuthErrorKind.locked => (
          Icons.lock_clock,
          'Account temporarily locked',
          'Too many failed attempts. Try again '
              '${retryAfter != null ? 'in ${retryAfter!.inMinutes} min' : 'later'}.',
        ),
      AuthErrorKind.rateLimited => (
          Icons.hourglass_top,
          'Slow down a moment',
          'Too many attempts. Try again '
              '${retryAfter != null ? 'in ${retryAfter!.inSeconds}s' : 'shortly'}.',
        ),
      AuthErrorKind.network => (
          Icons.wifi_off,
          'No connection',
          'Check your internet connection and try again.',
        ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: const Color(0xFF00BFA5)),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ],
    );
  }
}
