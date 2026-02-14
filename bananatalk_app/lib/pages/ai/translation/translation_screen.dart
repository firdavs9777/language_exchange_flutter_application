import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/models/ai/translation_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Enhanced Translation Screen
class TranslationScreen extends ConsumerStatefulWidget {
  const TranslationScreen({super.key});

  @override
  ConsumerState<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends ConsumerState<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  Language? _sourceLanguage;
  Language? _targetLanguage;
  bool _isTranslating = false;
  EnhancedTranslation? _result;
  String? _error;

  List<Language> _languages = [];
  bool _isLoadingLanguages = true;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final languagesList = data['data'] as List<dynamic>? ?? [];

        setState(() {
          _languages = languagesList
              .map((json) => Language.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoadingLanguages = false;

          // Set default languages (English -> Spanish)
          if (_languages.isNotEmpty) {
            _sourceLanguage = _languages.firstWhere(
              (l) => l.code == 'en',
              orElse: () => _languages.first,
            );
            _targetLanguage = _languages.firstWhere(
              (l) => l.code == 'es',
              orElse: () => _languages.length > 1 ? _languages[1] : _languages.first,
            );
          }
        });
      } else {
        setState(() {
          _isLoadingLanguages = false;
          _error = 'Failed to load languages';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLanguages = false;
        _error = 'Error loading languages: $e';
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      if (_result != null) {
        _textController.text = _result!.translation;
        _result = null;
      }
    });
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (_sourceLanguage == null || _targetLanguage == null) {
      setState(() {
        _error = 'Please select source and target languages';
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _error = null;
    });

    final request = EnhancedTranslationRequest(
      text: text,
      sourceLanguage: _sourceLanguage!.code,
      targetLanguage: _targetLanguage!.code,
    );

    final result = await AIService.getEnhancedTranslation(request);

    setState(() {
      _isTranslating = false;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is EnhancedTranslation) {
          _result = data;
        } else if (data is Map<String, dynamic>) {
          _result = EnhancedTranslation.fromJson(data);
        } else if (data is Map) {
          _result = EnhancedTranslation.fromJson(Map<String, dynamic>.from(data));
        } else {
          _error = 'Unexpected response format';
        }
      } else {
        _error = result['message']?.toString() ?? 'Translation failed';
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openLanguagePicker({required bool isSource}) async {
    if (_languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Languages are still loading...')),
      );
      return;
    }

    final result = await Navigator.push<Language>(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: isSource ? _sourceLanguage : _targetLanguage,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isSource) {
          _sourceLanguage = result;
        } else {
          _targetLanguage = result;
        }
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Smart Translation',
          style: context.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selector
            _buildLanguageSelector(),
            Spacing.gapLG,

            // Input Section
            _buildInputSection(),
            Spacing.gapLG,

            // Results Section
            if (_result != null) ...[
              _buildResultsSection(),
              Spacing.gapLG,

              // Breakdown Section
              if (_result!.breakdown != null) ...[
                _buildBreakdownSection(),
                Spacing.gapLG,
              ],

              // Alternatives Section
              if (_result!.hasAlternatives) ...[
                _buildAlternativesSection(),
                Spacing.gapLG,
              ],

              // Grammar Notes Section
              if (_result!.hasGrammarNotes) ...[
                _buildGrammarNotesSection(),
                Spacing.gapLG,
              ],

              // Idioms Section
              if (_result!.hasIdioms) ...[
                _buildIdiomsSection(),
                Spacing.gapLG,
              ],

              // Cultural Context
              if (_result!.culturalContext != null) ...[
                _buildCulturalContextSection(),
                Spacing.gapLG,
              ],
            ],

            // Error
            if (_error != null) ...[
              _buildErrorSection(),
              Spacing.gapLG,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    if (_isLoadingLanguages) {
      return Container(
        padding: Spacing.paddingXL,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: Spacing.paddingMD,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageButton(
              language: _sourceLanguage,
              onTap: () => _openLanguagePicker(isSource: true),
            ),
          ),
          IconButton(
            onPressed: _swapLanguages,
            icon: Icon(
              Icons.swap_horiz_rounded,
              color: context.primaryColor,
            ),
          ),
          Expanded(
            child: _buildLanguageButton(
              language: _targetLanguage,
              onTap: () => _openLanguagePicker(isSource: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({
    required Language? language,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderSM,
      child: Container(
        padding: Spacing.paddingMD,
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderSM,
        ),
        child: Row(
          children: [
            Text(
              language?.flag ?? '🌐',
              style: context.titleLarge,
            ),
            Spacing.hGapSM,
            Expanded(
              child: Text(
                language?.name ?? 'Select',
                style: context.labelLarge.copyWith(
                  color: language != null ? context.textPrimary : context.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: context.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_sourceLanguage?.flag ?? '🌐'} ${_sourceLanguage?.name ?? 'Source'}',
                style: context.labelLarge,
              ),
            ],
          ),
          Spacing.gapMD,
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter text to translate...',
              hintStyle: context.bodyMedium.copyWith(color: context.textHint),
              border: InputBorder.none,
            ),
            style: context.bodyLarge,
          ),
          Spacing.gapMD,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTranslating ? null : _translate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: _isTranslating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Translate',
                      style: context.titleSmall.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_targetLanguage?.flag ?? '🌐'} ${_targetLanguage?.name ?? 'Target'}',
                style: context.labelLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: context.iconColor,
                onPressed: () => _copyToClipboard(_result!.translation),
              ),
            ],
          ),
          Spacing.gapSM,
          Text(
            _result!.translation,
            style: context.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    final breakdown = _result!.breakdown!;
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 20,
                color: AppColors.info,
              ),
              Spacing.hGapSM,
              Text(
                'Word Breakdown',
                style: context.titleSmall,
              ),
            ],
          ),
          Spacing.gapLG,
          if (breakdown.words.isNotEmpty)
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: breakdown.words.map((w) {
                return Container(
                  padding: Spacing.paddingSM,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: AppRadius.borderSM,
                    border: Border.all(color: context.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.original,
                        style: context.labelLarge,
                      ),
                      Text(
                        w.translation,
                        style: context.bodySmall,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: AppRadius.borderXS,
                        ),
                        child: Text(
                          w.posAbbreviation,
                          style: context.captionSmall.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (breakdown.explanation.isNotEmpty) ...[
            Spacing.gapLG,
            Container(
              padding: Spacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.05),
                borderRadius: AppRadius.borderSM,
              ),
              child: Text(
                breakdown.explanation,
                style: context.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativesSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 20,
                color: AppColors.accent,
              ),
              Spacing.hGapSM,
              Text(
                'Alternative Translations',
                style: context.titleSmall,
              ),
            ],
          ),
          Spacing.gapMD,
          ..._result!.alternatives.map((alt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: Spacing.paddingMD,
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: AppRadius.borderSM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alt.text,
                          style: context.labelLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: AppRadius.borderSM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              alt.formalityIcon,
                              style: context.caption,
                            ),
                            Spacing.hGapXS,
                            Text(
                              alt.formality,
                              style: context.captionSmall.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (alt.context.isNotEmpty) ...[
                    Spacing.gapXS,
                    Text(
                      alt.context,
                      style: context.caption,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrammarNotesSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                size: 20,
                color: AppColors.success,
              ),
              Spacing.hGapSM,
              Text(
                'Grammar Notes',
                style: context.titleSmall,
              ),
            ],
          ),
          Spacing.gapMD,
          ..._result!.grammarNotes.map((note) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: Spacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: AppRadius.borderSM,
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.topic,
                    style: context.labelLarge.copyWith(color: AppColors.success),
                  ),
                  Spacing.gapXS,
                  Text(
                    note.explanation,
                    style: context.bodySmall,
                  ),
                  if (note.tip != null) ...[
                    Spacing.gapSM,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        Spacing.hGapXS,
                        Expanded(
                          child: Text(
                            note.tip!,
                            style: context.caption.copyWith(
                              color: AppColors.warning,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIdiomsSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              Spacing.hGapSM,
              Text(
                'Idioms & Expressions',
                style: context.titleSmall,
              ),
            ],
          ),
          Spacing.gapMD,
          ..._result!.idioms.map((idiom) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: Spacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.05),
                borderRadius: AppRadius.borderSM,
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idiom.original,
                    style: context.labelLarge,
                  ),
                  Spacing.gapXS,
                  Text(
                    'Literal: ${idiom.literalTranslation}',
                    style: context.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                  Spacing.gapXS,
                  Text(
                    'Meaning: ${idiom.meaning}',
                    style: context.bodySmall,
                  ),
                  if (idiom.equivalentIdiom.isNotEmpty) ...[
                    Spacing.gapXS,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: AppRadius.borderXS,
                      ),
                      child: Text(
                        'Equivalent: ${idiom.equivalentIdiom}',
                        style: context.caption.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCulturalContextSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.public_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              Spacing.hGapSM,
              Text(
                'Cultural Context',
                style: context.titleSmall,
              ),
            ],
          ),
          Spacing.gapMD,
          Text(
            _result!.culturalContext!,
            style: context.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          Spacing.hGapMD,
          Expanded(
            child: Text(
              _error!,
              style: context.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
