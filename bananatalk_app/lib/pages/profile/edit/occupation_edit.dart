import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/occupation_options.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tabs-style occupation edit. One tab per category from
/// [kOccupationCategories]; tapping an option selects it. A search bar at
/// the top filters across every category; if the search text matches
/// nothing in the list (or the user just wants their own wording) they
/// can submit it as a custom occupation. Selected value — predefined or
/// custom — appears in a pinned "Current" card above the tabs so it's
/// visible from any tab.
///
/// Backend storage is unchanged (single String, ≤80 chars).
class OccupationEdit extends ConsumerStatefulWidget {
  const OccupationEdit({super.key, required this.currentOccupation});

  final String currentOccupation;

  @override
  ConsumerState<OccupationEdit> createState() => _OccupationEditState();
}

class _OccupationEditState extends ConsumerState<OccupationEdit>
    with SingleTickerProviderStateMixin {
  static const int _maxLength = 80;

  /// Index of the synthetic "Custom" tab appended after the predefined
  /// categories. Used to drive both the TabController and the body switch
  /// that swaps the option list for the custom-input editor.
  int get _customTabIndex => kOccupationCategories.length;

  late String? _selected;
  bool _isSaving = false;
  final TextEditingController _search = TextEditingController();
  final TextEditingController _customInput = TextEditingController();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentOccupation.isEmpty
        ? null
        : widget.currentOccupation;
    _search.addListener(_onSearchChanged);
    _customInput.addListener(_onCustomChanged);

    // Open the tab that contains the current selection. Custom selections
    // open directly on the Custom tab with the field pre-filled, so the
    // user can edit instead of starting over.
    final selected = _selected;
    final int initialIndex;
    if (selected != null && _categoryIndexOf(selected) == null) {
      initialIndex = _customTabIndex;
      _customInput.text = selected;
    } else {
      initialIndex = _categoryIndexOf(selected) ?? 0;
    }
    _tabs = TabController(
      length: kOccupationCategories.length + 1, // +1 for the Custom tab
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _onCustomChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    _customInput
      ..removeListener(_onCustomChanged)
      ..dispose();
    _tabs.dispose();
    super.dispose();
  }

  // ─── Derived state ──────────────────────────────────────────────────────
  bool get _hasChanges =>
      (_selected ?? '') != widget.currentOccupation.trim();

  bool get _canSave => _hasChanges && !_isSaving;

  /// Index of the category that contains [value], or null if [value] is a
  /// custom occupation that doesn't belong to any predefined category.
  int? _categoryIndexOf(String? value) {
    if (value == null || value.isEmpty) return null;
    for (var i = 0; i < kOccupationCategories.length; i++) {
      if (kOccupationCategories[i].options.contains(value)) return i;
    }
    return null;
  }

  bool get _selectedIsCustom =>
      _selected != null && _categoryIndexOf(_selected) == null;

  // ─── Actions ────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authServiceProvider)
          .updateOccupation(occupation: _selected ?? '');
      ref.invalidate(userProvider);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.profileUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context, _selected);
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

  void _select(String option) {
    HapticFeedback.selectionClick();
    setState(() => _selected = option);
  }

  /// Commits the text in the dedicated Custom-tab field as the selected
  /// occupation. Capped at [_maxLength] to match the backend column.
  void _selectCustomFromInput() {
    final raw = _customInput.text.trim();
    if (raw.isEmpty) return;
    final value = raw.length > _maxLength ? raw.substring(0, _maxLength) : raw;
    HapticFeedback.selectionClick();
    setState(() => _selected = value);
    FocusScope.of(context).unfocus();
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _search.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;
    final canTap = _canSave && !_isSaving;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.occupation,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canTap ? _save : null,
              style: TextButton.styleFrom(
                backgroundColor: canTap
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.2),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
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
      body: Column(
        children: [
          _buildSearchBar(),
          if (_selected != null) _buildSelectionBanner(),
          _buildTabBar(),
          Expanded(
            child: isSearching
                ? _buildSearchResults(query)
                : _buildTabBarView(),
          ),
          _buildSaveBar(),
        ],
      ),
    );
  }

  // ─── Search bar ─────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : context.dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _search,
          enabled: !_isSaving,
          textInputAction: TextInputAction.search,
          style: context.bodyMedium,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.occupationSearchHint,
            hintStyle: context.bodyMedium.copyWith(color: context.textHint),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.textMuted,
              size: 20,
            ),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.textMuted,
                    ),
                    onPressed: _isSaving ? null : () => _search.clear(),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Current selection banner ───────────────────────────────────────────
  Widget _buildSelectionBanner() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCustom = _selectedIsCustom;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCustom ? Icons.edit_rounded : Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCustom
                        ? l10n.occupationCustomLabel
                        : l10n.occupationSelectedLabel,
                    style: context.captionSmall.copyWith(
                      color: context.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selected!,
                    style: context.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab bar ────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: context.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: [
          for (final category in kOccupationCategories)
            Tab(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(_localizedCategoryName(context, category)),
                ],
              ),
            ),
          // Custom tab — dedicated free-text input for occupations that
          // don't appear in any predefined category.
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✏️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context)!.occupationCustomTab),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab bar view ───────────────────────────────────────────────────────
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabs,
      children: [
        for (final category in kOccupationCategories)
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: category.options.length,
            itemBuilder: (_, i) => _optionRow(category.options[i]),
          ),
        _buildCustomTab(),
      ],
    );
  }

  // ─── Custom tab body ────────────────────────────────────────────────────
  Widget _buildCustomTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _customInput.text.trim();
    final canSubmit = text.isNotEmpty && text != _selected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Text(
          l10n.occupationCustomTabHint,
          style: context.bodyMedium.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : context.dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _customInput,
            enabled: !_isSaving,
            maxLength: _maxLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => canSubmit ? _selectCustomFromInput() : null,
            style: context.bodyLarge.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: l10n.occupationCustomInputHint,
              hintStyle:
                  context.bodyMedium.copyWith(color: context.textHint),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: context.textMuted,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: canSubmit ? _selectCustomFromInput : null,
            style: TextButton.styleFrom(
              backgroundColor: canSubmit
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.25),
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.occupationCustomSaveCTA,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Search results (flat filtered list) ────────────────────────────────
  Widget _buildSearchResults(String query) {
    final l10n = AppLocalizations.of(context)!;
    final matches = kAllOccupationOptions
        .where((o) => o.toLowerCase().contains(query))
        .toList();
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: context.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.occupationNoMatches,
              style: context.bodyMedium.copyWith(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              // The empty-state hint now points users at the Custom tab
              // (where they can enter their own profession) instead of an
              // inline CTA.
              l10n.occupationCustomTabHint,
              style: context.captionSmall.copyWith(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () {
                      _search.clear();
                      _tabs.animateTo(_customTabIndex);
                    },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(l10n.occupationCustomTab),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: matches.length,
      itemBuilder: (_, i) => _optionRow(matches[i]),
    );
  }

  // ─── Option row ─────────────────────────────────────────────────────────
  Widget _optionRow(String option) {
    final isSelected = _selected == option;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : () => _select(option),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10)
                  : context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : context.dividerColor.withValues(alpha: 0.4)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: context.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : context.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Maps a category's stable [OccupationCategory.id] to its localized
  /// display name. Falls back to the English [OccupationCategory.name] if
  /// the id is unknown (e.g., a new category was added to the data file
  /// but no ARB entry exists yet).
  String _localizedCategoryName(
    BuildContext context,
    OccupationCategory category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.id) {
      case 'tech':
        return l10n.occupationCatTech;
      case 'healthcare':
        return l10n.occupationCatHealthcare;
      case 'education':
        return l10n.occupationCatEducation;
      case 'business':
        return l10n.occupationCatBusiness;
      case 'creative':
        return l10n.occupationCatCreative;
      case 'media':
        return l10n.occupationCatMedia;
      case 'engineering':
        return l10n.occupationCatEngineering;
      case 'science':
        return l10n.occupationCatScience;
      case 'legal':
        return l10n.occupationCatLegal;
      case 'hospitality':
        return l10n.occupationCatHospitality;
      case 'trades':
        return l10n.occupationCatTrades;
      case 'transport':
        return l10n.occupationCatTransport;
      case 'government':
        return l10n.occupationCatGovernment;
      case 'retail':
        return l10n.occupationCatRetail;
      case 'agriculture':
        return l10n.occupationCatAgriculture;
      case 'sports':
        return l10n.occupationCatSports;
      case 'beauty':
        return l10n.occupationCatBeauty;
      case 'realEstate':
        return l10n.occupationCatRealEstate;
      case 'religion':
        return l10n.occupationCatReligion;
      case 'student':
        return l10n.occupationCatStudent;
      case 'other':
        return l10n.occupationCatOther;
      default:
        return category.name;
    }
  }

  // ─── Bottom save bar ────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: GradientSaveButton(
          canSave: _canSave,
          isSaving: _isSaving,
          onPressed: _save,
        ),
      ),
    );
  }
}
