import 'package:bananatalk_app/service/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The server-side interest profile that ranks the Moments feed.
class InterestService {
  InterestService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Deletes the signed-in user's interest profile. True on a 2xx answer;
  /// false on anything else, including a network error.
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await _client.delete(
        Uri.parse('${Endpoints.baseURL}${Endpoints.myInterestsURL}'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
