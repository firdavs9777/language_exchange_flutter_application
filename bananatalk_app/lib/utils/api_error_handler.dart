import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';

class ApiErrorHandler {
  /// Handle limit exceeded error (429)
  /// Extracts limit information from error message and shows appropriate dialog
  static Future<void> handleLimitExceededError({
    required BuildContext context,
    required dynamic error,
    String? userId,
  }) async {
    // Server text when there is any; otherwise the app's own localized
    // fallback is shown in the dialog.
    String? serverMessage;
    int? currentUsage;
    int? maxAllowed;
    String? resetTime;

    // Try to parse error message
    if (error is Map) {
      serverMessage = error['error'] ?? error['message'];
    } else if (error is String) {
      serverMessage = error;
    }
    final errorMessage = serverMessage ?? '';

    // Extract information from error message
    // Format: "Daily messages limit exceeded. You have used 50 of 50 messages today. Limit resets at 1/16/2025, 12:00:00 AM."
    final usageMatch = RegExp(r'used (\d+) of (\d+)').firstMatch(errorMessage);
    if (usageMatch != null) {
      currentUsage = int.tryParse(usageMatch.group(1) ?? '');
      maxAllowed = int.tryParse(usageMatch.group(2) ?? '');
    }

    final resetTimeMatch = RegExp(r'resets at (.+?)(?:\.|$)').firstMatch(errorMessage);
    if (resetTimeMatch != null) {
      resetTime = resetTimeMatch.group(1);
    }

    // Show dialog
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.limitDailyReachedTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serverMessage ?? l10n.limitDescDefault,
              style: const TextStyle(fontSize: 14),
            ),
            if (resetTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    l10n.vipResets(resetTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (currentUsage != null && maxAllowed != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: currentUsage / maxAllowed,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentUsage >= maxAllowed ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.vipUsedToday(currentUsage, maxAllowed),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VipPlansScreen(userId: userId),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.upgradeToVip),
          ),
        ],
      ),
    );
  }

  /// Parse error from API response
  static String parseError(dynamic error, {String defaultMessage = 'An error occurred'}) {
    if (error is Map) {
      return error['error'] ?? error['message'] ?? defaultMessage;
    } else if (error is String) {
      return error;
    } else {
      return defaultMessage;
    }
  }

  /// Check if error is a limit exceeded error (429)
  static bool isLimitExceededError(dynamic error) {
    if (error is Map) {
      final errorMessage = (error['error'] ?? error['message'] ?? '').toString();
      return errorMessage.toLowerCase().contains('limit exceeded') ||
          errorMessage.toLowerCase().contains('daily limit');
    } else if (error is String) {
      return error.toLowerCase().contains('limit exceeded') ||
          error.toLowerCase().contains('daily limit');
    }
    return false;
  }

  /// Handle API error with appropriate UI feedback
  static Future<void> handleApiError({
    required BuildContext context,
    required dynamic error,
    int? statusCode,
    String? userId,
  }) async {
    // Handle 429 (Limit Exceeded)
    if (statusCode == 429 || isLimitExceededError(error)) {
      await handleLimitExceededError(
        context: context,
        error: error,
        userId: userId,
      );
      return;
    }

    // Handle other errors
    final l10n = AppLocalizations.of(context)!;
    final errorMessage =
        parseError(error, defaultMessage: l10n.somethingWentWrong);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.ok,
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Extract limit information from error message
  static Map<String, dynamic>? extractLimitInfo(String errorMessage) {
    final limitTypeMatch = RegExp(r'Daily (\w+) limit exceeded', caseSensitive: false)
        .firstMatch(errorMessage);
    final usageMatch = RegExp(r'used (\d+) of (\d+)').firstMatch(errorMessage);
    final resetTimeMatch = RegExp(r'resets at (.+?)(?:\.|$)').firstMatch(errorMessage);

    if (limitTypeMatch == null && usageMatch == null) {
      return null;
    }

    return {
      'limitType': limitTypeMatch?.group(1)?.toLowerCase(),
      'current': usageMatch != null ? int.tryParse(usageMatch.group(1) ?? '') : null,
      'max': usageMatch != null ? int.tryParse(usageMatch.group(2) ?? '') : null,
      'resetTime': resetTimeMatch?.group(1),
    };
  }
}

