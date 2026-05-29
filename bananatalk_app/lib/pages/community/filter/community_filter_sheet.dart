import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/filter/filter_age_section.dart';
import 'package:bananatalk_app/pages/community/filter/filter_gender_section.dart';
import 'package:bananatalk_app/pages/community/filter/filter_languages_section.dart';
import 'package:bananatalk_app/pages/community/filter/filter_country_section.dart';
import 'package:bananatalk_app/pages/community/filter/filter_level_section.dart';
import 'package:bananatalk_app/pages/community/filter/filter_toggles_section.dart';
import 'package:bananatalk_app/pages/community/filter/filter_topics_section.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';

class CommunityFilter extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> filters) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  const CommunityFilter({
    super.key,
    required this.onApplyFilters,
    required this.initialFilters,
  });

  @override
  ConsumerState<CommunityFilter> createState() => _CommunityFilterState();
}

class _CommunityFilterState extends ConsumerState<CommunityFilter> {
  late double _minAge = 18;
  late double _maxAge = 100;
  late String? _selectedGender;
  Language? _selectedLanguage;
  Language? _selectedLearningLanguage;
  String? _selectedLanguageLevel;
  String? _selectedCountry;
  bool _onlineOnly = false;
  bool _newUsersOnly = false;
  bool _prioritizeNearby = false;
  int _topicsAtLeast = 0;
  List<String> _selectedTopics = [];
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;
  bool _isDetectingLocation = false;
  String _errorMessage = '';

  Timer? _matchCountDebounce;

  /// The filter set the live match-count is computed for.
  ///
  /// IMPORTANT: this must be a STABLE instance between debounces. The match-count
  /// provider is a `.family` keyed by this map; if we rebuilt the map on every
  /// `build()` (Maps use identity equality), every rebuild would spin up a new
  /// provider instance and fire a fresh network request. We only assign a new
  /// instance when filters actually settle (after the debounce), so unrelated
  /// rebuilds reuse the same family instance and don't refetch.
  Map<String, dynamic> _draftFilters = const {};

  @override
  void initState() {
    super.initState();
    _initializeValues();
    fetchLanguages();
  }

  @override
  void dispose() {
    _matchCountDebounce?.cancel();
    super.dispose();
  }

  void _initializeValues() {
    _minAge = (widget.initialFilters['minAge'] ?? 18).toDouble();
    _maxAge = (widget.initialFilters['maxAge'] ?? 100).toDouble();
    _selectedGender = widget.initialFilters['gender'];
    _selectedCountry = widget.initialFilters['country'];
    _onlineOnly = widget.initialFilters['onlineOnly'] ?? false;
    _newUsersOnly = widget.initialFilters['newUsersOnly'] ?? false;
    _prioritizeNearby = widget.initialFilters['prioritizeNearby'] ?? false;
    _topicsAtLeast =
        (widget.initialFilters['topicsAtLeast'] as num?)?.toInt() ?? 0;
    _selectedTopics =
        (widget.initialFilters['topics'] as List?)?.cast<String>() ?? [];
    // Seed the count with the initial state. Language selections are resolved
    // asynchronously in fetchLanguages(), which refreshes the draft afterwards.
    _draftFilters = _buildDraftFiltersMap();
  }

  Future<void> fetchLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> languagesList = data['data'] ?? [];

        setState(() {
          _languages = languagesList
              .map<Language>((json) => Language.fromJson(json))
              .toList();
          _isLoadingLanguages = false;
        });

        // Resolve native language from initial filters.
        final initialNative = widget.initialFilters['nativeLanguage'];
        if (initialNative != null && _languages.isNotEmpty) {
          final match = _languages
              .where((lang) => lang.name == initialNative)
              .firstOrNull;
          if (match != null) _selectedLanguage = match;
        }

        // Resolve learning language from initial filters.
        final initialLearning = widget.initialFilters['learningLanguage'];
        if (initialLearning != null && _languages.isNotEmpty) {
          final match = _languages
              .where((lang) => lang.name == initialLearning)
              .firstOrNull;
          if (match != null) _selectedLearningLanguage = match;
        }

