import 'dart:convert';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

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
  Language? _selectedLanguage;
  List<Language> _languages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    setState(() => _isLoading = true);

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
        });

        // Set selected language from initial value after languages are loaded
        if (widget.initialLanguage.isNotEmpty && _languages.isNotEmpty) {
          try {
            final matchingLanguage = _languages.firstWhere(
              (lang) => lang.name == widget.initialLanguage,
            );
            setState(() {
              _selectedLanguage = matchingLanguage;
            });
          } catch (e) {
            // Language not found, use first language as fallback
            if (_languages.isNotEmpty) {
              setState(() {
                _selectedLanguage = _languages.first;
              });
            }
            if (kDebugMode) {
              print('Initial language "${widget.initialLanguage}" not found, using first language');
            }
          }
        }
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

  // Open language picker
  Future<void> _openLanguagePicker() async {
    if (_languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languagesAreStillLoading),
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
    final isNative = widget.type == 'native';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isNative 
                ? AppLocalizations.of(context)!.selectYourNativeLanguage 
                : AppLocalizations.of(context)!.whichLanguageDoYouWantToLearn),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Language selector button/tile
                  InkWell(
                    onTap: _openLanguagePicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // Flag emoji or icon
                          if (_selectedLanguage != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                _selectedLanguage!.flag,
                                style: const TextStyle(fontSize: 32),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.language,
                                size: 32,
                                color: Colors.grey[600],
                              ),
                            ),
                          
                          // Language names
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNative
                                      ? 'Native Language (Required)'
                                      : 'Language to Learn (Required)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedLanguage?.name ?? AppLocalizations.of(context)!.selectALanguage,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedLanguage != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (_selectedLanguage != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedLanguage!.nativeName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Arrow icon
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedLanguage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select a language')),
                        );
                        return;
                      }

                      final languageName = _selectedLanguage!.name;

                      // Update user language via provider
                      if (isNative) {
                        await ref
                            .read(authServiceProvider)
                            .updateUserNativeLanguage(
                                natLang: languageName);
                      } else {
                        await ref
                            .read(authServiceProvider)
                            .updateUserLanguageToLearn(
                                langToLearn: languageName);
                      }

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved: $languageName')),
                      );

                      // Return to parent with result
                      Navigator.of(context).pop(languageName);
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
