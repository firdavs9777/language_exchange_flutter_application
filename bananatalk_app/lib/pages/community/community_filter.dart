import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommunityFilter extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  const CommunityFilter(
      {super.key, required this.onApplyFilters, required this.initialFilters});

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
  final List<String> genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _minAge = (widget.initialFilters['minAge'] ?? 18).toDouble();
    _maxAge = (widget.initialFilters['maxAge'] ?? 100).toDouble();
    _selectedGender = widget.initialFilters['gender'];
    _selectedLanguage = widget.initialFilters['nativeLanguage'];
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5003/api/v1/languages'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          _languages = data.map<String>((lang) => lang['name']).toList();
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
      _minAge = (widget.initialFilters['minAge'] ?? 18).toDouble();
      _maxAge = (widget.initialFilters['maxAge'] ?? 100).toDouble();
      _selectedGender = widget.initialFilters['gender'];
      _selectedLanguage = widget.initialFilters['nativeLanguage'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: resetFilters,
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Dropdown with loading and error handling
            const Text(
              'Native Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _isLoadingLanguages
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      )
                    : DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedLanguage,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: 'Language partner\'s native language',
                        ),
                        items: _languages
                            .map<DropdownMenuItem<String>>((String language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(language),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 16),

            // Age Range Slider
            const Text(
              'Age Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RangeSlider(
              values: RangeValues(_minAge, _maxAge),
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels(
                _minAge.toInt().toString(),
                _maxAge.toInt().toString(),
              ),
              onChanged: (values) {
                setState(() {
                  _minAge = values.start;
                  _maxAge = values.end;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Min Age: ${_minAge.toInt()}'),
                Text('Max Age: ${_maxAge.toInt()}'),
              ],
            ),
            const SizedBox(height: 16),

            // Gender Dropdown
            const Text(
              'Gender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedGender,
              hint: const Text('Select Gender'),
              items: genders.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  onPressed: () {
                    final filters = {
                      'minAge': _minAge.toInt(),
                      'maxAge': _maxAge.toInt(),
                      'gender': _selectedGender,
                      'nativeLanguage': _selectedLanguage,
                    };
                    widget.onApplyFilters(filters);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
