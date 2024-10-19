import 'package:flutter/material.dart';
import 'dart:convert';
// Category Object Blueprint

class Community {
  const Community(
      {required this.id,
      required this.name,
      required this.email,
      required this.bio,
      required this.images,
      required this.birth_day,
      required this.birth_month,
      required this.gender,
      required this.birth_year,
      required this.native_language,
      required this.language_to_learn,
      required this.followers,
      required this.followings,
      required this.imageUrls,
      required this.createdAt,
      required this.version});

  final String id;
  final String name;
  final String gender;
  final String email;
  final String bio;

  final List<String> images;
  final List<String> imageUrls;
  final List<String> followers;
  final List<String> followings;
  final String native_language;
  final String language_to_learn;
  final String birth_year;
  final String birth_month;
  final String birth_day;
  final String createdAt;
  final int version;

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        bio: json['bio'] ?? '',
        images: (json['images'] != null
                ? List<String>.from(json['images'])
                : <String>[]) ??
            [],
        birth_day: json['birth_day'],
        birth_month: json['birth_month'],
        gender: json['gender'],
        birth_year: json['birth_year'],
        native_language: json['native_language'],
        language_to_learn: json['language_to_learn'],
        imageUrls: (json['imageUrls'] != null
                ? List<String>.from(json['imageUrls'])
                : <String>[]) ??
            [],
        followers: (json['followers'] != null
                ? List<String>.from(json['followers'])
                : <String>[]) ??
            [],
        followings: (json['followings'] != null
                ? List<String>.from(json['followings'])
                : <String>[]) ??
            [],
        createdAt: json['createdAt'],
        version: json['__v']);
  }
}
