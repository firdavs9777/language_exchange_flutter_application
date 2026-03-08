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
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

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
  String? _selectedCountry;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;
  bool _isDetectingLocation = false;
  String _errorMessage = '';
  final List<String> genders = ['Male', 'Female', 'Other'];

  // Complete list of all countries with flags (alphabetically sorted)
  static const List<Map<String, String>> _countries = [
    {'name': 'Afghanistan', 'code': 'AF', 'flag': '🇦🇫'},
    {'name': 'Albania', 'code': 'AL', 'flag': '🇦🇱'},
    {'name': 'Algeria', 'code': 'DZ', 'flag': '🇩🇿'},
    {'name': 'Andorra', 'code': 'AD', 'flag': '🇦🇩'},
    {'name': 'Angola', 'code': 'AO', 'flag': '🇦🇴'},
    {'name': 'Antigua and Barbuda', 'code': 'AG', 'flag': '🇦🇬'},
    {'name': 'Argentina', 'code': 'AR', 'flag': '🇦🇷'},
    {'name': 'Armenia', 'code': 'AM', 'flag': '🇦🇲'},
    {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
    {'name': 'Austria', 'code': 'AT', 'flag': '🇦🇹'},
    {'name': 'Azerbaijan', 'code': 'AZ', 'flag': '🇦🇿'},
    {'name': 'Bahamas', 'code': 'BS', 'flag': '🇧🇸'},
    {'name': 'Bahrain', 'code': 'BH', 'flag': '🇧🇭'},
    {'name': 'Bangladesh', 'code': 'BD', 'flag': '🇧🇩'},
    {'name': 'Barbados', 'code': 'BB', 'flag': '🇧🇧'},
    {'name': 'Belarus', 'code': 'BY', 'flag': '🇧🇾'},
    {'name': 'Belgium', 'code': 'BE', 'flag': '🇧🇪'},
    {'name': 'Belize', 'code': 'BZ', 'flag': '🇧🇿'},
    {'name': 'Benin', 'code': 'BJ', 'flag': '🇧🇯'},
    {'name': 'Bhutan', 'code': 'BT', 'flag': '🇧🇹'},
    {'name': 'Bolivia', 'code': 'BO', 'flag': '🇧🇴'},
    {'name': 'Bosnia and Herzegovina', 'code': 'BA', 'flag': '🇧🇦'},
    {'name': 'Botswana', 'code': 'BW', 'flag': '🇧🇼'},
    {'name': 'Brazil', 'code': 'BR', 'flag': '🇧🇷'},
    {'name': 'Brunei', 'code': 'BN', 'flag': '🇧🇳'},
    {'name': 'Bulgaria', 'code': 'BG', 'flag': '🇧🇬'},
    {'name': 'Burkina Faso', 'code': 'BF', 'flag': '🇧🇫'},
    {'name': 'Burundi', 'code': 'BI', 'flag': '🇧🇮'},
    {'name': 'Cambodia', 'code': 'KH', 'flag': '🇰🇭'},
    {'name': 'Cameroon', 'code': 'CM', 'flag': '🇨🇲'},
    {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
    {'name': 'Cape Verde', 'code': 'CV', 'flag': '🇨🇻'},
    {'name': 'Central African Republic', 'code': 'CF', 'flag': '🇨🇫'},
    {'name': 'Chad', 'code': 'TD', 'flag': '🇹🇩'},
    {'name': 'Chile', 'code': 'CL', 'flag': '🇨🇱'},
    {'name': 'China', 'code': 'CN', 'flag': '🇨🇳'},
    {'name': 'Colombia', 'code': 'CO', 'flag': '🇨🇴'},
    {'name': 'Comoros', 'code': 'KM', 'flag': '🇰🇲'},
    {'name': 'Congo', 'code': 'CG', 'flag': '🇨🇬'},
    {'name': 'Costa Rica', 'code': 'CR', 'flag': '🇨🇷'},
    {'name': 'Croatia', 'code': 'HR', 'flag': '🇭🇷'},
    {'name': 'Cuba', 'code': 'CU', 'flag': '🇨🇺'},
    {'name': 'Cyprus', 'code': 'CY', 'flag': '🇨🇾'},
    {'name': 'Czech Republic', 'code': 'CZ', 'flag': '🇨🇿'},
    {'name': 'Denmark', 'code': 'DK', 'flag': '🇩🇰'},
    {'name': 'Djibouti', 'code': 'DJ', 'flag': '🇩🇯'},
    {'name': 'Dominica', 'code': 'DM', 'flag': '🇩🇲'},
    {'name': 'Dominican Republic', 'code': 'DO', 'flag': '🇩🇴'},
    {'name': 'Ecuador', 'code': 'EC', 'flag': '🇪🇨'},
    {'name': 'Egypt', 'code': 'EG', 'flag': '🇪🇬'},
    {'name': 'El Salvador', 'code': 'SV', 'flag': '🇸🇻'},
    {'name': 'Equatorial Guinea', 'code': 'GQ', 'flag': '🇬🇶'},
    {'name': 'Eritrea', 'code': 'ER', 'flag': '🇪🇷'},
    {'name': 'Estonia', 'code': 'EE', 'flag': '🇪🇪'},
    {'name': 'Eswatini', 'code': 'SZ', 'flag': '🇸🇿'},
    {'name': 'Ethiopia', 'code': 'ET', 'flag': '🇪🇹'},
    {'name': 'Fiji', 'code': 'FJ', 'flag': '🇫🇯'},
    {'name': 'Finland', 'code': 'FI', 'flag': '🇫🇮'},
    {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'Gabon', 'code': 'GA', 'flag': '🇬🇦'},
    {'name': 'Gambia', 'code': 'GM', 'flag': '🇬🇲'},
    {'name': 'Georgia', 'code': 'GE', 'flag': '🇬🇪'},
    {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
    {'name': 'Ghana', 'code': 'GH', 'flag': '🇬🇭'},
    {'name': 'Greece', 'code': 'GR', 'flag': '🇬🇷'},
    {'name': 'Grenada', 'code': 'GD', 'flag': '🇬🇩'},
    {'name': 'Guatemala', 'code': 'GT', 'flag': '🇬🇹'},
    {'name': 'Guinea', 'code': 'GN', 'flag': '🇬🇳'},
    {'name': 'Guinea-Bissau', 'code': 'GW', 'flag': '🇬🇼'},
    {'name': 'Guyana', 'code': 'GY', 'flag': '🇬🇾'},
    {'name': 'Haiti', 'code': 'HT', 'flag': '🇭🇹'},
    {'name': 'Honduras', 'code': 'HN', 'flag': '🇭🇳'},
    {'name': 'Hong Kong', 'code': 'HK', 'flag': '🇭🇰'},
    {'name': 'Hungary', 'code': 'HU', 'flag': '🇭🇺'},
    {'name': 'Iceland', 'code': 'IS', 'flag': '🇮🇸'},
    {'name': 'India', 'code': 'IN', 'flag': '🇮🇳'},
    {'name': 'Indonesia', 'code': 'ID', 'flag': '🇮🇩'},
    {'name': 'Iran', 'code': 'IR', 'flag': '🇮🇷'},
    {'name': 'Iraq', 'code': 'IQ', 'flag': '🇮🇶'},
    {'name': 'Ireland', 'code': 'IE', 'flag': '🇮🇪'},
    {'name': 'Israel', 'code': 'IL', 'flag': '🇮🇱'},
    {'name': 'Italy', 'code': 'IT', 'flag': '🇮🇹'},
    {'name': 'Ivory Coast', 'code': 'CI', 'flag': '🇨🇮'},
    {'name': 'Jamaica', 'code': 'JM', 'flag': '🇯🇲'},
    {'name': 'Japan', 'code': 'JP', 'flag': '🇯🇵'},
    {'name': 'Jordan', 'code': 'JO', 'flag': '🇯🇴'},
    {'name': 'Kazakhstan', 'code': 'KZ', 'flag': '🇰🇿'},
    {'name': 'Kenya', 'code': 'KE', 'flag': '🇰🇪'},
    {'name': 'Kiribati', 'code': 'KI', 'flag': '🇰🇮'},
    {'name': 'Kosovo', 'code': 'XK', 'flag': '🇽🇰'},
    {'name': 'Kuwait', 'code': 'KW', 'flag': '🇰🇼'},
    {'name': 'Kyrgyzstan', 'code': 'KG', 'flag': '🇰🇬'},
    {'name': 'Laos', 'code': 'LA', 'flag': '🇱🇦'},
    {'name': 'Latvia', 'code': 'LV', 'flag': '🇱🇻'},
    {'name': 'Lebanon', 'code': 'LB', 'flag': '🇱🇧'},
    {'name': 'Lesotho', 'code': 'LS', 'flag': '🇱🇸'},
    {'name': 'Liberia', 'code': 'LR', 'flag': '🇱🇷'},
    {'name': 'Libya', 'code': 'LY', 'flag': '🇱🇾'},
    {'name': 'Liechtenstein', 'code': 'LI', 'flag': '🇱🇮'},
    {'name': 'Lithuania', 'code': 'LT', 'flag': '🇱🇹'},
    {'name': 'Luxembourg', 'code': 'LU', 'flag': '🇱🇺'},
    {'name': 'Macau', 'code': 'MO', 'flag': '🇲🇴'},
    {'name': 'Madagascar', 'code': 'MG', 'flag': '🇲🇬'},
    {'name': 'Malawi', 'code': 'MW', 'flag': '🇲🇼'},
    {'name': 'Malaysia', 'code': 'MY', 'flag': '🇲🇾'},
    {'name': 'Maldives', 'code': 'MV', 'flag': '🇲🇻'},
    {'name': 'Mali', 'code': 'ML', 'flag': '🇲🇱'},
    {'name': 'Malta', 'code': 'MT', 'flag': '🇲🇹'},
    {'name': 'Marshall Islands', 'code': 'MH', 'flag': '🇲🇭'},
    {'name': 'Mauritania', 'code': 'MR', 'flag': '🇲🇷'},
    {'name': 'Mauritius', 'code': 'MU', 'flag': '🇲🇺'},
    {'name': 'Mexico', 'code': 'MX', 'flag': '🇲🇽'},
    {'name': 'Micronesia', 'code': 'FM', 'flag': '🇫🇲'},
    {'name': 'Moldova', 'code': 'MD', 'flag': '🇲🇩'},
    {'name': 'Monaco', 'code': 'MC', 'flag': '🇲🇨'},
    {'name': 'Mongolia', 'code': 'MN', 'flag': '🇲🇳'},
    {'name': 'Montenegro', 'code': 'ME', 'flag': '🇲🇪'},
    {'name': 'Morocco', 'code': 'MA', 'flag': '🇲🇦'},
    {'name': 'Mozambique', 'code': 'MZ', 'flag': '🇲🇿'},
    {'name': 'Myanmar', 'code': 'MM', 'flag': '🇲🇲'},
    {'name': 'Namibia', 'code': 'NA', 'flag': '🇳🇦'},
    {'name': 'Nauru', 'code': 'NR', 'flag': '🇳🇷'},
    {'name': 'Nepal', 'code': 'NP', 'flag': '🇳🇵'},
    {'name': 'Netherlands', 'code': 'NL', 'flag': '🇳🇱'},
    {'name': 'New Zealand', 'code': 'NZ', 'flag': '🇳🇿'},
    {'name': 'Nicaragua', 'code': 'NI', 'flag': '🇳🇮'},
    {'name': 'Niger', 'code': 'NE', 'flag': '🇳🇪'},
    {'name': 'Nigeria', 'code': 'NG', 'flag': '🇳🇬'},
    {'name': 'North Korea', 'code': 'KP', 'flag': '🇰🇵'},
    {'name': 'North Macedonia', 'code': 'MK', 'flag': '🇲🇰'},
    {'name': 'Norway', 'code': 'NO', 'flag': '🇳🇴'},
    {'name': 'Oman', 'code': 'OM', 'flag': '🇴🇲'},
    {'name': 'Pakistan', 'code': 'PK', 'flag': '🇵🇰'},
    {'name': 'Palau', 'code': 'PW', 'flag': '🇵🇼'},
    {'name': 'Palestine', 'code': 'PS', 'flag': '🇵🇸'},
    {'name': 'Panama', 'code': 'PA', 'flag': '🇵🇦'},
    {'name': 'Papua New Guinea', 'code': 'PG', 'flag': '🇵🇬'},
    {'name': 'Paraguay', 'code': 'PY', 'flag': '🇵🇾'},
    {'name': 'Peru', 'code': 'PE', 'flag': '🇵🇪'},
    {'name': 'Philippines', 'code': 'PH', 'flag': '🇵🇭'},
    {'name': 'Poland', 'code': 'PL', 'flag': '🇵🇱'},
    {'name': 'Portugal', 'code': 'PT', 'flag': '🇵🇹'},
    {'name': 'Puerto Rico', 'code': 'PR', 'flag': '🇵🇷'},
    {'name': 'Qatar', 'code': 'QA', 'flag': '🇶🇦'},
    {'name': 'Romania', 'code': 'RO', 'flag': '🇷🇴'},
    {'name': 'Russia', 'code': 'RU', 'flag': '🇷🇺'},
    {'name': 'Rwanda', 'code': 'RW', 'flag': '🇷🇼'},
    {'name': 'Saint Kitts and Nevis', 'code': 'KN', 'flag': '🇰🇳'},
    {'name': 'Saint Lucia', 'code': 'LC', 'flag': '🇱🇨'},
    {'name': 'Saint Vincent', 'code': 'VC', 'flag': '🇻🇨'},
    {'name': 'Samoa', 'code': 'WS', 'flag': '🇼🇸'},
    {'name': 'San Marino', 'code': 'SM', 'flag': '🇸🇲'},
    {'name': 'Sao Tome and Principe', 'code': 'ST', 'flag': '🇸🇹'},
    {'name': 'Saudi Arabia', 'code': 'SA', 'flag': '🇸🇦'},
    {'name': 'Senegal', 'code': 'SN', 'flag': '🇸🇳'},
    {'name': 'Serbia', 'code': 'RS', 'flag': '🇷🇸'},
    {'name': 'Seychelles', 'code': 'SC', 'flag': '🇸🇨'},
    {'name': 'Sierra Leone', 'code': 'SL', 'flag': '🇸🇱'},
    {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
    {'name': 'Slovakia', 'code': 'SK', 'flag': '🇸🇰'},
    {'name': 'Slovenia', 'code': 'SI', 'flag': '🇸🇮'},
    {'name': 'Solomon Islands', 'code': 'SB', 'flag': '🇸🇧'},
    {'name': 'Somalia', 'code': 'SO', 'flag': '🇸🇴'},
    {'name': 'South Africa', 'code': 'ZA', 'flag': '🇿🇦'},
    {'name': 'South Korea', 'code': 'KR', 'flag': '🇰🇷'},
    {'name': 'South Sudan', 'code': 'SS', 'flag': '🇸🇸'},
    {'name': 'Spain', 'code': 'ES', 'flag': '🇪🇸'},
    {'name': 'Sri Lanka', 'code': 'LK', 'flag': '🇱🇰'},
    {'name': 'Sudan', 'code': 'SD', 'flag': '🇸🇩'},
    {'name': 'Suriname', 'code': 'SR', 'flag': '🇸🇷'},
    {'name': 'Sweden', 'code': 'SE', 'flag': '🇸🇪'},
    {'name': 'Switzerland', 'code': 'CH', 'flag': '🇨🇭'},
    {'name': 'Syria', 'code': 'SY', 'flag': '🇸🇾'},
    {'name': 'Taiwan', 'code': 'TW', 'flag': '🇹🇼'},
    {'name': 'Tajikistan', 'code': 'TJ', 'flag': '🇹🇯'},
    {'name': 'Tanzania', 'code': 'TZ', 'flag': '🇹🇿'},
    {'name': 'Thailand', 'code': 'TH', 'flag': '🇹🇭'},
    {'name': 'Timor-Leste', 'code': 'TL', 'flag': '🇹🇱'},
    {'name': 'Togo', 'code': 'TG', 'flag': '🇹🇬'},
    {'name': 'Tonga', 'code': 'TO', 'flag': '🇹🇴'},
    {'name': 'Trinidad and Tobago', 'code': 'TT', 'flag': '🇹🇹'},
    {'name': 'Tunisia', 'code': 'TN', 'flag': '🇹🇳'},
    {'name': 'Turkey', 'code': 'TR', 'flag': '🇹🇷'},
    {'name': 'Turkmenistan', 'code': 'TM', 'flag': '🇹🇲'},
    {'name': 'Tuvalu', 'code': 'TV', 'flag': '🇹🇻'},
    {'name': 'Uganda', 'code': 'UG', 'flag': '🇺🇬'},
    {'name': 'Ukraine', 'code': 'UA', 'flag': '🇺🇦'},
    {'name': 'United Arab Emirates', 'code': 'AE', 'flag': '🇦🇪'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'Uruguay', 'code': 'UY', 'flag': '🇺🇾'},
    {'name': 'Uzbekistan', 'code': 'UZ', 'flag': '🇺🇿'},
    {'name': 'Vanuatu', 'code': 'VU', 'flag': '🇻🇺'},
    {'name': 'Vatican City', 'code': 'VA', 'flag': '🇻🇦'},
    {'name': 'Venezuela', 'code': 'VE', 'flag': '🇻🇪'},
    {'name': 'Vietnam', 'code': 'VN', 'flag': '🇻🇳'},
    {'name': 'Yemen', 'code': 'YE', 'flag': '🇾🇪'},
    {'name': 'Zambia', 'code': 'ZM', 'flag': '🇿🇲'},
    {'name': 'Zimbabwe', 'code': 'ZW', 'flag': '🇿🇼'},
  ];

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
          // Parse as Language objects
          _languages = languagesList
              .map<Language>((json) => Language.fromJson(json))
              .toList();
          _isLoadingLanguages = false;
        });

        // Set selected language from initial filters after languages are loaded
        if (widget.initialFilters['nativeLanguage'] != null && _languages.isNotEmpty) {
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
            if (kDebugMode) {
              debugPrint('Initial language "$initialLangName" not found in language list');
            }
          }
        }
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      setState(() {
        _isLoadingLanguages = false;
        _errorMessage = 'Failed to load languages. Please try again.';
      });
      if (kDebugMode) {
        debugPrint('Error fetching languages: $e');
      }
    }
  }

  void resetFilters() {
    setState(() {
      _minAge = 18.0;
      _maxAge = 100.0;
      _selectedGender = null;
      _selectedLanguage = null;
      _selectedCountry = null;
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
      'country': _selectedCountry,
    };

    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  // Open country picker
  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        countries: _countries,
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

  // Auto-detect location like HelloTalk
  Future<void> _autoDetectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      // Check permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isDetectingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Reverse geocode to get country (use English locale)
      await setLocaleIdentifier('en_US');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final country = placemarks[0].country;
        debugPrint('📍 Detected country: $country');

        // Find matching country in our list
        if (country != null) {
          final matchingCountry = _countries.firstWhere(
            (c) => c['name']!.toLowerCase() == country.toLowerCase() ||
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect country'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error detecting location: $e');
      setState(() {
        _isDetectingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get flag for selected country
  String _getCountryFlag(String? countryName) {
    if (countryName == null) return '🌍';
    final country = _countries.firstWhere(
      (c) => c['name'] == countryName,
      orElse: () => {'flag': '🌍'},
    );
    return country['flag'] ?? '🌍';
  }

  // Open language picker
  Future<void> _openLanguagePicker() async {
    if (_languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languagesAreStillLoading),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filter Communities',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                    _buildLanguageSection(),
                    const SizedBox(height: 24),
                    _buildCountrySection(),
                    const SizedBox(height: 24),
                    _buildAgeSection(),
                    const SizedBox(height: 24),
                    _buildGenderSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Fixed Bottom Button
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                boxShadow: AppShadows.sm,
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: context.titleMedium.copyWith(color: context.textOnPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your Perfect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Language Partner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

  Widget _buildLanguageSection() {
    return _buildSection(
      title: 'Native Language',
      icon: Icons.translate,
      child: _isLoadingLanguages
          ? _buildLoadingCard()
          : _errorMessage.isNotEmpty
              ? _buildErrorCard()
              : _buildLanguageSelector(),
    );
  }

  Widget _buildCountrySection() {
    return _buildSection(
      title: 'Country',
      icon: Icons.public,
      child: _buildCountrySelector(),
    );
  }

  Widget _buildAgeSection() {
    return _buildSection(
      title: 'Age Range',
      icon: Icons.cake,
      child: _buildAgeSelector(),
    );
  }

  Widget _buildGenderSection() {
    return _buildSection(
      title: 'Gender Preference',
      icon: Icons.person,
      child: _buildGenderSelector(),
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
            Icon(icon, size: 20, color: context.primaryColor),
            Spacing.hGapSM,
            Text(
              title,
              style: context.titleMedium,
            ),
          ],
        ),
        Spacing.gapMD,
        child,
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return InkWell(
      onTap: _openLanguagePicker,
      borderRadius: AppRadius.borderMD,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            // Flag emoji
            if (_selectedLanguage != null)
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: Text(
                  _selectedLanguage!.flag,
                  style: const TextStyle(fontSize: 28),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: Icon(
                  Icons.public,
                  size: 28,
                  color: context.textMuted,
                ),
              ),

            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLanguage?.name ?? AppLocalizations.of(context)!.anyLanguage,
                    style: context.titleMedium.copyWith(
                      color: _selectedLanguage != null
                          ? context.textPrimary
                          : context.textSecondary,
                    ),
                  ),
                  if (_selectedLanguage != null) ...[
                    Spacing.gapXXS,
                    Text(
                      _selectedLanguage!.nativeName,
                      style: context.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Column(
      children: [
        // Auto-detect location button
        GestureDetector(
          onTap: _isDetectingLocation ? null : _autoDetectLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 14),
            margin: const EdgeInsets.only(bottom: Spacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.borderMD,
              boxShadow: AppShadows.colored,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isDetectingLocation)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(context.textOnPrimary),
                    ),
                  )
                else
                  Icon(
                    Icons.my_location,
                    color: context.textOnPrimary,
                    size: 20,
                  ),
                Spacing.hGapSM,
                Text(
                  _isDetectingLocation ? 'Detecting...' : 'Auto-detect my location',
                  style: context.labelLarge.copyWith(color: context.textOnPrimary),
                ),
              ],
            ),
          ),
        ),

        // Country picker
        InkWell(
          onTap: _openCountryPicker,
          borderRadius: AppRadius.borderMD,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.borderMD,
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                // Flag emoji
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: Text(
                    _getCountryFlag(_selectedCountry),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),

                // Country name
                Expanded(
                  child: Text(
                    _selectedCountry ?? 'Any Country',
                    style: context.titleMedium.copyWith(
                      color: _selectedCountry != null
                          ? context.textPrimary
                          : context.textSecondary,
                    ),
                  ),
                ),

                // Clear button if selected
                if (_selectedCountry != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCountry = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.xs),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                Spacing.hGapSM,

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAgeButton('Min: ${_minAge.toInt()}', AppColors.success),
              _buildAgeButton('Max: ${_maxAge.toInt()}', AppColors.info),
            ],
          ),
          Spacing.gapXL,
          RangeSlider(
            values: RangeValues(_minAge, _maxAge),
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: context.primaryColor,
            inactiveColor: context.dividerColor,
            onChanged: (values) {
              setState(() {
                _minAge = values.start;
                _maxAge = values.end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgeButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.borderSM,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: context.labelLarge.copyWith(color: color),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(Spacing.xs),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          _buildGenderButton('Any', null, Icons.people),
          _buildGenderButton('Male', 'Male', Icons.man),
          _buildGenderButton('Female', 'Female', Icons.woman),
          _buildGenderButton('Other', 'Other', Icons.person_outline),
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
          });
        },
        child: Container(
          margin: const EdgeInsets.all(Spacing.xs),
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: BoxDecoration(
            color: isSelected ? context.primaryColor : context.containerColor,
            borderRadius: AppRadius.borderSM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? context.textOnPrimary : context.textSecondary,
                size: 20,
              ),
              Spacing.gapXS,
              Text(
                label,
                style: context.labelSmall.copyWith(
                  color: isSelected ? context.textOnPrimary : context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
          Spacing.hGapLG,
          Text(
            'Loading languages...',
            style: context.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          Spacing.hGapMD,
          Expanded(
            child: Text(
              _errorMessage,
              style: context.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isLoadingLanguages = true;
                _errorMessage = '';
              });
              fetchLanguages();
            },
            icon: const Icon(Icons.refresh, color: AppColors.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Country picker bottom sheet with search
class _CountryPickerSheet extends StatefulWidget {
  final List<Map<String, String>> countries;
  final String? selectedCountry;
  final Function(String?) onSelect;

  const _CountryPickerSheet({
    required this.countries,
    this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where((c) =>
                c['name']!.toLowerCase().contains(query.toLowerCase()) ||
                c['code']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Spacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Text(
                  'Select Country',
                  style: context.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => widget.onSelect(null),
                  child: Text(
                    'Any Country',
                    style: context.labelLarge.copyWith(color: context.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: context.bodyMedium.copyWith(color: context.textMuted),
                prefixIcon: Icon(Icons.search, color: context.textMuted),
                filled: true,
                fillColor: context.containerColor,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderMD,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
              ),
            ),
          ),

          Spacing.gapSM,

          // Country list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country['name'] == widget.selectedCountry;

                return ListTile(
                  onTap: () => widget.onSelect(country['name']),
                  leading: Text(
                    country['flag']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    country['name']!,
                    style: context.titleSmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? context.primaryColor : context.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: context.primaryColor,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                  tileColor: isSelected
                      ? context.primaryColor.withOpacity(0.1)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
