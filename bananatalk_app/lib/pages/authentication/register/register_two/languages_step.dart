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
const List<String> _cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

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
                    Text(
                      selectedLanguage!.flag,
                      style: const TextStyle(fontSize: 36),
                    ),
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
                      child: Icon(
                        Icons.language,
                        size: 28,
                        color: context.textSecondary,
                      ),
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
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
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
                              Icon(
                                Icons.search_off,
                                size: 56,
                                color: context.textMuted,
                              ),
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
                                    Text(
                                      lang.flag,
                                      style: const TextStyle(fontSize: 30),
                                    ),
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
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
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

/// Both language choices on one screen.
///
/// Replaces the separate native/learning pages. The wizard is where Apple and
/// Google signups are lost — 301 blank accounts on prod, 282 of 298 never
/// returning — and these were the last two pages of it, asking one question
/// each. Together they read as a single idea: the pair that gets you matched.
///
/// The exclusion guard is unchanged and load-bearing: each side's picker is
/// given the other side's language to exclude, so the same language can never
/// be chosen twice. The backend refuses that pair, and a picker that allowed
/// it produced an earlier cohort stuck on a silent 400.
///
/// Validation stays with the parent, which owns the error copy and already
/// distinguishes "no language" from "no level".
class LanguagesStep extends StatelessWidget {
  final Language? nativeLanguage;
  final Language? learningLanguage;
  final String? nativeLevel;
  final String? learningLevel;
  final bool isLoadingLanguages;
  final List<Language> allLanguages;
  final ValueChanged<Language> onNativeSelected;
  final ValueChanged<Language> onLearningSelected;
  final ValueChanged<String> onNativeLevelChanged;
  final ValueChanged<String> onLearningLevelChanged;
  final VoidCallback onSwap;
  final VoidCallback onNext;

  const LanguagesStep({
    super.key,
    required this.nativeLanguage,
    required this.learningLanguage,
    required this.nativeLevel,
    required this.learningLevel,
    required this.isLoadingLanguages,
    required this.allLanguages,
    required this.onNativeSelected,
    required this.onLearningSelected,
    required this.onNativeLevelChanged,
    required this.onLearningLevelChanged,
    required this.onSwap,
    required this.onNext,
  });

  Future<void> _pick(
    BuildContext context, {
    required Language? exclude,
    required ValueChanged<Language> onSelected,
    required Language? current,
  }) async {
    if (isLoadingLanguages || allLanguages.isEmpty) return;
    final selectable = exclude == null
        ? allLanguages
        : allLanguages.where((l) => l.code != exclude.code).toList();

    final result = await showModalBottomSheet<Language>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LanguagePickerSheet(
        languages: selectable,
        selectedLanguage: current,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bothChosen = nativeLanguage != null && learningLanguage != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.languagesStepTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.languagesStepSubtitle,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),
          const SizedBox(height: 28),

          _LanguageSide(
            cardKey: const Key('languages-native-card'),
            levelKeyPrefix: 'native',
            label: l10n.languagesISpeak,
            language: nativeLanguage,
            level: nativeLevel,
            levelLabel: nativeLanguage == null
                ? null
                : l10n.yourLevelIn(nativeLanguage!.name),
            isLoadingLanguages: isLoadingLanguages,
            onTap: () => _pick(
              context,
              exclude: learningLanguage,
              current: nativeLanguage,
              onSelected: onNativeSelected,
            ),
            onLevelChanged: onNativeLevelChanged,
          ),

          // The connector doubles as the swap control once both sides are
          // set — the commonest correction on this screen is having them the
          // wrong way round, and re-picking both costs four taps.
          _Connector(
            showSwap: bothChosen,
            swapLabel: l10n.languagesSwap,
            onSwap: onSwap,
          ),

          _LanguageSide(
            cardKey: const Key('languages-learning-card'),
            levelKeyPrefix: 'learning',
            label: l10n.languagesImLearning,
            language: learningLanguage,
            level: learningLevel,
            levelLabel: learningLanguage == null ? null : l10n.yourCurrentLevel,
            isLoadingLanguages: isLoadingLanguages,
            onTap: () => _pick(
              context,
              exclude: nativeLanguage,
              current: learningLanguage,
              onSelected: onLearningSelected,
            ),
            onLevelChanged: onLearningLevelChanged,
          ),

          const SizedBox(height: 32),
          AuthGradientButton(
            key: const Key('languages-continue'),
            label: l10n.continueButton,
            onPressed: onNext,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// One side of the pair: a heading, the language card, and — once a language
/// is chosen — its CEFR level as a compact chip row. Chips rather than the
/// full-width tiles the separate pages used: two stacked six-row lists would
/// not fit a phone screen, which is what made one-question-per-page feel
/// necessary in the first place.
class _LanguageSide extends StatelessWidget {
  final Key cardKey;
  final String levelKeyPrefix;
  final String label;
  final Language? language;
  final String? level;
  final String? levelLabel;
  final bool isLoadingLanguages;
  final VoidCallback onTap;
  final ValueChanged<String> onLevelChanged;

  const _LanguageSide({
    required this.cardKey,
    required this.levelKeyPrefix,
    required this.label,
    required this.language,
    required this.level,
    required this.levelLabel,
    required this.isLoadingLanguages,
    required this.onTap,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: cardKey,
          child: _LanguageCard(
            selectedLanguage: language,
            isLoadingLanguages: isLoadingLanguages,
            onTap: onTap,
          ),
        ),
        if (language != null && levelLabel != null) ...[
          const SizedBox(height: 14),
          Text(
            levelLabel!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cefrLevels
                .map(
                  (l) => _LevelChip(
                    key: Key('$levelKeyPrefix-level-$l'),
                    level: l,
                    isSelected: level == l,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onLevelChanged(l);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelChip({
    super.key,
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.cardBackground,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: isSelected ? AppColors.primary : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          level,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The vertical rule between the two sides, carrying the swap affordance.
class _Connector extends StatelessWidget {
  final bool showSwap;
  final String swapLabel;
  final VoidCallback onSwap;

  const _Connector({
    required this.showSwap,
    required this.swapLabel,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Container(width: 2, height: 28, color: context.dividerColor),
          if (showSwap) ...[
            const SizedBox(width: 14),
            TextButton.icon(
              key: const Key('languages-swap'),
              onPressed: () {
                HapticFeedback.selectionClick();
                onSwap();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.swap_vert, size: 18),
              label: Text(swapLabel),
            ),
          ],
        ],
      ),
    );
  }
}
