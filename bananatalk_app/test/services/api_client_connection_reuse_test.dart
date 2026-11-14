import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/api_client.dart';

/// ApiClient sends every request through one long-lived http.Client, so the
/// connection (TCP + TLS, ~0.32 s of a ~0.50 s request to the API) is reused.
/// It used to call the top-level http.get/post/put, one new client and one
/// new connection per request.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 't'}));

  test('several requests share one client', () async {
    var clientsMade = 0;
    var requests = 0;
    final transport = MockClient((req) async {
      requests++;
      return http.Response('{"success":true,"data":{}}', 200,
          headers: {'content-type': 'application/json'});
    });

    await http.runWithClient(() async {
      final api = ApiClient();
      await api.get('a');
      await api.post('b', body: {});
      await api.put('c', body: {});
      await api.get('d');
    }, () {
      clientsMade++;
      return transport;
    });

    expect(requests, 4);
    expect(clientsMade, 1, reason: 'one client, so one kept-alive connection');
  });
}
