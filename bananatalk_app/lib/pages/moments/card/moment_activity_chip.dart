import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/create/club_post.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Clubs v2: a club post's stats, "5.2 km · 31:00 · 5:58/km".
class MomentActivityChip extends StatelessWidget {
  const MomentActivityChip({super.key, required this.activity});

  final MomentActivity activity;

  @override
  Widget build(BuildContext context) {
    final line = clubActivityLine(AppLocalizations.of(context)!, activity);
    if (line.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('moment-activity'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_run_rounded, size: 16, color: context.primaryColor),
          const SizedBox(width: 6),
          Text(line, style: context.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
