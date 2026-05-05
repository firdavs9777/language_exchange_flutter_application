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

class PersonBloodType extends ConsumerStatefulWidget {
  final String currentSelectedBloodType;
  const PersonBloodType({super.key, required this.currentSelectedBloodType});

  @override
  ConsumerState<PersonBloodType> createState() => _PersonBloodTypeState();
}

class _PersonBloodTypeState extends ConsumerState<PersonBloodType> {
  // Positive (Rh+) and Negative (Rh-) groups
  static const List<String> _positiveTypes = [
    'Type A',
    'Type B',
    'Type AB',
    'Type O',
  ];
  static const List<String> _negativeTypes = [
    'Type A-',
    'Type B-',
    'Type AB-',
    'Type O-',
  ];

  late String _selectedBloodType;
  bool _isSaving = false;

  static const Color _bloodRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _selectedBloodType = widget.currentSelectedBloodType;
  }

  /// Extract just the letter portion (A, B, AB, O) from "Type A" or "Type A-"
  String _shortLabel(String type) {
    return type.replaceFirst('Type ', '').replaceFirst('-', '');
  }

  bool _isNegative(String type) => type.endsWith('-');

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    if (_selectedBloodType.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.pleaseSelectABloodType,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authServiceProvider)
          .updateUserBloodType(bloodType: _selectedBloodType);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.bloodTypeSavedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.of(context).pop(_selectedBloodType);
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
    final hasChanges = _selectedBloodType != widget.currentSelectedBloodType;
    final canSave = hasChanges && !_isSaving;

    return EditScreenScaffold(
      title: l10n.myBloodType,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected blood type preview
          _buildSelectedPreview(l10n),
          const SizedBox(height: 24),

          // Positive (Rh+) section
          _buildGroupHeader(
            l10n.rhPositive,
            l10n.rhPositiveDesc,
            Icons.add_circle_rounded,
            _bloodRed,
          ),
          const SizedBox(height: 12),
          _buildBloodTypeGrid(_positiveTypes, isNegative: false),

          const SizedBox(height: 28),

          // Negative (Rh-) section
          _buildGroupHeader(
            l10n.rhNegative,
            l10n.rhNegativeDesc,
            Icons.remove_circle_rounded,
            const Color(0xFF7C4DFF),
          ),
          const SizedBox(height: 12),
          _buildBloodTypeGrid(_negativeTypes, isNegative: true),

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

  // ========== SELECTED PREVIEW ==========
  Widget _buildSelectedPreview(AppLocalizations l10n) {
    final hasSelection = _selectedBloodType.isNotEmpty;
    final isNeg = hasSelection && _isNegative(_selectedBloodType);
    final color = hasSelection
        ? (isNeg ? const Color(0xFF7C4DFF) : _bloodRed)
        : context.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: hasSelection
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: hasSelection ? null : context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSelection
              ? color.withValues(alpha: 0.3)
              : context.dividerColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Blood drop icon with letter
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: hasSelection
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.75)],
                    )
                  : null,
              color: hasSelection ? null : context.containerColor,
              shape: BoxShape.circle,
              boxShadow: hasSelection
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: hasSelection
                ? Text(
                    _shortLabel(_selectedBloodType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  )
                : Icon(
                    Icons.bloodtype_rounded,
                    color: context.textMuted,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection ? l10n.yourBloodType : l10n.noBloodTypeSelected,
                  style: context.captionSmall.copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSelection
                      ? '${_shortLabel(_selectedBloodType)}${isNeg ? '−' : '+'}'
                      : l10n.tapTypeBelow,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hasSelection ? color : context.textPrimary,
                    fontSize: 22,
                  ),
                ),
                if (hasSelection) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isNeg ? l10n.rhNegative : l10n.rhPositive,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== GROUP HEADER ==========
  Widget _buildGroupHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: context.captionSmall.copyWith(
                color: context.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== BLOOD TYPE GRID ==========
  Widget _buildBloodTypeGrid(List<String> types, {required bool isNegative}) {
    final color = isNegative ? const Color(0xFF7C4DFF) : _bloodRed;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selectedBloodType == type;
        final letter = _shortLabel(type);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedBloodType = type);
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
                        colors: [color, color.withValues(alpha: 0.75)],
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
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          letter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isNegative ? '−' : '+',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : color,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
