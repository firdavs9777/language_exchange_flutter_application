// lib/providers/api_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// Global API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Global error handler state
class GlobalErrorState {
  final String? message;
  final GlobalErrorType? type;
  final DateTime? timestamp;

  GlobalErrorState({
    this.message,
    this.type,
    this.timestamp,
  });

  GlobalErrorState copyWith({
    String? message,
    GlobalErrorType? type,
    DateTime? timestamp,
  }) {
    return GlobalErrorState(
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get hasError => message != null && timestamp != null;
}

enum GlobalErrorType {
  authentication,
  authorization,
  rateLimit,
  network,
  server,
}

class GlobalErrorNotifier extends StateNotifier<GlobalErrorState> {
  GlobalErrorNotifier() : super(GlobalErrorState());

  void showError(String message, GlobalErrorType type) {
    state = GlobalErrorState(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
  }

  void clearError() {
    state = GlobalErrorState();
  }
}

final globalErrorProvider =
    StateNotifierProvider<GlobalErrorNotifier, GlobalErrorState>((ref) {
  return GlobalErrorNotifier();
});

/// Widget to handle global API errors and show appropriate UI feedback
class GlobalApiErrorHandler extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalApiErrorHandler({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GlobalApiErrorHandler> createState() =>
      _GlobalApiErrorHandlerState();
}

class _GlobalApiErrorHandlerState extends ConsumerState<GlobalApiErrorHandler> {
  DateTime? _lastErrorShown;

  @override
  void initState() {
    super.initState();
    _setupApiClientCallbacks();
  }

  void _setupApiClientCallbacks() {
    final apiClient = ApiClient();

    apiClient.onAuthenticationError = () {
      ref.read(globalErrorProvider.notifier).showError(
            'Session expired. Please log in again.',
            GlobalErrorType.authentication,
          );
    };

    apiClient.onRateLimitError = (message) {
      ref.read(globalErrorProvider.notifier).showError(
            message,
            GlobalErrorType.rateLimit,
          );
    };

    apiClient.onAuthorizationError = (message) {
      ref.read(globalErrorProvider.notifier).showError(
            message,
            GlobalErrorType.authorization,
          );
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GlobalErrorState>(globalErrorProvider, (previous, next) {
      if (next.hasError) {
        // Prevent duplicate error messages within 2 seconds
        if (_lastErrorShown != null &&
            DateTime.now().difference(_lastErrorShown!).inSeconds < 2) {
          return;
        }
        _lastErrorShown = DateTime.now();

        _showErrorFeedback(context, next);
      }
    });

    return widget.child;
  }

  void _showErrorFeedback(BuildContext context, GlobalErrorState error) {
    switch (error.type) {
      case GlobalErrorType.authentication:
        // Show dialog and redirect to login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Text('Session Expired'),
              ],
            ),
            content: Text(error.message ?? 'Please log in again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login
                  context.go('/login');
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        );
        break;

      case GlobalErrorType.rateLimit:
        // Show snackbar with countdown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.speed, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(error.message ?? 'Please slow down')),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        break;

      case GlobalErrorType.authorization:
        // Show snackbar for permission errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(error.message ?? 'Permission denied')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        break;

      case GlobalErrorType.network:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Network error. Check your connection.')),
              ],
            ),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        break;

      case GlobalErrorType.server:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Server error. Please try again later.')),
              ],
            ),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        break;

      default:
        break;
    }

    // Clear error after showing
    ref.read(globalErrorProvider.notifier).clearError();
  }
}

/// Mixin to add rate limit handling to buttons
mixin RateLimitButtonMixin<T extends StatefulWidget> on State<T> {
  bool _isRateLimited = false;
  int _cooldownSeconds = 0;

  void handleRateLimit(int cooldownSeconds) {
    setState(() {
      _isRateLimited = true;
      _cooldownSeconds = cooldownSeconds;
    });

    // Countdown timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _isRateLimited = false;
        }
      });

      return _cooldownSeconds > 0;
    });
  }

  bool get isRateLimited => _isRateLimited;
  String get cooldownText => 'Wait $_cooldownSeconds s';
}
