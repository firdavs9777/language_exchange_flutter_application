import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class Comments {
  const Comments(
      {required this.id,
      required this.text,
      required this.user,
      // required this.moment,
      required this.createdAt,
      required this.version});

  final String id;
  final String text;
  final Community user;
  // final Moments moment;
  final DateTime createdAt;
  final int version;

  factory Comments.fromJson(Map<String, dynamic> json) {
    return Comments(
        id: json['_id'],
        text: json['text'],
        user: Community.fromJson(json['user']),
        // moment: Moments.fromJson(json['moment']),
        createdAt: DateTime.parse(json['createdAt']),
        version: json['__v']);
  }
}
