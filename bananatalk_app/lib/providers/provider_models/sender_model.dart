import 'dart:convert';

class Sender {
  final String id;
  final String name;
  final String gender;
  final String email;
  final String bio;
  final String birthYear;
  final String birthMonth;
  final String birthDay;
  final List<String> images;
  final String nativeLanguage;
  final String languageToLearn;
  final DateTime createdAt;
  final int v;
  final List<String> imageUrls;
  final RecentMessage recentMessage;

  Sender({
    required this.id,
    required this.name,
    required this.gender,
    required this.email,
    required this.bio,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.images,
    required this.nativeLanguage,
    required this.languageToLearn,
    required this.createdAt,
    required this.v,
    required this.imageUrls,
    required this.recentMessage,
  });

  // Factory method to create a Sender from JSON
  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id'],
      name: json['name'],
      gender: json['gender'],
      email: json['email'],
      bio: json['bio'],
      birthYear: json['birth_year'],
      birthMonth: json['birth_month'],
      birthDay: json['birth_day'],
      images: List<String>.from(json['images']),
      nativeLanguage: json['native_language'],
      languageToLearn: json['language_to_learn'],
      createdAt: DateTime.parse(json['createdAt']),
      v: json['__v'],
      imageUrls: List<String>.from(json['imageUrls']),
      recentMessage: RecentMessage.fromJson(json['recentMessage']),
    );
  }

  // Convert Sender to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'gender': gender,
      'email': email,
      'bio': bio,
      'birth_year': birthYear,
      'birth_month': birthMonth,
      'birth_day': birthDay,
      'images': images,
      'native_language': nativeLanguage,
      'language_to_learn': languageToLearn,
      'createdAt': createdAt.toIso8601String(),
      '__v': v,
      'imageUrls': imageUrls,
      'recentMessage': recentMessage.toJson(),
    };
  }
}

class RecentMessage {
  final String content;
  final DateTime sentAt;

  RecentMessage({
    required this.content,
    required this.sentAt,
  });

  // Factory method to create a RecentMessage from JSON
  factory RecentMessage.fromJson(Map<String, dynamic> json) {
    return RecentMessage(
      content: json['content'],
      sentAt: DateTime.parse(json['sentAt']),
    );
  }

  // Convert RecentMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
