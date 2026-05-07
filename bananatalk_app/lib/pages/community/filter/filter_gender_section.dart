import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class FilterGenderSection extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  const FilterGenderSection({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _GenderButton(
            label: l10n.any,
            value: null,
            icon: Icons.people,
            selectedGender: selectedGender,
            onTap: () => onChanged(null),
          ),
          _GenderButton(
            label: l10n.male,
            value: 'Male',
            icon: Icons.man,
            selectedGender: selectedGender,
            onTap: () => onChanged('Male'),
          ),
          _GenderButton(
            label: l10n.female,
            value: 'Female',
            icon: Icons.woman,
            selectedGender: selectedGender,
            onTap: () => onChanged('Female'),
          ),
          _GenderButton(
            label: l10n.other,
            value: 'Other',
            icon: Icons.person_outline,
            selectedGender: selectedGender,
            onTap: () => onChanged('Other'),
          ),
        ],
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final String? selectedGender;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.selectedGender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : context.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
