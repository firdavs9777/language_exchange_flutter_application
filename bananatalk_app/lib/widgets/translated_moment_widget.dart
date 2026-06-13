import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/language_selection/show_language_picker.dart';

/// Soft-tinted translation panel that lives BELOW a moment's original text.
/// Caller still renders the original — this widget renders only the panel
/// (loading shimmer, translation body, language switcher, dismiss button).
/// Auto-translates to the user's preferred / device language on mount; user
/// can tap the language pill to open the full LanguagePickerScreen and
/// switch targets at any time.
class TranslatedMomentWidget extends StatefulWidget {
  final String momentId;
  final String originalText;
  final String? originalLanguage;
  final List<MessageTranslation>? existingTranslations;
  final VoidCallback? onTranslationAdded;
  final VoidCallback? onDismiss;
  // When non-null, skip the auto-detect path and translate to this code
  // straight away. Used when the caller already showed the picker before
  // expanding the panel.
  final String? initialTargetCode;

  const TranslatedMomentWidget({
    Key? key,
    required this.momentId,
    required this.originalText,
    this.originalLanguage,
    this.existingTranslations,
    this.onTranslationAdded,
    this.onDismiss,
    this.initialTargetCode,
  }) : super(key: key);

  @override
  State<TranslatedMomentWidget> createState() => _TranslatedMomentWidgetState();
}

class _TranslatedMomentWidgetState extends State<TranslatedMomentWidget>
    with SingleTickerProviderStateMixin {
  MessageTranslation? _activeTranslation;
  bool _isLoading = false;
  String? _error;

  // Language object cache used to render the header's flag + name with the
  // backend's display strings (LanguagePickerScreen returns the full Language
  // when picked; we hold it so getLanguageFlag/Name fall back gracefully).
  Language? _activeLanguage;

  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  // Pick the initial target language. If the caller already opened the
  // picker and passed an `initialTargetCode`, use that. Otherwise fall
  // back to the user's preferred / auto-detected language.
  Future<void> _bootstrap() async {
    final target = widget.initialTargetCode ??
        await TranslationService.getPreferredLanguage() ??
        await TranslationService.getAutoTranslateLanguage();

    if (!mounted) return;

    debugPrint('🌐 [moment-translate] bootstrap '
        'momentId=${widget.momentId} '
        'originalLanguage=${widget.originalLanguage} '
        'initialTargetCode=${widget.initialTargetCode} '
        'resolvedTarget=$target '
        'existingTranslationCount=${widget.existingTranslations?.length ?? 0}');

    // Use a cached translation when available — instant, no API call.
    final cached = _findExistingFor(target);
    if (cached != null) {
      debugPrint('🌐 [moment-translate] using cached translation for '
          'target=$target lang=${cached.language} '
          'preview="${cached.translatedText.substring(0, cached.translatedText.length.clamp(0, 60))}"');
      setState(() => _activeTranslation = cached);
      return;
    }

    await _translateTo(target);
  }

  MessageTranslation? _findExistingFor(String code) {
    final list = widget.existingTranslations;
    if (list == null) return null;
    for (final t in list) {
      if (t.language.toLowerCase() == code.toLowerCase() &&
          t.translatedText.trim().isNotEmpty) {
        return t;
      }
    }
    return null;
  }

  Future<void> _translateTo(String languageCode) async {
    final cached = _findExistingFor(languageCode);
    if (cached != null) {
      debugPrint('🌐 [moment-translate] cache hit on _translateTo '
          'requested=$languageCode returned=${cached.language}');
      setState(() {
        _activeTranslation = cached;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    debugPrint('🌐 [moment-translate] POST /moments/${widget.momentId}/translate '
        'targetLanguage=$languageCode');

    try {
      final result = await TranslationService.translateMoment(
        momentId: widget.momentId,
        targetLanguage: languageCode,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final tr = result['data'] as MessageTranslation;
        debugPrint('🌐 [moment-translate] response '
            'requested=$languageCode '
            'returnedLang=${tr.language} '
            'cached=${result['cached']} '
            'textPreview="${tr.translatedText.substring(0, tr.translatedText.length.clamp(0, 80))}"');
        setState(() {
          _activeTranslation = tr;
          _isLoading = false;
        });
        widget.onTranslationAdded?.call();
      } else {
        debugPrint('🌐 [moment-translate] error response '
            'requested=$languageCode error=${result['error']}');
        final l10n = AppLocalizations.of(context)!;
        final errorMsg =
            result['error']?.toString() ?? l10n.translationUnavailable;
        setState(() {
          _error = (errorMsg.contains('API key') ||
                  errorMsg.contains('libretranslate'))
              ? l10n.translationServiceBeingConfigured
              : l10n.translationUnavailable;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.translationUnavailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLanguagePicker() async {
    final picked = await showLanguagePickerSheet(
      context,
      currentCode: _activeTranslation?.language,
    );
    if (picked == null || !mounted) return;
    setState(() => _activeLanguage = picked);
    await TranslationService.setPreferredLanguage(picked.code);
    await _translateTo(picked.code);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    const accent = AppColors.primary;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: isDark
              ? accent.withValues(alpha: 0.10)
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: accent, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 6),
            _buildBody(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    // AppColors.primary inlined here (rather than passed as a parameter) so
    // the nested `const TextStyle(color: ...)` / `const Icon(color: ...)` /
    // `const AlwaysStoppedAnimation(...)` calls below are valid const exprs.
    const accent = AppColors.primary;
    // Pick the best label + flag for the current target language. Prefer
    // the Language object the picker handed us (richest data); fall back
    // to TranslationService's 44-entry static maps.
    final code = _activeTranslation?.language ?? _activeLanguage?.code;
    String flag = '🌐';
    String name = AppLocalizations.of(context)!.translate;
    if (code != null) {
      flag = _activeLanguage?.flag ?? TranslationService.getLanguageFlag(code);
      name = _activeLanguage?.name ?? TranslationService.getLanguageName(code);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        // Language pill — tap to open the full picker.
        GestureDetector(
          onTap: _openLanguagePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.20 : 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 12,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
        const Spacer(),
        if (widget.onDismiss != null)
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: context.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_isLoading && _activeTranslation == null) {
      return Text(
        AppLocalizations.of(context)!.translating,
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: context.textHint,
        ),
      );
    }
    if (_error != null && _activeTranslation == null) {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: context.textHint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 12, color: context.textHint),
            ),
          ),
        ],
      );
    }
    if (_activeTranslation != null) {
      return Text(
        _activeTranslation!.translatedText,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );
    }
    // Nothing yet (transient race during _bootstrap)
    return const SizedBox.shrink();
  }
}
