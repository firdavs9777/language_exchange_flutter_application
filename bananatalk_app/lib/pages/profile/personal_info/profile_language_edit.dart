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
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ProfileLanguageEdit extends ConsumerStatefulWidget {
  final String initialLanguage;
  final String type; // 'native' or 'learn'
  final String? otherLanguage; // The other language to validate against

  const ProfileLanguageEdit({
    super.key,
    required this.initialLanguage,
    required this.type,
    this.otherLanguage,
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
          _languages = languagesList
              .map<Language>((json) => Language.fromJson(json))
              .toList();
        });

        if (widget.initialLanguage.isNotEmpty && _languages.isNotEmpty) {
          try {
            final matchingLanguage = _languages.firstWhere(
              (lang) => lang.name == widget.initialLanguage,
            );
            setState(() {
              _selectedLanguage = matchingLanguage;
            });
          } catch (e) {
            if (_languages.isNotEmpty) {
              setState(() {
                _selectedLanguage = _languages.first;
              });
            }
            if (kDebugMode) {
              debugPrint('Language not found: ${widget.initialLanguage}');
            }
          }
        }
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToLoadLanguages),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;

    if (_languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.languagesAreStillLoading),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      AppPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );

    if (result != null) {
      if (widget.otherLanguage != null &&
          result.name.toLowerCase() == widget.otherLanguage!.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.type == 'native'
                  ? l10n.nativeLanguageCannotBeSame
                  : l10n.learningLanguageCannotBeSame,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _selectedLanguage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNative = widget.type == 'native';

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          isNative
              ? l10n.selectYourNativeLanguage
              : l10n.whichLanguageDoYouWantToLearn,
          style: context.titleLarge,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: Spacing.screenPadding,
              child: Column(
                children: [
                  InkWell(
                    onTap: _openLanguagePicker,
                    borderRadius: AppRadius.borderLG,
                    child: Container(
                      padding: Spacing.paddingLG,
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        border: Border.all(color: context.dividerColor),
                        borderRadius: AppRadius.borderLG,
                      ),
                      child: Row(
                        children: [
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
                                color: context.textSecondary,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNative
                                      ? l10n.nativeLanguageRequired
                                      : l10n.languageToLearnRequired,
                                  style: context.caption.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                                Spacing.gapXS,
                                Text(
                                  _selectedLanguage?.name ?? l10n.selectALanguage,
                                  style: context.titleMedium.copyWith(
                                    color: _selectedLanguage != null
                                        ? context.textPrimary
                                        : context.textSecondary,
                                  ),
                                ),
                                if (_selectedLanguage != null) ...[
                                  Spacing.gapXS,
                                  Text(
                                    _selectedLanguage!.nativeName,
                                    style: context.bodySmall.copyWith(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: context.iconColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Spacing.gapXL,
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedLanguage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.pleaseSelectALanguage),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      if (widget.otherLanguage != null &&
                          _selectedLanguage!.name.toLowerCase() ==
                              widget.otherLanguage!.toLowerCase()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.type == 'native'
                                  ? l10n.nativeLanguageCannotBeSame
                                  : l10n.learningLanguageCannotBeSame,
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final languageName = _selectedLanguage!.name;

                      if (isNative) {
                        await ref
                            .read(authServiceProvider)
                            .updateUserNativeLanguage(natLang: languageName);
                      } else {
                        await ref
                            .read(authServiceProvider)
                            .updateUserLanguageToLearn(langToLearn: languageName);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.saved}: $languageName'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop(languageName);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.gray900,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                    ),
                    child: Text(
                      l10n.save,
                      style: context.titleMedium.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
