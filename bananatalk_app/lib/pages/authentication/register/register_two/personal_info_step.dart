import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step that collects gender and/or birth date for OAuth users who did
/// not supply them during social sign-in. Only shown when
/// [showGenderField] or [showBirthDateField] is true.
///
/// All state lives in the parent [_RegisterTwoState]; this widget is
/// purely presentational and receives values + callbacks via constructor.
class PersonalInfoStep extends StatelessWidget {
  // Which fields to show
  final bool showGenderField;
  final bool showBirthDateField;

  // Current values
  final String? selectedGender;
  final TextEditingController birthDateController;

  // Validation errors (null = no error)
  final String? genderError;
  final String? birthDateError;

  // Callbacks
  final void Function(String gender) onGenderSelected;
  final void Function(DateTime date) onBirthDateSelected;
  final VoidCallback onNext;

  const PersonalInfoStep({
    super.key,
    required this.showGenderField,
    required this.showBirthDateField,
    required this.selectedGender,
    required this.birthDateController,
    required this.genderError,
    required this.birthDateError,
    required this.onGenderSelected,
    required this.onBirthDateSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            l10n.tellUsAboutYourself,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.justACoupleQuickThings,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),

          const SizedBox(height: 32),

          // Gender picker
          if (showGenderField) ...[
            Text(
              l10n.gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (genderError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  genderError!,
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: ['male', 'female', 'other'].map((g) {
                final isSelected = selectedGender == g;
                final label = g == 'male'
                    ? l10n.male
                    : g == 'female'
                        ? l10n.female
                        : l10n.other;
                final icons = {
                  'male': Icons.male_rounded,
                  'female': Icons.female_rounded,
                  'other': Icons.transgender_rounded,
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onGenderSelected(g);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : context.containerColor,
                        borderRadius: AppRadius.borderMD,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : context.dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icons[g] ?? Icons.person,
                            color: isSelected
                                ? Colors.white
                                : context.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : context.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Birth date picker
          if (showBirthDateField) ...[
            Text(
              l10n.birthDate,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final initialDate =
                    DateTime.now().subtract(const Duration(days: 365 * 20));
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme:
                            ColorScheme.light(primary: AppColors.primary),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  onBirthDateSelected(pickedDate);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderLG,
                  border: Border.all(
                    color: birthDateError != null
                        ? AppColors.error
                        : context.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        birthDateController.text.isNotEmpty
                            ? birthDateController.text
                            : l10n.selectYourBirthDate,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: birthDateController.text.isNotEmpty
                              ? context.textPrimary
                              : context.textHint,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: context.iconColor),
                  ],
                ),
              ),
            ),
            if (birthDateError != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Text(
                  birthDateError!,
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],

          const SizedBox(height: 32),

          AuthGradientButton(
            label: l10n.continueButton,
            onPressed: onNext,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
