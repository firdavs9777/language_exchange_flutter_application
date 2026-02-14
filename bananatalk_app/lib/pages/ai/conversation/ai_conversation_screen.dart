import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/models/ai/ai_conversation_model.dart';
import 'package:bananatalk_app/pages/ai/conversation/topic_selection_sheet.dart';
import 'package:bananatalk_app/pages/ai/conversation/conversation_history_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// AI Conversation Chat Screen
class AIConversationScreen extends ConsumerStatefulWidget {
  const AIConversationScreen({super.key});

  @override
  ConsumerState<AIConversationScreen> createState() => _AIConversationScreenState();
}

class _AIConversationScreenState extends ConsumerState<AIConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _messageStartTime;
  bool _isCreatingConversation = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final responseTime = _messageStartTime != null
        ? DateTime.now().difference(_messageStartTime!).inSeconds
        : null;

    _messageController.clear();
    _messageStartTime = null;

    final success = await ref.read(conversationProvider.notifier).sendMessage(
      content,
      responseTime: responseTime,
    );

    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _showTopicSelection() async {
    final result = await showModalBottomSheet<StartConversationRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TopicSelectionSheet(),
    );

    if (result != null) {
      setState(() => _isCreatingConversation = true);

      try {
        final success = await ref.read(conversationProvider.notifier).startConversation(result);
        if (success) {
          _scrollToBottom();
        }
      } finally {
        if (mounted) {
          setState(() => _isCreatingConversation = false);
        }
      }
    }
  }

  Future<void> _endConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Conversation?'),
        content: const Text('This will end the current conversation and show your summary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final summary = await ref.read(conversationProvider.notifier).endConversation();
      if (summary != null && mounted) {
        _showSummaryDialog(summary);
      }
    }
  }

  void _showSummaryDialog(ConversationSummary summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow('Duration', '${summary.duration ~/ 60} min'),
              _buildSummaryRow('Messages', '${summary.messagesCount}'),
              _buildSummaryRow('Fluency Score', '${summary.fluencyScore}'),
              if (summary.xpEarned > 0)
                _buildSummaryRow('XP Earned', '+${summary.xpEarned}'),
              const SizedBox(height: 12),
              const Text(
                'Feedback',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                summary.feedback,
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (summary.improvements.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Areas to Improve',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...summary.improvements.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(i)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    final languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ru': 'Russian',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'tr': 'Turkish',
      'nl': 'Dutch',
      'pl': 'Polish',
      'vi': 'Vietnamese',
      'th': 'Thai',
      'sv': 'Swedish',
      'da': 'Danish',
      'fi': 'Finnish',
      'no': 'Norwegian',
      'cs': 'Czech',
      'el': 'Greek',
      'he': 'Hebrew',
      'id': 'Indonesian',
      'ms': 'Malay',
      'ro': 'Romanian',
      'uk': 'Ukrainian',
      'hu': 'Hungarian',
      'bn': 'Bengali',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Tutor',
              style: context.titleMedium,
            ),
            if (state.conversation != null)
              Text(
                '${_getLanguageName(state.conversation!.targetLanguage)} - ${state.conversation!.cefrLevel}',
                style: context.caption,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: context.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConversationHistoryScreen(),
                ),
              );
            },
          ),
          if (state.conversation != null)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: AppColors.error),
              onPressed: _endConversation,
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: state.conversation == null
                ? _buildStartPrompt()
                : _buildMessagesList(state),
          ),

          // Input Bar
          if (state.conversation != null) _buildInputBar(state),
        ],
      ),
    );
  }

  Widget _buildStartPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: AppRadius.borderXXL,
              ),
              child: _isCreatingConversation
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(
                      Icons.smart_toy_rounded,
                      size: 50,
                      color: AppColors.accent,
                    ),
            ),
            Spacing.gapXXL,
            Text(
              _isCreatingConversation
                  ? 'Starting Conversation...'
                  : 'Start a Conversation',
              style: context.displaySmall,
            ),
            Spacing.gapSM,
            Text(
              _isCreatingConversation
                  ? 'Please wait while we set up your conversation.'
                  : 'Practice speaking with your AI tutor.\nChoose a topic to begin.',
              textAlign: TextAlign.center,
              style: context.bodySmall,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isCreatingConversation ? null : _showTopicSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: _isCreatingConversation
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Choose Topic',
                      style: context.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(ConversationState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: Spacing.paddingLG,
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length && state.isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(state.messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withOpacity(0.1),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            Spacing.hGapSM,
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.accent : context.cardBackground,
                    borderRadius: isUser ? AppRadius.chatBubbleMine : AppRadius.chatBubbleOther,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Text(
                    message.content,
                    style: context.bodyMedium.copyWith(
                      color: isUser ? Colors.white : context.textPrimary,
                    ),
                  ),
                ),
                // Grammar feedback for user messages
                if (isUser && message.feedback != null)
                  _buildFeedbackSection(message.feedback!),
              ],
            ),
          ),
          if (isUser) Spacing.hGapSM,
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(MessageFeedback feedback) {
    if (feedback.corrections.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: Spacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppColors.warning,
              ),
              Spacing.hGapXS,
              Text(
                'Grammar Feedback',
                style: context.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          Spacing.gapSM,
          ...feedback.corrections.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.original} → ',
                  style: context.bodySmall.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.error,
                  ),
                ),
                Expanded(
                  child: Text(
                    c.corrected,
                    style: context.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.accent.withOpacity(0.1),
          child: const Icon(
            Icons.smart_toy_rounded,
            size: 18,
            color: AppColors.accent,
          ),
        ),
        Spacing.hGapSM,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: AppRadius.borderLG,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              Spacing.hGapXS,
              _buildTypingDot(1),
              Spacing.hGapXS,
              _buildTypingDot(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.gray400.withOpacity(0.5 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputBar(ConversationState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onTap: () {
                _messageStartTime ??= DateTime.now();
              },
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: context.bodyMedium.copyWith(color: context.textHint),
                filled: true,
                fillColor: context.containerColor,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRound,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Spacing.hGapSM,
          Container(
            decoration: BoxDecoration(
              color: state.isLoading ? AppColors.gray300 : AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              color: Colors.white,
              onPressed: state.isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
