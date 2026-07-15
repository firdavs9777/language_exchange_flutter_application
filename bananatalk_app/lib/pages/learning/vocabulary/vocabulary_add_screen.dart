import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/languages_provider.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_snackbar.dart';

/// Add vocabulary screen
class VocabularyAddScreen extends ConsumerStatefulWidget {
  const VocabularyAddScreen({super.key});

  @override
  ConsumerState<VocabularyAddScreen> createState() => _VocabularyAddScreenState();
}

class _VocabularyAddScreenState extends ConsumerState<VocabularyAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _translationController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _exampleController = TextEditingController();
  final _exampleTranslationController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedLanguage = 'en';
  String? _selectedPartOfSpeech;
  List<String> _tags = [];
  bool _isLoading = false;
  bool _aiFilling = false;

  // Word languages come from the shared catalog (taggableLanguagesProvider:
  // full 110+ base-639-1 list, fallback while loading) — see the language
  // dropdown in build().

  final List<String> _partsOfSpeech = [
    'noun', 'verb', 'adjective', 'adverb', 'pronoun',
    'preposition', 'conjunction', 'interjection', 'phrase'
  ];

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    _exampleTranslationController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await LearningService.addVocabulary(
        word: _wordController.text.trim(),
        translation: _translationController.text.trim(),
        language: _selectedLanguage,
        pronunciation: _pronunciationController.text.trim().isEmpty
            ? null
            : _pronunciationController.text.trim(),
        partOfSpeech: _selectedPartOfSpeech,
        exampleSentence: _exampleController.text.trim().isEmpty
            ? null
            : _exampleController.text.trim(),
        exampleTranslation: _exampleTranslationController.text.trim().isEmpty
            ? null
            : _exampleTranslationController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          showLearningSnackBar(context, 'Word added successfully!');
          Navigator.pop(context);
        } else {
          showLearningSnackBar(context, result['error'] ?? 'Failed to add word');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAiFill() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      showLearningSnackBar(context, 'Enter a word first');
      return;
    }
    setState(() => _aiFilling = true);
    try {
      final data = await LearningService.aiDefineVocabulary(
        word: word,
        language: _selectedLanguage,
      );
      if (!mounted) return;
      setState(() {
        final translation = data['translation'] as String? ?? '';
        if (translation.isNotEmpty) {
          _translationController.text = translation;
        }
        final pronunciation = data['pronunciation'] as String? ?? '';
        if (pronunciation.isNotEmpty) {
          _pronunciationController.text = pronunciation;
        }
        final examples = (data['examples'] as List?) ?? [];
        if (examples.isNotEmpty) {
          _exampleController.text = examples.first.toString();
        }
        final pos = data['partOfSpeech'] as String? ?? '';
        if (pos.isNotEmpty && _partsOfSpeech.contains(pos)) {
          _selectedPartOfSpeech = pos;
        }
        final notes = <String>[];
        final registerNotes = data['registerNotes'] as String? ?? '';
        if (registerNotes.isNotEmpty) notes.add(registerNotes);
        final definition = data['definition'] as String? ?? '';
        if (definition.isNotEmpty) notes.add('Def: $definition');
        final collocations = (data['collocations'] as List?) ?? [];
        if (collocations.isNotEmpty) {
          notes.add('Collocations: ${collocations.join(', ')}');
        }
        if (notes.isNotEmpty) {
          _notesController.text = notes.join('\n');
        }
      });
      if (mounted) showLearningSnackBar(context, 'AI filled in!');
    } catch (e) {
      if (!mounted) return;
      showLearningSnackBar(context, 'AI fill failed. Please try again.');
    } finally {
      if (mounted) setState(() => _aiFilling = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
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
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Word',
          style: context.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: Spacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Selector
              _buildSectionTitle('Language'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.borderMD,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: ref
                        .watch(taggableLanguagesProvider)
                        .map((lang) {
                      return DropdownMenuItem(
                        value: lang['code'],
                        child: Text('${lang['flag']} ${lang['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLanguage = value);
                    },
                  ),
                ),
              ),
              Spacing.gapXL,

              // Word
              _buildSectionTitle('Word *'),
              _buildTextField(
                controller: _wordController,
                hint: 'Enter the word',
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              Spacing.gapSM,

              // AI Auto-fill button
              FilledButton.icon(
                onPressed: _aiFilling ? null : _onAiFill,
                icon: _aiFilling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('AI Auto-fill'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              Spacing.gapLG,

              // Translation
              _buildSectionTitle('Translation *'),
              _buildTextField(
                controller: _translationController,
                hint: 'Enter the translation',
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              Spacing.gapLG,

              // Pronunciation
              _buildSectionTitle('Pronunciation'),
              _buildTextField(
                controller: _pronunciationController,
                hint: 'e.g., OH-lah',
              ),
              Spacing.gapLG,

              // Part of Speech
              _buildSectionTitle('Part of Speech'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.borderMD,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedPartOfSpeech,
                    isExpanded: true,
                    hint: const Text('Select...'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._partsOfSpeech.map((pos) {
                        return DropdownMenuItem(
                          value: pos,
                          child: Text(pos[0].toUpperCase() + pos.substring(1)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPartOfSpeech = value);
                    },
                  ),
                ),
              ),
              Spacing.gapLG,

              // Example Sentence
              _buildSectionTitle('Example Sentence'),
              _buildTextField(
                controller: _exampleController,
                hint: 'Enter an example sentence',
                maxLines: 2,
              ),
              Spacing.gapLG,

              // Example Translation
              _buildSectionTitle('Example Translation'),
              _buildTextField(
                controller: _exampleTranslationController,
                hint: 'Translation of the example',
                maxLines: 2,
              ),
              Spacing.gapLG,

              // Tags
              _buildSectionTitle('Tags (max 5)'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _tagController,
                      hint: 'Add a tag',
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  Spacing.hGapSM,
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle),
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                Spacing.gapSM,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    );
                  }).toList(),
                ),
              ],
              Spacing.gapLG,

              // Notes
              _buildSectionTitle('Notes'),
              _buildTextField(
                controller: _notesController,
                hint: 'Add personal notes',
                maxLines: 3,
              ),
              Spacing.gapXXL,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: context.labelLarge,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return Builder(
      builder: (context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: context.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderMD,
            borderSide: BorderSide.none,
          ),
          contentPadding: Spacing.paddingLG,
        ),
      ),
    );
  }
}
