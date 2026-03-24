import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/ai/translation_model.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/pages/vip/vip_status_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HelloTalk-style translation bottom sheet with word breakdown, TTS, and vocabulary saving.
class TranslationBottomSheet extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String? initialTargetLanguage;

  const TranslationBottomSheet({
    super.key,
    required this.messageId,
    required this.originalText,
    this.initialTargetLanguage,
  });

  @override
  State<TranslationBottomSheet> createState() => _TranslationBottomSheetState();
}

class _TranslationBottomSheetState extends State<TranslationBottomSheet> {
  bool _isLoading = true;
  String? _error;
  String _targetLanguage = 'en';

  // Translation data
  String _translatedText = '';
  String? _transliteration;
  List<WordBreakdown> _breakdown = [];
  List<TranslationAlternative> _alternatives = [];
  List<GrammarNote> _grammarNotes = [];
  String? _culturalNote;
  bool _cached = false;
  bool _isLimitReached = false;

  // TTS
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isTtsLoading = false;
  bool _isTtsPlaying = false;

  @override
  void initState() {
    super.initState();
    _initLanguage();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isTtsPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initLanguage() async {
    if (widget.initialTargetLanguage != null) {
      _targetLanguage = widget.initialTargetLanguage!;
    } else {
      _targetLanguage = await TranslationService.getAutoTranslateLanguage();
    }
    _translate();
  }

  Future<void> _translate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await TranslationService.translateMessage(
      messageId: widget.messageId,
      targetLanguage: _targetLanguage,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;

      // Parse breakdown
      List<WordBreakdown> breakdown = [];
      final breakdownData = data['breakdown'];
      if (breakdownData is List) {
        breakdown = breakdownData
            .where((e) => e is Map)
            .map((e) => WordBreakdown.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // Parse alternatives
      List<TranslationAlternative> alternatives = [];
      final altData = data['alternatives'];
      if (altData is List) {
        alternatives = altData
            .where((e) => e is Map)
            .map((e) => TranslationAlternative.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // Parse grammar notes
      List<GrammarNote> grammar = [];
      final grammarData = data['grammar'] ?? data['grammarNotes'];
      if (grammarData is List) {
        grammar = grammarData
            .where((e) => e is Map)
            .map((e) => GrammarNote.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // Parse cultural note
      String? cultural;
      final culturalData = data['cultural'];
      if (culturalData is Map) {
        cultural = culturalData['notes']?.toString();
      } else if (culturalData is String) {
        cultural = culturalData;
      }

      setState(() {
        _translatedText = data['translatedText']?.toString() ?? data['translation']?.toString() ?? '';
        _transliteration = data['transliteration']?.toString();
        _breakdown = breakdown;
        _alternatives = alternatives;
        _grammarNotes = grammar;
        _culturalNote = cultural;
        _cached = result['cached'] == true;
        _isLoading = false;
      });
    } else {
      final errorCode = result['error']?.toString() ?? '';
      setState(() {
        _isLimitReached = errorCode == 'TRANSLATION_LIMIT_REACHED';
        _error = _isLimitReached
            ? null
            : (result['message']?.toString() ?? result['error']?.toString() ?? 'Translation failed');
        _isLoading = false;
      });
    }
  }

  Future<void> _playTTS() async {
    if (_isTtsLoading) return;

    // If already playing, stop
    if (_isTtsPlaying) {
      await _audioPlayer.stop();
      return;
    }

    setState(() => _isTtsLoading = true);

    final result = await TranslationService.getMessageTTS(
      messageId: widget.messageId,
      language: _targetLanguage,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final audioUrl = data?['audioUrl']?.toString();

      if (audioUrl != null) {
        try {
          await _audioPlayer.setUrl(audioUrl);
          await _audioPlayer.play();
        } catch (e) {
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to play audio')),
              );
            } catch (_) {}
          }
        }
      }
    } else {
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error']?.toString() ?? 'TTS unavailable')),
          );
        } catch (_) {}
      }
    }

    if (mounted) setState(() => _isTtsLoading = false);
  }

