import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/providers/provider_models/sender_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ChatList extends ConsumerStatefulWidget {
  const ChatList({super.key});

  @override
  ConsumerState<ChatList> createState() => _ChatMainState();
}

class _ChatMainState extends ConsumerState<ChatList> {
  late Future<List<Sender>> _messagesFuture;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final localDateTime = dateTime.toLocal();
    final date =
        DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (date == today) {
      return '${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return 'Yesterday ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return DateFormat('EEEE').format(localDateTime) +
          ' ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messageService = ref.read(messageServiceProvider);
      final senders =
          await messageService.getSendersList(id: '5d7a514b5d2c12c7449be043');
      // Sort senders by recentMessage.sentAt in descending order
      senders.sort(
          (a, b) => b.recentMessage.sentAt.compareTo(a.recentMessage.sentAt));
      _messagesFuture = Future.value(senders);
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

  Future<void> _refresh() async {
    setState(() {
      _error = '';
    });
    await _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<Sender>>(
                    future: _messagesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No messages available.'));
                      } else {
                        final senders = snapshot.data!;
                        return ListView.builder(
                          itemCount: senders.length,
                          itemBuilder: (context, index) {
                            final sender = senders[index];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage: sender.imageUrls.isNotEmpty
                                    ? NetworkImage(sender.imageUrls[0])
                                    : AssetImage(
                                            'assets/images/logo_no_background.png')
                                        as ImageProvider,
                              ),
                              title: Text(sender
                                  .name), // Adjust based on actual properties
                              subtitle: Text(sender.recentMessage.content),
                              trailing: Text(
                                formatDate(sender.recentMessage.sentAt),
                                style: TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SingleChat(
                                          senderId: sender.id,
                                          userName: sender.name)),
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
    );
  }
}
