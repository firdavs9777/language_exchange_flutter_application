import 'package:flutter/material.dart';
import 'dart:convert';
// Category Object Blueprint

class User {
  const User({
    required this.name,
    required this.password,
    required this.email,
    required this.bio,
    required this.image,
    required this.birth_day,
    required this.birth_month,
    required this.birth_year,
    required this.native_language,
    required this.language_to_learn,
  });

  final String name;
  final String password;
  final String email;
  final String bio;
  final String image;
  final String native_language;
  final String language_to_learn;
  final String birth_year;
  final String birth_month;
  final String birth_day;

  Object? toJson() {}
}
