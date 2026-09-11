import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Thirty dots: one per day, filled where the learner completed something.
/// Anchored on the newest active day so the grid needs no clock of its own.
class StreakCalendar extends StatelessWidget {
  final List<String> activeDays;
  final int days;

  const StreakCalendar({super.key, required this.activeDays, this.days = 30});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeDays.toSet();
    final anchor =
        activeDays.isEmpty ? null : DateTime.parse('${activeDays.last}T00:00:00Z');

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(days, (i) {
        final key = anchor == null
            ? ''
            : anchor
                .subtract(Duration(days: days - 1 - i))
                .toIso8601String()
                .substring(0, 10);
        final on = active.contains(key);
        return Container(
          key: Key('streak-dot-$i'),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? theme.colorScheme.primary : context.dividerColor,
          ),
        );
      }),
    );
  }
}
