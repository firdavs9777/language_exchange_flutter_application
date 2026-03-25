import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

class CallHistoryService {
  final ApiClient _apiClient;
  final String _currentUserId;

  CallHistoryService(this._apiClient, this._currentUserId);

  /// Get paginated call history
  Future<List<CallRecord>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/calls',
        queryParams: {'page': page.toString(), 'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return data
            .map((json) => CallRecord.fromJson(
                Map<String, dynamic>.from(json), _currentUserId))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get call history with specific user
  Future<List<CallRecord>> getCallHistoryWithUser(String recipientId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/calls',
        queryParams: {'userId': recipientId},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return data
            .map((json) => CallRecord.fromJson(
                Map<String, dynamic>.from(json), _currentUserId))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get missed calls count
  Future<int> getMissedCallsCount() async {
    try {
      final response = await _apiClient.get('/api/v1/calls/missed/count');

      if (response.statusCode == 200) {
        return response.data['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get single call details
  Future<CallRecord?> getCallDetails(String callId) async {
    try {
      final response = await _apiClient.get('/api/v1/calls/$callId');

      if (response.statusCode == 200) {
        return CallRecord.fromJson(
            Map<String, dynamic>.from(response.data['data']), _currentUserId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
