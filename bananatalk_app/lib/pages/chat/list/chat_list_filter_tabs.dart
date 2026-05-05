import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Horizontal chip row: All / Unread / Online filter.
/// Selection state lives in the parent; this widget is purely presentational.
class ChatListFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ChatListFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const filters = [
      ('all', 'All', Icons.chat_bubble_outline_rounded),
      ('unread', 'Unread', Icons.mark_email_unread_outlined),
      ('online', 'Online', Icons.circle),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label, icon) = filters[index];
          final isSelected = selectedFilter == value;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: value == 'online' ? 10 : 16,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : context.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onFilterChanged(value),
            selectedColor: context.primaryColor,
            backgroundColor: context.containerColor,
            labelStyle: TextStyle(
              color: isSelected ? colorScheme.onPrimary : context.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide.none,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }
}
