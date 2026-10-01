import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Nudge shown when a short thread went quiet with the partner's message
/// unanswered. Tapping the suggestion only hands text to [onPick] (the caller
/// fills the composer) -- never auto-sends.
class StallRescueBanner extends StatelessWidget {
  const StallRescueBanner({
    super.key,
    required this.name,
    required this.suggestion,
    required this.onPick,
    required this.onDismiss,
  });

  final String name;
  final String suggestion;
  final ValueChanged<String> onPick;
  final VoidCallback onDismiss;

  static const _maxMessages = 5;
  static const _staleAfter = Duration(hours: 24);

  /// 1-5 messages, newest one is theirs, and it is older than 24h.
  static bool shouldShowStallRescue({
    required List<Message> messages,
    required String myId,
    required DateTime now,
  }) {
    if (messages.isEmpty || messages.length > _maxMessages) return false;
    Message? newest;
    DateTime? newestAt;
    for (final m in messages) {
      final at = DateTime.tryParse(m.createdAt);
      if (at == null) return false;
      if (newestAt == null || at.isAfter(newestAt)) {
        newest = m;
        newestAt = at;
      }
    }
    if (newest == null || newestAt == null) return false;
    if (newest.sender.id == myId) return false;
    return now.difference(newestAt) > _staleAfter;
  }

  static String _key(String conversationId) =>
      'stall_rescue_shown_$conversationId';

  /// Once-per-conversation gate: returns true (and records it) the first time
  /// it is called for [conversationId], false afterwards.
  static Future<bool> claimShow(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_key(conversationId)) ?? false) return false;
      await prefs.setBool(_key(conversationId), true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: AppColors.matchReasonTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.matchReasonText),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stallRescueTitle(name),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.matchInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onPick(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.matchInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.matchMutedText,
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
