import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';

class CommunityFilter extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  const CommunityFilter({
    super.key,
    required this.onApplyFilters,
    required this.initialFilters,
  });

  @override
  State<CommunityFilter> createState() => _CommunityFilterState();
}

class _CommunityFilterState extends State<CommunityFilter> {
  late double _minAge = 18;
  late double _maxAge = 100;
  late String? _selectedGender;
  late String? _selectedLanguage;
  List<String> _languages = [];
  bool _isLoadingLanguages = true;
  String _errorMessage = '';
  final List<String> genders = ['Male', 'Female', 'Other'];

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
    _selectedLanguage = widget.initialFilters['nativeLanguage'];
  }

  Future<void> fetchLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> languagesList = data['data'] ?? [];
        print(languagesList);
        setState(() {
          _languages = languagesList.map<String>((lang) {
            return lang['name']?.toString() ?? lang.toString();
          }).toList();
          _isLoadingLanguages = false;
        });
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      setState(() {
        _isLoadingLanguages = false;
        _errorMessage = 'Failed to load languages. Please try again.';
      });
    }
  }

  void resetFilters() {
    setState(() {
      _minAge = 18.0;
      _maxAge = 100.0;
      _selectedGender = null;
      _selectedLanguage = null;
    });
  }

  void _applyFilters() {
    // Convert gender to lowercase to match backend format
    String? genderValue = _selectedGender?.toLowerCase();
    
    final filters = {
      'minAge': _minAge.toInt(),
      'maxAge': _maxAge.toInt(),
      'gender': genderValue, // Send lowercase to match backend
      'nativeLanguage': _selectedLanguage, // Language names should match exactly
    };
    
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filter Communities',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
            Icon(icon, size: 20, color: const Color(0xFF00BFA5)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: _selectedLanguage,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: 'Select native language',
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        onChanged: (newValue) {
          setState(() {
            _selectedLanguage = newValue;
          });
        },
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Any Language'),
          ),
          ..._languages.map<DropdownMenuItem<String>>((language) {
            return DropdownMenuItem<String>(
              value: language, // Store language name (e.g., "Korean")
              child: Text(language),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAgeButton('Min: ${_minAge.toInt()}', Colors.green[400]!),
              _buildAgeButton('Max: ${_maxAge.toInt()}', Colors.blue[400]!),
            ],
          ),
          const SizedBox(height: 20),
          RangeSlider(
            values: RangeValues(_minAge, _maxAge),
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: const Color(0xFF00BFA5),
            inactiveColor: Colors.grey[200],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00BFA5) : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Loading languages...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
            icon: Icon(Icons.refresh, color: Colors.red[400], size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
