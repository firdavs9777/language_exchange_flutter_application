import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class CorrectionService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Send a correction for a message
  static Future<Map<String, dynamic>> sendCorrection({
    required String messageId,
    required String originalText,
    required String correctedText,
    String? explanation,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.correctMessageURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'originalText': originalText,
          'correctedText': correctedText,
          if (explanation != null && explanation.isNotEmpty)
            'explanation': explanation,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null
              ? MessageCorrection.fromJson(data['data'])
              : null,
          'message': data['message'] ?? 'Correction sent',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send correction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get all corrections for a message
  static Future<Map<String, dynamic>> getCorrections({
    required String messageId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.getCorrectionsURL(messageId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': (data['data'] as List?)
                  ?.map((c) => MessageCorrection.fromJson(c))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get corrections',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Accept a correction
  static Future<Map<String, dynamic>> acceptCorrection({
    required String messageId,
    required String correctionId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.acceptCorrectionURL(messageId, correctionId)}',
      );

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null
              ? MessageCorrection.fromJson(data['data'])
              : null,
          'message': data['message'] ?? 'Correction accepted',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to accept correction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Compare two texts and highlight differences
  static List<TextDiff> getDifferences(String original, String corrected) {
    final diffs = <TextDiff>[];
    
    // Simple word-level diff
    final originalWords = original.split(' ');
    final correctedWords = corrected.split(' ');
    
    int i = 0, j = 0;
    
    while (i < originalWords.length || j < correctedWords.length) {
      if (i >= originalWords.length) {
        // Added words
        diffs.add(TextDiff(
          text: correctedWords[j],
          type: DiffType.added,
        ));
        j++;
      } else if (j >= correctedWords.length) {
        // Deleted words
        diffs.add(TextDiff(
          text: originalWords[i],
          type: DiffType.deleted,
        ));
        i++;
      } else if (originalWords[i] == correctedWords[j]) {
        // Unchanged
        diffs.add(TextDiff(
          text: originalWords[i],
          type: DiffType.unchanged,
        ));
        i++;
        j++;
      } else {
        // Changed - check if it's a replacement or insert/delete
        final nextOriginalMatch = _findNext(correctedWords[j], originalWords, i);
        final nextCorrectedMatch = _findNext(originalWords[i], correctedWords, j);
        
        if (nextOriginalMatch != -1 && 
            (nextCorrectedMatch == -1 || nextOriginalMatch - i <= nextCorrectedMatch - j)) {
          // Delete original words until we match
          while (i < nextOriginalMatch) {
            diffs.add(TextDiff(
              text: originalWords[i],
              type: DiffType.deleted,
            ));
            i++;
          }
        } else if (nextCorrectedMatch != -1) {
          // Add corrected words until we match
          while (j < nextCorrectedMatch) {
            diffs.add(TextDiff(
              text: correctedWords[j],
              type: DiffType.added,
            ));
            j++;
          }
        } else {
          // Simple replacement
          diffs.add(TextDiff(
            text: originalWords[i],
            type: DiffType.deleted,
          ));
          diffs.add(TextDiff(
            text: correctedWords[j],
            type: DiffType.added,
          ));
          i++;
          j++;
        }
      }
    }
    
    return diffs;
  }

  static int _findNext(String word, List<String> words, int start) {
    for (int i = start; i < words.length && i < start + 5; i++) {
      if (words[i] == word) return i;
    }
    return -1;
  }
}

/// Represents a text difference
class TextDiff {
  final String text;
  final DiffType type;

  TextDiff({
    required this.text,
    required this.type,
  });
}

/// Type of text difference
enum DiffType {
  unchanged,
  added,
  deleted,
}

