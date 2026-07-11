import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step where the user picks their native language and optionally their
/// proficiency level in it.
///
/// All state lives in the parent [_RegisterTwoState]. This widget
/// receives the current selection and callbacks via constructor.
///
/// [allLanguages] + [excludeLanguage] drive the searchable picker sheet
/// opened from here: the language already chosen as the *learning* language
/// (if any) is excluded from this list, mirroring the backend rule that
/// native != learning. This is the fix for the prod bug class where users
/// picked the same language for both and the backend silently 400'd.
class NativeLanguageStep extends StatelessWidget {
  final Language? selectedLanguage;
  final String? selectedLevel;
  final bool isLoadingLanguages;
  final List<Language> allLanguages;
  final Language? excludeLanguage;
  final ValueChanged<Language> onLanguageSelected;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const NativeLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.isLoadingLanguages,
    required this.allLanguages,
    required this.excludeLanguage,
    required this.onLanguageSelected,
    required this.onLevelChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LanguageStepBody(
      title: l10n.whatsYourNativeLanguage,
      subtitle: l10n.helpsMatchWithLearners,
      selectedLanguage: selectedLanguage,
      selectedLevel: selectedLevel,
      isNative: true,
      isLoadingLanguages: isLoadingLanguages,
      allLanguages: allLanguages,
      excludeLanguage: excludeLanguage,
      onLanguageSelected: onLanguageSelected,
      onLevelChanged: onLevelChanged,
      onNext: onNext,
    );
  }
}

/// Step where the user picks the language they are learning and their
/// current proficiency level (required before advancing).
///
/// The picker sheet opened from here excludes [excludeLanguage] (the native
/// language), mirroring the backend rule and preventing the class of prod
/// bug where a user picked the same language for both fields.
class LearningLanguageStep extends StatelessWidget {
  final Language? selectedLanguage;
  final String? selectedLevel;
  final bool isLoadingLanguages;
  final List<Language> allLanguages;
  final Language? excludeLanguage;
  final ValueChanged<Language> onLanguageSelected;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const LearningLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.isLoadingLanguages,
    required this.allLanguages,
    required this.excludeLanguage,
    required this.onLanguageSelected,
    required this.onLevelChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LanguageStepBody(
      title: l10n.whatAreYouLearning,
      subtitle: l10n.connectWithNativeSpeakers,
      selectedLanguage: selectedLanguage,
      selectedLevel: selectedLevel,
      isNative: false,
      isLoadingLanguages: isLoadingLanguages,
      allLanguages: allLanguages,
      excludeLanguage: excludeLanguage,
      onLanguageSelected: onLanguageSelected,
      onLevelChanged: onLevelChanged,
      onNext: onNext,
    );
  }
}

// ─── Shared body ────────────────────────────────────────────────────────────

const List<String> _cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

