import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SingleChat extends ConsumerStatefulWidget {
  final String senderId; // This should be passed from the previous screen
  final String userName;
  const SingleChat({Key? key, required this.senderId, required this.userName})
      : super(key: key);

  @override
  ConsumerState<SingleChat> createState() => _SingleChatState();
}

class _SingleChatState extends ConsumerState<SingleChat> {
  final TextEditingController _controller = TextEditingController();
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
      _messagesFuture = messageService.getConversation(
          senderId: widget.senderId, receiverId: '5d7a514b5d2c12c7449be043');
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

  void _sendMessage() async {
    // if (_controller.text.isNotEmpty) {
    //   try {
    //     final messageService = ref.read(messageServiceProvider);
    //     await messageService.sendMessage(
    //       receiverId: widget.senderId,
    //       content: _controller.text,
    //     );
    //     _controller.clear();
    //     _fetchMessages(); // Refresh messages after sending
    //   } catch (error) {
    //     setState(() {
    //       _error = 'Failed to send message: $error';
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Chat with ${widget.userName}'), // Replace with actual sender name if available
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Message>>(
                    future: _messagesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No messages available.'));
                      } else {
                        final messages = snapshot.data!;
                        return ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            // Adjust based on your message model
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Container(
                                  //   child: Align(
                                  //       alignment: Alignment.centerRight,
                                  //       child: Text(message.receiver.name)),
                                  // ),
                                  // Text(message.sender.id),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        message.message,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  // Align(
                                  //   alignment: Alignment.topRight,
                                  //   child: Container(
                                  //     margin: EdgeInsets.symmetric(
                                  //         vertical: 5, horizontal: 10),
                                  //     padding: EdgeInsets.all(10),
                                  //     decoration: BoxDecoration(
                                  //       color: Colors.grey[300],
                                  //       borderRadius: BorderRadius.circular(10),
                                  //     ),
                                  //     child: Text(
                                  //       message.receiver.name,
                                  //       style: TextStyle(color: Colors.black),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    maxLines: 2,
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
