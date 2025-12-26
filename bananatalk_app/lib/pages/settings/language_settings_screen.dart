import 'package:bananatalk_app/services/language_service.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/main.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String? _selectedLanguage;
  bool _isLoading = false;
  bool _autoTranslateMessages = true;
  bool _autoTranslateMoments = true;
  bool _autoTranslateComments = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    _loadAutoTranslateSettings();
  }

  Future<void> _loadAutoTranslateSettings() async {
    final messages = await TranslationService.shouldAutoTranslate('messages');
    final moments = await TranslationService.shouldAutoTranslate('moments');
    final comments = await TranslationService.shouldAutoTranslate('comments');
    
    setState(() {
      _autoTranslateMessages = messages;
      _autoTranslateMoments = moments;
      _autoTranslateComments = comments;
    });
  }

  Future<void> _loadCurrentLanguage() async {
    final currentLang = await LanguageService.getAppLanguage();
    setState(() {
      _selectedLanguage = currentLang;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (_selectedLanguage == languageCode) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await LanguageService.setAppLanguage(languageCode);
      ref.read(languageProvider.notifier).setLanguage(languageCode);
      
      setState(() {
        _selectedLanguage = languageCode;
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageChangedTo(LanguageService.getLanguageName(languageCode)),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorChangingLanguage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deviceLanguage = LanguageService.getDeviceLanguage();
    final languages = LanguageService.getSupportedLanguagesList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.languageSettings,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deviceLanguage,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.yourDeviceIsSetTo(
                            LanguageService.getLanguageFlag(deviceLanguage),
                            LanguageService.getLanguageName(deviceLanguage),
                          ),
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedLanguage != deviceLanguage) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.youCanOverride,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Language list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectLanguage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...languages.map((lang) {
                          final isSelected = _selectedLanguage == lang['code'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: isSelected ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: ListTile(
                              leading: Text(
                                lang['flag']!,
                                style: const TextStyle(fontSize: 28),
                              ),
                              title: Text(
                                lang['name']!,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                lang['code']!.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                    )
                                  : null,
                              onTap: () => _changeLanguage(lang['code']!),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Auto-translate settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.autoTranslateSettings,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text(l10n.autoTranslateMessages),
                                subtitle: Text(
                                  l10n.automaticallyTranslateIncomingMessages,
                                ),
                                value: _autoTranslateMessages,
                                onChanged: (value) async {
                                  setState(() {
                                    _autoTranslateMessages = value;
                                  });
                                  await TranslationService.setAutoTranslate(
                                    'messages',
                                    value,
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: Text(l10n.autoTranslateMoments),
                                subtitle: Text(
                                  l10n.automaticallyTranslateMomentsInFeed,
                                ),
                                value: _autoTranslateMoments,
                                onChanged: (value) async {
                                  setState(() {
                                    _autoTranslateMoments = value;
                                  });
                                  await TranslationService.setAutoTranslate(
                                    'moments',
                                    value,
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: Text(l10n.autoTranslateComments),
                                subtitle: Text(
                                  l10n.automaticallyTranslateComments,
                                ),
                                value: _autoTranslateComments,
                                onChanged: (value) async {
                                  setState(() {
                                    _autoTranslateComments = value;
                                  });
                                  await TranslationService.setAutoTranslate(
                                    'comments',
                                    value,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

