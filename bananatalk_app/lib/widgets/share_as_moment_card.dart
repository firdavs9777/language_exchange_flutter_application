import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/share_offer_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dismissible "Share as a moment" suggestion (spec 7.2).
///
/// Builds nothing, and never reads the offer policy, unless the server flag
/// `shareOffersEnabled` is on. With it on, the card appears only when
/// [ShareOfferPolicy.canOffer] allows, and counts itself as shown once.
/// The button opens the composer with [prefillText] (editable) and
/// [language] (an ISO 639-1 code, `''` when unknown).
class ShareAsMomentCard extends ConsumerStatefulWidget {
  const ShareAsMomentCard({
    super.key,
    required this.prefillText,
    required this.language,
    required this.slot,
    required this.onDismiss,
    this.padding = EdgeInsets.zero,
  });

  /// Whether the server's `shareOffersEnabled` is on. Call sites check it
  /// before building the card, so with it off their widget tree and layout
  /// stay as they were before share offers existed.
  static bool enabledIn(WidgetRef ref) => ref
      .watch(appConfigProvider)
      .maybeWhen(
        data: (c) => c?.shareOffersEnabled ?? false,
        orElse: () => false,
      );

  /// Space around the card, applied only while it is shown, so a hidden
  /// card takes no room at its call site.
  final EdgeInsetsGeometry padding;

  final String prefillText;
  final String language;

  /// Identifies this trigger instance for [ShareOfferPolicy.tryClaim], e.g.
  /// `correction:<messageId>`; a rebuilt card with the same slot keeps showing.
  final String slot;
  final VoidCallback onDismiss;

  @override
  ConsumerState<ShareAsMomentCard> createState() => _ShareAsMomentCardState();
}

class _ShareAsMomentCardState extends ConsumerState<ShareAsMomentCard> {
  /// null until the policy answered; only ever started with the flag on.
  bool? _visible;
  bool _checking = false;

  Future<void> _check() async {
    _checking = true;
    final policy = ref.read(shareOfferPolicyProvider);
    final now = DateTime.now();
    bool allowed;
    try {
      allowed = await policy.tryClaim(now, slot: widget.slot);
    } catch (_) {
      allowed = false;
    }
    if (mounted) setState(() => _visible = allowed);
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    widget.onDismiss();
    try {
      await ref.read(shareOfferPolicyProvider).recordDismissed(DateTime.now());
    } catch (_) {}
  }

  Future<void> _accept() async {
    final navigator = Navigator.of(context);
    setState(() => _visible = false);
    try {
      await ref.read(shareOfferPolicyProvider).recordAccepted(DateTime.now());
    } catch (_) {}
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CreateMoment(
          prefillText: widget.prefillText,
          prefillLanguage: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ShareAsMomentCard.enabledIn(ref)) return const SizedBox.shrink();
    if (!_checking) _check();
    if (_visible != true) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final card = Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.shareAsMomentTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: _dismiss,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _accept,
                child: Text(l10n.shareAsMomentAction),
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(padding: widget.padding, child: card);
  }
}