class _LanguageStepBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Language? selectedLanguage;
  final String? selectedLevel;
  final bool isNative;
  final bool isLoadingLanguages;
  final List<Language> allLanguages;
  final Language? excludeLanguage;
  final ValueChanged<Language> onLanguageSelected;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const _LanguageStepBody({
    required this.title,
    required this.subtitle,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.isNative,
    required this.isLoadingLanguages,
    required this.allLanguages,
    required this.excludeLanguage,
    required this.onLanguageSelected,
    required this.onLevelChanged,
    required this.onNext,
  });

  Future<void> _openPicker(BuildContext context) async {
    if (isLoadingLanguages || allLanguages.isEmpty) return;
    // CRITICAL GUARD: exclude the language already chosen on the other side
    // (native excludes learning, learning excludes native). This mirrors the
    // backend's rejection rule and prevents users from ever being able to
    // pick the same language twice — the root cause of the 23-user stuck
    // cohort where the backend silently 400'd on save.
    final selectable = excludeLanguage == null
        ? allLanguages
        : allLanguages
            .where((lang) => lang.code != excludeLanguage!.code)
            .toList();

    final result = await showModalBottomSheet<Language>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LanguagePickerSheet(
        languages: selectable,
        selectedLanguage: selectedLanguage,
      ),
    );

    if (result != null) {
      onLanguageSelected(result);
    }
  }

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
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),

          const SizedBox(height: 32),

          _LanguageCard(
            selectedLanguage: selectedLanguage,
            isLoadingLanguages: isLoadingLanguages,
            onTap: () => _openPicker(context),
          ),

          if (selectedLanguage != null) ...[
            const SizedBox(height: 28),
            Text(
              isNative
                  ? l10n.yourLevelIn(selectedLanguage!.name)
                  : l10n.yourCurrentLevel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._cefrLevels.map(
              (level) => _LevelTile(
                level: level,
                isSelected: selectedLevel == level,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onLevelChanged(level);
                },
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

class _LanguageCard extends StatelessWidget {
  final Language? selectedLanguage;
  final bool isLoadingLanguages;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.selectedLanguage,
    required this.isLoadingLanguages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoadingLanguages ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selectedLanguage != null
              ? AppColors.primary.withValues(alpha: 0.06)
              : context.cardBackground,
          borderRadius: AppRadius.borderLG,
          border: Border.all(
            color: selectedLanguage != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : context.dividerColor,
            width: selectedLanguage != null ? 2 : 1,
          ),
        ),
        child: isLoadingLanguages
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  if (selectedLanguage != null) ...[
                    Text(selectedLanguage!.flag,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLanguage!.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedLanguage!.nativeName,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: AppRadius.borderMD,
                      ),
                      child: Icon(Icons.language,
                          size: 28, color: context.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.tapToSelectLanguage,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  Icon(Icons.chevron_right, color: context.textSecondary),
                ],
              ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  String _description(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 'A1':
        return l10n.beginner;
      case 'A2':
        return l10n.elementary;
      case 'B1':
        return l10n.intermediate;
      case 'B2':
        return l10n.upperIntermediate;
      case 'C1':
        return l10n.advanced;
      case 'C2':
        return l10n.proficient;
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : context.cardBackground,
            borderRadius: AppRadius.borderMD,
            border: Border.all(
              color: isSelected ? AppColors.primary : context.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : context.containerColor,
                  borderRadius: AppRadius.borderSM,
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isSelected ? Colors.white : context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _description(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Searchable language picker sheet ───────────────────────────────────────

/// Bottom-sheet language picker: search field on top, rows below showing
/// flag emoji + native name + English name, teal check on the selected row.
///
/// The caller (`_LanguageStepBody._openPicker`) is responsible for filtering
/// out the language already chosen on the other side (native/learning
/// mutual exclusion) before constructing this widget — this sheet itself
/// just renders whatever list it's given.
class _LanguagePickerSheet extends StatefulWidget {
  final List<Language> languages;
  final Language? selectedLanguage;

  const _LanguagePickerSheet({
    required this.languages,
    required this.selectedLanguage,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<Language> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = _sorted(widget.languages);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Language> _sorted(List<Language> languages) {
    final sorted = List<Language>.from(languages);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = _sorted(widget.languages);
      } else {
        _filtered = _sorted(
          widget.languages.where((lang) {
            return lang.name.toLowerCase().contains(query) ||
                lang.nativeName.toLowerCase().contains(query);
          }).toList(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      hintStyle: TextStyle(color: context.textHint),
                      prefixIcon: Icon(Icons.search, color: context.textHint),
                      filled: true,
                      fillColor: context.containerColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 56, color: context.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noLanguagesFound,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final lang = _filtered[index];
                            final isSelected =
                                widget.selectedLanguage?.code == lang.code;
                            return InkWell(
                              onTap: () => Navigator.pop(context, lang),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Text(lang.flag,
                                        style: const TextStyle(fontSize: 30)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.nativeName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lang.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary, size: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
