import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/models/ai/grammar_feedback_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Grammar Feedback Analysis Screen
class GrammarFeedbackScreen extends ConsumerStatefulWidget {
  const GrammarFeedbackScreen({super.key});

  @override
  ConsumerState<GrammarFeedbackScreen> createState() =>
      _GrammarFeedbackScreenState();
}

class _GrammarFeedbackScreenState extends ConsumerState<GrammarFeedbackScreen> {
  final TextEditingController _textController = TextEditingController();
  Language? _selectedLanguage;
  bool _isAnalyzing = false;
  GrammarFeedback? _feedback;
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

          // Set default language (English)
          if (_languages.isNotEmpty) {
            _selectedLanguage = _languages.firstWhere(
              (l) => l.code == 'en',
              orElse: () => _languages.first,
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

  Future<void> _openLanguagePicker() async {
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
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLanguage = result;
        _feedback = null;
      });
    }
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (_selectedLanguage == null) {
      setState(() {
        _error = 'Please select a language';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    final request = AnalyzeGrammarRequest(
      text: text,
      targetLanguage: _selectedLanguage!.code,
    );

    final result = await AIService.analyzeGrammar(request);

    setState(() {
      _isAnalyzing = false;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is GrammarFeedback) {
          _feedback = data;
        } else if (data is Map) {
          _feedback = GrammarFeedback.fromJson(Map<String, dynamic>.from(data));
        } else {
          _error = 'Unexpected response format';
        }
      } else {
        _error = result['message']?.toString() ?? 'Analysis failed';
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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(grammarFeedbackHistoryProvider);

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
          'Grammar Check',
          style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            _buildInputSection(),
            const SizedBox(height: 20),

            // Results Section
            if (_feedback != null) ...[
              _buildScoreCard(),
              const SizedBox(height: 16),

              // Perfect text badge
              if (_feedback!.isPerfect) ...[
                _buildPerfectBadge(),
                const SizedBox(height: 16),
              ],

              // Positives Section
              if (_feedback!.hasPositives) ...[
                _buildPositivesSection(),
                const SizedBox(height: 16),
              ],

              // Errors Section
              if (_feedback!.hasErrors) ...[
                _buildErrorsSection(),
                const SizedBox(height: 16),
              ],

              // Corrected Text
              _buildCorrectedTextSection(),
              const SizedBox(height: 16),

              // Suggestions Section
              if (_feedback!.hasSuggestions) ...[
                _buildSuggestionsSection(),
                const SizedBox(height: 16),
              ],

              // Summary Section
              if (_feedback!.summary.isNotEmpty) ...[
                _buildSummarySection(),
                const SizedBox(height: 16),
              ],
            ],

            // Error
            if (_error != null) ...[
              _buildErrorAlert(),
              const SizedBox(height: 20),
            ],

            // History Section
            Text(
              'Recent Analysis',
              style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Spacing.gapMD,
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return _buildEmptyHistory();
                }
                return Column(
                  children: history
                      .take(5)
                      .map((h) => _buildHistoryCard(h))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.success),
              ),
              error: (_, __) => _buildEmptyHistory(),
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
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language Selection
          _buildLanguageSelector(),
          const SizedBox(height: 16),

          // Text Input
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter text to analyze...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeText,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Check Grammar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    if (_isLoadingLanguages) {
      return Row(
        children: [
          const Text(
            'Language:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Text(
          'Language:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _openLanguagePicker,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedLanguage?.flag ?? '🌐',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLanguage?.name ?? 'Select',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedLanguage != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    final score = _feedback!.overallScore;
    final color = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Score Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getScoreLabel(score),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_feedback!.errorCount} ${_feedback!.errorCount == 1 ? 'issue' : 'issues'} found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Score bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfectBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfect!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'No grammar issues found in your text.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositivesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up_rounded, size: 20, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'What You Did Well',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._feedback!.positives.map((positive) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Colors.green[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        positive,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 22, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Issues Found (${_feedback!.errors.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._feedback!.errors.map((error) => _buildErrorCard(error)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(GrammarError error) {
    final severityColor = _getSeverityColor(error.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type and severity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Text(error.typeIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.typeLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original vs Corrected
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              error.original,
                              style: const TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.red,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Corrected',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              error.corrected,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Explanation
                if (error.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    error.explanation,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],

                // Rule
                if (error.hasRule) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error.rule!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Examples
                if (error.hasExamples) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Examples:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: error.examples.map((ex) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ex,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectedTextSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 20, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Corrected Text',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 20, color: Colors.grey[600]),
                onPressed: () => _copyToClipboard(_feedback!.correctedText),
                tooltip: 'Copy',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Text(
              _feedback!.correctedText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 20, color: Colors.purple[600]),
              const SizedBox(width: 8),
              const Text(
                'Improved Suggestions',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._feedback!.suggestions.map((suggestion) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: Colors.purple[400],
                          ),
                          onPressed: () => _copyToClipboard(suggestion.text),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    if (suggestion.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        suggestion.explanation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_rounded, size: 20, color: Colors.teal[600]),
              const SizedBox(width: 8),
              const Text(
                'Summary',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _feedback!.summary,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(GrammarFeedback feedback) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFeedbackDetails(feedback),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getScoreColor(feedback.overallScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${feedback.overallScore}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _getScoreColor(feedback.overallScore),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.originalText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          feedback.isPerfect
                              ? Icons.check_circle_rounded
                              : Icons.edit_note_rounded,
                          size: 14,
                          color: feedback.isPerfect ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feedback.isPerfect
                              ? 'Perfect!'
                              : '${feedback.errors.length} issues',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetails(GrammarFeedback feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getScoreColor(feedback.overallScore)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${feedback.overallScore}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: _getScoreColor(feedback.overallScore),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getScoreLabel(feedback.overallScore),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _getScoreColor(feedback.overallScore),
                              ),
                            ),
                            Text(
                              '${feedback.errorCount} ${feedback.errorCount == 1 ? 'issue' : 'issues'} found',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Original Text
                      _buildDetailSection(
                        icon: Icons.text_fields,
                        title: 'Original Text',
                        color: Colors.grey[700]!,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            feedback.originalText,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Corrected Text
                      _buildDetailSection(
                        icon: Icons.check_circle_rounded,
                        title: 'Corrected Text',
                        color: Colors.green[600]!,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.green.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  feedback.correctedText,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.5),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy_rounded,
                                    size: 20, color: Colors.grey[600]),
                                onPressed: () =>
                                    _copyToClipboard(feedback.correctedText),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Errors
                      if (feedback.hasErrors) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection(
                          icon: Icons.edit_note_rounded,
                          title: 'Issues Found (${feedback.errors.length})',
                          color: Colors.orange[700]!,
                          child: Column(
                            children: feedback.errors
                                .map((e) => _buildErrorCard(e))
                                .toList(),
                          ),
                        ),
                      ],

                      // Positives
                      if (feedback.hasPositives) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection(
                          icon: Icons.thumb_up_rounded,
                          title: 'What You Did Well',
                          color: Colors.green[600]!,
                          child: Column(
                            children: feedback.positives
                                .map((p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              size: 18,
                                              color: Colors.green[500]),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              p,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],

                      // Suggestions
                      if (feedback.hasSuggestions) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection(
                          icon: Icons.auto_fix_high_rounded,
                          title: 'Suggestions',
                          color: Colors.purple[600]!,
                          child: Column(
                            children: feedback.suggestions
                                .map((s) => Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color:
                                                Colors.purple.withOpacity(0.15)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.text,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (s.explanation.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              s.explanation,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],

                      // Summary
                      if (feedback.summary.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection(
                          icon: Icons.summarize_rounded,
                          title: 'Summary',
                          color: Colors.teal[600]!,
                          child: Text(
                            feedback.summary,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: Spacing.paddingXL,
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: context.textMuted,
          ),
          Spacing.gapMD,
          Text(
            'No analysis history yet',
            style: context.bodyMedium?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF10B981);
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Very Good';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Needs Work';
    return 'Keep Practicing';
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'major':
        return Colors.orange;
      case 'minor':
        return Colors.amber[700]!;
      case 'moderate':
        return Colors.orange[600]!;
      default:
        return Colors.blue;
    }
  }
}
