import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_chips.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class FilterCategorySection extends StatelessWidget {
  final MomentFilter tempFilter;
  final ValueChanged<MomentFilter> onChanged;

  const FilterCategorySection({
    super.key,
    required this.tempFilter,
    required this.onChanged,
  });

  void _toggleCategory(String category) {
    final categories = List<String>.from(tempFilter.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    onChanged(tempFilter.copyWith(categories: categories));
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
            AppLocalizations.of(context)!.categories,
            Icons.category,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: FilterOptions.categories.map((category) {
              final isSelected = tempFilter.categories.contains(category);
              final icon = FilterOptions.categoryIcons[category] ?? '🌐';
              final label =
                  FilterOptions.categoryLabels[category] ?? category;

              return filterChip(
                context: context,
                label: '$icon $label',
                isSelected: isSelected,
                onTap: () => _toggleCategory(category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
