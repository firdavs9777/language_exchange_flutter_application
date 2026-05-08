import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/pages/community/widgets/community_filter_chip.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class FilterTopicsSection extends StatelessWidget {
  final List<String> selectedTopics;
  final ValueChanged<List<String>> onChanged;
  final List<Topic> topics;

  const FilterTopicsSection({
    super.key,
    required this.selectedTopics,
    required this.onChanged,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.filterTopicsEmpty,
          style: context.bodySmall.copyWith(color: context.textMuted),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topics.map((topic) {
          final isSelected = selectedTopics.contains(topic.id);
          return CommunityFilterChip(
            label: topic.name,
            emoji: topic.icon,
            isSelected: isSelected,
            onTap: () {
              final next = List<String>.from(selectedTopics);
              if (isSelected) {
                next.remove(topic.id);
              } else {
                next.add(topic.id);
              }
              onChanged(next);
            },
          );
        }).toList(),
      ),
    );
  }
}
