import 'package:flutter/material.dart';

import 'moment_filter_model.dart';
import 'filter_chips.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class FilterMoodSection extends StatelessWidget {
  final MomentFilter tempFilter;
  final ValueChanged<MomentFilter> onChanged;

  const FilterMoodSection({
    super.key,
    required this.tempFilter,
    required this.onChanged,
  });

  void _toggleMood(String mood) {
    final moods = List<String>.from(tempFilter.moods);
    if (moods.contains(mood)) {
      moods.remove(mood);
    } else {
      moods.add(mood);
    }
    onChanged(tempFilter.copyWith(moods: moods));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterSectionTitle(
            context,
            AppLocalizations.of(context)!.moods,
            Icons.emoji_emotions,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: FilterOptions.moods.map((mood) {
              final isSelected = tempFilter.moods.contains(mood);
              final emoji = FilterOptions.moodEmojis[mood] ?? '😊';

              return filterMoodChip(
                context: context,
                emoji: emoji,
                label: mood.capitalize(),
                isSelected: isSelected,
                onTap: () => _toggleMood(mood),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
