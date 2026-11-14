import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// `POST study/events`. Telemetry: the result is only a bool.
class StudyEventsApi {
  StudyEventsApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// True when the server accepted the batch.
  Future<bool> send(List<Map<String, dynamic>> events) async {
    final res = await _client.post(
      Endpoints.studyEventsURL,
      body: {'events': events},
      suppressRateLimitToast: true,
    );
    return res.success;
  }
}
