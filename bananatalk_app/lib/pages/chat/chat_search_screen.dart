import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/utils/time_utils.dart';

class ChatSearchScreen extends StatefulWidget {
  final String? conversationId;
  final String? senderId;
  final String? receiverId;
  final String otherUserName;
  final Function(Message)? onMessageTap;

  const ChatSearchScreen({
    Key? key,
    this.conversationId,
    this.senderId,
    this.receiverId,
    required this.otherUserName,
    this.onMessageTap,
  }) : super(key: key);

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ConversationService _conversationService = ConversationService();
  
  List<Message> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
        _error = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _searchQuery = query;
    });

    try {
      final result = await _conversationService.searchMessages(
        query: query,
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _searchResults = result['data'] as List<Message>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'] ?? 'Search failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Search failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = parseToKoreaTime(dateString);
      final now = getKoreaNow();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(date);
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  /// Highlight matching text in the message
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: Colors.grey[600]),
        children: [
          if (matchIndex > 0)
            TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFEB3B),
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchInChatWith(widget.otherUserName),
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search messages',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter keywords to find messages',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        return _buildSearchResultItem(message);
      },
    );
  }

  Widget _buildSearchResultItem(Message message) {
    final messageText = message.message ?? '[Media]';
    final senderName = message.sender.name ?? 'Unknown';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: message.sender.images?.isNotEmpty == true
            ? NetworkImage(message.sender.images!.first)
            : null,
        child: message.sender.images?.isEmpty != false
            ? Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(
            senderName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDate(message.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _buildHighlightedText(messageText, _searchQuery),
      ),
      onTap: () {
        if (widget.onMessageTap != null) {
          widget.onMessageTap!(message);
        }
        Navigator.pop(context, message);
      },
    );
  }
}

