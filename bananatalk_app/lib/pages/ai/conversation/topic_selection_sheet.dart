import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/models/ai/ai_conversation_model.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Bottom sheet for selecting conversation topic
class TopicSelectionSheet extends ConsumerStatefulWidget {
  const TopicSelectionSheet({super.key});

  @override
  ConsumerState<TopicSelectionSheet> createState() => _TopicSelectionSheetState();
}

class _TopicSelectionSheetState extends ConsumerState<TopicSelectionSheet> {
  String _selectedLevel = 'intermediate';
  String? _selectedTopicId;
  String? _selectedScenarioId;
  int _tabIndex = 0;

  // Language selection
  Language? _targetLanguage;
  Language? _nativeLanguage;
  List<Language> _languages = [];
  bool _isLoadingLanguages = true;

  final List<Map<String, String>> _levels = [
    {'id': 'beginner', 'name': 'Beginner', 'description': 'Simple vocabulary'},
    {'id': 'intermediate', 'name': 'Intermediate', 'description': 'Everyday topics'},
    {'id': 'advanced', 'name': 'Advanced', 'description': 'Complex discussions'},
  ];

  // Map level to CEFR
  String _getCefrLevel(String level) {
    switch (level) {
      case 'beginner':
        return 'A1';
      case 'intermediate':
        return 'B1';
      case 'advanced':
        return 'C1';
      default:
        return 'B1';
    }
  }

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

