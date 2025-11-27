import 'dart:convert';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ProfileLanguageEdit extends ConsumerStatefulWidget {
  final String initialLanguage;
  final String type; // 'native' or 'learn'

  const ProfileLanguageEdit({
    super.key,
    required this.initialLanguage,
    required this.type,
  });

  @override
  _ProfileLanguageEditState createState() => _ProfileLanguageEditState();
}

class _ProfileLanguageEditState extends ConsumerState<ProfileLanguageEdit> {
  late String _selectedLanguage;
  List<String> _languages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://api.banatalk.com/api/v1/languages'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          _languages =
              data.map<String>((lang) => lang['name'] as String).toList();
        });
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      print('Error fetching languages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load languages')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNative = widget.type == 'native';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isNative ? 'Select Native Language' : 'Select Language to Learn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value:
                        _selectedLanguage.isNotEmpty ? _selectedLanguage : null,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedLanguage = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelText: isNative
                          ? 'Native Language (Required)'
                          : 'Language to Learn (Required)',
                      prefixIcon: const Icon(Icons.language),
                    ),
                    items: _languages
                        .map<DropdownMenuItem<String>>((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedLanguage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select a language')),
                        );
                        return;
                      }

                      // Update user language via provider
                      if (isNative) {
                        await ref
                            .read(authServiceProvider)
                            .updateUserNativeLanguage(
                                natLang: _selectedLanguage);
                      } else {
                        await ref
                            .read(authServiceProvider)
                            .updateUserLanguageToLearn(
                                langToLearn: _selectedLanguage);
                      }

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved: $_selectedLanguage')),
                      );

                      // Return to parent with result
                      Navigator.of(context).pop(_selectedLanguage);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
