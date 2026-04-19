import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/models/ai/speech_model.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Pronunciation Practice Screen
class PronunciationScreen extends ConsumerStatefulWidget {
  const PronunciationScreen({super.key});

  @override
  ConsumerState<PronunciationScreen> createState() =>
      _PronunciationScreenState();
}

class _PronunciationScreenState extends ConsumerState<PronunciationScreen> {
  final TextEditingController _textController = TextEditingController();
  Language? _selectedLanguage;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isLoadingTTS = false;
  PronunciationResult? _result;
  String? _error;

  final List<String> _sampleTexts = [
    'Hello, how are you today?',
    'The quick brown fox jumps over the lazy dog.',
    'I would like to order a coffee, please.',
    'Can you help me find the train station?',
    'Nice to meet you, my name is...',
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = _sampleTexts[0];
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
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
          _isLoadingLanguages = false;

          // Default to English if available
          if (_languages.isNotEmpty) {
            try {
              _selectedLanguage = _languages.firstWhere(
                (lang) => lang.code.toLowerCase() == 'en',
              );
            } catch (e) {
              _selectedLanguage = _languages.first;
            }
          }
        });
      } else {
        setState(() {
          _isLoadingLanguages = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLanguages = false;
      });
    }
  }

  Future<void> _openLanguagePicker() async {
    if (_languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Languages are still loading...'),
          backgroundColor: Color(0xFFF59E0B),
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
      setState(() {
        _selectedLanguage = result;
      });
    }
  }

  Widget _buildLanguageSelector() {
    if (_isLoadingLanguages) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.containerColor,
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
                valueColor: AlwaysStoppedAnimation<Color>(context.textMuted),
              ),
            ),
            Spacing.hGapMD,
            Text(
              'Loading languages...',
              style: context.bodyMedium?.copyWith(color: context.textMuted),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _openLanguagePicker,
      borderRadius: AppRadius.borderMD,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            // Flag emoji
            if (_selectedLanguage != null)
              Text(
                _selectedLanguage!.flag,
                style: const TextStyle(fontSize: 26),
              )
            else
              Icon(
                Icons.public,
                size: 26,
                color: context.textMuted,
              ),
            Spacing.hGapMD,

            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLanguage?.name ?? 'Select Language',
                    style: context.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _selectedLanguage != null
                          ? context.textPrimary
                          : context.textSecondary,
                    ),
                  ),
                  if (_selectedLanguage != null) ...[
                    Spacing.gapXXS,
                    Text(
                      _selectedLanguage!.nativeName,
                      style: context.bodySmall?.copyWith(color: context.textMuted),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _error = null;
    });
    // Recording will be implemented with platform-specific audio recording
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    // Simulate analysis for demo purposes
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      _error = 'Recording feature requires native audio plugin configuration';
    });
  }

  Future<void> _playTTS() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoadingTTS = true;
    });

    final request = TTSRequest(
      text: text,
      language: _selectedLanguage?.code ?? 'en',
      voice: 'nova',
    );

    final result = await AIService.generateTTS(request);

    setState(() {
      _isLoadingTTS = false;
    });

    if (result['success'] == true) {
      // Play audio using audio player
      // This would typically use audioplayers package
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playing audio...')),
        );
      }
    } else {
      setState(() {
        _error = result['message']?.toString() ?? 'Failed to generate speech';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = _selectedLanguage?.code ?? 'en';
    final historyAsync = ref.watch(pronunciationHistoryProvider(langCode));
    final statsAsync = ref.watch(pronunciationStatsProvider(langCode));

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
          'Pronunciation Practice',
          style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            statsAsync.when(
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return _buildStatsCard(stats);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Practice Section
            _buildPracticeSection(),
            Spacing.gapXL,

            // Results Section
            if (_result != null) ...[
              _buildResultsSection(),
              Spacing.gapXL,
            ],

            // Error
            if (_error != null) ...[
              _buildErrorSection(),
              Spacing.gapXL,
            ],

            // History Section
            Text(
              'Practice History',
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
                child: CircularProgressIndicator(color: AppColors.warning),
              ),
              error: (_, __) => _buildEmptyHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(PronunciationStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderLG,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${stats.totalAttempts}',
            'Practices',
            Icons.mic_rounded,
          ),
          _buildStatItem(
            '${stats.averageScore.toStringAsFixed(0)}%',
            'Avg Score',
            Icons.trending_up_rounded,
          ),
          _buildStatItem(
            '${stats.perfectScores}',
            'Perfect',
            Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        Spacing.gapXS,
        Text(
          value,
          style: context.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: context.caption?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeSection() {
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
          Spacing.gapMD,

          // Text to Practice
          Text(
            'Text to Practice',
            style: context.labelLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          Spacing.gapSM,
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter text to practice...',
              hintStyle: TextStyle(color: context.textMuted),
              filled: true,
              fillColor: context.containerColor,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide(color: context.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide(color: context.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: const BorderSide(color: AppColors.warning),
              ),
            ),
          ),
          Spacing.gapMD,

          // Sample Texts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sampleTexts.take(3).map((text) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _textController.text = text;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: AppRadius.borderLG,
                  ),
                  child: Text(
                    text.length > 25 ? '${text.substring(0, 25)}...' : text,
                    style: context.caption?.copyWith(color: context.textSecondary),
                  ),
                ),
              );
            }).toList(),
          ),
          Spacing.gapLG,

          // Listen Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoadingTTS ? null : _playTTS,
                  icon: _isLoadingTTS
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.volume_up_rounded),
                  label: const Text('Listen First'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Spacing.gapMD,

          // Record Button
          Center(
            child: GestureDetector(
              onTap: _isAnalyzing
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? AppColors.error
                      : _isAnalyzing
                          ? AppColors.gray300
                          : AppColors.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording
                              ? AppColors.error
                              : AppColors.warning)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isAnalyzing
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
              ),
            ),
          ),
          Spacing.gapMD,
          Center(
            child: Text(
              _isRecording
                  ? 'Tap to stop'
                  : _isAnalyzing
                      ? 'Analyzing...'
                      : 'Tap to record',
              style: context.bodyMedium?.copyWith(color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
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
          // Overall Score
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _getScoreColor(_result!.overallScore).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_result!.overallScore}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(_result!.overallScore),
                          ),
                        ),
                        Text(
                          _result!.scoreGrade,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getScoreColor(_result!.overallScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _result!.isExcellent
                      ? 'Excellent pronunciation!'
                      : _result!.isGood
                          ? 'Good job!'
                          : 'Keep practicing!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Score Breakdown
          Row(
            children: [
              Expanded(
                child: _buildScoreItem(
                  'Accuracy',
                  _result!.accuracyScore,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreItem(
                  'Fluency',
                  _result!.fluencyScore,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreItem(
                  'Complete',
                  _result!.completenessScore,
                ),
              ),
            ],
          ),

          // Word-by-word feedback
          if (_result!.words.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Word Analysis',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _result!.words.map((w) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: w.isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: w.isCorrect
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        w.word,
                        style: TextStyle(
                          color: w.isCorrect ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${w.score}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: w.isCorrect ? Colors.green[600] : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Feedback
          if (_result!.feedback.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _result!.feedback,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Suggestions
          if (_result!.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._result!.suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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
              style: context.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(PronunciationResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderMD,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getScoreColor(result.overallScore).withOpacity(0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Center(
              child: Text(
                '${result.overallScore}',
                style: context.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(result.overallScore),
                ),
              ),
            ),
          ),
          Spacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.targetText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  result.scoreGrade,
                  style: context.caption?.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: Spacing.paddingXL,
      child: Column(
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 48,
            color: context.textMuted,
          ),
          Spacing.gapMD,
          Text(
            'No practice history yet',
            style: context.bodyMedium?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
