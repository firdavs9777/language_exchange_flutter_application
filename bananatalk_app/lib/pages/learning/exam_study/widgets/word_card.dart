import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/vocabulary_word.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Browse-mode card for a single vocabulary word. Tap the speaker icon to
/// play / fetch the TTS audio (handled by the caller). Tap the translate
/// icon to fetch a translation of the word + definition + example into
/// the user's native language (resolved via TranslationService.
/// getAutoTranslateLanguage, the same chain chat uses).
class WordCard extends StatefulWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.onPlayAudio,
    this.isPlaying = false,
  });

  final VocabularyWord word;
  final VoidCallback onPlayAudio;
  final bool isPlaying;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _showTranslation = false;
  bool _loading = false;
  String? _translatedWord;
  String? _translatedDefinition;
  String? _translatedExample;
  String? _error;

  Future<void> _onTapTranslate() async {
    // Toggle off if already showing.
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    // If already fetched, just show.
    if (_translatedWord != null) {
      setState(() => _showTranslation = true);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final target = await TranslationService.getAutoTranslateLanguage();
      final futures = await Future.wait([
        TranslationService.translateWord(
          word: widget.word.word,
          targetLanguage: target,
        ),
        TranslationService.translateWord(
          word: widget.word.definition,
          targetLanguage: target,
        ),
        if (widget.word.exampleSentence.isNotEmpty)
          TranslationService.translateWord(
            word: widget.word.exampleSentence,
            targetLanguage: target,
          ),
      ]);
      if (!mounted) return;
      setState(() {
        _translatedWord = futures[0];
        _translatedDefinition = futures[1];
        _translatedExample = futures.length > 2 ? futures[2] : null;
        _showTranslation = _translatedWord != null ||
            _translatedDefinition != null ||
            _translatedExample != null;
        _loading = false;
        if (!_showTranslation) _error = 'TRANSLATION_FAILED';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final word = widget.word;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word.word,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _onTapTranslate,
                icon: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: context.primaryColor,
                        ),
                      )
                    : Icon(
                        _showTranslation
                            ? Icons.translate_rounded
                            : Icons.translate_outlined,
                        color: _showTranslation
                            ? context.primaryColor
                            : context.textMuted,
                      ),
                tooltip: l10n.examVocabTranslate,
              ),
              IconButton(
                onPressed: widget.onPlayAudio,
                icon: Icon(
                  widget.isPlaying
                      ? Icons.volume_up_rounded
                      : Icons.play_circle_outline_rounded,
                  color: context.primaryColor,
                ),
                tooltip: 'Listen',
              ),
            ],
          ),
          if (_showTranslation && _translatedWord != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _translatedWord!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.primaryColor,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              _chip(context, word.partOfSpeech),
              _chip(context, word.level),
              if (word.topic != null && word.topic!.isNotEmpty)
                _chip(context, word.topic!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            word.definition,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimary,
              height: 1.45,
            ),
          ),
          if (_showTranslation && _translatedDefinition != null) ...[
            const SizedBox(height: 4),
            Text(
              _translatedDefinition!,
              style: TextStyle(
                fontSize: 13,
                color: context.primaryColor,
                height: 1.45,
              ),
            ),
          ],
          if (word.exampleSentence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.exampleSentence,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (_showTranslation && _translatedExample != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _translatedExample!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: context.primaryColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.examVocabTranslateFailed,
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.primaryColor,
        ),
      ),
    );
  }
}
