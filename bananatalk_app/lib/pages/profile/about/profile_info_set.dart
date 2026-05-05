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
      _showErrorSnackBar(l10n.pleaseEnterYourName);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authServiceProvider)
          .updateUserName(userName: name, gender: _selectedGender);

      if (!mounted) return;

      _showSuccessSnackBar(l10n.profileUpdatedSuccessfully);

      Navigator.pop(context, {
        'userName': name,
        'gender': _selectedGender ?? '',
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorSnackBar(
        '${l10n.failedToUpdate}: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = _hasChanges && !_isSaving;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          l10n.nameAndGender,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canSave ? _save : null,
              style: TextButton.styleFrom(
                backgroundColor: canSave
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name section
              _buildSectionLabel(l10n.nameLabel, Icons.badge_rounded),
              const SizedBox(height: 10),
              _buildNameField(l10n),

              const SizedBox(height: 28),

              // Gender section
              _buildSectionLabel(l10n.genderRequired, Icons.wc_rounded),
              const SizedBox(height: 10),
              _buildGenderSelector(l10n),

              const SizedBox(height: 32),

              // Primary save button
              _buildSaveButton(l10n),

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
      ),
    );
  }

  // ========== SECTION LABEL ==========
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ],
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

  // ========== SAVE BUTTON ==========
  Widget _buildSaveButton(AppLocalizations l10n) {
    final canSave = _hasChanges && !_isSaving;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSave ? _save : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: canSave
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    )
                  : null,
              color: canSave
                  ? null
                  : context.dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: canSave
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: canSave ? Colors.white : context.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.saveChanges,
                          style: context.titleSmall.copyWith(
                            color: canSave ? Colors.white : context.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
