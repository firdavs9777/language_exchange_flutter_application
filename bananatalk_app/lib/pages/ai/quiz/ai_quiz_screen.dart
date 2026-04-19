import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/pages/ai/quiz/quiz_player_screen.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// AI Quiz Hub Screen
class AIQuizScreen extends ConsumerStatefulWidget {
  const AIQuizScreen({super.key});

  @override
  ConsumerState<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends ConsumerState<AIQuizScreen> {
  String _selectedType = 'mixed';
  String _selectedDifficulty = 'adaptive';
  int _questionCount = 10;
  bool _isGenerating = false;

  // Language selection
  Language? _selectedLanguage;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    try {
      final url = '${Endpoints.baseURL}${Endpoints.languagesURL}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> languageList = data['data'] ?? [];
        setState(() {
          _languages = languageList
              .map((json) => Language.fromJson(json))
              .toList();
          _isLoadingLanguages = false;
          // Set default to English if available
          final englishIndex = _languages.indexWhere(
            (l) => l.code.toLowerCase() == 'en' || l.name.toLowerCase() == 'english'
          );
          if (englishIndex != -1) {
            _selectedLanguage = _languages[englishIndex];
          } else if (_languages.isNotEmpty) {
            _selectedLanguage = _languages.first;
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLanguages = false;
      });
    }
  }

  void _openLanguagePicker() async {
    final selectedLanguage = await Navigator.push<Language>(
      context,
      AppPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );

    if (selectedLanguage != null && mounted) {
      setState(() {
        _selectedLanguage = selectedLanguage;
      });
    }
  }

  final List<Map<String, dynamic>> _quizTypes = [
    {
      'id': 'weak_areas',
      'name': 'Weak Areas',
      'icon': Icons.gps_fixed_rounded,
      'color': Colors.red,
      'description': 'Focus on topics you struggle with',
    },
    {
      'id': 'vocabulary',
      'name': 'Vocabulary',
      'icon': Icons.book_rounded,
      'color': Colors.purple,
      'description': 'Test your word knowledge',
    },
    {
      'id': 'recent_content',
      'name': 'Recent Content',
      'icon': Icons.history_rounded,
      'color': Colors.blue,
      'description': 'Review what you learned recently',
    },
    {
      'id': 'mixed',
      'name': 'Mixed Practice',
      'icon': Icons.shuffle_rounded,
      'color': Colors.teal,
      'description': 'A mix of different topics',
    },
  ];

  final List<Map<String, String>> _difficulties = [
    {'id': 'easy', 'name': 'Easy'},
    {'id': 'medium', 'name': 'Medium'},
    {'id': 'hard', 'name': 'Hard'},
    {'id': 'adaptive', 'name': 'Adaptive'},
  ];

  Future<void> _generateQuiz() async {
    setState(() {
      _isGenerating = true;
    });

    final request = GenerateQuizRequest(
      type: _selectedType,
      questionCount: _questionCount,
      difficulty: _selectedDifficulty,
      language: _selectedLanguage?.code,
    );

    final success = await ref.read(aiQuizProvider.notifier).generateQuiz(request);

    setState(() {
      _isGenerating = false;
    });

    if (success && mounted) {
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => const QuizPlayerScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate quiz')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(aiQuizzesProvider);
    final statsAsync = ref.watch(aiQuizStatsProvider);

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
          'AI Quizzes',
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

            // Generate New Quiz Section
            Text(
              'Generate New Quiz',
              style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Spacing.gapMD,
            _buildGenerateSection(),
            Spacing.gapXL,

            // Previous Quizzes
            Text(
              'Previous Quizzes',
              style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Spacing.gapMD,
            quizzesAsync.when(
              data: (quizzes) {
                if (quizzes.isEmpty) {
                  return _buildEmptyQuizzes();
                }
                return Column(
                  children: quizzes
                      .take(5)
                      .map((q) => _buildQuizCard(q))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.error),
              ),
              error: (_, __) => _buildEmptyQuizzes(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(AIQuizStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: Spacing.paddingXL,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderLG,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('${stats.completedQuizzes}', 'Completed'),
              _buildStatColumn('${stats.averageScore.toStringAsFixed(0)}%', 'Avg Score'),
              _buildStatColumn('${stats.totalXpEarned}', 'XP Earned'),
            ],
          ),
          if (stats.weakAreas.isNotEmpty) ...[
            Spacing.gapMD,
            Container(
              padding: Spacing.paddingMD,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  Spacing.hGapSM,
                  Expanded(
                    child: Text(
                      'Focus area: ${stats.weakAreas.first.name}',
                      style: context.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: context.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacing.gapXS,
        Text(
          label,
          style: context.caption?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateSection() {
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
          // Quiz Type Selection
          Text(
            'Quiz Type',
            style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Spacing.gapMD,
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: _quizTypes.map((type) {
              final isSelected = _selectedType == type['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type['id'];
                  });
                },
                child: Container(
                  padding: Spacing.paddingSM,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (type['color'] as Color).withOpacity(0.1)
                        : context.containerColor,
                    borderRadius: AppRadius.borderSM,
                    border: Border.all(
                      color: isSelected
                          ? type['color'] as Color
                          : context.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 20,
                        color: type['color'] as Color,
                      ),
                      Spacing.hGapSM,
                      Expanded(
                        child: Text(
                          type['name'],
                          style: context.bodySmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? type['color'] as Color
                                : context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          Spacing.gapLG,

          // Language Selection
          Text(
            'Language',
            style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Spacing.gapSM,
          _buildLanguageSelector(),
          Spacing.gapLG,

          // Difficulty Selection
          Text(
            'Difficulty',
            style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Spacing.gapSM,
          Row(
            children: _difficulties.map((diff) {
              final isSelected = _selectedDifficulty == diff['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = diff['id']!;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: diff['id'] != 'adaptive' ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.error
                          : context.containerColor,
                      borderRadius: AppRadius.borderSM,
                    ),
                    child: Text(
                      diff['name']!,
                      textAlign: TextAlign.center,
                      style: context.caption?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Spacing.gapLG,

          // Question Count
          Row(
            children: [
              Text(
                'Questions:',
                style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Spacing.hGapMD,
              Text(
                '$_questionCount',
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _questionCount.toDouble(),
                  min: 5,
                  max: 20,
                  divisions: 3,
                  activeColor: AppColors.error,
                  onChanged: (value) {
                    setState(() {
                      _questionCount = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
          Spacing.gapMD,

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Generate Quiz',
                      style: context.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.textMuted,
              ),
            ),
            Spacing.hGapMD,
            Text(
              'Loading languages...',
              style: context.bodyMedium?.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _openLanguagePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            if (_selectedLanguage != null) ...[
              Text(
                _selectedLanguage!.flag,
                style: const TextStyle(fontSize: 24),
              ),
              Spacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedLanguage!.name,
                      style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_selectedLanguage!.nativeName.isNotEmpty &&
                        _selectedLanguage!.nativeName != _selectedLanguage!.name)
                      Text(
                        _selectedLanguage!.nativeName,
                        style: context.caption?.copyWith(color: context.textSecondary),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Icon(Icons.language, color: context.textMuted),
              Spacing.hGapMD,
              Expanded(
                child: Text(
                  'Select a language',
                  style: context.bodyMedium?.copyWith(color: context.textMuted),
                ),
              ),
            ],
            Icon(Icons.chevron_right, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(AIQuiz quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderMD,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (quiz.isCompleted && quiz.result != null) {
              _showQuizResult(quiz);
            } else {
              _startQuiz(quiz);
            }
          },
          borderRadius: AppRadius.borderMD,
          child: Padding(
            padding: Spacing.paddingLG,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(quiz.type).withOpacity(0.1),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Center(
                    child: Text(
                      quiz.typeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Spacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Text(
                            '${quiz.questionCount} questions',
                            style: context.caption?.copyWith(color: context.textSecondary),
                          ),
                          Spacing.hGapSM,
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Spacing.hGapSM,
                          Text(
                            quiz.difficulty,
                            style: context.caption?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (quiz.isCompleted && quiz.result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(quiz.result!.percentage.toInt())
                          .withOpacity(0.1),
                      borderRadius: AppRadius.borderSM,
                    ),
                    child: Text(
                      '${quiz.result!.percentage.toInt()}%',
                      style: context.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(quiz.result!.percentage.toInt()),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.play_arrow_rounded,
                    color: context.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz(AIQuiz quiz) async {
    final success = await ref.read(aiQuizProvider.notifier).startQuiz(quiz.id);
    if (success && mounted) {
      final state = ref.read(aiQuizProvider);
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => const QuizPlayerScreen(),
        ),
      );
    }
  }

  void _showQuizResult(AIQuiz quiz) {
    final result = quiz.result!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getScoreColor(result.percentage.toInt())
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            result.grade,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getScoreColor(result.percentage.toInt()),
                            ),
                          ),
                          Text(
                            '${result.percentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  _getScoreColor(result.percentage.toInt()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.correctCount}/${result.totalQuestions} correct',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildResultStat(
                        Icons.star_rounded,
                        '+${result.xpEarned}',
                        'XP Earned',
                        Colors.amber,
                      ),
                      _buildResultStat(
                        Icons.timer_rounded,
                        '${(result.timeSpent / 60).floor()}m',
                        'Time',
                        Colors.blue,
                      ),
                      _buildResultStat(
                        Icons.trending_up_rounded,
                        '${result.accuracyRate.toInt()}%',
                        'Accuracy',
                        Colors.green,
                      ),
                    ],
                  ),
                  if (result.feedback.isNotEmpty) ...[
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
                              result.feedback,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
    );
  }

  Widget _buildEmptyQuizzes() {
    return Container(
      padding: Spacing.paddingXL,
      child: Column(
        children: [
          Icon(
            Icons.quiz_rounded,
            size: 48,
            color: context.textMuted,
          ),
          Spacing.gapMD,
          Text(
            'No quizzes yet',
            style: context.bodyMedium?.copyWith(color: context.textMuted),
          ),
          Spacing.gapXS,
          Text(
            'Generate your first quiz above!',
            style: context.caption?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'weak_areas':
        return Colors.red;
      case 'vocabulary':
        return Colors.purple;
      case 'recent_content':
        return Colors.blue;
      case 'mixed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
