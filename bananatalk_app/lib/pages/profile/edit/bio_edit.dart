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

class ProfileBioEdit extends ConsumerStatefulWidget {
  final String currentBio;
  const ProfileBioEdit({super.key, required this.currentBio});

  @override
  ConsumerState<ProfileBioEdit> createState() => _ProfileBioEditState();
}

class _ProfileBioEditState extends ConsumerState<ProfileBioEdit> {
  late TextEditingController _bioController;
  late FocusNode _focusNode;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isFocused = false;

  static const int _maxLength = 500;
  static const int _recommendedMin = 50;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _bioController.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    final hasChanges = _bioController.text.trim() != widget.currentBio.trim();
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    } else {
      // Still need to rebuild for character counter
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bioController.removeListener(_onTextChange);
    _bioController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    final bio = _bioController.text.trim();
    if (bio.length > _maxLength) {
      showProfileSnackBar(
        context,
        message: l10n.charactersCount(_maxLength),
        type: ProfileSnackBarType.error,
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref.read(authServiceProvider).updateUserBio(bio: bio);

      if (!mounted) return;
      ref.invalidate(userProvider);
      showProfileSnackBar(
        context,
        message: l10n.bioUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context, bio);
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

  void _insertSuggestion(String text) {
    HapticFeedback.selectionClick();
    final current = _bioController.text;
    final newText = current.isEmpty ? text : '$current\n\n$text';
    if (newText.length <= _maxLength) {
      _bioController.text = newText;
      _bioController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = _hasChanges && !_isSaving;
    final length = _bioController.text.length;

    return EditScreenScaffold(
      title: l10n.editBio,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeaderHint(l10n),
            const SizedBox(height: 16),

            // Bio text area
            _buildBioField(l10n),
            const SizedBox(height: 12),

            // Character counter row
            _buildCounterRow(l10n, length),

            // Suggestions (only show if bio is empty/short and not focused)
            if (length < _recommendedMin) ...[
              const SizedBox(height: 24),
              _buildSuggestions(l10n),
            ],

            const SizedBox(height: 28),

            // Save button
            GradientSaveButton(
              canSave: canSave,
              isSaving: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  // ========== HEADER HINT ==========
  Widget _buildHeaderHint(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.bioHintCard,
              style: context.captionSmall.copyWith(
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BIO FIELD ==========
  Widget _buildBioField(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : context.dividerColor.withValues(alpha: 0.5)),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: !isDark && _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _bioController,
        focusNode: _focusNode,
        maxLines: 8,
        minLines: 6,
        maxLength: _maxLength,
        style: context.bodyLarge.copyWith(height: 1.5),
        enabled: !_isSaving,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: l10n.tellOthersAboutYourself,
          hintStyle: context.bodyMedium.copyWith(
            color: context.textHint,
            height: 1.5,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterText: '', // We use custom counter
        ),
      ),
    );
  }

  // ========== COUNTER ROW ==========
  Widget _buildCounterRow(AppLocalizations l10n, int length) {
    final progress = (length / _maxLength).clamp(0.0, 1.0);

    Color counterColor;
    String hint;

    if (length == 0) {
      counterColor = context.textMuted;
      hint = l10n.bioCounterStartWriting;
    } else if (length < _recommendedMin) {
      counterColor = const Color(0xFFFF9800);
      hint = l10n.bioCounterABitMore;
    } else if (length < _maxLength * 0.9) {
      counterColor = AppColors.success;
      hint = l10n.lookingGood;
    } else if (length <= _maxLength) {
      counterColor = const Color(0xFFFF9800);
      hint = l10n.bioCounterAlmostAtLimit;
    } else {
      counterColor = AppColors.error;
      hint = l10n.bioCounterTooLong;
    }

    return Row(
      children: [
        // Animated progress ring
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3,
                  backgroundColor: counterColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(counterColor),
                ),
              ),
            ),
            if (length >= _maxLength * 0.95)
              Icon(
                length > _maxLength
                    ? Icons.error_rounded
                    : Icons.warning_rounded,
                size: 12,
                color: counterColor,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            hint,
            style: context.captionSmall.copyWith(
              color: counterColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$length / $_maxLength',
          style: context.captionSmall.copyWith(
            color: counterColor,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ========== SUGGESTIONS ==========
  // Suggestion content stays English by design — see spec.
  Widget _buildSuggestions(AppLocalizations l10n) {
    final suggestions = [
      ('👋 Hi, I\'m', 'Hi, I\'m '),
      (
        '🌍 I love traveling',
        'I love traveling and meeting new people from around the world.',
      ),
      (
        '📚 Learning',
        'I\'m learning new languages and would love to practice with native speakers.',
      ),
      (
        '🎯 Looking for',
        'Looking for language exchange partners to chat with regularly.',
      ),
      ('🎨 My hobbies', 'My hobbies include '),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.bioQuickStarters,
              style: context.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : () => _insertSuggestion(s.$2),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
