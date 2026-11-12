import 'package:bananatalk_app/service/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The server-side interest profile that ranks the Moments feed.
class InterestService {
  InterestService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// How long [clear] waits for the server before answering false.
  final Duration timeout;

  /// Deletes the signed-in user's interest profile. True on a 2xx answer;
  /// false on anything else, including a network error or no answer within
  /// [timeout].
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await _client
          .delete(
            Uri.parse('${Endpoints.baseURL}${Endpoints.myInterestsURL}'),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
