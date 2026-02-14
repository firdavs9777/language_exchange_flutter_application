import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';

/// Topic chip widget for displaying interests
class TopicChip extends StatelessWidget {
  final Topic topic;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  const TopicChip({
    super.key,
    required this.topic,
    this.isSelected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00BFA5);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topic.icon,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              topic.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                topic.icon,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                topic.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? primaryColor : Colors.grey[800],
                ),
              ),
              if (topic.userCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatUserCount(topic.userCount),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatUserCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Simple topic chip from string
class SimpleTopicChip extends StatelessWidget {
  final String topicId;
  final bool isSelected;
  final VoidCallback? onTap;

  const SimpleTopicChip({
    super.key,
    required this.topicId,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topic = Topic.defaultTopics.firstWhere(
      (t) => t.id == topicId,
      orElse: () => Topic(
        id: topicId,
        name: topicId,
        icon: '🏷️',
        category: 'other',
      ),
    );

    return TopicChip(
      topic: topic,
      isSelected: isSelected,
      onTap: onTap,
      compact: true,
    );
  }
}
