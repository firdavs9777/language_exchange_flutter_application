import 'package:bananatalk_app/providers/provider_models/community_model.dart';

class Message {
  const Message(
      {required this.id,
      required this.sender,
      required this.receiver,
      required this.message,
      required this.createdAt,
      required this.version,
      required this.read});

  final String id;
  final Community sender;
  final Community receiver;
  final String message;
  final String createdAt;
  final int version;
  final bool read;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        id: json['_id'] ?? '',
        sender: json['sender'] != null
            ? Community.fromJson(json['sender'])
            : throw Exception('Sender cannot be null'),
        receiver: json['receiver'] != null
            ? Community.fromJson(json['receiver'])
            : throw Exception('Receiver cannot be null'),
        message: json['message'] ?? '',
        createdAt: json['createdAt'] ?? '',
        version: json['__v'] ?? 0,
        read: json['read'] ?? false);
  }
}
