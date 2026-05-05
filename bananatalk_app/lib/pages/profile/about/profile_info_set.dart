import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/pages/profile/widgets/section_label.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileInfoSet extends ConsumerStatefulWidget {
  final String userName;
  final String gender;
  const ProfileInfoSet({super.key, required this.userName, this.gender = ''});

  @override
  ConsumerState<ProfileInfoSet> createState() => _ProfileInfoSetState();
}

class _ProfileInfoSetState extends ConsumerState<ProfileInfoSet> {
  late TextEditingController _controllerName;
  late FocusNode _nameFocusNode;
  late String? _selectedGender;
  bool _isSaving = false;
  bool _hasChanges = false;

  static const List<String> _genders = ['male', 'female', 'other'];

  String _genderLabel(AppLocalizations l10n, String gender) {
    switch (gender) {
      case 'male':
        return l10n.male;
      case 'female':
        return l10n.female;
      case 'other':
        return l10n.other;
      default:
        return gender;
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      case 'other':
        return Icons.transgender_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _genderColor(String gender) {
    switch (gender) {
      case 'male':
        return const Color(0xFF2196F3);
      case 'female':
        return const Color(0xFFE91E63);
      case 'other':
        return const Color(0xFF7C4DFF);
      default:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerName = TextEditingController(text: widget.userName);
    _nameFocusNode = FocusNode();
    final normalised = widget.gender.toLowerCase();
    _selectedGender = _genders.contains(normalised) ? normalised : null;

    _controllerName.addListener(_checkChanges);
  }

  void _checkChanges() {
    final nameChanged = _controllerName.text.trim() != widget.userName;
    final genderChanged =
        (_selectedGender ?? '') != widget.gender.toLowerCase();
    final hasChanges = nameChanged || genderChanged;
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _controllerName.removeListener(_checkChanges);
    _controllerName.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    final name = _controllerName.text.trim();
    if (name.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.pleaseEnterYourName,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authServiceProvider)
          .updateUserName(userName: name, gender: _selectedGender);

      if (!mounted) return;

      showProfileSnackBar(
        context,
        message: l10n.profileUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );

      Navigator.pop(context, {
        'userName': name,
        'gender': _selectedGender ?? '',
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showProfileSnackBar(
        context,
        message:
            '${l10n.failedToUpdate}: ${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = _hasChanges && !_isSaving;

    return EditScreenScaffold(
      title: l10n.nameAndGender,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name section
            SectionLabel(icon: Icons.badge_rounded, text: l10n.nameLabel),
            const SizedBox(height: 10),
            _buildNameField(l10n),

            const SizedBox(height: 28),

            // Gender section
            SectionLabel(icon: Icons.wc_rounded, text: l10n.genderRequired),
            const SizedBox(height: 10),
            _buildGenderSelector(l10n),

            const SizedBox(height: 32),

            // Primary save button
            GradientSaveButton(
              canSave: canSave,
              isSaving: _isSaving,
              onPressed: _save,
            ),

            if (_hasChanges) ...[
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: context.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.unsavedChanges,
                      style: context.captionSmall.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== NAME FIELD ==========
  Widget _buildNameField(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFocused = _nameFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppColors.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : context.dividerColor.withValues(alpha: 0.5)),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isDark || !isFocused
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextField(
        controller: _controllerName,
        focusNode: _nameFocusNode,
        style: context.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        textCapitalization: TextCapitalization.words,
        enabled: !_isSaving,
        onTap: () => setState(() {}),
        onEditingComplete: () => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: l10n.enterYourName,
          hintStyle: context.bodyMedium.copyWith(color: context.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.person_rounded,
              color: isFocused ? AppColors.primary : context.textMuted,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: _controllerName.text.isNotEmpty && !_isSaving
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.textMuted,
                  ),
                  onPressed: () {
                    _controllerName.clear();
                    _checkChanges();
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ========== GENDER SELECTOR (chips instead of dropdown) ==========
  Widget _buildGenderSelector(AppLocalizations l10n) {
    return Row(
      children: _genders.map((gender) {
        final isSelected = _selectedGender == gender;
        final color = _genderColor(gender);
        final icon = _genderIcon(gender);
        final label = _genderLabel(l10n, gender);
        final isLast = gender == _genders.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedGender = gender);
                        _checkChanges();
                      },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withValues(alpha: 0.8)],
                          )
                        : null,
                    color: isSelected ? null : context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : context.dividerColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: context.titleSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