          // Set defaults
          if (_languages.isNotEmpty) {
            // Default target language: Spanish
            _targetLanguage = _languages.firstWhere(
              (l) => l.code == 'es',
              orElse: () => _languages.first,
            );
            // Default native language: English
            _nativeLanguage = _languages.firstWhere(
              (l) => l.code == 'en',
              orElse: () => _languages.first,
            );
          }
        });
      } else {
        setState(() => _isLoadingLanguages = false);
      }
    } catch (e) {
      setState(() => _isLoadingLanguages = false);
    }
  }

  Future<void> _openLanguagePicker({required bool isTarget}) async {
    if (_languages.isEmpty) return;

    final result = await Navigator.push<Language>(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePickerScreen(
          languages: _languages,
          selectedLanguage: isTarget ? _targetLanguage : _nativeLanguage,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isTarget) {
          _targetLanguage = result;
        } else {
          _nativeLanguage = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(conversationTopicsProvider(_selectedLevel));
    final scenariosAsync = ref.watch(practiceScenariosProvider(_selectedLevel));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: AppRadius.borderXS,
                ),
              ),
              Spacing.gapMD,

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Start Conversation',
                  style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Spacing.gapLG,

              // Language Selection
              _buildLanguageSelection(),
              Spacing.gapLG,

              // Level Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Difficulty Level',
                      style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Spacing.gapSM,
                    Row(
                      children: _levels.map((level) {
                        final isSelected = _selectedLevel == level['id'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLevel = level['id']!;
                                _selectedTopicId = null;
                                _selectedScenarioId = null;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                right: level['id'] != 'advanced' ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent
                                    : context.containerColor,
                                borderRadius: AppRadius.borderSM,
                              ),
                              child: Text(
                                level['name']!,
                                textAlign: TextAlign.center,
                                style: context.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Spacing.gapMD,

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: AppRadius.borderSM,
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? context.cardBackground
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSM,
                            boxShadow: _tabIndex == 0 ? AppShadows.sm : null,
                          ),
                          child: Text(
                            'Topics',
                            textAlign: TextAlign.center,
                            style: context.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _tabIndex == 0
                                  ? AppColors.accent
                                  : context.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1
                                ? context.cardBackground
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSM,
                            boxShadow: _tabIndex == 1 ? AppShadows.sm : null,
                          ),
                          child: Text(
                            'Scenarios',
                            textAlign: TextAlign.center,
                            style: context.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _tabIndex == 1
                                  ? AppColors.accent
                                  : context.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.gapMD,

              // Content
              Expanded(
                child: _tabIndex == 0
                    ? _buildTopicsList(topicsAsync, scrollController)
                    : _buildScenariosList(scenariosAsync, scrollController),
              ),

              // Start Button
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  boxShadow: AppShadows.sm,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canStart()
                        ? () {
                            final request = StartConversationRequest(
                              targetLanguage: _targetLanguage?.code ?? 'es',
                              cefrLevel: _getCefrLevel(_selectedLevel),
                              nativeLanguage: _nativeLanguage?.code,
                              topicId: _selectedTopicId,
                              scenarioId: _selectedScenarioId,
                              level: _selectedLevel,
                            );
                            Navigator.pop(context, request);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.gray300,
                      padding: Spacing.paddingLG,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                    ),
                    child: Text(
                      _targetLanguage != null
                          ? 'Start in ${_targetLanguage!.name}'
                          : 'Start Conversation',
                      style: context.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canStart() {
    return _targetLanguage != null &&
        (_selectedTopicId != null || _selectedScenarioId != null);
  }

  Widget _buildLanguageSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages',
            style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Spacing.gapSM,
          Row(
            children: [
              // Native Language
              Expanded(
                child: _buildLanguageButton(
                  label: 'I speak',
                  language: _nativeLanguage,
                  onTap: () => _openLanguagePicker(isTarget: false),
                ),
              ),
              Spacing.hGapMD,
              // Arrow
              Icon(Icons.arrow_forward_rounded, color: context.textMuted),
              Spacing.hGapMD,
              // Target Language
              Expanded(
                child: _buildLanguageButton(
                  label: 'Practice',
                  language: _targetLanguage,
                  onTap: () => _openLanguagePicker(isTarget: true),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({
    required String label,
    required Language? language,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    if (_isLoadingLanguages) {
      return Container(
        padding: Spacing.paddingMD,
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMD,
      child: Container(
        padding: Spacing.paddingMD,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.accent.withOpacity(0.1)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: isPrimary
              ? Border.all(color: AppColors.accent.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.captionSmall?.copyWith(color: context.textSecondary),
            ),
            Spacing.gapXS,
            Row(
              children: [
                Text(
                  language?.flag ?? '🌐',
                  style: const TextStyle(fontSize: 20),
                ),
                Spacing.hGapSM,
                Expanded(
                  child: Text(
                    language?.name ?? 'Select',
                    style: context.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: language != null ? context.textPrimary : context.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: context.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsList(
    AsyncValue<List<ConversationTopic>> topicsAsync,
    ScrollController scrollController,
  ) {
    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty) {
          return _buildEmptyState('No topics available');
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            final isSelected = _selectedTopicId == topic.id;
            return _buildTopicCard(topic, isSelected);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => _buildEmptyState('Failed to load topics'),
    );
  }

  Widget _buildTopicCard(ConversationTopic topic, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTopicId = topic.id;
          _selectedScenarioId = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.1)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              _getTopicIcon(topic.icon),
              style: const TextStyle(fontSize: 28),
            ),
            Spacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (topic.description != null)
                    Text(
                      topic.description!,
                      style: context.bodySmall?.copyWith(color: context.textSecondary),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }

  String _getTopicIcon(String iconName) {
    // Map icon names to emojis
    final iconMap = {
      'globe': '🌍',
      'travel': '✈️',
      'food': '🍕',
      'business': '💼',
      'sports': '⚽',
      'music': '🎵',
      'movie': '🎬',
      'book': '📚',
      'health': '💪',
      'technology': '💻',
      'art': '🎨',
      'nature': '🌿',
      'shopping': '🛍️',
      'home': '🏠',
      'education': '🎓',
      'weather': '🌤️',
      'family': '👨‍👩‍👧‍👦',
      'work': '💼',
      'hobby': '🎯',
      'daily': '☀️',
    };
    return iconMap[iconName.toLowerCase()] ?? '💬';
  }

  Widget _buildScenariosList(
    AsyncValue<List<PracticeScenario>> scenariosAsync,
    ScrollController scrollController,
  ) {
    return scenariosAsync.when(
      data: (scenarios) {
        if (scenarios.isEmpty) {
          return _buildEmptyState('No scenarios available');
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: scenarios.length,
          itemBuilder: (context, index) {
            final scenario = scenarios[index];
            final isSelected = _selectedScenarioId == scenario.id;
            return _buildScenarioCard(scenario, isSelected);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => _buildEmptyState('Failed to load scenarios'),
    );
  }

  Widget _buildScenarioCard(PracticeScenario scenario, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScenarioId = scenario.id;
          _selectedTopicId = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.1)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getTopicIcon(scenario.icon),
                  style: const TextStyle(fontSize: 28),
                ),
                Spacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (scenario.setting.isNotEmpty)
                        Text(
                          scenario.setting,
                          style: context.caption?.copyWith(color: context.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                  ),
              ],
            ),
            if (scenario.description.isNotEmpty) ...[
              Spacing.gapMD,
              Text(
                scenario.description,
                style: context.bodySmall?.copyWith(
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (scenario.objectives.isNotEmpty) ...[
              Spacing.gapMD,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: scenario.objectives.take(3).map((obj) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: AppRadius.borderMD,
                    ),
                    child: Text(
                      obj,
                      style: context.captionSmall?.copyWith(color: AppColors.success),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: context.textMuted,
          ),
          Spacing.gapMD,
          Text(
            message,
            style: context.bodyMedium?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }
}
