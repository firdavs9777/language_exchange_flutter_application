import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class BlockUserDialog {
  static Future<void> show({
    required BuildContext context,
    required String currentUserId,
    required String targetUserId,
    required String targetUserName,
    String? targetUserAvatar,
    VoidCallback? onBlocked,
    WidgetRef? ref,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.blockUser),
          ],
        ),
        content: Text(
          'Are you sure you want to block $targetUserName?\n\nYou will no longer see their messages, posts, or appear in each other\'s searches.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.block),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
      );
    }

    final result = await BlockService.blockUser(
      currentUserId: currentUserId,
      blockedUserId: targetUserId,
      blockedUserName: targetUserName,
      blockedUserAvatar: targetUserAvatar,
    );

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(result['message'] ?? 'Operation completed')),
            ],
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      if (result['success']) {
        // Refresh blocked users provider
        if (ref != null) {
          ref.invalidate(blockedUsersProvider);
          ref.invalidate(blockedUserIdsProvider);
        }
        if (onBlocked != null) onBlocked();
      }
    }
  }
}

