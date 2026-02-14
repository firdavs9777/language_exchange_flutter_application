import 'package:bananatalk_app/services/language_service.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
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
            backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.error,
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
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.languageSettings,
          style: context.titleLarge,
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
                    padding: Spacing.paddingLG,
                    margin: Spacing.screenPadding,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: AppRadius.borderMD,
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.info),
                            Spacing.hGapSM,
                            Text(
                              l10n.deviceLanguage,
                              style: context.titleMedium.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        Spacing.gapSM,
                        Text(
                          l10n.yourDeviceIsSetTo(
                            LanguageService.getLanguageFlag(deviceLanguage),
                            LanguageService.getLanguageName(deviceLanguage),
                          ),
                          style: context.bodyMedium.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                        if (_selectedLanguage != deviceLanguage) ...[
                          Spacing.gapSM,
                          Text(
                            l10n.youCanOverride,
                            style: context.bodySmall.copyWith(
                              color: AppColors.info,
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
                          style: context.titleMedium,
                        ),
                        Spacing.gapMD,
                        ...languages.map((lang) {
                          final isSelected = _selectedLanguage == lang['code'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: isSelected ? 2 : 0,
                            color: context.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMD,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
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
                                style: context.titleMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                lang['code']!.toUpperCase(),
                                style: context.caption,
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () => _changeLanguage(lang['code']!),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  Spacing.gapXXL,

                  // Auto-translate settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.autoTranslateSettings,
                          style: context.titleMedium,
                        ),
                        Spacing.gapMD,
                        Card(
                          color: context.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text(
                                  l10n.autoTranslateMessages,
                                  style: context.titleSmall,
                                ),
                                subtitle: Text(
                                  l10n.automaticallyTranslateIncomingMessages,
                                  style: context.bodySmall,
                                ),
                                value: _autoTranslateMessages,
                                activeColor: AppColors.primary,
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
                              Divider(height: 1, color: context.dividerColor),
                              SwitchListTile(
                                title: Text(
                                  l10n.autoTranslateMoments,
                                  style: context.titleSmall,
                                ),
                                subtitle: Text(
                                  l10n.automaticallyTranslateMomentsInFeed,
                                  style: context.bodySmall,
                                ),
                                value: _autoTranslateMoments,
                                activeColor: AppColors.primary,
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
                              Divider(height: 1, color: context.dividerColor),
                              SwitchListTile(
                                title: Text(
                                  l10n.autoTranslateComments,
                                  style: context.titleSmall,
                                ),
                                subtitle: Text(
                                  l10n.automaticallyTranslateComments,
                                  style: context.bodySmall,
                                ),
                                value: _autoTranslateComments,
                                activeColor: AppColors.primary,
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

                  Spacing.gapXXL,
                ],
              ),
            ),
    );
  }
}
