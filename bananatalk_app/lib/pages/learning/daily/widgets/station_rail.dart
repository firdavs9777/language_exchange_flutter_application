import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Progress across the day's stations. The count comes from the server's view
/// of the pack (done + empty), never from a client-side tally.
class StationRail extends StatelessWidget {
  final List<PackStation> stations;
  final int currentIndex;

  const StationRail({super.key, required this.stations, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final done = stations.where((s) => s.status != StationStatus.todo).length;

    return Row(
      children: [
        ...List.generate(stations.length, (i) {
          final s = stations[i];
          final satisfied = s.status != StationStatus.todo;
          final isCurrent = i == currentIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                key: isCurrent ? Key('rail-dot-$i-current') : Key('rail-dot-$i'),
                duration: const Duration(milliseconds: 220),
                height: isCurrent ? 6 : 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: satisfied
                      ? theme.colorScheme.primary
                      : isCurrent
                          ? theme.colorScheme.primary.withValues(alpha: 0.45)
                          : context.dividerColor,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text('$done/${stations.length}', style: theme.textTheme.labelMedium),
      ],
    );
  }
}
