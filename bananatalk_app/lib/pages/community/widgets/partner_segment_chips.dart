import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

/// `All · Serious learners · New members` segment row for the Partners list,
/// with an explainer line under the active segment. Mutually exclusive.
class PartnerSegmentChips extends ConsumerWidget {
  const PartnerSegmentChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(partnerSegmentProvider);

    void select(PartnerSegment s) {
      if (s == selected) return;
      HapticFeedback.selectionClick();
      ref.read(partnerSegmentProvider.notifier).state = s;
    }

    final hint = switch (selected) {
      PartnerSegment.serious => l10n.segmentSeriousHint,
      PartnerSegment.newMembers => l10n.segmentNewHint,
      PartnerSegment.all => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SegmentChip(
                  label: l10n.segmentAll,
                  selected: selected == PartnerSegment.all,
                  onTap: () => select(PartnerSegment.all),
                ),
                const SizedBox(width: 8),
                _SegmentChip(
                  label: '🔥 ${l10n.segmentSerious}',
                  selected: selected == PartnerSegment.serious,
                  onTap: () => select(PartnerSegment.serious),
                ),
                const SizedBox(width: 8),
                _SegmentChip(
                  label: '🌱 ${l10n.segmentNew}',
                  selected: selected == PartnerSegment.newMembers,
                  onTap: () => select(PartnerSegment.newMembers),
                ),
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.matchMutedText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.matchInk : AppColors.matchChipSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.matchInk : AppColors.matchHairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.matchAccent : AppColors.matchInk,
            ),
          ),
        ),
      ),
    );
  }
}
