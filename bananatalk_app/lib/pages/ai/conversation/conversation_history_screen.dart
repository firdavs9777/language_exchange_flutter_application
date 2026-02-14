import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/models/ai/ai_conversation_model.dart';
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Screen showing conversation history
class ConversationHistoryScreen extends ConsumerStatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  ConsumerState<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState
    extends ConsumerState<ConversationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conversation History',
          style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'In Progress'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList('completed'),
          _buildConversationList('active'),
        ],
      ),
    );
  }

  Widget _buildConversationList(String status) {
    final historyAsync = ref.watch(conversationHistoryProvider(status));

    return historyAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return _buildEmptyState(status);
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(conversationHistoryProvider(status));
          },
          child: ListView.builder(
            padding: Spacing.paddingLG,
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationCard(conversations[index]);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textMuted),
            Spacing.gapMD,
            Text(
              'Failed to load history',
              style: context.bodyMedium?.copyWith(color: context.textSecondary),
            ),
            Spacing.gapMD,
            ElevatedButton(
              onPressed: () {
                ref.invalidate(conversationHistoryProvider(status));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(AIConversation conversation) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderMD,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // View conversation details
            _showConversationDetails(conversation);
          },
          borderRadius: AppRadius.borderMD,
          child: Padding(
            padding: Spacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: AppRadius.borderSM,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    Spacing.hGapMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.settings.level.toUpperCase(),
                            style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            dateFormat.format(conversation.createdAt),
                            style: context.caption?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: conversation.isCompleted
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: AppRadius.borderMD,
                      ),
                      child: Text(
                        conversation.status,
                        style: context.caption?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: conversation.isCompleted
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                if (conversation.messages.isNotEmpty) ...[
                  Spacing.gapMD,
                  Container(
                    padding: Spacing.paddingMD,
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: AppRadius.borderSM,
                    ),
                    child: Text(
                      conversation.messages.last.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall?.copyWith(
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                Spacing.gapMD,
                Row(
                  children: [
                    Icon(
                      Icons.message_rounded,
                      size: 14,
                      color: context.textMuted,
                    ),
                    Spacing.hGapXS,
                    Text(
                      '${conversation.messages.length} messages',
                      style: context.caption?.copyWith(color: context.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      timeFormat.format(conversation.createdAt),
                      style: context.caption?.copyWith(color: context.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConversationDetails(AIConversation conversation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConversationDetailsSheet(
        conversationId: conversation.id,
        initialMessages: conversation.messages,
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: context.textMuted,
          ),
          Spacing.gapMD,
          Text(
            status == 'completed'
                ? 'No completed conversations'
                : 'No active conversations',
            style: context.bodyLarge?.copyWith(color: context.textSecondary),
          ),
          Spacing.gapSM,
          Text(
            'Start a new conversation to see it here',
            style: context.bodyMedium?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to show conversation details with messages
class _ConversationDetailsSheet extends StatefulWidget {
  final String conversationId;
  final List<AIMessage> initialMessages;

  const _ConversationDetailsSheet({
    required this.conversationId,
    required this.initialMessages,
  });

  @override
  State<_ConversationDetailsSheet> createState() =>
      _ConversationDetailsSheetState();
}

class _ConversationDetailsSheetState extends State<_ConversationDetailsSheet> {
  List<AIMessage> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messages = widget.initialMessages;
    _loadConversationDetails();
  }

  Future<void> _loadConversationDetails() async {
    try {
      final result = await AIService.getConversation(widget.conversationId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        AIConversation? conversation;

        if (data is AIConversation) {
          conversation = data;
        } else if (data is Map) {
          conversation =
              AIConversation.fromJson(Map<String, dynamic>.from(data));
        }

        if (conversation != null && mounted) {
          setState(() {
            _messages = conversation!.messages;
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_messages.isEmpty) {
            _error = 'No messages found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load conversation';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: AppRadius.borderXS,
                ),
              ),
              Padding(
                padding: Spacing.paddingXL,
                child: Row(
                  children: [
                    Text(
                      'Conversation',
                      style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            Spacing.gapMD,
            Text(
              'Loading messages...',
              style: context.bodyMedium?.copyWith(color: context.textMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textMuted),
            Spacing.gapMD,
            Text(
              _error!,
              style: context.bodyMedium?.copyWith(color: context.textSecondary),
            ),
            Spacing.gapMD,
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadConversationDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: context.textMuted),
            Spacing.gapMD,
            Text(
              'No messages in this conversation',
              style: context.bodyMedium?.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.role == 'user';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                Spacing.hGapSM,
              ],
              Flexible(
                child: Container(
                  padding: Spacing.paddingMD,
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.accent : context.containerColor,
                    borderRadius: isUser ? AppRadius.chatBubbleMine : AppRadius.chatBubbleOther,
                  ),
                  child: Text(
                    message.content,
                    style: context.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : context.textPrimary,
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
}
