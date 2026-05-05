import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/finish_step.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/native_language_step.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/personal_info_step.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/progress_indicator.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:bananatalk_app/providers/provider_models/location_modal.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Multi-step registration wizard (Step 2 of 2).
///
/// Flow: [Personal Info?] → [Native Language?] → [Learning Language?] → Finish
///
/// Steps are conditionally shown based on what the OAuth provider already
/// supplied. The parent owns all state, controllers, and navigation; the
/// step widgets are dumb views parameterised via constructor.
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
  // ─── PageView ────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Whether we need the personal-info step (OAuth users missing gender/DOB)
  late final bool _needsPersonalInfo;
  late final int _totalSteps;

  // ─── Personal info ───────────────────────────────────────────────────────
  String? _selectedGender;
  final TextEditingController _birthDateController = TextEditingController();
  String? _genderError;
  String? _birthDateError;

  // ─── Languages ──────────────────────────────────────────────────────────
  Language? _nativeLanguage;
  String? _nativeLevel;
  Language? _learningLanguage;
  String? _learningLevel;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;

  // Whether languages are already set (returning OAuth user)
  late final bool _hasExistingLanguages;

  // ─── Finish step ─────────────────────────────────────────────────────────
  List<File> _selectedImages = [];
  bool _showPhotoError = false;
  bool _isFetchingLocation = false;
  String? _country;
  String? _city;
  double? _latitude;
  double? _longitude;
  bool _termsAccepted = false;

  // ─── Submission ──────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _needsPersonalInfo = widget.gender.isEmpty || widget.birthDate.isEmpty;
    _hasExistingLanguages =
        widget.nativeLanguage.isNotEmpty && widget.learningLanguage.isNotEmpty;

    _totalSteps = (_needsPersonalInfo ? 1 : 0) +
        (_hasExistingLanguages ? 0 : 2) +
        1; // finish step always shown

    if (widget.gender.isNotEmpty) _selectedGender = widget.gender;
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

  // ─── Language loading ────────────────────────────────────────────────────

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

  // ─── Navigation ──────────────────────────────────────────────────────────

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

  // ─── Language picker ─────────────────────────────────────────────────────

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
      if (isNative &&
          _learningLanguage != null &&
          result.code == _learningLanguage!.code) {
        _showError(AppLocalizations.of(context)!.nativeCannotBeSameAsLearning);
        return;
      }
      if (!isNative &&
          _nativeLanguage != null &&
          result.code == _nativeLanguage!.code) {
        _showError(
            AppLocalizations.of(context)!.learningCannotBeSameAsNative);
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

  // ─── Image picker ────────────────────────────────────────────────────────

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
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
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

  // ─── Location ────────────────────────────────────────────────────────────

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
      final placemarks =
          await placemarkFromCoordinates(_latitude!, _longitude!);

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

  // ─── Submit ──────────────────────────────────────────────────────────────

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
        final url =
            Uri.parse('${Endpoints.baseURL}${Endpoints.updateDetailsURL}');
        final token = authService.token;

        final requestBody = {
          'name': widget.name,
          'gender': gender,
          'birth_year': year,
          'birth_month': month,
          'birth_day': day,
          'native_language':
              _nativeLanguage?.name ?? widget.nativeLanguage,
          'language_to_learn':
              _learningLanguage?.name ?? widget.learningLanguage,
          'profileCompleted': true,
          'images': [],
          if (_nativeLevel != null)
            'languageLevel': _learningLevel ?? _nativeLevel,
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

            final userId = authService.userId;
            if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
              try {
                await authService.uploadUserPhoto(userId, _selectedImages);
              } catch (e) {
                // Non-blocking
              }
            }

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
        language_to_learn:
            _learningLanguage?.name ?? widget.learningLanguage,
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
            if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
              try {
                await authService.uploadUserPhoto(userId, _selectedImages);
              } catch (e) {
                // Non-blocking
              }
            }

            if (_learningLevel != null || _nativeLevel != null) {
              try {
                await authService.updateUserLanguageLevel(
                  languageLevel: _learningLevel ?? _nativeLevel!,
                );
              } catch (e) {
                // Non-blocking
              }
            }

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

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    showAuthSnackBar(context, message: message, type: AuthSnackBarType.error);
  }

  // ─── Validation helpers for personal-info step ───────────────────────────

  void _onPersonalInfoNext() {
    bool valid = true;
    final l10n = AppLocalizations.of(context)!;

    if (widget.gender.isEmpty && _selectedGender == null) {
      setState(() => _genderError = l10n.pleaseSelectGender);
      valid = false;
    }
    if (widget.birthDate.isEmpty && _birthDateController.text.isEmpty) {
      setState(() => _birthDateError = l10n.pleaseSelectBirthDate);
      valid = false;
    }
    if (_birthDateController.text.isNotEmpty) {
      try {
        final parts = _birthDateController.text.split('.');
        final bd = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final age = DateTime.now().difference(bd).inDays ~/ 365;
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
  }

  void _onBirthDateSelected(DateTime date) {
    setState(() {
      _birthDateController.text =
          '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
      _birthDateError = null;
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              RegisterTwoProgressIndicator(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    if (_needsPersonalInfo)
                      PersonalInfoStep(
                        showGenderField: widget.gender.isEmpty,
                        showBirthDateField: widget.birthDate.isEmpty,
                        selectedGender: _selectedGender,
                        birthDateController: _birthDateController,
                        genderError: _genderError,
                        birthDateError: _birthDateError,
                        onGenderSelected: (g) => setState(() {
                          _selectedGender = g;
                          _genderError = null;
                        }),
                        onBirthDateSelected: _onBirthDateSelected,
                        onNext: _onPersonalInfoNext,
                      ),
                    if (!_hasExistingLanguages)
                      NativeLanguageStep(
                        selectedLanguage: _nativeLanguage,
                        selectedLevel: _nativeLevel,
                        isLoadingLanguages: _isLoadingLanguages,
                        onOpenPicker: () =>
                            _openLanguagePicker(isNative: true),
                        onLevelChanged: (level) =>
                            setState(() => _nativeLevel = level),
                        onNext: () {
                          if (_nativeLanguage == null) {
                            _showError(AppLocalizations.of(context)!
                                .selectNativeLanguage);
                            return;
                          }
                          _goToNext();
                        },
                      ),
                    if (!_hasExistingLanguages)
                      LearningLanguageStep(
                        selectedLanguage: _learningLanguage,
                        selectedLevel: _learningLevel,
                        isLoadingLanguages: _isLoadingLanguages,
                        onOpenPicker: () =>
                            _openLanguagePicker(isNative: false),
                        onLevelChanged: (level) =>
                            setState(() => _learningLevel = level),
                        onNext: () {
                          final l10n = AppLocalizations.of(context)!;
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
                      ),
                    FinishStep(
                      selectedImages: _selectedImages,
                      showPhotoError: _showPhotoError,
                      onPickImage: _pickImage,
                      onRemoveImage: _removeImage,
                      city: _city,
                      country: _country,
                      isFetchingLocation: _isFetchingLocation,
                      onDetectLocation: _getCurrentLocation,
                      termsAccepted: _termsAccepted,
                      onTermsChanged: (v) =>
                          setState(() => _termsAccepted = v),
                      isSubmitting: _isSubmitting,
                      onSubmit: _submit,
                    ),
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
            icon:
                Icon(Icons.arrow_back_ios, color: context.textPrimary, size: 22),
            onPressed: _goBack,
          ),
          const Spacer(),
          StepProgressLabel(
            current: _currentStep + 1,
            total: _totalSteps,
          ),
          Spacing.hGapLG,
        ],
      ),
    );
  }
}
