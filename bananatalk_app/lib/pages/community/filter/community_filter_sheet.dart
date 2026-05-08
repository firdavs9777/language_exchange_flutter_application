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
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;
  bool _isDetectingLocation = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeValues();
    fetchLanguages();
  }

  void _initializeValues() {
    _minAge = (widget.initialFilters['minAge'] ?? 18).toDouble();
    _maxAge = (widget.initialFilters['maxAge'] ?? 100).toDouble();
    _selectedGender = widget.initialFilters['gender'];
    _selectedCountry = widget.initialFilters['country'];
    _onlineOnly = widget.initialFilters['onlineOnly'] ?? false;
    _newUsersOnly = widget.initialFilters['newUsersOnly'] ?? false;
    _prioritizeNearby = widget.initialFilters['prioritizeNearby'] ?? false;
    // _selectedLanguage will be set after languages are loaded in fetchLanguages()
  }

  Future<void> fetchLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> languagesList = data['data'] ?? [];

        setState(() {
          _languages = languagesList
              .map<Language>((json) => Language.fromJson(json))
              .toList();
          _isLoadingLanguages = false;
        });

        // Set selected native language from initial filters after languages are loaded
        if (widget.initialFilters['nativeLanguage'] != null &&
            _languages.isNotEmpty) {
          final initialLangName = widget.initialFilters['nativeLanguage'];
          try {
            final matchingLanguage = _languages.firstWhere(
              (lang) => lang.name == initialLangName,
            );
            if (mounted) {
              setState(() {
                _selectedLanguage = matchingLanguage;
              });
            }
          } catch (e) {
            // Language not found, leave as null (Any Language)
            if (kDebugMode) {}
          }
        }

        // Set selected learning language from initial filters
        if (widget.initialFilters['learningLanguage'] != null &&
            _languages.isNotEmpty) {
          final initialLearningLangName =
              widget.initialFilters['learningLanguage'];
          try {
            final matchingLanguage = _languages.firstWhere(
              (lang) => lang.name == initialLearningLangName,
            );
            if (mounted) {
              setState(() {
                _selectedLearningLanguage = matchingLanguage;
              });
            }
          } catch (e) {
            // Language not found
          }
        }

        // Set selected language level from initial filters
        if (widget.initialFilters['languageLevel'] != null && mounted) {
          setState(() {
            _selectedLanguageLevel =
                widget.initialFilters['languageLevel'] as String?;
          });
        }
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      setState(() {
        _isLoadingLanguages = false;
        _errorMessage = 'Failed to load languages. Please try again.';
      });
      if (kDebugMode) {}
    }
  }

  bool get _isVip {
    final user = ref.read(userProvider).valueOrNull;
    return user?.isVip ?? false;
  }

  void _showVipPrompt() {
    final user = ref.read(userProvider).valueOrNull;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => VipPlansScreen(userId: user?.id),
      ),
    );
  }

  void resetFilters() {
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
    });
  }

  void _applyFilters() {
    // Convert gender to lowercase to match backend format
    String? genderValue = _selectedGender?.toLowerCase();

    final filters = {
      'minAge': _minAge.toInt(),
      'maxAge': _maxAge.toInt(),
      'gender': genderValue,
      'nativeLanguage': _selectedLanguage?.name,
      'learningLanguage': _selectedLearningLanguage?.name,
      'languageLevel': _selectedLanguageLevel,
      'country': _selectedCountry,
      'onlineOnly': _onlineOnly,
      'newUsersOnly': _newUsersOnly,
      'prioritizeNearby': _prioritizeNearby,
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
          setState(() {
            _selectedCountry = country;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

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
        setState(() {
          _isDetectingLocation = false;
        });
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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Location detected: $_selectedCountry'),
                  ],
                ),
                backgroundColor: const Color(0xFF00BFA5),
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _isDetectingLocation = false;
      });

      if (mounted) {
        showCommunitySnackBar(
          context,
          message: 'Could not detect country',
          type: CommunitySnackBarType.info,
        );
      }
    } catch (e) {
      setState(() {
        _isDetectingLocation = false;
      });

      if (mounted) {
        showCommunitySnackBar(
          context,
          message: 'Error: ${e.toString()}',
          type: CommunitySnackBarType.error,
        );
      }
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
      setState(() {
        _selectedLanguage = result;
      });
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
      setState(() {
        _selectedLearningLanguage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
          // Header row with X, title, Reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon:
                      Icon(Icons.close_rounded, color: context.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    l10n.filterCommunities,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: resetFilters,
                  child: Text(
                    l10n.reset,
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header Banner
          _buildHeaderBanner(),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: l10n.nativeLanguage,
                    icon: Icons.translate,
                    child: _isLoadingLanguages
                        ? const FilterLanguageLoadingCard()
                        : _errorMessage.isNotEmpty
                            ? FilterLanguageErrorCard(
                                errorMessage: _errorMessage,
                                onRetry: () {
                                  setState(() {
                                    _isLoadingLanguages = true;
                                    _errorMessage = '';
                                  });
                                  fetchLanguages();
                                },
                              )
                            : FilterLanguageSelector(
                                selectedLanguage: _selectedLanguage,
                                onTap: _openLanguagePicker,
                                placeholderIcon: Icons.public,
                              ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: l10n.learningLanguageLabel,
                    icon: Icons.school,
                    child: _isLoadingLanguages
                        ? const FilterLanguageLoadingCard()
                        : _errorMessage.isNotEmpty
                            ? FilterLanguageErrorCard(
                                errorMessage: _errorMessage,
                                onRetry: () {
                                  setState(() {
                                    _isLoadingLanguages = true;
                                    _errorMessage = '';
                                  });
                                  fetchLanguages();
                                },
                              )
                            : FilterLanguageSelector(
                                selectedLanguage: _selectedLearningLanguage,
                                onTap: _openLearningLanguagePicker,
                                placeholderIcon: Icons.school,
                              ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: l10n.languageLevel,
                    icon: Icons.signal_cellular_alt,
                    child: FilterLevelSection(
                      selectedLevel: _selectedLanguageLevel,
                      onChanged: (level) =>
                          setState(() => _selectedLanguageLevel = level),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildVipGatedSection(
                    title: l10n.country,
                    icon: Icons.public,
                    child: FilterCountrySelector(
                      selectedCountry: _selectedCountry,
                      isDetectingLocation: _isDetectingLocation,
                      onDetectLocation: _autoDetectLocation,
                      onOpenPicker: _openCountryPicker,
                      onClear: () =>
                          setState(() => _selectedCountry = null),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: l10n.ageRange,
                    icon: Icons.cake,
                    child: FilterAgeSection(
                      minAge: _minAge,
                      maxAge: _maxAge,
                      onChanged: (values) => setState(() {
                        _minAge = values.start;
                        _maxAge = values.end;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildVipGatedSection(
                    title: l10n.genderPreference,
                    icon: Icons.person,
                    child: FilterGenderSection(
                      selectedGender: _selectedGender,
                      onChanged: (g) =>
                          setState(() => _selectedGender = g),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilterToggleRow(
                    title: l10n.filterOnlineNow,
                    subtitle: l10n.onlineNow,
                    icon: Icons.circle,
                    value: _onlineOnly,
                    activeColor: AppColors.success,
                    onChanged: (val) =>
                        setState(() => _onlineOnly = val),
                  ),
                  const SizedBox(height: 16),
                  FilterToggleRow(
                    title: l10n.newUsersOnly,
                    subtitle: l10n.showNewUsersSubtitle,
                    icon: Icons.fiber_new_rounded,
                    value: _newUsersOnly,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (val) =>
                        setState(() => _newUsersOnly = val),
                  ),
                  const SizedBox(height: 24),
                  _buildPrioritizeNearbyToggle(l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Fixed Bottom Buttons
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              boxShadow: AppShadows.sm,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.applyFilters,
                        style: context.titleMedium
                            .copyWith(color: context.textOnPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () {
                        resetFilters();
                        _applyFilters();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restart_alt_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            l10n.reset,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor,
            context.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.findYourPerfect,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  l10n.languagePartner,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: context.primaryColor),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// VIP-gated section: shows content but intercepts taps for non-VIP users.
  Widget _buildVipGatedSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: context.primaryColor),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            if (!_isVip) _buildVipBadge(),
          ],
        ),
        const SizedBox(height: 12),
        if (_isVip)
          child
        else
          GestureDetector(
            onTap: _showVipPrompt,
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.5,
                  child: IgnorePointer(child: child),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderMD,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
    final hasLocation = userAsync.whenOrNull(
          data: (user) {
            final coords = user.location.coordinates;
            return coords.length >= 2 &&
                (coords[0] != 0.0 || coords[1] != 0.0);
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
          onChanged: (val) => setState(() => _prioritizeNearby = val),
        ),
        if (_prioritizeNearby && !hasLocation) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.updateLocationReminder,
                    style: context.caption
                        .copyWith(color: Colors.orange.shade800),
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
        Row(
          children: [
            const SizedBox(width: 8),
            _buildVipBadge(),
          ],
        ),
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
