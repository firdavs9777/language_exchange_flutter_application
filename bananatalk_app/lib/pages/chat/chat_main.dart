import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Chat partner model to organize conversations
class ChatPartner {
  final String id;
  final String name;
  final String? avatar;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageTime;
  final List<String> imageUrls;

  ChatPartner({
    required this.id,
    required this.name,
    this.avatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.imageUrls = const [],
  });
}

class ChatMain extends ConsumerStatefulWidget {
  const ChatMain({super.key});

  @override
  ConsumerState<ChatMain> createState() => _ChatMainState();
}

class _ChatMainState extends ConsumerState<ChatMain> {
  late Future<List<Message>> _messagesFuture;
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  List<ChatPartner> _chatPartners = [];
  String? _currentUserId;
  String? _activeUserId;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messageService = ref.read(messageServiceProvider);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      _currentUserId = userId;
      print(userId);

      _messagesFuture = messageService.getUserMessages(id: userId);
      final messages = await _messagesFuture;
      _processChatPartners(messages);
    } catch (error) {
      setState(() {
        _error = 'Failed to load messages: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processChatPartners(List<Message> messages) {
    if (_currentUserId == null) return;

    Map<String, ChatPartner> partnersMap = {};

    for (Message message in messages) {
      // Determine the other user in the conversation
      bool isSender = message.sender.id == _currentUserId;
      var otherUser = isSender ? message.receiver : message.sender;

      bool isIncoming = message.sender.id != _currentUserId;
      bool isUnread = isIncoming && !message.read;

      DateTime messageDate = DateTime.parse(message.createdAt);

      ChatPartner? existingPartner = partnersMap[otherUser.id];

      if (existingPartner == null) {
        partnersMap[otherUser.id] = ChatPartner(
          id: otherUser.id,
          name: otherUser.name,
          avatar:
              otherUser.imageUrls.isNotEmpty ? otherUser.imageUrls[0] : null,
          lastMessage: message.message,
          unreadCount: isUnread ? 1 : 0,
          lastMessageTime: messageDate,
          imageUrls: otherUser.imageUrls,
        );
      } else {
        // Update if this message is newer
        if (existingPartner.lastMessageTime == null ||
            messageDate.isAfter(existingPartner.lastMessageTime!)) {
          int currentUnreadCount = existingPartner.unreadCount;
          if (isUnread) currentUnreadCount += 1;

          partnersMap[otherUser.id] = ChatPartner(
            id: existingPartner.id,
            name: existingPartner.name,
            avatar: existingPartner.avatar,
            lastMessage: message.message,
            unreadCount: currentUnreadCount,
            lastMessageTime: messageDate,
            imageUrls: existingPartner.imageUrls,
          );
        } else if (isUnread) {
          // Just increment unread count for older messages
          partnersMap[otherUser.id] = ChatPartner(
            id: existingPartner.id,
            name: existingPartner.name,
            avatar: existingPartner.avatar,
            lastMessage: existingPartner.lastMessage,
            unreadCount: existingPartner.unreadCount + 1,
            lastMessageTime: existingPartner.lastMessageTime,
            imageUrls: existingPartner.imageUrls,
          );
        }
      }
    }

    // Sort by most recent message time
    List<ChatPartner> sortedPartners = partnersMap.values.toList();
    sortedPartners.sort((a, b) {
      int aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      int bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _chatPartners = sortedPartners;
    });
  }

  List<ChatPartner> get _filteredChatPartners {
    if (_searchQuery.trim().isEmpty) return _chatPartners;

    String normalizedQuery = _searchQuery.toLowerCase().trim();

    return _chatPartners.where((partner) {
      // Search by name
      if (partner.name.toLowerCase().contains(normalizedQuery)) return true;

      // Search by message content
      if (partner.lastMessage?.toLowerCase().contains(normalizedQuery) ==
          true) {
        return true;
      }

      return false;
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = '';
    });
    await _fetchMessages();
  }

  void _onSelectUser(String userId, String userName, String? profilePicture) {
    setState(() {
      _activeUserId = userId;
    });

    // Navigate to individual chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userId: userId,
          userName: userName,
          profilePicture: profilePicture,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildUsersList() {
    List<ChatPartner> displayPartners = _filteredChatPartners;

    if (_searchQuery.isNotEmpty && displayPartners.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No matching conversations found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (displayPartners.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No conversations found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayPartners.length,
      itemBuilder: (context, index) {
        final partner = displayPartners[index];
        bool isActive = _activeUserId == partner.id;

        return Container(
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: ListTile(
            onTap: () =>
                _onSelectUser(partner.id, partner.name, partner.avatar),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: partner.avatar != null && partner.avatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        partner.avatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: Text(
                              partner.name.isNotEmpty
                                  ? partner.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      partner.name.isNotEmpty
                          ? partner.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    partner.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (partner.lastMessageTime != null)
                  Text(
                    _formatTime(partner.lastMessageTime!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              partner.lastMessage ?? 'No messages yet',
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: partner.unreadCount > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      partner.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: _buildUsersList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}
