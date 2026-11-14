import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// `POST purchases/paywall-events`. Telemetry: the result is only a bool.
class PaywallApi {
  PaywallApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// True when the server accepted the batch.
  Future<bool> send(List<Map<String, dynamic>> events) async {
    final res = await _client.post(
      Endpoints.paywallEventsURL,
      body: {'events': events},
      suppressRateLimitToast: true,
    );
    return res.success;
  }
}
