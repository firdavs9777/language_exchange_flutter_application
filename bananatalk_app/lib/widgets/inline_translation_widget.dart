import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/widgets/translation_bottom_sheet.dart';

/// Inline translation that appears below a chat message bubble.
/// Auto-translates to the user's native language and shows the result compactly.
/// Tap to open full breakdown bottom sheet.
class InlineTranslationWidget extends StatefulWidget {
  final String messageId;
  final String originalText;
  final bool isMe;

  const InlineTranslationWidget({
    super.key,
    required this.messageId,
    required this.originalText,
    this.isMe = false,
  });

  @override
  State<InlineTranslationWidget> createState() => _InlineTranslationWidgetState();
}

class _InlineTranslationWidgetState extends State<InlineTranslationWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _translatedText;
  String? _transliteration;
  String _targetLanguage = 'en';
  bool _isVisible = true;

  // Cache to avoid re-fetching on rebuilds
  static final Map<String, _CachedTranslation> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadTranslation();
  }

  @override
  void didUpdateWidget(InlineTranslationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId) {
      _loadTranslation();
    }
  }

  Future<void> _loadTranslation() async {
    // Check cache first
    final cached = _cache[widget.messageId];
    if (cached != null) {
      setState(() {
        _translatedText = cached.translatedText;
        _transliteration = cached.transliteration;
        _targetLanguage = cached.targetLanguage;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Get user's preferred language
    final lang = await TranslationService.getAutoTranslateLanguage();
    _targetLanguage = lang;

    final result = await TranslationService.translateMessage(
      messageId: widget.messageId,
      targetLanguage: lang,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final translated = data['translatedText']?.toString() ?? data['translation']?.toString() ?? '';
      final translit = data['transliteration']?.toString();

      // Don't show if translation is same as original (same language)
      if (translated.trim().toLowerCase() == widget.originalText.trim().toLowerCase()) {
        setState(() {
          _isLoading = false;
          _isVisible = false;
        });
        return;
      }

      // Cache it
      _cache[widget.messageId] = _CachedTranslation(
        translatedText: translated,
        transliteration: translit,
        targetLanguage: lang,
      );

      setState(() {
        _translatedText = translated;
        _transliteration = translit;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _openFullTranslation() {
    showTranslationBottomSheet(
      context,
      messageId: widget.messageId,
      originalText: widget.originalText,
      targetLanguage: _targetLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? AppColors.gray500 : AppColors.gray400,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Translating...',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.gray500 : AppColors.gray400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError || _translatedText == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _openFullTranslation,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.gray800.withValues(alpha: 0.7)
              : AppColors.gray100.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Translated text
            Text(
              _translatedText!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.gray300 : AppColors.gray700,
                height: 1.3,
              ),
            ),
            // Transliteration (if available)
            if (_transliteration != null && _transliteration!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _transliteration!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.gray500 : AppColors.gray500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // "Tap for details" hint + language flag
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.translate,
                    size: 11,
                    color: isDark ? AppColors.gray600 : AppColors.gray400,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${TranslationService.getLanguageFlag(_targetLanguage)} Tap for details',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.gray600 : AppColors.gray400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CachedTranslation {
  final String translatedText;
  final String? transliteration;
  final String targetLanguage;

  _CachedTranslation({
    required this.translatedText,
    this.transliteration,
    required this.targetLanguage,
  });
}
