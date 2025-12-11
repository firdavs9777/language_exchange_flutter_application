import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationService {
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

  /// Create a new conversation room between users
  Future<Map<String, dynamic>> createConversationRoom({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.createConversationRoomURL}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'isNew': data['data']?['isNew'] ?? false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to create conversation',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get all conversations
  Future<Map<String, dynamic>> getConversations({
    bool? archived,
    bool? muted,
    bool? pinned,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${Endpoints.baseURL}${Endpoints.conversationsURL}').replace(
        queryParameters: {
          if (archived != null) 'archived': archived.toString(),
          if (muted != null) 'muted': muted.toString(),
          if (pinned != null) 'pinned': pinned.toString(),
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
          'data': (data['data'] as List?)
                  ?.map((item) => Conversation.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get conversations',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get single conversation
  Future<Map<String, dynamic>> getConversation({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.getConversationURL(conversationId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Mute conversation
  Future<Map<String, dynamic>> muteConversation({
    required String conversationId,
    int? duration, // Duration in milliseconds (null = permanent)
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.muteConversationURL(conversationId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: duration != null ? jsonEncode({'duration': duration}) : null,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation muted successfully',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to mute conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Unmute conversation
  Future<Map<String, dynamic>> unmuteConversation({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.unmuteConversationURL(conversationId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation unmuted successfully',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to unmute conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Archive conversation
  Future<Map<String, dynamic>> archiveConversation({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.archiveConversationURL(conversationId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation archived successfully',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to archive conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Unarchive conversation
  Future<Map<String, dynamic>> unarchiveConversation({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.unarchiveConversationURL(conversationId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation unarchived successfully',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to unarchive conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Pin conversation
  Future<Map<String, dynamic>> pinConversation({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.pinConversationURL(conversationId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation pinned successfully',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to pin conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Unpin conversation
  Future<Map<String, dynamic>> unpinConversation({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.unpinConversationURL(conversationId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation unpinned successfully',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to unpin conversation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Mark conversation as read
  Future<Map<String, dynamic>> markConversationRead({
    required String conversationId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.markConversationReadURL(conversationId)}');

      final response = await http.put(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Conversation marked as read',
          'data': Conversation.fromJson(data['data']),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to mark conversation as read',
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

class Conversation {
  final String id;
  final List<Community> participants;
  final Community? otherParticipant;
  final Message? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;

  Conversation({
    required this.id,
    required this.participants,
    this.otherParticipant,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List?)
              ?.map((item) => Community.fromJson(item))
              .toList() ??
          [],
      otherParticipant: json['otherParticipant'] != null
          ? Community.fromJson(json['otherParticipant'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: json['lastMessageAt'],
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'otherParticipant': otherParticipant?.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
    };
  }
}

