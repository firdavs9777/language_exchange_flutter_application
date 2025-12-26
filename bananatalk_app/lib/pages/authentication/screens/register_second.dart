import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/pages/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/authentication/screens/terms_of_service.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
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
  late String? _nativelanguage;
  late String? _language_to_learn;

  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  String? _country;
  String? _city;
  double? _latitude;
  double? _longitude;

  late TextEditingController _birthDate;
  late TextEditingController _image;

  List<String> _languages = [];
  List<File> _selectedImages = [];

  // Error states
  String? _bioError;
  String? _nativeLanguageError;
  String? _learnLanguageError;
  String? _genderError;
  String? _birthDateError;
  String? _imagesError;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.bio);
    _language_to_learn = widget.languageToLearn.isNotEmpty
        ? widget.languageToLearn
        : null;

    _birthDate = TextEditingController(
      text: widget.birthDate.isNotEmpty
          ? widget.birthDate
          : DateFormat('yyyy.MM.dd').format(DateTime.now()),
    );
    _nativelanguage = widget.nativeLanguage.isNotEmpty
        ? widget.nativeLanguage
        : null;

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
                .map<String>((lang) => lang['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList();
          });
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(
            'Failed to load languages. Status: ${response.statusCode}',
          );
          setState(() {
            _languages = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading languages: ${e.toString()}');
        setState(() {
          _languages = [];
        });
      }
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
    if (_nativelanguage == null || _nativelanguage.toString().isEmpty) {
      setState(() {
        _nativeLanguageError = 'Please select your native language';
      });
      isValid = false;
    }

    // Language to learn validation
    if (_language_to_learn == null || _language_to_learn.toString().isEmpty) {
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
          'native_language': _nativelanguage ?? '',
          'language_to_learn': _language_to_learn ?? '',
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
        native_language: _nativelanguage ?? '',
        language_to_learn: _language_to_learn ?? '',
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo_no_background.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Just a few more details to get started',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Bio field
              _buildSectionTitle('About You'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: BIO_MAX_LENGTH,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _bioError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _bioError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _bioError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: 'Bio',
                  hintText:
                      'Tell us about yourself... (e.g., I love traveling and learning new languages!)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.edit_note,
                    color: _bioError != null ? Colors.red : Colors.grey[600],
                  ),
                  errorText: _bioError,
                  helperText: bioCharRemaining >= 0
                      ? '$bioCharRemaining characters remaining'
                      : null,
                  helperStyle: TextStyle(
                    color: bioCharRemaining < 50
                        ? Colors.orange
                        : Colors.grey[600],
                  ),
                  counterText: '',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 24),

              // Language section
              _buildSectionTitle('Languages'),
              const SizedBox(height: 12),

              // Native language
              DropdownButtonFormField<String>(
                value: _nativelanguage,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _nativeLanguageError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _nativeLanguageError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _nativeLanguageError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: 'Native Language',
                  hintText: AppLocalizations.of(context)!.selectYourNativeLanguage2,
                  prefixIcon: Icon(
                    Icons.language,
                    color: _nativeLanguageError != null
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  errorText: _nativeLanguageError,
                ),
                items: _languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _nativelanguage = value;
                    _nativeLanguageError = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Language to learn
              DropdownButtonFormField<String>(
                value: _language_to_learn,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _learnLanguageError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _learnLanguageError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _learnLanguageError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: 'Language to Learn',
                  hintText: AppLocalizations.of(context)!.whichLanguageDoYouWantToLearn2,
                  prefixIcon: Icon(
                    Icons.school,
                    color: _learnLanguageError != null
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  errorText: _learnLanguageError,
                ),
                items: _languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _language_to_learn = value;
                    _learnLanguageError = null;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Personal Info section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 12),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _genderError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _genderError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _genderError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: 'Gender',
                  hintText: AppLocalizations.of(context)!.selectYourGender2,
                  prefixIcon: Icon(
                    Icons.person,
                    color: _genderError != null ? Colors.red : Colors.grey[600],
                  ),
                  errorText: _genderError,
                ),
                items: _genders.map((String? gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender ?? 'Select gender'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                    _genderError = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Birth date
              TextFormField(
                controller: _birthDate,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _birthDateError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _birthDateError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _birthDateError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: 'Birth Date',
                  hintText: AppLocalizations.of(context)!.dateFormat,
                  prefixIcon: Icon(
                    Icons.cake,
                    color: _birthDateError != null
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  errorText: _birthDateError,
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
                onTap: () async {
                  DateTime initialDate = DateTime.now();

                  if (_birthDate.text.isNotEmpty) {
                    try {
                      initialDate = DateFormat(
                        'yyyy.MM.dd',
                      ).parse(_birthDate.text);
                    } catch (e) {
                      initialDate = DateTime.now();
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
                      _birthDate.text = DateFormat(
                        'yyyy.MM.dd',
                      ).format(pickedDate);
                      _birthDateError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Location section
              _buildSectionTitle('Location (Optional)'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: _city != null && _country != null
                      ? Text(
                          '$_city, $_country',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )
                      : Text(AppLocalizations.of(context)!.detectYourLocation2),
                  subtitle: _city != null && _country != null
                      ? Text(AppLocalizations.of(context)!.tapToUpdateLocation2)
                      : Text(AppLocalizations.of(context)!.helpOthersFindYouNearby2),
                  trailing: _isFetchingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.gps_fixed,
                          color: Theme.of(context).primaryColor,
                        ),
                  onTap: _isFetchingLocation ? null : _getCurrentLocation,
                ),
              ),

              const SizedBox(height: 24),

              // Images section
              _buildSectionTitle('Profile Photos (Min 2, Max 6)'),
              const SizedBox(height: 12),

              if (_selectedImages.isEmpty)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imagesError != null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 64,
                          color: _imagesError != null
                              ? Colors.red
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to add photos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add at least 2 photos',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_selectedImages.isNotEmpty)
                Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount:
                          _selectedImages.length +
                          (_selectedImages.length < 6 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _selectedImages.length) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
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
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(8),
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
                              child: Icon(
                                Icons.add,
                                size: 40,
                                color: Colors.grey[400],
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedImages.length}/6 photos selected',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Complete Registration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}
