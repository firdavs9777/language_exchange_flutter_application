import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:bananatalk_app/providers/provider_models/location_modal.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Multi-step registration wizard (Step 2 of 2)
/// Flow: Native Language → Learning Language → Optional extras + Terms → Done
class RegisterTwo extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String password;
  final String gender;
  final String birthDate;
  final String nativeLanguage;
  final String learningLanguage;

  const RegisterTwo({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    this.gender = '',
    this.birthDate = '',
    this.nativeLanguage = '',
    this.learningLanguage = '',
  });

  @override
  ConsumerState<RegisterTwo> createState() => _RegisterTwoState();
}

class _RegisterTwoState extends ConsumerState<RegisterTwo> {
  static const List<String> _cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const Map<String, String> _levelDescriptions = {
    'A1': 'Beginner — I know a few words',
    'A2': 'Elementary — I can make simple sentences',
    'B1': 'Intermediate — I can have basic conversations',
    'B2': 'Upper Intermediate — I can discuss most topics',
    'C1': 'Advanced — I speak fluently with few errors',
    'C2': 'Proficient — Near-native level',
  };

  // Page controller for the wizard
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Whether we need personal info step (OAuth users missing gender/birthdate)
  late final bool _needsPersonalInfo;
  late final int _totalSteps;

  // Personal info (for OAuth users)
  String? _selectedGender;
  final TextEditingController _birthDateController = TextEditingController();
  String? _genderError;
  String? _birthDateError;

  // Languages
  Language? _nativeLanguage;
  String? _nativeLevel;
  Language? _learningLanguage;
  String? _learningLevel;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;

  // Fields
  List<File> _selectedImages = [];
  bool _showPhotoError = false;
  bool _isFetchingLocation = false;
  String? _country;
  String? _city;
  double? _latitude;
  double? _longitude;
  bool _termsAccepted = false;

  // Submission
  bool _isSubmitting = false;

  // Whether languages are already set (returning OAuth user)
  late final bool _hasExistingLanguages;

