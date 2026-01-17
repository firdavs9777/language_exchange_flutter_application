import 'dart:convert';
import 'dart:io';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/sender_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageService {
  Future<List<Message>> getUserMessages({required id}) async {
    try {
      final response = await http.get(Uri.parse(
          '${Endpoints.baseURL}${Endpoints.messageUrl}/${Endpoints.userUrl}/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((postJson) => Message.fromJson(postJson))
            .toList();
      } else {
        throw Exception('Failed to load community: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  Future<List<Message>> getConversation(
      {required senderId, required receiverId}) async {
    try {
      final response = await http.get(Uri.parse(
          '${Endpoints.baseURL}${Endpoints.messageUrl}/conversation/$senderId/$receiverId'));
      if (response.statusCode == 200) {
        print(response.body);
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((postJson) => Message.fromJson(postJson))
            .toList();
      } else {
        throw Exception('Failed to load community: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  Future<List<Sender>> getSendersList({required id}) async {
    try {
      final response = await http.get(Uri.parse(
          '${Endpoints.baseURL}${Endpoints.messageUrl}/${Endpoints.senderUrl}/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        if (data['success']) {
          return (data['data'] as List)
              .map((jsonItem) => Sender.fromJson(jsonItem))
              .toList();
        } else {
          throw Exception('Failed to load senders: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load community: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  Future<List<Message>> getSenderMessages({required id}) async {
    try {
      final response = await http.get(
          Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}/from/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((postJson) => Message.fromJson(postJson))
            .toList();
      } else {
        throw Exception('Failed to load message: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching message: $error');
      throw Exception('Failed to load message: $error');
    }
  }

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

  /// Send message with optional media
  Future<Map<String, dynamic>> sendMessage({
    required String receiver,
    String? message,
    File? file,
    Map<String, dynamic>? location,
    String? replyTo,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}');

      if (file != null) {
        // Send with media (multipart)
        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['receiver'] = receiver;
        if (message != null && message.isNotEmpty) {
          request.fields['message'] = message;
        }
        if (replyTo != null && replyTo.isNotEmpty) {
          request.fields['replyTo'] = replyTo;
        }
        if (location != null) {
          request.fields['location'] = jsonEncode(location);
        }
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'data': Message.fromJson(data['data']),
          };
        } else {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ?? 'Failed to send message',
          };
        }
      } else {
        // Send text or location only
        final response = await http.post(
          url,
          headers: _getHeaders(token),
          body: jsonEncode({
            'receiver': receiver,
            if (message != null && message.isNotEmpty) 'message': message,
            if (replyTo != null && replyTo.isNotEmpty) 'replyTo': replyTo,
            if (location != null) 'location': location,
          }),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'data': Message.fromJson(data['data']),
          };
        } else {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ?? 'Failed to send message',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Edit a message
  Future<Map<String, dynamic>> editMessage({
    required String messageId,
    required String message,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.editMessageURL(messageId)}');

      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Message edited successfully',
          'data': Message.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to edit message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete a message
  Future<Map<String, dynamic>> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.deleteMessageURL(messageId)}');

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'deleteForEveryone': deleteForEveryone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Message deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to delete message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Reply to a message
  Future<Map<String, dynamic>> replyToMessage({
    required String messageId,
    required String message,
    required String receiver,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.replyToMessageURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'message': message,
          'receiver': receiver,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Reply sent successfully',
          'data': Message.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send reply',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Forward a message
  Future<Map<String, dynamic>> forwardMessage({
    required String messageId,
    required List<String> receivers,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.forwardMessageURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'receivers': receivers}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Message forwarded successfully',
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to forward message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Pin a message
  Future<Map<String, dynamic>> pinMessage({
    required String messageId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.pinMessageURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Message pinned successfully',
          'data': Message.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to pin message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get message replies
  Future<Map<String, dynamic>> getMessageReplies({
    required String messageId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.getMessageRepliesURL(messageId)}?page=$page&limit=$limit');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'total': data['total'] ?? 0,
          'data': (data['data'] as List?)
                  ?.map((item) => Message.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get replies',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Add reaction to message
  Future<Map<String, dynamic>> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.addReactionURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'emoji': emoji}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Reaction added successfully',
          'data': (data['data'] as List?)
                  ?.map((item) => MessageReaction.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to add reaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Remove reaction from message
  Future<Map<String, dynamic>> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.removeReactionURL(messageId, emoji)}');

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Reaction removed successfully',
          'data': (data['data'] as List?)
                  ?.map((item) => MessageReaction.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to remove reaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get message reactions
  Future<Map<String, dynamic>> getReactions({
    required String messageId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.getReactionsURL(messageId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'data': (data['data'] as List?)
                  ?.map((item) => MessageReaction.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get reactions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Search messages
  Future<Map<String, dynamic>> searchMessages({
    String? query,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? mediaType,
    String? dateFrom,
    String? dateTo,
    bool? hasMedia,
    bool? isPinned,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${Endpoints.baseURL}${Endpoints.searchMessagesURL}').replace(
        queryParameters: {
          if (query != null) 'q': query,
          if (conversationId != null) 'conversationId': conversationId,
          if (senderId != null) 'senderId': senderId,
          if (receiverId != null) 'receiverId': receiverId,
          if (mediaType != null) 'mediaType': mediaType,
          if (dateFrom != null) 'dateFrom': dateFrom,
          if (dateTo != null) 'dateTo': dateTo,
          if (hasMedia != null) 'hasMedia': hasMedia.toString(),
          if (isPinned != null) 'isPinned': isPinned.toString(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'total': data['total'] ?? 0,
          'pagination': data['pagination'],
          'data': (data['data'] as List?)
                  ?.map((item) => Message.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to search messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get media upload configuration
  Future<Map<String, dynamic>> getMediaConfig() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}/video-config');

      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get media config',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Send video message (max 10 minutes, 1GB)
  /// Supported formats: MP4, MOV, AVI, WebM, 3GP, M4V
  Future<Map<String, dynamic>> sendVideoMessage({
    required String receiver,
    required File videoFile,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}/video');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['receiver'] = receiver;

      // Determine mime type - supports MP4, MOV, AVI, WebM, 3GP, M4V
      final extension = videoFile.path.split('.').last.toLowerCase();
      String mimeType = 'video/mp4';
      if (extension == 'mov') mimeType = 'video/quicktime';
      else if (extension == 'webm') mimeType = 'video/webm';
      else if (extension == 'avi') mimeType = 'video/x-msvideo';
      else if (extension == 'm4v') mimeType = 'video/x-m4v';
      else if (extension == '3gp') mimeType = 'video/3gpp';

      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': Message.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send video message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Send voice message (max 5 minutes, 25MB)
  Future<Map<String, dynamic>> sendVoiceMessage({
    required String receiver,
    required File audioFile,
    int? duration,
    List<double>? waveform,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}/voice');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['receiver'] = receiver;

      if (duration != null) {
        request.fields['duration'] = duration.toString();
      }

      if (waveform != null && waveform.isNotEmpty) {
        request.fields['waveform'] = jsonEncode(waveform);
      }

      // Determine mime type
      final extension = audioFile.path.split('.').last.toLowerCase();
      String mimeType = 'audio/mp4';
      if (extension == 'mp3') mimeType = 'audio/mpeg';
      else if (extension == 'm4a') mimeType = 'audio/mp4';
      else if (extension == 'ogg') mimeType = 'audio/ogg';
      else if (extension == 'webm') mimeType = 'audio/webm';
      else if (extension == 'wav') mimeType = 'audio/wav';

      request.files.add(await http.MultipartFile.fromPath(
        'voice',
        audioFile.path,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': Message.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send voice message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Send location message
  Future<Map<String, dynamic>> sendLocationMessage({
    required String receiver,
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageUrl}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'receiver': receiver,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            if (address != null) 'address': address,
            if (placeName != null) 'placeName': placeName,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': Message.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send location',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

final messageServiceProvider = Provider((ref) => MessageService());
