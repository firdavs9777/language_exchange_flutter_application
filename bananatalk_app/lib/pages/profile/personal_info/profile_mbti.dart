import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MBTIEdit extends ConsumerStatefulWidget {
  final String currentMBTI;
  const MBTIEdit({super.key, required this.currentMBTI});

  @override
  ConsumerState<MBTIEdit> createState() => _MBTIEditState();
}

class _MBTIEditState extends ConsumerState<MBTIEdit> {
  static const List<String> _mbtiList = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];

  late String _selectedMBTI;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMBTI = widget.currentMBTI;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    if (_selectedMBTI.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.pleaseSelectMbti,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref.read(authServiceProvider).updateUserMbti(mbti: _selectedMBTI);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.mbtiUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.of(context).pop(_selectedMBTI);
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
    final hasChanges = _selectedMBTI != widget.currentMBTI;
    final canSave = hasChanges && _selectedMBTI.isNotEmpty && !_isSaving;

    return EditScreenScaffold(
      title: l10n.selectYourMbti,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MBTI grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _mbtiList.length,
            itemBuilder: (context, index) {
              final mbti = _mbtiList[index];
              final isSelected = _selectedMBTI == mbti;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMBTI = mbti);
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.75),
                              ],
                            )
                          : null,
                      color: isSelected ? null : context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : context.dividerColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          mbti,
                          style: context.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.3,
                            color: isSelected
                                ? Colors.white
                                : context.textPrimary,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Save button
          GradientSaveButton(
            canSave: canSave,
            isSaving: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
