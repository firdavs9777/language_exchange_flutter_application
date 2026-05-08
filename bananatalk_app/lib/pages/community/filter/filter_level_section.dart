import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

const List<String> kLanguageLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

/// A row of ChoiceChip widgets for selecting a CEFR language level.
class FilterLevelSection extends StatelessWidget {
  final String? selectedLevel;
  final ValueChanged<String?> onChanged;

  const FilterLevelSection({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "Any" chip
        ChoiceChip(
          label: Text(AppLocalizations.of(context)!.any),
          selected: selectedLevel == null,
          onSelected: (selected) {
            if (selected) onChanged(null);
          },
          selectedColor: context.primaryColor,
          labelStyle: TextStyle(
            color: selectedLevel == null ? Colors.white : context.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: context.containerColor,
          side: BorderSide(
            color: selectedLevel == null
                ? context.primaryColor
                : context.dividerColor,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSM),
        ),
        // Level chips
        ...kLanguageLevels.map((level) {
          final isSelected = selectedLevel == level;
          return ChoiceChip(
            label: Text(level),
            selected: isSelected,
            onSelected: (selected) {
              onChanged(selected ? level : null);
            },
            selectedColor: context.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : context.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: context.containerColor,
            side: BorderSide(
              color: isSelected ? context.primaryColor : context.dividerColor,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSM),
          );
        }),
      ],
    );
  }
}
