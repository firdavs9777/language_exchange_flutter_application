import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/authentication/register/birth_date_input_formatter.dart';
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

  /// Fired as the user TYPES a birth date, so the parent can clear its
  /// validation error the same way picking from the calendar does.
  final ValueChanged<String> onBirthDateTyped;

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
    required this.onBirthDateTyped,
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
            const SizedBox(height: 4),
            // Says WHY it is asked. A bare demand for gender on a signup form
            // reads as data collection; the reason makes it answerable.
            Text(
              l10n.helpsMatchWithLearners,
              style: TextStyle(fontSize: 13, color: context.textMuted),
            ),
            if (genderError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  genderError!,
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
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
                    // Selection is a tinted card with a check, not a hard
                    // solid fill: on a sensitive question a softer affirmative
                    // reads as "noted", not "locked in".
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : context.containerColor,
                        borderRadius: AppRadius.borderLG,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : context.dividerColor,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.cardBackground,
                                ),
                                child: Icon(
                                  icons[g] ?? Icons.person,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textSecondary,
                                  size: 24,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.cardBackground,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.textPrimary,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
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
            Builder(
              builder: (fieldContext) {
              Future<void> openCalendar() async {
                final initialDate = DateTime.now().subtract(
                  const Duration(days: 365 * 20),
                );
                final pickedDate = await showDatePicker(
                  context: fieldContext,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  onBirthDateSelected(pickedDate);
                }
              }

              // Typed OR picked. The calendar alone meant scrolling back
              // decades for every signup; the hint shows the exact shape the
              // parser expects so nobody has to guess the order.
              return TextField(
                controller: birthDateController,
                keyboardType: TextInputType.number,
                inputFormatters: [BirthDateInputFormatter()],
                onChanged: onBirthDateTyped,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'YYYY.MM.DD',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.textHint,
                  ),
                  helperText: l10n.selectYourBirthDate,
                  helperStyle: TextStyle(fontSize: 12, color: context.textHint),
                  filled: true,
                  fillColor: context.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.cake_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    tooltip: l10n.selectYourBirthDate,
                    icon: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.iconColor,
                    ),
                    onPressed: openCalendar,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderLG,
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderLG,
                    borderSide: BorderSide(
                      color: birthDateError != null
                          ? AppColors.error
                          : context.dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderLG,
                    borderSide: BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              );
              },
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

          AuthGradientButton(label: l10n.continueButton, onPressed: onNext),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