  @override
  void initState() {
    super.initState();
    // OAuth users who are missing gender or birth date need an extra step
    _needsPersonalInfo = widget.gender.isEmpty || widget.birthDate.isEmpty;
    // If both languages are already set, skip language steps entirely
    _hasExistingLanguages = widget.nativeLanguage.isNotEmpty && widget.learningLanguage.isNotEmpty;

    // Calculate total steps: [personal info?] + [native lang?] + [learning lang?] + finish
    _totalSteps = (_needsPersonalInfo ? 1 : 0) +
        (_hasExistingLanguages ? 0 : 2) +
        1; // finish step always shown

    if (widget.gender.isNotEmpty) {
      _selectedGender = widget.gender;
    }
    if (widget.birthDate.isNotEmpty) {
      _birthDateController.text = widget.birthDate;
    }

    _fetchLanguages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // ─── Language Loading ────────────────────────────────────────────

  Future<void> _fetchLanguages() async {
    try {
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> languagesData = data['data'] ?? [];

        if (mounted) {
          setState(() {
            _languages = languagesData
                .map<Language>((json) => Language.fromJson(json))
                .toList();
            _isLoadingLanguages = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingLanguages = false);
          _showError('Failed to load languages');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLanguages = false);
        _showError('Error loading languages');
      }
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────

  void _goToNext() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─── Language Picker ─────────────────────────────────────────────

  Future<void> _openLanguagePicker({required bool isNative}) async {
    if (_languages.isEmpty) {
      _showError(AppLocalizations.of(context)!.languagesAreStillLoading);
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: isNative ? _nativeLanguage : _learningLanguage,
        ),
      ),
    );

    if (result != null) {
      // Don't allow same language for both
      if (isNative && _learningLanguage != null && result.code == _learningLanguage!.code) {
        _showError(AppLocalizations.of(context)!.nativeCannotBeSameAsLearning);
        return;
      }
      if (!isNative && _nativeLanguage != null && result.code == _nativeLanguage!.code) {
        _showError(AppLocalizations.of(context)!.learningCannotBeSameAsNative);
        return;
      }

      setState(() {
        if (isNative) {
          _nativeLanguage = result;
        } else {
          _learningLanguage = result;
        }
      });
    }
  }

  // ─── Image Picker ────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

      if (pickedFiles.isNotEmpty) {
        if (_selectedImages.length + pickedFiles.length > 6) {
          _showError(AppLocalizations.of(context)!.maximum6Photos);
          return;
        }
        setState(() {
          _selectedImages.addAll(
            pickedFiles.map((f) => File(f.path)),
          );
          _showPhotoError = false;
        });
      }
    } catch (e) {
      _showError('Error selecting images');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ─── Location ────────────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Please enable location services');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError('Location permission permanently denied. Enable in Settings.');
      return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      await setLocaleIdentifier('en_US');
      final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _country = place.country ?? 'Unknown';
          _city = place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown';
        });
      }
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToGetLocation);
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  // ─── Submit ──────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_selectedImages.isEmpty) {
      setState(() => _showPhotoError = true);
      _showError(AppLocalizations.of(context)!.profilePhotoRequired);
      return;
    }

    if (!_termsAccepted) {
      _showError(AppLocalizations.of(context)!.pleaseAcceptTerms);
      return;
    }

    setState(() => _isSubmitting = true);

    final birthDate = _birthDateController.text.isNotEmpty
        ? _birthDateController.text
        : widget.birthDate;
    final dateParts = birthDate.split('.');
    final year = dateParts.isNotEmpty ? dateParts[0] : '';
    final month = dateParts.length > 1 ? dateParts[1] : '';
    final day = dateParts.length > 2 ? dateParts[2] : '';
    final gender = _selectedGender ?? widget.gender;

    final authService = ref.read(authServiceProvider);
    final bool isOAuthUser = widget.password.isEmpty;

    if (isOAuthUser) {
      // OAuth user → profile update
      try {
        final url = Uri.parse('${Endpoints.baseURL}${Endpoints.updateDetailsURL}');
        final token = authService.token;

        final requestBody = {
          'name': widget.name,
          'gender': gender,
          'birth_year': year,
          'birth_month': month,
          'birth_day': day,
          'native_language': _nativeLanguage?.name ?? widget.nativeLanguage,
          'language_to_learn': _learningLanguage?.name ?? widget.learningLanguage,
          'profileCompleted': true,
          'images': [],
          if (_nativeLevel != null) 'languageLevel': _learningLevel ?? _nativeLevel,
          if (_city != null && _country != null)
            'location': {
              'type': 'Point',
              'coordinates': [
                (_longitude ?? 0.0).toDouble(),
                (_latitude ?? 0.0).toDouble(),
              ],
              'formattedAddress': '$_city, $_country',
              'city': _city ?? '',
              'country': _country ?? '',
            },
        };

        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            // Accept terms via API
            try {
              final prefs = await SharedPreferences.getInstance();
              final storedToken = prefs.getString('token') ?? '';
              if (storedToken.isNotEmpty && authService.token.isEmpty) {
                authService.token = storedToken;
              }
              if (authService.token.isNotEmpty || storedToken.isNotEmpty) {
                await authService.acceptTerms();
              }
            } catch (e) {
              // Non-blocking
            }

            // Upload images
            final userId = authService.userId;
            if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
              try {
                await authService.uploadUserPhoto(userId, _selectedImages);
              } catch (e) {
                // Non-blocking
              }
            }

            // Connect socket
            try {
              final chatSocketService = ChatSocketService();
              chatSocketService.enableReconnection();
              await chatSocketService.connect();
            } catch (e) {}

            ref.invalidate(userProvider);
            if (mounted) context.go('/home');
          }
        } else {
          setState(() => _isSubmitting = false);
          final errorData = jsonDecode(response.body);
          _showError(errorData['message'] ?? 'Failed to update profile');
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showError('Network error: $e');
      }
    } else {
      // Email/Password registration
      final user = User(
        name: widget.name,
        password: widget.password,
        email: widget.email,
        bio: '',
        gender: gender,
        images: [],
        birth_day: day,
        birth_month: month,
        birth_year: year,
        native_language: _nativeLanguage?.name ?? widget.nativeLanguage,
        language_to_learn: _learningLanguage?.name ?? widget.learningLanguage,
        topics: [],
        termsAccepted: true,
        location: LocationModal(
          type: 'Point',
          coordinates: [
            (_longitude ?? 0.0).toDouble(),
            (_latitude ?? 0.0).toDouble(),
          ],
          formattedAddress:
              _city != null && _country != null ? '$_city, $_country' : '',
          city: _city ?? '',
          country: _country ?? '',
        ),
      );

      try {
        final response = await authService.register(user);

        if (response['success'] == true) {
          final userData = response['user'] as Community?;
          final userId = userData?.id ?? '';

          if (mounted) {
            // Upload images
            if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
              try {
                await authService.uploadUserPhoto(userId, _selectedImages);
              } catch (e) {
                // Non-blocking
              }
            }

            // Update language level if set
            if (_learningLevel != null || _nativeLevel != null) {
              try {
                await authService.updateUserLanguageLevel(
                  languageLevel: _learningLevel ?? _nativeLevel!,
                );
              } catch (e) {
                // Non-blocking
              }
            }

            // Connect socket
            try {
              final chatSocketService = ChatSocketService();
              chatSocketService.enableReconnection();
              await chatSocketService.connect();
            } catch (e) {}

            ref.invalidate(userProvider);
            if (mounted) context.go('/home');
          }
        } else {
          setState(() => _isSubmitting = false);
          _showError(response['message'] ?? 'Registration failed');
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        String msg = 'An unknown error occurred';
        if (e.toString().contains('Duplicate field value')) {
          msg = 'Email already exists. Please use a different email.';
        }
        _showError(msg);
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    showAuthSnackBar(context, message: message, type: AuthSnackBarType.error);
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),
              // Progress bar
              _buildProgress(),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    if (_needsPersonalInfo) _buildPersonalInfoStep(),
                    if (!_hasExistingLanguages) _buildNativeLanguageStep(),
                    if (!_hasExistingLanguages) _buildLearningLanguageStep(),
                    _buildFinishStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.textPrimary, size: 22),
            onPressed: _goBack,
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.stepOf("2", "2"),
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacing.hGapLG,
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Step 1 of overall flow (always filled)
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Spacing.hGapSM,
          // Step 2 progress (sub-steps)
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (_currentStep + 1) / _totalSteps,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Personal Info Step (OAuth users only) ────────────────────────

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)!.tellUsAboutYourself,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.justACoupleQuickThings,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),

          const SizedBox(height: 32),

          // Gender
          if (widget.gender.isEmpty) ...[
            Text(
              AppLocalizations.of(context)!.gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (_genderError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_genderError!,
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Row(
              children: ['male', 'female', 'other'].map((g) {
                final isSelected = _selectedGender == g;
                final l10n = AppLocalizations.of(context)!;
                final label = g == 'male' ? l10n.male : g == 'female' ? l10n.female : l10n.other;
                final icons = {
                  'male': Icons.male_rounded,
                  'female': Icons.female_rounded,
                  'other': Icons.transgender_rounded,
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedGender = g;
                        _genderError = null;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : context.containerColor,
                        borderRadius: AppRadius.borderMD,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : context.dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icons[g] ?? Icons.person,
                            color: isSelected
                                ? Colors.white
                                : context.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : context.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Birth date
          if (widget.birthDate.isEmpty) ...[
            Text(
              AppLocalizations.of(context)!.birthDate,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final initialDate =
                    DateTime.now().subtract(const Duration(days: 365 * 20));

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme:
                            ColorScheme.light(primary: AppColors.primary),
                      ),
                      child: child!,
                    );
                  },
                );

                if (pickedDate != null) {
                  setState(() {
                    _birthDateController.text =
                        '${pickedDate.year}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.day.toString().padLeft(2, '0')}';
                    _birthDateError = null;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderLG,
                  border: Border.all(
                    color: _birthDateError != null
                        ? AppColors.error
                        : context.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _birthDateController.text.isNotEmpty
                            ? _birthDateController.text
                            : AppLocalizations.of(context)!.selectYourBirthDate,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _birthDateController.text.isNotEmpty
                              ? context.textPrimary
                              : context.textHint,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: context.iconColor),
                  ],
                ),
              ),
            ),
            if (_birthDateError != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Text(_birthDateError!,
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
          ],

          const SizedBox(height: 32),

          // Next button
          AuthGradientButton(
            label: AppLocalizations.of(context)!.continueButton,
            onPressed: () {
              bool valid = true;
              final l10n = AppLocalizations.of(context)!;
              if (widget.gender.isEmpty && _selectedGender == null) {
                setState(() => _genderError = l10n.pleaseSelectGender);
                valid = false;
              }
              if (widget.birthDate.isEmpty &&
                  _birthDateController.text.isEmpty) {
                setState(
                    () => _birthDateError = l10n.pleaseSelectBirthDate);
                valid = false;
              }
              // Age check
              if (_birthDateController.text.isNotEmpty) {
                try {
                  final parts = _birthDateController.text.split('.');
                  final bd = DateTime(
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                    int.parse(parts[2]),
                  );
                  final age =
                      DateTime.now().difference(bd).inDays ~/ 365;
                  if (age < 18) {
                    setState(() => _birthDateError = l10n.mustBe18);
                    valid = false;
                  }
                } catch (e) {
                  setState(() => _birthDateError = l10n.invalidDate);
                  valid = false;
                }
              }
              if (valid) _goToNext();
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Native Language Step ──────────────────────────────────────────

  Widget _buildNativeLanguageStep() {
    final l10n = AppLocalizations.of(context)!;
    return _buildLanguageStep(
      title: l10n.whatsYourNativeLanguage,
      subtitle: l10n.helpsMatchWithLearners,
      selectedLanguage: _nativeLanguage,
      selectedLevel: _nativeLevel,
      isNative: true,
      onLevelChanged: (level) => setState(() => _nativeLevel = level),
      onNext: () {
        if (_nativeLanguage == null) {
          _showError(l10n.selectNativeLanguage);
          return;
        }
        _goToNext();
      },
    );
  }

  // ─── Step 2: Learning Language ───────────────────────────────────

  Widget _buildLearningLanguageStep() {
    final l10n = AppLocalizations.of(context)!;
    return _buildLanguageStep(
      title: l10n.whatAreYouLearning,
      subtitle: l10n.connectWithNativeSpeakers,
      selectedLanguage: _learningLanguage,
      selectedLevel: _learningLevel,
      isNative: false,
      onLevelChanged: (level) => setState(() => _learningLevel = level),
      onNext: () {
        if (_learningLanguage == null) {
          _showError(l10n.selectLearningLanguage);
          return;
        }
        if (_learningLevel == null) {
          _showError(l10n.selectCurrentLevel);
          return;
        }
        _goToNext();
      },
    );
  }

  Widget _buildLanguageStep({
    required String title,
    required String subtitle,
    required Language? selectedLanguage,
    required String? selectedLevel,
    required bool isNative,
    required ValueChanged<String> onLevelChanged,
    required VoidCallback onNext,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Title
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

          // Language picker card
          _buildLanguageCard(
            selectedLanguage: selectedLanguage,
            onTap: () => _openLanguagePicker(isNative: isNative),
          ),

          // Level selection (always show for learning, optional for native)
          if (selectedLanguage != null) ...[
            const SizedBox(height: 28),
            Text(
              isNative
                  ? AppLocalizations.of(context)!.yourLevelIn(selectedLanguage.name)
                  : AppLocalizations.of(context)!.yourCurrentLevel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._cefrLevels.map((level) => _buildLevelTile(
                  level: level,
                  isSelected: selectedLevel == level,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onLevelChanged(level);
                  },
                )),
          ],

          const SizedBox(height: 32),

          // Next button
          AuthGradientButton(
            label: AppLocalizations.of(context)!.continueButton,
            onPressed: onNext,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required Language? selectedLanguage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoadingLanguages ? null : onTap,
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
        child: _isLoadingLanguages
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  if (selectedLanguage != null) ...[
                    Text(selectedLanguage.flag,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLanguage.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedLanguage.nativeName,
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

  Widget _buildLevelTile({
    required String level,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
              color: isSelected
                  ? AppColors.primary
                  : context.dividerColor,
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
                  _getLocalizedLevelDescription(context, level),
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

  String _getLocalizedLevelDescription(BuildContext context, String level) {
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

  // ─── Step 3: Finish (photo + location + terms) ───────────────────

  Widget _buildFinishStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)!.almostDone,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.addPhotoLocationForMatches,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),

          const SizedBox(height: 28),

          // Photo section
          _buildPhotoSection(),

          const SizedBox(height: 20),

          // Location section
          _buildLocationSection(),

          const SizedBox(height: 24),

          // Terms checkbox
          _buildTermsCheckbox(),

          const SizedBox(height: 24),

          // Submit button
          AuthGradientButton(
            label: AppLocalizations.of(context)!.startLearning,
            onPressed: _isSubmitting ? null : _submit,
            isLoading: _isSubmitting,
          ),

          const SizedBox(height: 12),

          // Note
          Center(
            child: Text(
              AppLocalizations.of(context)!.locationOptional,
              style: TextStyle(fontSize: 12, color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: _showPhotoError
                ? AppColors.error.withValues(alpha: 0.05)
                : context.cardBackground,
            borderRadius: AppRadius.borderLG,
            border: Border.all(
              color: _showPhotoError ? AppColors.error : context.dividerColor,
              width: _showPhotoError ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMD,
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    size: 26, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.addProfilePhoto,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.requiredUpTo6Photos,
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_selectedImages.length < 6 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.borderMD,
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: AppRadius.borderMD,
                      border: Border.all(color: context.dividerColor),
                    ),
                    child: Icon(Icons.add, size: 28, color: context.iconColor),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return GestureDetector(
      onTap: _isFetchingLocation ? null : _getCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _city != null
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : context.containerColor,
                borderRadius: AppRadius.borderMD,
              ),
              child: _isFetchingLocation
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      _city != null
                          ? Icons.location_on
                          : Icons.location_off_outlined,
                      color:
                          _city != null ? AppColors.primary : context.iconColor,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _city != null && _country != null
                        ? '$_city, $_country'
                        : AppLocalizations.of(context)!.tapToDetectLocation,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          _city != null ? context.textPrimary : context.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.optionalHelpsNearbyPartners,
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.gps_fixed, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _termsAccepted
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: _termsAccepted
                ? AppColors.primary.withValues(alpha: 0.3)
                : context.dividerColor,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const TermsOfServiceScreen(isPreRegistration: true),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textPrimary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: AppLocalizations.of(context)!.iAgreeToThe),
                      TextSpan(
                        text: AppLocalizations.of(context)!.termsOfService,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
