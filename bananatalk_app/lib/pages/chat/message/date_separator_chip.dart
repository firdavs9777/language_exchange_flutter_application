// lib/pages/chat/message/date_separator_chip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Human date label for a chat day separator. Pure so it is unit-testable;
/// [now] is injected (defaults to DateTime.now() at the call site).
String dateSeparatorLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return DateFormat('EEEE').format(d); // weekday
  if (d.year == today.year) return DateFormat('MMM d').format(d);
  return DateFormat('MMM d, yyyy').format(d);
}

class DateSeparatorChip extends StatelessWidget {
  const DateSeparatorChip({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final label = dateSeparatorLabel(day, DateTime.now());
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerColor, width: 0.5),
        ),
        child: Text(
          label,
          style: context.captionSmall.copyWith(
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
