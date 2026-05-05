import 'dart:convert';
import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ProfileLanguageEdit extends ConsumerStatefulWidget {
  final String initialLanguage;
  final String type; // 'native' or 'learn'
  final String? otherLanguage;

  const ProfileLanguageEdit({
    super.key,
    required this.initialLanguage,
    required this.type,
    this.otherLanguage,
  });

  @override
  ConsumerState<ProfileLanguageEdit> createState() =>
      _ProfileLanguageEditState();
}

class _ProfileLanguageEditState extends ConsumerState<ProfileLanguageEdit> {
  Language? _selectedLanguage;
  List<Language> _languages = [];
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isNative => widget.type == 'native';

  Color get _accentColor =>
      _isNative ? AppColors.primary : const Color(0xFFFF9800);

  IconData get _accentIcon =>
      _isNative ? Icons.home_rounded : Icons.school_rounded;

  String _accentLabel(AppLocalizations l10n) =>
      _isNative ? l10n.native : l10n.learning;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> languagesList = data['data'] ?? [];

        final languages = languagesList
            .map<Language>((json) => Language.fromJson(json))
            .toList();

        if (!mounted) return;
        setState(() => _languages = languages);

        if (widget.initialLanguage.isNotEmpty && languages.isNotEmpty) {
          try {
            final match = languages.firstWhere(
              (lang) => lang.name == widget.initialLanguage,
            );
            if (mounted) setState(() => _selectedLanguage = match);
          } catch (_) {
            if (kDebugMode) {
              debugPrint('Language not found: ${widget.initialLanguage}');
            }
          }
        }
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showProfileSnackBar(
        context,
        message: l10n.failedToLoadLanguages,
        type: ProfileSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();

    if (_languages.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.languagesAreStillLoading,
        type: ProfileSnackBarType.warning,
      );
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      AppPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      if (widget.otherLanguage != null &&
          result.name.toLowerCase() == widget.otherLanguage!.toLowerCase()) {
        showProfileSnackBar(
          context,
          message: _isNative
              ? l10n.nativeLanguageCannotBeSame
              : l10n.learningLanguageCannotBeSame,
          type: ProfileSnackBarType.error,
        );
        return;
      }

      HapticFeedback.selectionClick();
      setState(() => _selectedLanguage = result);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    if (_selectedLanguage == null) {
      showProfileSnackBar(
        context,
        message: l10n.pleaseSelectALanguage,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    if (widget.otherLanguage != null &&
        _selectedLanguage!.name.toLowerCase() ==
            widget.otherLanguage!.toLowerCase()) {
      showProfileSnackBar(
        context,
        message: _isNative
            ? l10n.nativeLanguageCannotBeSame
            : l10n.learningLanguageCannotBeSame,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final languageName = _selectedLanguage!.name;

      if (_isNative) {
        await ref
            .read(authServiceProvider)
            .updateUserNativeLanguage(natLang: languageName);
      } else {
        await ref
            .read(authServiceProvider)
            .updateUserLanguageToLearn(langToLearn: languageName);
      }

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.languageUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.of(context).pop(languageName);
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
    final hasChanges =
        _selectedLanguage != null &&
        _selectedLanguage!.name != widget.initialLanguage;
    final canSave = hasChanges && !_isSaving;

    return EditScreenScaffold(
      title: _isNative
          ? l10n.selectYourNativeLanguage
          : l10n.whichLanguageDoYouWantToLearn,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type indicator
                _buildTypeIndicator(l10n),
                const SizedBox(height: 16),

                // Hero language card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _selectedLanguage != null
                      ? _buildSelectedLanguageCard(l10n)
                      : _buildEmptyLanguageCard(l10n),
                ),

                const SizedBox(height: 16),

                // Browse languages button
                _buildBrowseButton(l10n),

                if (widget.otherLanguage != null) ...[
                  const SizedBox(height: 24),
                  _buildOtherLanguageHint(l10n),
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
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context)!.loadingLanguages,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  // ========== TYPE INDICATOR ==========
  Widget _buildTypeIndicator(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_accentIcon, color: _accentColor, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _accentLabel(l10n),
              style: context.captionSmall.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _isNative
                  ? l10n.nativeLanguageRequired
                  : l10n.languageToLearnRequired,
              style: context.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== SELECTED LANGUAGE CARD ==========
  Widget _buildSelectedLanguageCard(AppLocalizations l10n) {
    return Container(
      key: ValueKey('selected_${_selectedLanguage!.name}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withValues(alpha: 0.15),
            _accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Flag in circular badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _selectedLanguage!.flag,
              style: const TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'SELECTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedLanguage!.name,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedLanguage!.nativeName,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== EMPTY LANGUAGE CARD ==========
  Widget _buildEmptyLanguageCard(AppLocalizations l10n) {
    return Container(
      key: const ValueKey('empty_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.containerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.language_rounded,
              color: context.textMuted,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.selectALanguage,
            style: context.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tapBelowToBrowseLanguages(_languages.length),
            style: context.captionSmall.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== BROWSE BUTTON ==========
  Widget _buildBrowseButton(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = _isSaving || _languages.isEmpty;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _openLanguagePicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedLanguage != null
                      ? l10n.changeLanguage
                      : l10n.browseLanguages,
                  style: context.titleSmall.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== OTHER LANGUAGE HINT ==========
  Widget _buildOtherLanguageHint(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: context.captionSmall.copyWith(
                  color: const Color(0xFF1976D2),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: _isNative
                        ? l10n.yourLearningLanguageIsPrefix
                        : l10n.yourNativeLanguageIsPrefix,
                  ),
                  TextSpan(
                    text: widget.otherLanguage,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '. Choose a different language here.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
