import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationProgress {
  RegistrationProgress({required this.step, required this.fields, DateTime? savedAt})
      : savedAt = savedAt ?? DateTime.now();

  final int step;
  final Map<String, String> fields;
  final DateTime savedAt;

  Map<String, dynamic> toJson() =>
      {'step': step, 'fields': fields, 'savedAt': savedAt.toIso8601String()};

  factory RegistrationProgress.fromJson(Map<String, dynamic> json) => RegistrationProgress(
        step: json['step'] as int,
        fields: Map<String, String>.from(json['fields'] as Map),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class RegistrationProgressService {
  static const _key = 'registrationProgress';
  static const _maxAge = Duration(days: 7);

  Future<void> save(RegistrationProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<RegistrationProgress?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final progress = RegistrationProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(progress.savedAt) > _maxAge) {
        await clear();
        return null;
      }
      return progress;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
