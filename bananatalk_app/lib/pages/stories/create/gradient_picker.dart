import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';

class GradientPicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  const GradientPicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: StoryGradient.presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = StoryGradient.presets[i];
          final isSelected = g.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(g.id),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: g.toLinearGradient(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
