import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';

import 'package:bananatalk_app/pages/authentication/register/register_two/finish_step.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/native_language_step.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/personal_info_step.dart';
import 'package:bananatalk_app/pages/authentication/register/register_two/profile_photo_step.dart';
import 'package:bananatalk_app/pages/authentication/register/registration_progress_service.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_step_progress.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/utils/client_info.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  final String username; // Optional — empty string if user skipped it
  final String email;
  final String password;
  final String gender;
  final String birthDate;
  final String nativeLanguage;
  final String learningLanguage;

  /// True when this screen is reopened post-login (not right after OAuth
  /// sign-up) to finish a stalled profile. In this mode the constructor
  /// fields above may all be empty — [initState] fetches the current user
  /// via `getLoggedInUser()` and prefills from that instead.
  final bool completionMode;

  const RegisterTwo({
    super.key,
    this.name = '',
    this.email = '',
    this.password = '',
    this.username = '',
    this.gender = '',
    this.birthDate = '',
    this.nativeLanguage = '',
    this.learningLanguage = '',
    this.completionMode = false,
  });

  @override
  ConsumerState<RegisterTwo> createState() => _RegisterTwoState();
}

class _RegisterTwoState extends ConsumerState<RegisterTwo> {
  // ─── PageView ────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Optional profile photo picked during the wizard. Uploaded after the
  // final register call succeeds. Empty if user skipped.
  File? _pickedPhoto;

  // Whether we need the personal-info step (OAuth users missing gender/DOB)
  bool _needsPersonalInfo = false;
  int _totalSteps = 1;

  // ─── Completion mode (resume-after-login) ────────────────────────────────
  // When widget.completionMode is true, the constructor fields are mostly
  // empty — these hold the values actually used to prefill/compute steps,
  // populated from getLoggedInUser() before the wizard renders its pages.
  bool _isPrefilling = false;
  String _effectiveName = '';
  String _effectiveEmail = '';
  String _effectiveGender = '';
  String _effectiveBirthDate = '';
  String _effectiveNativeLanguage = '';
  String _effectiveLearningLanguage = '';

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
  bool _hasExistingLanguages = false;

  // ─── Finish step ─────────────────────────────────────────────────────────
  bool _isFetchingLocation = false;
  String? _country;
  String? _city;
  double? _latitude;
  double? _longitude;
  bool _termsAccepted = false;
  bool _showLocationError = false;

  // ─── Submission ──────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ─── Progress persistence (resume-after-close) ───────────────────────────
  // Never saved while widget.completionMode is true — that flow prefills
  // from the logged-in user, not from persisted wizard progress, and the
  // two must not fight over which fields are authoritative.
  final RegistrationProgressService _progressService =
      RegistrationProgressService();

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    if (widget.completionMode) {
      _isPrefilling = true;
      _prefillFromLoggedInUser();
    } else {
      _effectiveName = widget.name;
      _effectiveEmail = widget.email;
      _effectiveGender = widget.gender;
      _effectiveBirthDate = widget.birthDate;
      _effectiveNativeLanguage = widget.nativeLanguage;
      _effectiveLearningLanguage = widget.learningLanguage;
      _computeSteps();
    }

