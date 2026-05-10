import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Wraps [child] to detect long-press on individual words and offer a
/// "save to vocabulary" dialog with a translation preview.
///
/// Pass the same [textKey] to the [Text] (or [Text.rich]) widget inside
/// [child] so the widget can hit-test which word was pressed.
///
/// Native language is read from SharedPreferences (`user_native_language`)
/// avoiding any provider dependency and keeping this widget callable from
/// both Stateless and Stateful parents.
class WordLongPressHandler extends StatefulWidget {
  /// The full text string whose words can be saved.
  final String text;

  /// BCP-47 source language of [text], or null to let backend auto-detect.
  final String? sourceLanguage;

  /// The widget tree that renders [text]. Must contain a [Text] or [Text.rich]
  /// at the element identified by [textKey].
  final Widget child;

  /// Key attached to the innermost [Text] / [Text.rich] widget so that we can
  /// obtain its [RenderParagraph] for word-boundary hit-testing.
  final GlobalKey textKey;

  const WordLongPressHandler({
    super.key,
    required this.text,
    required this.child,
    required this.textKey,
    this.sourceLanguage,
  });

  @override
  State<WordLongPressHandler> createState() => _WordLongPressHandlerState();
}

class _WordLongPressHandlerState extends State<WordLongPressHandler> {
  // ──────────────────────────────────────────────────────── hit-test

  String? _hitTestWord(Offset gestureLocal) {
    final keyContext = widget.textKey.currentContext;
    if (keyContext == null) return null;

    final ro = keyContext.findRenderObject();
    if (ro is! RenderParagraph) return null;

    // Map gesture position (in this widget's coordinate space) → RenderParagraph local.
    final thisBox = context.findRenderObject() as RenderBox?;
    if (thisBox == null) return null;
    final global = thisBox.localToGlobal(gestureLocal);
    final paraLocal = ro.globalToLocal(global);

    final pos = ro.getPositionForOffset(paraLocal);
    final wordRange = ro.getWordBoundary(pos);

    if (wordRange.start < 0 ||
        wordRange.end > widget.text.length ||
        wordRange.start >= wordRange.end) {
      return null;
    }

    final raw = widget.text.substring(wordRange.start, wordRange.end).trim();
    if (raw.isEmpty || raw.length > 50) return null;

    // Strip leading/trailing punctuation (Unicode-aware).
    final cleaned = raw.replaceAll(
      RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
      '',
    );
    return cleaned.isEmpty ? null : cleaned;
  }

  // ──────────────────────────────────────────────────────── save flow

  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    final word = _hitTestWord(details.localPosition);
    if (word == null || !mounted) return;
    await _showSaveDialog(word);
  }

  Future<void> _showSaveDialog(String word) async {
    final l10n = AppLocalizations.of(context)!;

    // Resolve native language: name stored at login → BCP-47 code.
    final prefs = await SharedPreferences.getInstance();
    final nativeLangName = prefs.getString('user_native_language') ?? '';
    final nativeLangCode = TranslationService.supportedLanguages
            .firstWhere(
              (l) => l['name']!.toLowerCase() == nativeLangName.toLowerCase(),
              orElse: () => {'code': 'en'},
            )['code'] ??
        'en';

    if (!mounted) return;

    // Fetch translation preview (best-effort; show whatever we get).
    String? translation;
    try {
      translation = await TranslationService.translateWord(
        word: word,
        targetLanguage: nativeLangCode,
        sourceLanguage: widget.sourceLanguage,
      );
    } catch (_) {
      translation = null;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveToVocabulary(word)),
        content: Text(translation ?? word),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await LearningService.addVocabulary(
      word: word,
      translation: translation ?? word,
      language: widget.sourceLanguage ?? 'auto',
      exampleSentence: widget.text.length < 200 ? widget.text : null,
    );

    if (!mounted) return;

    final success = result['success'] == true;
    showChatSnackBar(
      context,
      message: success ? l10n.addedToVocabulary : l10n.alreadyInVocabulary,
      type: success ? ChatSnackBarType.success : ChatSnackBarType.info,
    );
  }

  // ──────────────────────────────────────────────────────── build

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _onLongPressStart,
      child: widget.child,
    );
  }
}
