import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Partners "Topic" chip: pick one topic to see people who share it.
/// Returns the picked topic id, or null when dismissed. Replaces the old
/// Topics tab's grid (the people list is the Partners list).
Future<String?> showTopicPickerSheet(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.topics, style: context.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in Topic.defaultTopics)
                      ChoiceChip(
                        key: ValueKey('topic_${topic.id}'),
                        avatar: Text(topic.icon),
                        label: Text(topic.localizedName(l10n)),
                        selected: topic.id == selectedId,
                        onSelected: (_) => Navigator.pop(context, topic.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