    _fetchLanguages();
  }

  /// Derives [_needsPersonalInfo], [_hasExistingLanguages] and [_totalSteps]
  /// from the effective (possibly prefilled) fields, and seeds the personal
  /// info controllers so an already-known gender/birth date isn't re-asked.
  void _computeSteps() {
    _needsPersonalInfo =
        _effectiveGender.isEmpty || _effectiveBirthDate.isEmpty;
    _hasExistingLanguages =
        _effectiveNativeLanguage.isNotEmpty &&
        _effectiveLearningLanguage.isNotEmpty &&
        _effectiveNativeLanguage != _effectiveLearningLanguage;

    _totalSteps =
        (_needsPersonalInfo ? 1 : 0) +
        1 + // profile photo step (required)
        (_hasExistingLanguages ? 0 : 2) +
        1; // finish step always shown

    if (_effectiveGender.isNotEmpty) _selectedGender = _effectiveGender;
    if (_effectiveBirthDate.isNotEmpty) {
      _birthDateController.text = _effectiveBirthDate;
    }
  }

  // ─── Sub-step index lookups (for FinishStep's summary edit shortcuts) ────
  // Mirrors the fixed PageView child order built in `build()`:
  // [PersonalInfo?] -> ProfilePhoto -> [NativeLanguage, LearningLanguage]? -> Finish
  // Each getter returns null when that step isn't part of this run (so the
  // summary card can hide its edit affordance instead of jumping nowhere).

  int? get _personalInfoStepIndex => _needsPersonalInfo ? 0 : null;

  int get _photoStepIndex => _needsPersonalInfo ? 1 : 0;

  int? get _languageStepIndex =>
      _hasExistingLanguages ? null : _photoStepIndex + 1;

  /// Per-step progress-bar labels built from the same step order used by the
  /// PageView's `children` in `build()`:
  /// [PersonalInfo?] -> ProfilePhoto -> [NativeLanguage, LearningLanguage]? -> Finish
  /// Kept in lockstep with `_computeSteps()`/`_totalSteps` so the label shown
  /// under the progress bar always matches the page actually on screen,
  /// instead of a fixed 4-label list that assumed a step order that doesn't
  /// hold once language steps are skipped (existing languages) or personal
  /// info is skipped (prefilled OAuth users).
  List<String> get _stepLabels => [
    if (_needsPersonalInfo) 'About you',
    'Photo',
    if (!_hasExistingLanguages) ...['Native language', 'Learning language'],
    'Finish',
  ];

  /// Completion-mode only: fetch the current user (already logged in — this
  /// screen was opened from the login gate, not straight after OAuth) and
  /// use it to prefill name/email/gender/birth date/languages so the wizard
  /// starts at the first genuinely missing step instead of step 0.
  Future<void> _prefillFromLoggedInUser() async {
    try {
      final user = await ref.read(authServiceProvider).getLoggedInUser();
      _effectiveName = user.name;
      _effectiveEmail = user.email;
      _effectiveGender = user.gender;
      _effectiveNativeLanguage = user.native_language;
      _effectiveLearningLanguage = user.language_to_learn;
      if (user.birth_year.isNotEmpty &&
          user.birth_month.isNotEmpty &&
          user.birth_day.isNotEmpty) {
        _effectiveBirthDate =
            '${user.birth_year}.${user.birth_month.padLeft(2, '0')}.${user.birth_day.padLeft(2, '0')}';
      }
    } catch (e) {
      // Fall back to whatever constructor values were passed (likely empty);
      // the wizard will just ask for everything again.
    } finally {
      _computeSteps();
      if (mounted) setState(() => _isPrefilling = false);
    }
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

  // Wizard page transitions: 300ms / easeOutCubic slide+fade everywhere a
  // step change is driven programmatically (Next/Back buttons, edit
  // shortcuts, PROFILE_INCOMPLETE recovery jump). The fade+slide visuals
  // themselves live in [_FadeSlidePageView] wrapping the PageView below;
  // this duration/curve pair is what actually drives the scroll physics.
  static const Duration _pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve _pageTransitionCurve = Curves.easeOutCubic;

  void _goToNext() {
    if (_currentStep < _totalSteps - 1) {
      _saveStepProgress();
      _pageController.nextPage(
        duration: _pageTransitionDuration,
        curve: _pageTransitionCurve,
      );
    }
  }

  // Persists progress for resume-after-close. This screen owns sub-steps
  // 0.._totalSteps-1; the overall registration flow numbers step 0 as the
  // *first* wizard screen (register_screen.dart, owned by another task), so
  // this screen's steps are offset by one. `completedSubStep` is the sub-step
  // just finished (i.e. the one the user is leaving), one ahead of
  // `_currentStep` because progress is saved right before advancing.
  // Never saved in completionMode — that flow prefills from the logged-in
  // user instead of resuming from local storage.
  void _saveStepProgress() {
    if (widget.completionMode) return;
    final completedSubStep = _currentStep + 1;
    _progressService.save(
      RegistrationProgress(
        step: 1 + completedSubStep,
        fields: {
          'email': _effectiveEmail,
          'name': _effectiveName,
          'gender': _selectedGender ?? _effectiveGender,
          'birthDate': _birthDateController.text.isNotEmpty
              ? _birthDateController.text
              : _effectiveBirthDate,
        },
      ),
    );
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: _pageTransitionDuration,
        curve: _pageTransitionCurve,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Jump directly to a given sub-step (0-indexed within this screen's
  /// PageView) — used by [FinishStep]'s summary-card edit shortcuts. Uses
  /// the same animated transition as Next/Back rather than [jumpToPage] so
  /// it doesn't feel jarring compared to normal navigation.
  void _goToStep(int index) {
    if (index < 0 || index >= _totalSteps || index == _currentStep) return;
    _pageController.animateToPage(
      index,
      duration: _pageTransitionDuration,
      curve: _pageTransitionCurve,
    );
  }

  // ─── Language picker ─────────────────────────────────────────────────────
  //
  // The searchable bottom-sheet picker now lives inside
  // NativeLanguageStep/LearningLanguageStep themselves (see
  // register_two/native_language_step.dart), which are handed the opposite
  // selection via `excludeLanguage` and filter it out of the sheet's list
  // *before* it's ever shown. That's the structural fix for the prod bug
  // class where 23 users picked the same language for native and learning
  // and the backend silently refused: it's no longer possible to select the
  // excluded language in the first place, vs. the old flow which let you
  // pick it and then showed an error after the fact. The redundant
  // post-hoc-equality check is kept below only as a defense-in-depth guard
  // (e.g. against stale `_languages` lists mid-fetch).

  void _onNativeLanguageSelected(Language language) {
    if (_learningLanguage != null && language.code == _learningLanguage!.code) {
      _showError(AppLocalizations.of(context)!.nativeCannotBeSameAsLearning);
      return;
    }
    setState(() => _nativeLanguage = language);
  }

  void _onLearningLanguageSelected(Language language) {
    if (_nativeLanguage != null && language.code == _nativeLanguage!.code) {
      _showError(AppLocalizations.of(context)!.learningCannotBeSameAsNative);
      return;
    }
    setState(() => _learningLanguage = language);
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
      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _country = place.country ?? 'Unknown';
          _city =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown';
          _showLocationError = false;
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

    if (_pickedPhoto == null) {
      _showError(AppLocalizations.of(context)!.profilePhotoRequired);
      return;
    }

    if (_city == null || _country == null) {
      setState(() => _showLocationError = true);
      _showError(AppLocalizations.of(context)!.locationOptional);
      return;
    }

    if (!_termsAccepted) {
      _showError(AppLocalizations.of(context)!.pleaseAcceptTerms);
      return;
    }

    setState(() => _isSubmitting = true);

    final birthDate = _birthDateController.text.isNotEmpty
        ? _birthDateController.text
        : _effectiveBirthDate;
    final dateParts = birthDate.split('.');
    final year = dateParts.isNotEmpty ? dateParts[0] : '';
    final month = dateParts.length > 1 ? dateParts[1] : '';
    final day = dateParts.length > 2 ? dateParts[2] : '';
    final gender = _selectedGender ?? _effectiveGender;

    final authService = ref.read(authServiceProvider);
    final bool isOAuthUser = widget.password.isEmpty;

    if (isOAuthUser) {
      // OAuth user → profile update
      try {
        final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.updateDetailsURL}',
        );
        final token = authService.token;

        final requestBody = {
          'name': _effectiveName,
          'gender': gender,
          'birth_year': year,
          'birth_month': month,
          'birth_day': day,
          'native_language': _nativeLanguage?.name ?? _effectiveNativeLanguage,
          'language_to_learn':
              _learningLanguage?.name ?? _effectiveLearningLanguage,
          'profileCompleted': true,
          'images': [],
          'clientInfo': await ClientInfo.collect(),
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

              // Cache native_language now so the inline translate chip can
              // resolve to it before /auth/me has run. This is the OAuth
              // signup's first authoritative write of the field.
              final pickedNative =
                  _nativeLanguage?.name ?? _effectiveNativeLanguage;
              if (pickedNative.isNotEmpty) {
                await prefs.setString('user_native_language', pickedNative);
              }
            } catch (e) {
              // Non-blocking
            }

            final userId = authService.userId;
            if (userId.isNotEmpty && _pickedPhoto != null) {
              try {
                await authService.uploadUserPhoto(userId, [_pickedPhoto!]);
              } catch (e) {
                // Non-blocking
              }
            }

            try {
              final chatSocketService = ChatSocketService();
              chatSocketService.enableReconnection();
              await chatSocketService.connect();
            } catch (e) {}

            await _progressService.clear();
            ref.invalidate(userProvider);
            if (mounted) context.go('/home');
          }
        } else {
          setState(() => _isSubmitting = false);
          final errorData = jsonDecode(response.body);
          // TODO(task8): switch to AuthErrorCode once the service layer
          // threads a structured `code` through instead of a raw map.
          final String? errorCode = errorData is Map
              ? errorData['code']?.toString()
              : null;
          final String errorMessage =
              (errorData is Map ? errorData['message']?.toString() : null) ??
              'Failed to update profile';
          final bool isProfileIncomplete =
              errorCode == 'PROFILE_INCOMPLETE' ||
              errorMessage.toLowerCase().contains('profile') &&
                  errorMessage.toLowerCase().contains('incomplete');
          if (isProfileIncomplete) {
            // Backend refused the completion (missing/duplicate core
            // fields) — jump back to the first step that still needs input
            // instead of leaving the user stuck on the finish screen.
            _computeSteps();
            if (mounted) {
              setState(() {});
              _pageController.jumpToPage(0);
            }
          }
          _showError(errorMessage);
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showError('Network error: $e');
      }
    } else {
      // Email/Password registration
      final user = User(
        name: _effectiveName,
        username: widget.username.isNotEmpty ? widget.username : null,
        password: widget.password,
        email: _effectiveEmail,
        bio: '',
        gender: gender,
        images: [],
        birth_day: day,
        birth_month: month,
        birth_year: year,
        native_language: _nativeLanguage?.name ?? _effectiveNativeLanguage,
        language_to_learn:
            _learningLanguage?.name ?? _effectiveLearningLanguage,
        topics: [],
        termsAccepted: true,
        location: LocationModal(
          type: 'Point',
          coordinates: [
            (_longitude ?? 0.0).toDouble(),
            (_latitude ?? 0.0).toDouble(),
          ],
          formattedAddress: _city != null && _country != null
              ? '$_city, $_country'
              : '',
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
            if (userId.isNotEmpty && _pickedPhoto != null) {
              try {
                await authService.uploadUserPhoto(userId, [_pickedPhoto!]);
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

            await _progressService.clear();
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

    if (_effectiveGender.isEmpty && _selectedGender == null) {
      setState(() => _genderError = l10n.pleaseSelectGender);
      valid = false;
    }
    if (_effectiveBirthDate.isEmpty && _birthDateController.text.isEmpty) {
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
    if (_isPrefilling) {
      return Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: AuthStepProgress(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  labels: _stepLabels,
                ),
              ),
              Expanded(
                child: _FadeSlidePageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    if (_needsPersonalInfo)
                      PersonalInfoStep(
                        showGenderField: _effectiveGender.isEmpty,
                        showBirthDateField: _effectiveBirthDate.isEmpty,
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
                    ProfilePhotoStep(
                      pickedPhoto: _pickedPhoto,
                      onPhotoChanged: (p) => setState(() => _pickedPhoto = p),
                      onContinue: _goToNext,
                    ),
                    if (!_hasExistingLanguages)
                      NativeLanguageStep(
                        selectedLanguage: _nativeLanguage,
                        selectedLevel: _nativeLevel,
                        isLoadingLanguages: _isLoadingLanguages,
                        allLanguages: _languages,
                        excludeLanguage: _learningLanguage,
                        onLanguageSelected: _onNativeLanguageSelected,
                        onLevelChanged: (level) =>
                            setState(() => _nativeLevel = level),
                        onNext: () {
                          if (_nativeLanguage == null) {
                            _showError(
                              AppLocalizations.of(
                                context,
                              )!.selectNativeLanguage,
                            );
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
                        allLanguages: _languages,
                        excludeLanguage: _nativeLanguage,
                        onLanguageSelected: _onLearningLanguageSelected,
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
                      city: _city,
                      country: _country,
                      isFetchingLocation: _isFetchingLocation,
                      onDetectLocation: _getCurrentLocation,
                      showLocationError: _showLocationError,
                      termsAccepted: _termsAccepted,
                      onTermsChanged: (v) => setState(() => _termsAccepted = v),
                      isSubmitting: _isSubmitting,
                      onSubmit: _submit,
                      summaryName: _effectiveName.isNotEmpty
                          ? _effectiveName
                          : null,
                      summaryGender: _selectedGender ?? _effectiveGender,
                      summaryBirthDate: _birthDateController.text.isNotEmpty
                          ? _birthDateController.text
                          : _effectiveBirthDate,
                      summaryNativeLanguage:
                          _nativeLanguage?.name ??
                          (_effectiveNativeLanguage.isNotEmpty
                              ? _effectiveNativeLanguage
                              : null),
                      summaryLearningLanguage:
                          _learningLanguage?.name ??
                          (_effectiveLearningLanguage.isNotEmpty
                              ? _effectiveLearningLanguage
                              : null),
                      summaryPhoto: _pickedPhoto,
                      onEditStep: _goToStep,
                      personalInfoStepIndex: _personalInfoStepIndex,
                      photoStepIndex: _photoStepIndex,
                      languageStepIndex: _languageStepIndex,
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
            icon: Icon(
              Icons.arrow_back_ios,
              color: context.textPrimary,
              size: 22,
            ),
            onPressed: _goBack,
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(
              context,
            )!.stepProgress(_currentStep + 1, _totalSteps),
            style: context.captionSmall.copyWith(
              color: context.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacing.hGapLG,
        ],
      ),
    );
  }
}

/// Wraps a [PageView] so that programmatic page changes (Next/Back/edit
/// shortcuts — navigation is always button-driven here, never a user swipe)
/// read as a 300ms easeOutCubic slide+fade instead of the default abrupt
/// page-to-page cut. Built on top of [AnimatedBuilder] listening to the
/// existing [controller] so it doesn't interfere with `_computeSteps`,
/// completion-mode prefill, or the PROFILE_INCOMPLETE `jumpToPage(0)`
/// recovery — those all just call the same controller methods as before.
class _FadeSlidePageView extends StatelessWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const _FadeSlidePageView({
    required this.controller,
    required this.onPageChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: onPageChanged,
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              double page;
              try {
                page = controller.page ?? controller.initialPage.toDouble();
              } catch (_) {
                // `.page` throws if accessed before the controller is
                // attached to a PageView (e.g. very first frame).
                page = i.toDouble();
              }
              final delta = (page - i).clamp(-1.0, 1.0);
              final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(delta * 40, 0),
                  child: child,
                ),
              );
            },
            child: children[i],
          ),
      ],
    );
  }
}
