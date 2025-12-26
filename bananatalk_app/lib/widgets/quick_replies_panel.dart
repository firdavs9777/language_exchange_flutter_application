import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/conversation_service.dart';

class QuickRepliesPanel extends StatefulWidget {
  final String conversationId;
  final Function(String text)? onQuickReplySelected;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const QuickRepliesPanel({
    Key? key,
    required this.conversationId,
    this.onQuickReplySelected,
    this.isExpanded = false,
    this.onToggleExpand,
  }) : super(key: key);

  @override
  State<QuickRepliesPanel> createState() => _QuickRepliesPanelState();
}

class _QuickRepliesPanelState extends State<QuickRepliesPanel> {
  final ConversationService _conversationService = ConversationService();
  List<QuickReply> _quickReplies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuickReplies();
  }

  Future<void> _loadQuickReplies() async {
    setState(() => _isLoading = true);

    try {
      final result = await _conversationService.getQuickReplies(
        conversationId: widget.conversationId,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _quickReplies = result['data'] as List<QuickReply>;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addQuickReply(String text) async {
    try {
      final result = await _conversationService.addQuickReply(
        conversationId: widget.conversationId,
        text: text,
      );

      if (mounted) {
        if (result['success'] == true) {
          await _loadQuickReplies();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick reply added')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to add quick reply'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuickReply(QuickReply reply) async {
    try {
      final result = await _conversationService.deleteQuickReply(
        conversationId: widget.conversationId,
        replyId: reply.id,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _quickReplies.removeWhere((r) => r.id == reply.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick reply deleted')),
          );
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _showAddQuickReplyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quick Reply'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter quick reply text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                _addQuickReply(text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showManageQuickRepliesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Quick Replies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddQuickReplyDialog();
                    },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _quickReplies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quickreply_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quick replies yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddQuickReplyDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add one'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _quickReplies.length,
                      itemBuilder: (context, index) {
                        final reply = _quickReplies[index];
                        return ListTile(
                          title: Text(reply.text),
                          subtitle: Text('Used ${reply.useCount} times'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteQuickReply(reply),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onQuickReplySelected?.call(reply.text);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_quickReplies.isEmpty && !widget.isExpanded) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.isExpanded ? 100 : 44,
      child: widget.isExpanded
          ? _buildExpandedPanel()
          : _buildCollapsedPanel(),
    );
  }

  Widget _buildCollapsedPanel() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _quickReplies.length + 1,
        itemBuilder: (context, index) {
          if (index == _quickReplies.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: _showAddQuickReplyDialog,
              ),
            );
          }

          final reply = _quickReplies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                reply.text.length > 25
                    ? '${reply.text.substring(0, 25)}...'
                    : reply.text,
              ),
              onPressed: () => widget.onQuickReplySelected?.call(reply.text),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Quick Replies',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showManageQuickRepliesSheet,
                  child: const Text('Manage'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                final reply = _quickReplies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(reply.text),
                    onPressed: () => widget.onQuickReplySelected?.call(reply.text),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick reply button for chat input
class QuickReplyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool hasQuickReplies;

  const QuickReplyButton({
    Key? key,
    this.onPressed,
    this.hasQuickReplies = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.quickreply_outlined),
          if (hasQuickReplies)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onPressed: onPressed,
      tooltip: 'Quick replies',
    );
  }
}

