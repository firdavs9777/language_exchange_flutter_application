import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/referral_service.dart';

/// The backend credits only accounts younger than this
/// (controllers/referrals.js NEW_ACCOUNT_WINDOW_MS).
const inviteCodeEntryWindow = Duration(days: 14);

/// Whether an account created at [createdAt] (ISO 8601) may still claim.
bool canEnterInviteCode(String createdAt, DateTime now) {
  final created = DateTime.tryParse(createdAt);
  if (created == null) return false;
  return now.difference(created) < inviteCodeEntryWindow;
}

/// Localized text for a failed claim.
String inviteClaimErrorText(AppLocalizations l10n, Object error) {
  if (error is ReferralRejectedException) {
    return error.code == referralUnknownCode
        ? l10n.referralCodeUnknown
        : l10n.referralCodeNotAccepted;
  }
  return l10n.networkError;
}

/// "Have an invite code?" on the Invite friends screen (links#10).
///
/// For a fresh install that lost the `/i/CODE` link: the user types the code
/// after completing their profile, as the web invite page tells them to.
/// Prefilled with a stored pending code (from a tapped link or the Play
/// install referrer) whose automatic claim did not go through.
class InviteCodeEntryCard extends ConsumerStatefulWidget {
  const InviteCodeEntryCard({super.key});

  @override
  ConsumerState<InviteCodeEntryCard> createState() =>
      _InviteCodeEntryCardState();
}

class _InviteCodeEntryCardState extends ConsumerState<InviteCodeEntryCard> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillPending();
  }

  Future<void> _prefillPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString(pendingReferralPrefsKey);
      if (mounted && pending != null && _controller.text.isEmpty) {
        _controller.text = pending;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context)!;
    final code = normalizeInviteCode(_controller.text);
    if (code == null) {
      setState(() => _error = l10n.referralCodeUnknown);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(referralServiceProvider).claim(code);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(pendingReferralPrefsKey);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      if (result.invitee > 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.referralClaimed(result.invitee))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = inviteClaimErrorText(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Card(
      key: const ValueKey('invite_code_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.referralHaveCode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('invite_code_field'),
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: l10n.referralEnterCodeHint,
                      errorText: _error,
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!_busy) _apply();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    key: const ValueKey('invite_code_apply'),
                    onPressed: _busy ? null : _apply,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.referralApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