        // Resolve language level from initial filters.
        _selectedLanguageLevel ??=
            widget.initialFilters['languageLevel'] as String?;

        // Refresh the count now that language selections are known.
        _refreshDraftFilters();
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLanguages = false;
        _errorMessage = 'Failed to load languages. Please try again.';
      });
      if (kDebugMode) debugPrint('fetchLanguages failed: $e');
    }
  }

  bool get _isVip {
    // VIP gating disabled product-wide — filter restrictions removed.
    return true;
  }

  void _showVipPrompt() {
    final user = ref.read(userProvider).valueOrNull;
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => VipPlansScreen(userId: user?.id)),
    );
  }

  /// Called whenever any filter value changes. Reflects the change in the UI
  /// immediately, then refreshes the live match-count 300 ms after the last
  /// change (debounced) by swapping in a new [_draftFilters] instance.
  void _onAnyFilterChanged() {
    setState(() {});
    _matchCountDebounce?.cancel();
    _matchCountDebounce = Timer(
      const Duration(milliseconds: 300),
      _refreshDraftFilters,
    );
  }

  /// Assigns a fresh draft-filters map so the match-count family re-evaluates
  /// exactly once. Safe to call from async callbacks (guards on mounted).
  void _refreshDraftFilters() {
    if (!mounted) return;
    setState(() => _draftFilters = _buildDraftFiltersMap());
  }

  /// Serialises the current sheet state into a plain Map for the count endpoint.
  Map<String, dynamic> _buildDraftFiltersMap() {
    return {
      'minAge': _minAge.toInt(),
      'maxAge': _maxAge.toInt(),
      if (_selectedGender != null) 'gender': _selectedGender!.toLowerCase(),
      if (_selectedLanguage != null) 'nativeLanguage': _selectedLanguage!.name,
      if (_selectedLearningLanguage != null)
        'learningLanguage': _selectedLearningLanguage!.name,
      if (_selectedLanguageLevel != null)
        'languageLevel': _selectedLanguageLevel,
      if (_selectedCountry != null) 'country': _selectedCountry,
      'onlineOnly': _onlineOnly,
      'newUsersOnly': _newUsersOnly,
      'prioritizeNearby': _prioritizeNearby,
      if (_topicsAtLeast > 0) 'topicsAtLeast': _topicsAtLeast,
      if (_selectedTopics.isNotEmpty) 'topics': _selectedTopics,
    };
  }

  void _clearAll() {
    setState(() {
      _minAge = 18.0;
      _maxAge = 100.0;
      _selectedGender = null;
      _selectedLanguage = null;
      _selectedLearningLanguage = null;
      _selectedLanguageLevel = null;
      _selectedCountry = null;
      _onlineOnly = false;
      _newUsersOnly = false;
      _prioritizeNearby = false;
      _topicsAtLeast = 0;
      _selectedTopics = [];
    });
    _onAnyFilterChanged();
  }

  void _applyFilters() {
    final filters = {
      'minAge': _minAge.toInt(),
      'maxAge': _maxAge.toInt(),
      'gender': _selectedGender?.toLowerCase(),
      'nativeLanguage': _selectedLanguage?.name,
      'learningLanguage': _selectedLearningLanguage?.name,
      'languageLevel': _selectedLanguageLevel,
      'country': _selectedCountry,
      'onlineOnly': _onlineOnly,
      'newUsersOnly': _newUsersOnly,
      'prioritizeNearby': _prioritizeNearby,
      'topicsAtLeast': _topicsAtLeast,
      'topics': _selectedTopics,
    };

    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
          _onAnyFilterChanged();
        },
      ),
    );
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        if (mounted) {
          showCommunitySnackBar(
            context,
            message: 'Location permission is required',
            type: CommunitySnackBarType.info,
          );
        }
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      await setLocaleIdentifier('en_US');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final country = placemarks[0].country;

        if (country != null) {
          final matchingCountry = kAllCountries.firstWhere(
            (c) =>
                c['name']!.toLowerCase() == country.toLowerCase() ||
                c['name']!.toLowerCase().contains(country.toLowerCase()) ||
                country.toLowerCase().contains(c['name']!.toLowerCase()),
            orElse: () => {'name': country},
          );

          setState(() {
            _selectedCountry = matchingCountry['name'] ?? country;
            _isDetectingLocation = false;
          });
          _onAnyFilterChanged();

          if (mounted) {
            showCommunitySnackBar(
              context,
              message: AppLocalizations.of(
                context,
              )!.communityLocationDetected(_selectedCountry ?? ''),
              type: CommunitySnackBarType.success,
            );
          }
          return;
        }
      }

      setState(() => _isDetectingLocation = false);
      if (mounted) {
        showCommunitySnackBar(
          context,
          message: 'Could not detect country',
          type: CommunitySnackBarType.info,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDetectingLocation = false);
      showCommunitySnackBar(
        context,
        message: 'Error: ${e.toString()}',
        type: CommunitySnackBarType.error,
      );
    }
  }

  Future<void> _openLanguagePicker() async {
    if (_languages.isEmpty) {
      showCommunitySnackBar(
        context,
        message: AppLocalizations.of(context)!.languagesAreStillLoading,
        type: CommunitySnackBarType.success,
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

    if (result != null) {
      setState(() => _selectedLanguage = result);
      _onAnyFilterChanged();
    }
  }

  Future<void> _openLearningLanguagePicker() async {
    if (_languages.isEmpty) {
      showCommunitySnackBar(
        context,
        message: AppLocalizations.of(context)!.languagesAreStillLoading,
        type: CommunitySnackBarType.success,
      );
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      AppPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: _selectedLearningLanguage,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedLearningLanguage = result);
      _onAnyFilterChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Watch the STABLE draft instance — only changes on debounce / settle.
    final countAsync = ref.watch(filterMatchCountProvider(_draftFilters));

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Sticky top — title + live match count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      l10n.filterSheetTitle,
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  countAsync.when(
                    data: (n) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        l10n.filterMatchCount(n),
                        style: context.bodyMedium.copyWith(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable body — sections in ExpansionTiles
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      l10n.filterAge,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      FilterAgeSection(
                        minAge: _minAge,
                        maxAge: _maxAge,
                        onChanged: (values) {
                          setState(() {
                            _minAge = values.start;
                            _maxAge = values.end;
                          });
                          _onAnyFilterChanged();
                        },
                      ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      l10n.filterGender,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _isVip
                          ? FilterGenderSection(
                              selectedGender: _selectedGender,
                              onChanged: (g) {
                                setState(() => _selectedGender = g);
                                _onAnyFilterChanged();
                              },
                            )
                          : GestureDetector(
                              onTap: _showVipPrompt,
                              child: Stack(
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: IgnorePointer(
                                      child: FilterGenderSection(
                                        selectedGender: _selectedGender,
                                        onChanged: (_) {},
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: _buildVipBadge(),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      l10n.filterLanguages,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildLanguageField(
                        selected: _selectedLanguage,
                        onTap: _openLanguagePicker,
                        icon: Icons.public,
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageField(
                        selected: _selectedLearningLanguage,
                        onTap: _openLearningLanguagePicker,
                        icon: Icons.school,
                      ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      l10n.filterCountry,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: !_isVip
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildVipBadge(),
                              const Icon(Icons.expand_more),
                            ],
                          )
                        : null,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _isVip
                          ? FilterCountrySelector(
                              selectedCountry: _selectedCountry,
                              isDetectingLocation: _isDetectingLocation,
                              onDetectLocation: _autoDetectLocation,
                              onOpenPicker: _openCountryPicker,
                              onClear: () {
                                setState(() => _selectedCountry = null);
                                _onAnyFilterChanged();
                              },
                            )
                          : GestureDetector(
                              onTap: _showVipPrompt,
                              child: Opacity(
                                opacity: 0.5,
                                child: IgnorePointer(
                                  child: FilterCountrySelector(
                                    selectedCountry: _selectedCountry,
                                    isDetectingLocation: false,
                                    onDetectLocation: () {},
                                    onOpenPicker: () {},
                                    onClear: () {},
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      l10n.filterLevel,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      FilterLevelSection(
                        selectedLevel: _selectedLanguageLevel,
                        onChanged: (level) {
                          setState(() => _selectedLanguageLevel = level);
                          _onAnyFilterChanged();
                        },
                      ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      l10n.filterTopicsTitle,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      FilterTopicsSection(
                        selectedTopics: _selectedTopics,
                        topics: Topic.defaultTopics,
                        onChanged: (next) {
                          setState(() => _selectedTopics = next);
                          _onAnyFilterChanged();
                        },
                      ),
                    ],
                  ),
                  ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      l10n.filterToggles,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      FilterToggleRow(
                        title: l10n.filterOnlineNow,
                        subtitle: l10n.onlineNow,
                        icon: Icons.circle,
                        value: _onlineOnly,
                        activeColor: AppColors.success,
                        onChanged: (val) {
                          setState(() => _onlineOnly = val);
                          _onAnyFilterChanged();
                        },
                      ),
                      const SizedBox(height: 12),
                      FilterToggleRow(
                        title: l10n.newUsersOnly,
                        subtitle: l10n.showNewUsersSubtitle,
                        icon: Icons.fiber_new_rounded,
                        value: _newUsersOnly,
                        activeColor: const Color(0xFF00C853),
                        onChanged: (val) {
                          setState(() => _newUsersOnly = val);
                          _onAnyFilterChanged();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPrioritizeNearbyToggle(l10n),
                      const SizedBox(height: 16),
                      FilterMutualInterestsSlider(
                        value: _topicsAtLeast,
                        onChanged: (v) {
                          setState(() => _topicsAtLeast = v);
                          _onAnyFilterChanged();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Sticky bottom — Clear all + Apply
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.clear_all_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          l10n.filterClearAll,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      l10n.filterApply,
                      style: context.titleMedium.copyWith(
                        color: context.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Native/learning language field — collapses the loading / error / selector
  /// ternary that was duplicated for both languages.
  Widget _buildLanguageField({
    required Language? selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    if (_isLoadingLanguages) return const FilterLanguageLoadingCard();
    if (_errorMessage.isNotEmpty) {
      return FilterLanguageErrorCard(
        errorMessage: _errorMessage,
        onRetry: () {
          setState(() {
            _isLoadingLanguages = true;
            _errorMessage = '';
          });
          fetchLanguages();
        },
      );
    }
    return FilterLanguageSelector(
      selectedLanguage: selected,
      onTap: onTap,
      placeholderIcon: icon,
    );
  }

  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritizeNearbyToggle(AppLocalizations l10n) {
    final userAsync = ref.watch(userProvider);
    final hasLocation =
        userAsync.whenOrNull(
          data: (user) {
            final coords = user.location.coordinates;
            return coords.length >= 2 && (coords[0] != 0.0 || coords[1] != 0.0);
          },
        ) ??
        false;

    final toggleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterToggleRow(
          title: l10n.prioritizeNearby,
          subtitle: hasLocation
              ? l10n.showNearbyFirst
              : l10n.setLocationToEnable,
          icon: Icons.near_me_rounded,
          value: _prioritizeNearby,
          activeColor: context.primaryColor,
          onChanged: (val) {
            setState(() => _prioritizeNearby = val);
            _onAnyFilterChanged();
          },
        ),
        if (_prioritizeNearby && !hasLocation) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.updateLocationReminder,
                    style: context.caption.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (_isVip) return toggleWidget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const SizedBox(width: 8), _buildVipBadge()]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showVipPrompt,
          child: Opacity(
            opacity: 0.5,
            child: IgnorePointer(child: toggleWidget),
          ),
        ),
      ],
    );
  }
}
