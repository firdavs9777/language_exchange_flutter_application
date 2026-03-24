import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/ai/lesson_builder_model.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/pages/learning/lessons/lesson_player_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// AI Lesson Builder Screen
/// Generate custom lessons using AI
class LessonBuilderScreen extends ConsumerStatefulWidget {
  const LessonBuilderScreen({super.key});

  @override
  ConsumerState<LessonBuilderScreen> createState() => _LessonBuilderScreenState();
}

class _LessonBuilderScreenState extends ConsumerState<LessonBuilderScreen> {
  final _topicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedLanguage = 'en';
  String _selectedLevel = 'A1';
  String _selectedCategory = 'vocabulary';
  int _exerciseCount = 10;
  bool _isGenerating = false;
  GeneratedLessonResponse? _generatedLesson;
  String? _error;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'nl', 'name': 'Dutch'},
    {'code': 'pl', 'name': 'Polish'},
    {'code': 'uz', 'name': 'Uzbek'},
  ];

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  final List<Map<String, dynamic>> _categories = [
    {'value': 'vocabulary', 'label': 'Vocabulary', 'icon': Icons.abc},
    {'value': 'grammar', 'label': 'Grammar', 'icon': Icons.spellcheck},
    {'value': 'conversation', 'label': 'Conversation', 'icon': Icons.chat},
    {'value': 'reading', 'label': 'Reading', 'icon': Icons.menu_book},
    {'value': 'listening', 'label': 'Listening', 'icon': Icons.hearing},
    {'value': 'writing', 'label': 'Writing', 'icon': Icons.edit},
  ];

  final List<String> _suggestedTopics = [
    'Greetings and Introductions',
    'At the Restaurant',
    'Travel and Tourism',
    'Shopping',
    'Weather and Seasons',
    'Family and Relationships',
    'Work and Office',
    'Daily Routine',
    'Hobbies and Interests',
    'Health and Body',
    'Food and Cooking',
    'Technology',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedLesson = null;
    });

    final request = GenerateLessonRequest(
      language: _selectedLanguage,
      topic: _topicController.text.trim(),
      level: _selectedLevel,
      category: _selectedCategory,
      exerciseCount: _exerciseCount,
    );

    final result = await AIService.generateLesson(request);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        if (result['success'] == true && result['data'] != null) {
          _generatedLesson = result['data'] as GeneratedLessonResponse;
        } else {
          _error = result['message'] ?? 'Failed to generate lesson';
        }
      });
    }
  }

  void _openLesson() async {
    if (_generatedLesson == null) return;

    final lessonId = _generatedLesson!.lesson.id;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
    );

    // Try to start the lesson first (this might return full lesson with exercises)
    final startResult = await LearningService.startLesson(lessonId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    Lesson? fullLesson;

    // If start returned lesson data, use it
    if (startResult['success'] == true && startResult['data'] != null) {
      try {
        final data = startResult['data'];
        if (data is Map<String, dynamic>) {
          // Check if it's a full lesson with exercises
          if (data['exercises'] != null || data['content'] != null) {
            fullLesson = Lesson.fromJson(data);
          }
        }
      } catch (e) {
      }
    }

    // Navigate to player
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonPlayerScreen(
            lessonId: lessonId,
            initialLesson: fullLesson,
          ),
        ),
      );
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
          'AI Lesson Builder',
          style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacing.paddingLG,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Configuration Section
              _buildSectionTitle('Lesson Configuration'),
              const SizedBox(height: 12),
              _buildConfigurationCard(),
              const SizedBox(height: 24),

              // Topic Section
              _buildSectionTitle('Topic'),
              const SizedBox(height: 12),
              _buildTopicInput(),
              const SizedBox(height: 12),
              _buildSuggestedTopics(),
              const SizedBox(height: 24),

              // Generate Button
              _buildGenerateButton(),
              const SizedBox(height: 24),

              // Result Section
              if (_isGenerating) _buildLoadingState(),
              if (_error != null) _buildErrorState(),
              if (_generatedLesson != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Custom Lessons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'AI creates personalized lessons on any topic',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: context.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildConfigurationCard() {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          // Language Selection
          _buildDropdownRow(
            icon: Icons.language,
            label: 'Language',
            value: _selectedLanguage,
            items: _languages.map((lang) => DropdownMenuItem(
              value: lang['code'],
              child: Text(lang['name']!),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedLanguage = value);
            },
          ),
          const Divider(height: 24),

          // Level Selection
          _buildDropdownRow(
            icon: Icons.signal_cellular_alt,
            label: 'Level',
            value: _selectedLevel,
            items: _levels.map((level) => DropdownMenuItem(
              value: level,
              child: Text(_getLevelDescription(level)),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedLevel = value);
            },
          ),
          const Divider(height: 24),

          // Category Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Category',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['value'];
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat['value']),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const Divider(height: 24),

          // Exercise Count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.format_list_numbered, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Exercises: $_exerciseCount',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _exerciseCount.toDouble(),
                min: 5,
                max: 20,
                divisions: 15,
                activeColor: const Color(0xFF8B5CF6),
                onChanged: (value) {
                  setState(() => _exerciseCount = value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('20', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: const SizedBox(),
          style: const TextStyle(
            color: Color(0xFF8B5CF6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicInput() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: TextFormField(
        controller: _topicController,
        decoration: InputDecoration(
          hintText: 'Enter a topic (e.g., "Food and Dining")',
          hintStyle: TextStyle(color: context.textMuted),
          prefixIcon: Icon(Icons.topic, color: context.textMuted),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderLG,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: context.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a topic';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSuggestedTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Topics',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedTopics.map((topic) {
            return InkWell(
              onTap: () {
                setState(() {
                  _topicController.text = topic;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateLesson,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isGenerating ? Icons.hourglass_empty : Icons.auto_awesome,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isGenerating ? 'Generating...' : 'Generate Lesson',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: Spacing.paddingXL,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
          Spacing.gapMD,
          Text(
            'Creating your lesson...',
            style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Spacing.gapSM,
          Text(
            'AI is generating exercises and content',
            style: context.bodySmall?.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: _generateLesson,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final lesson = _generatedLesson!.lesson;
    final stats = _generatedLesson!.generation;

    return Container(
      padding: Spacing.paddingXL,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                const SizedBox(width: 6),
                Text(
                  'Lesson Generated!',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lesson Info
          Text(
            lesson.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.description,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _buildStatChip(Icons.quiz, '${lesson.exerciseCount} exercises'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.timer, '${lesson.estimatedMinutes} min'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.star, '${lesson.xpReward} XP'),
            ],
          ),
          const SizedBox(height: 16),

          // Generation Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGenStat('Tokens', '${stats.tokensUsed}'),
                _buildGenStat('Cost', stats.estimatedCost),
                _buildGenStat('Time', '${(stats.timeMs / 1000).toStringAsFixed(1)}s'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _generatedLesson = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Generate Another',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _openLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Lesson',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Back to Lessons button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // Show confirmation and pop back to lessons screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Lesson "${lesson.title}" saved!'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Lessons'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'A1':
        return 'A1 - Beginner';
      case 'A2':
        return 'A2 - Elementary';
      case 'B1':
        return 'B1 - Intermediate';
      case 'B2':
        return 'B2 - Upper Intermediate';
      case 'C1':
        return 'C1 - Advanced';
      case 'C2':
        return 'C2 - Proficient';
      default:
        return level;
    }
  }
}
