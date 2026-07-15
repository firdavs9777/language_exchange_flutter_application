import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// One-time content-policy acceptance gate for Reels (Apple Guideline 1.2 —
/// public UGC video requires an objectionable-content agreement). Shown
/// before the first Reels-tab content render (`ReelsGridScreen`) and, since
/// a user can also enter reel creation directly from the prompt-of-day
/// card without ever visiting the grid, before the first reel post
/// (`CreateReelFlow`) as well.
class ReelPolicyGate {
  ReelPolicyGate._();

  static const _prefsKey = 'reels_policy_accepted';

  /// True if the user has already accepted — the local flag is checked
  /// first (instant, no network dependency), then the server-synced user
  /// field (covers a fresh install / different device where the local flag
  /// isn't set yet but the account already accepted).
  static Future<bool> hasAccepted(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) == true) return true;

    final serverAccepted =
        ref.read(userProvider).valueOrNull?.reelsPolicyAccepted ?? false;
    if (serverAccepted) {
      await prefs.setBool(_prefsKey, true);
      return true;
    }
    return false;
  }

  /// Ensures the user has accepted the policy, showing the dialog if not.
  /// Returns true when accepted (already, or just now); false when
  /// declined or the widget was unmounted before the check completed.
  static Future<bool> ensureAccepted(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (await hasAccepted(ref)) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ReelPolicyDialog(),
    );

    if (accepted != true) return false;
    await _persistAcceptance(ref);
    return true;
  }

  static Future<void> _persistAcceptance(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);

    // Best-effort server persist via the existing profile-update endpoint
    // (PUT /auth/updatedetails) — a network failure here shouldn't block
    // the user, since the local flag already gates this device for this
    // and future sessions.
    try {
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        await http.put(
          Uri.parse('${Endpoints.baseURL}${Endpoints.updateDetailsURL}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'reelsPolicyAccepted': true}),
        );
      }
    } catch (_) {
      // Non-fatal — local flag already covers this device.
    }
    ref.invalidate(userProvider);
  }
}

/// Zero-tolerance content-policy acceptance dialog shown by
/// [ReelPolicyGate.ensureAccepted].
class ReelPolicyDialog extends StatelessWidget {
  const ReelPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.videocam, color: Color(0xFF00BFA5)),
          SizedBox(width: 10),
          Expanded(child: Text('Reels content guidelines')),
        ],
      ),
      content: const SingleChildScrollView(
        child: Text(
          'Reels are short language-learning videos — prompt answers, '
          'speaking practice, native-speaker explainers, and culture clips.\n\n'
          'Bananatalk has zero tolerance for objectionable content: no '
          'nudity, hate speech, harassment, violence, or illegal content. '
          'Reported videos are automatically hidden pending review after '
          '2 reports, and violations can result in content removal or '
          'account bans.\n\n'
          'You can report or block from any reel at any time.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
            foregroundColor: Colors.white,
          ),
          child: const Text('I agree'),
        ),
      ],
    );
  }
}
