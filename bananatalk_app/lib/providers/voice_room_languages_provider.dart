import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';

const List<String> kVoiceRoomLanguagesFallback = [
  'English',
  'Korean',
  'Japanese',
  'Chinese',
  'Spanish',
  'French',
  'German',
  'Italian',
  'Portuguese',
  'Russian',
  'Arabic',
  'Hindi',
  'Uzbek',
];

final voiceRoomLanguagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.languagesURL}'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      return kVoiceRoomLanguagesFallback;
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? [];
    final names = data
        .map((e) => (e is Map ? e['name']?.toString() : null))
        .whereType<String>()
        .toList();
    return names.isEmpty ? kVoiceRoomLanguagesFallback : names;
  } catch (e) {
    return kVoiceRoomLanguagesFallback;
  }
});
