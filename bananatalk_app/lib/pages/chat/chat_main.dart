import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class ChatMain extends ConsumerStatefulWidget {
  const ChatMain({super.key});

  @override
  ConsumerState<ChatMain> createState() => _ChatMainState();
}

class _ChatMainState extends ConsumerState<ChatMain> {
  late Future<List<Message>> _messagesFuture;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messageService = ref.read(messageServiceProvider);
      _messagesFuture =
          messageService.getUserMessages(id: '5d7a514b5d2c12c7449be042');
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
        title: const Text('Chat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<Message>>(
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
                        final messages = snapshot.data!;
                        return ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return ListTile(
                              title: Text(message.sender
                                  .name), // Adjust based on actual properties
                              subtitle: Text(message.receiver.name),
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
