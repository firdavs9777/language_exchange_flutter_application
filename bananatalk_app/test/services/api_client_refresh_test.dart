import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/service/endpoints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Endpoints.baseURL is a mutable static shared across the whole test
  // process — a fragile global seam. Any test that mutates it must restore
  // it deterministically, which is why the override/restore lives in
  // setUp/tearDown here rather than inside the test body.
  late String originalBaseUrl;

  setUp(() {
    originalBaseUrl = Endpoints.baseURL;
    Endpoints.baseURL = 'http://127.0.0.1:9'; // closed port -> immediate error

    SharedPreferences.setMockInitialValues({'refreshToken': 'stale-token'});

    final client = ApiClient();
    client.clearTokenCache();
    // ApiClient is a singleton; a previous test could leave _isRefreshing
    // stuck true (or stale queued completers), which would make every call
    // in this test take the queued branch and pass for the wrong reason.
    client.resetRefreshStateForTest();
  });

  tearDown(() {
    Endpoints.baseURL = originalBaseUrl;
  });

  test('concurrent refresh calls all resolve (no hang) when server unreachable', () async {
    final client = ApiClient();

    // The three calls are issued synchronously (no await between them), so
    // the first call's synchronous prefix sets _isRefreshing = true before
    // the second and third calls check it — reliably exercising both the
    // direct-refresh branch (call 1) and the queued branch (calls 2 and 3).
    final results = await Future.wait([
      client.refreshAccessTokenForTest(),
      client.refreshAccessTokenForTest(),
      client.refreshAccessTokenForTest(),
    ]).timeout(const Duration(seconds: 40));

    expect(results, [null, null, null]);
  });
}
