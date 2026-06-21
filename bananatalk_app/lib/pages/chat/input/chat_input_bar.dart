import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final bool showPhrasesPanel;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final VoidCallback onToggleMediaPanel;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onTogglePhrasesPanel;
  final VoidCallback onTyping;
  final VoidCallback onStopTyping;
  final VoidCallback onHidePanels;
  // Direct shortcut for the toolbar's gallery/location/gif buttons —
  // reuses the parent's existing media-panel handler so we don't duplicate
  // the underlying pickers.
  final Function(String)? onMediaOption;
  final Message? replyingToMessage;
  final String? otherUserName;
  final VoidCallback? onCancelReply;
  final VoidCallback? onAudioPressed;
  // Upload progress
  final int uploadBytesSent;
  final int uploadTotalBytes;
  final String? uploadFileName;

  const ChatInputBar({
    Key? key,
    required this.messageController,
    required this.isSending,
    required this.showMediaPanel,
    required this.showStickerPanel,
    this.showPhrasesPanel = false,
    required this.onSendMessage,
    required this.onToggleMediaPanel,
    required this.onToggleStickerPanel,
    required this.onTogglePhrasesPanel,
    required this.onTyping,
    required this.onStopTyping,
    required this.onHidePanels,
    this.onMediaOption,
    this.replyingToMessage,
    this.otherUserName,
    this.onCancelReply,
    this.onAudioPressed,
    this.uploadBytesSent = 0,
    this.uploadTotalBytes = 0,
    this.uploadFileName,
  }) : super(key: key);

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with TickerProviderStateMixin {
  bool _hasText = false;
  late AnimationController _sendButtonController;

  // HelloTalk-style live translate state. The user picks a target language
  // once; thereafter every keystroke debounces a re-translate, and the live
  // result is shown in a preview band above the input row. On send, the
  // translated text is the message body (the original typed text is local
  // to the input only).
  String? _translateTargetCode;
  String? _translatedText;
  bool _translating = false;
  Timer? _translateDebounce;
  // Remembers the last input we asked the API to translate so we don't
  // fire a duplicate request when text-change events arrive from focus,
  // selection, etc. (not real edits).
  String? _lastTranslatedSource;

  // Full 127-language list from GET /languages, lazily fetched on first
  // picker open and cached for the widget lifetime. Falls back to the
  // 44-language hardcoded list inside TranslationService if the fetch fails.
  List<Language> _allLanguages = [];
  bool _loadingLanguages = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.messageController.text.trim().isNotEmpty;
    widget.messageController.addListener(_onTextChanged);

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    if (_hasText) _sendButtonController.forward();
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _translateDebounce?.cancel();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
    // When translate-mode is on, debounce a live re-translate.
    if (_translateTargetCode != null) {
      _scheduleLiveTranslate();
    }
  }

  void _scheduleLiveTranslate() {
    _translateDebounce?.cancel();
    final current = widget.messageController.text.trim();
    if (current.isEmpty) {
      setState(() {
        _translatedText = null;
        _lastTranslatedSource = null;
      });
      return;
    }
    if (current == _lastTranslatedSource) return;
    _translateDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _translateTargetCode == null) return;
      _runLiveTranslate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: !widget.showMediaPanel && !widget.showStickerPanel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyingToMessage != null) ...[
              _buildReplyPreview(context, isDark),
              const SizedBox(height: 8),
            ],
            // Live translation preview (HelloTalk-style)
            if (_translateTargetCode != null) ...[
              _buildTranslationPreview(isDark),
              const SizedBox(height: 8),
            ],
            // Compose row — input + send/mic. The trailing button is a
            // single slot that cross-fades between Mic (empty input) and
            // Send (has text), like WhatsApp / iMessage. Gives the field
            // the maximum possible width and removes the awkward "two
            // buttons fighting for the same job" feel.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildTextField(context, isDark)),
                const SizedBox(width: 8),
                _buildSendButton(context, isDark),
              ],
            ),
            const SizedBox(height: 6),
            // Tools row — distributed across the full width with rounded,
            // tinted icons. Direct shortcuts for the most common media
            // types (gallery / location / GIF); + stays as the overflow
            // for camera / video / audio / document.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAttachButton(isDark),
                _buildToolButton(
                  isDark,
                  icon: Icons.photo_library_rounded,
                  tint: const Color(0xFF8B5CF6),
                  onTap: () => widget.onMediaOption?.call('gallery'),
                ),
                _buildToolButton(
                  isDark,
                  icon: Icons.place_rounded,
                  tint: const Color(0xFFEF4444),
                  onTap: () => widget.onMediaOption?.call('location'),
                ),
                _buildToolButton(
                  isDark,
                  icon: Icons.gif_box_rounded,
                  tint: const Color(0xFF06B6D4),
                  onTap: () => widget.onMediaOption?.call('gif'),
                ),
                _buildEmojiButton(isDark),
                _buildTranslateButton(isDark),
                _buildPhrasesButton(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark) {
    final replyMessage = widget.replyingToMessage!;
    final replyText = replyMessage.message ??
        (replyMessage.media != null ? '📷 Media' : 'Message');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${widget.otherUserName ?? "user"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onCancelReply,
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
      ),
    );
  }

  Widget _buildAttachButton(bool isDark) {
    final isActive = widget.showMediaPanel;

    const tint = Color(0xFF64748B); // slate — "more / overflow"
    return GestureDetector(
      onTap: widget.onToggleMediaPanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.18)
              : tint.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedRotation(
          turns: isActive ? 0.125 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.add_rounded,
            color: isActive ? AppColors.primary : tint,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 140),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: widget.messageController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.typeAMessage,
          hintStyle: TextStyle(
            color: context.textHint,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          // Taller resting height — the field now feels closer in mass to
          // the 44px tool buttons, not a thin sliver between them.
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          isDense: true,
        ),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 15,
          color: context.textPrimary,
          height: 1.35,
        ),
        onSubmitted: (_) => _handleSend(),
        onChanged: (text) {
          if (text.trim().isNotEmpty) {
            widget.onTyping();
          } else {
            widget.onStopTyping();
          }
        },
        onTap: widget.onHidePanels,
      ),
    );
  }

  Widget _buildEmojiButton(bool isDark) {
    final isActive = widget.showStickerPanel;

    const tint = Color(0xFFF59E0B);
    return GestureDetector(
      onTap: widget.onToggleStickerPanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? tint.withValues(alpha: 0.18)
              : tint.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isActive ? Icons.keyboard_rounded : Icons.emoji_emotions_rounded,
          color: tint,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPhrasesButton(bool isDark) {
    const tint = Color(0xFF8B5CF6); // HelloTalk-style purple speech bubble
    final isActive = widget.showPhrasesPanel;
    return GestureDetector(
      onTap: widget.onTogglePhrasesPanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: isActive ? 0.22 : (isDark ? 0.14 : 0.08)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isActive ? Icons.keyboard_rounded : Icons.chat_bubble_rounded,
          color: tint,
          size: isActive ? 24 : 22,
        ),
      ),
    );
  }

  Widget _buildTranslateButton(bool isDark) {
    const accent = AppColors.primary;
    final isActive = _translateTargetCode != null;
    return GestureDetector(
      onTap: _openLanguagePicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isActive ? 0.22 : (isDark ? 0.14 : 0.08)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isActive
            ? Center(
                child: Text(
                  _translateTargetCode!.toUpperCase(),
                  style: const TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              )
            : const Icon(
                Icons.translate_rounded,
                color: accent,
                size: 24,
              ),
      ),
    );
  }

  // Live-translation preview band — sits above the input row when
  // translate-mode is active. Mirrors the reply-preview visual treatment.
  Widget _buildTranslationPreview(bool isDark) {
    const accent = AppColors.primary;
    final targetCode = _translateTargetCode!;
    // Prefer the rich Language entry from the backend list (gives correct
    // flag + display name for the full 127-language catalog); fall back to
    // TranslationService's 44-entry map for codes not in /languages.
    Language? backendLang;
    for (final l in _allLanguages) {
      if (l.code == targetCode) {
        backendLang = l;
        break;
      }
    }
    final flag = backendLang?.flag ??
        TranslationService.getLanguageFlag(targetCode);
    final name = backendLang?.name ??
        TranslationService.getLanguageName(targetCode);
    final preview = _translatedText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark
            ? accent.withValues(alpha: 0.10)
            : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(flag, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    if (_translating) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  preview == null || preview.isEmpty
                      ? (_hasText
                          ? 'Translating…'
                          : 'Start typing to see the translation')
                      : preview,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: preview == null
                        ? context.textHint
                        : (isDark ? Colors.white : Colors.black87),
                    fontStyle:
                        preview == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearTranslateMode,
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
      ),
    );
  }

  // Lazily fetch the full 127-language list from GET /languages. Cached for
  // the widget lifetime. Silent on failure — _openLanguagePicker falls back
  // to TranslationService.supportedLanguages (44 hardcoded entries).
  Future<void> _ensureLanguagesLoaded() async {
    if (_allLanguages.isNotEmpty || _loadingLanguages) return;
    _loadingLanguages = true;
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> list = decoded['data'] ?? [];
        _allLanguages =
            list.map<Language>((j) => Language.fromJson(j)).toList();
      }
    } catch (_) {
      // Best-effort; the picker fallback handles an empty list.
    } finally {
      _loadingLanguages = false;
    }
  }

  // Open the full LanguagePickerScreen (search, recommended section,
  // alphabetical index — same widget the community filter uses). Picking
  // activates translate-mode or switches the target; the preview band
  // stays visible until the user dismisses it.
  Future<void> _openLanguagePicker() async {
    await _ensureLanguagesLoaded();
    if (!mounted) return;

    // Fallback to the 44-language hardcoded list when the backend fetch
    // is empty (offline, server hiccup) so the user can still translate.
    final languages = _allLanguages.isNotEmpty
        ? _allLanguages
        : TranslationService.supportedLanguages
            .map((m) => Language(
                  id: m['code'] ?? '',
                  code: m['code'] ?? '',
                  name: m['name'] ?? '',
                  nativeName: m['name'] ?? '',
                  backendFlag: m['flag'],
                ))
            .toList();

    if (languages.isEmpty) return;

    final currentSelection = _translateTargetCode == null
        ? null
        : languages.firstWhere(
            (l) => l.code == _translateTargetCode,
            orElse: () => languages.first,
          );

    final picked = await Navigator.of(context).push<Language>(
      AppPageRoute(
        builder: (_) => LanguagePickerScreen(
          languages: languages,
          selectedLanguage: currentSelection,
        ),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _translateTargetCode = picked.code;
      _lastTranslatedSource = null; // force a fresh translate
    });
    HapticUtils.lightImpact();
    if (widget.messageController.text.trim().isNotEmpty) {
      _runLiveTranslate();
    }
  }

  // Actually call the API and refresh the live translation. Silent on
  // failure — the preview band shows a small "couldn't translate" hint
  // instead of replacing the previous good result.
  Future<void> _runLiveTranslate() async {
    final source = widget.messageController.text.trim();
    final target = _translateTargetCode;
    if (source.isEmpty || target == null) return;

    final user = ref.read(userProvider).valueOrNull;
    final sourceCode = TranslationService.codeForLanguageName(
        user?.native_language ?? '');

    setState(() => _translating = true);
    final result = await TranslationService.translateWord(
      word: source,
      targetLanguage: target,
      sourceLanguage: sourceCode,
    );
    if (!mounted || _translateTargetCode != target) return;
    setState(() {
      _translating = false;
      _lastTranslatedSource = source;
      if (result != null && result.trim().isNotEmpty) {
        _translatedText = result;
      }
    });
  }

  void _clearTranslateMode() {
    _translateDebounce?.cancel();
    setState(() {
      _translateTargetCode = null;
      _translatedText = null;
      _translating = false;
      _lastTranslatedSource = null;
    });
  }

  // Intercepts send when translate-mode is active: replace controller text
  // with the live translation so the message body carries the picked
  // language. Then defers to the parent's normal send pipeline (which
  // clears the controller and handles optimistic UI).
  void _handleSend() {
    if (_translateTargetCode != null &&
        _translatedText != null &&
        _translatedText!.trim().isNotEmpty) {
      widget.messageController.text = _translatedText!;
      widget.messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _translatedText!.length),
      );
      // Reset translate-mode after a send — feels less surprising than
      // staying armed for the next message.
      _clearTranslateMode();
    }
    HapticUtils.onMessageSend();
    widget.onSendMessage();
  }

  Widget _buildSendButton(BuildContext context, bool isDark) {
    final isUploadingMedia = widget.uploadTotalBytes > 0;
    final canSend = !widget.isSending || isUploadingMedia;
    // Single slot: tap-sends when there's text, tap-records audio when empty.
    return GestureDetector(
      onTap: !canSend
          ? null
          : _hasText
              ? _handleSend
              : widget.onAudioPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: _hasText && canSend
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _hasText
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          boxShadow: _hasText && canSend
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: _buildSendIcon(context, isDark, isUploadingMedia, canSend),
          ),
        ),
      ),
    );
  }

  Widget _buildSendIcon(
      BuildContext context, bool isDark, bool isUploadingMedia, bool canSend) {
    // Sending text (not media upload) — spinner
    if (widget.isSending && !isUploadingMedia) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    // Has text — Telegram-style tilted paper-plane on the gradient pill.
    // Nudged 1px right so the visual mass of the icon centers inside the
    // circle (the asset's optical center sits slightly left of geometric).
    if (_hasText) {
      return const Padding(
        key: ValueKey('send'),
        padding: EdgeInsets.only(left: 2),
        child: Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // Uploading media with no text — progress ring
    if (isUploadingMedia) {
      return SizedBox(
        key: const ValueKey('uploading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: widget.uploadBytesSent / widget.uploadTotalBytes,
          valueColor: AlwaysStoppedAnimation<Color>(context.textSecondary),
          backgroundColor: context.textMuted.withValues(alpha: 0.3),
        ),
      );
    }

    // Empty input — mic, signalling tap-to-record (WhatsApp pattern)
    return Icon(
      Icons.mic_rounded,
      key: const ValueKey('mic'),
      color: context.textSecondary,
      size: 26,
    );
  }

  // Generic toolbar button used by the row-2 shortcuts (gallery, location,
  // gif). Same 40x40 frame as the rest of the tools row; each instance gets
  // a tinted icon so they're distinguishable at a glance without screaming.
  Widget _buildToolButton(
    bool isDark, {
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          // Subtle tinted background so each tool reads as its own affordance
          // (not a hostile sea of grey squares) without competing with the
          // input bubble. 8% alpha keeps it whisper-quiet on both themes.
          color: tint.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: tint, size: 24),
      ),
    );
  }

}
