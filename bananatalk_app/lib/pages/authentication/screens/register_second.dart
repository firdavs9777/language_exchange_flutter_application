import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/pages/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bananatalk_app/providers/provider_models/location_modal.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterTwo extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String password;
  final String bio;
  final String gender;
  final String nativeLanguage;
  final String languageToLearn;
  final String birthDate;

  const RegisterTwo({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    this.bio = '',
    this.gender = '',
    this.nativeLanguage = '',
    this.languageToLearn = '',
    this.birthDate = '',
  });

  @override
  ConsumerState<RegisterTwo> createState() => _RegisterTwoState();
}

class _RegisterTwoState extends ConsumerState<RegisterTwo> {
  // Character limits
  static const int BIO_MAX_LENGTH = 300;
  static const int BIO_MIN_LENGTH = 10;

  late String? _selectedGender;
  final List<String?> _genders = ['Male', 'Female', 'Other'];
  final Map<String, String> _genderMap = {
    'Male': 'male',
    'Female': 'female',
    'Other': 'other',
  };

  late TextEditingController _bioController;

  // Language selection with Language model
  Language? _nativeLanguage;
  Language? _languageToLearn;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;

  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  String? _country;
  String? _city;
  double? _latitude;
  double? _longitude;

  late TextEditingController _birthDate;
  late TextEditingController _image;

  List<File> _selectedImages = [];

