import 'dart:convert';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityService {
  Future<List<Community>> getCommunity() async {
    try {
      final response = await http
          .get(Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((postJson) => Community.fromJson(postJson))
            .toList();
      } else {
        throw Exception('Failed to load community: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  Future<Community> getSingleCommunity({required id}) async {
    try {
      final response = await http
          .get(Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data['data']);
        return Community.fromJson(data[
            'data']); // Assuming 'data' is a map representing the new moment
      } else {
        throw Exception('Failed to create moment');
      }
    } catch (error) {
      print('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  Future<void> followUser({required userId, required targetUserId}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/follow/$targetUserId');
    try {
      final response = await http.put(url);
      print(response);
    } catch (error) {
      print('Error when following the user: $error');
      throw Exception('Failed to call the api: $error');
    }
  }

  Future<void> unfollowUser({required userId, required targetUserId}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/unfollow/$targetUserId');
    try {
      final response = await http.put(url);
      print(response);
    } catch (error) {
      print('Error when unfollowing the user: $error');
      throw Exception('Failed to call the api: $error');
    }
  }

  Future<void> getfollowersCount(
      {required userId, required targetUserId}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/unfollow/$targetUserId');
    try {
      final response = await http.put(url);
      print(response);
    } catch (error) {
      print('Error when unfollowing the user: $error');
      throw Exception('Failed to call the api: $error');
    }
  }

  Future<void> getfollowingsCount(
      {required userId, required targetUserId}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/followers');
    try {
      final response = await http.get(url);
      print(response);
    } catch (error) {
      print('Error when unfollowing the user: $error');
      throw Exception('Failed to call the api: $error');
    }
  }
}

final communityProvider = FutureProvider<List<Community>>((ref) async {
  final service = CommunityService();
  return service.getCommunity();
});

final communityServiceProvider = Provider((ref) => CommunityService());
