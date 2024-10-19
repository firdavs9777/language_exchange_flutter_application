import 'dart:convert';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/sender_model.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final messageServiceProvider = Provider((ref) => MessageService());
