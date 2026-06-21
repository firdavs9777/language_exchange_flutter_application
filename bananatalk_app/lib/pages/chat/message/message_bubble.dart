import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/message_reaction_widget.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/widgets/forwarded_message_indicator.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/widgets/translation_bottom_sheet.dart';
import 'package:bananatalk_app/widgets/correction_bottom_sheet.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/chat/header/user_avatar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/chat/message/message_context_menu_item.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/message/bubble/bubble_actions_menu.dart';
import 'package:bananatalk_app/pages/chat/message/bubble/system_bubble.dart';
import 'package:bananatalk_app/pages/chat/message/message_bubble/text_message_view.dart';
import 'package:bananatalk_app/pages/chat/message/message_bubble/image_message_view.dart';
import 'package:bananatalk_app/pages/chat/message/message_bubble/voice_message_view.dart';
import 'package:bananatalk_app/pages/chat/message/message_bubble/gif_message_view.dart';

class ChatMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;
  final String otherUserName;
  final String? otherUserPicture;
  final String? otherUserNativeLanguage;
  final Function(Message)? onDelete;
  final Function(Message)? onEdit;
  final Function(Message)? onReply;
  final Function(String messageId)? onReplyTap; // Tap on reply preview to scroll
  final Message? replyToMessage;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(Message, bool)? onSelectionChanged;
  final Function(Message)? onPin;
  final Function(Message)? onUnpin;
  final Function(Message)? onForward;
  final Function(Message)? onRetry; // Retry sending failed message
  final Function(Message)? onDeleteFailed; // Delete failed message from UI
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    this.otherUserPicture,
    this.otherUserNativeLanguage,
    this.onDelete,
    this.onEdit,
    this.onReply,
    this.onReplyTap,
    this.replyToMessage,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionChanged,
    this.onPin,
    this.onUnpin,
    this.onForward,
    this.onRetry,
    this.onDeleteFailed,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  ConsumerState<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends ConsumerState<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _reactionPickerOverlay;
  String? _currentUserId;
  final GlobalKey _bubbleKey = GlobalKey();

  // Session-scoped cache for the inline-translate chip, keyed by messageId.
  // Survives leaving and re-entering a chat (bubble widget state is rebuilt,
  // but this static map persists for the process lifetime). Cleared on app
  // restart — at which point the backend's per-message translation cache
  // returns the same answer instantly on the next tap.
  static final Map<String, String> _inlineTranslationCache = {};

  // Inline-translation state for the quick "Translate" chip — null = hidden.
  String? _inlineTranslation;
  bool _inlineTranslating = false;

  // Slide-in animation flag: prevents replaying on every rebuild
  bool _hasAnimatedIn = false;

  // Swipe-to-reply state
  double _swipeOffset = 0;
  static const double _swipeThreshold = 60.0;
  late AnimationController _swipeAnimController;
  late Animation<double> _swipeAnimation;

  // ---------- Theme-aware colour helpers ----------

  Color _myMessageColor(BuildContext context) =>
      context.isDarkMode ? AppColors.chatBubbleMineDark : AppColors.chatBubbleMine;
  Color _otherMessageColor(BuildContext context) =>
      context.isDarkMode ? AppColors.chatBubbleOtherDark : AppColors.chatBubbleOther;
  Color _myTextColor(BuildContext context) => AppColors.chatTextMine;
  Color _otherTextColor(BuildContext context) =>
      context.isDarkMode ? AppColors.white : AppColors.chatTextOther;
  Color _timestampColor(BuildContext context) => context.textSecondary;
  Color _sendingColor(BuildContext context) => context.textSecondary;
  Color _failedColor(BuildContext context) => AppColors.error;

  // ---------- Bubble shape ----------

  // M3 asymmetric bubble radius: 20/20 top, 4/20 or 20/4 bottom based on isMe.
  // In grouped messages the "tail corner" stays small (4) regardless of position
  // to preserve the conversation-thread visual rhythm.
  BorderRadius _bubbleRadius() {
    const double full = 20.0;
    const double small = 4.0;

    if (widget.isMe) {
      // My messages: bottom-right is the tail corner
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(small),
        );
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(full),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(small),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(small),
        );
      }
    } else {
      // Other messages: bottom-left is the tail corner
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(small),
          bottomRight: Radius.circular(full),
        );
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(full),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(small),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(small),
          bottomRight: Radius.circular(full),
        );
      }
    }
  }

  // ---------- Lifecycle ----------

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _initSwipeAnimation();
    // Rehydrate the inline translation. Session cache first (fastest, also
    // covers the case where the user just translated). If empty, fall through
    // to the message's persisted translations[] — the backend saves every
    // translation to Mongo (Message.translations) and ships them down on the
    // conversation fetch, so a previously-translated message stays translated
    // across app restarts with no extra round-trip.
    _inlineTranslation = _inlineTranslationCache[widget.message.id];
    if (_inlineTranslation == null && widget.message.translations.isNotEmpty) {
      _rehydrateFromPersistedTranslations();
    }
    // Mark animation as done after first frame so subsequent rebuilds
    // (e.g. when a new message arrives) don't replay the slide-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hasAnimatedIn = true);
    });
  }

  void _initSwipeAnimation() {
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _swipeAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOut),
    );
    _swipeAnimController.addListener(() {
      setState(() {
        _swipeOffset = _swipeAnimation.value;
      });
    });
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _hideReactionPicker();
    _swipeAnimController.dispose();
    super.dispose();
  }

  // ---------- Swipe-to-reply ----------

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.isSelectionMode) return;
    final newOffset =
        (_swipeOffset + details.delta.dx).clamp(-_swipeThreshold * 1.5, 0.0);
    setState(() {
      _swipeOffset = newOffset;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isSelectionMode) return;
    if (_swipeOffset <= -_swipeThreshold) {
      HapticFeedback.mediumImpact();
      widget.onReply?.call(widget.message);
    }
    _swipeAnimation =
        Tween<double>(begin: _swipeOffset, end: 0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOut),
    );
    _swipeAnimController.forward(from: 0);
  }

  // ---------- Reaction picker ----------

  void _showReactionPicker(BuildContext context) {
    _hideReactionPicker();
    HapticFeedback.lightImpact();

    final RenderBox? renderBox =
        _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    const pickerHeight = 56.0;
    const pickerWidth = 260.0;
    final pickerY = position.dy - pickerHeight - 10;

    double pickerX;
    if (widget.isMe) {
      pickerX = (screenWidth - pickerWidth - 16)
          .clamp(16.0, screenWidth - pickerWidth - 16);
    } else {
      pickerX = 56.0;
    }

    _reactionPickerOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideReactionPicker,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: pickerX,
            top: pickerY > 0 ? pickerY : position.dy + size.height + 10,
            child: Material(
              color: Colors.transparent,
              child: ReactionPicker(
                onEmojiSelected: (emoji) {
                  _handleReactionTap(emoji);
                  _hideReactionPicker();
                },
                currentReactions: widget.message.reactions
                    .where((r) => r.user.id == _currentUserId)
                    .map((r) => r.emoji)
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reactionPickerOverlay!);
    Future.delayed(const Duration(seconds: 5), _hideReactionPicker);
  }

  void _hideReactionPicker() {
    _reactionPickerOverlay?.remove();
    _reactionPickerOverlay = null;
  }

  Future<void> _handleReactionTap(String emoji) async {
    if (_currentUserId == null) return;

    final existingReaction = widget.message.reactions.firstWhere(
      (r) => r.user.id == _currentUserId && r.emoji == emoji,
      orElse: () => MessageReaction(
        user: Community(
          id: '',
          name: '',
          email: '',
          bio: '',
          mbti: '',
          bloodType: '',
          images: [],
          birth_day: '',
          birth_month: '',
          gender: '',
          birth_year: '',
          native_language: '',
          language_to_learn: '',
          followers: [],
          followings: [],
          imageUrls: [],
          createdAt: '',
          version: 0,
          location: Location.defaultLocation(),
        ),
        emoji: '',
      ),
    );

    try {
      final messageService = ref.read(messageServiceProvider);
      if (existingReaction.emoji.isNotEmpty) {
        await messageService.removeReaction(
          messageId: widget.message.id,
          emoji: emoji,
        );
      } else {
        await messageService.addReaction(
          messageId: widget.message.id,
          emoji: emoji,
        );
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context,
            message: 'Failed to update reaction: $e',
            type: ChatSnackBarType.error);
      }
    }
  }

  // ---------- Translation ----------

  void _showTranslation(BuildContext context) {
    final text = widget.message.message;
    if (text == null || text.isEmpty) return;
    showTranslationBottomSheet(
      context,
      messageId: widget.message.id,
      originalText: text,
    );
  }

  // Look in widget.message.translations[] for an entry matching the user's
  // current target language and, if found, surface it without a network call.
  // Best-effort — silent on failure since the chip stays available for a tap.
  Future<void> _rehydrateFromPersistedTranslations() async {
    try {
      final target = (await _resolveTranslationTarget()).toLowerCase();
      if (!mounted) return;
      for (final t in widget.message.translations) {
        if (t.language.toLowerCase() == target &&
            t.translatedText.trim().isNotEmpty) {
          _inlineTranslationCache[widget.message.id] = t.translatedText;
          setState(() => _inlineTranslation = t.translatedText);
          return;
        }
      }
    } catch (_) {}
  }

  // Single tap-target under partner text messages. Opens a small action
  // sheet with Correct / Translate (or Hide translation) / Save phrase —
  // keeps the bubble visually clean while preserving discoverability.
  void _showQuickActionsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final hasInlineTranslation = _inlineTranslation != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.orange),
                title: Text(l10n.chatMessageCorrect),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showCorrectionBottomSheet(
                    context,
                    messageId: widget.message.id,
                    originalText: widget.message.message!,
                    senderName: widget.otherUserName,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  hasInlineTranslation
                      ? Icons.visibility_off_outlined
                      : Icons.translate_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  hasInlineTranslation
                      ? 'Hide translation'
                      : l10n.chatMessageTranslate,
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _toggleInlineTranslation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined,
                    color: Colors.purple),
                title: Text(l10n.chatMessageSavePhrase),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _saveMessageToVocab(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick inline translate: tap once to fetch + show under the bubble, tap
  // again to hide. Resolves the target to the current user's native_language
  // (authoritative path: Riverpod userProvider fed by /auth/me) before falling
  // back to TranslationService.getAutoTranslateLanguage()'s pref/device locale.
  Future<void> _toggleInlineTranslation() async {
    if (_inlineTranslating) return;
    if (_inlineTranslation != null) {
      // User explicitly hid the translation — drop it from the session cache
      // too so the next chat-room re-entry starts collapsed.
      _inlineTranslationCache.remove(widget.message.id);
      setState(() => _inlineTranslation = null);
      return;
    }
    final text = widget.message.message;
    if (text == null || text.isEmpty) return;

    setState(() => _inlineTranslating = true);
    try {
      final target = await _resolveTranslationTarget();
      final result = await TranslationService.translateMessage(
        messageId: widget.message.id,
        targetLanguage: target,
      );
      if (!mounted) return;
      // Backend's POST /messages/:id/translate (advancedMessages.translateMessage)
      // returns data.translatedText for both fresh and cached responses; the
      // older /translate/enhanced endpoint uses data.translation. Read both so
      // either source works.
      final translated = result['success'] == true
          ? ((result['data']?['translatedText'] ??
                  result['data']?['translation']) as String?)
              ?.trim()
          : null;
      final hasTranslation = translated != null && translated.isNotEmpty;
      if (hasTranslation) {
        _inlineTranslationCache[widget.message.id] = translated;
      }
      setState(() {
        _inlineTranslation = hasTranslation ? translated : null;
        _inlineTranslating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _inlineTranslating = false);
    }
  }

  // Pick the target language code for an inline translate, preferring the
  // freshest source. The Riverpod userProvider (fed by /auth/me) is the
  // authoritative answer; SharedPref caches and device locale are only
  // fallbacks for cases where /auth/me hasn't resolved yet. Strips any
  // regional suffix ("Chinese (Simplified)" → "Chinese") so users who picked
  // one of the expanded 127-language variants at signup still resolve to a
  // supported code instead of silently falling back to English.
  Future<String> _resolveTranslationTarget() async {
    final user = ref.read(userProvider).valueOrNull;
    final native = user?.native_language;
    if (native != null && native.trim().isNotEmpty) {
      final code = _codeForLanguageName(native);
      if (code != null) return code;
    }
    return TranslationService.getAutoTranslateLanguage();
  }

  String? _codeForLanguageName(String name) {
    final cleaned = name.trim().toLowerCase();
    final base = cleaned.contains('(')
        ? cleaned.split('(').first.trim()
        : cleaned;
    for (final candidate in {cleaned, base}) {
      for (final lang in TranslationService.supportedLanguages) {
        if (lang['name']!.toLowerCase() == candidate ||
            lang['code']!.toLowerCase() == candidate) {
          return lang['code'];
        }
      }
    }
    return null;
  }

  // ---------- Profile navigation ----------

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SingleCommunity(community: widget.message.sender),
      ),
    );
  }

  // ---------- Sending status ----------

  Widget _buildSendingStatus() {
    final status = widget.message.sendingStatus;

    if (status == MessageSendingStatus.none) return const SizedBox.shrink();

    if (status == MessageSendingStatus.sending) {
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_sendingColor(context)),
              ),
            ),
            Spacing.hGapXS,
            Text(
              'Sending...',
              style: context.captionSmall.copyWith(
                color: _sendingColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (status == MessageSendingStatus.failed) {
      return GestureDetector(
        onTap: () => _showFailedMessageOptions(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _failedColor(context).withValues(alpha: 0.1),
            borderRadius: AppRadius.borderSM,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 12, color: _failedColor(context)),
              Spacing.hGapXS,
              Text(
                'Failed · Tap for options',
                style: context.captionSmall.copyWith(
                  color: _failedColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showFailedMessageOptions(BuildContext context) {
    showFailedMessageOptions(
      context: context,
      message: widget.message,
      onRetry: () => widget.onRetry?.call(widget.message),
      onDelete: () => widget.onDeleteFailed?.call(widget.message),
    );
  }

  // ---------- Context menu ----------

  void _showContextMenu(BuildContext context) {
    _hideReactionPicker();
    HapticFeedback.mediumImpact();

    final RenderBox? renderBox =
        _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasText = widget.message.message != null &&
        widget.message.message!.isNotEmpty;

    bool canEdit = false;
    if (widget.isMe &&
        !widget.message.isDeleted &&
        widget.message.type == 'text') {
      try {
        final diff = DateTime.now()
            .difference(DateTime.parse(widget.message.createdAt));
        canEdit = diff.inMinutes < 15;
      } catch (_) {}
    }

    final menuItems = <MessageContextMenuItem>[];

    menuItems.add(MessageContextMenuItem(
      icon: Icons.reply_rounded,
      label: AppLocalizations.of(context)!.chatMessageReply,
      onTap: () {
        _hideReactionPicker();
        widget.onReply?.call(widget.message);
      },
    ));

    if (hasText) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.copy_rounded,
        label: AppLocalizations.of(context)!.chatMessageCopy,
        onTap: () {
          _hideReactionPicker();
          Clipboard.setData(ClipboardData(text: widget.message.message!));
          showChatSnackBar(context,
              message: 'Copied', type: ChatSnackBarType.success);
        },
      ));
    }

    if (hasText && !widget.isMe) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.spellcheck_rounded,
        label: AppLocalizations.of(context)!.chatMessageCorrect,
        // Orange — flags this as the "language-learning correction" action,
        // matches the quick-actions sheet styling.
        accentColor: const Color(0xFFFB923C),
        onTap: () {
          _hideReactionPicker();
          showCorrectionBottomSheet(
            context,
            messageId: widget.message.id,
            originalText: widget.message.message!,
            senderName: widget.otherUserName,
          );
        },
      ));
    }

    if (hasText) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.translate_rounded,
        label: AppLocalizations.of(context)!.chatMessageTranslate,
        // Primary purple — the brand's translate accent.
        accentColor: AppColors.primary,
        onTap: () {
          _hideReactionPicker();
          _showTranslation(context);
        },
      ));
    }

    if (hasText && widget.message.type == 'text') {
      menuItems.add(MessageContextMenuItem(
        // Filled star → unambiguous "save / favorite" affordance vs the
        // outlined bookmark icon (which read more like "page marker").
        icon: Icons.star_rounded,
        label: AppLocalizations.of(context)!.chatMessageSavePhrase,
        // Gold amber — matches the VIP / save-vocab visual identity.
        accentColor: const Color(0xFFF59E0B),
        onTap: () {
          _hideReactionPicker();
          _saveMessageToVocab(context);
        },
      ));
    }

    menuItems.add(MessageContextMenuItem(
      icon: widget.message.isPinned
          ? Icons.push_pin_outlined
          : Icons.push_pin_rounded,
      label: widget.message.isPinned ? 'Unpin' : 'Pin',
      onTap: () {
        _hideReactionPicker();
        if (widget.message.isPinned) {
          widget.onUnpin?.call(widget.message);
        } else {
          widget.onPin?.call(widget.message);
        }
      },
    ));

    if (canEdit) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.edit_rounded,
        label: AppLocalizations.of(context)!.chatMessageEdit,
        onTap: () {
          _hideReactionPicker();
          widget.onEdit?.call(widget.message);
        },
      ));
    }

    // Forward — works for any non-deleted message regardless of sender.
    if (!widget.message.isDeleted) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.forward_rounded,
        label: AppLocalizations.of(context)!.forward,
        onTap: () {
          _hideReactionPicker();
          widget.onForward?.call(widget.message);
        },
      ));
    }

    if (widget.isMe && !widget.message.isDeleted) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.delete_rounded,
        label: AppLocalizations.of(context)!.chatMessageDelete,
        isDestructive: true,
        onTap: () {
          _hideReactionPicker();
          widget.onDelete?.call(widget.message);
        },
      ));
    }

    // KakaoTalk-style layout: dim the rest of the chat, float the reaction
    // picker just above the bubble, and stack the action list just below.
    // Both share one overlay so a single backdrop-tap dismisses everything.
    const reactionPickerHeight = 56.0;
    // Picker spans most of the screen width — the internal Row scrolls
    // horizontally past the first few emojis so the full 16-reaction set
    // is reachable on any screen size.
    final reactionPickerWidth = screenSize.width - 32;
    const reactionGap = 10.0;
    const itemHeight = 48.0;
    const menuPaddingV = 8.0;
    const menuGap = 10.0;
    final menuHeight =
        (menuItems.length * itemHeight) + (menuPaddingV * 2);
    const menuWidth = 220.0;

    // Layout strategy — keep reaction picker and action menu on OPPOSITE
    // sides of the bubble so they never overlap. Pick the side per pane
    // based on available space; if both can't fit on their preferred side
    // they swap (menu above, reactions below).
    double reactionX;
    if (widget.isMe) {
      reactionX = (position.dx + size.width - reactionPickerWidth)
          .clamp(8.0, screenSize.width - reactionPickerWidth - 8);
    } else {
      reactionX =
          position.dx.clamp(8.0, screenSize.width - reactionPickerWidth - 8);
    }
    double menuX;
    if (widget.isMe) {
      menuX = (position.dx + size.width - menuWidth)
          .clamp(8.0, screenSize.width - menuWidth - 8);
    } else {
      menuX = position.dx.clamp(8.0, screenSize.width - menuWidth - 8);
    }

    final spaceAbove = position.dy - 60;
    final spaceBelow = screenSize.height - (position.dy + size.height) - 40;
    final menuFitsBelow = menuHeight + menuGap <= spaceBelow;
    final reactionFitsAbove =
        reactionPickerHeight + reactionGap <= spaceAbove;

    final double reactionY;
    final double menuY;
    if (menuFitsBelow && reactionFitsAbove) {
      // Ideal: reactions above, menu below.
      reactionY = position.dy - reactionPickerHeight - reactionGap;
      menuY = position.dy + size.height + menuGap;
    } else if (!menuFitsBelow && reactionFitsAbove) {
      // No room below — menu above, reactions even higher.
      menuY = (position.dy - menuHeight - menuGap)
          .clamp(40.0, screenSize.height - menuHeight - 40);
      reactionY = (menuY - reactionPickerHeight - reactionGap)
          .clamp(40.0, screenSize.height - reactionPickerHeight - 40);
    } else if (menuFitsBelow && !reactionFitsAbove) {
      // No room above — reactions below the menu.
      menuY = position.dy + size.height + menuGap;
      reactionY = (menuY + menuHeight + reactionGap)
          .clamp(40.0, screenSize.height - reactionPickerHeight - 40);
    } else {
      // Neither side fits comfortably — center the pair vertically and let
      // the menu sit above the reactions (most-used items closest to thumb).
      menuY = ((screenSize.height -
                  menuHeight -
                  reactionGap -
                  reactionPickerHeight) /
              2)
          .clamp(40.0, screenSize.height - menuHeight - 40);
      reactionY = menuY + menuHeight + reactionGap;
    }

    _reactionPickerOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dimmed backdrop — tap anywhere dismisses the combined sheet.
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideReactionPicker,
              child:
                  Container(color: AppColors.black.withValues(alpha: 0.35)),
            ),
          ),
          // Reaction picker — quick taps for ❤️ / 👍 / 😂 / 😮 / 😢 / 🙏.
          Positioned(
            left: reactionX,
            top: reactionY,
            child: Material(
              color: Colors.transparent,
              child: ReactionPicker(
                onEmojiSelected: (emoji) {
                  _handleReactionTap(emoji);
                  _hideReactionPicker();
                },
                currentReactions: widget.message.reactions
                    .where((r) => r.user.id == _currentUserId)
                    .map((r) => r.emoji)
                    .toList(),
              ),
            ),
          ),
          // Action list — KakaoTalk-style vertical menu of full actions.
          Positioned(
            left: menuX,
            top: menuY,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: menuWidth,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: menuPaddingV),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: menuItems.map((item) {
                    // Default label color (greyscale). Accent items override
                    // the icon + iconBg with their own color but keep the
                    // label readable so the row still scans like a list.
                    final labelColor = item.isDestructive
                        ? AppColors.error
                        : (isDark
                            ? AppColors.gray200
                            : AppColors.gray900);
                    final iconColor = item.isDestructive
                        ? AppColors.error
                        : (item.accentColor ?? labelColor);
                    final hasAccent = item.accentColor != null;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        item.onTap();
                      },
                      child: Container(
                        height: itemHeight,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Filled circular icon chip — makes the
                            // language-learning actions pop without
                            // crowding the row.
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: hasAccent
                                    ? iconColor.withValues(alpha: 0.14)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.icon,
                                  size: 18, color: iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasAccent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: hasAccent ? iconColor : labelColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reactionPickerOverlay!);
  }

  // ---------- Save-phrase-to-vocab helpers ----------

  /// Returns the first word of [text], capped at 30 chars.
  String _previewWord(String text) {
    final firstWord = text.trim().split(RegExp(r'\s+')).first;
    if (firstWord.length > 30) return '${firstWord.substring(0, 27)}…';
    return firstWord;
  }

  Future<void> _saveMessageToVocab(BuildContext ctx) async {
    final l10n = AppLocalizations.of(context)!;
    final text = widget.message.message ?? '';
    if (text.isEmpty) return;

    // Cap phrase at 100 chars.
    final phrase = text.length > 100 ? '${text.substring(0, 97)}…' : text;

    // Resolve native language name → BCP-47 code.
    final prefs = await SharedPreferences.getInstance();
    final nativeLangName = prefs.getString('user_native_language') ?? 'English';
    final targetCode = TranslationService.supportedLanguages
            .firstWhere(
              (l) =>
                  l['name']!.toLowerCase() == nativeLangName.toLowerCase(),
              orElse: () => {'code': 'en'},
            )['code'] ??
        'en';

    // Fetch translation preview (best-effort).
    String? translation;
    try {
      translation = await TranslationService.translateWord(
        word: phrase,
        targetLanguage: targetCode,
      );
    } catch (_) {
      translation = null;
    }

    if (!mounted) return;

    // Confirm dialog.
    final titlePreview = _previewWord(phrase);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.saveToVocabulary(titlePreview)),
        content: Text(translation ?? phrase),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await LearningService.addVocabulary(
      word: phrase,
      translation: translation ?? phrase,
      language: 'auto',
      exampleSentence: text != phrase ? text : null,
    );

    if (!mounted) return;

    final success = result['success'] == true;
    showChatSnackBar(
      context,
      message: success ? l10n.addedToVocabulary : l10n.alreadyInVocabulary,
      type: success ? ChatSnackBarType.success : ChatSnackBarType.info,
    );
  }

  // ---------- Quick-actions chip ----------

  /// Small circular chip rendered to the right of partner text bubbles.
  /// Tap opens the Correct / Translate / Save Phrase sheet. The sparkle
  /// icon gets a dot overlay when an inline translation is cached.
  Widget _buildQuickActionsChip(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showQuickActionsSheet(context),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: _inlineTranslating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    if (_inlineTranslation != null)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------- Message content dispatcher ----------

  Widget _buildMessageContent(Message msg) {
    // Voice / audio: has media with voice|audio type
    if (msg.media != null &&
        (msg.media!.type == 'voice' || msg.media!.type == 'audio')) {
      return VoiceMessageView(
        message: msg,
        isMe: widget.isMe,
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // GIF: type field is 'gif' and message text is a URL
    if (msg.type == 'gif') {
      return GifMessageView(
        message: msg,
        isMe: widget.isMe,
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // Image / video / document / location: has media (non-voice)
    if (msg.media != null) {
      return ImageMessageView(
        message: msg,
        isMe: widget.isMe,
        myMessageColor: _myMessageColor(context),
        otherMessageColor: _otherMessageColor(context),
        myTextColor: _myTextColor(context),
        otherTextColor: _otherTextColor(context),
        timestampColor: _timestampColor(context),
        bubbleRadius: _bubbleRadius(),
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // Text (default — includes stickers, wave sticker, link preview).
    // Stickers come over the wire with type='sticker' (see chat_conversation_screen
    // _sendMessage); TextMessageView already detects single-emoji content and
    // renders it large without a bubble, so we just route the same view.
    if (msg.type == 'text' || msg.type == 'sticker' || msg.type.isEmpty) {
      // For received messages, the sender's user ID doubles as the
      // conversation key (consistent with ChatOptionsMenu / ChatAppBar).
      final convId = widget.isMe ? null : msg.sender.id;
      return TextMessageView(
        message: msg,
        isMe: widget.isMe,
        myMessageColor: _myMessageColor(context),
        otherMessageColor: _otherMessageColor(context),
        myTextColor: _myTextColor(context),
        otherTextColor: _otherTextColor(context),
        bubbleRadius: _bubbleRadius(),
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
        conversationId: convId,
      );
    }

    // Unknown type — safe fallback
    return SystemBubble(text: 'Unsupported message type');
  }

  // ---------- Build ----------

  Widget _buildBubbleContent(BuildContext context) {
    final swipeProgress = _swipeOffset.abs();
    final replyIconOpacity =
        (swipeProgress / _swipeThreshold).clamp(0.0, 1.0);
    final replyIconScale =
        (0.5 + (replyIconOpacity * 0.5)).clamp(0.5, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: widget.isSelectionMode
          ? () {
              widget.onSelectionChanged
                  ?.call(widget.message, !widget.isSelected);
            }
          : () => _showContextMenu(context),
      // Double tap → quick ❤️ reaction (Telegram / iMessage pattern).
      // Toggle: if the user already reacted with ❤️ it's removed, otherwise
      // added. The full picker stays one long-press away.
      onDoubleTap: widget.isSelectionMode
          ? null
          : () {
              HapticFeedback.lightImpact();
              _handleReactionTap('❤️');
            },
      // Single tap is intentionally a near no-op: dismisses the floating
      // reaction picker if it's open, or toggles selection in select-mode.
      // Reading a message shouldn't pop UI on every accidental thumb tap —
      // reactions move to double-tap, full menu to long-press.
      onTap: widget.isSelectionMode
          ? () {
              widget.onSelectionChanged
                  ?.call(widget.message, !widget.isSelected);
            }
          : _hideReactionPicker,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Reply icon (shown while swiping left)
          if (_swipeOffset < 0)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform.scale(
                  scale: replyIconScale,
                  child: Opacity(
                    opacity: replyIconOpacity,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: swipeProgress >= _swipeThreshold
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.reply_rounded,
                        color: swipeProgress >= _swipeThreshold
                            ? AppColors.white
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Message content with swipe transform
          Transform.translate(
            offset: Offset(_swipeOffset, 0),
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: (!widget.isFirstInGroup || !widget.isLastInGroup)
                    ? 1
                    : 3,
                horizontal: widget.isSelectionMode ? 4 : 16,
              ),
              decoration: widget.isSelectionMode
                  ? BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: AppRadius.borderSM,
                    )
                  : null,
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: widget.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Selection checkbox
                      if (widget.isSelectionMode) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Checkbox(
                            value: widget.isSelected,
                            onChanged: (value) {
                              widget.onSelectionChanged?.call(
                                  widget.message, value ?? false);
                            },
                          ),
                        ),
                      ],

                      // Avatar for other user
                      if (!widget.isMe && !widget.isSelectionMode) ...[
                        if (widget.isLastInGroup)
                          GestureDetector(
                            onTap: () => _navigateToProfile(context),
                            child: UserAvatar(
                              profilePicture: widget.otherUserPicture,
                              userName: widget.otherUserName,
                              radius: 18,
                              nativeLanguage: widget.otherUserNativeLanguage,
                            ),
                          )
                        else
                          const SizedBox(width: 36),
                        Spacing.hGapSM,
                      ],

                      // Timestamp + status (left of my messages)
                      if (widget.isMe &&
                          !widget.isSelectionMode &&
                          widget.isLastInGroup)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 4, bottom: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildSendingStatus(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatMessageTime(
                                        widget.message.createdAt),
                                    style: context.captionSmall.copyWith(
                                      color: widget.message.isFailed
                                          ? _failedColor(context)
                                          : _timestampColor(context),
                                    ),
                                  ),
                                  if (widget.message.sendingStatus ==
                                      MessageSendingStatus.none) ...[
                                    Spacing.hGapXXS,
                                    Icon(
                                      widget.message.read
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: widget.message.read
                                          ? _myMessageColor(context)
                                          : _timestampColor(context),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Message bubble content
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: widget.isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (widget.message.isForwarded)
                                ForwardedMessageIndicator(
                                  forwardedFrom:
                                      widget.message.forwardedFrom,
                                  isMe: widget.isMe,
                                ),
                              Stack(
                                key: _bubbleKey,
                                children: [
                                  _buildMessageContent(widget.message),
                                  // Pin indicator
                                  if (widget.message.isPinned)
                                    Positioned(
                                      top: 4,
                                      right: widget.isMe ? 4 : null,
                                      left: widget.isMe ? null : 4,
                                      child: Icon(
                                        Icons.push_pin_rounded,
                                        size: 14,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick-actions trigger — small circular chip attached
                      // to the right side of partner text bubbles. Opens
                      // Correct / Translate / Save Phrase. Position keeps it
                      // close to the message instead of taking its own row.
                      if (!widget.isMe &&
                          !widget.message.isDeleted &&
                          widget.message.type == 'text' &&
                          widget.message.message != null &&
                          widget.message.message!.isNotEmpty &&
                          !widget.isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 2),
                          child: _buildQuickActionsChip(context),
                        ),

                      // Timestamp (right of other user's messages)
                      if (!widget.isMe &&
                          !widget.isSelectionMode &&
                          widget.isLastInGroup)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text(
                            formatMessageTime(widget.message.createdAt),
                            style: context.captionSmall.copyWith(
                              color: _timestampColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Reactions below the message row
                  if (widget.message.reactions.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2,
                        left: !widget.isMe && !widget.isSelectionMode
                            ? 44
                            : 0,
                      ),
                      child: MessageReactionWidget(
                        reactions: widget.message.reactions,
                        currentUserId: _currentUserId,
                        onReactionTap: (emoji) =>
                            _handleReactionTap(emoji),
                      ),
                    ),

                  // Inline translation panel — shown only after a successful fetch.
                  if (!widget.isMe &&
                      !widget.message.isDeleted &&
                      widget.message.type == 'text' &&
                      widget.message.message != null &&
                      widget.message.message!.isNotEmpty &&
                      !widget.isSelectionMode) ...[
                    if (_inlineTranslation != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 6, left: 52, right: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.06),
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _inlineTranslation!,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                              color: context.isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    // After the first frame the flag is set — skip animation on every
    // subsequent rebuild (e.g. when a new message arrives in the list).
    if (_hasAnimatedIn) {
      return _buildBubbleContent(context);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(widget.isMe ? (1 - value) * 16 : (1 - value) * -16, 0),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: _buildBubbleContent(context),
    );
  }
}