  void _showWordDetail(WordBreakdown word) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WordDetailSheet(
        word: word,
        messageId: widget.messageId,
        language: _targetLanguage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray700 : AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.translate, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${TranslationService.getLanguageFlag(_targetLanguage)} ${TranslationService.getLanguageName(_targetLanguage)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_isLimitReached)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.translate, size: 32, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daily Translation Limit Reached',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free users get 5 translations per day.\nUpgrade to VIP for unlimited translations!',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VipStatusScreen(userId: userId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Upgrade to VIP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _translate,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original text
                    Text(
                      widget.originalText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.gray300 : AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Translated text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.primaryColor.withValues(alpha: 0.15)
                            : theme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translatedText,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.white : AppColors.gray900,
                            ),
                          ),
                          if (_transliteration != null && _transliteration!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _transliteration!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.gray400 : AppColors.gray600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // TTS button
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildIconButton(
                          icon: _isTtsPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                          label: _isTtsPlaying ? 'Stop' : 'Listen',
                          isLoading: _isTtsLoading,
                          onTap: _playTTS,
                          isDark: isDark,
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        _buildIconButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _translatedText));
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Translation copied'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            } catch (_) {
                              // SnackBar may not show if no ScaffoldMessenger ancestor
                            }
                          },
                          isDark: isDark,
                          theme: theme,
                        ),
                        if (_cached) ...[
                          const Spacer(),
                          Icon(Icons.cached, size: 14, color: AppColors.gray500),
                          const SizedBox(width: 4),
                          Text('Cached', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                        ],
                      ],
                    ),

                    // Word breakdown
                    if (_breakdown.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Word Breakdown',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gray300 : AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _breakdown.map((word) {
                          return GestureDetector(
                            onTap: () => _showWordDetail(word),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.gray800 : AppColors.gray100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? AppColors.gray700 : AppColors.gray200,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    word.original,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    word.translation,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Alternatives
                    if (_alternatives.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Alternatives',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gray300 : AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_alternatives.map((alt) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alt.formalityIcon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alt.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppColors.gray300 : AppColors.gray700,
                                    ),
                                  ),
                                  if (alt.context.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        alt.context,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.gray500 : AppColors.gray600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))),
                    ],

                    // Grammar notes
                    if (_grammarNotes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Grammar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gray300 : AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_grammarNotes.map((note) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.gray800 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.topic,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                              ),
                            ),
                            if (note.explanation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.explanation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.gray300 : AppColors.gray700,
                                ),
                              ),
                            ],
                            if (note.sourceExample.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.sourceExample,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ))),
                    ],

                    // Cultural note
                    if (_culturalNote != null && _culturalNote!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.gray800 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🌍', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _culturalNote!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.gray300 : AppColors.gray700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray800 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                ),
              )
            else
              Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Word detail popup shown when tapping a word chip
class _WordDetailSheet extends StatefulWidget {
  final WordBreakdown word;
  final String messageId;
  final String language;

  const _WordDetailSheet({
    required this.word,
    required this.messageId,
    required this.language,
  });

  @override
  State<_WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<_WordDetailSheet> {
  bool _isSaving = false;
  bool _saved = false;

  Future<void> _saveToVocabulary() async {
    setState(() => _isSaving = true);

    final result = await TranslationService.saveToVocabulary(
      messageId: widget.messageId,
      word: widget.word.original,
      translation: widget.word.translation,
      pronunciation: widget.word.pronunciation,
      language: widget.language,
      partOfSpeech: widget.word.partOfSpeech.isNotEmpty ? widget.word.partOfSpeech : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _saved = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to vocabulary!'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? 'Failed to save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray700 : AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Word
          Text(
            widget.word.original,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),

          // Pronunciation
          if (widget.word.pronunciation != null && widget.word.pronunciation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.word.pronunciation!,
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppColors.gray400 : AppColors.gray600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.gray700 : AppColors.gray200),
          const SizedBox(height: 16),

          // Meaning
          Text(
            widget.word.translation,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.white : AppColors.gray900,
            ),
          ),

          // Part of speech
          if (widget.word.partOfSpeech.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.gray800 : AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.word.partOfSpeech,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
            ),
          ],

          // Alternative translations
          if (widget.word.alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Also: ${widget.word.alternatives.join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _saved || _isSaving ? null : _saveToVocabulary,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_saved ? Icons.check_rounded : Icons.bookmark_add_rounded),
                label: Text(_saved ? 'Saved' : 'Save to Vocabulary'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Show the translation bottom sheet for a message
Future<void> showTranslationBottomSheet(
  BuildContext context, {
  required String messageId,
  required String originalText,
  String? targetLanguage,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => TranslationBottomSheet(
      messageId: messageId,
      originalText: originalText,
      initialTargetLanguage: targetLanguage,
    ),
  );
}