  // Error states
  String? _bioError;
  String? _nativeLanguageError;
  String? _learnLanguageError;
  String? _genderError;
  String? _birthDateError;
  String? _imagesError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.bio);

    _birthDate = TextEditingController(
      text: widget.birthDate.isNotEmpty
          ? widget.birthDate
          : DateFormat('yyyy.MM.dd').format(DateTime.now()),
    );

    if (widget.gender.isNotEmpty) {
      final displayGender = _genderMap.entries
          .firstWhere(
            (entry) => entry.value == widget.gender.toLowerCase(),
            orElse: () => MapEntry(widget.gender, widget.gender),
          )
          .key;
      _selectedGender = displayGender;
    } else {
      _selectedGender = null;
    }

    _image = TextEditingController();
    fetchLanguages();

    // Add listener to bio for real-time validation
    _bioController.addListener(() {
      if (_bioError != null) {
        setState(() {
          _bioError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _birthDate.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Location services are disabled. Please enable them.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

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
        });

        _showSuccessSnackBar('Location detected: $_city, $_country');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get location: ${e.toString()}');
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> fetchLanguages() async {
    try {
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> languagesData = data['data'] ?? [];

        if (mounted) {
          setState(() {
            _languages = languagesData
                .map<Language>((json) => Language.fromJson(json))
                .toList();
            _isLoadingLanguages = false;
          });

          // Set initial values if provided
          if (widget.nativeLanguage.isNotEmpty && _languages.isNotEmpty) {
            try {
              _nativeLanguage = _languages.firstWhere(
                (lang) => lang.name == widget.nativeLanguage,
              );
            } catch (e) {
              // Language not found
            }
          }

          if (widget.languageToLearn.isNotEmpty && _languages.isNotEmpty) {
            try {
              _languageToLearn = _languages.firstWhere(
                (lang) => lang.name == widget.languageToLearn,
              );
            } catch (e) {
              // Language not found
            }
          }
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(
            'Failed to load languages. Status: ${response.statusCode}',
          );
          setState(() {
            _languages = [];
            _isLoadingLanguages = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading languages: ${e.toString()}');
        setState(() {
          _languages = [];
          _isLoadingLanguages = false;
        });
      }
    }
  }

  Future<void> _openLanguagePicker({required bool isNative}) async {
    if (_languages.isEmpty) {
      _showErrorSnackBar('Languages are still loading. Please wait...');
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: isNative ? _nativeLanguage : _languageToLearn,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isNative) {
          _nativeLanguage = result;
          _nativeLanguageError = null;
        } else {
          _languageToLearn = result;
          _learnLanguageError = null;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 85, // Compress images to reduce upload size
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        if (_selectedImages.length + pickedFiles.length > 6) {
          _showErrorSnackBar('You can only select up to 6 images');
          return;
        }

        setState(() {
          _selectedImages.addAll(
            pickedFiles.map((pickedFile) => File(pickedFile.path)),
          );
          _imagesError = null;
        });

        debugPrint(
          '✅ Selected ${pickedFiles.length} images. Total: ${_selectedImages.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error picking images: $e');
      _showErrorSnackBar('Error selecting images: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _bioError = null;
      _nativeLanguageError = null;
      _learnLanguageError = null;
      _genderError = null;
      _birthDateError = null;
      _imagesError = null;
      _locationError = null;
    });

    // Bio validation
    if (_bioController.text.trim().isEmpty) {
      setState(() {
        _bioError = 'Bio is required';
      });
      isValid = false;
    } else if (_bioController.text.trim().length < BIO_MIN_LENGTH) {
      setState(() {
        _bioError = 'Bio must be at least $BIO_MIN_LENGTH characters';
      });
      isValid = false;
    } else if (_bioController.text.trim().length > BIO_MAX_LENGTH) {
      setState(() {
        _bioError = 'Bio cannot exceed $BIO_MAX_LENGTH characters';
      });
      isValid = false;
    }

    // Native language validation
    if (_nativeLanguage == null) {
      setState(() {
        _nativeLanguageError = 'Please select your native language';
      });
      isValid = false;
    }

    // Language to learn validation
    if (_languageToLearn == null) {
      setState(() {
        _learnLanguageError = 'Please select the language you want to learn';
      });
      isValid = false;
    }

    // Gender validation
    if (_selectedGender == null || _selectedGender.toString().isEmpty) {
      setState(() {
        _genderError = 'Please select your gender';
      });
      isValid = false;
    }

    // Age validation
    List<String> dateParts = _birthDate.text.split('.');
    String year = dateParts[0];
    String month = dateParts[1];
    String day = dateParts[2];
    DateTime birthDate = DateTime(
      int.parse(year),
      int.parse(month),
      int.parse(day),
    );
    DateTime today = DateTime.now();

    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    if (age < 18) {
      setState(() {
        _birthDateError = 'You must be at least 18 years old';
      });
      isValid = false;
    }

    // Images validation
    if (_selectedImages.length < 2) {
      setState(() {
        _imagesError = 'Please select at least 2 profile images';
      });
      isValid = false;
    }

    // Location validation (required for matching and community features)
    if (_city == null || _country == null) {
      setState(() {
        _locationError = 'Please detect your location';
      });
      isValid = false;
    }

    return isValid;
  }

  void submit() async {
    if (_isSubmitting) return;

    if (!_validateForm()) {
      _showErrorSnackBar('Please fix the errors before continuing');
      return;
    }

    // Check if user has accepted terms of service from backend (required for App Store compliance)
    // For new users registering, we check if they're already logged in (OAuth flow)
    final authService = ref.read(authServiceProvider);
    bool termsAccepted = false;

    try {
      // If user is already authenticated (OAuth flow), check their terms status
      if (authService.isLoggedIn && authService.userId.isNotEmpty) {
        final user = await authService.getLoggedInUser();
        termsAccepted = user.termsAccepted;
      }
    } catch (e) {
      // If not authenticated yet (email registration), terms will be false
      debugPrint('User not authenticated yet, will show terms: $e');
    }

    if (!termsAccepted) {
      // Show terms screen before allowing registration
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
      );

      if (!mounted) return;

      // Re-check if terms were accepted (for OAuth users)
      try {
        if (authService.isLoggedIn && authService.userId.isNotEmpty) {
          final updatedUser = await authService.getLoggedInUser();
          if (!updatedUser.termsAccepted) {
            // User didn't accept terms, cannot proceed with registration
            return;
          }
        }
      } catch (e) {
        // For email registration, terms acceptance will be handled after account creation
        debugPrint('Will check terms after registration: $e');
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    List<String> dateParts = _birthDate.text.split('.');
    String year = dateParts[0];
    String month = dateParts[1];
    String day = dateParts[2];

    final genderValue = _selectedGender != null
        ? _genderMap[_selectedGender] ?? _selectedGender!.toLowerCase()
        : '';

    final bool isOAuthUser = widget.password.isEmpty;

    if (isOAuthUser) {
      // OAuth User Profile Update
      try {
        print('🔧 OAuth user completing profile...');

        final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.updateDetailsURL}',
        );
        final token = ref.read(authServiceProvider).token;

        final requestBody = {
          'name': widget.name,
          'gender': genderValue,
          'bio': _bioController.text.trim(),
          'birth_year': year,
          'birth_month': month,
          'birth_day': day,
          'native_language': _nativeLanguage?.name ?? '',
          'language_to_learn': _languageToLearn?.name ?? '',
          'profileCompleted': true,
          'location': {
            'type': 'Point',
            'coordinates': [
              (_longitude ?? 0.0).toDouble(),
              (_latitude ?? 0.0).toDouble(),
            ],
            'formattedAddress': _city != null && _country != null
                ? '$_city, $_country'
                : '',
            'city': _city ?? '',
            'country': _country ?? '',
          },
        };

        print('📤 Sending profile update...');

        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );

        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ Profile update successful!');

          if (mounted) {
            // Ensure token is available before checking terms
            final authService = ref.read(authServiceProvider);

            // Wait a bit and verify token is available
            await Future.delayed(const Duration(milliseconds: 800));

            // Refresh token from SharedPreferences to ensure it's available
            final prefs = await SharedPreferences.getInstance();
            final storedToken = prefs.getString('token') ?? '';
            if (storedToken.isNotEmpty && authService.token.isEmpty) {
              // Token is in storage but not in memory - update it
              authService.token = storedToken;
              debugPrint('✅ Token refreshed from storage before checking terms');
            }

            // Check if user has accepted terms (for OAuth users completing profile)
            try {
              if (authService.token.isNotEmpty || storedToken.isNotEmpty) {
                // Try to fetch user data with retry logic
                Community? user;
                for (int attempt = 0; attempt < 3; attempt++) {
                  try {
                    if (attempt > 0) {
                      await Future.delayed(
                        Duration(milliseconds: 500 * attempt),
                      );
                    }
                    user = await authService.getLoggedInUser();
                    break; // Success, exit retry loop
                  } catch (e) {
                    debugPrint(
                      'Attempt ${attempt + 1} to fetch user failed: $e',
                    );
                    if (attempt == 2) {
                      // Last attempt failed, allow user to proceed
                      debugPrint(
                        'Could not fetch user after 3 attempts, allowing to proceed',
                      );
                    }
                  }
                }

                if (user != null && !user.termsAccepted) {
                  // Show terms screen before entering app
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );

                  if (!mounted) return;

                  // Re-check after terms acceptance with retry
                  Community? updatedUser;
                  for (int attempt = 0; attempt < 3; attempt++) {
                    try {
                      if (attempt > 0) {
                        await Future.delayed(
                          Duration(milliseconds: 500 * attempt),
                        );
                      }
                      updatedUser = await authService.getLoggedInUser();
                      break;
                    } catch (e) {
                      debugPrint(
                        'Attempt ${attempt + 1} to re-fetch user failed: $e',
                      );
                    }
                  }

                  if (updatedUser != null && !updatedUser.termsAccepted) {
                    // User didn't accept, stay on registration screen
                    setState(() {
                      _isSubmitting = false;
                    });
                    return;
                  }
                }
              }
            } catch (e) {
              // If we can't fetch user data, allow them to proceed
              // This handles edge cases where API might be temporarily unavailable
              debugPrint('Error checking terms after profile completion: $e');
              // Continue to app - terms will be checked on next login or app launch
            }

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (ctx) => const TabsScreen()),
              (route) => false,
            );

            _showSuccessSnackBar('Profile completed! Welcome to BanaTalk! 🎉');
          }

          // Upload images before navigation to avoid ref disposal issues
          final userId = ref.read(authServiceProvider).userId;
          if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
            print('📸 Uploading ${_selectedImages.length} images...');
            try {
              // Upload images synchronously before navigation
              await ref
                  .read(authServiceProvider)
                  .uploadUserPhoto(userId, _selectedImages);
              print('✅ Images uploaded successfully');
            } catch (error) {
              print('❌ Image upload error: $error');
              // Don't block navigation if upload fails - user can upload later
            }
          }
        } else {
          setState(() {
            _isSubmitting = false;
          });

          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ?? 'Failed to update profile';
          print('❌ Profile update failed: $errorMessage');

          if (mounted) {
            _showErrorSnackBar(errorMessage);
          }
        }
      } catch (error) {
        setState(() {
          _isSubmitting = false;
        });
        print('❌ Profile update exception: $error');

        if (mounted) {
          _showErrorSnackBar('Network error: ${error.toString()}');
        }
      }
    } else {
      // Email/Password User Registration
      User user = User(
        name: widget.name,
        password: widget.password,
        email: widget.email,
        bio: _bioController.text.trim(),
        gender: genderValue,
        images: [],
        birth_day: day,
        birth_month: month,
        birth_year: year,
        native_language: _nativeLanguage?.name ?? '',
        language_to_learn: _languageToLearn?.name ?? '',
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
        final response = await ref.read(authServiceProvider).register(user);

        if (response['success'] == true) {
          final userData = response['user'] as Community?;
          String userId = '';

          if (userData != null) {
            userId = userData.id;
          }

          if (mounted) {
            // Check terms using user data from registration response first
            // This avoids making an extra API call immediately after registration
            bool termsAccepted = false;
            try {
              // Try to get termsAccepted from the registration response user data
              if (userData != null) {
                // Check if user data has termsAccepted field (from backend response)
                // If not available, assume false (new users need to accept)
                termsAccepted = userData.termsAccepted;
                debugPrint(
                  '📋 Terms status from registration response: $termsAccepted',
                );
              } else {
                debugPrint('⚠️ User data is null in registration response');
              }
            } catch (e) {
              debugPrint('Could not read terms from registration response: $e');
              // Default to false if we can't read it
              termsAccepted = false;
            }

            // If terms not accepted, show terms screen
            if (!termsAccepted) {
              // Ensure token is available before showing terms screen
              final authService = ref.read(authServiceProvider);

              // Wait a bit and verify token is available
              await Future.delayed(const Duration(milliseconds: 800));

              // Refresh token from SharedPreferences to ensure it's available
              final prefs = await SharedPreferences.getInstance();
              final storedToken = prefs.getString('token') ?? '';
              if (storedToken.isNotEmpty && authService.token.isEmpty) {
                // Token is in storage but not in memory - update it
                authService.token = storedToken;
                debugPrint('✅ Token refreshed from storage before showing terms');
              }

              bool shouldProceed = true;

              try {
                if (authService.token.isNotEmpty || storedToken.isNotEmpty) {
                  // Try to fetch user data with retry logic
                  Community? user;
                  for (int attempt = 0; attempt < 3; attempt++) {
                    try {
                      if (attempt > 0) {
                        await Future.delayed(
                          Duration(milliseconds: 500 * attempt),
                        );
                      }
                      user = await authService.getLoggedInUser();
                      break; // Success, exit retry loop
                    } catch (e) {
                      debugPrint(
                        'Attempt ${attempt + 1} to fetch user failed: $e',
                      );
                      if (attempt == 2) {
                        // Last attempt failed, allow user to proceed
                        debugPrint(
                          'Could not fetch user after 3 attempts, allowing to proceed',
                        );
                      }
                    }
                  }

                  if (user != null && !user.termsAccepted) {
                    // Show terms screen before entering app
                    final termsResult = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServiceScreen(),
                      ),
                    );

                    if (!mounted) return;

                    // Re-check after terms acceptance
                    Community? updatedUser;
                    for (int attempt = 0; attempt < 3; attempt++) {
                      try {
                        if (attempt > 0) {
                          await Future.delayed(
                            Duration(milliseconds: 500 * attempt),
                          );
                        }
                        updatedUser = await authService.getLoggedInUser();
                        break;
                      } catch (e) {
                        debugPrint(
                          'Attempt ${attempt + 1} to re-fetch user failed: $e',
                        );
                      }
                    }

                    if (updatedUser != null && !updatedUser.termsAccepted) {
                      // User didn't accept, stay on registration screen
                      setState(() {
                        _isSubmitting = false;
                      });
                      shouldProceed = false;
                    }
                  }
                }
              } catch (e) {
                // If we can't fetch user data, allow them to proceed
                debugPrint('Error checking terms after registration: $e');
                // Continue to app - terms will be checked on next login or app launch
              }

              // Only proceed with image upload and navigation if terms were accepted
              if (shouldProceed && mounted) {
                // Upload images before navigation to avoid ref disposal issues
                if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
                  print('📸 Uploading ${_selectedImages.length} images...');
                  try {
                    // Upload images synchronously before navigation
                    await ref
                        .read(authServiceProvider)
                        .uploadUserPhoto(userId, _selectedImages);
                    print('✅ Images uploaded successfully');
                  } catch (error) {
                    print('❌ Image upload error: $error');
                    // Don't block navigation if upload fails - user can upload later
                  }
                }

                if (!mounted) return;

                _showSuccessSnackBar(
                  'Registration Successful! Welcome to BanaTalk! 🎉',
                );

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (ctx) => const TabsScreen()),
                  (route) => false,
                );
              }
            } else {
              // Terms already accepted - proceed directly with image upload and navigation
              // Upload images before navigation to avoid ref disposal issues
              if (userId.isNotEmpty && _selectedImages.isNotEmpty) {
                print('📸 Uploading ${_selectedImages.length} images...');
                try {
                  // Upload images synchronously before navigation
                  await ref
                      .read(authServiceProvider)
                      .uploadUserPhoto(userId, _selectedImages);
                  print('✅ Images uploaded successfully');
                } catch (error) {
                  print('❌ Image upload error: $error');
                  // Don't block navigation if upload fails - user can upload later
                }
              }

              if (!mounted) return;

              _showSuccessSnackBar(
                'Registration Successful! Welcome to BanaTalk! 🎉',
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => const TabsScreen()),
                (route) => false,
              );
            }
          }
        } else {
          setState(() {
            _isSubmitting = false;
          });

          String errorMessage =
              response['message'] ?? 'Registration failed. Please try again.';
          _showErrorSnackBar(errorMessage);
        }
      } catch (error) {
        setState(() {
          _isSubmitting = false;
        });

        String errorMessage = 'An unknown error occurred';
        if (error.toString().contains('Duplicate field value')) {
          errorMessage = 'Email already exists. Please use a different email.';
        }

        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioCharCount = _bioController.text.length;
    final bioCharRemaining = BIO_MAX_LENGTH - bioCharCount;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(context),

            // Progress Indicator
            _buildProgressIndicator(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Header
                    _buildHeader(),

                    const SizedBox(height: 32),

                    // Bio field
                    _buildSectionTitle('About You', Icons.edit_note),
                    const SizedBox(height: 12),
                    _buildBioField(bioCharRemaining),

                    const SizedBox(height: 28),

                    // Language section with modern cards
                    _buildSectionTitle('Languages', Icons.translate),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(
                      label: 'Native Language',
                      language: _nativeLanguage,
                      error: _nativeLanguageError,
                      onTap: () => _openLanguagePicker(isNative: true),
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(
                      label: 'Language to Learn',
                      language: _languageToLearn,
                      error: _learnLanguageError,
                      onTap: () => _openLanguagePicker(isNative: false),
                      icon: Icons.school_outlined,
                    ),

                    const SizedBox(height: 28),

                    // Personal Info section
                    _buildSectionTitle('Personal Information', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildGenderSelector(),
                    const SizedBox(height: 16),
                    _buildBirthDateField(),

                    const SizedBox(height: 28),

                    // Location section
                    _buildSectionTitle('Location', Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildLocationCard(),

                    const SizedBox(height: 28),

                    // Images section
                    _buildSectionTitle('Profile Photos', Icons.photo_library_outlined),
                    const SizedBox(height: 4),
                    Text(
                      'Add at least 2 photos (max 6)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagesSection(),

                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800], size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            'Step 2 of 2',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us more about yourself to find the perfect language partners',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildBioField(int bioCharRemaining) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _bioError != null ? Colors.red : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: BIO_MAX_LENGTH,
            decoration: InputDecoration(
              hintText: 'Tell us about yourself, your interests, and why you want to learn a new language...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
            onChanged: (value) => setState(() {}),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_bioError != null)
                  Expanded(
                    child: Text(
                      _bioError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  )
                else
                  const SizedBox(),
                Text(
                  '${_bioController.text.length}/$BIO_MAX_LENGTH',
                  style: TextStyle(
                    fontSize: 12,
                    color: bioCharRemaining < 50 ? Colors.orange : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector({
    required String label,
    required Language? language,
    required String? error,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: _isLoadingLanguages ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: error != null ? Colors.red : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag or Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: language != null
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isLoadingLanguages
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : language != null
                        ? Text(
                            language.flag,
                            style: const TextStyle(fontSize: 28),
                          )
                        : Icon(
                            icon,
                            color: Colors.grey[400],
                            size: 24,
                          ),
              ),
            ),
            const SizedBox(width: 16),

            // Language info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    language?.name ?? 'Select a language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: language != null ? Colors.grey[900] : Colors.grey[400],
                    ),
                  ),
                  if (language != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _genderError != null ? Colors.red : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildGenderButton('Male', 'Male', Icons.man),
              _buildGenderButton('Female', 'Female', Icons.woman),
              _buildGenderButton('Other', 'Other', Icons.person_outline),
            ],
          ),
          if (_genderError != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
              child: Text(
                _genderError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String? value, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = value;
            _genderError = null;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      onTap: () async {
        DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 20));

        if (_birthDate.text.isNotEmpty) {
          try {
            initialDate = DateFormat('yyyy.MM.dd').parse(_birthDate.text);
          } catch (e) {
            initialDate = DateTime.now().subtract(const Duration(days: 365 * 20));
          }
        }

        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          setState(() {
            _birthDate.text = DateFormat('yyyy.MM.dd').format(pickedDate);
            _birthDateError = null;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _birthDateError != null ? Colors.red : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cake_outlined,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birth Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _birthDate.text.isNotEmpty
                        ? _formatDisplayDate(_birthDate.text)
                        : 'Select your birth date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _birthDate.text.isNotEmpty ? Colors.grey[900] : Colors.grey[400],
                    ),
                  ),
                  if (_birthDateError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _birthDateError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplayDate(String date) {
    try {
      final parsed = DateFormat('yyyy.MM.dd').parse(date);
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  Widget _buildLocationCard() {
    final hasError = _locationError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isFetchingLocation ? null : _getCurrentLocation,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
                width: hasError ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _city != null
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : hasError
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isFetchingLocation
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          _city != null ? Icons.location_on : Icons.location_off_outlined,
                          color: _city != null
                              ? Theme.of(context).primaryColor
                              : hasError
                                  ? Colors.red[400]
                                  : Colors.grey[400],
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _city != null && _country != null
                            ? '$_city, $_country'
                            : 'Tap to detect your location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _city != null
                              ? Colors.grey[900]
                              : hasError
                                  ? Colors.red[400]
                                  : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Required - helps find nearby partners',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.gps_fixed,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              _locationError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[400],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagesSection() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _imagesError != null ? Colors.red : Colors.grey.shade200,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Profile Photos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to select images',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              if (_imagesError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _imagesError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length + (_selectedImages.length < 6 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _selectedImages.length) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        if (_imagesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _imagesError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '${_selectedImages.length}/6 photos selected',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Complete Registration',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
